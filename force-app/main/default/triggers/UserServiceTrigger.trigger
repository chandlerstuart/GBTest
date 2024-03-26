trigger UserServiceTrigger on UserServicePresence ( after insert, after update, before insert, before update, before delete, after delete )
{
    //TriggerFactory.createHandler(AP08_UserServicePresenceTriggerBL.class);
    AP45_UserServiceTriggerHandler handler = new AP45_UserServiceTriggerHandler();
    
    if (trigger.isBefore){
        if (trigger.isInsert){
            handler.OnBeforeInsert(trigger.new);
        }
        if (trigger.isUpdate){
            handler.OnBeforeUpdate(trigger.new, trigger.newMap, trigger.old, trigger.oldMap);
        }
    }
    
    if (trigger.isAfter){
        if (trigger.isInsert){
            handler.OnAfterInsert(trigger.new);
        }
        if (trigger.isUpdate){
            handler.OnAfterUpdate(trigger.new, trigger.newMap, trigger.old, trigger.oldMap);
        }
    }

    //2017-02-23 : SM : New method call
    //We need to call a bulkified method to send notification emails if a user has gone offline unexpectedly
    //if (trigger.isAfter){
    //  if (trigger.isUpdate){
    //      AP08_UserServicePresenceTriggerBL.sendNotificationEmails(trigger.new, trigger.oldMap);
    //  }
    //}
}