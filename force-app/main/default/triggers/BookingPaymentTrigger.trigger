/*
Name:  BookingPaymentTrigger.trigger
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
1.0  Mark Cane&    2021-11-02  Initial Development.
1.1  Chandler S    2023/07/05  Act On It - Implemented Act On It Trigger
*/
trigger BookingPaymentTrigger on Booking_Payment__c (after insert, after update, after delete, after undelete){ 

    //& Respect the org-level behaviour settings.
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if( (orgSettings!=null && !orgSettings.TriggersActive__c) || GBWire.WorkItemTriggerHandler.disableLocalTriggers ){ return; }

    //1.0- if (!Test.isRunningTest()) return;//2021-11-03. unit testing only.

    BookingPaymentTriggerHandler handler = new BookingPaymentTriggerHandler(Trigger.isExecuting, Trigger.size);

    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUndelete)) {
        handler.onAfterInsert(Trigger.new, Trigger.newMap);
    } else if (Trigger.isAfter && Trigger.isUpdate) {
        handler.onAfterUpdate(Trigger.new, Trigger.newMap, Trigger.oldMap);
    } else if (Trigger.isAfter && Trigger.isDelete) {
        handler.onAfterDelete(Trigger.old, Trigger.oldMap);
    } else if (Trigger.isAfter && Trigger.isUndelete){
        handler.onAfterUndelete(Trigger.new, Trigger.newMap);
    }
    
    // Act On It - Trigger 
    ActOnIt.ActOnItGlobalTriggerHandler.processTriggerRecords(trigger.oldMap, trigger.newMap); 
    
}