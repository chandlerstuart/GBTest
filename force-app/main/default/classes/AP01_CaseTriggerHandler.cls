/**
   @Author: Renz Melecotones
   @name: AP01_CaseTriggerHandler
   @CreateDate: 04.04.2016
   @Description: Handler Class for CaseTrigger
   @Version <1.0>

History
------- 
Ver. Author        Date        Detail
1.1  J.Radcliffe   2018-06-19  Implementing the 'Phased Code Removal' custom setting to support with the phased removal of redundant code (Housekeeping)
1.2  J.Radcliffe   2018-08-20  'Phased Code Removal' continued
1.3  J.Radcliffe   2018-09-19  Disable WIRE triggers on Before Triggers
1.4  M.Cane        2018-09-28  Update to restore prior state of WIRE triggers on Before Triggers.
1.5  J.Radcliffe   2018-11-05  Adding calls to the WIRE Action Identifier and Action Utility in After Trigger Context 
1.6  J.Radcliffe   2018-11-08  Adding references to static variables for WIRE recursion control
1.7  J.Radcliffe   2019-06-13  Remove redundant trigger actions (Comment out)
1.8  J.Radcliffe   2019-06-13  Redirect exception handling to PlatformLogManager
1.9  J.Radcliffe   2019-07-11  Queue WIRE actions for ActionType Cases after  insert
 */ 
