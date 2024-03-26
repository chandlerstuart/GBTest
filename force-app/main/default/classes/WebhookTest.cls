/*
Name: WebhookTest.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Test suite for Webhook callback functions.

Coverage for classes below (target 85%):
WebhookResource.cls : 80%
WebhookManager.cls : 66%

TODO:
[ ] negative test cases to be added once response codes sorted out.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-12-23  Initial development.
1.1  Mark Cane&    2019-12-27  Postive end-to-end tests added.
1.2  Mark Cane&    2020-03-02  Added singleTestCase3-5.
1.3  J Radcliffe   2023-02-09  Added singleTestCase6.
*/
@isTest
public with sharing class WebhookTest {
    
    /*
    Test cases:
        singleTestCase1 - ApexRest. Webhook Type = [Id Format] - customer-update-idf-test.
        singleTestCase2 - ApexRest. Webhook Type = [Request Handler] - customer-update-rh-test.
        singleTestCase3 - ApexRest. Webhook Type = [Id Format] - customer-update-idf-test - DET FlowResponseHandler.
        singleTestCase4 - ApexRest. Webhook Type = [Flow Request Handler] - customer-update-frh-test.
        singleTestCase5 - ApexRest. Webhook Type = [Id Format] [IsAsyncCallback=true] - customer-update-ida-test.
        singleTestCase6 - ApexRest. Webhook Type = [Flow Request Handler + Apex Defined Data Type] - customer-update-adt-frh-test
    */
    
    /* **/
    static testMethod void singleTestCase1() {
        // Test case 1 : ApexRest. Webhook Type = [Id Format] - customer-update-idf-test.

        // inbound webhook call.
        // outbound callout via DET (mock provides a response with an Industry field value).
        // DET response handler updates the account.

        Account a = new Account();
        a.Name = 'Test Account';
        insert a;

        Test.setMock(HttpCalloutMock.class, new CallbackResponseMockImpl(a.Id));

	    RestRequest req = new RestRequest();				
	    req.requestURI = URL.getOrgDomainUrl().toExternalForm()+'/services/apexrest/CRM/v1.0/Webhook/customer-update-idf-test/'+a.Id;
	    req.httpMethod = 'POST';
	    
        RestContext.request = req;
		RestContext.response = new RestResponse();

		Test.startTest();
        WebhookResource.doPost();
        Test.stopTest();
        
        RestResponse res = RestContext.response;

        System.assertEquals(200, res.statusCode);
        //Success Response Format String=={ "LocalId" : "{0}", "LocalName" : "{1}", "CreatedBy" : "{2}", "CreatedByEmail" : "{3}" }
        System.assertEquals('{ "LocalId" : "'+a.Id+'",  "LocalName" : "'+a.Name+'", "CreatedBy" : "'+UserInfo.getName()+'", "CreatedByEmail" : "'+UserInfo.getUserEmail()+'" }', res.responseBody.toString());
        System.assertEquals('High Tech',[select Industry from Account where Id=:a.Id].Industry);
  	}
    /* */

    /* **/
    static testMethod void singleTestCase2() {
        // Test case 2 : ApexRest. Webhook Type = [Request Handler] - customer-update-rh-test.

        // inbound webhook call.
        // webhook hands-off to ApexClass for processing (mechanism intended for merge type webhooks).
        // ApexClass creates outbound callout via DET (mock provides a response with an Industry field value).
        // DET response handler updates the account.

        Account a = new Account();
        a.Name = 'Test Account';
        insert a;

        Test.setMock(HttpCalloutMock.class, new CallbackResponseMockImpl(a.Id));

	    RestRequest req = new RestRequest();				
	    req.requestURI = URL.getOrgDomainUrl().toExternalForm()+'/services/apexrest/CRM/v1.0/Webhook/customer-update-rh-test/'+a.Id;
	    req.httpMethod = 'POST';
	    
        RestContext.request = req;
		RestContext.response = new RestResponse();

		Test.startTest();
        WebhookResource.doPost();
        Test.stopTest();
        
        RestResponse res = RestContext.response;

        System.assertEquals(200, res.statusCode);
        System.assertEquals('High Tech',[select Industry from Account where Id=:a.Id].Industry);
  	}
    /* */

/* **/
    static testMethod void singleTestCase3() {
        // Test case 1 : ApexRest. Webhook Type = [Id Format] - customer-update-idf-test - DET FlowResponseHandler.

        // inbound webhook call.
        // outbound callout via DET (mock provides a response with an Industry field value).
        // DET response handler updates the account.
    
        Account a = new Account();
        a.Name = 'Test Account';
        insert a;

        Test.setMock(HttpCalloutMock.class, new CallbackResponseMockImpl2(a.Id));

	    RestRequest req = new RestRequest();				
	    req.requestURI = URL.getOrgDomainUrl().toExternalForm()+'/services/apexrest/CRM/v1.0/Webhook/customer-update-idf-flow-test/'+a.Id;
	    req.httpMethod = 'POST';
	    
        RestContext.request = req;
		RestContext.response = new RestResponse();

		Test.startTest();
        WebhookResource.doPost();
        Test.stopTest();
        
        RestResponse res = RestContext.response;

        System.assertEquals(200, res.statusCode);
        //Success Response Format String=={ "LocalId" : "{0}", "LocalName" : "{1}", "CreatedBy" : "{2}", "CreatedByEmail" : "{3}" }
        System.assertEquals('{ "LocalId" : "'+a.Id+'",  "LocalName" : "'+a.Name+'", "CreatedBy" : "'+UserInfo.getName()+'", "CreatedByEmail" : "'+UserInfo.getUserEmail()+'" }', res.responseBody.toString());
  	}
    /* */ 
    
    /* **/
    static testMethod void singleTestCase4() {
        // Test case 4 : ApexRest. Webhook Type = [Flow Request Handler] - customer-update-frh-test.

        // inbound webhook call.
        // request reshaped and handed to Flow.
        // compose success response.

        Account a = new Account();
        a.Name = 'Test Account';
        insert a;

	    RestRequest req = new RestRequest();				
	    req.requestURI = URL.getOrgDomainUrl().toExternalForm()+'/services/apexrest/CRM/v1.0/Webhook/customer-update-frh-test/'+a.Id;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"totalSize":1,"done":true,"records":[{"attributes":{"type":"Account","url":"/services/data/v47.0/sobjects/Account/'+a.Id+'"},"Id":"'+a.Id+'","Name":"Unit Testing","RecordType":{"attributes":{"type":"RecordType","url":"/services/data/v47.0/sobjects/RecordType/012b00000009VrWAAU"},"DeveloperName":"Unit_Test"}}]}');
	    
        RestContext.request = req;
		RestContext.response = new RestResponse();

		Test.startTest();
        WebhookResource.doPost();
        Test.stopTest();
        
        RestResponse res = RestContext.response;

        System.assertEquals(200, res.statusCode);
        System.assertEquals('{ "LocalId" : "'+a.Id+'",  "LocalName" : "'+a.Name+'", "CreatedBy" : "'+UserInfo.getName()+'", "CreatedByEmail" : "'+UserInfo.getUserEmail()+'" }', res.responseBody.toString());
  	}
    /* */ 
    
    /* **/
    static testMethod void singleTestCase5() {
        // Test case 5 : ApexRest. Webhook Type = [Id Format] [IsAsyncCallback=true] - customer-update-ida-test.

        // inbound webhook call.
        // @future - outbound callout via DET (mock provides a response with an Industry field value).
        //         - result returned via DET (mock provides a response with an Industry field value).

        Account a = new Account();
        a.Name = 'Test Account';
        insert a;

        Test.setMock(HttpCalloutMock.class, new CallbackResponseMockImpl(a.Id));

	    RestRequest req = new RestRequest();				
	    req.requestURI = URL.getOrgDomainUrl().toExternalForm()+'/services/apexrest/CRM/v1.0/Webhook/customer-update-ida-test/'+a.Id;
	    req.httpMethod = 'POST';
	    
        RestContext.request = req;
		RestContext.response = new RestResponse();

		Test.startTest();
        WebhookResource.doPost();
        Test.stopTest();
        
        RestResponse res = RestContext.response;

        System.assertEquals(200, res.statusCode);
        System.assertEquals('High Tech',[select Industry from Account where Id=:a.Id].Industry);
  	}
    /* */    

    static testMethod void singleTestCase6(){

        // Test case 6 : ApexRest. Webhook Type = [Id Format] [IsAsyncCallback=true] - customer-update-f-adt-rh-test	.
        String requestJSON ='{"name":"Request JSON Structure","innerObj":{"innerName":"First Entry","innerVal":99},"innerList":[{"innerName":"firstEntry","innerObj":{"innerVal":1,"innerName":"Test1"}},{"innerName":"secondEntry","innerObj":{"innerVal":2,"innerName":"Test3"}},{"innerName":"thirdEntry","innerObj":{"innerVal":3,"innerName":"Test3"}}]}';

        Test.setMock(HttpCalloutMock.class, new CallbackResponseMockImpl3());

	    RestRequest req = new RestRequest();				
	    req.requestURI = URL.getOrgDomainUrl().toExternalForm()+'/services/apexrest/CRM/v1.0/Webhook/customer-update-f-adt-rh-test/';
	    req.requestBody = Blob.valueOf(requestJSON);
        req.httpMethod = 'POST';
	    
        RestContext.request = req;
		RestContext.response = new RestResponse();

		Test.startTest();
        WebhookResource.doPost();
        Test.stopTest();
        
        RestResponse res = RestContext.response;

        System.assertEquals(200, res.statusCode);
        system.assertNotEquals(null, WebhookManager.flowADTData);

        //Confirm the request is successfully deserialized and stored as an object in the correct structure (to be successfully passed to flow)
        ADTTest testData = (ADTTest)WebhookManager.flowADTData;
        system.assertEquals(3, testData.innerList.size());
        system.assertEquals('Request JSON Structure', testData.name);

    }

    /* */

    public class CallbackResponseMockImpl implements HttpCalloutMock {

        private String responseBody;
        private Integer responseStatusCode;

        public CallbackResponseMockImpl(Id accountId){
            responseBody = '{"attributes": { "type":"Account" },"Id":"'+accountId+'","Industry":"High Tech"}';
            responseStatusCode=200;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            res.setStatusCode(responseStatusCode);
            return res;
        }
    }    

    public class CallbackResponseMockImpl2 implements HttpCalloutMock {

        private String responseBody;
        private Integer responseStatusCode;

        public CallbackResponseMockImpl2(Id accountId){

            //Id = [get>records>list],[index>0>Map],[get>Id>end]
            //Name = [get>records>list],[index>0>Map],[get>Name>end]
            //Industry = [get>records>list],[index>0>Map],[get>RecordType>Map],[get>DeveloperName>end]
            responseBody = '{"totalSize":1,"done":true,"records":[{"attributes":{"type":"Account","url":"/services/data/v47.0/sobjects/Account/'+accountId+'"},"Id":"'+accountId+'","Name":"Unit Testing","RecordType":{"attributes":{"type":"RecordType","url":"/services/data/v47.0/sobjects/RecordType/012b00000009VrWAAU"},"DeveloperName":"Unit_Test"}}]}';
            responseStatusCode=200;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            res.setStatusCode(responseStatusCode);
            return res;
        }
    }    

    public class CallbackResponseMockImpl3 implements HttpCalloutMock {

        private String responseBody;
        private Integer responseStatusCode;

        public CallbackResponseMockImpl3(){

            responseBody = null;
            responseStatusCode=200;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            res.setStatusCode(responseStatusCode);
            return res;
        }
    }    

    public class TestableRequestHandler implements IWebhookRequestHandler {
        
        public void handleRequest(RestRequest req, RestResponse res, Webhook__mdt WH){
            
            String recordIdAsString = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
            Id recordId = Id.valueOf(recordIdAsString);

            for (DataEventTypeAction.DataEventTypeActionResult detaResult : DataEventTypeAction.invokeDataEventType( new List<DataEventTypeAction.DataEventTypeActionRequest>{ new DataEventTypeAction.DataEventTypeActionRequest('Account_Retrieve_Sync_Test',recordId) })){
                res.statusCode = (detaResult.isSuccess) ? 200 : 400;
            }
        }    
    }  

    // This inner class is referenced as the ResponseHandler for the Account_Retrieve_Sync_Test DET.
    public class TestableDataEventTypeResponseHandler implements IDataEventTypeResponseHandler {
        public Boolean handleOutboundResponse(HttpResponse r){
            
            Account a = (Account)JSON.deserialize(r.getBody(), Account.class);
            update a;

            return true;
        }
    }

    //Test Apex Defined Data Types
    @TestVisible public class ADTTest{
        @AuraEnabled @invocableVariable public string name;
        @AuraEnabled @invocableVariable public ADTInner2 innerObj;
        @AuraEnabled @invocableVariable public List<ADTInner1> innerList;
    }

    public class ADTInner1{
        @AuraEnabled @invocableVariable public string innerName;
        @AuraEnabled @invocableVariable public ADTInner2 innerObj;
    }

    public class ADTInner2{
        @AuraEnabled @invocableVariable public string innerName;
        @AuraEnabled @invocableVariable public Integer innerVal;
    }
}