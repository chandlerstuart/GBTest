/*
Name: SendBreakpointsInvitationResHandlerTest
======================================================
======================================================
Purpose: Test Suite for SendBreakpointsInvitationResponseHandler.cls
======================================================
======================================================
History

Version		Author			Date		Detail
1.0			J Radcliffe		2022-02-07	Initial Development
*/
@isTest
public with sharing class SendBreakpointsInvitationResHandlerTest {
    
    //Confirm the Account is successfully updated
    @isTest static void testResponseHandlerSuccess(){

        Account acc = new Account(FirstName='Test',LastName='Account');
        insert acc;

        test.startTest();
            Boolean result = SendBreakpointsInvitationResponseHandler.handleOutboundResponse(new HTTPResponse(), null, null, new Set<Id>{acc.Id});
        test.stopTest();

        system.assertEquals(true, result);
        Account accAfterUpdate = [Select Id, Breakpoint_Invitation_Date__pc, Breakpoints_Invitation_Agent__pc, BreakpointsInvitationEmailStatus__c From Account Where Id =:acc.Id];
        system.assertEquals(UserInfo.getUserId(), accAfterUpdate.Breakpoints_Invitation_Agent__pc);
        system.assertEquals(true, accAfterUpdate.Breakpoint_Invitation_Date__pc >= system.now().addMinutes(-1));//Set to now-ish
        system.assertEquals(true, accAfterUpdate.Breakpoint_Invitation_Date__pc <= system.now());//Set to now-ish
        system.assertEquals(ApplicationConstant.BREAKPOINTS_INVITE_EMAIL_STATUS_PENDING, accAfterUpdate.BreakpointsInvitationEmailStatus__c);//Set to now-ish
    }

    //Confirm failure is returned to framework (false), but no exception is thrown.
    @isTest static void testResponseHandlerFail(){

        test.startTest();
            Boolean result = SendBreakpointsInvitationResponseHandler.handleOutboundResponse(new HTTPResponse(), null, null, new Set<Id>{UserInfo.getUserId()});//Pass User Id to cause error (Expected Account Id)
        test.stopTest();

        system.assertEquals(false, result);
    }

    @isTest static void testResponseHandlerException(){

        Account acc = new Account(FirstName='Test',LastName='Account');
        insert acc;

        Boolean result;
        test.startTest();
            SendBreakpointsInvitationResponseHandler.throwException = true;
            result = SendBreakpointsInvitationResponseHandler.handleOutboundResponse(new HTTPResponse(), null, null, new Set<Id>{acc.Id});
        test.stopTest();

        system.assertEquals(false, result);

    }

}