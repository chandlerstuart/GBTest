/*
Name:  OnBooking
Copyright © 2018  Golfbreaks
======================================================
======================================================
Purpose:
-------

Centralised trigger for the Custom Object : Booking__c

This trigger is not packaged as the Object exists outside
the package. Keeping this (GBWire) Trigger separate from 
the local trigger for consistency with the other packaged
Triggers

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2018-07-07  Initial development.
1.1  J Radcliffe   2018-07-30  Added support for disabling wire triggers
1.2  J.Radcliffe   2018-10-08  Disabling WIRE triggers on Insert triggers - Instead this functionality will be called via process builder (apex action) AFTER the Business Unit has been set (essential for Preferred Queue/CRP Calculation)
1.3  J.Radcliffe   2019-04-08  Retiring Trigger W-000071
*/
trigger OnBooking on Booking__c (after insert, after update) {
   
    //1.1
    //GBWire__RoutingEngineSettings__c res = GBWire__RoutingEngineSettings__c.getOrgDefaults();
    
    //1.1
    //if(!res.GBWire__DisableTriggers__c){
        
        //GBWire.WorkItemTriggerHandler handler = new GBWire.WorkItemTriggerHandler(ApplicationConstant.OBJECT_NAME_BOOKING);
        
        
        //if (Trigger.isInsert && Trigger.isAfter){
         //  handler.onAfterInsert(trigger.newMap, ApplicationConstant.OBJECT_NAME_BOOKING); <--- 1.2 Commented Out
        //}
        
        //if (Trigger.isUpdate && Trigger.isAfter){
         //   handler.onAfterUpdate(trigger.newMap, trigger.oldMap, ApplicationConstant.OBJECT_NAME_BOOKING);
        //}
    //}
   
}