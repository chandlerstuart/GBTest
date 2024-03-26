/*
Name:  OnSupplierAgreement.trigger
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
Ver. Author           Date        Detail
1.0  Simon Molloy     2015-05-11  Initial Development.
*/
trigger OnSupplierAgreement on Supplier_Agreement__c (after insert) {
    //& Respect the org-level behaviour setting.                                      
    OrgSettings__c orgSettings = OrgSettings__c.getInstance();
    if (!orgSettings.TriggersActive__c) return;
                                                                                      
    /* 
    2017-11-17 : SM : If we do not have a shared parent record we must schedule the sharing for the future
    2017-11-17 : SM : to give the parent time to be shared correctly
    */
    if (Trigger.isInsert && Trigger.isAfter) {
        Map<Id, SObject> processMap = S2SExternalSharingHelper.filterRecords(Trigger.new, 'Supplier_Agreement__c', 'Account__c', 'Account');
        List<Supplier_Agreement__c> processList = new List<Supplier_Agreement__c>();
        Set<Id> recordIds = new Set<Id>();

        for (Supplier_Agreement__c s : Trigger.new){
            if (processMap.containsKey(s.Id)){
                processList.add(s);
            }else {
                recordIds.add(s.Id);
            }
        }

        if (null != processList && !processList.isEmpty()){
           
            S2SExternalSharingHelper h = new S2SExternalSharingHelper();
            h.shareRecordsFromTrigger(processList, 'Account__c', 'Supplier_Agreement__c', false);    
        
        }
        
        if (null != recordIds && !recordIds.isEmpty()){

            S2SExternalSharingHelper.scheduleSharing(recordIds, 'Supplier_Agreement__c','Account__c',NULL);
        }
        
    }
    /* */
}