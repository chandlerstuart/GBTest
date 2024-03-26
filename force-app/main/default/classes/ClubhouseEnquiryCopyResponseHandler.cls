/*
Name:  ClubhouseEnquiryCopyResponseHandler.cls
======================================================
======================================================
Purpose:Response Handler for Clubhouse Enquiry Copy Webhook Callouts
-------
======================================================
======================================================

History
------- 
Ver. Author        Date         Detail
1.0  J Radcliffe   2019-10-28   Initial development
1.1  J Radcliffe   2019-11-27   @future method for retries if record is locked
1.2  J Radcliffe   2019-11-28   Replacing @future with Queueable - Cannot call @future from an @future
*/
public without sharing class ClubhouseEnquiryCopyResponseHandler implements IDataEventTypeResponseHandler {

    @TestVisible
    public static Boolean throwException = false;
    @TestVisible
    public static String exceptionError = 'Error Updating the Account';
    @TestVisible
    public static final String lockError = 'UNABLE_TO_LOCK_ROW';//1.1+

    public static Boolean handleOutboundResponse(HttpResponse response) {

        ClubhouseCopyEnquiryResponseWrapper res = (response.getBody()!= null)?(ClubhouseCopyEnquiryResponseWrapper)JSON.deserialize(response.getBody(),ClubhouseCopyEnquiryResponseWrapper.class):null;

        try{
            //Notes - Web hook response includes a single record
            //Summary - Set the Golfbreaks Person Id on the Account as a reference to the External Record
            if(res == null || res.CopyClientResponse == null || res.CopyClientResponse.SalesforceID == null || res.CopyClientResponse.GolfbreaksID == null) return false;
            Account acc = [Select Id, Golfbreaks_Person_Id__c, Golfbreaks_Person_Id__pc From Account Where Id =:res.CopyClientResponse.SalesforceID Limit 1];
            if(acc == null) return false;
            if(acc.Golfbreaks_Person_Id__c == null){
                acc.Golfbreaks_Person_Id__c = res.CopyClientResponse.GolfbreaksID;
                acc.Golfbreaks_Person_Id__pc = res.CopyClientResponse.GolfbreaksID;
                if(throwException) throw new TestCodeException(exceptionError);
                update acc;
            }
        }catch(Exception e){
            if(e.getMessage().containsIgnoreCase(lockError) && res != null){//1.1+
                //handleOutboundResponseFuture(res.CopyClientResponse.SalesforceID, res.CopyClientResponse.GolfbreaksID);//1.2-
                system.enqueueJob(new handleOutboundResponseQueueable(res));//1.2+
            }else{
                PlatformLogManager.logExceptions(e, 'ClubhouseEnquiryCopyResponseHandler', 'handleOutboundResponse');
            }
            return false;
        }
        return true;
    }

    public Class ClubhouseCopyEnquiryResponseWrapper{
        ClubhouseClientCopyResponseHandler.ClubhouseCopyClientResponse CopyClientResponse;
        ClubhouseCopyEnquiryResponse CopyEnquiryResponse;
        public ClubhouseCopyEnquiryResponseWrapper(ClubhouseClientCopyResponseHandler.ClubhouseCopyClientResponse CopyClientResponse, ClubhouseCopyEnquiryResponse CopyEnquiryResponse){
            this.CopyClientResponse = CopyClientResponse;
            this.CopyEnquiryResponse = CopyEnquiryResponse;
        }
    }

    public Class ClubhouseCopyEnquiryResponse{
        public String SalesforceID;
        public Integer GolfbreaksID;
        public String Outcome;
    }

    public class handleOutboundResponseQueueable implements Queueable{//1.2+

        public ClubhouseCopyEnquiryResponseWrapper res;

        public handleOutboundResponseQueueable(ClubhouseCopyEnquiryResponseWrapper response){
            this.res = response;
        }

        public void execute(QueueableContext context) {

            try{
                if(res == null || res.CopyClientResponse == null || res.CopyClientResponse.SalesforceID == null || res.CopyClientResponse.GolfbreaksID == null) return;
                Account acc = [Select Id, Golfbreaks_Person_Id__c, Golfbreaks_Person_Id__pc From Account Where Id =:res.CopyClientResponse.SalesforceID Limit 1];
                if(acc == null) return;
                if(acc.Golfbreaks_Person_Id__c == null){
                    acc.Golfbreaks_Person_Id__c = res.CopyClientResponse.GolfbreaksID;
                    acc.Golfbreaks_Person_Id__pc = res.CopyClientResponse.GolfbreaksID;
                    update acc;
                }
            }catch(Exception e){
                if(e.getMessage().containsIgnoreCase(lockError) && res != null){ 
                    system.enqueueJob(new handleOutboundResponseQueueable(res));//Chain the job until the record is unlocked. Only chain if it is a record locking exception.
                }else{
                    PlatformLogManager.logExceptions(e, 'handleOutboundResponseQueueable', 'execute');
                }
            }
        }
    }

    /*
    @future 1.2-
    public static void handleOutboundResponseFuture(String sfId, Integer gbId){//1.1+
        try{
            if(sfId == null || gbId == null) return;
            Account acc = [Select Id, Golfbreaks_Person_Id__c From Account Where Id =:sfId Limit 1];
            acc.Golfbreaks_Person_Id__c = gbId;
            update acc;
        }catch(Exception e){
            //If retry fails, log exception
            PlatformLogManager.logExceptions(e, 'ClubhouseEnquiryCopyResponseHandler', 'handleOutboundResponseFuture');
        }
    }*/
}