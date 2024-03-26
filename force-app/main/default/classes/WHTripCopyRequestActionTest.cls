/*
Name:  WHTripCopyRequestActionTest.cls
======================================================
======================================================
Purpose: Test Suite for WHTripCopyRequestAction class
-------
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2020-03-06  Initial Development.
*/
@isTest
public with sharing class WHTripCopyRequestActionTest { 
    
    @TestSetup static void createTestData(){
        Map<String,Object> dataMap = new Map<String,Object>();
        dataMap.put('masterOpportunityId','006234567891011121');
        dataMap.put('tripAmount',209.99);
        dataMap.put('tripAmountBCY',182.00);
        dataMap.put('tripStatus','Quote Sent');
        dataMap.put('apiSource','testSource');
        insert new OutboundCallout__c(ReshapedPayloadBody__c=JSON.serialize(dataMap),//Set the expected reshaped payload property
                                    AcceptHeader__c='application/json',
                                    ContentTypeHeader__c='application/json',
                                    DataEventType__c='TestDataEvent',
                                    Endpoint__c='callout:testNameSpace/api/v1.0/fakeAPI',
                                    Method__c='GET');        
    }

    @isTest static void testGetData(){
        Id calloutId = [Select Id From OutboundCallout__c Limit 1].Id;
        WHTripCopyRequestAction.Request req = new WHTripCopyRequestAction.Request();
        req.outboundCalloutId = calloutId;

        List<WHTripCopyRequestAction.Result> results = new List<WHTripCopyRequestAction.Result>();
        test.startTest();
            results = WHTripCopyRequestAction.getData(new List<WHTripCopyRequestAction.Request>{req});
        test.stopTest();

        system.assertEquals('006234567891011121', results[0].masterOpportunityId);
        system.assertEquals(209.99, results[0].tripAmount);
        system.assertEquals(182.00, results[0].tripAmountBCY);
        system.assertEquals('Quote Sent', results[0].tripStatus);
        system.assertEquals('testSource', results[0].apiSource);

    }


}