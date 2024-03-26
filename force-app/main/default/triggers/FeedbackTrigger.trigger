/*
Name:  FeedbackTrigger
======================================================
======================================================
Purpose:
-------
Trigger for Feedback__c Object.

======================================================
======================================================
History
------- 
Ver. Author                Date             Detail
1.0  J Radcliffe           2021-01-21       Initial development. Enabling Object for ActOnIt Alerts
*/
trigger FeedbackTrigger on Feedback__c (before insert, before update, before delete, after undelete, after insert, after update) {
    
    // Org Wide Settings to check whether this Apex trigger should run or not?
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if( (orgSettings != null && !orgSettings.TriggersActive__c) /*1.1*/ || GBWire.WorkItemTriggerHandler.disableLocalTriggers )return;
    
    ActOnIt.ActOnItGlobalTriggerHandler.processTriggerRecords(trigger.oldMap, trigger.newMap); 

}