/*
Name:  ActOnItWebhookRequestHandler.cls
======================================================
======================================================
Purpose: Handler class for HTTP requests from Tealium and 
facilitates the publishing of ActOnIt notifications to 
targeted recipients for web visits
-------
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2020-11-23  Initial development.
1.1  J Radcliffe   2021-02-17  Uncontacted Clients Only.
1.2  J Radcliffe   2021-04-14  Exclude notifications published between 06:30 and 06:40 pm GMT (data is loaded to Tealium causing a spike in alerts that are not true web visits)
1.3  J Radcliffe   2023-02-14  Do not publish multiple web visit alerts for the same customer within an hour.
1.4  J Radcliffe   2023-04-21  Enhancements. Exclude recently created opps & check the customer is still active on the site before notifying reps.
1.5  J Radcliffe   2023-08-17  Enhancements. Include alerts for 'Contacted' Opportunities.
*/
global class ActOnItWebhookRequestHandler implements IWebhookRequestHandler{

    @TestVisible public static final String webVisitMessageType = 'WebVisitMessageType';
    @TestVisible public static Boolean isAvailabilityCheckSuccessful = true;//1.4+
    @TestVisible public static String testAvailabilitySuccessResponse = '{"users":1}';//1.4+

    public static final String checkAvailabilityDETName = 'Proactive_Chat_Check_Availability';//1.4+
    
    Boolean isPauseWindow;//1.2+
    DateTime currentDT = system.now();//1.2+

    public void handleRequest(RestRequest req, RestResponse res, Webhook__mdt wh){
        
        try{

            isPauseWindow = (currentDT>=DateTime.newInstanceGMT(currentDT.yearGmt(), currentDT.monthGmt(), currentDT.dayGmt(), 06, 30, 00) && currentDT<=DateTime.newInstanceGMT(currentDT.yearGmt(), currentDT.monthGmt(), currentDT.dayGmt(), 06, 40, 00))?true:false;
            if(isPauseWindow){
                res.statusCode = 200;
                return;//Do not publish notifications during pause window.
            } 

            //Default res to success
            res.statusCode = (wh.SuccessResponseStatusCode__c==null)?200:Integer.valueOf(wh.SuccessResponseStatusCode__c);

            //Check to see if the Message Type exists (required for any message)
            if([Select Count() From ActOnIt__MessageType__c Where ActOnIt__DeveloperName__c =:webVisitMessageType]==0){logFailResponse(res,'Could not find Message Type: '+webVisitMessageType,wh);return;} 

            //Extract Account Id from JSON Request
            String jsonString = (req.requestBody != null)?escapeSpecialCharacters(req.requestBody.toString()):null;
            Map<String,Object> requestData = (Map<String,Object>)JSON.deserializeUntyped(jsonString);
            Id accountId = (requestData != null)?(Id)requestData.get('salesforce_id'):null;
            if(accountId == null){logFailResponse(res,'Could not retrieve Account Id from JSON Request',wh);return;}              
            
            Id uncontactedOppRTId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(ApplicationConstant.OPPORTUNITY_UNCONTACTED).getRecordTypeId();
            Id contactedOppRTId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(ApplicationConstant.OPPORTUNITY_CONTACTED).getRecordTypeId();

            //Query for an Active Sales Opportunity (assigned to an Active ActOnIt User)
            DateTime creationThreshold = System.now().addMinutes(-5);//1.4+

            String query = 'Select Id, TealiumId__c, LatestTealiumId__c, (Select Id, OwnerId, Name From Opportunities Where IsClosed = false and Owner.IsActive = true and (RecordTypeId = \''+uncontactedOppRTId+'\' or RecordTypeId = \''+contactedOppRTId+'\') and CreatedDate <=:creationThreshold ';//2.4~ creationThreshold
            if(!Test.isRunningTest()) query = query + 'and OwnerId In(Select ActOnIt__User__c From ActOnIt__UserSettings__c Where ActOnIt__AppEnabled__c = true)';//Only apply app filter in a non test context (saves overhead and the inevitable risks of having to create active app user in test context)
            query = query+' Order By CreatedDate Desc) From Account Where Id = :accountId';
            
            Account acc;
            try{
                acc = Database.query(query);
            }catch(Exception e){system.debug(e.getMessage()+'-'+e.getStackTraceString());}
            if(acc == null){logFailResponse(res,'Unrecognised Client Account (Id:'+accountId+')',wh);return;}   

            //If there is no identifiable recipient, exit returning success message
            if(acc.Opportunities == null || acc.Opportunities.size()==0){res.responseBody = Blob.valueOf('Success. No identifiable Message Recipient'); return;}
            
            String tealiumId = (requestData != null)?(String)requestData.get('tealium_id'):null;
            if(tealiumId == null || String.isBlank(tealiumId)){logFailResponse(res,'Unable to verify Tealium Id for Account (req: '+jsonString+')',wh);return;} 

            //1.4+
            //Check to see if the user (customer) is still online (with a matching tealium id). This prevents false reports of the customer being online.
            DataEventTypeAction.DataEventTypeActionRequest detar = new DataEventTypeAction.DataEventTypeActionRequest(checkAvailabilityDETName,acc.Id);
            detar.queryStringParameters = 'user='+tealiumId+'_Sarazen_Production';
            List<DataEventTypeAction.DataEventTypeActionResult> detaResults = (!Test.isRunningTest())?DataEventTypeAction.invokeDataEventType( new List<DataEventTypeAction.DataEventTypeActionRequest>{ detar }):new List<DataEventTypeAction.DataEventTypeActionResult>();
            if(Test.isRunningTest()){
                detaResults.add(new DataEventTypeAction.DataEventTypeActionResult(acc.Id,isAvailabilityCheckSuccessful));
                detaResults[0].responseBody = (isAvailabilityCheckSuccessful)?testAvailabilitySuccessResponse:null;
            }

            //1.4+
            String responseBody = (detaResults!=null && !detaResults.isEmpty() && detaResults[0].isSuccess == true && detaResults[0].responseBody != null && !String.isBlank(detaResults[0].responseBody)) ? detaResults[0].responseBody : null;
            if(responseBody == null){logFailResponse(res,'Unable to verify account is online (Id:'+accountId+')',wh);return;}
            
            //1.4+
            Map<String,Object> data = (Map<String,Object>)JSON.deserializeUntyped(responseBody);
            if(data == null || data.get('users') == null){logFailResponse(res,'Unable to verify account is online (Id:'+accountId+')',wh);return;}

            //Capture the latest Tealium Id for posting in the live chat invitation
            acc.LatestTealiumId__c = tealiumId;
            update acc;
            
            //1.4+
            if(Integer.valueOf(data.get('users')) == 0){
                res.responseBody = Blob.valueOf('Success. Client is no longer online'); 
                return;
            } 

            //Publish message to Opportunity Owner recipient
            Id messageRecipientId = (wh != null && wh.SuccessResponseFormatFields__c != null && wh.SuccessResponseFormatFields__c.contains('005'))?wh.SuccessResponseFormatFields__c:acc.Opportunities[0].OwnerId;//Workaround implemented to allow for testing with specific recipients (specify a UserId in the SuccessResponseFormatFields__c field)
            Id recordId = acc.Opportunities[0].Id;

            //1.3+ Apply dupe check
            DateTime oneHourAgo = System.now().addMinutes(-60);
            if([Select count() From ActOnIt__MessageRecipient__c Where ActOnIt__DeliveryDateTime__c >=:oneHourAgo and OwnerId = :messageRecipientId and ActOnIt__MessageType__c = :webVisitMessageType]>0){res.responseBody = Blob.valueOf('Message already sent within the past hour'); return;}

            String message = 'Your client ('+acc.Opportunities[0].Name+') is visiting the website';
            List<ActOnIt.ActOnItMessageManager.SingleMessageWrapper> messages = new List<ActOnIt.ActOnItMessageManager.SingleMessageWrapper>();
            messages.add(new ActOnIt.ActOnItMessageManager.SingleMessageWrapper(
                webVisitMessageType,
                message,
                new List<Id>{recordId},//Add link to Opp Record
                new List<Id>{messageRecipientId},//Publish Message to record owner
                null,//No exclusions required
                'Tealium Webhook',//Source (for reporting)
                system.now()//Publish immediately
            ));
            //Publish Message
            List<ActOnIt.ActOnItMessageManager.PassOrFail> results = ActOnIt.ActOnItMessageManager.validateAndPublishMessages(messages,true);

            //Return publish validation results in response
            if(results == null || results.size()==0){logFailResponse(res,'Something unexpected happened when attempting to publish the message to '+messageRecipientId,wh);return;}  
            res.statusCode = results[0].status == 'PASS'?200:400;
            res.responseBody = Blob.valueOf(results[0].message);
            return;            
        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'ActOnItWebhookRequestHandler','handleRequest');
            logFailResponse(res,'Unexpected Exception: '+e.getMessage()+'-'+e.getStackTraceString(),wh);
            return;
        }
        
    }

    private static String escapeSpecialCharacters(String jsonString){
        jsonString = jsonString.replace('\n','\\n');
        jsonString = jsonString.replace('\r','\\r');
        jsonString = jsonString.replace('\\',' ');
        jsonString = jsonString.replace(' n ','');
        jsonString = jsonString.replace('\"','"');
        jsonString = jsonString.replace('n"','"');
        jsonString = jsonString.replace('n}','}');

        return jsonString;
    }

    private static void logFailResponse(RestResponse res, String failMessage, Webhook__mdt wh){
        res.responseBody = Blob.valueOf('Request Handling Failure > '+failMessage);
        res.statusCode = wh.ErrorResponseStatusCode__c!=null?Integer.valueOf(wh.ErrorResponseStatusCode__c):400;
    }
}