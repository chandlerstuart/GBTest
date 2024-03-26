/*
Name:  WHKaptioClientCopyResponseActionTest.cls
======================================================
======================================================
Purpose: Test Suite for WHKaptioClientCopyResponseAction class
-------
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2020-02-25  Initial Development.
*/
@isTest
public with sharing class WHKaptioClientCopyResponseActionTest {
    
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
        WHKaptioClientCopyResponseAction.Request req = new WHKaptioClientCopyResponseAction.Request();
        req.outboundCalloutId = calloutId;

        List<WHKaptioClientCopyResponseAction.Result> results = new List<WHKaptioClientCopyResponseAction.Result>();
        test.startTest();
            results = WHKaptioClientCopyResponseAction.getData(new List<WHKaptioClientCopyResponseAction.Request>{req});
        test.stopTest();

        system.assertEquals('001533342291011121', results[0].kaptioAccountId);
        system.assertEquals('001234567891011121', results[0].masterAccountId);

    }


}