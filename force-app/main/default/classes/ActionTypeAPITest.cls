/*
Name: ActionTypeAPITest.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Test suite for Action Type API functions.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-11-04  Initial development. 
*/
@isTest
public with sharing class ActionTypeAPITest {
        //1.3+
    static testMethod void singleTestCase1() {
        // Test case 1 : ApexRest. todo.

        Test.setMock(HttpCalloutMock.class, new ClubhouseClientResponseMockImpl());

	    RestRequest req = new RestRequest();				
	    req.requestURI = URL.getOrgDomainUrl().toExternalForm()+'/services/apexrest/CRM/v1.0/ActionType';  
	    req.httpMethod = 'POST';
        String jsonString = getTestCaseActionBody(1,false);
        req.requestBody = Blob.valueOf(jsonString);
	    RestContext.request = req;
		RestContext.response = new RestResponse();

		Test.startTest();
            ActionTypeAPIV1Resource.doPost();
            String json = RestContext.response.responseBody.toString();
            ActionTypeAPIV1Response response = (ActionTypeAPIV1Response)System.JSON.deserialize(json, ActionTypeAPIV1Response.class);

            system.debug('response: '+response);
		Test.stopTest();

        system.assertEquals(true, response.isSuccess);
        system.assertEquals(1, response.results.size());
        system.assertEquals(true, response.results[0].isSuccess);
        system.assertEquals(0, response.results[0].errors.size());
  	}
    /* */      

    //Helper class that builds an Enquiry Request Body
    static String getTestCaseActionBody(Integer count, Boolean isInvalid){

        List<EnquiryAPIV1Request> requestList = new List<EnquiryAPIV1Request>();
        for(integer i = 0;i<count;i++){
            EnquiryAPIV1Request req = new EnquiryAPIV1Request();
            req.actionTypeName = (isInvalid)? null : 'TestCaseAction';
            //Client
            if(req.clientDetails == null) req.clientDetails = new EnquiryAPIV1Request.ClientDetails();
            req.clientDetails.firstName = 'Test';
            req.clientDetails.lastName = 'Client'+i;
            req.clientDetails.email = 'testClient'+i+'@example.com';
            req.clientDetails.mobilePhone = '+447900000000';
            //Trip
            if(req.tripDetails == null) req.tripDetails = new EnquiryAPIV1Request.tripDetails();
            req.tripDetails.countries = new List<String>{'Belgium,Spain,France,Portugal'};
            //Task
            if(req.taskDetails == null) req.taskDetails = new EnquiryAPIV1Request.taskDetails();
            req.taskDetails.subject = 'This is a subject';
            requestList.add(req);
        }
        return JSON.serialize(requestList);
    }

    /* **/
    //1.3+
    static testMethod void negativeTestCase1() {
        // Test case 1 : ApexRest. todo.

        Test.setMock(HttpCalloutMock.class, new ClubhouseClientResponseMockImpl());

	    RestRequest req = new RestRequest();				
	    req.requestURI = URL.getOrgDomainUrl().toExternalForm()+'/services/apexrest/CRM/v1.0/ActionType';  
	    req.httpMethod = 'POST';
        String jsonString = getTestCaseActionBody(1,true); //<-- IsInvalid = true (no Action Type)
        req.requestBody = Blob.valueOf(jsonString);
	    RestContext.request = req;
        RestContext.response = new RestResponse();
		
		Test.startTest();
            ActionTypeAPIV1Resource.doPost();
            String json = RestContext.response.responseBody.toString();
            ActionTypeAPIV1Response response = (ActionTypeAPIV1Response)System.JSON.deserialize(json, ActionTypeAPIV1Response.class);         

            system.debug('response2: '+response);
		Test.stopTest();

        system.assertEquals(true, response.isSuccess);
        system.assertEquals(1, response.results.size());
        system.assertEquals(false, response.results[0].isSuccess);
        system.assertNotEquals(0, response.results[0].errors.size());
        system.assertEquals(Label.Enquiry_Validation_Error_Missing_Action_Type, response.results[0].errors[0].errorMessage);
  	}
    /* */    

    //1.3+
    static testMethod void bulkTestCase1() {
        // Test case 1 : ApexRest. todo.

        //NOTE - Currently API only supports single requests. Max number of callouts per transaction is 100.
        //Can only bulk test 100 enquiries until CH API's are bulk enabled

        Test.setMock(HttpCalloutMock.class, new ClubhouseClientResponseMockImpl());

	    RestRequest req = new RestRequest();				
	    req.requestURI = URL.getOrgDomainUrl().toExternalForm()+'/services/apexrest/CRM/v1.0/ActionType';  
	    req.httpMethod = 'POST';
        String jsonString = getTestCaseActionBody(100,false);
        req.requestBody = Blob.valueOf(jsonString);
	    RestContext.request = req;
		RestContext.response = new RestResponse();

		Test.startTest();
            ActionTypeAPIV1Resource.doPost();
            String json = RestContext.response.responseBody.toString();

            ActionTypeAPIV1Response response = (ActionTypeAPIV1Response)System.JSON.deserialize(json, ActionTypeAPIV1Response.class);

            system.debug('response: '+response);
		Test.stopTest();

                
        system.assertEquals(100, response.results.size());

        for(ActionTypeAPIV1Response.ActionTypeResult r : response.results){
            system.assertEquals(true, r.isSuccess);
            system.assertEquals(false, r.errors.size()>0);
        }
  	}

    //1.3+
    static testMethod void bulkTestCase2() {
        // Test case 1 : ApexRest. todo.

        //NOTE - Currently API only supports single requests. Max number of callouts per transaction is 100.
        //Can only bulk test 100 enquiries until CH API's are bulk enabled

        Test.setMock(HttpCalloutMock.class, new ClubhouseClientResponseMockImpl());

	    RestRequest req = new RestRequest();				
	    req.requestURI = URL.getOrgDomainUrl().toExternalForm()+'/services/apexrest/CRM/v1.0/ActionType';  
	    req.httpMethod = 'POST';
        String jsonString = getTestCaseActionBody(100,true);
        req.requestBody = Blob.valueOf(jsonString);
	    RestContext.request = req;
		RestContext.response = new RestResponse();

		Test.startTest();
            ActionTypeAPIV1Resource.doPost();
            String json = RestContext.response.responseBody.toString();

            ActionTypeAPIV1Response response = (ActionTypeAPIV1Response)System.JSON.deserialize(json, ActionTypeAPIV1Response.class);

            system.debug('response: '+response);
		Test.stopTest();

        system.assertEquals(100, response.results.size());

        for(ActionTypeAPIV1Response.ActionTypeResult r : response.results){
            system.assertEquals(false, r.isSuccess);
            system.assertEquals(true, r.errors.size()>0);
            system.assertEquals(Label.Enquiry_Validation_Error_Missing_Action_Type, r.errors[0].errorMessage);
        }
  	}

    public class ClubhouseClientResponseMockImpl implements HttpCalloutMock {

        private String responseBody;
        private Integer responseStatusCode;

        public ClubhouseClientResponseMockImpl(){
            Account acc = new Account();
            acc.Name = 'Test Account';
            insert acc;
            responseBody = '{ "SalesforceClientID":"'+acc.Id+'"}';
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
}