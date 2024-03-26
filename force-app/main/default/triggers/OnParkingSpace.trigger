/*
Name:  OnParkingSpace.trigger
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Trigger for Parking_Space__c. Uses ParkingSpaceTriggerHandler.cls to 
handle all logic.

======================================================
======================================================
History
------- 
Ver. Author                Date                  Detail
1.0  Simon Molloy        2016-10-10              Initial development.

*/

trigger OnParkingSpace on Parking_Space__c (before insert, after insert, before update) {
    
     //& Respect the org-level behaviour setting. 
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if (!orgSettings.TriggersActive__c) return;

    
    ParkingSpaceTriggerHandler handler = new ParkingSpaceTriggerHandler(Trigger.isExecuting, Trigger.size);

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
    //TODO: This needs to be uncommented when the code is ready
    /*
    if (Trigger.isUpdate && Trigger.isAfter) {
        handler.onAfterUpdate(Trigger.new, Trigger.newMap, Trigger.oldMap);
    }
    */
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