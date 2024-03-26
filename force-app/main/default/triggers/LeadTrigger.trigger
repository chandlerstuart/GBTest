/**
   @Authors: Alyanna N, Majoy M, Nicole DG, Ivy A
   @name: LeadTrigger
   @CreateDate: 06.04.2016
   @Description: Trigger for Lead
   @Version <1.0>
   
History
------- 
Ver. Author          Date       Detail
1.1  J Radcliffe     2018-08-03 Exit trigger when invoked during a WIRE context
1.2  J Radcliffe     2018-08-20 Replacing 'isRunningWIRE' with 'disableLocalTriggers' variable - Support for exiting triggers when GBWire.WorkItemTriggerHandler.disableLocalTriggers = true;
   
 */ 
trigger LeadTrigger on Lead (before Insert, after Insert, before Update, after Update, before Delete, after Delete, after UnDelete) {
        
    // Org Wide Settings to check whether this Apex trigger should run or not -- Added by M. Cebrian May 6, 2016 - Code Review Implementation
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    
    if( (orgSettings<> null && !orgSettings.TriggersActive__c) /*1.1|| GBWire.WorkItemTriggerHandler.isRunningWIRE == true */ /*1.2*/ || GBWire.WorkItemTriggerHandler.disableLocalTriggers){
        return;
    }
    
    AP03_LeadTriggerHandler handler = new AP03_LeadTriggerHandler();

        if( Trigger.isBefore ){
        /* Before Insert */
        if( Trigger.isInsert ){
            handler.OnBeforeInsert(Trigger.new);
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