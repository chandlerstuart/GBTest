/*
Name:  StartAConversationRespHandlerActionTest.cls
======================================================
======================================================
Purpose:
-------
Test Suite for StartAConversationResponseHandlerActionTest.cls
====================================================== 
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2023-01-25  Initial development
*/
@isTest
public with sharing class StartAConversationRespHandlerActionTest {
    
    @isTest static void testResponseHandler(){

        String jsonResponse = '{"success":true,"conversationId":"63d123268528dce9855c3b9f","errorMessage":"No error, all good :)"}';

        test.startTest();
            List<StartAConversationResponseHandlerAction.Request> requests = new List<StartAConversationResponseHandlerAction.Request>();
            StartAConversationResponseHandlerAction.Request req = new StartAConversationResponseHandlerAction.Request();
            req.jsonResponseBody = jsonResponse;
            requests.add(req);

            StartAConversationResponseHandlerAction.Result res = StartAConversationResponseHandlerAction.getData(requests)[0];

            system.assertEquals('63d123268528dce9855c3b9f', res.conversationId);
            system.assertEquals(true, res.success);
            system.assertEquals('No error, all good :)', res.errorMessage);

        test.stopTest();

    }

}