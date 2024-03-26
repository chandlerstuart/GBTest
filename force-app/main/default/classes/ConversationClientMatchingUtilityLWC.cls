/*
Name:  ConversationClientMatchingUtilityLWC.cls
Copyright © 2022  Golfbreaks
======================================================
======================================================
Purpose: Controller for Conversation Client Matching Utility
-------
This utility performs a search for Accounts with a 
matching phone number to make recommendations for the agent
to connect the conversation to the account.
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-11-30  Initial development.
*/
public with sharing class ConversationClientMatchingUtilityLWC {
   @AuraEnabled
   public static List<Account> findClients(String recordId){
        try {
            if(recordId == null) return null;
            Conversation__c conversation = [Select Id, Account__c, PhoneNumber__c From Conversation__c Where Id = :recordId];
            if(conversation.PhoneNumber__c == null || conversation.Account__c != null) return null;//Exit if Account already assigned or no number can be identified.
            return [Select Id, FirstName, LastName, PersonEmail From Account Where PersonMobilePhone = :conversation.PhoneNumber__c or PersonOtherPhone = :conversation.PhoneNumber__c or PersonHomePhone = :conversation.PhoneNumber__c or Phone = :conversation.PhoneNumber__c];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage()+'-'+e.getStackTraceString()); 
        }
   }

   @AuraEnabled
   public static boolean setAccountId(String recordId, Id accountId){
        try {
            if(recordId == null 
            || accountId == null) return false;
            update new Conversation__c(Id=recordId,Account__c=accountId);
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage()+'-'+e.getStackTraceString()); 
        }
   }
}