/*
Name:  TakePaymentControllerExtensionTest.cls
======================================================
======================================================
Purpose:
-------
Test Class for TakePaymentControllerExtension

======================================================
======================================================
History
------- 
Ver. Author           Date        Detail
1.0  James Radcliffe  08/06/2018  Initial Development.
1.1  James Radcliffe  13/06/2018  Adding test class for exceptions thrown after payment taken
*/
@isTest
public class TakePaymentControllerExtensionTest {
    
    @testSetup static void createTestData(){
        
        //Prep environment (custom settings)
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;  
        
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        
        //Setup Test Data
        //Create new Person Account
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert acc;
        //Create a Booking Request Opportunity
        String newSalesOpp = ApplicationConstant.OPPORTUNITY_RECORD_NEWSALES;
        String oppLeadSource = ApplicationConstant.OPPORTUNITY_LEAD_SOURCE_BOOKING_REQUEST;
        Id newSalesOppRTId = [Select Id From RecordType Where DeveloperName = :newSalesOpp Limit 1].Id;
        
        Opportunity opp = new Opportunity();
        
        opp.Name = 'Booking Request Test Opp';
        opp.CloseDate = system.today();
        opp.StageName = '1. Recommendations';
        opp.Additionalinformation__c = 'Test Clubhouse Sync';
        opp.AffiliateCampaignId__c = 99999999;
        opp.Nights__c = 5;
        opp.AccountId = acc.Id;
        opp.CountriesInterested__c = 'Spain;Portugal';
        opp.LeadSource = oppLeadSource;
        opp.TravelGroupSize__c = 2;
        opp.RecordTypeId = newSalesOppRTId;
        opp.Transaction_Authorised_Amount__c = 10.00;
        opp.Card_Token_ID__c = '1234321';
        opp.Venue__c = 'Fake Hotel & Golf';
        opp.PromoCode__c = '12345';
        
        insert(opp);            
        
        //Create a Booking
        Booking__c b = new Booking__c();
        b.Name = '111111';
        b.TECH_Opportunity__c = opp.Id;
        b.Account__c = acc.Id;
        b.Golfbreaks_Booking_ID__c = 11111;
        insert b; 
        
    }
    
    @isTest static void testSuccessfulPageLoad(){
        
        //Query the Opp
        Opportunity opp = [Select Id, Transaction_Authorised_Amount__c, Card_Token_Id__c, Transaction_Amount__c, (Select Id, Account__r.PersonEmail, Golfbreaks_Booking_Id__c From Bookings__r) From Opportunity Limit 1][0];
        //Confirm the details are accurate
        //Has a booking
        system.assertEquals(true,opp.Bookings__r.size()>0);
        //Authorised amount > 0
        system.assertEquals(true, opp.Transaction_Authorised_Amount__c>0);
        //No previous payments
        system.assertEquals(0.00, opp.Transaction_Amount__c);
        //Has correct details for callout
        system.assertNotEquals(null,opp.Card_Token_ID__c);
        system.assertNotEquals(null,opp.Bookings__r[0].Golfbreaks_Booking_Id__c);
        system.assertNotEquals(null,opp.Bookings__r[0].Account__r.PersonEmail);
        
        //Create Standard Controller
        ApexPages.StandardController cont = new ApexPages.StandardController(opp);
        
        test.startTest();
            GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
            //Instantiate Extension (load page)
            TakePaymentControllerExtension ext = new TakePaymentControllerExtension(cont);     
        test.stopTest();
        
        //Assert no errors are shown
        system.assertEquals(false, ApexPages.hasMessages());
        
        //Confirm state variables have been set correctly
        system.assertEquals(false,ext.showError);
        system.assertEquals(true,ext.showForm);
        system.assertEquals(false,ext.showSuccess);
        
        //Confirm the Transaction Amount has been defaulted for the agent
        system.assertEquals(opp.Transaction_Amount__c,ext.transactionAmount);
        system.assertEquals(ext.theOpp.Transaction_Amount__c,ext.theOpp.Transaction_Authorised_Amount__c);
        
    }
    
    @isTest static void testNoBookingValidation(){
        //Query the Opp
        Opportunity opp = [Select Id, (Select Id From Bookings__r) From Opportunity Limit 1][0];
        //Delete the Booking
        delete opp.Bookings__r;
        
        //Create Standard Controller
        ApexPages.StandardController cont = new ApexPages.StandardController(opp);
        
        test.startTest();
            GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
            //Instantiate Extension (load page)
            TakePaymentControllerExtension ext = new TakePaymentControllerExtension(cont);     
        test.stopTest();        
        
        //Confirm an error is displayed with the correct content
        system.assertEquals(true, ApexPages.hasMessages());        
        system.assertEquals(true, ApexPages.getMessages()[0].getDetail().contains('No Booking was found'));
        
    }
    
