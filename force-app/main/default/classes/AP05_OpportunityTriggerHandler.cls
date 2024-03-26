/**
   @Author: Renz Melecotones
   @name: AP05_OpportunityTriggerHandler
   @CreateDate: 10.03.2016
   @Description: Handler Class for OpportunityTrigger
   @Version <1.0>

History
------- 
Ver. Author        Date        Detail
1.1  J.Radcliffe   2018-06-19  Implementing the 'Phased Code Removal' custom setting to support with the phased removal of redundant code (Housekeeping)
1.2  J.Radcliffe   2018-09-19  Disable WIRE triggers on Before Triggers
1.3  M.Cane        2018-09-28  Update to restore prior state of WIRE triggers on Before Triggers.
1.4  J.Radcliffe   2018-11-05  Adding calls to the WIRE Action Identifier and Action Utility in After Trigger Context 
1.5  J.Radcliffe   2018-11-06  Setting Default Business Unit/Booking system on Opportunity if none is specified (insert & update)
1.6  J.Radcliffe   2018-11-08  Adding references to static variables for WIRE recursion control
1.7	 J.Radcliffe   2019-02-26  Adding new RTs for Business Unit Calculation
1.8  J.Radcliffe   2019-05-02  Wrapping legacy integrations with additional Phased Code Removal Settings
1.9  J.Radcliffe   2019-05-03  Redirecting exception handling to Platform Log Manager
1.10 J.Radcliffe   2019-07-04  New Method invocation; updateCustomerCallBackTime
1.11 J.Radcliffe   2019-07-04  Comment Out Redundant Methods
1.12 J.Radcliffe   2019-07-11  Queue WIRE actions for ActionType Opps after  insert
1.13 J.Radcliffe   2019-10-17  Invoke Data Event Handler
1.14 J.Radcliffe   2019-11-14  Recursion guards extended to support partial processing dml operations (insert and update only).
1.15 J.Radcliffe   2019-11-26  Bug Fix - Disable Data Event Triggers during WIRE Activity (following Opp Insert) to prevent duplicate CH callouts (enquiry-copy on insert and initial assignment) 
1.16 J.Radcliffe   2021-11-02  Call the calculateQuoteShareId method after insert and before update
1.17 J.Radcliffe   2022-02-15  Integration Framework Plugin - After Insert
1.18 J.Radcliffe   2023-04-23  Invoke the formatOpportunityQuoteParagraphs method to format the Sign Off Paragraph before insert and update.
1.19 Mark Cane&    2023-08-21  Disable update triggers for opportunity update during after insert trigger.
1.20 J Radcliffe   2024-02-13  Invoke assignPublicId method (GUID Generator) - Create a PublicId__c before insert.
1.21 Mark Cane&    2024-02-16  Bug fixes. Switch Wire action processing to future if parent transaction (i.e. ActionTypeRequest) is Queueable. 
1.22 J Radcliffe   2024-02-16  Bug fixes. Related to 1.21 - Changed limit check to greater or equals
*/ 
public with sharing class AP05_OpportunityTriggerHandler {

    public static boolean firstRunOnAfterUpdate = true;
    
    //recursion flags Added By Dee June 4 -- Based on Code Review
    public static Boolean isBeforeUpdateTriggerCalled = FALSE;
    public static Boolean isBeforeInsertTriggerCalled = FALSE;
    public static Boolean isAfterUpdateTriggerCalled = FALSE;
    public static Boolean isAfterDeleteTriggerCalled = FALSE;
    public static Boolean isAfterInsertTriggerCalled = FALSE;

    @testVisible private static Integer triggerSize=0;//1.14+

    @testVisible private static Boolean isQueueableLimitReached {//1.21+
        get {
            if (isQueueableLimitReached==null || !isQueueableLimitReached){
                isQueueableLimitReached = (Limits.getLimitQueueableJobs()>=Limits.getQueueableJobs());
            }
            return isQueueableLimitReached;
        }
        private set;
    }

    public AP05_OpportunityTriggerHandler(){
        
    }

    public void OnBeforeInsert(List<Opportunity> newOppList){
    	
        //1.2 - Disable WIRE triggers on Before Triggers
        Boolean wireTriggerState = GBWire.WorkItemTriggerHandler.disableWIRETriggers;//1.3
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
        
        //1.1 - Retrieve lowest level 'Phased Code Removal' settings
        Phased_Code_Removal__c pcr = Phased_Code_Removal__c.getInstance();
         
        if(!isBeforeInsertTriggerCalled){

            triggerSize = Trigger.new.size();//1.14+ -- set in the first Before phase only, errored records are removed before the After phase.

            GUIDGenerator.assignPublicId(newOppList);//1.20+

            //2016-12-08 : SM : New method to update RequestedCallBackDateTime on an Opp based on Diary Date
            //2016-12-08 : SM : Plus Call Back Hour + Call Back Minute
            AP06_OpportunityTriggerBL.updateCallbackDateTime(newOppList,null); 
            AP06_OpportunityTriggerBL.updateCustomerCallBackDateTime(newOppList, null);//1.10+
            AP06_OpportunityTriggerBL.formatOpportunityQuoteParagraphs(null,newOppList);//1.18+ 

            //1.1 - Check the 'Disable Monthly Sales Target Automation' setting before executing
            /*1.11
            if(pcr != null && !pcr.Disable_Monthly_Sales_Target_Automation__c){
            	AP06_OpportunityTriggerBL.mapMonthlySalesTargetLookup(newOppList, null);
            }*/
            
            //1.5 - Collate sorted lists for BL processing
            List<Opportunity> defaultBUOpps = new List<Opportunity>();
            Id newSalesOppRTID = ApplicationConstant.OPP_RECTYPEID_NSO;
            //1.7
            Id contactedRTId = ApplicationConstant.OPP_RECTYPEID_CONTACTED;
            Id uncontactedRTId = ApplicationConstant.OPP_RECTYPEID_UNCONTACTED;
            //Loop through trigger records
            for(Opportunity opp : newOppList){
                if((opp.RecordTypeId == newSalesOppRTID ||/*1.7*/ opp.RecordTypeId == contactedRTId || opp.RecordTypeId == uncontactedRTId /*1.7*/) && (opp.Golfbreaks_Business_Unit__c == null || opp.Booking_System__c == null)){
                    defaultBUOpps.add(opp);
                }
            }
            if(defaultBUOpps.size()>0){           
                //1.5 - Default Business Unit/Booking System
                AP06_OpportunityTriggerBL.setDefaultBusinessUnitAndBookingSystem(defaultBUOpps);
            }
            
            isBeforeInsertTriggerCalled = TRUE;
        }
		GBWire.WorkItemTriggerHandler.disableWIRETriggers = wireTriggerState;//1.2,1.3    
    }   
    
    public void OnBeforeUpdate(List<Opportunity> newOppList, Map<Id,Opportunity> newOppMap, List<Opportunity> oldOppList, Map<Id,Opportunity> oldOppMap){
        
        //1.2 - Disable WIRE triggers on Before Triggers
        Boolean wireTriggerState = GBWire.WorkItemTriggerHandler.disableWIRETriggers;//1.3
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
        
        //1.1 - Retrieve lowest level 'Phased Code Removal' settings 
        Phased_Code_Removal__c pcr = Phased_Code_Removal__c.getInstance();

        if(!isBeforeUpdateTriggerCalled) triggerSize = Trigger.new.size();//1.14+ -- set in the first Before phase only, errored records are removed before the After phase.
                
        if(!isBeforeUpdateTriggerCalled || (isBeforeUpdateTriggerCalled && (Trigger.new.size()!=triggerSize))){//1.14+
                        
            //2016-12-08 : SM : New method to update RequestedCallBackDateTime on an Opp based on Diary Date
            //2016-12-08 : SM : Plus Call Back Hour + Call Back Minute
            AP06_OpportunityTriggerBL.updateCallbackDateTime(newOppList,oldOppMap);
            AP06_OpportunityTriggerBL.updateCustomerCallBackDateTime(newOppList, oldOppMap);//1.10+
            AP06_OpportunityTriggerBL.calculateQuoteShareId(newOppList);//1.16+
            AP06_OpportunityTriggerBL.formatOpportunityQuoteParagraphs(oldOppMap,newOppList);//1.18+
            
            //1.1 - Check the 'Disable Monthly Sales Target Automation' setting before executing
            /*1.11
            if(pcr != null && !pcr.Disable_Monthly_Sales_Target_Automation__c){
            	AP06_OpportunityTriggerBL.mapMonthlySalesTargetLookup(newOppList, oldOppMap);
            }*/
            //1.8 - Check the 'Disable_Miscellaneous_Redundant_Triggers__c' before executing
            /*1.11
            if(pcr != null && !pcr.Disable_Miscellaneous_Redundant_Triggers__c){
                AP06_OpportunityTriggerBL.populateOppDetails(newOppList, oldOppMap);
            }*/
            //1.5 - Collate sorted lists for BL processing
            List<Opportunity> defaultBUOpps = new List<Opportunity>();
            Id newSalesOppRTID = ApplicationConstant.OPP_RECTYPEID_NSO;
            //1.7
            Id contactedRTId = ApplicationConstant.OPP_RECTYPEID_CONTACTED;
            Id uncontactedRTId = ApplicationConstant.OPP_RECTYPEID_UNCONTACTED;
            //Loop through trigger records
            for(Opportunity opp : newOppList){
                if((opp.RecordTypeId == newSalesOppRTID ||/*1.7*/ opp.RecordTypeId == contactedRTId || opp.RecordTypeId == uncontactedRTId /*1.7*/) && (opp.Golfbreaks_Business_Unit__c == null || opp.Booking_System__c == null)){
                    defaultBUOpps.add(opp);
                }
            }
            if(defaultBUOpps.size()>0){           
                //1.5 - Default Business Unit/Booking System
                AP06_OpportunityTriggerBL.setDefaultBusinessUnitAndBookingSystem(defaultBUOpps);
            }
            
            
            
            isBeforeUpdateTriggerCalled = TRUE;
        }
		GBWire.WorkItemTriggerHandler.disableWIRETriggers = wireTriggerState;//1.2,1.3        
    }
    
    public void OnAfterInsert(List<Opportunity> newOppList, Map<Id,Opportunity> newOppMap, List<Opportunity> oldOppList, Map<Id,Opportunity> oldOppMap){
        
        //1.1 - Retrieve lowest level 'Phased Code Removal' settings
        Phased_Code_Removal__c pcr = Phased_Code_Removal__c.getInstance();
        
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Boolean previousIsWIRECodeBlockedValue = WorkItemWIREActionIdentifier.isWIRECodeBlocked;//<--1.6
        
        if(!isAfterInsertTriggerCalled || (isAfterInsertTriggerCalled && (Trigger.new.size()!=triggerSize))){//1.14+
            WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//<--1.6

            Boolean previousIsBeforeUpdateTriggerCalled = isBeforeUpdateTriggerCalled;//1.19+
            Boolean previousIsAfterUpdateTriggerCalled = isAfterUpdateTriggerCalled;//1.19+

            isBeforeUpdateTriggerCalled = TRUE;//1.19+
            isAfterUpdateTriggerCalled = TRUE;//1.19+

            AP06_OpportunityTriggerBL.calculateQuoteShareId(newOppList);//1.16+

            isBeforeUpdateTriggerCalled = previousIsBeforeUpdateTriggerCalled;//1.19+
            isBeforeUpdateTriggerCalled = previousIsAfterUpdateTriggerCalled;//1.19+

                        
            //1.1 - Check the 'Disable Account NVM Id Setting' setting before executing
            /*1.11
          	if(pcr != null && !pcr.Disable_Account_NVM_Id_Setting__c){
            	AP06_OpportunityTriggerBL.updateOppIdOnAccount(newOppList); 
            }*/    
            
            //1.1 - Check the 'Disable Monthly Sales Target Automation' setting before executing
            /*1.11
            if(pcr != null && !pcr.Disable_Monthly_Sales_Target_Automation__c){
            	AP06_OpportunityTriggerBL.updateMonthlySalesTargetRollup(newOppList, null);
            }*/
            
            //AP06_OpportunityTriggerBL.updateTotalPreviousOpportunitiesOnLead(newOppList);   
            
            //1.1 - Check the 'Disable SAA Capacity Calculation' setting before executing
            /*1.11
            if(pcr != null && !pcr.Disable_SAA_Capacity_Calculation__c){    
            	AP54_SalesAgentAttributeUtility.updateCorrespodingSAAofRecOwners(new List<Lead>(), newOppList);
            }*/

            DataEventTypeTriggerHandler dth = new DataEventTypeTriggerHandler(ApplicationConstant.OBJECT_TYPE_OPPORTUNITY);//1.17+
            dth.handleTriggerOperationType();//1.13+
            
            WorkItemWIREActionIdentifier.isWIRECodeBlocked = previousIsWIRECodeBlockedValue; //<--1.6
            if(isAfterInsertTriggerCalled) triggerSize = Trigger.new.size();//1.14+
            isAfterInsertTriggerCalled = TRUE;
        }
        
        //1.4 - Evaluate Trigger records, identify and invoke required WIRE actions
        if(!WorkItemWIREActionIdentifier.isWIRECodeBlocked){//1.6+
            try{
                WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//1.6+
                Map<Id,GBWire.WorkItemWithActionsWrapper> WIREMap = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
                WIREMap = WorkItemWIREActionIdentifier.processWorkItems(null, newOppMap, ApplicationConstant.OBJECT_TYPE_OPPORTUNITY);
                if(WIREMap != null && WIREMap.keySet().size()>0){ 
                    if(newOppMap != null && newOppMap.values().size()>0 && newOppMap.values()[0].ActionType__c != null){//1.12+
                        
                        if (!isQueueableLimitReached){//1.21+
                            system.enqueueJob(new WorkItemWIREActionIdentifier.ExecuteWIREActionsQueueable(WIREMap,ApplicationConstant.OBJECT_TYPE_OPPORTUNITY,true));//1.15~
                        } else if (Limits.getLimitFutureCalls()>Limits.getFutureCalls()){//1.21+
                            
                            Map<String,Object> mapToValue;
                            Map<Id,Map<String,Object>> WIREMapSerializable = new Map<Id,Map<String,Object>>();//1.21+ -- managed package classes serializable in the namespace only.

                            for(Id oppId : WIREMap.keySet()){

                                mapToValue = new Map<String,Object>();

                                mapToValue.put('doAssign',WIREMap.get(oppId).doAssign);
                                mapToValue.put('doPreferredQueueCalc',WIREMap.get(oppId).doPreferredQueueCalc);
                                mapToValue.put('doCRPCalc',WIREMap.get(oppId).doCRPCalc);
                                mapToValue.put('doAgentCapacityCalc',WIREMap.get(oppId).doAgentCapacityCalc);
                                mapToValue.put('doPreferredAgentCalc',WIREMap.get(oppId).doPreferredAgentCalc);
                                mapToValue.put('previousOwnerId',WIREMap.get(oppId).previousOwnerId);
                                mapToValue.put('previousClientId',WIREMap.get(oppId).previousClientId);

                                WIREMapSerializable.put(oppId,mapToValue);
                            }
                            if (!WIREMapSerializable.isEmpty()) WorkItemWIREActionIdentifier.executeWIRETriggerActionsFuture(JSON.serialize(WIREMapSerializable,false),ApplicationConstant.OBJECT_TYPE_OPPORTUNITY,true);//1.21+
                            
                        } else GBWire.WorkItemUtility.executeWIRETriggerActions(WIREMap, ApplicationConstant.OBJECT_TYPE_OPPORTUNITY);//1.21+ -- attempt to process in-transaction.

                    }else{
                        GBWire.WorkItemUtility.executeWIRETriggerActions(WIREMap, ApplicationConstant.OBJECT_TYPE_OPPORTUNITY);
                    }
                }
                WorkItemWIREActionIdentifier.isWIRECodeBlocked = previousIsWIRECodeBlockedValue; //<--1.6
            }catch(exception e){
                            system.debug('*** -- Exception: ' + e + ' at ' + e.getLineNumber() + ' -- ***');
                            PlatformLogManager.logExceptions(e, 'AP05_OpportunityTriggerHandler', 'OnAfterInsert');//1.9+
            }
        }  
    }
    
    public void OnAfterUpdate(List<Opportunity> newOppList, Map<Id,Opportunity> newOppMap, List<Opportunity> oldOppList, Map<Id,Opportunity> oldOppMap){
        
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Boolean previousIsWIRECodeBlockedValue = WorkItemWIREActionIdentifier.isWIRECodeBlocked;//<--1.6
        
        //1.1 - Retrieve lowest level 'Phased Code Removal' settings
        Phased_Code_Removal__c pcr = Phased_Code_Removal__c.getInstance();
        
        if(!isAfterUpdateTriggerCalled || (isAfterUpdateTriggerCalled && (Trigger.new.size()!=triggerSize))){//1.14+
            WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//<--1.6 
            
            //If the OpportunityOwnerId__c is change, sync changes to Opportunity Work Item
            //AP06_OpportunityTriggerBL.syncOpportunityOwnerChangesToWorkItem(oldOppMap,newOppMap);  
            
            //AP06_OpportunityTriggerBL.createUpdateEvent(newOppMap, oldOppMap); 1.11-
            //1.1 - Check the 'Disable Account NVM Id Setting' setting before executing
            /*1.11
          	if(pcr != null && !pcr.Disable_Account_NVM_Id_Setting__c){
            	AP06_OpportunityTriggerBL.updateOppIdOnAccount(newOppList);
            }*/
            //1.8 - Check the 'Disable_Legacy_Acct_Manager_Integrations__c' before executing
            /*if(pcr != null && !pcr.Disable_Legacy_Acct_Manager_Integrations__c){
                AP06_OpportunityTriggerBL.checkOppOwnerUpdate(newOppList, oldOppMap);
            }*/
            
            //1.1 - Check the 'Disable SAA Capacity Calculation' setting before executing
            /*1.11
            if(pcr != null && !pcr.Disable_SAA_Capacity_Calculation__c){  
                AP06_OpportunityTriggerBL.checkStatusUpdates(newOppList, oldOppMap);
            	AP54_SalesAgentAttributeUtility.updateCorrespodingSAAofRecOwners(new List<Lead>(), newOppList);
            }*/
            
            //1.1 - Check the 'Disable Monthly Sales Target Automation' setting before executing
            /*1.11
            if(pcr != null && !pcr.Disable_Monthly_Sales_Target_Automation__c){
            	AP06_OpportunityTriggerBL.updateMonthlySalesTargetRollup(newOppList, oldOppMap);
            }*/

            DataEventTypeTriggerHandler dth = new DataEventTypeTriggerHandler(ApplicationConstant.OBJECT_TYPE_OPPORTUNITY);//1.13+
            dth.handleTriggerOperationType();//1.13+

            if(isAfterUpdateTriggerCalled) triggerSize = Trigger.new.size();//1.14+

            isAfterUpdateTriggerCalled = TRUE;
            WorkItemWIREActionIdentifier.isWIRECodeBlocked = previousIsWIRECodeBlockedValue; //<--1.6
        }
        
        //1.4 - Evaluate Trigger records, identify and invoke required WIRE actions
        if(!WorkItemWIREActionIdentifier.isWIRECodeBlocked){//<--1.6
            WorkItemWIREActionIdentifier.isWIRECodeBlocked = true; //<--1.6
            Map<Id,GBWire.WorkItemWithActionsWrapper> WIREMap = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            WIREMap = WorkItemWIREActionIdentifier.processWorkItems(oldOppMap, newOppMap, ApplicationConstant.OBJECT_TYPE_OPPORTUNITY);
            if(WIREMap != null && WIREMap.keySet().size()>0){
                try{
                    GBWire.WorkItemUtility.executeWIRETriggerActions(WIREMap, ApplicationConstant.OBJECT_TYPE_OPPORTUNITY);
                }catch(exception e){
                    system.debug('*** -- Exception: ' + e + ' at ' + e.getLineNumber() + ' -- ***');
                    PlatformLogManager.logExceptions(e, 'AP05_OpportunityTriggerHandler', 'OnAfterUpdate');//1.9+
                }
            }
            WorkItemWIREActionIdentifier.isWIRECodeBlocked = previousIsWIRECodeBlockedValue; //<--1.6
        }
    }
    
    public void OnBeforeDelete(List<Opportunity> newOppList, Map<Id,Opportunity> newOppMap, List<Opportunity> oldOppList, Map<Id,Opportunity> oldOppMap){

		//1.2 - Disable WIRE triggers on Before Triggers
    	Boolean wireTriggerState = GBWire.WorkItemTriggerHandler.disableWIRETriggers;//1.3
    	GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
      
      	//Add Trigger Code Here
      
		GBWire.WorkItemTriggerHandler.disableWIRETriggers = wireTriggerState;//1.2,1.3
    }
    
    public void OnAfterDelete(List<Opportunity> newOppList, Map<Id,Opportunity> newOppMap, List<Opportunity> oldOppList, Map<Id,Opportunity> oldOppMap){
        
        //1.1 - Retrieve lowest level 'Phased Code Removal' settings
        Phased_Code_Removal__c pcr = Phased_Code_Removal__c.getInstance();
        
        if(!isAfterDeleteTriggerCalled){
            //if (null != newOppList && !newOppList.isEmpty()){
            //    AP06_OpportunityTriggerBL.updateTotalPreviousOpportunitiesOnLead(newOppList);
            //}
            
            //1.1 - Check the 'Disable Monthly Sales Target Automation' setting before executing
            /*1.11
            if(pcr != null && !pcr.Disable_Monthly_Sales_Target_Automation__c){
            	AP06_OpportunityTriggerBL.updateMonthlySalesTargetRollup(oldOppList, null);
            }*/
            
            isAfterDeleteTriggerCalled = TRUE;
        
        }
    }
     
    public void OnAfterUnDelete(List<Opportunity> newOppList, Map<Id,Opportunity> newOppMap, List<Opportunity> oldOppList, Map<Id,Opportunity> oldOppMap){
        
    }
    
    public void OnUndelete(List<Opportunity> newOppList, Map<Id,Opportunity> newOppMap, List<Opportunity> oldOppList, Map<Id,Opportunity> oldOppMap){
        //1.2 - Disable WIRE triggers on Before Triggers
        Boolean wireTriggerState = GBWire.WorkItemTriggerHandler.disableWIRETriggers;//1.3
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
      
	      //Add Trigger Code Here
      
		GBWire.WorkItemTriggerHandler.disableWIRETriggers = wireTriggerState;//1.2,1.3    	
    }
}