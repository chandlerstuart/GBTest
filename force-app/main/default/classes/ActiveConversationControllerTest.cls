/*
Name:  ActiveConversationControllerTest.cls
======================================================
======================================================
Purpose: Test Suite for ActiveConversationController.cls
-------

Coverage: ActiveConversationController.cls - 95%

======================================================
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2023-09-25  Initial development.
*/
@isTest
public with sharing class ActiveConversationControllerTest {

    @testSetup static void createTestData(){
        
        //Create Person Account
        insert AP23_TestDataFactory.createPersonAccount(1);

    }

    @isTest
    static void testGetMostRecentActiveConversationSuccess() {

        // Create a test record and a related Conversation__c record
        Account testAccount = [Select Id From Account];

        Conversation__c testConversation = new Conversation__c(
            Status__c = 'New',//Active conversation
            Account__c = testAccount.Id
        );
        insert testConversation;

        // Call the method and verify that it returns the correct (active) Conversation__c record
        Test.startTest();
            Conversation__c result = ActiveConversationController.getMostRecentActiveConversation(testAccount.Id, 'Account__c');
        Test.stopTest();

        System.assertEquals(testConversation.Id, result.Id);
    }

    @isTest
    static void testGetMostRecentActiveConversationNoResults() {
        // Create a test record and a related Conversation__c record
        Account testAccount = [Select Id From Account];

        Conversation__c testConversation = new Conversation__c(
            Status__c = 'Closed',//Inactive conversation
            Account__c = testAccount.Id
        );
        insert testConversation;

        // Call the method and verify no record is returned (but no error thrown)
        Test.startTest();
            Conversation__c result = ActiveConversationController.getMostRecentActiveConversation(testAccount.Id, 'Account__c');
        Test.stopTest();

        System.assertEquals(null, result);
    }
    
    @isTest
    static void testGetMostRecentActiveConversationInvalidFieldReference() {
         
        // Create a test record and a related Conversation__c record
        Account testAccount = [Select Id From Account];

        Conversation__c testConversation = new Conversation__c(
            Status__c = 'New',//Active conversation
            Account__c = testAccount.Id
        );
        insert testConversation;
 
        // Call the method and verify that it returns no results (due to query exception)
        Test.startTest();
            Conversation__c result;
            Boolean errorThrown = false;
            try{
                result = ActiveConversationController.getMostRecentActiveConversation(testAccount.Id, 'UnrecognisedField__c');
            }catch(Exception e){
                errorThrown = true;
                system.assertEquals(true, e.getMessage().contains('No such column \'UnrecognisedField__c\' on entity \'Conversation__c\''));
            }
            system.assertEquals(true, errorThrown);//Confirm an exception was thrown 
        Test.stopTest();

        //Confirm the query exception was logged
        system.assertEquals(1, [Select Count() From Golfbreaks__PlatformLog__c]);
 
        System.assertEquals(null, result);
    }

    @isTest
    static void testCloseActiveConversationSuccess() {
        // Create a test record and a related Conversation__c record
        Account testAccount = [Select Id From Account];

        Conversation__c testConversation = new Conversation__c(
            Status__c = 'New',//Active conversation
            Account__c = testAccount.Id
        );
        insert testConversation;

        // Call the method to close the conversation
        Test.startTest();
            Boolean success = ActiveConversationController.closeActiveConversation(testConversation.Id);
        Test.stopTest();

        // Verify that the conversation is closed and the method returns true
        Conversation__c closedConversation = [SELECT Status__c FROM Conversation__c WHERE Id = :testConversation.Id];
        System.assertEquals('Closed', closedConversation.Status__c);
        System.assertEquals(true, success);
    }

    @isTest
    static void testCloseActiveConversationFail() {

        // Call the method to close the conversation, passing an invalid id.
        Test.startTest();
            Boolean success;
            Boolean errorThrown;
            try{
                success = ActiveConversationController.closeActiveConversation(UserInfo.getUserId());//Invalid conversation id
            }catch(Exception e){
                errorThrown = true;
                system.assertEquals(true, e.getMessage().contains('Invalid id value for this SObject type'));
            }
            system.assertEquals(true, errorThrown);//Confirm an exception was thrown 
        Test.stopTest();

        //Confirm the dml exception was logged and the method returns false
        system.assertEquals(1, [Select Count() From Golfbreaks__PlatformLog__c]);
    }
}