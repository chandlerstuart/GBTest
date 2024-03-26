/*
Name:  ClubhouseClientCopyResponseHandler.cls
======================================================
======================================================
Purpose:Response Handler for Clubhouse Client Copy Webhook Callouts
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
public without sharing class ClubhouseClientCopyResponseHandler implements IDataEventTypeResponseHandler {

    @TestVisible
    public static Boolean throwException = false;
    @TestVisible
    public static String exceptionError = 'Error Updating the Account';
    @TestVisible
    public static final String lockError = 'UNABLE_TO_LOCK_ROW';//1.1+

    public static Boolean handleOutboundResponse(HttpResponse response) {

        ClubhouseCopyClientResponse res = (response.getBody()!= null)?(ClubhouseCopyClientResponse)JSON.deserialize(response.getBody(),ClubhouseCopyClientResponse.class):null;
        if(res == null || res.SalesforceID == null || res.GolfbreaksID == null) return false;

        try{
            //Notes - Web hook response includes a single record
            //Summary - Set the Golfbreaks Person Id on the Account as a reference to the External Record
            system.debug('response.getBody: '+response.getBody());
            Account acc = [Select Id, Golfbreaks_Person_Id__c, Golfbreaks_Person_Id__pc From Account Where Id =:res.SalesforceID Limit 1];
            if(acc == null) return false;
            if(acc.Golfbreaks_Person_Id__c == null){
                acc.Golfbreaks_Person_Id__c = res.GolfbreaksID;
                acc.Golfbreaks_Person_Id__pc = res.GolfbreaksID;
                if(throwException) throw new TestCodeException(exceptionError);
                update acc;
            }
        }catch(Exception e){
            if(e.getMessage().containsIgnoreCase(lockError) && res != null){//1.1+
                //handleOutboundResponseFuture(res.SalesforceID, res.GolfbreaksID);//1.2-
                system.enqueueJob(new handleOutboundResponseQueueable(res));//1.2+
            }else{
                PlatformLogManager.logExceptions(e, 'ClubhouseClientCopyResponseHandler', 'handleOutboundResponse');
            }
            return false;
        }
        return true;
    }

    public Class ClubhouseCopyClientResponse{
        public String SalesforceID;
        public Integer GolfbreaksID;
        public String Outcome;
        public ClubhouseCopyClientResponse(String sfId, Integer chId){
            this.SalesforceID = sfId;
            this.GolfbreaksID = chId;
        }
    }

    public class handleOutboundResponseQueueable implements Queueable{//1.2+

        public ClubhouseCopyClientResponse res;

        public handleOutboundResponseQueueable(ClubhouseCopyClientResponse response){
            this.res = response;
        }

        public void execute(QueueableContext context) {

            try{
                Account acc = [Select Id, Golfbreaks_Person_Id__c, Golfbreaks_Person_Id__pc From Account Where Id =:res.SalesforceID Limit 1];
                if(acc == null) return;
                if(acc.Golfbreaks_Person_Id__c == null){
                    acc.Golfbreaks_Person_Id__c = res.GolfbreaksID;
                    acc.Golfbreaks_Person_Id__pc = res.GolfbreaksID;
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
    @future //1.2-
    public static void handleOutboundResponseFuture(String sfId, Integer gbId){//1.1+
        try{
            if(sfId == null || gbId == null) return;
            Account acc = [Select Id, Golfbreaks_Person_Id__c From Account Where Id =:sfId Limit 1];
            acc.Golfbreaks_Person_Id__c = gbId;
            update acc;
        }catch(Exception e){
            //If retry fails, log exception
            PlatformLogManager.logExceptions(e, 'ClubhouseClientCopyResponseHandler', 'handleOutboundResponseFuture');
        }
    }*/
}