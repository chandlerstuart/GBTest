/*
Name:  GXPMessengerCanvasCMPController
Copyright © 2022  Golfbreaks
======================================================
======================================================
Purpose:
-------
Controller for GXPMessengerCanvasCMP aura component. 
This component displays a (canvas) window through to the
GXP message center where agents can engage in SMS/WhatsApp
conversations with a customer.

The controller is responsible for collecting the data required
by the app and passing as parameters.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-12-05  Initial development.
*/
public with sharing class GXPMessengerCanvasCMPController{

    public class CustomException extends Exception{}
    @TestVisible public static Boolean throwException = false;
    
    @AuraEnabled
    public static Map<String,Object> getCanvasAppData(Id recordId){ 
        try {
            if(recordId == null) return null;
            Map<String,Object> canvasParams = new Map<String,Object>();
            canvasParams.put('salesforceId',recordId);
            String conversationId = [Select Id, ConversationId__c From Conversation__c Where Id = :recordId].ConversationId__c;
            canvasParams.put('conversationId',conversationId);
            if(throwException){throw new CustomException('Whoops, something went wrong');}
            return canvasParams;
        } catch (Exception e) {
            Golfbreaks.PlatformLogManager.logExceptions(e, 'GXPMessengerCanvasCMPController', 'getCanvasAppData');
            throw new AuraHandledException(e.getMessage()+'-'+e.getStackTraceString());
        }
    }

}