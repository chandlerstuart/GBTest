/*
Name:  StartAConversationResponseHandlerTest.cls
======================================================
======================================================
Purpose:
-------
Test Suite for StartAConversationResponseHandler.cls 
====================================================== 
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-11-30  Initial development
*/
@isTest
public with sharing class StartAConversationResponseHandlerTest {
    
    @isTest static void handleOutboundResponseTestSuccess(){

        system.assertEquals(0, [Select Count() From Conversation__c]);

        HttpResponse r = new HttpResponse();
        r.setBody('{"success":true,"conversationId":"63d123268528dce9855c3b9f","errorMessage":""}');

        Boolean isSuccess;
        test.startTest();
            isSuccess = StartAConversationResponseHandler.handleOutboundResponse(r, null, null, new Set<Id>{UserInfo.getUserId()});
        test.stopTest();

        system.assertEquals(true, isSuccess);

        Conversation__c c = [Select Id, OwnerId, ConversationId__c, Status__c, InitiatedBy__c From Conversation__c];
        system.assertEquals(UserInfo.getUserId(), c.OwnerId);
        system.assertEquals('63d123268528dce9855c3b9f', c.ConversationId__c);
        system.assertEquals(StartAConversationResponseHandler.withClientStatus, c.Status__c);
        system.assertEquals(StartAConversationResponseHandler.initiatedByAgent, c.InitiatedBy__c);
    }

    @isTest static void handleOutboundResponseTestFailure(){

        system.assertEquals(0, [Select Count() From Conversation__c]);
        system.assertEquals(0, [Select Count() From Golfbreaks__PlatformLog__c]);

        HttpResponse r = new HttpResponse();
        r.setBody('');//No Id returned
 
        Boolean isSuccess;
        test.startTest();
            isSuccess = StartAConversationResponseHandler.handleOutboundResponse(r, null, null, new Set<Id>{UserInfo.getUserId()});
        test.stopTest();

        system.assertEquals(false, isSuccess);//Error returned to framework

        system.assertEquals(0, [Select Count() From Conversation__c]);//No conversation created
        system.assertEquals(1, [Select Count() From Golfbreaks__PlatformLog__c]);//Error logged

    }
}