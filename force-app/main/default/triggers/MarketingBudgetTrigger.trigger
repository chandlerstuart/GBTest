trigger MarketingBudgetTrigger on MarketingBudget__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if( orgSettings<> null && !orgSettings.TriggersActive__c ) return;

    AP55_MarketingBudgetTriggerHandler handler = new AP55_MarketingBudgetTriggerHandler();

 //   if( Trigger.isBefore ){
 //       /* Before Insert */
 //       if( Trigger.isInsert ){
 //           handler.OnBeforeInsert(Trigger.new);
 //       }
 //       /* Before Update */
 //       if( Trigger.isUpdate ){
 //           handler.OnBeforeUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
 //       }
 //       /* Before Delete */
 //       if( Trigger.isDelete ){
 //           handler.OnBeforeDelete(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
 //       }
 //   }
 //   else 
 if( Trigger.isAfter ){
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
    ///* After Undelete */
    //else if( Trigger.isUnDelete ){
    //    handler.OnUndelete(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
    //}
}