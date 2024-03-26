/*
Name:  TokenWorkAPIResponseHandlerTest.cls
======================================================
======================================================
Purpose:
-------
Test Suite for TokenWorkAPIResponseHandler class
======================================================
====================================================== 
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-05-12  Initial development.
1.1  J Radcliffe   2022-05-31  New test method: testResponseHandlerRecordLockRetry
*/
@isTest
public with sharing class TokenWorkAPIResponseHandlerTest {
    
    @TestSetup static void createTestData(){
        insert new Opportunity(Name='Test Opp',StageName=ApplicationConstant.RECOMMENDATIONSTAGE,CloseDate=System.today());
    }

    //Confirm the Public Id in the response is successfully stored against the Opportunity record
    @isTest static void testResponseHandlerSuccess(){
        Opportunity opp = [Select Id, PublicId__c From Opportunity];

        String publicId = 'e52ad03d-ac0d-487f-a6f2-510d5959baf5';

        HttpResponse res = new HttpResponse();
        res.setBody(publicId);

        test.startTest();
            Boolean isSuccess = TokenWorkAPIResponseHandler.handleOutboundResponse(res, null, null, new Set<Id>{opp.Id});
        test.stopTest();

        //Confirm the Public Id is set successfully
        system.assertEquals(publicId, [Select Id, PublicId__c From Opportunity].PublicId__c);
        //Confirm the success response is returned to the framework
        system.assertEquals(true, isSuccess);
    }

    @isTest static void testResponseHandlerFail(){
        Opportunity opp = [Select Id, PublicId__c From Opportunity];

        String publicId = 'e52ad03d-ac0d-487f-a6f2-510d5959baf5';

        HttpResponse res = new HttpResponse();
        res.setBody(publicId);

        test.startTest();
            Boolean isSuccess = TokenWorkAPIResponseHandler.handleOutboundResponse(res, null, null, new Set<Id>{opp.Id,UserInfo.getUserId()});//Add a second id to cause an error
        test.stopTest();

        //Confirm the fail response is returned to the framework
        system.assertEquals(false, isSuccess);
        //Confirm the Log message was record (reporting the failure)
        system.assertEquals(1, [Select Count() From Golfbreaks__PlatformLog__c]);
    }

    //1.1+ Test retry mechanism (locking errors)
    @isTest static void testResponseHandlerRecordLockRetry(){

        Opportunity opp = [Select Id, PublicId__c From Opportunity];
        system.assertEquals(null,opp.PublicId__c);

        String publicId = 'e52ad03d-ac0d-487f-a6f2-510d5959baf5';

        HttpResponse res = new HttpResponse();
        res.setBody(publicId);
        res.setStatus('200');
        
        test.startTest();
            TokenWorkAPIResponseHandler.throwException = true;//Throw an exception on record update
            TokenWorkAPIResponseHandler.exceptionError = TokenWorkAPIResponseHandler.lockError;//Error is due to record locking
            Boolean successOrFail = TokenWorkAPIResponseHandler.handleOutboundResponse(res,null,null,new Set<Id>{opp.Id});
        test.stopTest();

        Opportunity updatedOpp = [Select Id, PublicId__c From Opportunity];
        system.assertEquals(false,successOrFail);//Confirm the first attempt failed
        system.assertEquals(publicId,updatedOpp.PublicId__c);//Confirm the Id has been successfully updated by retry attempt
    }    

}