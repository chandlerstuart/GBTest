/*
Name:
-----
OutboundCalloutLocalTrigger.trigger
================================================================
================================================================
Purpose:
------
A local trigger for non-packaged activity (activity outside the integration framework). Initially introduced to add support for Act On It alerting (i.e. invoking the Act On It application).
================================================================
================================================================
Verison  Author         Date        Detail
v1.0     J Radcliffe    14/02/23    Inital Deployment - AOI Trigger
v1.1     C Stuart       02/03/23    Org Settings Check
*/

trigger OutboundCalloutLocalTrigger on OutboundCallout__c (after insert, after update) {

    // check Should trigger's be running?
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if(orgSettings<> null && !orgSettings.TriggersActive__c) return;

    // ActOnIt triggers
    ActOnIt.ActOnItGlobalTriggerHandler.processTriggerRecords(trigger.oldMap, trigger.newMap);
}