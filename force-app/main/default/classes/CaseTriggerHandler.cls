/*
Name:  CaseTriggerHandler.cls
Copyright © 2014  CloudMethods
======================================================
======================================================
Purpose:
-------
Handler class for all trigger operations related to the Case standard object.
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2014-05-21  Initial development (added processPricingCaseAssignmentRules).
1.1  Mark Cane&    2014-05-29  Added checkPricingCaseEntitlementSet and managePricingCaseMilestoneStatus.
1.2  Mark Cane&    2014-09-10  Added processExternalSalesforceSupportCases.
1.3  Mark Cane&    2017-02-28  Commented-out processExternalSalesforceSupportCases.
*/
public with sharing class CaseTriggerHandler { 
    private Boolean isExecuting = false; //& indicates whether the script is executing in a Trigger context.
    private Integer batchSize = 0;

    //& statics to prevent recursive behaviour associated with update operations.
    //& (via W/F update later in the context sequence or direct in-trigger update or in-direct via roll-up (OLI, OLIS)).
    public static Boolean firstAfterUpdateRun = true;
    public static Boolean firstBeforeUpdateRun = true;
    
    public CaseTriggerHandler(boolean isExecuting, integer size){
        isExecuting = isExecuting;
        batchSize = size;
    }
            
    //& trigger action methods.    
    public void onBeforeInsert(Case[] insertedRecords){    
    	checkPricingCaseEntitlementSet(insertedRecords);
    	//1.3 processExternalSalesforceSupportCases(insertedRecords);  
    }
    
    //public void onAfterInsert(Case[] insertedRecords, Map<Id, Case> newMap){}
    
    public void onBeforeUpdate(Case[] updatedRecords, Map<Id, Case> newMap, Map<Id, Case> oldMap){
    	if (firstBeforeUpdateRun){
    		firstBeforeUpdateRun = false; // prevent recursive updates within applied logic. 
			
			managePricingCaseMilestoneStatus(updatedRecords,oldMap);
    	}
    }
    
    public void onAfterUpdate(Case[] updatedRecords, Map<Id, Case> newMap, Map<Id, Case> oldMap){ 
    	if (firstAfterUpdateRun){
    		firstAfterUpdateRun = false; // prevent recursive updates within applied logic. 
    		
    		processPricingCaseAssignmentRules(updatedRecords,oldMap);
    	}
    }
    
    //public void onBeforeDelete(List<Case> deletedRecords, Map<Id, Case> oldMap){}{}
    
    //public void onAfterDelete(List<Case> deletedRecords, Map<Id, Case> oldMap){}
    
    //public void onAfterUndelete(List<Case> undeletedRecords, Map<Id, Case> newMap){}
    
    //& End trigger action methods.
    
    
    //& helper methods.
	private void checkPricingCaseEntitlementSet(List<Case> insertedRecords){		
		try {			
			Map<String, Id> developerNameToRTId = AppHelper.getRecordTypesByDeveloperName('Case');						
			Id pricingCaseRTId=developerNameToRTId.get(AppConstants.CASE_RECORD_TYPE_DEVELOPER_NAME_PRICING);
			
			Map<Id,List<Case>> accountIdToCases = new Map<Id, List<Case>>();
			
			for (Case c : insertedRecords){
				// Pricing RT cases with an account specified and no entitlement set.				
				if (c.RecordTypeId==pricingCaseRTId && c.AccountId!=null && c.EntitlementId==null){					
					if (!accountIdToCases.containsKey(c.AccountId)){
						accountIdToCases.put(c.AccountId, new List<Case>());
					}
					accountIdToCases.get(c.AccountId).add(c);
				}			
			}		
			if (accountIdToCases.size()==0) return;
			
			Map<Id, Entitlement> accountIdToEntitlement = new Map<Id, Entitlement>();
			
			for (Entitlement e : [select Id, BusinessHoursId, AccountId from Entitlement where SlaProcess.Name=:AppConstants.ENTITLEMENT_PROCESS_NAME_PRICING_SLA and AccountId in:accountIdToCases.keySet()]){				
				accountIdToEntitlement.put(e.AccountId,e);				
			}
			if (accountIdToEntitlement.size()==0) return;
			
			for (List<Case> cases : accountIdToCases.values()){
				for (Case c : cases){
					if (accountIdToEntitlement.containsKey(c.AccountId)){
						c.EntitlementId=accountIdToEntitlement.get(c.AccountId).Id;
						if (accountIdToEntitlement.get(c.AccountId).BusinessHoursId!=null) c.BusinessHoursId=accountIdToEntitlement.get(c.AccountId).BusinessHoursId;
					}
				}
			}
		} catch (Exception e){
			System.debug(LoggingLevel.WARN, '->->Exception thrown : ' + e.getMessage());			
			//TODO - revisit approach to runtime exception handling.			
			for (Case c : insertedRecords){ c.addError(e.getMessage()); }
		}		
	}    
        
    private void managePricingCaseMilestoneStatus(List<Case> modifiedRecords, Map<Id, Case> oldMap){
    	try {
			Map<String, Id> developerNameToRTId = AppHelper.getRecordTypesByDeveloperName('Case');						
			Id pricingCaseRTId=developerNameToRTId.get(AppConstants.CASE_RECORD_TYPE_DEVELOPER_NAME_PRICING);    		
    		
    		Set<Id> startClockCaseIds = new Set<Id>();
    		Set<Id> stopClockCaseIds = new Set<Id>();
    		    		
    		for (Case c : modifiedRecords){
	    		if (c.RecordTypeId!=pricingCaseRTId) continue;
    		
    			if (c.Status==AppConstants.CASE_STATUS_ASSIGNED_TO_CASE_CREATOR 
    					&& oldMap.get(c.Id).Status!=AppConstants.CASE_STATUS_ASSIGNED_TO_CASE_CREATOR
    					&& c.EntitlementId!=null
    					&& !c.IsStopped){    				
    				c.IsStopped=true;    				
    			}
    		
    			if (c.Status==AppConstants.CASE_STATUS_ASSIGNED_TO_PRICING && oldMap.get(c.Id).Status!=AppConstants.CASE_STATUS_ASSIGNED_TO_PRICING    				
    					&& c.EntitlementId!=null
    					&& c.IsStopped){    				
    				c.IsStopped=false;    				    				
    			}    		
    		}    		    		
		} catch (Exception e){		
			System.debug(LoggingLevel.WARN, '->->Exception thrown : ' + e.getMessage());			
			//TODO - revisit approach to runtime exception handling.			
			for (Case c : modifiedRecords){ c.addError(e.getMessage()); }
    	}
    }
    
    private void processPricingCaseAssignmentRules(List<Case> modifiedRecords, Map<Id, Case> oldMap){    
    	// Note, we can't detect whether the "run assignment rules" checkbox has been ticked or not, 
    	// trigger code runs before assignment rules in the transaction, we therefore have to assume a negative case.  
    	
    	// Note - the trigger operates in allOrNothing mode - no partial updates are applied.  	
    	try {    	
			Map<String, Id> developerNameToRTId = AppHelper.getRecordTypesByDeveloperName('Case');						
			Id pricingCaseRTId=developerNameToRTId.get(AppConstants.CASE_RECORD_TYPE_DEVELOPER_NAME_PRICING);
    		
	    	List<Case> casesToUpdate = new List<Case>();
	    	
	    	for (Case c : modifiedRecords){
	    		if (c.RecordTypeId!=pricingCaseRTId) continue;
	    		
	    		if ((c.Status==AppConstants.CASE_STATUS_ASSIGNED_TO_PRICING && 
	    			oldMap.get(c.Id).Status!=AppConstants.CASE_STATUS_ASSIGNED_TO_PRICING)     			
	    			||    			
	    			(c.Status==AppConstants.CASE_STATUS_PRICING_COMPLETED && 
	    			oldMap.get(c.Id).Status!=AppConstants.CASE_STATUS_PRICING_COMPLETED)
	    			
	    			){  	
	    			casesToUpdate.add(c);    	
				}	    				
			}
	    	
	    	if (casesToUpdate.size()>0) {	    		
	    		casesToUpdate = [select Id from Case where Id in:casesToUpdate]; // requery the records, as the trigger context is readonly.
	    		
		    	Database.DMLOptions dmo = new Database.DMLOptions();
				dmo.assignmentRuleHeader.useDefaultRule= true;
	    		
	    		Database.update(casesToUpdate, dmo);
	    	}
		} catch (Exception e){		
			System.debug(LoggingLevel.WARN, '->->Exception thrown : ' + e.getMessage());			
			//TODO - revisit approach to runtime exception handling.			
			for (Case c : modifiedRecords){ c.addError(e.getMessage()); }
    	}
    }       
    
    /* ** 1.3/.
	private void processExternalSalesforceSupportCases(List<Case> insertedRecords){
		//Note, enumerate inserted Cases - if record type [SF Support] then lookup User (via WebEmail) and set Reporter__c (User lookup).		
		try {
			
			Map<String, Id> developerNameToRTId = AppHelper.getRecordTypesByDeveloperName('Case');						
			Id salesforceSupportCaseRTId=developerNameToRTId.get(AppConstants.CASE_RECORD_TYPE_DEVELOPER_NAME_SALESFORCE_SUPPORT);
		
			Map<String, List<Case>> suppliedEmailToCases = new Map<String, List<Case>>(); 
			
			// Step 1 - gather cases by webemail.
			for (Case c : insertedRecords){				
				if (c.RecordTypeId!=salesforceSupportCaseRTId) continue;
				if (String.isBlank(c.SuppliedEmail)) continue;
				if (c.Reporter__c!=null) continue;

				if (!suppliedEmailToCases.containsKey(c.SuppliedEmail)) suppliedEmailToCases.put(c.SuppliedEmail, new List<Case>());
				suppliedEmailToCases.get(c.SuppliedEmail).add(c);
			}
			if (suppliedEmailToCases.isEmpty()) return;

			// Step 2 - query the User object for matches on WebEmail, where found update related Cases (set reporter field lookup to user Id).
			for (User u : [select Id, Email from User where Email in:suppliedEmailToCases.keySet() and isActive=true]){				
				for (Case c : suppliedEmailToCases.get(u.Email)){
					c.Reporter__c = u.Id;
				}
			}			
		} catch (Exception e){
			System.debug(LoggingLevel.WARN, '->->Exception thrown : ' + e.getMessage());	
			for (Case c : insertedRecords){ c.addError(e.getMessage()); }
		}
		return;		
	}  
	/* */  
	//& End helper methods.
}