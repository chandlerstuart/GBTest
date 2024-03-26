/*
Name:  BookingTaskTrigger.trigger
Copyright © 2021 Golfbreaks
======================================================
======================================================
Purpose:
-------
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2022-05-16  Initial Development.
*/
trigger BookingTaskTrigger on BookingTask__c (before insert, before update, after undelete, after insert, after update, after delete){ 

    //& Respect the org-level behaviour settings.
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if( (orgSettings!=null && !orgSettings.TriggersActive__c) || GBWire.WorkItemTriggerHandler.disableLocalTriggers ){ return; }

    BookingTaskTriggerHandler handler = new BookingTaskTriggerHandler(Trigger.isExecuting, Trigger.size);

    /*if (Trigger.isBefore && Trigger.isInsert) {
        handler.onBeforeInsert(Trigger.new);
    } else if (Trigger.isBefore && Trigger.isUpdate) {
        handler.onBeforeUpdate(Trigger.new, Trigger.newMap, Trigger.oldMap);
    } else if (Trigger.isAfter && Trigger.isUndelete){
        handler.onAfterUndelete(Trigger.new);
    }*/
    
    if (Trigger.isAfter && Trigger.isInsert) {
        handler.onAfterInsert(Trigger.new, Trigger.newMap);
    } else if (Trigger.isAfter && Trigger.isUpdate) {
        handler.onAfterUpdate(Trigger.old, Trigger.oldMap, Trigger.new, Trigger.newMap);
    } else if (Trigger.isAfter && Trigger.isDelete){
        handler.onAfterDelete(Trigger.old,Trigger.oldMap);
    }
    
}