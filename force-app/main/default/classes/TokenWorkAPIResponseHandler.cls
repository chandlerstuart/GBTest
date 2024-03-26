/*
Name:  TokenWorkAPIResponseHandler.cls
======================================================
======================================================
Purpose:
-------
Response handler (local IFreamework Plugin) callouts to the Token Work API. Responsible
for dynamically setting the PublicId__c field with the value returned by the API.

Design Notes - 

The public id is a secure unique identifier for the record that can be safely 
exposed to customers (e.g. within a portal url). The Public Id is created by the Enterprise API. 
It is only retrieved and stored in SF for select Objects (for use within links managed in SF) however, 
for security purposes, the Enterprise API will create and house a public id for every Salesforce record 
that is retrieved and (potentially) exposed to customers or client applications.


The Token Work API handles single record requests only, so the response handler 
can expect one record and one public record Id in the response body

This handler is dynamic in the sense that it can be used for all Object Types. 
However, it currently expects the field API name to be consistent (PublicId__c)
======================================================
====================================================== 
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-05-11  Initial development.
1.1  J Radcliffe   2022-05-31  Add support for retries following a locking error.
*/
public with sharing class TokenWorkAPIResponseHandler implements IDataEventTypeResponseHandler3 {

    @TestVisible
    public static Boolean throwException = false;//1.1+
    @TestVisible
    public static String exceptionError;//1.1+
    @TestVisible
    public static final String lockError = 'UNABLE_TO_LOCK_ROW';//1.1+

    public static Boolean handleOutboundResponse(HttpResponse r, String reshapedResponseBody, Id outboundCalloutId, Set<Id> recordIds){

        //Verify one (and only one record id is passed)
        if(recordIds == null){Golfbreaks.PlatformLogManager.logCustomMessage('No records were passed to the Custom Apex Response Handler.','No Record Ids','TokenWorkAPIResponseHandler','handleOutboundResponse',null);return false;}
        if(recordIds.size()>1){Golfbreaks.PlatformLogManager.logCustomMessage('More than one record was passed to the Custom Apex Response Handler. Calls to the Token Work API return one Id, so only single callouts (per record) are supported.','Multiple Records Detected (Expected 1)','TokenWorkAPIResponseHandler','handleOutboundResponse',null);return false;}

        Id recordId = new List<Id>(recordIds)[0];

        try{
            //Verify the response contains a (public id) value
            if(r.getBody() == null || String.isBlank(String.valueOf(r.getBody()))){Golfbreaks.PlatformLogManager.logCustomMessage('No Public Id was returned in the response body.','Missing Public Id','TokenWorkAPIResponseHandler','handleOutboundResponse',null);return false;}
            
            //Update Public Record Id on related record
            sObject record = Schema.getGlobalDescribe().get(String.valueOf(recordId.getSobjectType())).newSObject(recordId);
            record.put('PublicId__c',r.getBody());
            if(throwException) throw new TestCodeException(exceptionError);
            update record;
            return true;
        }catch(Exception e){
            if(e.getMessage().containsIgnoreCase(lockError) && recordId != null && r.getBody() != null){//1.1+
                system.debug('Failed set Public Id > '+e.getMessage()+' > '+e.getStackTraceString()+'. Retrying...');
                system.enqueueJob(new handleOutboundResponseQueueable(r.getBody(),recordId));
            }else{
                system.debug('Failed set Public Id > '+e.getMessage()+' > '+e.getStackTraceString());
                Golfbreaks.PlatformLogManager.logExceptions(e,'TokenWorkAPIResponseHandler','handleOutboundResponse'); 
            }
            return false;
        }

    }

    public class handleOutboundResponseQueueable implements Queueable{//1.1+
        public String publicId;
        public Id recordId;

        public handleOutboundResponseQueueable(String publicId, Id recordId){
            this.publicId = publicId;
            this.recordId = recordId;
        }
        
        public void execute(QueueableContext context) {
            system.debug('Retrying the population of the public Id against the record');

            try{ 
                sObject record = Schema.getGlobalDescribe().get(String.valueOf(recordId.getSobjectType())).newSObject(recordId);
                record.put('PublicId__c',publicId);
                update record;
            }catch(Exception e){
                if(e.getMessage().containsIgnoreCase(lockError)){ 
                    system.debug('Failed set Public Id > '+e.getMessage()+' > '+e.getStackTraceString());
                    system.enqueueJob(new handleOutboundResponseQueueable(publicId,recordId));//Chain the job until the record is unlocked.
                }else{
                    system.debug('Failed set Public Id > '+e.getMessage()+' > '+e.getStackTraceString());
                    Golfbreaks.PlatformLogManager.logExceptions(e, 'TokenWorkAPIResponseHandler', 'execute (retry)');
                }
            }
        }

    }

}