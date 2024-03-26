/*
Name:  DataEventRequestTrigger.trigger
Copyright © 2022  Golfbreaks
======================================================
======================================================
Purpose:
-------
 
Object trigger for the Custom Object : DataEventRequest__c

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2022-06-20  Initial development.
*/
trigger DataEventRequestTrigger on DataEventRequest__c (before insert, before update) {    
    DataEventRequestTriggerHandler handler = new DataEventRequestTriggerHandler(Trigger.isExecuting, Trigger.size);

    /* */    
    if (Trigger.isInsert && Trigger.isBefore){
        handler.onBeforeInsert(Trigger.new);
    }/* */   

    /* */    
    if (Trigger.isUpdate && Trigger.isBefore){
        handler.onBeforeUpdate(Trigger.new,Trigger.oldMap);
    }/* */
}