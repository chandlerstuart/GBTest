/*
Name:  OnNVMCallSummary.trigger
Copyright © 2016 CloudMethods
======================================================
======================================================
Purpose:
-------
Single Trigger pattern - all actions are delegated to the handler class.
Enforces the single trigger per action optimisations.
Multiple triggers defined for an action share the same context - and therefore execution limits.
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2016-06-18  Initial Development.
*/
trigger OnNVMCallSummary on NVMStatsSF__NVM_Call_Summary__c (
                            before insert, 
                             after insert,
//                           before update
                             after update                               
//                           before delete 
//                           after delete
//                          after undelete
                            ) {

    //& Respect the org-level behaviour setting.                                      
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if (!orgSettings.TriggersActive__c) return;
                                                                                      
    NVMCallSummaryTriggerHandler handler = new NVMCallSummaryTriggerHandler(Trigger.isExecuting, Trigger.size);

    /* */
    if (Trigger.isInsert && Trigger.isBefore) {
        handler.onBeforeInsert(Trigger.new);
    }
    /* */
    /* */
    if (Trigger.isInsert && Trigger.isAfter) {
        handler.onAfterInsert(Trigger.new, Trigger.newMap);
    }
    /* */
    /* * /
    if (Trigger.isUpdate && Trigger.isBefore) {        
        handler.onBeforeUpdate(Trigger.new, Trigger.newMap, Trigger.oldMap);
    }
    /* */    
    if (Trigger.isUpdate && Trigger.isAfter) {
        handler.onAfterUpdate(Trigger.new, Trigger.newMap, Trigger.oldMap);
    }
    /* */
    /* * /
    if (Trigger.isDelete && Trigger.isBefore) {
        handler.onBeforeDelete(Trigger.old, Trigger.oldMap);
    }
    /* */
    /* * /
    if (Trigger.isDelete && Trigger.isAfter) {        
        handler.onAfterDelete(Trigger.old, Trigger.oldMap);
    } 
    /* */
    /* * / 
    if (Trigger.isUnDelete) {
        handler.onAfterUndelete(Trigger.new, Trigger.newMap);
    }
    /* */
}