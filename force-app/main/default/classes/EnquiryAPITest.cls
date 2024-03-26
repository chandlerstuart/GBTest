/*
Name: EnquiryAPITest.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Test suite for Enquiry API functions.

Coverage for classes below (target 85%):
EnquiryAPIV1Resource.cls : 0%	

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-05-05  Initial development.
1.1  Mark Cane&    2019-06-10  Test method modifications following changes to EnquiryAPIV1Response structure.
1.2  J Radcliffe   2019-07-22  new Test Method bulkAsyncTestCase1 
*/
@isTest(SeeAllData=false)
public with sharing class EnquiryAPITest {
	/*
    Test cases:
        singleTestCase1 - ApexRest. Single enquiry post.
        ..
        bulkTestCase1 - ApexRest. Bulk post to Enquiry endpoint.
        bulkTestCase2 - ApexRest. Bulk post to EnquiryAsync endpoint.
        ..
        negativeTestCase1 - ApexRest. Invalid Action Type specified.
        negativeTestCase2 - ApexRest. Bulk post to Enquiry endpoint. Invalid Action Type specified.
	*/
	
    @testSetup static void setup(){ }
    
    /* **/
    static testMethod void singleTestCase1() {
        // Test case 1 : ApexRest. Single enquiry post.

        String jsonString = getTestCaseActionBody(1,false);

        Test.setMock(HttpCalloutMock.class, new ClubhouseClientResponseMockImpl());

	    RestRequest req = new RestRequest();				
	    req.requestURI = URL.getOrgDomainUrl().toExternalForm()+'/services/apexrest/1.0/Enquiry';  
	    req.httpMethod = 'POST';        
        req.requestBody = Blob.valueOf(jsonString);
	    RestContext.request = req;
		RestContext.response = new RestResponse();

        Test.startTest();
        
        EnquiryAPIV1Resource.doPost();

        jsonString = RestContext.response.responseBody.toString();
        EnquiryAPIV1Response response = (EnquiryAPIV1Response)System.JSON.deserialize(jsonString, EnquiryAPIV1Response.class);
        
        Test.stopTest();

        System.assertEquals(true, response.isSuccess);
        System.assertEquals(1, response.enquiryResults.size());
        System.assertEquals(true, response.enquiryResults[0].isSuccess);
        System.assertEquals(0, response.enquiryResults[0].enquiryErrors.size());
  	}
    /* */ 

    /* **/
    static testMethod void bulkTestCase1() {
        // Bulk Test case 1 : ApexRest. Bulk post to Enquiry endpoint.

        //NOTE - Currently API only supports single requests. Max number of callouts per transaction is 100.
        //Can only bulk test 100 enquiries until CH API's are bulk enabled

        String jsonString = getTestCaseActionBody(100,false);

        Test.setMock(HttpCalloutMock.class, new ClubhouseClientResponseMockImpl());

	    RestRequest req = new RestRequest();				
	    req.requestURI = URL.getOrgDomainUrl().toExternalForm()+'/services/apexrest/1.0/Enquiry';  
        req.httpMethod = 'POST';            
        req.requestBody = Blob.valueOf(jsonString);
	    RestContext.request = req;
		RestContext.response = new RestResponse();

		Test.startTest();
        
        EnquiryAPIV1Resource.doPost();
        
        jsonString = RestContext.response.responseBody.toString();
        EnquiryAPIV1Response response = (EnquiryAPIV1Response)System.JSON.deserialize(jsonString, EnquiryAPIV1Response.class);

		Test.stopTest();
                
        System.assertEquals(100, response.enquiryResults.size());

        for(EnquiryAPIV1Response.EnquiryResult r : response.enquiryResults){
            System.assertEquals(true, r.isSuccess);
            System.assertEquals(false, r.enquiryErrors.size()>0);
        }
  	}
    /* */

    /* **/
    static testMethod void bulkTestCase2() {
        // Bulk Test case 2 : ApexRest. Bulk post to EnquiryAsync endpoint.

        //Configuring API Settings
        FrameworkSettings__c fs = new FrameworkSettings__c();
        fs.EnquiriesPerQueueInsert__c = 100;//Only permitted one queued job in a test context. Setting batch size to total count
        fs.EnquiriesPerProcessorCycle__c = 100;//All must be processed on the first run. An attempt to chain jobs would throw an exception
        insert fs;

        String jsonString = getTestCaseActionBody(100,false);

        Test.setMock(HttpCalloutMock.class, new ClubhouseClientResponseMockImpl());

	    RestRequest req = new RestRequest();				
	    req.requestURI = URL.getOrgDomainUrl().toExternalForm()+'/services/apexrest/1.0/EnquiryAsync';  
	    req.httpMethod = 'POST';        
        req.requestBody = Blob.valueOf(jsonString);
	    RestContext.request = req;
		RestContext.response = new RestResponse();

		Test.startTest();
        
        EnquiryAPIV1AsyncResource.doPost();
        
        jsonString = RestContext.response.responseBody.toString();
        EnquiryAPIV1Response response = (EnquiryAPIV1Response)System.JSON.deserialize(jsonString, EnquiryAPIV1Response.class);

		Test.stopTest();
                
        System.assertEquals(100, response.enquiryResults.size());

        for(EnquiryAPIV1Response.EnquiryResult r : response.enquiryResults){
            System.assertEquals(true, r.isSuccess);
            System.assertEquals(false, r.enquiryErrors.size()>0);
        }
        System.assertEquals(100, [Select Id From EnquiryRequest__c].size());//Confirm all logs have been queued
        System.assertEquals(1, [Select Id,  JobType, Status, MethodName, NumberOfErrors, TotalJobItems From AsyncApexJob Where ApexClass.Name = 'EnquiryRequestProcessor' and JobType='Queueable' and Status= 'Queued'].size());//Confirm the processor has been queued
    }
    /* */

    /* **/
    static testMethod void negativeTestCase1() {
        // Negative Test case 1 : ApexRest. Invalid Action Type specified.

        String jsonString = getTestCaseActionBody(1,true); //<-- IsInvalid = true (no Action Type)

        Test.setMock(HttpCalloutMock.class, new ClubhouseClientResponseMockImpl());

	    RestRequest req = new RestRequest();				
	    req.requestURI = URL.getOrgDomainUrl().toExternalForm()+'/services/apexrest/1.0/Enquiry';  
	    req.httpMethod = 'POST';        
        req.requestBody = Blob.valueOf(jsonString);
	    RestContext.request = req;
        RestContext.response = new RestResponse();
		
		Test.startTest();
        
        EnquiryAPIV1Resource.doPost();
        
        jsonString = RestContext.response.responseBody.toString();
        EnquiryAPIV1Response response = (EnquiryAPIV1Response)System.JSON.deserialize(jsonString, EnquiryAPIV1Response.class);         
    
		Test.stopTest();

        System.assertEquals(true, response.isSuccess);
        System.assertEquals(1, response.enquiryResults.size());
        System.assertEquals(false, response.enquiryResults[0].isSuccess);
        System.assertNotEquals(0, response.enquiryResults[0].enquiryErrors.size());
        System.assertEquals(Label.Enquiry_Validation_Error_Missing_Action_Type, response.enquiryResults[0].enquiryErrors[0].errorMessage);
  	}
    /* */   

    static testMethod void negativeTestCase2() {
        // Negative Test case 2 : ApexRest. Bulk post to Enquiry endpoint. Invalid Action Type.

        //NOTE - Currently API only supports single requests. Max number of callouts per transaction is 100.
        //Can only bulk test 100 enquiries until CH API's are bulk enabled
        String jsonString = getTestCaseActionBody(100,true);

        Test.setMock(HttpCalloutMock.class, new ClubhouseClientResponseMockImpl());

	    RestRequest req = new RestRequest();				
	    req.requestURI = URL.getOrgDomainUrl().toExternalForm()+'/services/apexrest/1.0/Enquiry';  
	    req.httpMethod = 'POST';        
        req.requestBody = Blob.valueOf(jsonString);
	    RestContext.request = req;
		RestContext.response = new RestResponse();

		Test.startTest();
        
        EnquiryAPIV1Resource.doPost();
        
        jsonString = RestContext.response.responseBody.toString();
        EnquiryAPIV1Response response = (EnquiryAPIV1Response)System.JSON.deserialize(jsonString, EnquiryAPIV1Response.class);

        Test.stopTest();

        System.assertEquals(100, response.enquiryResults.size());

        for(EnquiryAPIV1Response.EnquiryResult r : response.enquiryResults){
            System.assertEquals(false, r.isSuccess);
            System.assertEquals(true, r.enquiryErrors.size()>0);
            System.assertEquals(Label.Enquiry_Validation_Error_Missing_Action_Type, r.enquiryErrors[0].errorMessage);
        }
  	}
    
    //Helper class that builds an Enquiry Request Body
    private static String getTestCaseActionBody(Integer count, Boolean isInvalid){

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