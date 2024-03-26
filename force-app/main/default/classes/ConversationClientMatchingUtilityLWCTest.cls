/*
Name:  ConversationClientMatchingUtilityLWCTest.cls
Copyright © 2022  Golfbreaks
======================================================
======================================================
Purpose: 
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-11-30  Initial development.
*/
@isTest
public with sharing class ConversationClientMatchingUtilityLWCTest {

    public static final String testPhoneNumber = '+447944444444';

    @TestSetup static void createTestData(){
        //Create 10 accounts
        List<Account> accs = AP23_TestDataFactory.createPersonAccount(10,false);
        for(Integer i=0;i<5;i++){//Apply phone to 5 of the 10 accounts
            accs[i].PersonMobilePhone = testPhoneNumber;
        }
        insert accs;

        insert new Conversation__c(PhoneNumber__c=testPhoneNumber,Status__c='New',InitiatedBy__c='client',Account__c=null);
    }

    
    @isTest static void findClientsTest(){

        String recordId = [Select Id From Conversation__c].Id;

        List<Account> accs;
        test.startTest();
            accs = ConversationClientMatchingUtilityLWC.findClients(recordId);
        test.stopTest();

        system.assertEquals(5, accs.size());//5 accounts returned
    }

    @isTest static void setAccountIdTest(){
        Conversation__c c = [Select Id, Account__c From Conversation__c];
        system.assertEquals(null, c.Account__c);

        Account acc = [Select Id From Account Limit 1];

        test.startTest();
            ConversationClientMatchingUtilityLWC.setAccountId(c.Id, acc.Id);
        test.stopTest();

        system.assertEquals(acc.Id, [Select Id, Account__c From Conversation__c].Account__c);

    }

}