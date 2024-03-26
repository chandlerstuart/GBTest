/*
Name:  StartAConversationResponseHandler.cls
======================================================
======================================================
Purpose:
-------
Response Handler for 'Start a Conversation' Data Event Types.
This handler creates an initial conversation entry for the running user,
applying the conversation id returned by the response.
====================================================== 
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-11-24  Initial development
*/
public with sharing class StartAConversationResponseHandler implements IDataEventTypeResponseHandler3{

    public static final String withClientStatus = 'WithClient';
    public static final String initiatedByAgent = 'agent';

    public class CustomException extends Exception {}

    public class APIResponseData{
        public Boolean success;
        public String conversationId;
        public String errorMessage;
    }

    public static Boolean handleOutboundResponse(HttpResponse r, String reshapedResponseBody, Id outboundCalloutId, Set<Id> recordIds){
        
        try{
            if(r == null || r.getBody() == null || String.isBlank(r.getBody())) throw new CustomException('Cannot create conversation. Not data retuned in response body');

            String resBody = r.getBody();
            String extConversationId;
            if(!String.isBlank(resBody)){
                APIResponseData data = (StartAConversationResponseHandler.APIResponseData)JSON.deserialize(resBody, StartAConversationResponseHandler.APIResponseData.class);
                if(data != null) extConversationId = data.conversationId;
            }

            //Create a Conversation entry with basic information. 
            //Note - more detail is subsequently added from the flow calling the api.
            Conversation__c c = new Conversation__c();
            c.Status__c = withClientStatus;
            c.OwnerId = UserInfo.getUserId();
            c.InitiatedBy__c = initiatedByAgent;
            c.ConversationId__c = extConversationId;
            c.AssignTo__c = UserInfo.getUserEmail();
            insert c;

            return true;

        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'StartAConversationResponseHandler','handleOutboundResponse');
            return false;
        }

    }
}