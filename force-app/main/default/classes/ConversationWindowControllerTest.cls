/*
Name:  ConversationWindowControllerTest.cls
Copyright © 2022  Golfbreaks
======================================================
======================================================
Purpose: Test Suite for ConversationWindowController
-------

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-11-22  Initial development.
*/
@isTest
public with sharing class ConversationWindowControllerTest {
    
    @TestSetup static void createTestData(){
        insert new Conversation__c(ConversationId__c='12345678910',Status__c='New');
    }

    @isTest static void testGetConversationId(){

        Id recordId = [Select Id From Conversation__c].Id;

        test.startTest();
            ConversationWindowController.getConversationId(recordId);
        test.stopTest();
    }

}