/*
Name:  GolfbreaksBusinessUnitTrigger
Copyright © 2018  Golfbreaks
======================================================
======================================================
Purpose:
-------

Centralised trigger for the Custom Object : Golfbreaks_Business_Unit__c

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-05-08  Initial development.
1.1  Mark Cane&    2023-02-08  Added support for Entity Administration Lock protection.
*/
trigger GolfbreaksBusinessUnitTrigger on Golfbreaks_Business_Unit__c (before delete, after insert, before update, after update) {

    golfbreaks.EntityAdministrationLockManager.checkPermissions();//1.1+

    // Org Wide Settings to determine whether this Apex trigger should run
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if(orgSettings != null && !orgSettings.TriggersActive__c) return;   

    GolfbreaksBusinessUnitTriggerHandler handler = new GolfbreaksBusinessUnitTriggerHandler();

    if(trigger.isBefore){
        if(trigger.isDelete){
            handler.onBeforeDelete(trigger.old);
        }
    }

    if(trigger.isAfter){
        if(trigger.isInsert){
            handler.onAfterInsert(trigger.new,trigger.newMap);
        }
        if(trigger.isUpdate){
            handler.onAfterUpdate(trigger.newMap, trigger.oldMap);
        }
    }
}