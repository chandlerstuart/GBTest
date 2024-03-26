/**
History
------- 
Ver. Author          Date       Detail
1.1  J Radcliffe     2018-08-20 Exit trigger when GBWire.WorkItemTriggerHandler.disableLocalTriggers = true
1.1  J Radcliffe     2019-10-17 After Delete Trigger
1.2  M Cane          2019-11-13 Before Insert Trigger event added.
1.3  J Radcliffe     2023-06-04 Before Delete Trigger event added.
*/ 
trigger AccountTrigger on Account (before update, after update, before insert, after insert, after delete, before delete) {

    // Org Wide Settings to check whether this Apex trigger should run or not?
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if( (orgSettings<> null && !orgSettings.TriggersActive__c) /*1.1*/ || GBWire.WorkItemTriggerHandler.disableLocalTriggers ){
        return;
    }
    
    if (Trigger.isBefore){
        AP01_AccountTriggerHandler accountHandler = new AP01_AccountTriggerHandler();
        if (Trigger.isUpdate){
            system.debug('Old:'+Trigger.OldMap.values());
            system.debug('New:'+Trigger.newMap.values());
            accountHandler.OnBeforeUpdate(Trigger.new, Trigger.newMap, Trigger.oldMap);
        }
        if (Trigger.isInsert) {//1.2+
            accountHandler.OnBeforeInsert(Trigger.new);        
        }        
        if (Trigger.isDelete){//1.3+
            accountHandler.OnBeforeDelete(Trigger.old); 
        }
    }
    
    if( Trigger.isAfter) {
        AP01_AccountTriggerHandler accountHandler = new AP01_AccountTriggerHandler();
        if( Trigger.isUpdate ){
            accountHandler.OnAfterUpdate(Trigger.new, Trigger.newMap, Trigger.oldMap);        
        }

        if (Trigger.isInsert) {
            S2SExternalSharingHelper h = new S2SExternalSharingHelper();
            h.shareRecordsFromTrigger(Trigger.new, null, 'Account');
            //2017-07-14 : SM : COMMENTED OUT FOR PHASE 1
            accountHandler.OnAfterInsert(trigger.new, trigger.newMap, null);
        }

        if (Trigger.isDelete){//1.1+
            accountHandler.OnAfterDelete(Trigger.old);
        }
    }

    
}