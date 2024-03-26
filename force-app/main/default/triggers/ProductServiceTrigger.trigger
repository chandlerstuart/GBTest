/*
Name:  ProductServiceTrigger.cls
======================================================
======================================================
Purpose:
-------
Trigger on Product_Service__c object
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.0  Simon Molloy  2017-11-03   Initial development
*/
trigger ProductServiceTrigger on Product_Service__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
// Org Wide Settings to check whether this Apex trigger should run or not
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if( orgSettings<> null && !orgSettings.TriggersActive__c ){
        return;
    }
    
    AP66_ProductServiceTriggerHandler handler = new AP66_ProductServiceTriggerHandler();

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
        //if( Trigger.isDelete ){
        //    handler.OnBeforeDelete(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
        //}
    }
    else if( Trigger.isAfter ){
        /* After Insert */
        //if( Trigger.isInsert ){
        //    handler.OnAfterInsert(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
        //}
        /* After Update */
        //if( Trigger.isUpdate ){
        //    handler.OnAfterUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
        //}
        /* After Delete */
        //if( Trigger.isDelete ){
        //    handler.OnAfterDelete(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
        //}
    }
    /* After Undelete */
    //else if( Trigger.isUnDelete ){
    //    handler.OnUndelete(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
    //}
}