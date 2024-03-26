/*
Name: EnquiryActionTest.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Test suite for Enquiry Action  functions.

Coverage for classes below (target 85%):
EnquiryAction.cls : 100%	

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-06-10  Initial development.
*/
@isTest(SeeAllData=false)
public with sharing class EnquiryActionTest {
	/*
    Test cases:
        singleTestCase1 - ApexAction. Create new Enquiry -WIP.
        ..
        negativeTestCase1 - ApexAction. todo.
	*/
	
    @testSetup static void setup(){}
    
    /* **/
    static testMethod void singleTestCase1() {
        // Test case 1 : ApexAction. Create new Enquiry -WIP.

        Test.setMock(HttpCalloutMock.class, new ClubhouseClientResponseMockImpl());

        EnquiryActionInput e = new EnquiryActionInput();

        e.actionTypeName = 'TestCaseAction';
        //Client
        e.firstName = 'Test';
        e.lastName = 'Client1';
        e.email = 'testClient1@example.com';
        e.mobilePhone = '+447900000000';
        //Trip
        e.countries = new List<String>{'Belgium,Spain,France,Portugal'};
        //Task
        e.subject = 'This is a subject';

        List<EnquiryActionOutput> results = EnquiryAction.createEnquiries( new List<EnquiryActionInput>{ e } );
        
        for (EnquiryActionOutput r : results){        

            System.debug(LoggingLevel.ERROR,'FINDME>>'+r);

            System.assert(r.isSuccess);
            System.assertNotEquals(null,r.recordId);
            System.assert(((String)r.recordId).startsWith('500'));
            System.assertNotEquals(null,r.clientId);
            System.assert(((String)r.clientId).startsWith('001'));
        }        
  	}
    /* */          

    public class ClubhouseClientResponseMockImpl implements HttpCalloutMock {

        private String responseBody;
        private Integer responseStatusCode;

        public ClubhouseClientResponseMockImpl(){
            responseBody='{ "GolfbreaksEnquiryID":"ClubhouseIdValue", "SalesforceClientID":"001b000000qDVy6AAZ", "GolfbreaksClientID":"ClubhouseIdValue" }';
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