/**
*  @Author: Jerella Ledesma
*  @name: AP21_NVMCallBackTriggerBL
*  @CreateDate: 04.09.2016
*  @Description: Handler Class for NVM Callback
*  @Version <1.0>
*  @Updated 05.11.2016 Atlee
*           05.12.2016 Jerome To - Added all event parameters on NVM_Call_Back__c
 */ 
trigger NVMCallBackTrigger on NVM_Call_Back__c ( before insert, after insert, before update, after update, before delete, after delete, after undelete){
    // Org Wide Settings to check whether this Apex trigger should run or not
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if( orgSettings<> null && !orgSettings.TriggersActive__c ){
        return;
    }

    if(Trigger.isAfter){ 
        AP44_NVMCallBackTriggerHandler NVMHandler = new AP44_NVMCallBackTriggerHandler();
        if(Trigger.isInsert){
            NVMHandler.afterInsert(Trigger.New);

        }

        if(Trigger.isUpdate){
            NVMHandler.afterUpdate(Trigger.oldMap, Trigger.newMap);
        }
        //TriggerFactory.createHandler(AP21_NVMCallBackTriggerBL.class);
    }
}