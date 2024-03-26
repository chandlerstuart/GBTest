/*
Name:  IOutboundCalloutGenerator.cls
======================================================
======================================================
Purpose:
-------
Interface class - provides abstracted pluggable interface for generating Outbound Callouts to add to the OC queue. 

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2021-01-26  Initial development.
*/
global interface IOutboundCalloutGenerator {
    //Inputs:
    //DET mdt Configuration
    //Scheduled Job Id passed from the Scheduleable Job that initiated processing of Scheduled Events
    List<OutboundCallout__c> buildOutboundCalloutList(DataEventType__mdt det, Id scheduledJobId);
}