public with sharing class AP01_CaseTriggerHandler {

    // Identifier that insert methods have not or already been executed
    public static boolean comesFromInsert = false;
    
    //recursion flags Added By Dee June 4 -- Based on Code Review
    public static Boolean isBeforeUpdateTriggerCalled = FALSE;
    public static Boolean isBeforeInsertTriggerCalled = FALSE;
    public static Boolean isAfterUpdateTriggerCalled = FALSE;
    public static Boolean isAfterInsertTriggerCalled = FALSE;

    public AP01_CaseTriggerHandler(){
        
    }

    public void OnBeforeInsert(List<Case> newCaseList, Map<Id,Case> newCaseMap, List<Case> oldCaseList, Map<Id,Case> oldCaseMap){
        
        //1.3 - Disable WIRE triggers on Before Triggers
        Boolean wireTriggerState = GBWire.WorkItemTriggerHandler.disableWIRETriggers;//1.4
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
        
        //1.2 - Retrieve lowest level 'Phased Code Removal' settings
        //Phased_Code_Removal__c pcr = Phased_Code_Removal__c.getInstance(); <-- 1.7  
        
        comesFromInsert = true;
        if(!isBeforeInsertTriggerCalled){
            //AP02_CaseTriggerBL.setEntitlementOnCase(newCaseList); <-- 1.7
            AP02_CaseTriggerBL.populateAccountandOppbyBookingId(newCaseList, null);
            
            /* 1.7
            if(comesFromInsert){
                if(pcr != null && !pcr.Disable_Case_Scoring__c){//1.2
                	AP07_CaseScoringLogic.setCaseScore(newCaseList, true);
                }
            }*/
            
            isBeforeInsertTriggerCalled = TRUE;
        }        
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = wireTriggerState;//1.3,1.4        
    }   
    
    public void OnBeforeUpdate(List<Case> newCaseList, Map<Id,Case> newCaseMap, List<Case> oldCaseList, Map<Id,Case> oldCaseMap){
        
        //1.3 - Disable WIRE triggers on Before Triggers
        Boolean wireTriggerState = GBWire.WorkItemTriggerHandler.disableWIRETriggers;//1.4
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
        
        if(!isBeforeUpdateTriggerCalled){
            
            //1.2 - Retrieve lowest level 'Phased Code Removal' settings
        	//Phased_Code_Removal__c pcr = Phased_Code_Removal__c.getInstance(); <--1.7
            
            AP02_CaseTriggerBL.populateAccountandOppbyBookingId(newCaseList, oldCaseMap);
            //AP02_CaseTriggerBL.setEntitlementOnCase(newCaseList); <-- 1.7
            //AP02_CaseTriggerBL.updateCaseMileStone(newCaseMap); <-- 1.7
            
            //AP02_CaseTriggerBL.populateCaseDetails(newCaseList, oldCaseMap); <-- 1.7

            /* 1.7
            if(pcr != null && !pcr.Disable_Case_Scoring__c){//1.2
                if(!comesFromInsert && !System.isBatch()){
                    AP07_CaseScoringLogic.setCaseScore(newCaseList, true);
                }
                
                if(comesFromInsert){
                    AP07_CaseScoringLogic.setCaseScore(newCaseList, true);
                }
            }*/ 
        
            isBeforeUpdateTriggerCalled = TRUE;
        }
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = wireTriggerState;//1.3,1.4
    }
    
    public void OnAfterInsert(List<Case> newCaseList, Map<Id,Case> newCaseMap, List<Case> oldCaseList, Map<Id,Case> oldCaseMap){
        
        //List<Error_Log__c> logs = new List<Error_Log__c>();<--1.8

        Boolean previousIsWIRECodeBlockedValue = WorkItemWIREActionIdentifier.isWIRECodeBlocked;//<--1.6
               
        //1.1 - Retrieve lowest level 'Phased Code Removal' settings
        //Phased_Code_Removal__c pcr = Phased_Code_Removal__c.getInstance();<--1.7
        
        if(!isAfterInsertTriggerCalled){
            WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//<--1.6
            isAfterInsertTriggerCalled = TRUE;
            //1.1 - Check the 'Disable Account NVM Id Setting' setting before executing
          	/*1.7
              if(pcr != null && !pcr.Disable_Account_NVM_Id_Setting__c){
            	AP02_CaseTriggerBL.updateCaseIdOnAccount(newCaseList);
            }*/
            
            //AP02_CaseTriggerBL.updateOpportunityServiceAgentAssigned(newCaseList);<-- 1.7
            //2017-09-25 : SM : New method call to set Case Assignment Rules after insert
            
            /* 1.7
            if(pcr != null && !pcr.Disable_Accenture_Case_Routing__c){//1.2
            	AP02_CaseTriggerBL.setAssingmentRuleOnCase(newCaseList);
            }*/
            
            WorkItemWIREActionIdentifier.isWIRECodeBlocked = previousIsWIRECodeBlockedValue;//<--1.6
        }
        
        //1.5 - Evaluate Trigger records, identify and invoke required WIRE actions
        if(!WorkItemWIREActionIdentifier.isWIRECodeBlocked){//1.6+
            try{
                WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//1.6+
                Map<Id,GBWire.WorkItemWithActionsWrapper> WIREMap = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
                WIREMap = WorkItemWIREActionIdentifier.processWorkItems(null, newCaseMap, ApplicationConstant.CASE_SOBJECTTYPE);
                if(WIREMap != null && WIREMap.keySet().size()>0){ 
                    if(newCaseMap != null && newCaseMap.values().size()>0 && newCaseMap.values()[0].ActionType__c != null){//1.9+
                        system.enqueueJob(new WorkItemWIREActionIdentifier.ExecuteWIREActionsQueueable(WIREMap,ApplicationConstant.CASE_SOBJECTTYPE));  
                    }else{
                        GBWire.WorkItemUtility.executeWIRETriggerActions(WIREMap, ApplicationConstant.CASE_SOBJECTTYPE);
                    }
                }
                WorkItemWIREActionIdentifier.isWIRECodeBlocked = previousIsWIRECodeBlockedValue; //1.6+
            }catch(exception e){
                system.debug('*** -- Exception: ' + e + ' at ' + e.getLineNumber() + ' -- ***');
                PlatformLogManager.logExceptions(e, 'AP01_CaseTriggerHandler', 'OnAfterInsert');//1.8+
            }
        }  
    }
    
    public void OnAfterUpdate(List<Case> newCaseList, Map<Id,Case> newCaseMap, List<Case> oldCaseList, Map<Id,Case> oldCaseMap){
        
        Boolean previousIsWIRECodeBlockedValue = WorkItemWIREActionIdentifier.isWIRECodeBlocked;//<--1.6
    
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        //1.1 - Retrieve lowest level 'Phased Code Removal' settings
        //Phased_Code_Removal__c pcr = Phased_Code_Removal__c.getInstance();//<--1.7  
        
        if(!isAfterUpdateTriggerCalled){
            isAfterUpdateTriggerCalled = TRUE;
            WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//<--1.6
            //AP02_CaseTriggerBL.createUpdateEvent(newCaseMap, oldCaseMap); <-- 1.7
            
            //1.1 - Check the 'Disable Account NVM Id Setting' setting before executing
            /* 1.7
            if(pcr != null && !pcr.Disable_Account_NVM_Id_Setting__c){
                if(!System.isBatch()) {
                    AP02_CaseTriggerBL.updateCaseIdOnAccount(newCaseList);
                }
            }*/
            
            //AP02_CaseTriggerBL.updateOpportunityServiceAgentAssigned(newCaseList);<-- 1.7
            WorkItemWIREActionIdentifier.isWIRECodeBlocked = previousIsWIRECodeBlockedValue;//<--1.6
        }
        
        //1.5 - Evaluate Trigger records, identify and invoke required WIRE actions
        if(!WorkItemWIREActionIdentifier.isWIRECodeBlocked){//<--1.6
            WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;
            Map<Id,GBWire.WorkItemWithActionsWrapper> WIREMap = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            WIREMap = WorkItemWIREActionIdentifier.processWorkItems(oldCaseMap, newCaseMap, ApplicationConstant.CASE_SOBJECTTYPE);
            if(WIREMap != null && WIREMap.keySet().size()>0){
                try{
                    GBWire.WorkItemUtility.executeWIRETriggerActions(WIREMap, ApplicationConstant.CASE_SOBJECTTYPE);
                }catch(exception e){
                    system.debug('*** -- Exception: ' + e + ' at ' + e.getLineNumber() + ' -- ***');
                    PlatformLogManager.logExceptions(e, 'AP05_OpportunityTriggerHandler', 'OnAfterInsert');//<-- 1.8
                    //logs.add(ApplicationConstant.getExceptionLog(e, 'executeWIRETriggerActions', 'WorkItemUtility', null));<--1.8
                }
                /*1.8
                finally{
                    if(!logs.isEmpty()){ 
                        Database.insert(logs, false); 
                    }
                }*/
            }
            WorkItemWIREActionIdentifier.isWIRECodeBlocked = previousIsWIRECodeBlockedValue;//<--1.6
        }
    }
    
    public void OnBeforeDelete(List<Case> newCaseList, Map<Id,Case> newCaseMap, List<Case> oldCaseList, Map<Id,Case> oldCaseMap){
        //1.3 - Disable WIRE triggers on Before Triggers
        Boolean wireTriggerState = GBWire.WorkItemTriggerHandler.disableWIRETriggers;//1.4
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true; 
      
      	//Add Trigger Code Here
      
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = wireTriggerState;//1.3,1.4
	}
    
    public void OnAfterDelete(List<Case> newCaseList, Map<Id,Case> newCaseMap, List<Case> oldCaseList, Map<Id,Case> oldCaseMap){

    }
     
    public void OnAfterUnDelete(List<Case> newCaseList, Map<Id,Case> newCaseMap, List<Case> oldCaseList, Map<Id,Case> oldCaseMap){
        
    }
    
    public void OnUndelete(List<Case> newCaseList, Map<Id,Case> newCaseMap, List<Case> oldCaseList, Map<Id,Case> oldCaseMap){
        //1.3 - Disable WIRE triggers on Before Triggers
        Boolean wireTriggerState = GBWire.WorkItemTriggerHandler.disableWIRETriggers;//1.4
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
      
      	//Add Trigger Code Here
      
    	GBWire.WorkItemTriggerHandler.disableWIRETriggers = wireTriggerState;//1.3,1.4
    }
}