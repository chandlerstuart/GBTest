/**
Name:  SalesAgentAttributesTrigger.cls
Copyright © 2016  GolfBreaks Offshore Team
======================================================
======================================================
Purpose:
-------
Master trigger for all the events and context variables of Sales_Agent_Attributes__c
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  M.Cebrian    2016-04-21  Initial development
**/
trigger SalesAgentAttributesTrigger on Sales_Agent_Attributes__c (after insert, after update) {
    
    //instantiate handler class
    AP37_SalesAgentAttributesHandler handler = new AP37_SalesAgentAttributesHandler();
    
    //handle after events
    if(Trigger.isAfter){
        System.debug(LoggingLevel.INFO, '>>> IS AFTER');
        if(Trigger.isInsert){
            System.debug(LoggingLevel.INFO, '>>> IS INSERT');
            handler.onAfterInsert(Trigger.newMap);
        }
        else if(Trigger.isUpdate){
            System.debug(LoggingLevel.INFO, '>>> IS UPDATE');
            handler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
        }
    }
}