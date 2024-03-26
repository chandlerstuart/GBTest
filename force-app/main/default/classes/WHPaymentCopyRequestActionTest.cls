/*
Name:  WHPaymentCopyRequestActionTest.cls
======================================================
======================================================
Purpose: Test Suite for WHPaymentCopyRequestAction class
-------
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2020-03-06  Initial Development.
*/
@isTest
public with sharing class WHPaymentCopyRequestActionTest { 
    
    @TestSetup static void createTestData(){
        Map<String,Object> dataMap = new Map<String,Object>();
        dataMap.put('payerEmail','test.payer@example.com');
        dataMap.put('payerName','Test Payer');
        dataMap.put('paymentId','a08234567891011121');
        dataMap.put('currencyISOCode','GBP');
        dataMap.put('itineraryBookingId','a04234567891011121');
        dataMap.put('amount',89.99);
        dataMap.put('surcharge',13.66);
        dataMap.put('paymentDateTime',DateTime.newInstance(system.today().year(),system.today().month(),system.today().day()));
        dataMap.put('totalAmountPaid',157.45);

        insert new OutboundCallout__c(ReshapedPayloadBody__c=JSON.serialize(dataMap),//Set the expected reshaped payload property
                                    AcceptHeader__c='application/json',
                                    ContentTypeHeader__c='application/json',
                                    DataEventType__c='TestDataEvent',
                                    Endpoint__c='callout:testNameSpace/api/v1.0/fakeAPI',
                                    Method__c='GET');        
    }

    @isTest static void testGetData(){
        Id calloutId = [Select Id From OutboundCallout__c Limit 1].Id;
        WHPaymentCopyRequestAction.Request req = new WHPaymentCopyRequestAction.Request();
        req.outboundCalloutId = calloutId;

        List<WHPaymentCopyRequestAction.Result> results = new List<WHPaymentCopyRequestAction.Result>();
        test.startTest();
            results = WHPaymentCopyRequestAction.getData(new List<WHPaymentCopyRequestAction.Request>{req});
        test.stopTest();

        system.assertEquals('test.payer@example.com', results[0].payerEmail);
        system.assertEquals('Test Payer', results[0].payerName);
        system.assertEquals('a08234567891011121', results[0].paymentId);
        system.assertEquals('GBP', results[0].currencyISOCode);
        system.assertEquals('a04234567891011121', results[0].itineraryBookingId);
        system.assertEquals(89.99, results[0].amount);
        system.assertEquals(13.66, results[0].surcharge);
        system.assertEquals(DateTime.newInstance(system.today().year(),system.today().month(),system.today().day()),results[0].paymentDateTime);
        system.assertEquals(157.45, results[0].totalAmountPaid);


    }


}