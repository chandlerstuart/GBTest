/*
Name:  StartAConversationResponseHandlerAction.cls
======================================================
======================================================
Purpose:
-------
Flow action for deserializing 'Start a Conversation' request response
into apex defined data types that can be referenced within the flow.
====================================================== 
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2023-01-25  Initial development
*/
public with sharing class StartAConversationResponseHandlerAction {
    
    @InvocableMethod(label='Get Data' description='Returns response details from start a conversation response body' category='SMS')
    public static List<Result> getData(List<Request> requests) {

        List<Result> results = new List<Result>();
        for(Request r : requests){
            results.add((Result)JSON.deserialize(r.jsonResponseBody,StartAConversationResponseHandlerAction.Result.class));
        }
        return results;
    }

    public class Request {
        @InvocableVariable(label='JSON Response Body' description='The JSON body returned by the API request' required=true)
        public String jsonResponseBody;

        public request(){}
    }
  
    public class Result {
        @InvocableVariable(label='Success')
        public Boolean success;
        @InvocableVariable(label='Conversation Id')
        public String conversationId;
        @InvocableVariable(label='Error Message')
        public String errorMessage;

        public result(){}
    }

}