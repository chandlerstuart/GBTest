/*
Name:  QuickCalloutButtonControllerTest.cls
======================================================
======================================================
Purpose: Test Suite for QuickCalloutButtonController.cls

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-02-04  Initial development.
*/
@isTest
public with sharing class QuickCalloutButtonControllerTest {
    
    @isTest static void testQuickCalloutButtonControllerCalloutSuccess(){

        Account a = new Account(Name='Unit test');
        insert a;

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('success'));

        test.startTest();
            QuickCalloutButtonController.ActionResult result = QuickCalloutButtonController.executeCallout(a.Id, 'Account_Update_Sync_Test');
        test.stopTest();

        system.assertEquals(true,result.isSuccess);

    }

    @isTest static void testQuickCalloutButtonControllerCalloutFailure(){

        Account a = new Account(Name='Unit test');
        insert a;

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('fail'));

        test.startTest();
            QuickCalloutButtonController.ActionResult result = QuickCalloutButtonController.executeCallout(a.Id, 'Account_Update_Sync_Test');
        test.stopTest();

        system.assertEquals(false,result.isSuccess);
        system.assertEquals('{ "message":"Something went wrong" }',result.responseBody);

    }

    @isTest static void testQuickCalloutButtonControllerCalloutInsufficientData(){

        Account a = new Account(Name='Unit test');
        insert a;

        test.startTest();
            QuickCalloutButtonController.ActionResult result = QuickCalloutButtonController.executeCallout(null, 'Account_Update_Sync_Test');
        test.stopTest();

        system.assertEquals(false,result.isSuccess);
        system.assertEquals('A record Id must be provided',result.errorMessage);

    }
    
    public class HttpResponseMockImpl implements HttpCalloutMock {
        private String responseBody;
        private Integer responseStatusCode;

        public HttpResponseMockImpl(String testCase){
            
            switch on testCase {
                when 'success' {
                    responseBody='{ "SalesforceClientID":"001b000000qDVy6AAZ", "GolfbreaksClientID":"ClubhouseIdValue" }';
                    responseStatusCode=200;
                }
                when 'fail' {
                    responseBody='{ "message":"Something went wrong" }';
                    responseStatusCode=400;
                }
            }
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            res.setStatusCode(responseStatusCode);
            return res;
        }
    }

}