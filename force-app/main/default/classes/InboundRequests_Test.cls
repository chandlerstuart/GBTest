/**
Name:  InboundRequests_Test.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test Class for InboundRequests
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.0  Atlee     2016-05-06   Initial test class development
**/
@isTest
public class InboundRequests_Test{
    static testMethod void testRequestPost(){
        Test.StartTest();
        //Test Data
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(Name = 'Testing Lead 101', StageName = 'Qualification', CloseDate = System.Today());
        insert opp;
        
        InboundRequests.InboundRequest rqst = new InboundRequests.InboundRequest();
        rqst.enquiryId = '11111';
        rqst.closedate = String.valueOf(System.Today()+1);
        rqst.stage = 'Closed Won';
        rqst.oppName = 'Testing Lead 101';
        rqst.category = 'Category';
        String JsonMsg=JSON.serialize(rqst);
        

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = 'https://instance/services/apexrest/';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(JsonMsg);
        
        RestContext.request = req;
        RestContext.response = res;
    
        System.debug('Resp: ' +RestContext.request.requestBody);
        InboundRequests.RequestSubmission_Post();
        InboundRequests.RequestSubmission_Put();
        //System.debug('Opp: ' +InboundRequests.ProcessRequest(RestContext.request.requestBody).opp);
        Test.StopTest();
    }
}