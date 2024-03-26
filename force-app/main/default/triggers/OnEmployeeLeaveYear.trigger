/*
Name:  OnEmployeeLeaveYear.trigger
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Trigger for EmployeeLeaveYear__c. Uses EmployeeLeaveYearTriggerHandler.cls to 
handle all logic.

======================================================
======================================================
History
------- 
Ver. Author                Date                  Detail
1.0  Örn Ingvar          2014-08-13     Initial development.

*/
trigger OnEmployeeLeaveYear on EmployeeLeaveYear__c (
    before insert, 
    before update, 
    after insert
    ) {

    //Respect the org-level behaviour setting. 
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if (!orgSettings.TriggersActive__c) return;
    
    EmployeeLeaveYearTriggerHandler handler = new EmployeeLeaveYearTriggerHandler(Trigger.isExecuting, Trigger.size);

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

}