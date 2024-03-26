/*
Name:  GPTServiceEmailCopilotControllerTest
======================================================
======================================================
Purpose:
-------
Test Suite for GPTServiceEmailCopilotController.cls
======================================================
======================================================

Coverage: 
GPTServiceEmailCopilotController.cls - 100%

History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2023-10-11  Initial development.
*/
@isTest
public with sharing class GPTServiceEmailCopilotControllerTest {

    @testSetup static void createTestData(){
        
        // Create test data: Case and related EmailMessages
        Account testAccount = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert testAccount;

        Opportunity testOpp = AP23_TestDataFactory.createOpportunity(1, 'New', testAccount)[0];
        insert testOpp;

        Booking__c testBooking = AP23_TestDataFactory.createBooking(1, testAccount, testOpp.Id)[0];
        insert testBooking;

        Case testCase = new Case(Description = 'Test Description', AccountId = testAccount.Id, Booking__c=testBooking.Id);
        insert testCase;

        EmailMessage testEmail = new EmailMessage(
            Subject = 'Test Subject',
            TextBody = 'Test Text Body',
            HTMLBody = 'Test HTML Body',
            Incoming = true,
            ParentId = testCase.Id
        );
        insert testEmail;

    }

    @isTest
    public static void testLoadComponent() {

        Case testCase = [Select Id From Case];
        
        Test.startTest();
            // Call the method under test
            GPTServiceEmailCopilotController.PageData result = GPTServiceEmailCopilotController.loadComponent(testCase.Id);
        Test.stopTest();

        // Assert the results
        System.assertNotEquals(null, result);
        System.assertEquals(2, result.contentSelectOptions.size());//Case Detail and Email Message select options.
        System.assertNotEquals(null, result.clientId);//Case client identified.
        System.assertNotEquals(null, result.bookingId);//Case booking identified.
        System.assertEquals(2, result.idToHTMLEmailContentMap.values().size());//Includes HTML reference content
        System.assertEquals(2, result.idToTextEmailContentMap.values().size());//Includes Text reference content
        system.assertEquals(true, result.promptOptions.size()>0);//Retrieved prompt quick action configuration

    }

    @isTest
    public static void testLoadComponentException() {

        Case testCase = [Select Id From Case];
        
        Test.startTest();
            // Call the method under test
            GPTServiceEmailCopilotController.throwError = true;//Cause unexpected exception
            GPTServiceEmailCopilotController.PageData result = GPTServiceEmailCopilotController.loadComponent(testCase.Id);
        Test.stopTest();

        // Assert the results
        System.assertNotEquals(null, result);
        System.assertEquals(true, result.errorMessage.contains('Whoops! Something went wrong'));
    }

    @isTest
    public static void testAskGPT() {

        Account testAccount = [Select Id From Account];
        Booking__c testBooking = [Select Id From Booking__c];
        EmailMessage emailMessage = [Select Id, TextBody From EmailMessage];

        // Set up the mock callout
        Test.setMock(HttpCalloutMock.class, new GPTAPIManagerTest.MockHttpResponseSuccess());

        Test.startTest();
        //Start conversation
        GPTServiceEmailCopilotController.AskGPTSuccessResponse response = GPTServiceEmailCopilotController.askGPT(null, null, testBooking.Id, testAccount.Id, emailMessage.TextBody);

        // Assert the results
        System.assertNotEquals(null, response);
        System.assertEquals(true, response.isSuccess);//Is Successful
        System.assertEquals(3, response.messages.size());//1 = System, 2 = Default User Prompt, 3 = GPT response
        System.assertEquals('system', response.messages[0].role);
        System.assertEquals('user', response.messages[1].role);
        System.assertEquals('Assistant', response.messages[2].role);
        system.assertEquals('Why did the chicken cross the road?', response.output);//GPT response content

        GPTServiceEmailCopilotController.AskGPTSuccessResponse response2 = GPTServiceEmailCopilotController.askGPT(JSON.serialize(response.messages,false), 'I don\'t know, why did the chicken cross the road?', null, null, emailMessage.TextBody);

        //Continue conversation
        System.assertNotEquals(null, response2);
        System.assertEquals(true, response2.isSuccess);
        System.assertEquals(5, response2.messages.size());//1 = System, 2 = Default, 3 = GPT response, 4 = New User Prompt, 5 = GPT response

        Test.stopTest();

    }
}