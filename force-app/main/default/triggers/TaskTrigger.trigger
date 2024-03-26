/**
   @Author: Nicole de Guzman/Renz Melecotones
   @name: TaskTrigger
   @CreateDate: 03.04.2016
   @Description: Trigger for Task
   @Version <1.0>
*/ 
trigger TaskTrigger on Task (before insert, before update, before delete,  after insert, after update, after delete, after undelete) {

    // Org Wide Settings to check whether this Apex trigger should run or not -- Added by Nicole DG May 7, 2016 - Code Review Implementation
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if(orgSettings <> NULL && !orgSettings.TriggersActive__c){
        return;
    }

    AP19_TaskTriggerHandler handler = new AP19_TaskTriggerHandler();
    
    if( Trigger.isBefore ){
        /* Before Insert */
        if( Trigger.isInsert ){
            handler.OnBeforeInsert(Trigger.new);
        }
        /* Before Update */
        if( Trigger.isUpdate ){
            handler.OnBeforeUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
        }
        /* Before Delete */
        if( Trigger.isDelete ){
            handler.OnBeforeDelete(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
        }
    }
    else if( Trigger.isAfter ){
        /* After Insert */
        if( Trigger.isInsert ){         
            handler.OnAfterInsert(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
        }
        /* After Update */
        if( Trigger.isUpdate ){
            handler.OnAfterUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
        }
        /* After Delete */
        if( Trigger.isDelete ){
            handler.OnAfterDelete(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
        }
    }
    /* After Undelete */
    else if( Trigger.isUnDelete ){
        handler.OnUndelete(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
    }
}