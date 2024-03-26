/*
Name:  DataEventRequestTriggerHandler.cls
Copyright © 2022  Golfbreaks
======================================================
======================================================
Purpose:
-------

Trigger handler for the Custom Object Trigger : DataEventRequestTrigger.

Logic (CronTrigger management)
(1) DETM calls DeferredDataEventTypeHelper.createDeferredRequests to create/update DER.

(2) On insert or update -> 
for each der if the Callouttime is different from the CRON next trigger time then..
..Cancel the row-specific Schedulable
..Reschedule the row-specific Schedulable
If der is updated to aborted or complete then abort the related cron.

(3) DataEventRequestSchedulable ->
On execute - call DETM with override to ensure OC are generated.

======================================================
======================================================
Permissions Model:
-----------------
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2022-06-20  Initial development.
*/
public with sharing class DataEventRequestTriggerHandler {
    //& indicates whether the script is executing in a Trigger context.
    private Boolean isExecuting = false;
    private Integer batchSize = 0;
    
    public DataEventRequestTriggerHandler(Boolean isExecuting, Integer size){
        this.isExecuting = isExecuting;
        this.batchSize = size;        
    }
           
    //& trigger action methods.        
    public void onBeforeInsert(DataEventRequest__c[] insertedRecords){
        try {

            Map<String,Datetime> detToNextCalloutDt = new Map<String,Datetime>();

            for (DataEventRequest__c der : insertedRecords){
                if (der.Status__c!='New') continue;

                if (!detToNextCalloutDt.containsKey(der.DataEventType__c)) detToNextCalloutDt.put(der.DataEventType__c,null);

                if (detToNextCalloutDt.get(der.DataEventType__c)==null || (der.CalloutDate__c!=null && der.CalloutDate__c<detToNextCalloutDt.get(der.DataEventType__c))) detToNextCalloutDt.put(der.DataEventType__c,der.CalloutDate__c);
            }

            if (detToNextCalloutDt.isEmpty()) return;

            for (String dataEventTypeName : detToNextCalloutDt.keySet()){
                if (detToNextCalloutDt.get(dataEventTypeName)==null) continue;
                
                DeferredDataEventTypeHelper.rescheduleCron(dataEventTypeName,detToNextCalloutDt.get(dataEventTypeName));
            }

        } catch(exception e){ LogHelper.logExceptions(e, 'DataEventRequestTriggerHandler', 'onBeforeInsert'); }
    }

    public void onBeforeUpdate(DataEventRequest__c[] updatedRecords, Map<Id,DataEventRequest__c> oldMap){
        try {
            

            Map<String,Datetime> detToNextCalloutDt = new Map<String,Datetime>();

            for (DataEventRequest__c der : updatedRecords){
                if (der.Status__c!='New') continue;
                if (der.CalloutDate__c==null || der.CalloutDate__c==oldMap.get(der.Id).CalloutDate__c) continue;

                if (!detToNextCalloutDt.containsKey(der.DataEventType__c)) detToNextCalloutDt.put(der.DataEventType__c,null);

                if (detToNextCalloutDt.get(der.DataEventType__c)==null || (der.CalloutDate__c!=null && der.CalloutDate__c<detToNextCalloutDt.get(der.DataEventType__c))) detToNextCalloutDt.put(der.DataEventType__c,der.CalloutDate__c);
            }

            if (detToNextCalloutDt.isEmpty()) return;

            for (String dataEventTypeName : detToNextCalloutDt.keySet()){
                if (detToNextCalloutDt.get(dataEventTypeName)==null) continue;
                
                DeferredDataEventTypeHelper.rescheduleCron(dataEventTypeName,detToNextCalloutDt.get(dataEventTypeName));
            }            

        } catch(exception e){ LogHelper.logExceptions(e, 'DataEventRequestTriggerHandler', 'onBeforeUpdate'); }
    }    
    //& end trigger action methods.
}