/*
Name:  ClubhouseEnquiryCopyResponseHandlerTest.cls
======================================================
======================================================
Purpose:Test Suite for ClubhouseEnquiryCopyResponseHandler
-------
======================================================
======================================================

History
------- 
Ver. Author        Date         Detail
1.0  J Radcliffe   2019-10-29   Initial development
*/
@isTest
public with sharing class ClubhouseEnquiryCopyResponseHandlerTest {
    
    @testSetup static void createTestData(){
        //Create a test Person Account
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        system.assertEquals(null,acc.Golfbreaks_Person_Id__c);
        insert acc;
    }

    @isTest static void testResponseHandleSuccess(){
        Id sfAccountId = [Select Id From Account].Id;
        Integer chPersonId = 12345678;
        HttpResponse res = new HttpResponse();
        res.setBody(JSON.serialize(new ClubhouseEnquiryCopyResponseHandler.ClubhouseCopyEnquiryResponseWrapper(new ClubhouseClientCopyResponseHandler.ClubhouseCopyClientResponse(sfAccountId,chPersonId),null)));
        res.setStatus('200');
        
        test.startTest();
            Boolean successOrFail = ClubhouseEnquiryCopyResponseHandler.handleOutboundResponse(res);
        test.stopTest();

        Account acc = [Select Id, Golfbreaks_Person_Id__c From Account];
        system.assertEquals(chPersonId,acc.Golfbreaks_Person_Id__c);//Confirm the Id has been successfully set
        system.assertEquals(true,successOrFail);
    }

    @isTest static void testResponseHandleException(){

        system.assertEquals(0,[Select Id From Golfbreaks__PlatformLog__c].size());

        Id sfAccountId = [Select Id From Account].Id;
        Integer chPersonId = 12345678;
        HttpResponse res = new HttpResponse();
        res.setBody(JSON.serialize(new ClubhouseEnquiryCopyResponseHandler.ClubhouseCopyEnquiryResponseWrapper(new ClubhouseClientCopyResponseHandler.ClubhouseCopyClientResponse(sfAccountId,chPersonId),null)));
        res.setStatus('200');
        
        test.startTest();
            ClubhouseEnquiryCopyResponseHandler.throwException = true;//Throw an exception on record update
            Boolean successOrFail = ClubhouseEnquiryCopyResponseHandler.handleOutboundResponse(res);
        test.stopTest();

        Account acc = [Select Id, Golfbreaks_Person_Id__c From Account];
        system.assertEquals(null,acc.Golfbreaks_Person_Id__c);//Confirm the Id has not been set (due to the Exception)
        system.assertEquals(false,successOrFail);//Confirm the failure has been returned

        //Confirm the Exception has been logged
        Golfbreaks__PlatformLog__c log = [Select Id, Golfbreaks__Message__c From Golfbreaks__PlatformLog__c];
        system.assertEquals(true,log.Golfbreaks__Message__c.contains(ClubhouseEnquiryCopyResponseHandler.exceptionError));

    }    

    @isTest static void testResponseHandlerRecordLockRetry(){
        Id sfAccountId = [Select Id From Account].Id;
        Integer chPersonId = 12345678;
        HttpResponse res = new HttpResponse();
        res.setBody(JSON.serialize(new ClubhouseEnquiryCopyResponseHandler.ClubhouseCopyEnquiryResponseWrapper(new ClubhouseClientCopyResponseHandler.ClubhouseCopyClientResponse(sfAccountId,chPersonId),null)));
        res.setStatus('200');
        
        test.startTest();
            ClubhouseEnquiryCopyResponseHandler.throwException = true;//Throw an exception on record update
            ClubhouseEnquiryCopyResponseHandler.exceptionError = ClubhouseEnquiryCopyResponseHandler.lockError;//Error is due to record locking
            Boolean successOrFail = ClubhouseEnquiryCopyResponseHandler.handleOutboundResponse(res);
        test.stopTest();

        Account acc = [Select Id, Golfbreaks_Person_Id__c From Account];
        system.assertEquals(false,successOrFail);//Confirm the first attempt failed
        system.assertEquals(chPersonId,acc.Golfbreaks_Person_Id__c);//Confirm the Id has been successfully set

    }

}