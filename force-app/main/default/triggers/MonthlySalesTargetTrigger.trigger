trigger MonthlySalesTargetTrigger on Monthly_Sales_Target__c (before insert, before update, before delete,  after insert, after update, after delete, after undelete) {
	
	AP41_MonthlySalesTargetTriggerHandler handler = new AP41_MonthlySalesTargetTriggerHandler();
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
}