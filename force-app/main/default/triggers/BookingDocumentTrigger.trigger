/**
History
------- 
Ver. Author          Date           Detail
1.1  J Radcliffe     2022-03-04     Initial Development
*/ 
trigger BookingDocumentTrigger on BookingDocument__c (after insert, after delete) {

    // Org Wide Settings to check whether this Apex trigger should run or not
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if( (orgSettings<> null && !orgSettings.TriggersActive__c) || GBWire.WorkItemTriggerHandler.disableLocalTriggers ){
        return;
    }

    BookingDocumentTriggerHandler bookingDocumentHandler = new BookingDocumentTriggerHandler();

    if (Trigger.isAfter){
        if (Trigger.isInsert) {
            bookingDocumentHandler.OnAfterInsert(Trigger.new, Trigger.newMap);        
        }   
        if(Trigger.isDelete){
            bookingDocumentHandler.OnAfterDelete(Trigger.old, Trigger.oldMap);
        }
    }

}