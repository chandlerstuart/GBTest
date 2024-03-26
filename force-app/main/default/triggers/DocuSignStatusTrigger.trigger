trigger DocuSignStatusTrigger on dsfs__DocuSign_Status__c (after insert, after update) {
    // Org Wide Settings to check whether this Apex trigger should run or not?
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if( (orgSettings != null && !orgSettings.TriggersActive__c) /*1.1*/ || GBWire.WorkItemTriggerHandler.disableLocalTriggers )return;

    ActOnIt.ActOnItGlobalTriggerHandler.processTriggerRecords(trigger.oldMap, trigger.newMap); 
}