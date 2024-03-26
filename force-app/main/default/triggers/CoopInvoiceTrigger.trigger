trigger CoopInvoiceTrigger on Co_op_Invoice__c (before insert, before update) {
    
    CoopInvoiceTriggerHandler handler = new CoopInvoiceTriggerHandler();
    
    if(Trigger.IsBefore){
    
        if(Trigger.IsInsert){
        handler.onBeforeInsert(Trigger.New);
        }
        
        if(Trigger.IsUpdate){
        handler.onBeforeUpdate(Trigger.NewMap,Trigger.OldMap);
        }
    }

}