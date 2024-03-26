/**
@Author: Majoy M, Nicole DG, Ivy A
@name: AP03_LeadTriggerHandler
@CreateDate: 06.04.2016
@Description: Handler Class for LeadTrigger
@Version <1.0>

History
------- 
Ver. Author        Date        Detail
1.1  J.Radcliffe   2018-06-19  Implementing the 'Phased Code Removal' custom setting to support with the phased removal of redundant code (Housekeeping)
1.2  J.Radcliffe   2018-09-19  Disable WIRE triggers on Before Triggers
1.3  M.Cane        2018-09-28  Update to restore prior state of WIRE triggers on Before Triggers.
1.4  J.Radcliffe   2018-11-05  Adding calls to the WIRE Action Identifier and Action Utility in After Trigger Context 
1.5  J.Radcliffe   2018-11-06  Adding references to static variables for WIRE recursion control
1.6  J.Radcliffe   2018-11-19  Moving CH Client Create (@future) callout to AFTER the WIRE triggers have executed.
1.7  J.Radcliffe   2019-05-02  Wrapping legacy integrations with additional Phased Code Removal Settings
1.8  J.Radcliffe   2019-05-03  Redirecting exception handling to Platform Log Manager
1.9  J.Radcliffe   2019-07-11  Queue WIRE actions for ActionType Cases after  insert
*/ 
public with sharing class AP03_LeadTriggerHandler {
    
    //recursion flags Added By Dee June 4 -- Based on Code Review
    public static Boolean isBeforeUpdateTriggerCalled = FALSE;
    public static Boolean isBeforeInsertTriggerCalled = FALSE;
    public static Boolean isAfterUpdateTriggerCalled = FALSE;
    public static Boolean isAfterInsertTriggerCalled = FALSE;
    public static Boolean isClientCreateCalled = FALSE;//1.6
    
    
    public AP03_LeadTriggerHandler(){
        
    }
    
    public void OnBeforeInsert(List<Lead> newLeadList){
        
        //1.2 - Disable WIRE triggers on Before Triggers
        Boolean wireTriggerState = GBWire.WorkItemTriggerHandler.disableWIRETriggers;//1.3
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
        
        if(!isBeforeInsertTriggerCalled){
            AP04_LeadTriggerBL.OnBeforeInsert(newLeadList);
            
            isBeforeInsertTriggerCalled = TRUE;
        }       
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = wireTriggerState;//1.2,1.3       
    }   
    
    public void OnBeforeUpdate(List<Lead> newLeadList, Map<Id,Lead> newLeadMap, List<Lead> oldLeadList, Map<Id,Lead> oldLeadMap){
        
        //1.2 - Disable WIRE triggers on Before Triggers
        Boolean wireTriggerState = GBWire.WorkItemTriggerHandler.disableWIRETriggers;//1.3
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
        
        if(!isBeforeUpdateTriggerCalled){
            AP04_LeadTriggerBL.OnBeforeUpdate(newLeadList, oldLeadList, oldLeadMap);
            
            isBeforeUpdateTriggerCalled = TRUE;
        }      

        GBWire.WorkItemTriggerHandler.disableWIRETriggers = wireTriggerState;//1.2,1.3      
    }
    
    public void OnAfterInsert(List<Lead> newLeadList, Map<Id,Lead> newLeadMap, List<Lead> oldLeadList, Map<Id,Lead> oldLeadMap){
        
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        //1.1 - Retrieve lowest level 'Phased Code Removal' settings
        Phased_Code_Removal__c pcr = Phased_Code_Removal__c.getInstance();
        
        Boolean previousIsWIRECodeBlockedValue = WorkItemWIREActionIdentifier.isWIRECodeBlocked;//<--1.5 
        
        if(!isAfterInsertTriggerCalled){
            WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;
            AP04_LeadTriggerBL.OnAfterInsert(newLeadList,oldLeadMap);
            //1.1 - Check the 'Disable Account NVM Id Setting' setting before executing
            if(pcr != null && !pcr.Disable_Account_NVM_Id_Setting__c){
                AP04_LeadTriggerBL.setLeadIdRating(newLeadMap);
            }
            isAfterInsertTriggerCalled = TRUE;
            WorkItemWIREActionIdentifier.isWIRECodeBlocked = previousIsWIRECodeBlockedValue; 
        }
                
        //1.4 - Evaluate Trigger records, identify and invoke required WIRE actions
        if(!WorkItemWIREActionIdentifier.isWIRECodeBlocked){//1.5+
            try{
                WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//1.5+ Do not re run WIRE actions whilst running WIRE actions
                Map<Id,GBWire.WorkItemWithActionsWrapper> WIREMap = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
                WIREMap = WorkItemWIREActionIdentifier.processWorkItems(null, newLeadMap, ApplicationConstant.LEAD_SOBJECTTYPE);
                if(WIREMap != null && WIREMap.keySet().size()>0){ 
                    if(newLeadMap != null && newLeadMap.values().size()>0 && newLeadMap.values()[0].ActionType__c != null){//1.9+
                        system.enqueueJob(new WorkItemWIREActionIdentifier.ExecuteWIREActionsQueueable(WIREMap,ApplicationConstant.LEAD_SOBJECTTYPE));  
                    }else{
                        GBWire.WorkItemUtility.executeWIRETriggerActions(WIREMap, ApplicationConstant.LEAD_SOBJECTTYPE);
                    }
                }
                WorkItemWIREActionIdentifier.isWIRECodeBlocked = previousIsWIRECodeBlockedValue; //1.5+
            }catch(exception e){
                system.debug('*** -- Exception: ' + e + ' at ' + e.getLineNumber() + ' -- ***');
                PlatformLogManager.logExceptions(e, 'AP03_LeadTriggerHandler', 'OnAfterInsert');//1.8+
            }
        }  

        //1.6 Create Client in CH
        if (null != newLeadList && !isClientCreateCalled){ 
            //ONLY Process on Lead Size = 1
            if (1 == newLeadList.size()){
                //1.7 Check the 'Disable_Legacy_Client_Enq_Integrations__c' setting before executing
                if(pcr != null && !pcr.Disable_Legacy_Client_Enq_Integrations__c){
                    AP04_LeadTriggerBL.createClubhouseClient(newLeadList[0]);
                }
                AP04_LeadTriggerBL.comesFromInsert = true;
                //Only callout once
                isClientCreateCalled = true;
            }
        }
        
    }
    
    public void OnAfterUpdate(List<Lead> newLeadList, Map<Id,Lead> newLeadMap, List<Lead> oldLeadList, Map<Id,Lead> oldLeadMap){
        
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Boolean previousIsWIRECodeBlockedValue = WorkItemWIREActionIdentifier.isWIRECodeBlocked;//<--1.5 
        
        if(!isAfterUpdateTriggerCalled){
            WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//<--1.5
            AP04_LeadTriggerBL.OnAfterUpdate(newLeadList, oldLeadMap, newLeadMap);//Temp calling
            
            isAfterUpdateTriggerCalled = TRUE;
            WorkItemWIREActionIdentifier.isWIRECodeBlocked = previousIsWIRECodeBlockedValue;//<--1.5
        }
        
        //1.4 - Evaluate Trigger records, identify and invoke required WIRE actions
        if(!WorkItemWIREActionIdentifier.isWIRECodeBlocked){//<--1.5
            WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//<--1.5
            Map<Id,GBWire.WorkItemWithActionsWrapper> WIREMap = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            WIREMap = WorkItemWIREActionIdentifier.processWorkItems(oldLeadMap, newLeadMap, ApplicationConstant.LEAD_SOBJECTTYPE);
            if(WIREMap != null && WIREMap.keySet().size()>0){
                try{
                    GBWire.WorkItemUtility.executeWIRETriggerActions(WIREMap, ApplicationConstant.LEAD_SOBJECTTYPE);
                }catch(exception e){
                    system.debug('*** -- Exception: ' + e + ' at ' + e.getLineNumber() + ' -- ***');
                    //1.8
                    PlatformLogManager.logExceptions(e, 'AP03_LeadTriggerHandler', 'OnAfterUpdate');
                    //logs.add(ApplicationConstant.getExceptionLog(e, 'executeWIRETriggerActions', 'WorkItemUtility', null));
                }
                /*finally{ <-- 1.8
                    if(!logs.isEmpty()){ 
                        Database.insert(logs, false); 
                    }
                }*/
                
            }
            WorkItemWIREActionIdentifier.isWIRECodeBlocked = previousIsWIRECodeBlockedValue;//<--1.5
        }
        
    }
    
    public void OnBeforeDelete(List<Lead> newLeadList, Map<Id,Lead> newLeadMap, List<Lead> oldLeadList, Map<Id,Lead> oldLeadMap){
        
        //1.2 - Disable WIRE triggers on Before Triggers
        Boolean wireTriggerState = GBWire.WorkItemTriggerHandler.disableWIRETriggers;//1.3
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
        
        //Add Trigger Code Here
        
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = wireTriggerState;//1.2,1.3
    }
    
    public void OnAfterDelete(List<Lead> newLeadList, Map<Id,Lead> newLeadMap, List<Lead> oldLeadList, Map<Id,Lead> oldLeadMap){
        
    }
    
    public void OnAfterUnDelete(List<Lead> newLeadList, Map<Id,Lead> newLeadMap, List<Lead> oldLeadList, Map<Id,Lead> oldLeadMap){
        
    }
    
    public void OnUndelete(List<Lead> newLeadList, Map<Id,Lead> newLeadMap, List<Lead> oldLeadList, Map<Id,Lead> oldLeadMap){
        
        //1.2 - Disable WIRE triggers on Before Triggers
        Boolean wireTriggerState = GBWire.WorkItemTriggerHandler.disableWIRETriggers;//1.3
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
        
        //Add Trigger Code Here
        
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = wireTriggerState;//1.2,1.3
    }
}