/*
Name:  WHKaptioClientMergeResponseActionTest.cls
======================================================
======================================================
Purpose: Test Suite for WHKaptioClientMergeResponseAction class
-------
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2020-03-20  Initial Development.
*/
@isTest
public with sharing class WHKaptioClientMergeResponseActionTest {
    
    @TestSetup static void createTestData(){
        Map<String,Object> dataMap = new Map<String,Object>();
        dataMap.put('kaptioAccountId','001533342291011121');
        dataMap.put('masterAccountId','001234567891011121');
        insert new OutboundCallout__c(ReshapedPayloadBody__c=JSON.serialize(dataMap),//Set the expected reshaped payload property
                                    AcceptHeader__c='application/json',
                                    ContentTypeHeader__c='application/json',
                                    DataEventType__c='TestDataEvent',
                                    Endpoint__c='callout:testNameSpace/api/v1.0/fakeAPI',
                                    Method__c='GET');   
    }

    @isTest static void testGetData(){
        Id calloutId = [Select Id From OutboundCallout__c Limit 1].Id;
        WHKaptioClientMergeResponseAction.Request req = new WHKaptioClientMergeResponseAction.Request();
        req.outboundCalloutId = calloutId;

        List<WHKaptioClientMergeResponseAction.Result> results = new List<WHKaptioClientMergeResponseAction.Result>();
        test.startTest();
            results = WHKaptioClientMergeResponseAction.getData(new List<WHKaptioClientMergeResponseAction.Request>{req});
        test.stopTest();

        system.assertEquals('001533342291011121', results[0].kaptioAccountId);
        system.assertEquals('001234567891011121', results[0].masterAccountId);

    }


}