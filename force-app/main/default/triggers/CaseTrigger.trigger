/**
   @Author: Renz Melecotones
   @name: CaseTrigger
   @CreateDate: 09.03.2016
   @Description: Trigger for Case
   @Version <1.0>
   
History
------- 
Ver. Author          Date       Detail
1.1  J Radcliffe     2018-08-06 Exit trigger when invoked during a WIRE context
1.2  J Radcliffe     2018-08-20 Replacing 'isRunningWIRE' with 'disableLocalTriggers' variable - Support for exiting triggers when GBWire.WorkItemTriggerHandler.disableLocalTriggers = true;
*/

trigger CaseTrigger on Case (before insert, before update, before delete,  after insert, after update, after delete, after undelete) {

    // Org Wide Settings to check whether this Apex trigger should run or not | Jerome To | May 6, 2016 | Code Review Implementation
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if( (orgSettings<> null && !orgSettings.TriggersActive__c) /*1.1|| GBWire.WorkItemTriggerHandler.isRunningWIRE == true */ /*1.2*/ || GBWire.WorkItemTriggerHandler.disableLocalTriggers) return;

    AP01_CaseTriggerHandler handler = new AP01_CaseTriggerHandler();

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
}