    @isTest static void testPaymentAlreadyTakenValidation(){
        
        //Query the Opp
        Opportunity opp = [Select Id, Transaction_Amount__c From Opportunity Limit 1][0];
        //Set Transaction Amount (Payment already taken)
        opp.Transaction_Amount__c = 10.00;
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        update opp;
        
        //Create Standard Controller
        ApexPages.StandardController cont = new ApexPages.StandardController(opp);
        
        test.startTest();
            GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
            //Instantiate Extension (load page)
            TakePaymentControllerExtension ext = new TakePaymentControllerExtension(cont);     
        test.stopTest();        
        
        //Confirm an error is displayed with the correct content
        system.assertEquals(true, ApexPages.hasMessages());        
        system.assertEquals(true, ApexPages.getMessages()[0].getDetail().contains('Only one payment can be taken per Booking Request'));
        
    }
    
    @isTest static void testNoAuthorisedAmountValidation(){
        
        //Query the Opp
        Opportunity opp = [Select Id, Transaction_Authorised_Amount__c From Opportunity Limit 1][0];
        //Set Authorised Amount
        opp.Transaction_Authorised_Amount__c = 0.00;
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        update opp;
        
        //Create Standard Controller
        ApexPages.StandardController cont = new ApexPages.StandardController(opp);
        
        test.startTest();
            GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
            //Instantiate Extension (load page)
            TakePaymentControllerExtension ext = new TakePaymentControllerExtension(cont);     
        test.stopTest();        
        
        //Confirm an error is displayed with the correct content
        system.assertEquals(true, ApexPages.hasMessages());        
        system.assertEquals(true, ApexPages.getMessages()[0].getDetail().contains('Cannot take payment. Authorsied Transaction Amount'));
        
    }
    
    @isTest static void testAuthorisedAmountExceededValidation(){
        
        //Query the Opp
        Opportunity opp = [Select Id, Transaction_Authorised_Amount__c, Card_Token_Id__c, Transaction_Amount__c, (Select Id, Account__r.PersonEmail, Golfbreaks_Booking_Id__c From Bookings__r) From Opportunity Limit 1][0];
        
        //Create Standard Controller
        ApexPages.StandardController cont = new ApexPages.StandardController(opp);
        
        //Instantiate Extension (load page)
        TakePaymentControllerExtension ext = new TakePaymentControllerExtension(cont);     
        
        //Assert no errors are shown
        system.assertEquals(false, ApexPages.hasMessages());
        
        //Set the Transaction_Amount__c to exceed the Authorised Amount
        ext.theOpp.Transaction_Amount__c = ext.theOpp.Transaction_Authorised_Amount__c+1;
        
        //Run validation checks
        test.startTest();
            GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
            ext.verifyPaymentRequestDetails();
        test.stopTest();
        
        //Confirm an error is displayed with the correct content
        system.assertEquals(true, ApexPages.hasMessages());        
        system.assertEquals(true, ApexPages.getMessages()[0].getDetail().contains('cannot exceed the maximum authorised amount'));
        
    }
    
    @isTest static void testInsufficientInformationValidation(){
        
        //Query the Opp
        Opportunity opp = [Select Id, Card_Token_Id__c From Opportunity Limit 1][0];
        
        //Remove the Card_Token_Id__c
        opp.Card_Token_ID__c = null;
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        update opp;
        
        //Create Standard Controller
        ApexPages.StandardController cont = new ApexPages.StandardController(opp);
        
        test.startTest();
            GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;   
            //Instantiate Extension (load page)
            TakePaymentControllerExtension ext = new TakePaymentControllerExtension(cont);     
        test.stopTest();        
        
        //Confirm an error is displayed with the correct content
        system.assertEquals(true, ApexPages.hasMessages());        
        system.assertEquals(true, ApexPages.getMessages()[0].getDetail().contains('The following required detail/s are missing: Card Token Id'));
        
    }
    
