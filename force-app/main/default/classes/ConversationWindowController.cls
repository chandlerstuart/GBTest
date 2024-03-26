/*
Name:  ConversationWindowController.cls
Copyright © 2022  Golfbreaks
======================================================
======================================================
Purpose: Controller for ConversationWindow lwc
-------

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-11-02  Initial development.
*/
public with sharing class ConversationWindowController {
    

    @AuraEnabled
    public static string getConversationId(String recordId){
        try {
            if(recordId == null) return null;
            return [Select ConversationId__c From Conversation__c Where Id =:recordId].ConversationId__c;} catch (Exception e) { throw new AuraHandledException(e.getMessage()+'-'+e.getStackTraceString());}
    }
}