/*
Name:  TerritoryTrigger
Copyright © 2018  Golfbreaks
======================================================
======================================================
Purpose:
-------

Centralised trigger for the Custom Object : Territory__c

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-05-07  Initial development.
1.1  J Radcliffe   2023-02-13  Added support for Entity Administration Lock protection.
*/
trigger TerritoryTrigger on Territory__c (before insert, before update, before delete, after insert, after update) {

    golfbreaks.EntityAdministrationLockManager.checkPermissions();//1.1+

    // Org Wide Settings to determine whether this Apex trigger should run
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if(orgSettings != null && !orgSettings.TriggersActive__c) return;

    TerritoryTriggerHandler handler = new TerritoryTriggerHandler();

    if(trigger.isBefore){
        if(trigger.isDelete){
            handler.onBeforeDelete(trigger.old);
        }
        if(trigger.isInsert){
            handler.onBeforeInsert(trigger.new);
        }
        if(trigger.isUpdate){
            handler.onBeforeUpdate(trigger.new,trigger.oldMap);
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