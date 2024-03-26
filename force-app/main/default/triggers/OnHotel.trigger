/*
Name:  OnHotel.trigger
Copyright © 2015 CloudMethods
======================================================
======================================================
Purpose:
-------
Single Trigger pattern - all actions are delegated to the handler class.
Enforces the single trigger per action optimisations.
Multiple triggers defined for an action share the same context - and therefore execution limits.
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2015-05-11  Initial Development.
1.1  Simon Molloy  2017-11-17  New code to filter those records before sharing that have a successfully shared parent
*/
trigger OnHotel on Hotel__c (after insert) {

    //& Respect the org-level behaviour setting.                                      
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if (!orgSettings.TriggersActive__c) return;
                                                                                      
    /* 
    2017-11-17 : SM : If we do not have a shared parent record we must schedule the sharing for the future
    2017-11-17 : SM : to give the parent time to be shared correctly
    */
    if (Trigger.isInsert && Trigger.isAfter) {
        Map<Id, SObject> processMap = S2SExternalSharingHelper.filterRecords(Trigger.new, 'Hotel__c', 'Account__c', 'Account');
        List<Hotel__c> processList = new List<Hotel__c>();
        Set<Id> recordIds = new Set<Id>();

        for (Hotel__c h : Trigger.new){
            if (processMap.containsKey(h.Id)){
                processList.add(h);
            }else {
                recordIds.add(h.Id);
            }
        }

        if (null != processList && !processList.isEmpty()){
           
            S2SExternalSharingHelper h = new S2SExternalSharingHelper();
            h.shareRecordsFromTrigger(processList, 'Account__c', 'Hotel__c', true);    
        
        }
        
        if (null != recordIds && !recordIds.isEmpty()){

            S2SExternalSharingHelper.scheduleSharing(recordIds, 'Hotel__c','Account__c',NULL);
        }
        
    }
    /* */
}