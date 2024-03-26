/**
* @author -         Abrar Haq (Accenture)
* @date -           30/03/2016
* @description -    A utility class to process records of Request Queue object
* #############Change Log#############
* Modified by     Version     Change Date
* James R         1.1         08-05-2018	Added SFDCAddress variable to include when building the AccountClientRequestWrapper
* James R         1.2         11-06-2018 	Added a nullToEmpty conversion when building the AccountClientRequestWrapper to ensure values are cleared instead of ignored (by Clubhouse)
* M.Cane          1.3         21/06/2018    queryRequestQueueByRelatedObjectIds method changes to ensure that failed status RQ records do not block new queue entries.
* J Radcliffe     1.4         05/09/2018    Modified 'notifyUsers' method to expose content as labels instead of hard coded text
* J Radcliffe     1.5         29/04/2019    Explicitly setting Record Type (Request) to ensure Requests created by Automated Process are processed
**/
public with sharing class RequestQueueUtility{

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         01/04/2016
    Version -      1.0 
    Function -     Populate fields in Request Queue object to create
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static void populateRequestQueueRecords(List<Account> lstAccountsToProcess){
        if( lstAccountsToProcess.size() > 0 ){
            Set<String> setRelatedIds = new Set<String>();
            List<Request_Queue__c> lstRequestQueueRecordsToUpdate = new List<Request_Queue__c>();
            // Related_ID__c >> Request_Queue__c
            Map<String, Request_Queue__c> mapRelatedIdAndRequestQueue = new Map<String, Request_Queue__c>();

            // Get the Object Type
            Id accountRecordId = lstAccountsToProcess[0].Id;
            Schema.SObjectType objectType = accountRecordId.getSobjectType();

            // Get the custom setting values for Reuqest Queue Object Type and Priority
            Integer requestQueuePriority;
            Map<String, Integer> mapObjectTypeAndPriority = new Map<String, Integer>();             
            mapObjectTypeAndPriority = ApplicationConstant.getRequestQueueObjectPriority();
            
            // Get the Request Queue Priority based on Object Type
            if( mapObjectTypeAndPriority <> null && mapObjectTypeAndPriority.containsKey( String.ValueOf(objectType) ) ){
                requestQueuePriority = mapObjectTypeAndPriority.get( String.ValueOf(objectType) );
            }

            // Process Account records to create Request Queue object records
            for(Account accountRecord : lstAccountsToProcess){
                setRelatedIds.add( accountRecord.Id );
            }

            mapRelatedIdAndRequestQueue = queryRequestQueueByRelatedObjectIds(setRelatedIds);

            if( mapRelatedIdAndRequestQueue <> null ){            
                // Process Account records to create Request Queue object records
                for(Account accountRecord : lstAccountsToProcess){
                    // If total records for the Related Id with the record type "Request" in Request Queue object do not exist then 
                    // create a Request Queue record for that Related Id otherwise do not create it.
                    if( !mapRelatedIdAndRequestQueue.containsKey(accountRecord.Id) ){
                        Request_Queue__c requestQueueRecord = new Request_Queue__c();
                            requestQueueRecord.SObject_Name__c = String.ValueOf(objectType);
                            requestQueueRecord.Related_ID__c = accountRecord.Id;
                            if( accountRecord.Golfbreaks_Person_Id__c <> null ){
                                requestQueueRecord.External_ID__c = String.ValueOf( accountRecord.Golfbreaks_Person_Id__c );
                            }
                            if( requestQueuePriority <> null ){
                                requestQueueRecord.Priority__c = String.ValueOf( requestQueuePriority );
                            }
                            requestQueueRecord.Request_Status__c = ApplicationConstant.REQUEST_QUEUE_STATUS_WAITING;
                        lstRequestQueueRecordsToUpdate.add(requestQueueRecord);
                   }
                }
            }
            
            if( lstRequestQueueRecordsToUpdate.size() > 0 ){
                createRequestQueueRecord(lstRequestQueueRecordsToUpdate);
            }
        }        
    }

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         01/04/2016
    Version -      1.0 
    Function -     Create Request Queue object records
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/    
    public static void createRequestQueueRecord(List<Request_Queue__c> lstRequestQueueRecordsToUpdate){
        // Update Request Queue object records
        if( lstRequestQueueRecordsToUpdate.size() > 0 ){
            Schema.SObjectField requestQueueIdField = Request_Queue__c.Fields.Id;
            Database.UpsertResult[] lstUpsertedRequestQueueRecords = Database.Upsert(lstRequestQueueRecordsToUpdate, requestQueueIdField, false);
            
            for(Integer i=0; i<lstUpsertedRequestQueueRecords.size(); i++){
                Database.UpsertResult result = lstUpsertedRequestQueueRecords[i];
                
                if(lstUpsertedRequestQueueRecords.get(i).isSuccess()){
                    System.Debug('>> Success : lstUpsertedRequestQueueRecords.get(i).getId() <<'+lstUpsertedRequestQueueRecords.get(i).getId() );
                }
                else{
                    List<Database.Error> lstErrors = result.getErrors();
                    for(Integer j=0; j< lstErrors.size(); j++){       
                        String errorDescription = '';
                        errorDescription += ApplicationConstant.GENERAL_EXCEPTION_GET_STATUS_CODE +' '+ lstErrors.get(j).getStatusCode() + '\n';
                        errorDescription += ApplicationConstant.GENERAL_EXCEPTION_GET_FIELDS +' '+ lstErrors.get(j).getFields() + '\n';
                        errorDescription += ApplicationConstant.GENERAL_EXCEPTION_GET_ERROR_MESSAGE +' '+ lstErrors.get(j).getMessage() + '\n';
                        System.Debug('>> Error : errorDescription <<'+errorDescription );
                        System.Debug('>> Error : lstUpsertedRequestQueueRecords.get(i).getId() <<'+lstUpsertedRequestQueueRecords.get(i).getId() );
                        System.Debug('>> Error : lstRequestQueueRecordsToUpdate[i].Id <<'+lstRequestQueueRecordsToUpdate[i].Id );
                    }
                }
            }
        }
    }

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         12/04/2016
    Version -      1.0 
    Function -     Query Request Queue object using Related_ID__c
    #############Change Log#############
    Modified by     Version     Change Date
    * M.Cane        1.3         21/06/2018  Changes to ensure that failed status RQ records do not block new queue entries.
    ****************************************************************************************/
    public static Map<String, Request_Queue__c> queryRequestQueueByRelatedObjectIds(Set<String> setRelatedIds){
        // Request Queue record type : Request
        Id recordTypeRequestQueueRequestId = ApplicationConstant.getRecordTypeId( ApplicationConstant.OBJECT_TYPE_REQUEST_QUEUE, ApplicationConstant.RECORD_TYPE_REQUEST_QUEUE_REQUEST );
        // Related_ID__c >> Request_Queue__c
        Map<String, Request_Queue__c> mapRelatedIdAndRequestQueue = new Map<String, Request_Queue__c>();

        if( setRelatedIds.size() > 0 ){
            for(Request_Queue__c requestQueueRecord : [SELECT Id, Related_ID__c FROM Request_Queue__c 
            												WHERE Related_ID__c IN :setRelatedIds AND RecordTypeId = :recordTypeRequestQueueRequestId
            												AND Request_Status__c<>:ApplicationConstant.REQUEST_QUEUE_STATUS_FAILED]){//1.3
                mapRelatedIdAndRequestQueue.put(requestQueueRecord.Related_ID__c, requestQueueRecord);                
            }            
        }
        return mapRelatedIdAndRequestQueue;        
    }

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         30/03/2016
    Version -      1.0 
    Function -     Run the Batch class of Request Queue object
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static void runRequestQueueBatch(){
        // Request Queue record type : Request
        Id recordTypeRequestQueueRequestId = ApplicationConstant.getRecordTypeId( ApplicationConstant.OBJECT_TYPE_REQUEST_QUEUE, ApplicationConstant.RECORD_TYPE_REQUEST_QUEUE_REQUEST );
        List<AsyncApexJob> lstRequestQueueBatchJobs = new List<AsyncApexJob>();
        // Remaining Number of Records to process
        // If it equals to 0 then do not run batch process
        // If it is greather than 0 then check the batch class
        Integer remainingRequestQueueRecords = [Select Id FROM Request_Queue__c WHERE RecordTypeId = :recordTypeRequestQueueRequestId AND Request_Status__c IN :ApplicationConstant.CUSTOM_SETTING_REQUEST_QUEUE_STATUS_SETTING.keySet()].size();

        if( remainingRequestQueueRecords > 0 ){
            lstRequestQueueBatchJobs = [SELECT Id, ApexClass.Name FROM AsyncApexJob WHERE ApexClass.Name = :ApplicationConstant.APEX_CLASS_REQUEST_QUEUE_BATCH AND Status IN :ApplicationConstant.SET_ASYNC_APEX_JOB_STATUS];
            // Check the batch class, Whether the batch class of Request Queue is running or not.
            // If it is then do not run batch again.
            // If it is already process / ran then run the batch class again
            if( lstRequestQueueBatchJobs.size() > 0 ){

            }
            else{
                RequestQueueBatch executeRequestQueueBatch = new RequestQueueBatch();
                database.executebatch( executeRequestQueueBatch );
            }
        }
    }

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         31/03/2016
    Version -      1.0 
    Function -     Build the query of Request Queue object
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String buildRequestQueueQuery(){
        String commaSeperatedStatusValues = '';
        String requestQueueStatusValues = '';
        String soql = '';
        String requestQueueFields = '';
        Integer numberOfRequestQueueRecordsToProcess = ApplicationConstant.NUMBER_OF_RECORDS_REQUEST_QUEUE_TO_PROCESS;
        Id recordTypeRequestQueueRequestId = ApplicationConstant.getRecordTypeId( ApplicationConstant.OBJECT_TYPE_REQUEST_QUEUE, ApplicationConstant.RECORD_TYPE_REQUEST_QUEUE_REQUEST );
        Set<String> setRequestQueueFields = Request_Queue__c.getSObjectType().getDescribe().fields.getMap().keySet();
        // Get Request Queue Status values to process records
        Set<String> setRequestQueueStatusToProcess = ApplicationConstant.CUSTOM_SETTING_REQUEST_QUEUE_STATUS_SETTING.keySet();

        for(String requestQueueFieldAPIName : setRequestQueueFields){
            if( requestQueueFields == '' ){
                requestQueueFields += requestQueueFieldAPIName;
            }
            else{
                requestQueueFields += ',' + requestQueueFieldAPIName;
            }                    
        }

        // Build a string for list of Status to process
        for(String requestQueueStatus : setRequestQueueStatusToProcess){
            if( commaSeperatedStatusValues == '' ){
                commaSeperatedStatusValues += '\'' + requestQueueStatus + '\'';
            }
            else{
                commaSeperatedStatusValues += ',' +  '\'' + requestQueueStatus + '\'';
            } 
        }

        requestQueueStatusValues = '(' + commaSeperatedStatusValues + ')';

        soql = 'SELECT ';
        soql += requestQueueFields;
        soql += ' FROM Request_Queue__c ';
        soql += ' WHERE RecordTypeId = \'' + recordTypeRequestQueueRequestId + '\'';
        //soql += ' AND Request_Status__c IN (\'Retrying\', \'Waiting\')';
        //Request_Status__c IN ('Waiting','Retrying')
        soql += ' AND Request_Status__c IN ' + requestQueueStatusValues;
        soql += ' Order By Priority__c ASC ';
        soql += ' LIMIT  '+numberOfRequestQueueRecordsToProcess;

        return soql;
    }

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         31/03/2016
    Version -      1.0 
    Function -     Build AccountClientRequestWrapper class using an Account Record
    #############Change Log#############
    Modified by     Version     Change Date 
    Simon M.        1.0         2017-09-26  Added in IsPGA Flag
	James R.        1.1         2018-04-20  Added SFDCAddress variable
    ****************************************************************************************/
    public static AccountClientRequestWrapper buildAccountClientRequestWrapper(String objectRecordId){
        String soql = '';
        String objectFields = '';
        SObject sobjectRecord;
        Set<String> setObjectFields = new Set<String>();
        AccountClientRequestWrapper acctClientRequestWrapper = new AccountClientRequestWrapper(); 

        if( String.isNotBlank(objectRecordId) ){
            Id recordId = (Id)objectRecordId;

            // Get the Object Type
            Schema.SObjectType objectType = recordId.getSobjectType();
            // Process custom setting records
            for(Object_Field_Mapping__c objectFieldMapping : ApplicationConstant.CUSTOM_SETTING_OBJECT_FIELD_MAPPING_SETTING.values()){
                if( objectFieldMapping.Object_API_Name__c == String.ValueOf(objectType) ){
                    if( objectFields == '' ){
                        objectFields += objectFieldMapping.Field_API_Name__c;
                    }
                    else{
                        objectFields += ',' + objectFieldMapping.Field_API_Name__c;
                    }
                    setObjectFields.add(objectFieldMapping.Field_API_Name__c);
                }            
            }

            // Query Object and get record        
            soql = 'SELECT ' + objectFields + ' FROM ' + String.ValueOf(objectType) + ' WHERE Id =: objectRecordId ';
            sobjectRecord = Database.query(soql);
            
            // Convert general SObject to an Account
            Account accountRecord = (Account)sobjectRecord;
            if( accountRecord <> null && accountRecord.Id <> null ){
                // Populate Account Client Request Wrapper
                acctClientRequestWrapper.ClientAccountID = accountRecord.Id;
                //1.2 - performining null check (using the nullToEmpty method) to send an empty string to Clubhouse for selected fields
                acctClientRequestWrapper.Salutation = accountRecord.Salutation;
                acctClientRequestWrapper.FirstName = AccountClientRequestWrapper.nullToEmpty(accountRecord.FirstName);
                acctClientRequestWrapper.LastName = AccountClientRequestWrapper.nullToEmpty(accountRecord.LastName);
                acctClientRequestWrapper.PersonEmail = AccountClientRequestWrapper.nullToEmpty(accountRecord.PersonEmail);
                acctClientRequestWrapper.PersonMobilePhone = AccountClientRequestWrapper.nullToEmpty(accountRecord.PersonMobilePhone);
                acctClientRequestWrapper.PersonHomePhone = AccountClientRequestWrapper.nullToEmpty(accountRecord.PersonHomePhone);
                acctClientRequestWrapper.PersonOtherPhone = AccountClientRequestWrapper.nullToEmpty(accountRecord.PersonOtherPhone);
                acctClientRequestWrapper.NewsletterSignup = accountRecord.NewsletterSignUp__c;
                acctClientRequestWrapper.IsPGA = accountRecord.Is_PGA__pc;
                acctClientRequestWrapper.SalesforceAddress = new AccountClientRequestWrapper.SalesforceAddressModel(accountRecord);
                /*
                acctClientRequestWrapper.BirthDate = accountRecord.PersonBirthDate;
                acctClientRequestWrapper.SalesChannel = accountRecord.Sales_Channel__c;
                acctClientRequestWrapper.IsSensitive = accountRecord.Is_Sensitive__pc;
                acctClientRequestWrapper.IsBlacklisted = accountRecord.Is_Blacklisted__pc;
                acctClientRequestWrapper.IsPress = accountRecord.Is_Press__pc;
                acctClientRequestWrapper.IsVIP = accountRecord.Is_VIP__pc;
                
                acctClientRequestWrapper.IsDeceased = accountRecord.Is_Deceased__pc;
                acctClientRequestWrapper.BondHolder = accountRecord.Bond_Holder__pc;
                if( accountRecord.Last_Login__pc <> null ){
                    Date lastLoginDate = date.newinstance(accountRecord.Last_Login__pc.year(), accountRecord.Last_Login__pc.month(), accountRecord.Last_Login__pc.day());
                    acctClientRequestWrapper.LastLogin = lastLoginDate;
                }
                acctClientRequestWrapper.LoginCreated = accountRecord.Login_Created__pc;
                acctClientRequestWrapper.LoyaltyQualificationDate = accountRecord.Loyalty_Qualification_Date__pc;                
                */
            }
        }

        return acctClientRequestWrapper;
    }

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         31/03/2016
    Version -      1.0 
    Function -     Build JSON using AccountClientRequestWrapper
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String buildAccountClientRequestJSON(AccountClientRequestWrapper acctClientRequestWrapper){
        String acctClientRequestJSON = JSON.serializePretty(acctClientRequestWrapper);
        return acctClientRequestJSON;
    }
    
    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         31/03/2016
    Version -      1.0 
    Function -     Populate wrapper class using Response JSON
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static List<AccountClientResponseWrapper> populateAccountClientResponseWrapper(String acctClientResponseJSON){
        List<AccountClientResponseWrapper> lstAccountClientResponseWrapper = new List<AccountClientResponseWrapper>();
        if( String.isNotBlank(acctClientResponseJSON) ){
            lstAccountClientResponseWrapper = (List<AccountClientResponseWrapper>) JSON.deserialize( acctClientResponseJSON, List<AccountClientResponseWrapper>.class );            
        }
        return lstAccountClientResponseWrapper;
    }

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         31/03/2016
    Version -      1.0 
    Function -     Send the notification email to specified users after each Batch Process finish
    #############Change Log#############
    Modified by     Version     Change Date
	J Radcliffe		1.1		    05/09/2018 - Replaced Subject text with custom label
    ****************************************************************************************/
    public static void notifyUsers(Request_Queue__c requestQueueRecord){
        // getEmailInvocations() = Returns the number of email invocations (such as sendEmail) that have been called.
        // getLimitEmailInvocations() = Returns the total number of email invocation (such as sendEmail) that can be called. 
        // Send an email to specified User
        if( Limits.getLimitEmailInvocations() >= Limits.getEmailInvocations() ){
            String htmlBody = emailBody(requestQueueRecord);
            User loggedInUser = [SELECT Id FROM User WHERE Id = :Userinfo.getUserId() LIMIT 1];
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId( loggedInUser.Id );
            mail.setSubject(System.Label.Request_Queue_Failure_Notification_Subject);
            mail.setHtmlBody(htmlBody);
            //mail.setPlainTextBody('');
            //System.EmailException: SendEmail failed. First exception on row 0; first error: INVALID_SAVE_AS_ACTIVITY_FLAG, saveAsActivity must be false when sending mail to users.: [saveAsActivity, true]
            mail.saveAsActivity = false;
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });        
        }
    }

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         31/03/2016
    Version -      1.0 
    Function -     Build an Email Body to send notification
    #############Change Log#############
    Modified by     Version     Change Date
	J Radcliffe		1.1		    05/09/2018 - Replaced text with custom label
    ****************************************************************************************/
    public static String emailBody(Request_Queue__c requestQueueRecord){
        String emailBody = '';
            emailBody += String.valueOf(system.Label.Request_Queue_Failure_Notification_Body)+' <b>'+ requestQueueRecord.Name +'</b>'+
            '<br/>'+
            '<td>'+'<a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/'+requestQueueRecord.Id+'">'+'Please click here to see the details'+'</a>'+'</td>'+
            '</tr>'+
            '</table>';
        return emailBody;
    }

    /*************************************************************************************** 
    Developer -    Jerome To (Accenture)
    Date -         July 7, 2016
    Version -      1.0 
    Function -     Populate fields in Request Queue object to create for Opportunity Object
    #############Change Log#############
    Modified by     Version     Change Date     Detail
    J Radcliffe     1.5         29/04/2019      Explicitly setting Record Type (Request) to ensure Requests created by Automated Process are processed 
    ****************************************************************************************/
    public static void populateRequestQueueRecords(List<Opportunity> lstOpportunitiesToProcess){
        if( !lstOpportunitiesToProcess.isEmpty() ){
            Set<String> setRelatedIds = new Set<String>();
            List<Request_Queue__c> lstRequestQueueRecordsToUpdate = new List<Request_Queue__c>();
            // Related_ID__c >> Request_Queue__c
            Map<String, Request_Queue__c> mapRelatedIdAndRequestQueue = new Map<String, Request_Queue__c>();

            // Get the Object Type
            //Id opportunityRecordId = lstOpportunitiesToProcess[0].Id;
            Schema.SObjectType objectType = lstOpportunitiesToProcess[0].Id.getSobjectType();

            // Get the custom setting values for Reuqest Queue Object Type and Priority
            Integer requestQueuePriority;
            Map<String, Integer> mapObjectTypeAndPriority = new Map<String, Integer>();             
            mapObjectTypeAndPriority = ApplicationConstant.getRequestQueueObjectPriority();
            
            // Get the Request Queue Priority based on Object Type
            if( mapObjectTypeAndPriority <> null && mapObjectTypeAndPriority.containsKey( String.ValueOf(objectType) ) ){
                requestQueuePriority = mapObjectTypeAndPriority.get( String.ValueOf(objectType) );
            }

            // Process Opportunity records to create Request Queue object records
            for(Opportunity opportunityRecord : lstOpportunitiesToProcess){
                setRelatedIds.add( opportunityRecord.Id );
            }

            Id requestRTID = ApplicationConstant.REQ_QUEUE_RTID_REQUEST;//1.5

            mapRelatedIdAndRequestQueue = queryRequestQueueByRelatedObjectIds(setRelatedIds);

            if( mapRelatedIdAndRequestQueue <> null ){            
                // Process Opportunity records to create Request Queue object records
                for(Opportunity opportunityRecord : lstOpportunitiesToProcess){
                    // If total records for the Related Id with the record type "Request" in Request Queue object do not exist then 
                    // create a Request Queue record for that Related Id otherwise do not create it.
                    if( !mapRelatedIdAndRequestQueue.containsKey(opportunityRecord.Id) ){
                        Request_Queue__c requestQueueRecord = new Request_Queue__c();
                            requestQueueRecord.SObject_Name__c = String.ValueOf(objectType);
                            requestQueueRecord.Related_ID__c = opportunityRecord.Id;
                            if( opportunityRecord.GolfbreaksEnquiryId__c <> null ){
                                requestQueueRecord.External_ID__c = String.ValueOf( opportunityRecord.GolfbreaksEnquiryId__c );
                            }
                            if( requestQueuePriority <> null ){
                                requestQueueRecord.Priority__c = String.ValueOf( requestQueuePriority );
                            }
                            requestQueueRecord.RecordTypeId = requestRTID;//1.5
                            requestQueueRecord.Request_Status__c = ApplicationConstant.REQUEST_QUEUE_STATUS_WAITING;
                        lstRequestQueueRecordsToUpdate.add(requestQueueRecord);
                    }
                }
            }
            
            if( lstRequestQueueRecordsToUpdate.size() > 0 ){
                createRequestQueueRecord(lstRequestQueueRecordsToUpdate);
            }
        }        
    }
    
     /*************************************************************************************** 
    Developer -    Jerome To (Accenture)
    Date -         July 7, 2016
    Version -      1.0 
    Function -     Build OpportunityAccountManagerRequestWrapper class using an Opportunity Record
    #############Change Log#############
    Modified by     Version     Change Date 
    ****************************************************************************************/
    public static Map<Id, OpportunityAccountManagerRequestWrapper> buildOpportunityAccountManagerRequestWrapperMap(Set<Id> objectRecordIds){
        String soql = '';
        String objectFields = '';
        List<Opportunity> opportunityRecords = new List<Opportunity>();
        Set<Id> ownerSet = new Set<Id>();
        Map<Id, User> mapUsers = new Map<Id, User>(); 
        Set<String> setObjectFields = new Set<String>();        
        OpportunityAccountManagerRequestWrapper opptyAccountManagerRequestWrapper = new OpportunityAccountManagerRequestWrapper(); 
        Map<Id, OpportunityAccountManagerRequestWrapper> opportunityAccountManagerRequestWrapperMap = new Map<Id, OpportunityAccountManagerRequestWrapper>();
        
        
        for(Object_Field_Mapping__c objectFieldMapping : ApplicationConstant.CUSTOM_SETTING_OBJECT_FIELD_MAPPING_SETTING.values()){
            if( objectFieldMapping.Object_API_Name__c == ApplicationConstant.OBJECT_TYPE_OPPORTUNITY ){
                if( objectFields == '' ){
                    objectFields += objectFieldMapping.Field_API_Name__c;
                }
                else{
                    objectFields += ',' + objectFieldMapping.Field_API_Name__c;
                }
                setObjectFields.add(objectFieldMapping.Field_API_Name__c);
            }            
        }

        // Query Object and get record        
        soql = 'SELECT ' + objectFields + ' FROM ' + ApplicationConstant.OBJECT_TYPE_OPPORTUNITY + ' WHERE Id IN: objectRecordIds ';
        opportunityRecords = (List<Opportunity>)Database.query(soql);

        for(Opportunity opportunityRecord : opportunityRecords) {
            ownerSet.add(opportunityRecord.OwnerId);
        }

        mapUsers = new Map<Id, User>([SELECT Id, FirstName, LastName, Golfbreaks_Employee_Id__c, Email FROM User WHERE Id IN:ownerSet]);
        
        for(Opportunity opportunityRecord : opportunityRecords){
            opptyAccountManagerRequestWrapper = new OpportunityAccountManagerRequestWrapper();
            opptyAccountManagerRequestWrapper.AccountManagerEntity = 1; // defalut
            opptyAccountManagerRequestWrapper.EntityGolfbreaksID = (opportunityRecord.GolfbreaksEnquiryId__c <> null ) ? Integer.valueOf(opportunityRecord.GolfbreaksEnquiryId__c) : null;
            opptyAccountManagerRequestWrapper.NewAccountManager 
                = new OpportunityAccountManagerRequestWrapper.EmployeeModel(Integer.valueOf(mapUsers.get(opportunityRecord.OwnerId).Golfbreaks_Employee_Id__c), 
                                                                             mapUsers.get(opportunityRecord.OwnerId).Email, 
                                                                             mapUsers.get(opportunityRecord.OwnerId).FirstName, 
                                                                             mapUsers.get(opportunityRecord.OwnerId).LastName);
            opportunityAccountManagerRequestWrapperMap.put( opportunityRecord.Id ,opptyAccountManagerRequestWrapper);

        }
        
        return opportunityAccountManagerRequestWrapperMap;
    }


}