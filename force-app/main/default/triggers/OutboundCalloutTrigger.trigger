/*
Name:  OutboundCalloutTrigger.trigger
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
 
Object trigger for the Custom Object : OutboundCallout__c

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-09-06  Initial development.
1.1  Mark Cane&    2019-10-07  Added before insert+update events.
*/
trigger OutboundCalloutTrigger on OutboundCallout__c (before insert, after insert, before update) {    
    OutboundCalloutTriggerHandler handler = new OutboundCalloutTriggerHandler(Trigger.isExecuting, Trigger.size);

    /* */    
    if (Trigger.isInsert && Trigger.isBefore){
        handler.onBeforeInsert(Trigger.new);
    }
    /* */   

    /* */    
    if (Trigger.isInsert && Trigger.isAfter){
        handler.onAfterInsert(Trigger.new);
    }
    /* */   

    /* */    
    if (Trigger.isUpdate && Trigger.isBefore){
        handler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
    /* */
}