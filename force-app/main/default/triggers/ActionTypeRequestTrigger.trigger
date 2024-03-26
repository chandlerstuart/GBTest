/*
Name:  ActionTypeRequestTrigger.trigger
Copyright © 2023  Golfbreaks
======================================================
======================================================
Purpose:
-------
 
Object trigger for the Custom Object : ActionTypeRequest__c

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2023-11-22  Initial development.
*/
trigger ActionTypeRequestTrigger on ActionTypeRequest__c (after insert, after update){
    ActionTypeRequestTriggerHandler handler = new ActionTypeRequestTriggerHandler(Trigger.isExecuting, Trigger.size);

    /* */    
    if (Trigger.isInsert && Trigger.isAfter){
        handler.onAfterInsert(Trigger.new);
    }/* */   

    /* */    
    if (Trigger.isUpdate && Trigger.isAfter){
        handler.onAfterUpdate(Trigger.new,Trigger.oldMap);
    }/* */
}