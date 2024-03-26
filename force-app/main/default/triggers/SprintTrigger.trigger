/*
Name:  SprintTrigger.trigger
======================================================
======================================================
Purpose:
-------
Trigger for SPrint__c. Uses SprintTriggerHandler.cls to 
handle all logic.

======================================================
======================================================
History
------- 
Ver. Author                Date                  Detail
1.0  James Radcliffe       2017-09-01            Initial development.

*/
trigger SprintTrigger on Sprint__c (before insert,before update) {

   SprintTriggerHandler handler = new SprintTriggerHandler();
   
   if(Trigger.IsBefore){
       if(Trigger.IsInsert){
           handler.onBeforeInsert(Trigger.new);
       }
       if(Trigger.IsUpdate){
           handler.onBeforeUpdate(Trigger.oldMap,Trigger.newMap);
       }
   }

}