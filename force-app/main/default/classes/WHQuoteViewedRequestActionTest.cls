/*
Name:  WHQuoteViewedRequestActionTest.cls
======================================================
======================================================
Purpose: Test Suite for WHQuoteViewedRequestAction class
-------
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2020-07-29  Initial Development.
*/
@isTest
public with sharing class WHQuoteViewedRequestActionTest {
    
    @TestSetup static void createTestData(){
        Map<String,Object> dataMap = new Map<String,Object>();
        dataMap.put('opportunityId','006234567891011121');
        insert new OutboundCallout__c(ReshapedPayloadBody__c=JSON.serialize(dataMap),//Set the expected reshaped payload property
                                    AcceptHeader__c='application/json',
                                    ContentTypeHeader__c='application/json',
                                    DataEventType__c='TestDataEvent',
                                    Endpoint__c='callout:testNameSpace/api/v1.0/fakeAPI',
                                    Method__c='GET');        
    }

    @isTest static void testGetData(){
        Id calloutId = [Select Id From OutboundCallout__c Limit 1].Id;
        WHQuoteViewedRequestAction.Request req = new WHQuoteViewedRequestAction.Request();
        req.outboundCalloutId = calloutId;

        List<WHQuoteViewedRequestAction.Result> results = new List<WHQuoteViewedRequestAction.Result>();
        test.startTest();
            results = WHQuoteViewedRequestAction.getData(new List<WHQuoteViewedRequestAction.Request>{req});
        test.stopTest();

        system.assertEquals('006234567891011121', results[0].opportunityId);
    }

}