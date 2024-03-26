/*
Name:  ClubhouseClientMergeResponseHandlerTest.cls
======================================================
======================================================
Purpose:Test Suite for ClubhouseClientMergeResponseHandler
-------
======================================================
======================================================

History
------- 
Ver. Author        Date         Detail
1.0  J Radcliffe   2019-10-29   Initial development
*/
@isTest
public with sharing class ClubhouseClientMergeResponseHandlerTest {

    @testSetup static void createTestData(){
        //Create a test Person Account
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        system.assertEquals(null,acc.BreakpointsAmountPending__c);
        system.assertEquals(null,acc.BreakpointsAmountAvailable__c);
        system.assertEquals(false,acc.BreakpointsMember__c);
        system.assertEquals(false,acc.Breakpoints_Invite_Sent__c);
        system.assertEquals(null,acc.Loyalty_Qualification_Date__pc);
        system.assertEquals(null,acc.Breakpoints_Expiry_Field__c);
        insert acc;
    }

    @isTest static void testResponseHandleSuccess(){
        Id sfAccountId = [Select Id From Account].Id;
        String memberStatus = ClubhouseClientMergeResponseHandler.membershipStatusMember;
        Integer availablePoints = 400;
        Integer pendingPoints = 150; 
        Date qualificationDate = system.today().addDays(-100);
        Date expirationDate = system.today().addDays(100);
        HttpResponse res = new HttpResponse();
        res.setBody(JSON.serialize(new ClubhouseClientMergeResponseHandler.ClubhouseMergeClientResponse(sfAccountId,true,new ClubhouseClientMergeResponseHandler.LoyaltyTransactionPosition(memberStatus,availablePoints,pendingPoints,qualificationDate,expirationDate))));
        res.setStatus('200');
        
        test.startTest();
            Boolean successOrFail = ClubhouseClientMergeResponseHandler.handleOutboundResponse(res);
        test.stopTest();

        Account acc = [Select Id, BreakpointsAmountPending__c, BreakpointsAmountAvailable__c, BreakpointsMember__c, Breakpoints_Invite_Sent__c, Loyalty_Qualification_Date__pc, Breakpoints_Expiry_Field__c From Account];
        //Confirm the Data has been successfully set
        system.assertEquals(pendingPoints,acc.BreakpointsAmountPending__c);
        system.assertEquals(availablePoints,acc.BreakpointsAmountAvailable__c);
        system.assertEquals(true,acc.BreakpointsMember__c);
        system.assertEquals(true,acc.Breakpoints_Invite_Sent__c);
        system.assertEquals(qualificationDate,acc.Loyalty_Qualification_Date__pc);
        system.assertEquals(expirationDate,acc.Breakpoints_Expiry_Field__c);
        system.assertEquals(true,successOrFail);
    }

    @isTest static void testResponseHandleException(){

        system.assertEquals(0,[Select Id From Golfbreaks__PlatformLog__c].size());

        Id sfAccountId = [Select Id From Account].Id;
        String memberStatus = ClubhouseClientMergeResponseHandler.membershipStatusMember;
        Integer availablePoints = 400;
        Integer pendingPoints = 150; 
        Date qualificationDate = system.today().addDays(-100);
        Date expirationDate = system.today().addDays(100);
        HttpResponse res = new HttpResponse();
        res.setBody(JSON.serialize(new ClubhouseClientMergeResponseHandler.ClubhouseMergeClientResponse(sfAccountId,true,new ClubhouseClientMergeResponseHandler.LoyaltyTransactionPosition(memberStatus,availablePoints,pendingPoints,qualificationDate,expirationDate))));
        res.setStatus('200');
        
        test.startTest();
            ClubhouseClientMergeResponseHandler.throwException = true;//Throw an exception on record update
            Boolean successOrFail = ClubhouseClientMergeResponseHandler.handleOutboundResponse(res);
        test.stopTest();

        Account acc = [Select Id, BreakpointsAmountPending__c, BreakpointsAmountAvailable__c, BreakpointsMember__c, Breakpoints_Invite_Sent__c, Loyalty_Qualification_Date__pc, Breakpoints_Expiry_Field__c From Account];
        system.assertEquals(false,successOrFail);//Confirm the failure has been returned
        //Confirm no Data changes have been made
        system.assertEquals(null,acc.BreakpointsAmountPending__c);
        system.assertEquals(null,acc.BreakpointsAmountAvailable__c);
        system.assertEquals(false,acc.BreakpointsMember__c);
        system.assertEquals(false,acc.Breakpoints_Invite_Sent__c);
        system.assertEquals(null,acc.Loyalty_Qualification_Date__pc);
        system.assertEquals(null,acc.Breakpoints_Expiry_Field__c);

        //Confirm the Exception has been logged
        Golfbreaks__PlatformLog__c log = [Select Id, Golfbreaks__Message__c From Golfbreaks__PlatformLog__c];
        system.assertEquals(true,log.Golfbreaks__Message__c.contains(ClubhouseClientMergeResponseHandler.exceptionError));

    }    

    @isTest static void testResponseHandlerRecordLockRetry(){
        Id sfAccountId = [Select Id From Account].Id;
        String memberStatus = ClubhouseClientMergeResponseHandler.membershipStatusMember;
        Integer availablePoints = 400;
        Integer pendingPoints = 150; 
        Date qualificationDate = system.today().addDays(-100);
        Date expirationDate = system.today().addDays(100);
        HttpResponse res = new HttpResponse();
        res.setBody(JSON.serialize(new ClubhouseClientMergeResponseHandler.ClubhouseMergeClientResponse(sfAccountId,true,new ClubhouseClientMergeResponseHandler.LoyaltyTransactionPosition(memberStatus,availablePoints,pendingPoints,qualificationDate,expirationDate))));
        res.setStatus('200');
        
        test.startTest();
            ClubhouseClientMergeResponseHandler.throwException = true;//Throw an exception on record update
            ClubhouseClientMergeResponseHandler.exceptionError = ClubhouseClientMergeResponseHandler.lockError;//Error is due to record locking
            Boolean successOrFail = ClubhouseClientMergeResponseHandler.handleOutboundResponse(res);
        test.stopTest();

        Account acc = [Select Id, BreakpointsAmountPending__c, BreakpointsAmountAvailable__c, BreakpointsMember__c, Breakpoints_Invite_Sent__c, Loyalty_Qualification_Date__pc, Breakpoints_Expiry_Field__c From Account];
        
        system.assertEquals(false,successOrFail);//Confirm the first attempt failed
        //Confirm the Data has been successfully set
        system.assertEquals(pendingPoints,acc.BreakpointsAmountPending__c);
        system.assertEquals(availablePoints,acc.BreakpointsAmountAvailable__c);
        system.assertEquals(true,acc.BreakpointsMember__c);
        system.assertEquals(true,acc.Breakpoints_Invite_Sent__c);
        system.assertEquals(qualificationDate,acc.Loyalty_Qualification_Date__pc);
        system.assertEquals(expirationDate,acc.Breakpoints_Expiry_Field__c);
        
    }

}