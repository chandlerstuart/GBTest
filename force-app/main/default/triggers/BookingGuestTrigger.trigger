/**
History
------- 
Ver. Author          Date           Detail
1.1  J Radcliffe     2021-09-10     Initial Development
1.2  J Radcliffe     2024-02-13     New trigger event: before insert
*/ 
trigger BookingGuestTrigger on BookingGuest__c (before update, after update, after insert, before insert) {

    // Org Wide Settings to check whether this Apex trigger should run or not?
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if( (orgSettings<> null && !orgSettings.TriggersActive__c) || GBWire.WorkItemTriggerHandler.disableLocalTriggers ){
        return;
    }
 
    BookingGuestTriggerHandler bookingGuestHandler = new BookingGuestTriggerHandler();
    if (Trigger.isBefore){
        if (Trigger.isUpdate){
            bookingGuestHandler.onBeforeUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
        }    
        if (Trigger.isInsert){//1.2+
            bookingGuestHandler.onBeforeInsert(Trigger.new);
        } 
    }    

    if (Trigger.isAfter){
        if (Trigger.isInsert) {//1.2+
            bookingGuestHandler.OnAfterInsert(Trigger.new);        
        }   
        if (Trigger.isUpdate) {//1.2+
            bookingGuestHandler.OnAfterUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);        
        }   
    }
}