    @isTest static void testTakePaymentSuccess(){
        
        //Query the Opp
        Opportunity opp = [Select Id, Transaction_Authorised_Amount__c, Card_Token_Id__c, Transaction_Amount__c, (Select Id, Account__r.PersonEmail, Golfbreaks_Booking_Id__c From Bookings__r) From Opportunity Limit 1][0];
        
        //Create Standard Controller
        ApexPages.StandardController cont = new ApexPages.StandardController(opp);
        
        //Instantiate Extension (load page)
        TakePaymentControllerExtension ext = new TakePaymentControllerExtension(cont);     
        
        //Assert no errors are shown
        system.assertEquals(false, ApexPages.hasMessages());
        
        //Confirm the Transaction Amount matches the Authorised Amount
        system.assertEquals(ext.theOpp.Transaction_Amount__c, ext.theOpp.Transaction_Authorised_Amount__c);
        
        test.startTest();
            GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
            //Take Payment
            //Invoke the continuation by calling the action method
            Continuation conti = (Continuation)ext.processRequest();
        test.stopTest();
        
        // Verify that the continuation has the proper requests
        Map<String, HttpRequest> requests = conti.getRequests();
        system.assert(requests.size() == 1);
        system.assert(requests.get(ext.requestLabel) != null);
        
        // Perform mock callout 
        // (i.e. skip the callout and call the callback method)
        HttpResponse response = new HttpResponse();
        response.setBody('{"AllPaymentMethodsSuccessful":true}');   
        response.setStatusCode(200);
        // Set the fake response for the continuation     
        Test.setContinuationResponse(ext.requestLabel, response);
        // Invoke callback method
        Object result = Test.invokeContinuationMethod(ext, conti);
        // result is the return value of the callback
        system.assertEquals(null, result);
        // Verify that the controller's result variable
        //   is set to the mock response.
        system.assertEquals('{"AllPaymentMethodsSuccessful":true}', ext.result);
        system.assertEquals(200,ext.resultStatusCode);
        
        //Confirm the Transaction Amount has been saved on the Opportunity
        Opportunity oppAfterUpdate = [Select Id, Transaction_Amount__c, Card_Token_ID__c From Opportunity Where Id =:opp.Id][0];
        system.debug('oppAfterUpdate: '+oppAfterUpdate);
        system.assertEquals(oppAfterUpdate.Transaction_Amount__c, ext.theOpp.Transaction_Amount__c);
        //Confirm the token Id has been cleared
        system.assertEquals(null,oppAfterUpdate.Card_Token_ID__c);
        //Confirm the success message is shown
        system.assertEquals(true,ext.showSuccess);
        //Confirm no errors are shown
        system.assertEquals(false, ApexPages.hasMessages());
    }
    
    @isTest static void testTakePaymentFailure(){
        
        //Query the Opp
        Opportunity opp = [Select Id, Transaction_Authorised_Amount__c, Card_Token_Id__c, Transaction_Amount__c, (Select Id, Account__r.PersonEmail, Golfbreaks_Booking_Id__c From Bookings__r) From Opportunity Limit 1][0];
        
        //Create Standard Controller
        ApexPages.StandardController cont = new ApexPages.StandardController(opp);
        
        //Instantiate Extension (load page)
        TakePaymentControllerExtension ext = new TakePaymentControllerExtension(cont);     
        
        //Assert no errors are shown
        system.assertEquals(false, ApexPages.hasMessages());
        
        //Confirm the Transaction Amount matches the Authorised Amount
        system.assertEquals(ext.theOpp.Transaction_Amount__c, ext.theOpp.Transaction_Authorised_Amount__c);
        
        test.startTest();
            GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
            //Take Payment
            //Invoke the continuation by calling the action method
            Continuation conti = (Continuation)ext.processRequest();
        test.stopTest();
        
        // Verify that the continuation has the proper requests
        Map<String, HttpRequest> requests = conti.getRequests();
        system.assert(requests.size() == 1);
        system.assert(requests.get(ext.requestLabel) != null);
        
        // Perform mock callout 
        // (i.e. skip the callout and call the callback method)
        HttpResponse response = new HttpResponse();
        response.setBody('Mock response body');   
        response.setStatusCode(500);
        // Set the fake response for the continuation     
        Test.setContinuationResponse(ext.requestLabel, response);
        // Invoke callback method
        Object result = Test.invokeContinuationMethod(ext, conti);
        // result is the return value of the callback
        system.assertEquals(null, result);
        // Verify that the controller's result variable
        //   is set to the mock response.
        system.assertEquals('Mock response body', ext.result);
        system.assertEquals(500,ext.resultStatusCode);
        
        //Confirm the Transaction Amount has NOT been saved on the Opportunity
        Opportunity oppAfterUpdate = [Select Id, Transaction_Amount__c From Opportunity Where Id =:opp.Id][0];
        system.debug('oppAfterUpdate: '+oppAfterUpdate);
        system.assertNotEquals(oppAfterUpdate.Transaction_Amount__c, ext.theOpp.Transaction_Amount__c);
        //Confirm the success message remains hidden
        system.assertEquals(false,ext.showSuccess);
        //Confirm an error message is shown
        system.assertEquals(true, ApexPages.hasMessages());
        system.assertEquals(true, ApexPages.getMessages()[0].getDetail().contains('Payment Request Unsuccessful. Error:'));
        
    }
    
