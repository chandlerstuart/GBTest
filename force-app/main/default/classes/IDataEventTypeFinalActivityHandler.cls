/*
Name:  IDataEventTypeFinalActivityHandler.cls
======================================================
======================================================
Purpose:
-------
Interface class - provides abstracted pluggable interface for 
handling any final actions following a callout.
This action is invoked AFTER the response handler and is only 
executed if the callout has no remaining child callouts 
(executed for the final callout in a sequence). 

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2021-02-11  Initial development.
*/
global interface IDataEventTypeFinalActivityHandler {
    void execute(DataEventType__mdt det, OutboundCallout__c oc);
}