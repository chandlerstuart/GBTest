/**
   @Author: James Radcliffe
   @name: IndividualTrigger
   @CreateDate: 16/04/2018
   @Description: Trigger for Individual
   @Version <1.0>
*/ 
trigger IndividualTrigger on Individual (before insert, after insert, after update) {
    
    // Org Wide Settings to check whether this Apex trigger should run or not 
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if( orgSettings<> null && !orgSettings.TriggersActive__c ) return;
    
    //Instantiate handler
    IndividualTriggerHandlerV2 handler = new IndividualTriggerHandlerV2();
    
    if(trigger.isInsert){
        if(trigger.isAfter){
            handler.onAfterInsert(trigger.new, trigger.newMap);
        }
    }
    if(trigger.isUpdate){
        if(trigger.isAfter){
            handler.onAfterUpdate(trigger.old,trigger.oldMap, trigger.new, trigger.newMap);
        }
    }

}