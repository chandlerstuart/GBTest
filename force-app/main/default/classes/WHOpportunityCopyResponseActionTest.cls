/*
Name:  WHOpportunityCopyResponseActionTest.cls
======================================================
======================================================
Purpose: Test Suite for WHOpportunityCopyResponseAction class
-------
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2020-02-25  Initial Development.
*/
@isTest
public with sharing class WHOpportunityCopyResponseActionTest {
    
    @TestSetup static void createTestData(){
        Map<String,Object> dataMap = new Map<String,Object>();
        dataMap.put('kaptioAccountId','001234567891011121');
        dataMap.put('masterAccountId','001466367891011121');
        insert new OutboundCallout__c(ReshapedPayloadBody__c=JSON.serialize(dataMap),//Set the expected reshaped payload property
                                    AcceptHeader__c='application/json',
                                    ContentTypeHeader__c='application/json',
                                    DataEventType__c='TestDataEvent',
                                    Endpoint__c='callout:testNameSpace/api/v1.0/fakeAPI',
                                    Method__c='GET');   
    }

    @isTest static void testGetData(){
        Id calloutId = [Select Id From OutboundCallout__c Limit 1].Id;
        WHOpportunityCopyResponseAction.Request req = new WHOpportunityCopyResponseAction.Request();
        req.outboundCalloutId = calloutId;

        List<WHOpportunityCopyResponseAction.Result> results = new List<WHOpportunityCopyResponseAction.Result>();
        test.startTest();
            results = WHOpportunityCopyResponseAction.getData(new List<WHOpportunityCopyResponseAction.Request>{req});
        test.stopTest();

        system.assertEquals('001234567891011121', results[0].kaptioAccountId);
        system.assertEquals('001466367891011121', results[0].masterAccountId);

    }


}