/**
  * @author -         Jerome To (ACN)
  * @date -           MAY 11, 2016
  * @description -    Trigger for CampaignForecast__c
  * #############Change Log#############
  * Modified by     Version     Change Date
  **/

trigger CampaignForecastTrigger on CampaignForecast__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
	OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if( orgSettings<> null && !orgSettings.TriggersActive__c ) return;

    AP47_CampaignForecastHandler handler = new AP47_CampaignForecastHandler();

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
    //else if( Trigger.isUnDelete ){
    //    handler.OnUndelete(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
    //}
}