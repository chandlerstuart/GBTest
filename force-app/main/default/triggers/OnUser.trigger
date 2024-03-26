/*
Name:  OnUser.trigger
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Trigger for User. Uses UserTriggerHandler.cls to 
handle all logic.

======================================================
======================================================
History
------- 
Ver. Author                Date                  Detail
1.0  Örn Ingvar          2014-08-13     Initial development.
1.1  J Radcliffe         2021-01-21     Enabling Object for ActOnIt alerts

*/
trigger OnUser on User (after update, after insert, before insert, before update ) {//1.1~

     //Respect the org-level behaviour setting. 
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if (!orgSettings.TriggersActive__c) return;

    ActOnIt.ActOnItGlobalTriggerHandler.processTriggerRecords(trigger.oldMap, trigger.newMap);//1.1+ 

    UserTriggerHandler handler = new UserTriggerHandler(Trigger.isExecuting, Trigger.size);

    /* */
    if (Trigger.isUpdate && Trigger.isAfter) {
        handler.onAfterUpdate(Trigger.new, Trigger.newMap, Trigger.oldMap);
    }
}