    //1.1 - If an exception is thrown after the API starts taking payments then a success status is returned, but there is still an error. This method tests the error is handled appropriately.
    @isTest static void testTakePaymentSuccessThenFailure(){
        
        //Query the Opp
        Opportunity opp = [Select Id, Transaction_Authorised_Amount__c, Card_Token_Id__c, Transaction_Amount__c, (Select Id, Account__r.PersonEmail, Golfbreaks_Booking_Id__c From Bookings__r) From Opportunity Limit 1][0];
        
        //Create Standard Controller
        ApexPages.StandardController cont = new ApexPages.StandardController(opp);
        
        //Instantiate Extension (load page)
        TakePaymentControllerExtension ext = new TakePaymentControllerExtension(cont);     
        
        //Assert no errors are shown
        system.assertEquals(false, ApexPages.hasMessages());
        
        //Confirm the Transaction Amount matches the Authorised Amount
        system.assertEquals(ext.theOpp.Transaction_Amount__c, ext.theOpp.Transaction_Authorised_Amount__c);
        
        test.startTest();
            GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
            //Take Payment
            //Invoke the continuation by calling the action method
            Continuation conti = (Continuation)ext.processRequest();
        test.stopTest();
        
        // Verify that the continuation has the proper requests
        Map<String, HttpRequest> requests = conti.getRequests();
        system.assert(requests.size() == 1);
        system.assert(requests.get(ext.requestLabel) != null);
        
        // Perform mock callout 
        // (i.e. skip the callout and call the callback method)
        HttpResponse response = new HttpResponse();
        response.setBody('{"AllPaymentMethodsSuccessful":false, "PaymentMethodOutcomes": [{"Outcome": "Cannot find a tokenised card called eCommerce stored card"}]}');   
        response.setStatusCode(200);
        // Set the fake response for the continuation     
        Test.setContinuationResponse(ext.requestLabel, response);
        // Invoke callback method
        Object result = Test.invokeContinuationMethod(ext, conti);
        // result is the return value of the callback
        system.assertEquals(null, result);
        // Verify that the controller's result variable
        //   is set to the mock response.
        system.assertEquals('{"AllPaymentMethodsSuccessful":false, "PaymentMethodOutcomes": [{"Outcome": "Cannot find a tokenised card called eCommerce stored card"}]}', ext.result);
        system.assertEquals(200,ext.resultStatusCode);
        
        //Confirm the Transaction Amount has NOT been saved on the Opportunity
        Opportunity oppAfterUpdate = [Select Id, Transaction_Amount__c, Card_Token_Id__c From Opportunity Where Id =:opp.Id][0];
        system.debug('oppAfterUpdate: '+oppAfterUpdate);
        system.assertNotEquals(oppAfterUpdate.Transaction_Amount__c, ext.theOpp.Transaction_Amount__c);
        
        //Confirm the success message is not shown
        system.assertEquals(false,ext.showSuccess);
        
        //Confirm errors are shown
        system.assertEquals(true, ApexPages.hasMessages());
        
        //Confirm the error is as expected
        system.assertEquals(true, ApexPages.getMessages()[0].getDetail().contains('There was an error. DO NOT submit another take payment request for this booking'));
        
        //Confirm an error log has been inserted
        Error_Log__c[] logs = [Select Id, Class_Name__c, Method_Name__c, trace__c From Error_Log__c Where Class_Name__c = 'TakePaymentControllerExtension' and Method_Name__c = 'processResponse'];
        system.assertEquals(1,logs.size());
        system.debug('logs:'+logs);

        //Confirm the token Id has been cleared 
        system.assertEquals(null, oppAfterUpdate.Card_Token_ID__c);
    }
    
}