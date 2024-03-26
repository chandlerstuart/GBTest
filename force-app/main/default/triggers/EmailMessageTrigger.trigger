/**
   @Author: Renz Melecotones
   @name: EmailMessageTrigger
   @CreateDate: 04.13.2016
   @Description: Trigger for EmailMessage
   @Version <1.0>
*/ 
trigger EmailMessageTrigger on EmailMessage (before insert, before update, before delete,  after insert, after update, after delete, after undelete) {

    // Org Wide Settings to check whether this Apex trigger should run or not 
    // Jerome To (ACN) May 10, 2016 - Code Review Implementation
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if( orgSettings<> null && !orgSettings.TriggersActive__c ){
        return;
    }
    
    AP25_EmailMessageTriggerHandler handler = new AP25_EmailMessageTriggerHandler();

    if( Trigger.isBefore ){
        /* Before Insert */
        if( Trigger.isInsert ){
            handler.OnBeforeInsert(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
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