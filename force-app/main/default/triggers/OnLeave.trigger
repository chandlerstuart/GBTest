/*
Name:  OnLeave.trigger
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Trigger for Leave__c. Uses LeaveTriggerHandler.cls to 
handle all logic.

======================================================
======================================================
History
------- 
Ver. Author                Date                  Detail
1.0  Halldór Örn        2014-06-16     Initial development.

*/

trigger OnLeave on Leave__c (before insert, after insert, before update, after update, before delete) {
    
     //& Respect the org-level behaviour setting. 
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if (!orgSettings.TriggersActive__c) return;

    
    LeaveTriggerHandler handler = new LeaveTriggerHandler(Trigger.isExecuting, Trigger.size);

    /* */
    if (Trigger.isInsert && Trigger.isBefore) {
        handler.onBeforeInsert(Trigger.new);
    }
    /* */

    if (Trigger.isInsert && Trigger.isAfter) {
        handler.onAfterInsert(Trigger.new, Trigger.newMap);
    }

    /* */
    if (Trigger.isUpdate && Trigger.isBefore) {
        handler.onBeforeUpdate(Trigger.new, Trigger.newMap, Trigger.oldMap);
    }
    /* */    
    
    if (Trigger.isUpdate && Trigger.isAfter) {
        handler.onAfterUpdate(Trigger.new, Trigger.newMap, Trigger.oldMap);
    }
    
    /* */
   
    if (Trigger.isDelete && Trigger.isBefore) {
        handler.onBeforeDelete(Trigger.old, Trigger.oldMap);
    }
  
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