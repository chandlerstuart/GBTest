/*
Name:
-----
RoutingLogEntryTrigger.trigger
================================================================
================================================================
Purpose:
------
Trigger built for the Routing Log Entry object
================================================================
================================================================
Verison  Author         Date        Detail
v1.0     C Stuart       20/03/2023  Inital Deployment -- Act On It Trigger
*/
trigger RoutingLogEntryTrigger on GBWire__RoutingLogEntry__c (after insert, after update) {

    // check Should Trigger's be running?
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if(orgSettings != null && !orgSettings.TriggersActive__c) return;
        
    // Act On It trigger
    ActOnIt.ActOnItGlobalTriggerHandler.processTriggerRecords(trigger.oldMap, trigger.newMap);
}