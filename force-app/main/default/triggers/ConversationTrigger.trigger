/**
History
------- 
Ver. Author          Date        Detail
1.1  J Radcliffe     2022-11-01  Initial development
*/ 
trigger ConversationTrigger on Conversation__c (after insert, after update) {

    // Org Wide Settings to check whether this Apex trigger should run or not?
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if( (orgSettings<> null && !orgSettings.TriggersActive__c) || GBWire.WorkItemTriggerHandler.disableLocalTriggers ){
        return;
    }

    //Invoke AOI application (for trigger event messages/notifications)
    ActOnIt.ActOnItGlobalTriggerHandler.processTriggerRecords(trigger.oldMap, trigger.newMap);

    ConversationTriggerHandler handler = new ConversationTriggerHandler();

    if(Trigger.isAfter){
        if(Trigger.isUpdate){
            handler.onAfterUpdate(Trigger.oldMap,Trigger.newMap);
        }else if(Trigger.isInsert){
            handler.onAfterInsert(Trigger.newMap);
        }
    }

}