/*
Name:  ActiveConversationController.cls
======================================================
======================================================
Purpose: Controller for Active Conversation aura cmp.
This component will surface the most recent active conversation
on the conversation's related parent record layout for easier access.
-------

======================================================
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2023-09-25  Initial development.
*/
public with sharing class ActiveConversationController {

    public class CustomException extends Exception{}
    
    //Dynamically retrieve the most recently modified active conversation for the record.
    @AuraEnabled
    public static Conversation__c getMostRecentActiveConversation(String recordId, String conversationLookupFieldName) {
        Conversation__c activeConversation;
        
        // Build and execute a dynamic query to get the most recent active conversation.
        String closedStatus = ApplicationConstant.CONVERSATION_STATUS_CLOSED;
        String query = 'SELECT Id, Name FROM Conversation__c WHERE ' + conversationLookupFieldName +' = :recordId AND Status__c != :closedStatus ORDER BY LastModifiedDate DESC LIMIT 1';

        try {
            List<Conversation__c> conversations = Database.query(query);
            if (!conversations.isEmpty()) {
                activeConversation = conversations[0];
            }
        } catch (QueryException e) {
            //Log configuration failures FOA the Salesforce Team
            Golfbreaks.PlatformLogManager.logExceptions(e,'ActiveConversationController','getMostRecentActiveConversation');
            throw e;
        }
        
        return activeConversation;
    }

    //Close the active conversation.
    @AuraEnabled
    public static boolean closeActiveConversation(String conversationId) {
        try{
            if(conversationId != null){
                update new Conversation__c(Id=conversationId,Status__c=ApplicationConstant.CONVERSATION_STATUS_CLOSED);
            }else throw new CustomException('No active conversation id specified in request');
            return true;
        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'ActiveConversationController','closeActiveConversation');
            throw new CustomException(e.getMessage()+'-'+e.getStackTraceString());
        }
    }



}