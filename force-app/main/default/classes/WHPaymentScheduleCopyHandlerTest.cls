/*
Name:  WHPaymentScheduleCopyRequestHandler.cls
======================================================
======================================================
Purpose: Test Suite for WHPaymentScheduleCopyRequestHandler
-------
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2020-04-21  Initial Development.
*/
@isTest
public with sharing class WHPaymentScheduleCopyHandlerTest {

    @testSetup static void createTestData(){
        
        //creating test accounts
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert acc;

        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, ApplicationConstant.RECOMMENDATIONSTAGE, acc)[0];
        insert opp;

        Booking__c booking = AP23_TestDataFactory.createBooking(1, opp.AccountId, opp.id)[0];
        booking.INTL_KaptioItineraryId__c = 'a0h24000002NIMAAA4';
        insert booking;
    }

    @isTest static void testExpectedPaymentCalculation(){

        system.assertEquals(0, [Select Id From Expected_Payment__c].size());

        String itineraryId = 'a0h24000002NIMAAA4';

        //4 payment schedules in random order (due dates)
        String jsonString = '[{"paymentSchedules":[{"paymentScheduleId":"a1y9H000007hzgOJAQ","expectedAmount":300,"dueDate":"2019-09-20","currencyISOCode":"NOK"},{"paymentScheduleId":"a1y4H000006hzgORTR","expectedAmount":200,"dueDate":"2020-10-20","currencyISOCode":"NOK"},{"paymentScheduleId":"a1y4H000007uzgOQAQ","expectedAmount":400,"dueDate":"2020-11-20","currencyISOCode":"NOK"},{"paymentScheduleId":"a1y6H000006hzgORSR","expectedAmount":100,"dueDate":"2019-10-20","currencyISOCode":"NOK"}],"itineraryBookingId":"'+itineraryId+'"}]';

        RestRequest req = new RestRequest();				
	    req.requestBody = Blob.valueOf(jsonString);
        req.httpMethod = 'POST';

        RestResponse res = new RestResponse();
        
        RestContext.request = req;	    
        RestContext.response = res;

        Webhook__mdt wh = [Select Id, SuccessResponseStatusCode__c, ErrorResponseStatusCode__c From Webhook__mdt Where PathIdentifier__c = 'exp-payment-copy'];

        test.startTest();
            WHPaymentScheduleCopyRequestHandler handler = new WHPaymentScheduleCopyRequestHandler();
            handler.handleRequest(req,res,wh);
        
            //Retrieve Expected Payments in ascending order of their Due Date
            Booking__c bookingsWithExpectedPayments = [Select Id, (Select Id, INTL_KaptioPaymentScheduleId__c, Expected_Amount__c, ExpectedPaymentType__c, Outstanding_Balance__c, Expected_Payment_Date__c, Booking_System__c, Booking__c From Expected_Payments__r Order By Expected_Payment_Date__c ASC ) From Booking__c Where INTL_KaptioItineraryId__c = :itineraryId];
            system.assertEquals(4, bookingsWithExpectedPayments.Expected_Payments__r.size());

            //Confirm the amounts & types have been calculated correctly
            for(Integer i=0; i<4;i++){
                Expected_Payment__c ep = bookingsWithExpectedPayments.Expected_Payments__r[i];
                if(i==0){
                    system.assertEquals('a1y9H000007hzgOJAQ', ep.INTL_KaptioPaymentScheduleId__c);
                    system.assertEquals(300, ep.Expected_Amount__c);
                    system.assertEquals(ApplicationConstant.EPAYMENTTYPEPARTIALDEPOSIT, ep.ExpectedPaymentType__c);
                }else if(i==1){
                    system.assertEquals('a1y6H000006hzgORSR', ep.INTL_KaptioPaymentScheduleId__c);
                    system.assertEquals(400, ep.Expected_Amount__c);
                    system.assertEquals(ApplicationConstant.EPAYMENTTYPEPARTIALDEPOSIT, ep.ExpectedPaymentType__c);
                }else if(i==2){
                    system.assertEquals('a1y4H000006hzgORTR', ep.INTL_KaptioPaymentScheduleId__c);
                    system.assertEquals(600, ep.Expected_Amount__c);
                    system.assertEquals(ApplicationConstant.EPAYMENTTYPEFULLDEPOSIT, ep.ExpectedPaymentType__c);
                }else{
                    system.assertEquals('a1y4H000007uzgOQAQ', ep.INTL_KaptioPaymentScheduleId__c);
                    system.assertEquals(1000, ep.Expected_Amount__c);
                    system.assertEquals(ApplicationConstant.EPAYMENTTYPEFULLBALANCE, ep.ExpectedPaymentType__c);

                }
            }

            system.assertEquals(wh.SuccessResponseStatusCode__c, res.statusCode);

            //Create a new request to exclude the Full B and Full D records and create a new Partial Depposit record
            String newJSON = '[{"paymentSchedules":[{"paymentScheduleId":"a1y9H000007hzgOJAQ","expectedAmount":300,"dueDate":"2019-09-20","currencyISOCode":"NOK"},{"paymentScheduleId":"a1y4H000007uzgOAAA","expectedAmount":243,"dueDate":"2019-03-23","currencyISOCode":"NOK"},{"paymentScheduleId":"a1y6H000006hzgORSR","expectedAmount":100,"dueDate":"2019-10-20","currencyISOCode":"NOK"}],"itineraryBookingId":"'+itineraryId+'"}]';

            RestRequest req2 = new RestRequest();				
            req2.requestBody = Blob.valueOf(newJSON);
            req2.httpMethod = 'POST';

            RestResponse res2 = new RestResponse();
            
            RestContext.request = req2;	    
            RestContext.response = res2;

            WHPaymentScheduleCopyRequestHandler handler2 = new WHPaymentScheduleCopyRequestHandler();
            handler2.handleRequest(req2,res2,wh);

        test.stopTest();

        //Retrieve Expected Payments in ascending order of their Due Date
        Booking__c bookingsWithExpectedPaymentsAfterUpdate = [Select Id, (Select Id, INTL_KaptioPaymentScheduleId__c, Expected_Amount__c, ExpectedPaymentType__c, Outstanding_Balance__c, Expected_Payment_Date__c, Booking_System__c, Booking__c From Expected_Payments__r Order By Expected_Payment_Date__c ASC ) From Booking__c Where INTL_KaptioItineraryId__c = :itineraryId];
        system.assertEquals(3, bookingsWithExpectedPaymentsAfterUpdate.Expected_Payments__r.size());

        //Confirm the amounts & types have been re-calculated correctly for the existing records, the new record has been created and the other records deleted.
        for(Integer i=0; i<3;i++){
            Expected_Payment__c ep = bookingsWithExpectedPaymentsAfterUpdate.Expected_Payments__r[i];
            if(i==0){//New Record
                system.assertEquals('a1y4H000007uzgOAAA', ep.INTL_KaptioPaymentScheduleId__c);
                system.assertEquals(243, ep.Expected_Amount__c);
                system.assertEquals(ApplicationConstant.EPAYMENTTYPEPARTIALDEPOSIT, ep.ExpectedPaymentType__c);
            }else if(i==1){//Previous Partial Deposit, now Full Deposit
                system.assertEquals('a1y9H000007hzgOJAQ', ep.INTL_KaptioPaymentScheduleId__c);
                system.assertEquals(543, ep.Expected_Amount__c);
                system.assertEquals(ApplicationConstant.EPAYMENTTYPEFULLDEPOSIT, ep.ExpectedPaymentType__c);
            }else{//Previous Partial Deposit, now Full Balance
                system.assertEquals('a1y6H000006hzgORSR', ep.INTL_KaptioPaymentScheduleId__c);
                system.assertEquals(643, ep.Expected_Amount__c);
                system.assertEquals(ApplicationConstant.EPAYMENTTYPEFULLBALANCE, ep.ExpectedPaymentType__c);
            }
        }

        system.assertEquals(wh.SuccessResponseStatusCode__c, res2.statusCode);


    }

    @isTest static void testResponseErrorNoId(){
        //Omit Itinerary Booking Id
        String jsonString = '[{"paymentSchedules":[{"paymentScheduleId":"a1y9H000007hzgOJAQ","expectedAmount":300,"dueDate":"2019-09-20","currencyISOCode":"NOK"},{"paymentScheduleId":"a1y4H000006hzgORTR","expectedAmount":200,"dueDate":"2020-10-20","currencyISOCode":"NOK"},{"paymentScheduleId":"a1y4H000007uzgOQAQ","expectedAmount":400,"dueDate":"2020-11-20","currencyISOCode":"NOK"},{"paymentScheduleId":"a1y6H000006hzgORSR","expectedAmount":100,"dueDate":"2019-10-20","currencyISOCode":"NOK"}]}]';

        RestRequest req = new RestRequest();				
	    req.requestBody = Blob.valueOf(jsonString);
        req.httpMethod = 'POST';

        RestResponse res = new RestResponse();
        
        RestContext.request = req;	    
        RestContext.response = res;

        Webhook__mdt wh = [Select Id, SuccessResponseStatusCode__c, ErrorResponseStatusCode__c From Webhook__mdt Where PathIdentifier__c = 'exp-payment-copy'];

        test.startTest();
            WHPaymentScheduleCopyRequestHandler handler = new WHPaymentScheduleCopyRequestHandler();
            handler.handleRequest(req,res,wh);
        test.stopTest();    

        system.assertEquals(0, [Select Id From Expected_Payment__c].size());//Confirm no records were created
        system.assertEquals(true, RestContext.response.responseBody.toString().contains('Could not find Booking - Required Property Missing > itineraryBookingId'));//Confirm the correct error is returned in the response
        system.assertEquals(wh.ErrorResponseStatusCode__c, res.statusCode);
    }

    @isTest static void testResponseFailureUnrecognisedId(){
        String unrecognisedItineraryId = 'a0h24000002NIMBBB4';
        
        //Specify invalid Itinerary Booking Id
        String jsonString = '[{"paymentSchedules":[{"paymentScheduleId":"a1y9H000007hzgOJAQ","expectedAmount":300,"dueDate":"2019-09-20","currencyISOCode":"NOK"},{"paymentScheduleId":"a1y4H000006hzgORTR","expectedAmount":200,"dueDate":"2020-10-20","currencyISOCode":"NOK"},{"paymentScheduleId":"a1y4H000007uzgOQAQ","expectedAmount":400,"dueDate":"2020-11-20","currencyISOCode":"NOK"},{"paymentScheduleId":"a1y6H000006hzgORSR","expectedAmount":100,"dueDate":"2019-10-20","currencyISOCode":"NOK"}],"itineraryBookingId":"'+unrecognisedItineraryId+'"}]';

        RestRequest req = new RestRequest();				
	    req.requestBody = Blob.valueOf(jsonString);
        req.httpMethod = 'POST';

        RestResponse res = new RestResponse();
        
        RestContext.request = req;	    
        RestContext.response = res;

        Webhook__mdt wh = [Select Id, SuccessResponseStatusCode__c, ErrorResponseStatusCode__c From Webhook__mdt Where PathIdentifier__c = 'exp-payment-copy'];

        test.startTest();
            WHPaymentScheduleCopyRequestHandler handler = new WHPaymentScheduleCopyRequestHandler();
            handler.handleRequest(req,res,wh);
        test.stopTest();    

        system.assertEquals(0, [Select Id From Expected_Payment__c].size());//Confirm no records were created
        system.assertEquals(true, RestContext.response.responseBody.toString().contains('Could not find Booking with itineraryBookingId'));//Confirm the correct error is returned in the response
        system.assertEquals(wh.ErrorResponseStatusCode__c, res.statusCode);
    }

    @isTest static void testDeleteAllUnrecognised(){

        system.assertEquals(0, [Select Id From Expected_Payment__c].size());

        String itineraryId = 'a0h24000002NIMAAA4';

        //Create 4 Expected Payments
        String jsonString = '[{"paymentSchedules":[{"paymentScheduleId":"a1y9H000007hzgOJAQ","expectedAmount":300,"dueDate":"2019-09-20","currencyISOCode":"NOK"},{"paymentScheduleId":"a1y4H000006hzgORTR","expectedAmount":200,"dueDate":"2020-10-20","currencyISOCode":"NOK"},{"paymentScheduleId":"a1y4H000007uzgOQAQ","expectedAmount":400,"dueDate":"2020-11-20","currencyISOCode":"NOK"},{"paymentScheduleId":"a1y6H000006hzgORSR","expectedAmount":100,"dueDate":"2019-10-20","currencyISOCode":"NOK"}],"itineraryBookingId":"'+itineraryId+'"}]';

        RestRequest req = new RestRequest();				
	    req.requestBody = Blob.valueOf(jsonString);
        req.httpMethod = 'POST';

        RestResponse res = new RestResponse();
        
        RestContext.request = req;	    
        RestContext.response = res;

        Webhook__mdt wh = [Select Id, SuccessResponseStatusCode__c, ErrorResponseStatusCode__c From Webhook__mdt Where PathIdentifier__c = 'exp-payment-copy'];

        test.startTest();
            WHPaymentScheduleCopyRequestHandler handler = new WHPaymentScheduleCopyRequestHandler();
            handler.handleRequest(req,res,wh);
        
            system.assertEquals(4, [Select Id From Expected_Payment__c].size());

            //Send Empty List for second request
            String newJSONString = '[{"paymentSchedules":[],"itineraryBookingId":"'+itineraryId+'"}]';

            RestRequest req2 = new RestRequest();				
            req2.requestBody = Blob.valueOf(newJSONString);
            req2.httpMethod = 'POST';

            RestResponse res2 = new RestResponse();
            
            RestContext.request = req2;	    
            RestContext.response = res2;

            WHPaymentScheduleCopyRequestHandler handler2 = new WHPaymentScheduleCopyRequestHandler();
            handler2.handleRequest(req2,res2,wh);
        
            system.assertEquals(0, [Select Id From Expected_Payment__c].size());//Confirm the EPs have been deleted

        test.stopTest();

    }

}