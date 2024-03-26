/*
Name:  WHTealiumIdRetrieveResponseActionTest.cls
======================================================
======================================================
Purpose: Test Suite for WHTealiumIdRetrieveResponseAction class
-------
https://webapi.golfbreaks.com/tracking/{agent_id}
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane     2020-05-27  Initial Development.
*/
@isTest
public with sharing class WHTealiumIdRetrieveResponseActionTest {
    
    @TestSetup static void createTestData(){
        Map<String,Object> dataMap = new Map<String,Object>();
        dataMap.put('tealiumID','1000');
        dataMap.put('callerId','+442079873322');
        insert new OutboundCallout__c(ReshapedPayloadBody__c=JSON.serialize(dataMap),//Set the expected reshaped payload property
                                    AcceptHeader__c='application/json',
                                    ContentTypeHeader__c='application/json',
                                    DataEventType__c='TestDataEvent',
                                    Endpoint__c='callout:testNameSpace/api/v1.0/fakeAPI',
                                    Method__c='GET');   
    }

    @isTest static void testGetData(){
        
        Id calloutId = [select Id from OutboundCallout__c limit 1].Id;
        WHTealiumIdRetrieveResponseAction.Request req = new WHTealiumIdRetrieveResponseAction.Request();
        req.outboundCalloutId = calloutId;

        List<WHTealiumIdRetrieveResponseAction.Result> results = new List<WHTealiumIdRetrieveResponseAction.Result>();
        
        Test.startTest();
        results = WHTealiumIdRetrieveResponseAction.getData(new List<WHTealiumIdRetrieveResponseAction.Request>{req});
        Test.stopTest();

        System.assertEquals('1000', results[0].tealiumId);
        System.assertEquals('+442079873322', results[0].callerId);
    }
}