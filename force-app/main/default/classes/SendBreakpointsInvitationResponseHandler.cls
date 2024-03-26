/*
Name: SendBreakpointsInvitationResponseHandler
======================================================
======================================================
Purpose: Response Handler class for CHBreakpointsInvitation 
Data Event Type (Integration Framework).

//Note - Handlers are only invoked for successful callouts (no response status checks required)

1. Set the Invitation Agent & Invitation Date for reporting purposes // This works because the DET is invoked sychronously (running user is the user who triggered the invitation)
2. Update the Breakpoints Invite Email Status to 'Pending' to trigger
email send from Marketing Cloud Journey

======================================================
======================================================
History

Version		Author			Date		Detail
1.0			J Radcliffe		2022-02-07	Initial Development
*/
public with sharing class SendBreakpointsInvitationResponseHandler implements IDataEventTypeResponseHandler3{

    @TestVisible public static Boolean throwException = false;

    public static Boolean handleOutboundResponse(HttpResponse r, String reshapedResponseBody, Id outboundCalloutId, Set<Id> recordIds){
        try{
            if(recordIds != null && recordIds.size()>0){
                List<Account> accs = [Select Id, Breakpoint_Invitation_Date__pc, Breakpoints_Invitation_Agent__pc, BreakpointsInvitationEmailStatus__c From Account Where Id In :recordIds];
                if(accs != null && accs.size()>0){
                    for(Account acc : accs){
                        acc.Breakpoint_Invitation_Date__pc = System.now();
                        acc.Breakpoints_Invitation_Agent__pc = UserInfo.getUserId();
                        acc.BreakpointsInvitationEmailStatus__c = ApplicationConstant.BREAKPOINTS_INVITE_EMAIL_STATUS_PENDING;
                    }
                    update accs;//all or none = true
                    if(Test.isRunningTest() && throwException){//Force an exception to test error handling
                        String hello;
                        hello.deleteWhitespace();//Null Exception
                    }
                    return true;
                }else{
                    return false;
                }
            }else{
                return false;
            }
        }catch(Exception e){
            system.debug('Failed to update Accounts > '+e.getMessage()+' > '+e.getStackTraceString());
            return false;
        }
    }

}