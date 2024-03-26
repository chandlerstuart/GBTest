/*
Name:  ClubhouseClientMergeResponseHandler.cls
======================================================
======================================================
Purpose:Response Handler for Clubhouse Client Merge Webhook Callouts
-------
======================================================
======================================================

History
------- 
Ver. Author        Date         Detail
1.0  J Radcliffe   2019-10-29   Initial development
1.1  J Radcliffe   2019-11-27   @future method for retries if record is locked
1.2  J Radcliffe   2019-11-28   Replacing @future with Queueable - Cannot call @future from an @future
*/
public with sharing class ClubhouseClientMergeResponseHandler implements IDataEventTypeResponseHandler{
    @TestVisible
    public static final String membershipStatusNone = 'None';
    @TestVisible
    public static final String membershipStatusInvited = 'Invited';
    @TestVisible
    public static final String membershipStatusMember = 'Member';

    @TestVisible
    public static Boolean throwException = false;
    @TestVisible
    public static String exceptionError = 'Error Updating the Account';
    @TestVisible
    public static final String lockError = 'UNABLE_TO_LOCK_ROW';//1.1+

    public static Boolean handleOutboundResponse(HttpResponse response) {

        ClubhouseMergeClientResponse res = (response.getBody()!= null)?(ClubhouseMergeClientResponse)JSON.deserialize(response.getBody(),ClubhouseMergeClientResponse.class):null;

        try{
            if(res == null) return false;
            if(res.WinningClientID != null && res.WinningClientExists){
                Account acc = [Select Id, BreakpointsMember__c, Breakpoints_Expiry_Field__c, Loyalty_Qualification_Date__pc, Breakpoints_Invite_Sent__c, BreakpointsAmountPending__c, BreakpointsAmountAvailable__c From Account Where Id =:res.WinningClientID Limit 1];
                if(acc == null || res.LoyaltyTransactionPosition == null) return false;
                DateTime qdate = res.LoyaltyTransactionPosition.QualificationDate;
                DateTime expDate = res.LoyaltyTransactionPosition.LiveExpirationDate;

                acc.BreakpointsAmountPending__c = res.LoyaltyTransactionPosition.PendingPoints;
                acc.BreakpointsAmountAvailable__c = res.LoyaltyTransactionPosition.AvailablePoints;
                acc.BreakpointsMember__c = (res.LoyaltyTransactionPosition.MembershipStatus == membershipStatusMember)?true:false;
                acc.Breakpoints_Invite_Sent__c = (res.LoyaltyTransactionPosition.MembershipStatus == membershipStatusMember || res.LoyaltyTransactionPosition.MembershipStatus == membershipStatusInvited)?true:false;
                acc.Loyalty_Qualification_Date__pc = (qDate != null)? Date.newInstance(qdate.year(),qdate.month(),qdate.day()):null;
                acc.Breakpoints_Expiry_Field__c = (expDate != null)? Date.newInstance(expDate.year(),expDate.month(),expDate.day()):null;
                if(throwException) throw new TestCodeException(exceptionError);
                update acc;
            }
        }catch(Exception e){
            if(e.getMessage().containsIgnoreCase(lockError) && res != null){//1.1+
                //handleOutboundResponseFuture(JSON.serialize(res));//1.2-
                system.enqueueJob(new handleOutboundResponseQueueable(res));//1.2+
            }else{
                PlatformLogManager.logExceptions(e, 'ClubhouseClientMergeResponseHandler', 'handleOutboundResponse');
            }
            return false;
        }
        return true;
    }

    public class ClubhouseMergeClientResponse{
        public String WinningClientID;
        public Boolean WinningClientExists;//True if there is a client with the winning client ID. If this is false then the merge will not have been attempted and the state of the other fields in the result is undocumented.
        public LoyaltyTransactionPosition LoyaltyTransactionPosition;

        public ClubhouseMergeClientResponse(String sfId, Boolean winningClientExists, LoyaltyTransactionPosition loyaltyData){
            this.WinningClientID = sfId;
            this.WinningClientExists = winningClientExists;
            this.LoyaltyTransactionPosition = loyaltyData;
        }
    }

    //The loyalty transaction state of the winning client as of the time the function returns, after the merge has completed. Always filled if WinningClientExists is true, even if no merge took place.
    public class LoyaltyTransactionPosition{
        public String MembershipStatus; //'None','Invited' or 'Member'
        public Integer AvailablePoints; //The number of points available to the client.
        public Integer PendingPoints; //The number of points pending in future transactions.
        public DateTime QualificationDate; //The date that the client joined the Breakpoints scheme or null if they have not joined the scheme.
        public DateTime LiveExpirationDate; //The date on which the entire breakpoint balance will expire.
    
        public LoyaltyTransactionPosition(String memberStatus, Integer availablePoints, Integer pendingPoints, DateTime qualificationDate, DateTime expirationDate){
            this.MembershipStatus = memberStatus;
            this.AvailablePoints = availablePoints;
            this.PendingPoints = pendingPoints;
            this.QualificationDate = qualificationDate;
            this.LiveExpirationDate = expirationDate;
        }
    }


    public class handleOutboundResponseQueueable implements Queueable{//1.2+

        public ClubhouseMergeClientResponse res;

        public handleOutboundResponseQueueable(ClubhouseMergeClientResponse response){
            this.res = response;
        }

        public void execute(QueueableContext context) {

            try{
                
                if(res == null) return;
                if(res.WinningClientID != null && res.WinningClientExists){
                    Account acc = [Select Id, BreakpointsMember__c, Breakpoints_Expiry_Field__c, Loyalty_Qualification_Date__pc, Breakpoints_Invite_Sent__c, BreakpointsAmountPending__c, BreakpointsAmountAvailable__c From Account Where Id =:res.WinningClientID Limit 1];
                    if(acc == null || res.LoyaltyTransactionPosition == null) return;
                    DateTime qdate = res.LoyaltyTransactionPosition.QualificationDate;
                    DateTime expDate = res.LoyaltyTransactionPosition.LiveExpirationDate;

                    acc.BreakpointsAmountPending__c = res.LoyaltyTransactionPosition.PendingPoints;
                    acc.BreakpointsAmountAvailable__c = res.LoyaltyTransactionPosition.AvailablePoints;
                    acc.BreakpointsMember__c = (res.LoyaltyTransactionPosition.MembershipStatus == membershipStatusMember)?true:false;
                    acc.Breakpoints_Invite_Sent__c = (res.LoyaltyTransactionPosition.MembershipStatus == membershipStatusMember || res.LoyaltyTransactionPosition.MembershipStatus == membershipStatusInvited)?true:false;
                    acc.Loyalty_Qualification_Date__pc = (qDate != null)? Date.newInstance(qdate.year(),qdate.month(),qdate.day()):null;
                    acc.Breakpoints_Expiry_Field__c = (expDate != null)? Date.newInstance(expDate.year(),expDate.month(),expDate.day()):null;
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
    
    /*@future //1.2-
    public static void handleOutboundResponseFuture(String jsonString){//1.1+
        try{
            ClubhouseMergeClientResponse res = (ClubhouseMergeClientResponse)JSON.deserialize(jsonString,ClubhouseMergeClientResponse.class);
            if(res == null) return;
            if(res.WinningClientID != null && res.WinningClientExists){
                Account acc = [Select Id, BreakpointsMember__c, Breakpoints_Expiry_Field__c, Loyalty_Qualification_Date__pc, Breakpoints_Invite_Sent__c, BreakpointsAmountPending__c, BreakpointsAmountAvailable__c From Account Where Id =:res.WinningClientID Limit 1];
                if(acc == null || res.loyaltyData == null) return;
                acc.BreakpointsAmountPending__c = res.loyaltyData.PendingPoints;
                acc.BreakpointsAmountAvailable__c = res.loyaltyData.AvailablePoints;
                acc.BreakpointsMember__c = (res.loyaltyData.MembershipStatus == membershipStatusMember)?true:false;
                acc.Breakpoints_Invite_Sent__c = (res.loyaltyData.MembershipStatus == membershipStatusMember || res.loyaltyData.MembershipStatus == membershipStatusInvited)?true:false;
                acc.Loyalty_Qualification_Date__pc = res.loyaltyData.QualificationDate;
                acc.Breakpoints_Expiry_Field__c = res.loyaltyData.LiveExpirationDate;
                update acc;
            }
        }catch(Exception e){
            //If retry fails, log exception
            PlatformLogManager.logExceptions(e, 'ClubhouseClientMergeResponseHandler', 'handleOutboundResponseFuture');
        }
    }*/

}