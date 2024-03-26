/*
Name:  CallTrackingUtilityController.cls
======================================================
======================================================
Purpose: Apex controller for CallTrackingUtility cmp

This class tracks active call activity. Leveraging Vonage
APIs to identify how long the agent has been connected to
a customer and firing a prompt (via Act On It) to sign the 
customer up to the Newsletter.

1) Using the omni toolkit determine when the agent is on an active call.
2) Whilst on the call periodically callout to vonage to check the live status of the call 
(i.e. ringing, connected, wrap up etc), as per the configured polling interval. 
3) Check to see if the agent has been 'connected' for the configured 'minimum connected time' (seconds),
else wait (queue a subsequent callout at the configured minimum).
4) Callout to a second api to retrieve call details incl caller Id/dialled number & Tealium Id
5) Lookup client in SF with a matching phone number/tealium id and open opportunity. Exit if
more or less than 1.
6) Verify the prompt should be sent based on custom business logic i.e. not already subscribed, did not recently unsub etc.
7) Publish Act On It alert message, prompting the agent to invite the customer to sign up to the newsletter.

Design Notes:
If a nextAttemptInSeconds is not returned to the component, the polling will cancel, minimising the number of calls
to the vonage contact centre api.
If a nextAttemptInSeconds is returned, a subsequent call of the excuteCallTracking method will be scheduled at that time.
This class makes use of the Integration Framework to call Vonage CC APIs directly (agent status) and via Cloudflare middleware (call details) created by S.H.

-------
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-05-26  Initial Development.
1.1  J Radcliffe   2022-06-01  Enhancements. React to tab changes (detect newly created records)
*/
public without sharing class CallTrackingUtilityController {

    public static final String AgentStatusDET = 'VonageCCAPIGetAgentStatus';
    public static final String CallDetailsDET = 'GetDialledNumberForActiveCaller';
    public static final String weeklyNewsletterFieldName = 'Weekly_Newsletter__c';
 
    @TestVisible public static DateTime currentTimeOverride;
    @TestVisible public static String testAgentStatusJSON;
    @TestVisible public static String testCallDetailJSON;

    public Class TrackingData{
        @AuraEnabled public String message;
        @AuraEnabled public Integer nextAttemptInSeconds;//Seconds
        @AuraEnabled public String unrecognisedPhoneNumber;//1.1+
        public TrackingData(String message){
            this.message = message;
        } 
        public TrackingData(String message,Integer nextAttemptInSeconds){
            this.message = message;
            this.nextAttemptInSeconds = nextAttemptInSeconds;
        }
    }

    @AuraEnabled
    public static List<User> getNVMUsers(){
        try {
            return [Select Id, Name, NVMContactWorld__NVM_Agent_Id__c  From User Where NVMContactWorld__NVM_Agent_Id__c  != null and IsActive = true Order by Name ASC];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    //AgentId - Option Agent Id (helpful for testing)
    //minimumConnectedCallTime - The minimum amount of time (in seconds) that the agent must be connected to a customer before they are delivered the prompt
    //pollingInterval - The interval (in seconds) between each attempt to assess the active call status (from when the agent initially moves to Busy - Call status)
    //messageTypeDeveloperName - The developer name of the Message Type used (and required) to publish the relevant alert message to the agent
    //customMessage - Optional custom message to publish to user (can be exposed as a design attribute in the component)
    
    @AuraEnabled
    public static TrackingData executeCallTracking(String agentId, Integer minimumConnectedCallTime, Integer pollingInterval, String messageTypeDeveloperName, String customMessage){
        try {

            //Verify details and apply defaults
            User runningUser; 
            if(agentId == null){
                runningUser  = [Select Id, NVMContactWorld__NVM_Agent_Id__c, FirstName, LastName From User Where Id =:UserInfo.getUserId()];
                agentId = runningUser.NVMContactWorld__NVM_Agent_Id__c;
            }else{
                runningUser = [Select Id, NVMContactWorld__NVM_Agent_Id__c, FirstName, LastName From User Where NVMContactWorld__NVM_Agent_Id__c = :agentId];
            } 
            
            if(Test.isRunningTest()) agentId = '286';//Test Agent Id

            if(agentId == null) return new TrackingData('Not an NVM User');
            if(messageTypeDeveloperName == null ) return new TrackingData('No Message Type specified (cannot publish Act On It prompt message)');
            List<ActOnIt__MessageType__c> types = [Select Id, ActOnIt__IsActive__c From ActOnIt__MessageType__c Where ActOnIt__DeveloperName__c = :messageTypeDeveloperName];
            if(types.size()==0) return new TrackingData('Unrecognised Message Type (cannot publish Act On It prompt message)');
            if(!types[0].ActOnIt__IsActive__c) return new TrackingData('Inactive Message Type (cannot publish Act On It prompt message)');
            if(minimumConnectedCallTime == null) minimumConnectedCallTime = 15;
            if(pollingInterval == null) pollingInterval = 15;

            //Check user is Active Act On It user
            if(!Test.isRunningTest()) if([Select Count() From ActOnIt__UserSettings__c Where ActOnIt__User__c=:runningUser.Id and ActOnIt__IsActive__c = true] == 0) return new TrackingData('User is not an Act On It App User (Cannot receive prompt message).');
            
            //Get agent status info from vonage cc api's (via Integration Framework)
            //https://newvoicemedia.atlassian.net/wiki/spaces/VCCA/pages/3568009217/Get+agent+current+status
            List<DataEventTypeAction.DataEventTypeActionRequest> requests = new List<DataEventTypeAction.DataEventTypeActionRequest>();
            requests.add(new DataEventTypeAction.DataEventTypeActionRequest(AgentStatusDET,null));
            
            //Test Response Details (for unit testing)
            List<DataEventTypeAction.DataEventTypeActionResult> testResults;
            if(Test.isRunningTest()){
                testResults = new List<DataEventTypeAction.DataEventTypeActionResult>();
                DataEventTypeAction.DataEventTypeActionResult testResult = new DataEventTypeAction.DataEventTypeActionResult(null);
                testResult.responseBody = testAgentStatusJSON;
                testResults.add(testResult);
            }  

            List<DataEventTypeAction.DataEventTypeActionResult> results = (!Test.isRunningTest())?DataEventTypeAction.invokeDataEventType(requests):testResults;
            DataEventTypeAction.DataEventTypeActionResult result = results[0];
            system.debug('Response Body > '+result.responseBody);
            if(result.responseBody == null) return new TrackingData('No tracking information available for this agent/call');
            ResponseData data = (ResponseData)JSON.deserialize(result.responseBody, ResponseData.class);
            
            for(TrackingDetail td : data.items){
                system.debug(td);
                if(td.agentId != agentId) continue;
                if(td.interaction.size()==0) return new TrackingData('No active interaction',pollingInterval);//Try again
                if(td.interaction[0].state != 'Connected' /*&& td.interaction[0].state != 'Unexpected'*/) return new TrackingData('No connected call > '+td.interaction[0].state,pollingInterval);

                //Check connected call duration
                Integer connectedTime;
                DateTime startTime = Datetime.valueOfGMT(td.interaction[0].since.replace('T',' '));
                DateTime now = (Test.isRunningTest()&& currentTimeOverride != null)?currentTimeOverride:System.now();
                system.debug('Current Date Time > '+now);
                connectedTime = (Integer)(now.getTime()-startTime.getTime())/1000;
                system.debug('Since Date Time > '+startTime);
                system.debug('connectedTime > '+connectedTime);
                if(connectedTime<minimumConnectedCallTime) return new TrackingData('Connected time is less than confgured minimum by '+(minimumConnectedCallTime-connectedTime)+' seconds',minimumConnectedCallTime-connectedTime);

                //Get call detail (via Integration Framework)
                List<DataEventTypeAction.DataEventTypeActionRequest> requests2 = new List<DataEventTypeAction.DataEventTypeActionRequest>();
                requests2.add(new DataEventTypeAction.DataEventTypeActionRequest(CallDetailsDET,runningUser.Id));
                
                //Test Response Details (for unit testing)
                List<DataEventTypeAction.DataEventTypeActionResult> testResults2;
                if(Test.isRunningTest()){
                    testResults2 = new List<DataEventTypeAction.DataEventTypeActionResult>();
                    DataEventTypeAction.DataEventTypeActionResult testResult2 = new DataEventTypeAction.DataEventTypeActionResult(null);
                    testResult2.responseBody = testCallDetailJSON;
                    testResults2.add(testResult2);
                } 

                List<DataEventTypeAction.DataEventTypeActionResult> results2 = (!Test.isRunningTest())?DataEventTypeAction.invokeDataEventType(requests2):testResults2;
                DataEventTypeAction.DataEventTypeActionResult result2 = results2[0];
                system.debug('Response Body > '+result2.responseBody);

                Map<String,Object> callDetail = (Map<String,Object>)JSON.deserializeUntyped(result2.responseBody);
                String error = (String)callDetail?.get('error');
                //if(error != null) return new TrackingData(error);
                String direction = (String)callDetail?.get('direction');
                String callerId = (String)callDetail?.get('callerId');
                String dialledNumber = (String)callDetail?.get('dialledNumber');
                String tealiumId = (String)callDetail?.get('tealiumId');

                //Get customer's number (outbound = dialled number, inbound = caller number)
                String customerNumber = (direction == 'Inbound')?callerId:dialledNumber;
                if(customerNumber == null) return new TrackingData('No phone number was identified');

                String query = 'Select Id, FirstName, LastName, PersonIndividual.Weekly_Newsletter__c, PersonIndividual.Data_Audit_Last_Completed__c, PersonIndividual.LastEmailSubscriptionStatusChangeDT__c, ';
                query = query+' (Select Id From Opportunities Where IsOpen__c = true Limit 1)';
                query = query+' From Account Where IsPersonAccount = true and (PersonMobilePhone =:customerNumber or PersonOtherPhone = :customerNumber or PersonHomePhone = :customerNumber or Phone = :customerNumber ';
                if(tealiumId != null){
                    query = query+' or TealiumId__c =:tealiumId) ';
                }else{
                    query = query+')';
                }
                query = query+' and Id In(Select AccountId From Opportunity Where CreatedDate >= LAST_N_DAYS:365 and IsOpen__c = true)';
                //if(true)return new TrackingData(query);
                
                List<Account> accounts = Database.query(query);
                if(accounts.size()==0){//1.1~
                    TrackingData t = new TrackingData('Phone number not recognised > '+customerNumber);
                    t.unrecognisedPhoneNumber = customerNumber;//1.1+
                    return t;
                } 
                if(accounts.size()>1) return new TrackingData('More than one Account with an open Opportunity has been identified');

                Account acc = accounts[0];
                Opportunity opp = accounts[0].Opportunities[0];

                //Exclude if the are already opted in or recently opted out or been audited
                if(acc.PersonIndividual.Weekly_Newsletter__c) return new TrackingData('Customer already opted in > '+acc.FirstName+' '+acc.LastName+' ('+acc.Id+')');
                if(acc.PersonIndividual.Data_Audit_Last_Completed__c > System.today().addDays(-90)) return new TrackingData('Customer was recently audited > '+acc.FirstName+' '+acc.LastName+' ('+acc.Id+')');
                
                list<IndividualHistory> indHist = [Select Id, IndividualId, OldValue, NewValue From IndividualHistory Where Field = :weeklyNewsletterFieldName and CreatedDate >= LAST_90_DAYS and IndividualId = :acc.PersonIndividualId Order By Createddate DESC Limit 1];
                if(indHist != null && indHist.size()>0 && indHist[0].NewValue == false){
                    return new TrackingData('Customer recently opted out > '+acc.FirstName+' '+acc.LastName+' ('+acc.Id+')');
                }

                //Exit if the prompt has already been sent to the user (and is still visible)
                if([Select Count() From ActOnIt__MessageRecipient__c Where ActOnIt__RecordId__c = :opp.Id and OwnerId =:UserInfo.getUserId() and ActOnIt__IsClosed__c = false and ActOnIt__MessageType__r.ActOnIt__DeveloperName__c =:messageTypeDeveloperName]>0) return new TrackingData('A prompt has already been delivered to the agent for this customer record');

                //Post a Message
                if(customMessage != null){ 
                    if(customMessage.containsIgnoreCase('[!userFirstName]')) customMessage = customMessage.replace('[!userFirstName]',runningUser.FirstName);
                    if(customMessage.containsIgnoreCase('[!userLastName]')) customMessage = customMessage.replace('[!userLastName]',runningUser.LastName);
                    if(customMessage.containsIgnoreCase('[!clientFirstName]')) customMessage = customMessage.replace('[!clientFirstName]',acc.FirstName);
                    if(customMessage.containsIgnoreCase('[!clientLastName]')) customMessage = customMessage.replace('[!clientLastName]',acc.LastName);
                }

                //Send message via Act On It
                ActOnIt.ActOnItMessageManager.PassOrFail publishResult = sendMessage(runningUser.Id,messageTypeDeveloperName,customMessage,opp.Id);
                if(!publishResult.isSuccess){
                    return new TrackingData('Message Publish Failure: '+publishResult.message);
                }else{
                    return new TrackingData('Message Published');
                } 
            }

            return new TrackingData('No agent status data available for this user'); 

        } catch (Exception e) {
            Golfbreaks.PlatformLogManager.logExceptions(e,'CallTrackingUtilityController','executeCallTracking');
            return new TrackingData('ERROR > '+e.getMessage()+'-'+e.getStackTraceString());
        }
    }

    //1.1+
    //This method is used to retry the number of the active caller to cater to the scenario when a new record is created whilst on the call (phone number wasn't recognised during the initial execution/search)
    //This method is called when a number is available and the agent navigates to an Account or Opportunity whilst on an active call. 
    //The number will only be available if the agent has been connected for the minimum time and if the agent remains on the call, meaning we can avoid additional/redundant callouts to the Vonage APIs.
    @AuraEnabled
    public static TrackingData retryPhoneNumber(String agentId, String customerNumber, Id oppId, String messageTypeDeveloperName, String customMessage){
        try {
            if(customerNumber == null || oppId == null || messageTypeDeveloperName == null ) return new TrackingData('Insufficient data provided for retryPhoneNumber method.');

            //Verify details and apply defaults
            User runningUser; 
            if(agentId == null){
                runningUser  = [Select Id, NVMContactWorld__NVM_Agent_Id__c, FirstName, LastName From User Where Id =:UserInfo.getUserId()];
                agentId = runningUser.NVMContactWorld__NVM_Agent_Id__c;
            }else{
                runningUser = [Select Id, NVMContactWorld__NVM_Agent_Id__c, FirstName, LastName From User Where NVMContactWorld__NVM_Agent_Id__c = :agentId];
            } 

            //Query Account related to opp and verify phone number 
            String query = 'Select Id, FirstName, LastName, PersonIndividual.Weekly_Newsletter__c, PersonIndividual.Data_Audit_Last_Completed__c, PersonIndividual.LastEmailSubscriptionStatusChangeDT__c ';
            query = query+' From Account Where IsPersonAccount = true and (PersonMobilePhone =:customerNumber or PersonOtherPhone = :customerNumber or PersonHomePhone = :customerNumber or Phone = :customerNumber) ';
            query = query+' and Id In(Select AccountId From Opportunity Where Id =:oppId)';

            List<Account> accounts = Database.query(query);
            if(accounts.size()==0) return new TrackingData('No match found for the in-focus Opportunity\'s Account');
            if(accounts.size()>1) return new TrackingData('Exiting. More than one Account with a matching phone number has been identified');

            Account acc = accounts[0];

            //Exclude if the are already opted in or recently opted out or been audited
            if(acc.PersonIndividual.Weekly_Newsletter__c) return new TrackingData('Customer already opted in > '+acc.FirstName+' '+acc.LastName+' ('+acc.Id+')');
            if(acc.PersonIndividual.Data_Audit_Last_Completed__c > System.today().addDays(-90)) return new TrackingData('Customer was recently audited > '+acc.FirstName+' '+acc.LastName+' ('+acc.Id+')');
            
            list<IndividualHistory> indHist = [Select Id, IndividualId, OldValue, NewValue From IndividualHistory Where Field = :weeklyNewsletterFieldName and CreatedDate >= LAST_90_DAYS and IndividualId = :acc.PersonIndividualId Order By Createddate DESC Limit 1];
            if(indHist != null && indHist.size()>0 && indHist[0].NewValue == false){
                return new TrackingData('Customer recently opted out > '+acc.FirstName+' '+acc.LastName+' ('+acc.Id+')');
            }            

            //Exit if the prompt has already been sent to the user (and is still visible)
            if([Select Count() From ActOnIt__MessageRecipient__c Where ActOnIt__RecordId__c = :oppId and OwnerId =:UserInfo.getUserId() and ActOnIt__IsClosed__c = false and ActOnIt__MessageType__r.ActOnIt__DeveloperName__c =:messageTypeDeveloperName]>0) return new TrackingData('A prompt has already been delivered to the agent for this customer record');

            //Post a Message
            if(customMessage != null){ 
                if(customMessage.containsIgnoreCase('[!userFirstName]')) customMessage = customMessage.replace('[!userFirstName]',runningUser.FirstName);
                if(customMessage.containsIgnoreCase('[!userLastName]')) customMessage = customMessage.replace('[!userLastName]',runningUser.LastName);
                if(customMessage.containsIgnoreCase('[!clientFirstName]')) customMessage = customMessage.replace('[!clientFirstName]',acc.FirstName);
                if(customMessage.containsIgnoreCase('[!clientLastName]')) customMessage = customMessage.replace('[!clientLastName]',acc.LastName);
            }

            //Send message via Act On It
            ActOnIt.ActOnItMessageManager.PassOrFail publishResult = sendMessage(runningUser.Id,messageTypeDeveloperName,customMessage,oppId);
            if(!publishResult.isSuccess){
                return new TrackingData('Message Publish Failure: '+publishResult.message);
            }else{
                return new TrackingData('Message Published');
            } 
        } catch (Exception e) {
            Golfbreaks.PlatformLogManager.logExceptions(e,'CallTrackingUtilityController','retryPhoneNumber');
            return new TrackingData('ERROR > '+e.getMessage()+'-'+e.getStackTraceString());
        }
    }

    public static ActOnIt.ActOnItMessageManager.PassOrFail sendMessage(Id recipientId, String messageTypeDevName, String customMessage, Id recordId){
        
        List<ActOnIt.ActOnItMessageManager.SingleMessageWrapper> messages = new List<ActOnIt.ActOnItMessageManager.SingleMessageWrapper>();
        ActOnIt.ActOnItMessageManager.SingleMessageWrapper message; 
            message = new ActOnIt.ActOnItMessageManager.SingleMessageWrapper(
                messageTypeDevName, 
                customMessage, 
                new List<Id>{recordId},
                new List<Id>{recipientId}, 
                null, 
                'CallTrackingUtilityController', 
                null
        );
        messages.add(message);
                
        return ActOnIt.ActOnItMessageManager.validateAndPublishMessages(messages,true)[0];
    }

    public Class ResponseData{
        public List<TrackingDetail> items;
    }

    public Class TrackingDetail{
        public String agentId;
        public List<Interaction> interaction;
    }
 
    public Class Interaction{
        public String since;
        public String medium;
        public String direction;
        public String state;
    }
}