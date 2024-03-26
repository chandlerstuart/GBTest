/**
* @author -         Abrar Haq (Accenture)
* @date -           30/03/2016
* @description -    A batch class to process records of Request Queue object
* #############Change Log#############
* Modified by      Version     Change Date   Detail
  James Radcliffe  1.1         02-05-19      Removing email notification on failures (to be replaced by Process Builder) - 
**/
global class RequestQueueBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful{
    global Request_Queue__c requestQueueRecordToUpdate;
    global List<Request_Queue__c> lstRequestQueueRecordsToUpdate;

    global RequestQueueBatch(){
        requestQueueRecordToUpdate = new Request_Queue__c();
        lstRequestQueueRecordsToUpdate = new List<Request_Queue__c>();        
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        // Get the Built Query of Request Queue object
        String query = RequestQueueUtility.buildRequestQueueQuery();
        return Database.getQueryLocator( query );
    }

    global void execute(Database.BatchableContext BC, List<Request_Queue__c> scope){
        String payloadJSON = '';
		HttpResponse httpResponseRequestQueue = new HttpResponse();
        Dom.Document doc = new Dom.Document();
        Map<String, String> mapHTTPHeaders = new Map<String, String>();
        //Map<String, Object> mapObjectFieldNameAndFieldValue = new Map<String, Object>();
        AccountClientRequestWrapper acctClientRequestWrapper = new AccountClientRequestWrapper();


        //Start Jerome To July 7, 2016
        Map<Id, OpportunityAccountManagerRequestWrapper> opportunityAccountManagerRequestWrapperMap = new Map<Id, OpportunityAccountManagerRequestWrapper>();
        if(!scope.isEmpty()) {
            Id recordId = String.valueOf(scope.get(0).Related_ID__c);
            if(String.valueof(recordId.getSobjectType()) == 'Opportunity') {
                Set<Id> opportunityIds = new Set<Id>();
                for(Request_Queue__c requestQueueRecord : scope) {
                    if(String.isNotBlank(requestQueueRecord.Related_ID__c)){
                        opportunityIds.add(requestQueueRecord.Related_ID__c);
                    }
                }            
                opportunityAccountManagerRequestWrapperMap = RequestQueueUtility.buildOpportunityAccountManagerRequestWrapperMap(opportunityIds);
            }
        }
        //End Jerome To July 7, 2016

        try{    
    		for(Request_Queue__c requestQueueRecord : scope) {
    		    requestQueueRecordToUpdate = requestQueueRecord;

                // Get the Object Type for "SObject_Name__c" field
                Id recordId = requestQueueRecord.Related_ID__c;
                Schema.SObjectType objectType = recordId.getSobjectType();
                
                if(String.valueof(objectType) == ApplicationConstant.OBJECT_TYPE_OPPORTUNITY){
                    payloadJSON = JSON.serializePretty(opportunityAccountManagerRequestWrapperMap.get(requestQueueRecordToUpdate.Related_ID__c));
                } else{                
                    // Get the Object Type, Query particular object record using "Related_ID__c" and get a map in "Object Field API Name"
                    // its associated "Field Value"
                    acctClientRequestWrapper = RequestQueueUtility.buildAccountClientRequestWrapper( requestQueueRecordToUpdate.Related_ID__c );
                    // Get the JSON for the Pay Laod
                    payloadJSON = RequestQueueUtility.buildAccountClientRequestJSON( acctClientRequestWrapper );                
                }

                requestQueueRecordToUpdate.Request_Payload__c = payloadJSON;
                requestQueueRecordToUpdate.Processed_on_date__c = System.today();
                //requestQueueRecordToUpdate.Response_time__c = 
    
                // Do Callout to an external system of Golfbreaks "Club House"
                if( String.isNotBlank( payloadJSON ) ){
                    requestQueueRecordToUpdate.Request_Payload__c = payloadJSON;
                    // Do HTTP Callout using "Named Credential: Request_Queue_Credentials"
                    //httpResponseRequestQueue = APIUtility.callOutPost( ApplicationConstant.NAMED_CREDENTIAL_REQUEST_QUEUE, payloadJSON, APIUtility.BodyType.JSON, mapHTTPHeaders );
                    httpResponseRequestQueue = APIUtility.callOutPost( ((String.valueof(objectType) == ApplicationConstant.OBJECT_TYPE_OPPORTUNITY) ? ApplicationConstant.CHANGED_ACCOUNT_MANAGER_REQUEST_QUEUE : ApplicationConstant.NAMED_CREDENTIAL_REQUEST_QUEUE) , payloadJSON, APIUtility.BodyType.JSON, mapHTTPHeaders );
                }
                
                // Response in Success
                if( APIUtility.setPositiveStatuses.contains( httpResponseRequestQueue.getStatusCode() ) ){
                    // Set Status to "Success"
                    requestQueueRecordToUpdate.Request_Status__c = ApplicationConstant.REQUEST_QUEUE_STATUS_SUCCESS;
                    // Change the Record Type of Request Queue object to "Log"
                    requestQueueRecordToUpdate.RecordTypeId = ApplicationConstant.getRecordTypeId( ApplicationConstant.OBJECT_TYPE_REQUEST_QUEUE, ApplicationConstant.RECORD_TYPE_REQUEST_QUEUE_LOG );
                }
                else{
                    if( requestQueueRecordToUpdate.Retry__c < ApplicationConstant.MAX_NUMBER_OF_RETRY_REQUEST_QUEUE ){
                        // Set Status to "Retrying"
                        requestQueueRecordToUpdate.Request_Status__c = ApplicationConstant.REQUEST_QUEUE_STATUS_RETRYING;
                        // Increment Retry Count
                        if( requestQueueRecordToUpdate.Retry__c == null ){
                            requestQueueRecordToUpdate.Retry__c = 1;
                        }
                        else{
                            requestQueueRecordToUpdate.Retry__c = requestQueueRecordToUpdate.Retry__c + 1;
                        }
                    }
                    else{
                        // Set Status to "Failed"
                        requestQueueRecordToUpdate.Request_Status__c = ApplicationConstant.REQUEST_QUEUE_STATUS_FAILED;
                        // Send Notification Email to specified Users
                        //RequestQueueUtility.notifyUsers(requestQueueRecordToUpdate); <-- 1.1. Comment Out
                        // Change the Record Type of Request Queue object to "Log"
                        requestQueueRecordToUpdate.RecordTypeId = ApplicationConstant.getRecordTypeId( ApplicationConstant.OBJECT_TYPE_REQUEST_QUEUE, ApplicationConstant.RECORD_TYPE_REQUEST_QUEUE_LOG );
                    }
                }
    
                // Populate Request Queue object fields
                if( httpResponseRequestQueue <> null ){
                    String responseBody = JSON.serializePretty( httpResponseRequestQueue.getBody() );
                    requestQueueRecordToUpdate.Response_Message__c = httpResponseRequestQueue.toString();
                    requestQueueRecordToUpdate.Response_Payload__c = responseBody;//String.ValueOf( httpResponseRequestQueue.getBody() );
                    requestQueueRecordToUpdate.Response_Status_code__c = String.ValueOf( httpResponseRequestQueue.getStatusCode() );
                }

                lstRequestQueueRecordsToUpdate.add( requestQueueRecordToUpdate );
    		}
    		
    		// Update Request Queue object records
    		if( lstRequestQueueRecordsToUpdate.size() > 0 ){
                RequestQueueUtility.createRequestQueueRecord(lstRequestQueueRecordsToUpdate);
    		}
        }
        catch(System.Exception ex){
            System.Debug('>>Exception getMessage<<'+ex.getMessage());
            System.Debug('>>Exception getLineNumber<<'+ex.getLineNumber());
            System.Debug('>>Exception getTypeName<<'+ex.getTypeName());
            System.Debug('>>Exception httpResponseRequestQueue.toString<<'+httpResponseRequestQueue.toString());
            System.Debug('>>Exception httpResponseRequestQueue.getBody<<'+httpResponseRequestQueue.getBody());
            System.Debug('>>Exception httpResponseRequestQueue.getStatusCode<<'+httpResponseRequestQueue.getStatusCode());

            // Change the Record Type of Request Queue object to "Log"
            requestQueueRecordToUpdate.RecordTypeId = ApplicationConstant.getRecordTypeId( ApplicationConstant.OBJECT_TYPE_REQUEST_QUEUE, ApplicationConstant.RECORD_TYPE_REQUEST_QUEUE_LOG );
            // Set Status to "Failed"
            requestQueueRecordToUpdate.Request_Status__c = ApplicationConstant.REQUEST_QUEUE_STATUS_FAILED;
            // Processed Date and Time
            requestQueueRecordToUpdate.Processed_on_date__c = System.today();
            //requestQueueRecordToUpdate.Response_time__c = 

            requestQueueRecordToUpdate.Request_Payload__c = payloadJSON;
            requestQueueRecordToUpdate.Response_Message__c = ex.getMessage();
            requestQueueRecordToUpdate.Response_Payload__c = String.ValueOf( httpResponseRequestQueue.getBody() );
            requestQueueRecordToUpdate.Response_Status_code__c = String.ValueOf( httpResponseRequestQueue.getStatusCode() );
            lstRequestQueueRecordsToUpdate.add(requestQueueRecordToUpdate);

    		// Update Request Queue object records
    		if( lstRequestQueueRecordsToUpdate.size() > 0 ){
                RequestQueueUtility.createRequestQueueRecord(lstRequestQueueRecordsToUpdate);
    		}

            // Send Notification Email to specified Users
            RequestQueueUtility.notifyUsers(requestQueueRecordToUpdate);
        }
    }

    global void finish(Database.BatchableContext BC){
        RequestQueueUtility.runRequestQueueBatch();
    }
    
}