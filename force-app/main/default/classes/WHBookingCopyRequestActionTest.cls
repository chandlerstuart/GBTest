/*
Name:  WHBookingCopyRequestActionTest.cls
======================================================
======================================================
Purpose: Test Suite for WHBookingCopyRequestAction class
-------
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2020-03-06  Initial Development.
*/
@isTest
public with sharing class WHBookingCopyRequestActionTest { 
    
    @TestSetup static void createTestData(){
        Map<String,Object> dataMap = new Map<String,Object>();
        
        dataMap.put('cancelledDate',system.today().addDays(-5));
        dataMap.put('isCancelled',true);
        dataMap.put('currencyISOCode','GBP');
        dataMap.put('salesRegion','UK & Ireland');
        dataMap.put('grossProfit',57.99);
        dataMap.put('grossProfitBCY',34.54);
        dataMap.put('grossProfitCCY',60.65);
        dataMap.put('kaptioItineraryId','a01234567891011121');
        dataMap.put('masterAccountId','001234567891011121');
        dataMap.put('masterOpportunityId','006234567891011121');
        dataMap.put('bookingNumber','12345');
        dataMap.put('description','testRequestData');
        dataMap.put('travelDate',system.today().addDays(5));
        dataMap.put('travelReturnDate',system.today().addDays(10));
        dataMap.put('nights',4);
        dataMap.put('numberOfGuests',7);
        dataMap.put('salesPriceGross',32.43);
        dataMap.put('costPriceGross','69.32');
        dataMap.put('costPriceBCY',72.33);
        dataMap.put('amountPaid',0.01);
        dataMap.put('salesAgentId','005123456643333');
        dataMap.put('itineraryItemAccountName','Elba Sunset Mallorca');


        insert new OutboundCallout__c(ReshapedPayloadBody__c=JSON.serialize(dataMap),//Set the expected reshaped payload property
                                    AcceptHeader__c='application/json',
                                    ContentTypeHeader__c='application/json',
                                    DataEventType__c='TestDataEvent',
                                    Endpoint__c='callout:testNameSpace/api/v1.0/fakeAPI',
                                    Method__c='GET');        
    }

    @isTest static void testGetData(){
        Id calloutId = [Select Id From OutboundCallout__c Limit 1].Id;
        WHBookingCopyRequestAction.Request req = new WHBookingCopyRequestAction.Request();
        req.outboundCalloutId = calloutId;

        List<WHBookingCopyRequestAction.Result> results = new List<WHBookingCopyRequestAction.Result>();
        test.startTest();
            results = WHBookingCopyRequestAction.getData(new List<WHBookingCopyRequestAction.Request>{req});
        test.stopTest();

        system.assertEquals(system.today().addDays(-5), results[0].cancelledDate);
        system.assertEquals(true, results[0].isCancelled);
        system.assertEquals('GBP', results[0].currencyISOCode);
        system.assertEquals('UK & Ireland', results[0].salesRegion);
        system.assertEquals(57.99, results[0].grossProfit);
        system.assertEquals(34.54, results[0].grossProfitBCY);
        system.assertEquals(60.65, results[0].grossProfitCCY);
        system.assertEquals('a01234567891011121', results[0].kaptioItineraryId);
        system.assertEquals('001234567891011121', results[0].masterAccountId);
        system.assertEquals('006234567891011121', results[0].masterOpportunityId);
        system.assertEquals('12345', results[0].bookingNumber);
        system.assertEquals('testRequestData', results[0].description);
        system.assertEquals(system.today().addDays(5), results[0].travelDate);
        system.assertEquals(system.today().addDays(10), results[0].travelReturnDate);
        system.assertEquals(4, results[0].nights);
        system.assertEquals(7, results[0].numberOfGuests);
        system.assertEquals(32.43, results[0].salesPriceGross);
        system.assertEquals(69.32, results[0].costPriceGross);
        system.assertEquals(72.33, results[0].costPriceBCY);
        system.assertEquals(0.01, results[0].amountPaid);
        system.assertEquals('005123456643333', results[0].salesAgentId);
        system.assertEquals('Elba Sunset Mallorca', results[0].itineraryItemAccountName);


    }


}