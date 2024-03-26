/**
   @Author: Renz Melecotones
   @name: BookingTrigger
   @CreateDate: 22.03.2016
   @Description: Trigger for Booking__c
   @Version <1.0>

History
------- 
Ver. Author          Date       Detail
1.1  J Radcliffe     2018-08-20 Exit trigger when GBWire.WorkItemTriggerHandler.disableLocalTriggers = true
1.2  J Radcliffe     2020-11-19 Added ActOnIt support for Booking object (Invoke Global Trigger Handler)

*/ 
trigger BookingTrigger on Booking__c (before insert, before update, before delete,  after insert, after update, after delete, after undelete) {
    
    // Org Wide Settings to check whether this Apex trigger should run or not -- Added by M. Cebrian May 6, 2016 - Code Review Implementation
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if( (orgSettings<> null && !orgSettings.TriggersActive__c) /*1.1*/ || GBWire.WorkItemTriggerHandler.disableLocalTriggers ){
        return;
    }

    AP09_BookingTriggerHandler handler = new AP09_BookingTriggerHandler();

    if( Trigger.isBefore ){
        /* Before Insert */
        if( Trigger.isInsert ){
            handler.OnBeforeInsert(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
        }
        /* Before Update */
        if( Trigger.isUpdate ){
            handler.OnBeforeUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
        }
        /* Before Delete */
        if( Trigger.isDelete ){
            handler.OnBeforeDelete(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
        }
    }
    else if( Trigger.isAfter ){
        /* After Insert */
        if( Trigger.isInsert ){
            handler.OnAfterInsert(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
        }
        /* After Update */
        if( Trigger.isUpdate ){
            handler.OnAfterUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
        }
        /* After Delete */
        if( Trigger.isDelete ){
            handler.OnAfterDelete(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
        }
    }
    /* After Undelete */
    else if( Trigger.isUnDelete ){
        handler.OnUndelete(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
    }

    //1.1+
    ActOnIt.ActOnItGlobalTriggerHandler.processTriggerRecords(trigger.oldMap, trigger.newMap); 

}