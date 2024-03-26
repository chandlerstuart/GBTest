/*
Name:  OnContact.trigger
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
1.0  Mark Cane&    2015-05-06  Initial Development.
*/
trigger OnContact on Contact (after insert) {

	//& Respect the org-level behaviour setting.                            	      
	OrgSettings__c orgSettings = OrgSettings__c.getInstance();
	if (!orgSettings.TriggersActive__c) return;
		                            	                      	                      
    /* */
    if (Trigger.isInsert && Trigger.isAfter) {
    	S2SExternalSharingHelper h = new S2SExternalSharingHelper();
    	h.shareRecordsFromTrigger(Trigger.new, 'AccountId', 'Contact', true);
    }
    /* */
}