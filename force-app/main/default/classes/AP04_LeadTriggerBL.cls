/*
Name:  AP04_LeadTriggerBL.cls
======================================================
======================================================
Purpose:
-------
Business Logic Class for AP03_LeadTriggerHandler
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.0  Accenture     2016-04-06   Initial development
2.0  Simon Molloy  2016-12-12   Added in new createClubhouseEnquiry method to call Clubhouse API on AfterInsert
2.1  Simon Molloy  2017-02-16   Added code to set Gender on Lead
2.2  Simon Molloy  2017-03-06   Updated method updateTotalPreviousBookingsOnUpdate (line 869) to check for NULL
2.3  Simon Molloy  2017-07-06   New functionality for Shadow Opportunity & creating Enquiry in Clubhouse
2.4  Simon Molloy  2017-07-27   New method to update Shadow Opportunity record if Lead Status is set to No Sale or Duplicate
2.5  Simon Molloy  2017-08-09   New method to update AccountManager (owner) in Clubhouse if the Owner of a Lead has changed
2.6  Simon Molloy  2017-12-07   New method to update Opp Amount post-conversion by totalling Quotes (as per AP18_QuoteTriggerBL.cls)
2.7  Simon Molloy  2018-01-02   Update to PostConvertProcessor to take Lead ID as Source_Lead__c on Converted Opp rather than Shadow Opp.Source_Lead__c
2.8  Simon Molloy  2018-01-09   Changed logic for updating Opportunity Amount & Lead_Source__c fields
2.9  Simon Molloy  2018-01-23   Added in new fields to the 'createShadowOpp' method that are not covered by standard Lead mapping
3.0  Mark Cane     2018-04-15   Added method updateCustomerCallBackDateTime and calls from BI and BU triggers.
3.1  Mark Cane     2018-04-25   Added method updateDefaultInternationalisationValues and calls from BI trigger.
3.2  Mark Cane     2018-06-08   Modified doPostConvert to move Opportunity deletion to the WithoutSharingUtility class.
3.3  Mark Cane     2018-06-13   Modified doPostConvert to move Opportunity queries to the WithoutSharingUtility class.
3.4  James Radcliffe  2018-06-18  Implementing the 'Phased Code Removal' custom setting to support with the phased removal of redundant code (Housekeeping)
3.5  James Radcliffe  2018-08-22  Disabling WIRE Triggers when inserting Shadow Opportunities
3.6  James Radcliffe  2018-08-24  Invoking WorkItemUtility post lead conversion
3.7  James Radcliffe  2018-11-19  Moving CH Client Create (@future) callout to AFTER the WIRE triggers have executed (see Trigger Handler for related changes).
3.8  James Radcliffe  2019-03-29  'populateAccountDetailsOnLead' Bug Fix - Logic change for setting Best Time to Call
3.9  James Radcliffe  2019-04-08  Replacing 'runWIRETriggerLogicOnWorkItems' invokation with 'executeWIRETriggerActions' - W-000071
3.10 James Radcliffe  2019-04-26  Removing explicit call for WIRE actions as they are expensive to process and no longer required
3.11 James Radcliffe  2019-05-02  Wrapping legacy integrations with additional Phased Code Removal Settings
3.12 James Radcliffe  2019-05-03  Redirecting exception handling to Platform Log Manager
*/
public with sharing class AP04_LeadTriggerBL
{   
    // Used for logging --- Added by Dee 5/15
    public static final String CLASS_NAME = 'AP04_LeadTriggerBL';
    public static final String GENDER_MALE = 'Male';
    public static final String GENDER_FEMALE = 'Female';
    
    public static boolean firstRun = true;
    public static boolean comesFromInsert = false;
    
    //recursion flags Added By Dee June 4 -- Based on Code Review
    public static Boolean isBeforeUpdateTriggerCalled = FALSE;
    public static Boolean isBeforeInsertTriggerCalled = FALSE;
    public static Boolean isAfterUpdateTriggerCalled = FALSE;
    public static Boolean isAfterInsertTriggerCalled = FALSE;

    
    public static void OnBeforeInsert(List<Lead> newLeadList){
        comesFromInsert = true;
        
        //3.4 - Retrieve lowest level 'Phased Code Removal' settings
        Phased_Code_Removal__c pcr = Phased_Code_Removal__c.getInstance();
        
        if(!isBeforeInsertTriggerCalled){

            //Update Callback Date Time
            updateCallBackDateTime(newLeadList, null);
            updateCustomerCallBackTime(newLeadList,null);//3.0
            updateDefaultInternationalisationValues(newLeadList);//3.1
            catchDupeLeads(newLeadList);
            
            //3.4 - Check the 'Disable Lead Scoring' setting before executing
            if(pcr != null && !pcr.Disable_Lead_Scoring__c){
                setLeadScore(newLeadList);
            }
            
            //3.4 - Check the 'Disable Gender Calculation' setting before executing
            if(pcr != null && !pcr.Disable_Gender_Calculation__c){
                //2017-07-25 : SM : Populate Gender on Lead
                populateGenderLead(newLeadList);
            }
            //3.11 - Check the 'Disable_Legacy_Client_Enq_Integrations__c' before executing
            if(pcr != null && !pcr.Disable_Legacy_Client_Enq_Integrations__c){
                populateAccountDetailsOnLead(newLeadList, null);
            }
            
            //3.4 - Check the 'Disable Total Previous Bookings Calc' setting before executing
            if(pcr != null && !pcr.Disable_Total_Previous_Bookings_Calc__c){
                updateTotalPreviousBookingsOnInsert(newLeadList);
            }
            //3.11 - Check the 'Disable_Miscellaneous_Redundant_Triggers__c' before executing
            if(pcr != null && !pcr.Disable_Miscellaneous_Redundant_Triggers__c){
                changeLeadSource(newLeadList); 
            }
            isBeforeInsertTriggerCalled = TRUE;
        }
        
    }

    public static void OnBeforeUpdate(List<Lead> newLeadList, List<Lead> oldLeadList, Map<Id,Lead> oldLeadMap){
        
        //3.4 - Retrieve lowest level 'Phased Code Removal' settings
        Phased_Code_Removal__c pcr = Phased_Code_Removal__c.getInstance();
        
        if(!comesFromInsert){
            if(!isBeforeUpdateTriggerCalled){
                //Update Callback Date Time
                updateCallBackDateTime(newLeadList, oldLeadMap);
                updateCustomerCallBackTime(newLeadList,oldLeadMap);//3.0
                
                //3.4 - Check the 'Disable Lead Scoring' setting before executing
                if(pcr != null && !pcr.Disable_Lead_Scoring__c){
                    setLeadScore(newLeadList);
                }
                //3.11 - Check the 'Disable_Miscellaneous_Redundant_Triggers__c' before executing
                if(pcr != null && !pcr.Disable_Miscellaneous_Redundant_Triggers__c){
                    populateLeadDetails(newLeadList, oldLeadMap);
                }
                //3.11 - Check the 'Disable_Legacy_Client_Enq_Integrations__c' before executing
                if(pcr != null && !pcr.Disable_Legacy_Client_Enq_Integrations__c){
                    populateAccountDetailsOnLead(newLeadList, oldLeadMap);
                }
                if(!System.isBatch()){
                    //3.4 - Check the 'Disable_Accenture_Lead_Routing__c' before executing
                    if(pcr != null && !pcr.Disable_Accenture_Lead_Routing__c){
                        isChangeLead(newLeadList, oldLeadMap);
                    }
                }
                //3.4 - Check the 'Disable Total Previous Bookings Calc' before executing
                if(pcr != null && !pcr.Disable_Total_Previous_Bookings_Calc__c){
                    updateTotalPreviousBookingsOnUpdate(newLeadList, oldLeadList);
                }
                
                isBeforeUpdateTriggerCalled = TRUE;
            }
        }
        else{
            //3.4 - Check the 'Disable (Accenture) Lead Routing' setting before executing
            if(pcr != null && !pcr.Disable_Accenture_Lead_Routing__c){
                filterReturnTravellerLeadsForRouting(newLeadList);
            }    
        } 
    }

    public static void OnAfterInsert(List<Lead> newLeadList, Map<Id,Lead> oldLeadMap){
        
        //3.4 - Retrieve lowest level 'Phased Code Removal' settings
        Phased_Code_Removal__c pcr = Phased_Code_Removal__c.getInstance();
        
        if(!isAfterInsertTriggerCalled){
            
            //3.4 - Check the 'Disable SAA Capacity Calculation' setting before executing
            if(pcr != null && !pcr.Disable_SAA_Capacity_Calculation__c){
                AP54_SalesAgentAttributeUtility.updateCorrespodingSAAofRecOwners(newLeadList, new List<Opportunity>());
            }
            
            system.debug('*** -- newLeadList = ' + newLeadList.size() + ' -- ***');
            /*if (null != newLeadList){ <<<<---- 3.7 (Commented Out) 
                //ONLY Process on Lead Size = 1
                if (1 == newLeadList.size()){
                    createClubhouseClient(newLeadList[0]);
                    comesFromInsert = true;
                }
            }*/
            
            //MC WIP - 2017-02-16
            runAssignmentRulesForBypassSAARoutingLeads(newLeadList); // following insert only.            
            
            isAfterInsertTriggerCalled = TRUE;
        }
    }

    public static void OnAfterUpdate(List<Lead> newLeadList, Map<Id,Lead> oldLeadMap, Map<Id,Lead> newLeadMap){
        
      //3.4 - Retrieve lowest level 'Phased Code Removal' settings
      Phased_Code_Removal__c pcr = Phased_Code_Removal__c.getInstance();
      
      if(!isAfterUpdateTriggerCalled){
        if(!comesFromInsert){

            if (!system.isBatch()){
                if (null != newLeadlist && oldLeadMap != null){
                    
                    if (1 == newLeadList.size()){
                        Lead oldLead = oldLeadMap.get(newLeadList[0].Id);
                        if ((ApplicationConstant.LEAD_STATUS_CONTACT_ATTEMPTED.equalsIgnoreCase(newLeadList[0].Status) && 
                            !ApplicationConstant.LEAD_STATUS_CONTACT_ATTEMPTED.equalsIgnoreCase(oldLead.Status)) && 
                            null == newLeadList[0].GolfbreaksEnquiryId__c){
                            //3.11 - Check the 'Disable_Legacy_Client_Enq_Integrations__c' before executing
                            if(pcr != null && !pcr.Disable_Legacy_Client_Enq_Integrations__c){
                                createClubhouseEnquiry(newLeadList[0]);
                            }
                        }
                    }
                }
            }  

            //3.4 - Check the 'Disable Account NVM Id Setting' setting before executing
            if(pcr != null && !pcr.Disable_Account_NVM_Id_Setting__c){
                setLeadIdRating(newLeadMap);
            }    
            
            //3.4 - Check the 'Disable SAA Capacity Calculation' setting before executing
            if(pcr != null && !pcr.Disable_SAA_Capacity_Calculation__c){
                checkStatusUpdates(newLeadList,oldLeadMap);
            }
            
            createUpdateEvent(newLeadMap,oldLeadMap);              
            
            //3.4 - Check the 'Disable SAA Capacity Calculation' setting before executing
            if(pcr != null && !pcr.Disable_SAA_Capacity_Calculation__c){
                AP54_SalesAgentAttributeUtility.updateCorrespodingSAAofRecOwners(newLeadList, new List<Opportunity>());
            }    

            //2017-07-27 : SM : New call to update Shadow Opportunity stage if Lead Status is No Sale or Duplicate
            Map<Id, Lead> processMap = new Map<Id, Lead>();
            if (null != newLeadList && null != oldLeadMap){
                for (Lead l : newLeadlist){
                    Lead oldLead = oldLeadMap.get(l.Id);
                    if (l.OwnerId != oldLead.OwnerId){
                        if (!processMap.containsKey(l.Id)) processMap.put(l.Id, l);
                    }
                    if (ApplicationConstant.LEAD_NO_SALE.equalsIgnoreCase(l.Status) ||
                        ApplicationConstant.LEAD_STATUS_DUPLICATE.equalsIgnoreCase(l.Status)){
                            if (!processMap.containsKey(l.Id)) processMap.put(l.Id, l);
                    }else if (ApplicationConstant.LEAD_STATUS_CONTACT_ATTEMPTED.equalsIgnoreCase(l.Status) && 
                                (ApplicationConstant.LEAD_NO_SALE.equalsIgnoreCase(oldLeadMap.get(l.Id).Status) ||
                                    ApplicationConstant.LEAD_STATUS_DUPLICATE.equalsIgnoreCase(oldLeadMap.get(l.Id).Status))){
                            if (!processMap.containsKey(l.Id)) processMap.put(l.Id, l);
                    }
                }
                //3.11 - Check the 'Disable_Shadow_Opportunities__c' before executing
                if(pcr != null && !pcr.Disable_Shadow_Opportunities__c){
                    updateShadowOpportunity(processMap.values(), oldLeadMap);
                }
            }

            //3.1 - check the Disable_Legacy_Acct_Manager_Integrations__c setting before executing
            if(pcr != null && !pcr.Disable_Legacy_Acct_Manager_Integrations__c){
                //2017-08-09 : SM : New call to update the Account Manager (owner) of the Lead in Clubhouse, if the owner has changed
                if (!system.isBatch()){
                    if (null != newLeadlist && null != oldLeadMap){
                        if (1 == newLeadList.size() && (newLeadList[0].OwnerId != oldLeadMap.get(newLeadList[0].Id).OwnerId) && 
                            null != newLeadList[0].GolfbreaksEnquiryId__c){

                            updateAccountManager(String.valueOf(newLeadList[0].Id));
                        }
                    }
                }  
            }

            //Call the method to populate the converted Opportunity post-conversion
            //2018-01-18 : SM : Not running this method now, running the code from the LC04_LeadConvertProcessor class
            /*
            if (!system.isBatch()){
                system.debug('*** -- Calling postConvertProcessor -- ***');
                if (null != newLeadList){
                    Set<Id> leadIds = new Set<Id>();
                    for (Lead l : newLeadList){
                        leadIds.add(l.Id);
                    }
                    if (!leadIds.isEmpty() && !system.isFuture()){
                        postConvertProcessor(leadIds);
                    }
                }
            }
            */
        }
          
          //3.4 - Check the 'Disable SAA Capacity Calculation' setting before executing
          if(pcr != null && !pcr.Disable_SAA_Capacity_Calculation__c){
            checkLeadOwnerUpdate(newLeadList,oldLeadMap);
          }
          
          isAfterUpdateTriggerCalled = TRUE;
      }
    }
    
    /**
     ** @Author: Simon Molloy
     ** @Method Name: updateAccountManager
     ** @Description: If the Lead Owner changes, update the Account Manager in Clubhouse
     **/    
     public static void updateAccountManager(String leadId){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        try {
            
            WS01_RebarHTTPCallout.updateAccountManager(leadId);
            
        }catch (Exception e){
            system.debug('*** -- Exception: ' + e + ' at ' + e.getLineNumber() + ' -- ***');
            logs.add(ApplicationConstant.getExceptionLog(e, 'updateAccountManager', CLASS_NAME, null));
        }finally {
            if(!logs.isEmpty()){ Database.insert(logs, false); }   
        }    
     }

    /**
     ** @Author: Simon Molloy
     ** @Method Name: updateShadowOpportunity
     ** @Description: If the Lead is marked as No Sale or Duplicate, the corresponding Shadow Opportunity should
     ** also be updated
     ** @Modification: Also updates Owner of Shadow Opportunity if Lead Owner is changed
     ** @Modification: Also updates Account Manager (owner) in Clubhouse
     **/    
     public static void updateShadowOpportunity(List<Lead> inLeads, Map<Id, Lead> oldLeads){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        system.debug('*** -- inLeads = ' + inLeads.size() + ' -- ***');
        system.debug('*** -- oldLeads = ' + oldLeads.size() + ' -- ***');
        try {
            Set<Id> leadIds = new Set<Id>();
            for (Lead l : inLeads){
                leadIds.add(l.Id);
            }

            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
            for (Opportunity o : [select Id, StageName, Source_Lead__c, NoSaleReason__c, OwnerId from Opportunity where Source_Lead__c in :leadIds AND 
                                    RecordTypeId = :ApplicationConstant.getRecordTypeId('Opportunity','Sales_Shadow_Opportunity')]){
                
                oppMap.put(o.Source_Lead__c, o);
                
            }

            List<Opportunity> changedOpps = new List<Opportunity>();
            for (Lead l : inLeads){
                Opportunity shadowOpp = oppMap.get(l.Id);
                //Get the old Lead value, to see if the Owner has changed
                Lead oldLead = oldLeads.get(l.Id);
                boolean oppChanged = false;
                if (null != shadowOpp){
                    if (ApplicationConstant.LEAD_NO_SALE.equalsIgnoreCase(l.Status)){
                        shadowOpp.StageName = ApplicationConstant.OPP_STAGE_NOSALE;
                        shadowOpp.NoSaleReason__c = l.NoSaleReason__c;
                        shadowOpp.NoSaleReasonComments__c = l.NoSaleReasonComments__c;
                        oppChanged = true;
                    }else if (ApplicationConstant.LEAD_STATUS_DUPLICATE.equalsIgnoreCase(l.Status)){
                        shadowOpp.StageName = ApplicationConstant.OPP_STAGE_DUPLICATE;
                        shadowOpp.NoSaleReasonComments__c = l.DuplicateNotaLeadReason__c;
                        oppChanged = true;
                    }else if (ApplicationConstant.LEAD_STATUS_CONTACT_ATTEMPTED.equalsIgnoreCase(l.Status)){
                        shadowOpp.NoSaleReasonComments__c = null;
                        shadowOpp.StageName = ApplicationConstant.RECOMMENDATIONSTAGE;
                        shadowOpp.RecordTypeId = ApplicationConstant.getRecordTypeId('Opportunity','Sales_Shadow_Opportunity');
                        oppChanged = true;
                    }

                    if (l.OwnerId != oldLead.OwnerId && shadowOpp.OwnerId != l.OwnerId){
                        shadowOpp.OwnerId = l.OwnerId;
                        oppChanged = true;
                    }

                    if (oppChanged) changedOpps.add(shadowOpp);
                }
            }

            //Update the Opportunities
            
            try {
                update changedOpps;   
            }catch(Exception e){
                system.debug('*** -- Exception: ' + e + ' at ' + e.getLineNumber() + ' -- ***');
                logs.add(ApplicationConstant.getExceptionLog(e, 'updateShadowOpportunity', CLASS_NAME, null));
            }finally{
                if(!logs.isEmpty()){ Database.insert(logs, false); }
            }
        }catch (Exception e){
            system.debug('*** -- Exception: ' + e + ' at ' + e.getLineNumber() + ' -- ***');
            logs.add(ApplicationConstant.getExceptionLog(e, 'updateShadowOpportunity', CLASS_NAME, null));
        }finally {
            if(!logs.isEmpty()){ Database.insert(logs, false); }   
        }    
     }


    /**
     ** @Author: Simon Molloy
     ** @Method Name: createShadowOpportunity
     ** @Description: Overloaded method for createShadowOpportunity that accepts Lead records as opposed to Lead Ids
     ** Will call createShadowOpportunity(Set<Id> inLeadIds)
     **/    
    public static void createShadowOpportunity(List<Lead> inLeads){
        Set<Id> leadIds = new Set<Id>();
        for (Lead l : inLeads){
            leadIds.add(l.Id);
        }

        createShadowOpportunity(leadIds);
    }

    /**
     ** @Author: Simon Molloy
     ** @Method Name: createShadowOpportunity
     ** @Description: creates Opportunity record for each Lead, record type "Sales_Shadow_Opportunity"
     ** enabling quoting at earliest possible time for Sales Agents
     **/        
    public static void createShadowOpportunity(Set<Id> inLeadIds){
        system.debug('*** -- Into createShadowOpportunity -- ***');
        List<Error_Log__c> logs = new List<Error_Log__c>();
        //Try / Catch block
        try {
            
            //List<Lead> leads = [select Id, FirstName, LastName, Status, GolfbreaksEnquiryId__c, Golfbreaks_Opportunity_Portal_Key__c, 
            //                    Account__c, Business_Unit__c, Booking_System__c from Lead where Id in :inleadIds];
            List<Lead> leads = [select Id, FirstName, LastName, Status, GolfbreaksEnquiryId__c, Golfbreaks_Opportunity_Portal_Key__c, 
                                Account__c from Lead where Id in :inleadIds];

            system.debug('*** -- Leads size = ' + leads.size() + ' -- ***');

            Id shadowRTId = ApplicationConstant.getRecordTypeId('Opportunity','Sales_Shadow_Opportunity');
            Map<Id, Lead> processMap = new Map<Id, Lead>();
            Set<Id> leadIds = new Set<Id>();
            
            for (Lead l : leads){
                system.debug('*** -- Putting Lead Id with ' + l.Status + ' -- ***');
                leadIds.add(l.Id);
            }

            Map<Id, Opportunity> shadowOpps = new Map<Id, Opportunity>();
            for (Opportunity o : [select Id, Source_Lead__c from Opportunity where Source_Lead__c in :leadIds AND RecordTypeId = :shadowRTId]){
                if (null != o.Source_Lead__c) shadowOpps.put(o.Source_Lead__c, o);
            }
            //for (Opportunity o : [select Id, Source_Lead__c, Business_Unit2__c, Booking_System__c from Opportunity where Source_Lead__c in :leadIds AND RecordTypeId = :shadowRTId]){
            //    if (null != o.Source_Lead__c) shadowOpps.put(o.Source_Lead__c, o);
            //}
            
            
            //For each lead check the Status, the Golfbreaks Enquiry ID and if it already has a Shadow Opportunity
            for (Lead l : leads){
                if (ApplicationConstant.LEAD_STATUS_CONTACT_ATTEMPTED.equalsIgnoreCase(l.Status) && 
                    null != l.GolfbreaksEnquiryId__c && 
                    !shadowOpps.containsKey(l.Id)){
                    processMap.put(l.Id, l);
                }
            }

            Map<Id, Opportunity> newOppMap = new Map<Id, Opportunity>();
            system.debug('*** -- Processing ' + processMap.size() + ' -- ***');
            for (Lead l : processMap.values()){
                Opportunity shadowOpp = new Opportunity();
                shadowOpp.Name = l.FirstName + ' ' + l.LastName;
                shadowOpp.CloseDate = Date.today();
                shadowOpp.StageName = ApplicationConstant.RECOMMENDATIONSTAGE;
                shadowOpp.AccountId = l.Account__c;
                shadowOpp.Source_Lead__c = l.Id;
                shadowOpp.GolfbreaksEnquiryId__c = l.GolfbreaksEnquiryId__c;
                shadowOpp.Golfbreaks_Portal_Key__c = l.Golfbreaks_Opportunity_Portal_Key__c;
                shadowOpp.RecordTypeId = shadowRTId;
                //shadowOpp.Business_Unit2__c = l.Business_Unit__c;
                //shadowOpp.Booking_System__c = l.Booking_System__c;

                newOppMap.put(l.Id, shadowOpp);
            }

            //Insert the Opportunities
            system.debug('*** -- Insert the Shadow Opps -- ***');
            try {
            	GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;//<--- Disable WIRE Triggers for Shadow Opp Insert 3.5
            	system.debug('Disabling WIRE Triggers for Shadow Opp Insert');
                insert newOppMap.values(); 
                system.debug('Enabling WIRE Triggers following Shadow Opp Insert'); 
                GBWire.WorkItemTriggerHandler.disableWIRETriggers  = false;//<--- Enable WIRE Triggers following Shadow Opp Insert 3.5
            }catch(Exception e){
                system.debug('*** -- Exception: ' + e + ' at ' + e.getLineNumber() + ' -- ***');
                logs.add(ApplicationConstant.getExceptionLog(e, 'createShadowOpportunity', CLASS_NAME, null));
            }finally{
                if(!logs.isEmpty()){ Database.insert(logs, false); }
            }
        }catch (Exception e){
            system.debug('*** -- Exception: ' + e + ' at ' + e.getLineNumber() + ' -- ***');
            logs.add(ApplicationConstant.getExceptionLog(e, 'createShadowOpportunity', CLASS_NAME, null));
        }finally {
            if(!logs.isEmpty()){ Database.insert(logs, false); }   
        }
    } 

    //2018-01-18 : SM : Publicly accessible, non-future, post covert method
    public static void doPostConvert(Set<Id> inLeadIds){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        //Try / Catch block
        try {
        	
            if(!Test.isRunningTest()){//Running WIRE triggers in a test context throws an error within the package that is not accessible. The tests within the package handle the unit testing of the WorkItemUtility
                //3.6 Invoke WorkItemUtility to run Lead Closure WIRE activity - Delete Preferred Agent, recalculate Agent Capacity, run Account CRP recalculation
                system.debug('Running GBWire.WorkItemUtility.runWIRETriggerLogicOnWorkItems on Converted Leads');
                //GBWire.WorkItemUtility.runWIRETriggerLogicOnWorkItems(inLeadIds,'Lead',true,true,false,false,true); /*<--- 3.9 comment out*/
                //3.9 //3.10 Comment Out
                /*Map<Id,GBWire.WorkItemWithActionsWrapper> recordIdsWithRequiredActions = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
                for(Id leadId : inLeadIds){
                    GBWire.WorkItemWithActionsWrapper wrapper = new GBWire.WorkItemWithActionsWrapper();
                    wrapper.doPreferredAgentCalc = true;
                    wrapper.doAgentCapacityCalc = true;
                    wrapper.doCRPCalc = true;
                    wrapper.doAssign = false;
                    wrapper.doPreferredQueueCalc = false;
                    recordIdsWithRequiredActions.put(leadId,wrapper);
                }
                try{
                    //GBWire.WorkItemUtility.executeWIRETriggerActions(recordIdsWithRequiredActions, ApplicationConstant.OBJECT_TYPE_LEAD);
                }catch(exception e){
                    PlatformLogManager.logExceptions(e,'AP04_LeadTriggerBL','doPostConvert');
                }*/
                
                
            }
        	
            Map<Id, Lead> leads = new Map<Id, Lead>([select Id, IsConverted, ConvertedOpportunityId, Amount__c from Lead where Id in :inLeadIds]);
            system.debug('*** -- Into doPostConvert -- ***');
            Id shadowRTId = ApplicationConstant.getRecordTypeId('Opportunity','Sales_Shadow_Opportunity');
            List<Lead> processList = new List<Lead>();
            
            Map<Id, Opportunity> shadowOpps = new Map<Id, Opportunity>();
            /*
            //3.3
            for (Opportunity o : [select Id, Source_Lead__c, StageName, Amount, Business_Unit2__c, Booking_System__c,  
                                    (select Id, Opportunity__c, GrossProfit__c, Status__c from Quotes__r),
                                    (select Id, TECH_Opportunity__c from Bookings__r) 
                                    from Opportunity where Source_Lead__c in :inLeadIds AND RecordTypeId = :shadowRTId]){
                if (null != o.Source_Lead__c) shadowOpps.put(o.Source_Lead__c, o);
            }            
            */            
            shadowOpps = WithoutSharingUtility.queryShadowOpportunities(inLeadIds,shadowRTId);            

            Set<Id> convertedOppIds = new Set<Id>();
            for (Lead l : leads.values()){
                system.debug('*** -- doPostConvert.Lead = ' + l + ' -- ***');
                if (l.IsConverted && 
                    null != l.ConvertedOpportunityId && 
                    null != shadowOpps.get(l.Id)){

                    processList.add(l);
                    convertedOppIds.add(l.ConvertedOpportunityId);
                }
            }    

            List<Quote__c> quotesToSave = new List<Quote__c>();
            List<Booking__c> bookingsToSave = new List<Booking__c>();
            List<Opportunity> oppsToDelete = new List<Opportunity>();

            Map<Id, Opportunity> convertedOpps = WithoutSharingUtility.queryConvertedOpportunities(convertedOppIds);


            //3.3 Map<Id, Opportunity> convertedOpps = new Map<Id, Opportunity>([select Id, StageName, Amount, Source_Lead__c from Opportunity where Id in :convertedOppIds]);
            //Map<Id, Opportunity> convertedOpps = new Map<Id, Opportunity>([select Id, StageName, Amount, Source_Lead__c, Business_Unit2__c, Booking_System__c from Opportunity where Id in :convertedOppIds]);
            Map<Id, Opportunity> leadToOppMap = new Map<Id, Opportunity>();
            for (Opportunity o : convertedOpps.values()){
                if (null != o.Source_Lead__c) leadToOppMap.put(o.Source_Lead__c, o);
            }

            for (Lead l : processList){
                Opportunity shadowOpp = shadowOpps.get(l.Id);
                Opportunity convertedOpp = convertedOpps.get(l.ConvertedOpportunityId);

                for (Quote__c q : shadowOpp.Quotes__r){
                    q.Opportunity__c = convertedOpp.Id;
                    quotesToSave.add(q);
                }
                for (Booking__c b : shadowOpp.Bookings__r){
                    b.TECH_Opportunity__c = convertedOpp.Id;
                    bookingsToSave.add(b);
                }

                //2017-12-07 : SM : New method call - to undo this change comment out Line 426 - 430 and uncomment Line 425
                if (ApplicationConstant.RECOMMENDATIONSTAGE != shadowOpp.StageName){
                    convertedOpp.StageName = shadowOpp.StageName;
                }
                //convertedOpp.Amount = shadowOpp.Amount;
                //2018-01-09 : SM : Modifying this logic due to Case 00858597
                if (null == convertedOpp.Amount && null != shadowOpp.Quotes__r && !shadowOpp.Quotes__r.isEmpty()){
                    convertedOpp.Amount = getAmount(shadowOpp.Quotes__r);
                }else {
                    if (convertedOpp.Amount == null && null != shadowOpp.Amount){
                        convertedOpp.Amount = shadowOpp.Amount;
                    }
                }
                if (null == convertedOpp.Source_Lead__c){
                    //convertedOpp.Source_Lead__c = shadowOpp.Source_Lead__c;
                    convertedOpp.Source_Lead__c = l.Id;
                }
                
                //if (convertedOpp.Business_Unit2__c != shadowOpp.Business_Unit2__c) convertedOpp.Business_Unit2__c = shadowOpp.Business_Unit2__c;
                //if (convertedOpp.Booking_System__c != shadowOpp.Booking_System__c) convertedOpp.Booking_System__c = shadowOpp.Booking_System__c;

                oppsToDelete.add(shadowOpp);
            }

            for (Opportunity o : convertedOpps.values()){
                if (null != leads.get(o.Source_Lead__c)){
                    if (null == o.Amount) o.Amount = leads.get(o.Source_Lead__c).Amount__c;
                }
            }


            system.debug('*** -- attempt save in doPostConvert -- ***');
            //SAVE & DELETE All the records
            if (!quotesToSave.isEmpty()){
                try {
                    update quotesToSave;    
                }catch(Exception e){
                    logs.add(ApplicationConstant.getExceptionLog(e, 'doPostConvert', CLASS_NAME, null));
                }
            }
            
            if (!bookingsToSave.isEmpty()){
                try {
                    update bookingsToSave; 
                }catch(Exception e){
                    logs.add(ApplicationConstant.getExceptionLog(e, 'doPostConvert', CLASS_NAME, null));
                }
            }
            if (!convertedOpps.values().isEmpty()){
                try {
                    update convertedOpps.values();
                }catch(Exception e){
                    logs.add(ApplicationConstant.getExceptionLog(e, 'doPostConvert', CLASS_NAME, null));
                }
            }

            if (!oppsToDelete.isEmpty()){
                try {
                    //3.2 delete oppsToDelete;
                    WithoutSharingUtility.deleteSObjects(oppsToDelete);//3.2                    

                }catch(Exception e){
                    logs.add(ApplicationConstant.getExceptionLog(e, 'doPostConvert', CLASS_NAME, null));
                }
            }

            if(!logs.isEmpty()){ Database.insert(logs, false);}
        }catch (Exception e){
            logs.add(ApplicationConstant.getExceptionLog(e, 'doPostConvert', CLASS_NAME, null));
        }finally {
            if(!logs.isEmpty()){ Database.insert(logs, false); }   
        }        
    }

    /**
     ** @Author: Simon Molloy
     ** @Method Name: postConvertProcessor
     ** @Description: After Lead conversion, updates new Opportunity with 'Shadow' Opportunity values 
     ** and deletes the 'Shadow' Opportunity
     ** @Modification: New method added - getAmount - to get the Opportunity Amount based off of Quotes (as per AP18_QuoteTriggerBL)
     **/  
    //2018-01-18 : SM Commented out as we no longer call it
    /*
    @future(callout=false)     
    private static void postConvertProcessor(Set<Id> inLeadIds){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        //Try / Catch block
        try {
            Map<Id, Lead> leads = new Map<Id, Lead>([select Id, IsConverted, ConvertedOpportunityId, Amount__c from Lead where Id in :inLeadIds]);
            system.debug('*** -- Into postConvertProcessor -- ***');
            Id shadowRTId = ApplicationConstant.getRecordTypeId('Opportunity','Sales_Shadow_Opportunity');
            List<Lead> processList = new List<Lead>();
            
            Map<Id, Opportunity> shadowOpps = new Map<Id, Opportunity>();
            for (Opportunity o : [select Id, Source_Lead__c, StageName, Amount, 
                                    (select Id, Opportunity__c, GrossProfit__c, Status__c from Quotes__r),
                                    (select Id, TECH_Opportunity__c from Bookings__r) 
                                    from Opportunity where Source_Lead__c in :inLeadIds AND RecordTypeId = :shadowRTId]){
                if (null != o.Source_Lead__c) shadowOpps.put(o.Source_Lead__c, o);
            }

            Set<Id> convertedOppIds = new Set<Id>();
            for (Lead l : leads.values()){
                system.debug('*** -- Lead = ' + l + ' -- ***');
                if (l.IsConverted && 
                    null != l.ConvertedOpportunityId && 
                    null != shadowOpps.get(l.Id)){

                    processList.add(l);
                    convertedOppIds.add(l.ConvertedOpportunityId);
                }
            }    

            List<Quote__c> quotesToSave = new List<Quote__c>();
            List<Booking__c> bookingsToSave = new List<Booking__c>();
            List<Opportunity> oppsToDelete = new List<Opportunity>();

            Map<Id, Opportunity> convertedOpps = new Map<Id, Opportunity>([select Id, StageName, Amount, Source_Lead__c from Opportunity where Id in :convertedOppIds]);
            Map<Id, Opportunity> leadToOppMap = new Map<Id, Opportunity>();
            for (Opportunity o : convertedOpps.values()){
                if (null != o.Source_Lead__c) leadToOppMap.put(o.Source_Lead__c, o);
            }

            for (Lead l : processList){
                Opportunity shadowOpp = shadowOpps.get(l.Id);
                Opportunity convertedOpp = convertedOpps.get(l.ConvertedOpportunityId);

                for (Quote__c q : shadowOpp.Quotes__r){
                    q.Opportunity__c = convertedOpp.Id;
                    quotesToSave.add(q);
                }
                for (Booking__c b : shadowOpp.Bookings__r){
                    b.TECH_Opportunity__c = convertedOpp.Id;
                    bookingsToSave.add(b);
                }

                //2017-12-07 : SM : New method call - to undo this change comment out Line 426 - 430 and uncomment Line 425
                if (ApplicationConstant.RECOMMENDATIONSTAGE != shadowOpp.StageName){
                    convertedOpp.StageName = shadowOpp.StageName;
                }
                //convertedOpp.Amount = shadowOpp.Amount;
                //2018-01-09 : SM : Modifying this logic due to Case 00858597
                if (null == convertedOpp.Amount && null != shadowOpp.Quotes__r && !shadowOpp.Quotes__r.isEmpty()){
                    convertedOpp.Amount = getAmount(shadowOpp.Quotes__r);
                }else {
                    if (convertedOpp.Amount == null && null != shadowOpp.Amount){
                        convertedOpp.Amount = shadowOpp.Amount;
                    }
                }
                if (null == convertedOpp.Source_Lead__c){
                    //convertedOpp.Source_Lead__c = shadowOpp.Source_Lead__c;
                    convertedOpp.Source_Lead__c = l.Id;
                }

                oppsToDelete.add(shadowOpp);
            }

            for (Opportunity o : convertedOpps.values()){
                if (null != leads.get(o.Source_Lead__c)){
                    if (null == o.Amount) o.Amount = leads.get(o.Source_Lead__c).Amount__c;
                }
            }


            system.debug('*** -- attempt save in postConvertProcessor -- ***');
            //SAVE & DELETE All the records
            if (!quotesToSave.isEmpty()){
                try {
                    update quotesToSave;    
                }catch(Exception e){
                    logs.add(ApplicationConstant.getExceptionLog(e, 'postConvertProcessor', CLASS_NAME, null));
                }
            }
            
            if (!bookingsToSave.isEmpty()){
                try {
                    update bookingsToSave; 
                }catch(Exception e){
                    logs.add(ApplicationConstant.getExceptionLog(e, 'postConvertProcessor', CLASS_NAME, null));
                }
            }
            if (!convertedOpps.values().isEmpty()){
                try {
                    update convertedOpps.values();
                }catch(Exception e){
                    logs.add(ApplicationConstant.getExceptionLog(e, 'postConvertProcessor', CLASS_NAME, null));
                }
            }

            if (!oppsToDelete.isEmpty()){
                try {
                    delete oppsToDelete;
                }catch(Exception e){
                    logs.add(ApplicationConstant.getExceptionLog(e, 'postConvertProcessor', CLASS_NAME, null));
                }
            }

            if(!logs.isEmpty()){ Database.insert(logs, false);}
        }catch (Exception e){
            logs.add(ApplicationConstant.getExceptionLog(e, 'createShadowOpportunity', CLASS_NAME, null));
        }finally {
            if(!logs.isEmpty()){ Database.insert(logs, false); }   
        }
        
    }
    */
    //2017-12-07 : SM : Method to take in all Quotes and work out the correct Amount for the Converted Opp
    //2017-12-07 : SM : See AP18_QuoteTriggerBL for same code
    private static Decimal getAmount(List<Quote__c> quotes){
        boolean hasBooking = false;
        Decimal returnAmount;
        for(Quote__c qt : quotes){
            if(qt.Status__c == ApplicationConstant.QUOTEBOOKINGSTATUS || qt.Status__c == ApplicationConstant.QUOTECANCELLATION){
                hasBooking = true;
                if(null != qt.GrossProfit__c) {
                    returnAmount = qt.GrossProfit__c;
                }
            }
        }
        if(!hasBooking) {
            system.debug('*** -- Into Averaging Code -- ***');
            integer noOfQuotes = quotes.size();
            system.debug('*** -- Number of quotes ' + noOfQuotes + ' -- ***');
            decimal quoteTotals = 0;
            for (Quote__c qt : quotes){
                quoteTotals += (null == qt.GrossProfit__c ? 0 : qt.GrossProfit__c);
            }
            system.debug('*** -- quoteTotals ' + quoteTotals + ' -- ***');
            returnAmount = quoteTotals / noOfQuotes;
        }

        return returnAmount;
    }
    
    /**
     ** @Author: Mark Cane
     ** @Method Name: runAssignmentRulesForBypassSAARoutingLeads
     ** @Description: applied DML update to leads that shoudl bypass SAA routing. 
     ** Assumption that trigger recursive guard vars protect this code from reentrancy.
     **/        
    private static void runAssignmentRulesForBypassSAARoutingLeads(List<Lead> leads){       
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        try {
        
            System.debug('runAssignmentRulesForBypassSAARoutingLeads --- leads: ' + leads.size());
                
            List<Lead> leadsToUpdate = new List<Lead>();
            
            for (Lead l : leads){
                if (l.Bypass_SAA_Routing__c){ leadsToUpdate.add(new Lead(Id=l.Id)); }
            }
            if (leadsToUpdate.isEmpty()) return;
                        
            Boolean cachedComesFromInsert = AP04_LeadTriggerBL.comesFromInsert;
            
            // the static guard vars must be manipulated to prevent trigger logic running within this update. 
            
            AP04_LeadTriggerBL.isBeforeUpdateTriggerCalled = true;
            AP04_LeadTriggerBL.isAfterUpdateTriggerCalled = true;
            AP04_LeadTriggerBL.comesFromInsert = false;

            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule = true;     
            
            Database.update(leadsToUpdate,dmo);
            
            AP04_LeadTriggerBL.isBeforeUpdateTriggerCalled = false;
            AP04_LeadTriggerBL.isAfterUpdateTriggerCalled = false;
            AP04_LeadTriggerBL.comesFromInsert = cachedComesFromInsert;         
        
        }catch(Exception e){
            logs.add(ApplicationConstant.getExceptionLog(e, 'runAssignmentRulesForBypassSAARoutingLeads()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){ Database.insert(logs, false); }
        }
    }    
    

    /**
     ** @Author: Simon Molloy
     ** @Method Name: updateCallbackDateTime
     ** @Description: Updates Call Back Date Time with Diary Date + Call Back Hour / Minute (if populated)
     **
     **/    
    private static void updateCallbackDateTime(List<Lead> newLeads, Map<Id, Lead> oldLeads){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        try {
            if (null != newLeads && !newLeads.isEmpty()){
                if (null != oldLeads){
                    for (Lead l : newLeads){
                        boolean isError = false;
                        Lead oldLead = oldLeads.get(l.Id);
                        if (l.Call_Back_Hour__c != oldLead.Call_Back_Hour__c ||
                            l.Call_Back_Minute__c != oldLead.Call_Back_Minute__c ||
                            l.Diarydate__c != oldLead.Diarydate__c){
                            if (null != l.Call_Back_Hour__c || null != l.Call_Back_Minute__c){
                                if (null != l.Call_Back_Hour__c && null == l.Call_Back_Minute__c){
                                    //2016-12-09 : SM : Defaulting minutes to '00' if Hour is selected
                                    //l.addError('Please select a Call Back Minute value for this Lead');
                                    //isError = true;
                                    l.Call_Back_Minute__c = '00';
                                }
                                if (null != l.Call_Back_Minute__c && null == l.Call_Back_Hour__c){
                                    l.addError('Please select a Call Back Hour value for this Lead');
                                    isError = true;
                                }
                                
                                if (!isError){
                                    l.CallBackDateTime__c = buildCallBackDateTime(l);
                                }
                            }
                        }
                        if (null == l.Call_Back_Hour__c && null == l.Call_Back_Minute__c){
                            if (null != l.CallBackDateTime__c) l.CallBackDateTime__c = null;
                        }
                    }
                }else {
                    for (Lead l : newLeads){
                        boolean isError = false;
                        if (null != l.Call_Back_Hour__c || null != l.Call_Back_Minute__c){
                            if (null != l.Call_Back_Hour__c && null == l.Call_Back_Minute__c){
                                //2016-12-09 : SM : Defaulting minutes to '00' if Hour is selected
                                //l.addError('Please select a Call Back Minute value for this Lead');
                                //isError = true;
                                l.Call_Back_Minute__c = '00';
                            }
                            if (null != l.Call_Back_Minute__c && null == l.Call_Back_Hour__c){
                                l.addError('Please select a Call Back Hour value for this Lead');
                                isError = true;
                            }
                            
                            if (!isError){
                                l.CallBackDateTime__c = buildCallBackDateTime(l);
                            }
                        }
                    }
                }
            }
        }catch (Exception e){
            logs.add(ApplicationConstant.getExceptionLog(e, 'updateCallbackDateTime()', CLASS_NAME, 'Lead'));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
       
    }
    
    private static DateTime buildCallBackDateTime(Lead l){
        if (null == l.Diarydate__c) return null;
        Time myTime = Time.newInstance(integer.valueOf(l.Call_Back_Hour__c), integer.valueOf(l.Call_Back_Minute__c), 0, 0);

        DateTime dt = DateTime.newInstance(l.Diarydate__c, myTime);
        
        return dt;
    }
    
    /**
     ** @Author: Mark Cane
     ** @Method Name: updateCustomerCallbackDateTime
     ** @Description: Set the DST aware time field value.
     **
     **/    
    private static void updateCustomerCallBackTime(List<Lead> newLeads, Map<Id, Lead> oldLeads){//2.10
        List<Error_Log__c> logs = new List<Error_Log__c>();
        try {
            if ((Trigger.isInsert && null != newLeads && !newLeads.isEmpty()) ||               
              (Trigger.isUpdate && oldLeads!=null && !oldLeads.isEmpty())){

                TimeZone tz = TimeZone.getTimeZone('Europe/London');
                Datetime startDt,adjustedDt;
                Integer tzOffset;
  
                for (Lead l : newLeads){
          
                    if (Trigger.isInsert && l.Customer_Call_Back_Date_Time__c==null) continue;          
                    if (Trigger.isUpdate && (!oldLeads.containsKey(l.Id) || oldLeads.get(l.Id).Customer_Call_Back_Date_Time__c==l.Customer_Call_Back_Date_Time__c)) continue;
                      
                      
                    if (Trigger.isUpdate && oldLeads.get(l.Id).Customer_Call_Back_Date_Time__c!=null && l.Customer_Call_Back_Date_Time__c==null){
                        // date field is set from non-null to null == blank the target field.
                        l.Customer_Call_Back_Time_DST__c=null;
            
                    } else {
                        // new lead with the date field set, or updated lead and the date value has changed.
                        
                        startDt = l.Customer_Call_Back_Date_Time__c;
              
                        tzOffset = tz.getOffset(startDt);
                        adjustedDt = startDt.addSeconds(tzOffset/1000);
                        
                        l.Customer_Call_Back_Time_DST__c = String.valueOf(adjustedDt.timeGmt()).Left(5);
                    }          
                }
            }
        }catch (Exception e){
            logs.add(ApplicationConstant.getExceptionLog(e, 'updateCustomerCallbackDateTime()', CLASS_NAME, 'Lead'));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }       
    }
    
    /**
     ** @Author: Mark Cane
     ** @Method Name: updateDefaultInternationalisationValues
     ** @Description: Set the default Golfbreaks Business Unit and Booking System if not set.
     **
     **/    
    private static void updateDefaultInternationalisationValues(List<Lead> newLeads){//2.11
        List<Error_Log__c> logs = new List<Error_Log__c>();
        try {
            if (!Trigger.isInsert || null == newLeads || newLeads.isEmpty()) return;

            Boolean hasMissingBookingSystemValues=false; 

            for (Lead l : newLeads){                    
                
                if (l.Golfbreaks_Business_Unit__c==null && Internationalisation_Settings__c.getInstance()!=null)
                    l.Golfbreaks_Business_Unit__c = Internationalisation_Settings__c.getInstance().Default_Golfbreaks_Business_Unit_Id__c;
                
                if (String.isBlank(l.Booking_System__c) && l.Golfbreaks_Business_Unit__c!=null)                 
                    hasMissingBookingSystemValues=true;
            }
            
            if (hasMissingBookingSystemValues){
                
                Map<Id,Golfbreaks_Business_Unit__c> idToBusinessUnit = new Map<Id,Golfbreaks_Business_Unit__c>([select Id, Default_Booking_System__c from Golfbreaks_Business_Unit__c where Default_Booking_System__c!=null]); 

                for (Lead l : newLeads){
                    
                    if (String.isBlank(l.Booking_System__c) &&
                        l.Golfbreaks_Business_Unit__c!=null && 
                        idToBusinessUnit.containsKey(l.Golfbreaks_Business_Unit__c)){
                        
                        l.Booking_System__c = idToBusinessUnit.get(l.Golfbreaks_Business_Unit__c).Default_Booking_System__c;                            
                    }
                }
            }
        }catch (Exception e){
            logs.add(ApplicationConstant.getExceptionLog(e, 'updateDefaultInternationalisationValues()', CLASS_NAME, 'Lead'));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }       
    }             
    
    /**
     ** @Author: Simon Molloy
     ** @Method Name: createClubhouseClient
     ** @Description: Takes a newly inserted Lead, and creates a client in Clubhouse if appropriate
     **
     **/    
    public static void createClubhouseClient(Lead leadToConvert){
        String accId = '';
        String oppId = '';
        String accName = '';
        String errors = '';
        String oppName;
        oppName = '';
        Id leadId = leadToConvert.Id;
        
        String webServiceResponse = '';
        Integer responseStatus = 0;
        Boolean isUpdate = true;
        List<String> tmpString = new List<String>();
        Communication_Preference__c newsletterCommPref;
        
        if (!'PHONE'.equalsIgnoreCase(leadToConvert.LastName)){

            try {
                if((leadToConvert.GolfbreaksEnquiryId__c == null || String.isBlank(String.valueOf(leadToConvert.GolfbreaksEnquiryId__c))) && leadToConvert.Status != ApplicationConstant.LEAD_STATUS_CLOSED_CONVERTED){
                    System.debug('>>>> rebar is called');
                    //webServiceResponse = WS01_RebarHTTPCallout.outboundMessageCreatorFuture(leadId);
                    WS01_RebarHTTPCallout.outboundMessageCreatorFuture(leadId, 'CLIENT');
                    System.debug('>>>> webServiceResponse ' +webServiceResponse);
                    
                    /*
                    //parse return string to get response
                    if(String.isNotBlank(webServiceResponse)){
                        tmpString = webServiceResponse.split(';');
                        responseStatus = Integer.valueOf(tmpString[0]);
                        if(tmpString[1] == 'CREATED'){
                            isUpdate = false;
                        } else if(tmpString[1] == 'UPDATED'){
                            isUpdate = true;
                        } else if(tmpString[1] == 'ERROR'){
                            errors = tmpString[2];
                        }
                    }
                    */
                }
                
                //We cannot do anything with the response as its now running in an @future method
                //TODO: Do we need to validate the return / setting of the GolfbreaksEnquiryId__c value?
                //if ((String.isNotBlank(String.valueOf(leadToConvert.GolfbreaksEnquiryId__c)) || APIUtility.setPositiveStatuses.contains( responseStatus )) && leadToConvert.Status != ApplicationConstant.LEAD_STATUS_CLOSED_CONVERTED ) {
                    //TODO:  What?  Do we also update the Lead with the correspdonding found / created Client ID?
                //}
                
            
            } catch(DmlException e){ 
                String error = e.getMessage();
                System.debug('The following exception has occurred: ' + e.getMessage());
           }
        }
    }
    
    /**
     ** @Author: Simon Molloy
     ** @Method Name: createClubhouseEnquiry
     ** @Description: Takes a newly inserted Lead, and creates a corresponding Enquiry in Clubhouse
     ** 2016-12-06 : SM : Not using in this version, saving here for future development
     **
     **/    
     
    private static void createClubhouseEnquiry(Lead leadToConvert){
        String accId = '';
        String oppId = '';
        String accName = '';
        String errors = '';
        String oppName;
        oppName = '';
        Id leadId = leadToConvert.Id;
        
        String webServiceResponse = '';
        Integer responseStatus = 0;
        Boolean isUpdate = true;
        List<String> tmpString = new List<String>();
        Communication_Preference__c newsletterCommPref;
                         
        try {
            if((leadToConvert.GolfbreaksEnquiryId__c == null || String.isBlank(String.valueOf(leadToConvert.GolfbreaksEnquiryId__c))) && leadToConvert.Status != ApplicationConstant.LEAD_STATUS_CLOSED_CONVERTED){
                System.debug('>>>> rebar is called');
                //webServiceResponse = WS01_RebarHTTPCallout.outboundMessageCreatorFuture(leadId);
                WS01_RebarHTTPCallout.outboundMessageCreatorFuture(leadId, 'ENQUIRY');
                System.debug('>>>> webServiceResponse ' +webServiceResponse);
                
                /*
                //parse return string to get response
                if(String.isNotBlank(webServiceResponse)){
                    tmpString = webServiceResponse.split(';');
                    responseStatus = Integer.valueOf(tmpString[0]);
                    if(tmpString[1] == 'CREATED'){
                        isUpdate = false;
                    } else if(tmpString[1] == 'UPDATED'){
                        isUpdate = true;
                    } else if(tmpString[1] == 'ERROR'){
                        errors = tmpString[2];
                    }
                }
                */
            }
            
            //We cannot do anything with the response as its now running in an @future method
            //TODO: Do we need to validate the return / setting of the GolfbreaksEnquiryId__c value?
            //if ((String.isNotBlank(String.valueOf(leadToConvert.GolfbreaksEnquiryId__c)) || APIUtility.setPositiveStatuses.contains( responseStatus )) && leadToConvert.Status != ApplicationConstant.LEAD_STATUS_CLOSED_CONVERTED ) {
                //TODO:  What?  Do we also update the Lead with the correspdonding found / created Client ID?
            //}
            
        
        } catch(DmlException e){ 
            String error = e.getMessage();
            System.debug('The following exception has occurred: ' + e.getMessage());
       }
    }
    
    /**
     ** @Author: <Recuerdo Bregente>
     ** @Method Name: isChangeLeadOwner
     ** @Description: This method will update AssignedtoSAA__c of Lead record
     **
     **/   
    private static void isChangeLead(List<Lead> newLeadList, Map<Id, Lead> oldLeadMap){
        System.debug('isChangeLead --- Start');
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Set<Id> salesRep = new Set<Id>();
        List<Lead> leadsToRoute = new List<Lead>(); 
        
        try{
            for(Sales_Agent_Attributes__c saa: [SELECT Id, Sales_Rep__c FROM Sales_Agent_Attributes__c WHERE RecordType.Name = :ApplicationConstant.LEAD_SALES_AGENT]){
                salesRep.add(saa.Sales_Rep__c);
            }
            
            // Go through every lead in the trigger
            for (Lead leadRec : newLeadList){
                if(leadRec.Status <> ApplicationConstant.LEAD_CLOSED_CONVERTED && leadRec.Status <> ApplicationConstant.LEAD_NO_SALE && 
                    leadRec.Status <> ApplicationConstant.LEAD_STATUS_DUPLICATE){        
                    if(leadRec.OwnerId <> oldLeadMap.get(leadRec.Id).OwnerId){ 
                        if(!salesRep.contains(leadRec.OwnerId)){
                            leadRec.AssignedtoSAA__c = false;
                        }
                    }
                    else{
                        leadsToRoute.add(leadRec);
                    }
                }
            }
            System.debug('isChangeLead --- leadsToRoute:'+leadsToRoute);
            if(!leadsToRoute.isEmpty()){
                AP27_LeadAssignmentUtility.leadRouter(leadsToRoute, true);
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'isChangeLead', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
        System.debug('isChangeLead --- End');
    }
    
    /**
     ** @Author: <Recuerdo Bregente>
     ** @Method Name: filterReturnTravellerLeadsForRouting
     ** @Description: This method will filter return traveller leads for routing
     **
     **/   
    private static void filterReturnTravellerLeadsForRouting(List<Lead> newLeadList){
        System.debug('filterReturnTravellerLeadsForRouting --- Start');
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Map<Id, User> apiUser = new Map<Id, User>([SELECT Id, Name FROM User WHERE Name = :ApplicationConstant.USER_NAME_API_USER]);
        List<Lead> travellerLeads = new List<Lead>();
        List<Lead> leadsForRouting = new List<Lead>();
        List<Lead> inboundCallLeads = new List<Lead>();
        
        try{
            for(Lead leadRecord : newLeadList){
                if(ApplicationConstant.LEAD_STATUS_NEW.equals(leadRecord.Status) && !String.isEmpty(leadRecord.SalesRegion__c) && 
                    (ApplicationConstant.LEAD_SOURCE_PHONE.equals(leadRecord.LeadSource) && apiUser.containsKey(leadRecord.OwnerId))){
                    inboundCallLeads.add(leadRecord);
                }
                else if(ApplicationConstant.RETURNING_TRAVELLER.equals(leadRecord.LeadSource)){
                    travellerLeads.add(leadRecord);
                }
                else{
                    leadsForRouting.add(leadRecord);
                }
            }
            
            if(!travellerLeads.isEmpty()){
                AP27_LeadAssignmentUtility.assignToReturningTravellerSalesTeam(travellerLeads);
            }
            
            if(!leadsForRouting.isEmpty()){
                AP27_LeadAssignmentUtility.leadRouter(leadsForRouting, true);
            }
            
            if(!inboundCallLeads.isEmpty()){
                Map<String, String> teamMap = AP27_LeadAssignmentUtility.mapTeamByRegionAndSize(inboundCallLeads);
                AP27_LeadAssignmentUtility.assignLeadsToQueue(inboundCallLeads, teamMap);
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'filterReturnTravellerLeadsForRouting', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
        
        System.debug('filterReturnTravellerLeadsForRouting --- End');
    }

    
    /**
     ** @Author: Merari Cebrian
     ** @Method Name: verifyLeadOwnerChanged
     ** @Description: Verifies if lead owner has changed
     **
     **/   
    private static void checkLeadOwnerUpdate(List<Lead> newLeadList, Map<Id, Lead> oldLeadMap){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        List<Lead> leadToUpdate = new List<Lead>();
        
        try{
            for(Lead newLead : newLeadList) {
                if(oldLeadMap.containsKey(newLead.Id) && newLead.OwnerId != oldLeadMap.get(newLead.Id).OwnerId) {
                    leadToUpdate.add(newLead);
                    leadToUpdate.add(oldLeadMap.get(newLead.Id));
                }
            }
            if(!leadToUpdate.isEmpty()) AP54_SalesAgentAttributeUtility.updateCorrespodingSAAofRecOwners(leadToUpdate, new List<Opportunity>());
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'checkLeadOwnerUpdate', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }
    
    /**
     ** @Author: Recuerdo Bregente / MaJoy Maliñana
     ** @Method Name/s: setLeadScore, getLeadScoringRuleByRecordType, checkMatching, getFieldValue, getScoreMapping, getLeadRating, isInRange 
     ** @Description: Logic for setting Lead Scoring upon inserting or updating Lead record.
     **
     **/    
    public static void setLeadScore (List<Lead> newLeadMap){
        System.debug('setLeadScore --- Start');
        
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Map<Id, RecordType> recordTypeMap = new Map<Id, RecordType>([SELECT Id,Name FROM RecordType WHERE SobjectType=:'Lead']); 
        Map<String, Id> leadAndRecordTypeMap = new Map<String, Id>();
        List<Lead> leadWithRecordType = new List<Lead>();
        
        try{
            String leadIdentifier = '';
            for(Lead leadRecord: newLeadMap){
                if(leadRecord.RecordTypeId != null){
                    leadWithRecordType.add(leadRecord);
                    leadIdentifier = leadRecord.LastName+leadRecord.FirstName+leadRecord.Company+leadRecord.Status+leadRecord.LeadSource+leadRecord.Email+leadRecord.Phone;
                    leadAndRecordTypeMap.put(leadIdentifier, leadRecord.RecordTypeId);
                }
            }
            
            newLeadMap = leadWithRecordType;
            
            Map<Id, LeadScoringRule__c> lsrMap = getLeadScoringRuleByRecordType(leadAndRecordTypeMap.values());
            
            Map<String, Decimal> leadAndScoringMap = new Map<String, Decimal>();
            Map<String, String> describedFieldsMap = getDescribeFields();
            for(Lead leadRecord: newLeadMap){
                leadIdentifier = leadRecord.LastName+leadRecord.FirstName+leadRecord.Company+leadRecord.Status+leadRecord.LeadSource+leadRecord.Email+leadRecord.Phone;
                for(LeadScoringRule__c lsr: lsrMap.values()){
                    if(lsr.RecordType__c.equals(leadRecord.RecordTypeId) && 
                        checkMatching(leadRecord, lsr, describedFieldsMap)){
                        if(!leadAndScoringMap.containsKey(leadIdentifier)){
                            leadAndScoringMap.put(leadIdentifier, 0);
                        }
                        leadAndScoringMap.put(leadIdentifier, leadAndScoringMap.get(leadIdentifier) + lsr.Points__c);
                    }
                }
            }
            
            Map<Id, LeadScoreMapping__c> scoreMap = getScoreMapping();
            
            Decimal points = 0;
            for(Lead leadRecord: newLeadMap){
                leadIdentifier = leadRecord.LastName+leadRecord.FirstName+leadRecord.Company+leadRecord.Status+leadRecord.LeadSource+leadRecord.Email+leadRecord.Phone;
                if(leadAndScoringMap.containsKey(leadIdentifier)){
                    points = leadAndScoringMap.get(leadIdentifier);
                    leadRecord.Rating = getLeadRating(points, scoreMap);
                    System.debug('========'+leadRecord.Rating+'===========');
                    leadRecord.Points__c = points;
                    leadRecord.LeadScoreAppliedDate__c = Date.today();
                }
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'setLeadScore', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
        System.debug('setLeadScore --- End');
    }
    
    private static Map<Id, LeadScoringRule__c> getLeadScoringRuleByRecordType(List<String> recordTypeIds){
        System.debug('getLeadScoringRuleByRecordType --- Start');
        return new Map<Id, LeadScoringRule__c>([SELECT Id,Name,Active__c,FieldLabel__c,Operator__c,RecordTypeId,RecordType__c,Value__c,MinimumValue__c,MaximumValue__c,Points__c FROM 
               LeadScoringRule__c WHERE RecordType__c IN :recordTypeIds AND Active__c = true AND FieldLabel__c <> '' AND
               Operator__c <> '' AND Points__c <> null]);
    }
    
    private static Boolean checkMatching(Lead leadRecord, LeadScoringRule__c lsr, Map<String, String> describedFieldsMap){
        System.debug('checkMatching --- Start');
        Boolean isMatch = false;
        
        String fieldValue = getFieldValue(leadRecord, lsr.FieldLabel__c, describedFieldsMap);
        System.debug('checkMatching --- rule value: ' + lsr.Value__c);
        
        if(lsr.Operator__c.equals('equals') && !String.isEmpty(fieldValue) && (fieldValue.equalsIgnoreCase(lsr.Value__c) || 
            (lsr.Value__c.isNumeric() && !lsr.Value__c.contains('.') && fieldValue.contains('.') && fieldValue.split('\\.').size() == 2 && 
            fieldValue.split('\\.')[0].isNumeric() && fieldValue.split('\\.')[1].isNumeric() && 
            fieldValue.split('\\.')[1] == '0' && fieldValue.split('\\.')[0] == lsr.Value__c))){
            isMatch = true;
        }
        else if(lsr.Operator__c.equals('not equals') && !String.isEmpty(fieldValue) && ((!lsr.Value__c.isNumeric() && !fieldValue.equalsIgnoreCase(lsr.Value__c)) || 
            (lsr.Value__c.isNumeric() && !fieldValue.equalsIgnoreCase(lsr.Value__c) && 
            fieldValue.contains('.') && fieldValue.split('\\.').size() == 2 && 
            fieldValue.split('\\.')[0].isNumeric() && fieldValue.split('\\.')[1].isNumeric() && 
            fieldValue.split('\\.')[1] == '0' && fieldValue.split('\\.')[0] != lsr.Value__c))){
            isMatch = true;
        }
        else if(lsr.Operator__c.equals('contains') && !String.isEmpty(fieldValue) && fieldValue.containsIgnoreCase(lsr.Value__c)){
            isMatch = true;
        }
        else if(lsr.Operator__c.equals('starts with') && !String.isEmpty(fieldValue) && fieldValue.startsWithIgnoreCase(lsr.Value__c)){
            isMatch = true;
        }
        else if(lsr.Operator__c.equals('less than/greater than') && !String.isEmpty(fieldValue) && 
                (fieldValue.isNumeric() || (fieldValue.contains('.') && fieldValue.split('\\.').size() == 2 && 
                fieldValue.split('\\.')[0].isNumeric() && fieldValue.split('\\.')[1].isNumeric())) && 
                isInRange(fieldValue, lsr)){
            isMatch = true;
        }
        else{
            isMatch = false;
        }
        
        System.debug('checkMatching --- End, Found Matched: ' + isMatch);
        
        return isMatch;
    }
    
    private static String getFieldValue(Lead leadRecord, String fieldLabel, Map<String, String> describedFieldsMap){
        System.debug('getFieldValue --- Start');
        String fieldValue = '';
        String fieldApi = '';
        
        if(describedFieldsMap.containsKey(fieldLabel)){
            fieldApi = describedFieldsMap.get(fieldLabel);
        }
        
        if(fieldLabel.equals('Lead Status') && String.isEmpty(fieldApi)){
            fieldApi = 'Status';
        }
        
        try{
            fieldValue = String.valueOf(leadRecord.get(fieldApi));
        }
        catch(Exception e){
            System.Debug('ERROR: Cannot find API for field: ' + fieldLabel);
        }
        
        System.debug('getFieldValue --- End, Field Value = ' + fieldValue);
        return fieldValue;
    }
    
    // Added 5/12/2016 --- Dee
    private static Map<String, String> getDescribeFields(){
    
        Map<String, String> describedFieldsMap = new Map<String, String>();
        
        Map<String, Schema.SObjectField> ObjectFieldMap =
            Schema.getGlobalDescribe().get('Lead').getDescribe().fields.getMap();
        
        for(String key : ObjectFieldMap.KeySet()){
            describedFieldsMap.put(ObjectFieldMap.get(key).getDescribe().getLabel(), key);
        }
        
        return describedFieldsMap;
    }
    
    private static Map<Id, LeadScoreMapping__c> getScoreMapping(){
        return new Map<Id, LeadScoreMapping__c>([SELECT Id, LeadScoreMaximumValue__c, LeadScoreMinimumValue__c, LeadRating__c FROM 
            LeadScoreMapping__c Where RuleType__c = 'Lead' AND
            LeadScoreMaximumValue__c <> null AND LeadScoreMinimumValue__c <> null AND LeadRating__c <> '']);
    }
    
    private static String getLeadRating(Decimal score, Map<Id, LeadScoreMapping__c> scoreMap){
        System.debug('getLeadRating --- Start');
        String rating = '';
        for(LeadScoreMapping__c scoreMapRecord: scoreMap.values()){
            if(scoreMapRecord.LeadScoreMaximumValue__c >= score && scoreMapRecord.LeadScoreMinimumValue__c <= score){
                rating = scoreMapRecord.LeadRating__c;
            }
        }
        
        System.debug('getLeadRating --- End, Rating = ' + rating);
        return rating;
    }
    
    public static Boolean isInRange(String fieldValue, LeadScoringRule__c lsr){
        Boolean isMatch = true;
        Decimal numValue = Decimal.valueOf(fieldValue);
        if(lsr.MinimumValue__c <> null && (Decimal)lsr.MinimumValue__c > numValue){
            isMatch = false;
        }
        
        if(lsr.MaximumValue__c <> null && (Decimal)lsr.MaximumValue__c < numValue){
            isMatch = false;
        }
        
        return isMatch;
    }
    
    /**
       *  This method is used to get the latest Lead according to its Rating, namely: Hot, Warm, Cold
       *  @name: setLeadIdRating
       *  @developer: Jerella Ledesma
       *  @param: leadToUpdateList - Map of the list of Lead in the afterUpdate transaction 
       * -------------------------------------------------
       * M.Cebrian(Accenture)   29-Apr-2016     Added latestNoRating
       * M.Cebrian(Accenture)   10-May-2016     Added logic for including status as criteria
       * S.Molloy               09-March-2017   Moving this method to WithoutSharingUtility.setLeadIdRating to avoid permission issues
    */
    public static void setLeadIdRating(Map<Id, Lead> leadToUpdateList){
        System.debug('AP04_LeadTriggerBL.setLeadIdRating --- Start');

        WithoutSharingUtility.setLeadIdRating(leadToUpdateList);

        System.debug('AP04_LeadTriggerBL.setLeadIdRating --- End');
    }

      /**
       *  This method is used to update the TotalPreviousBookings field in lead upon update
       *  @name: updateTotalPreviousBookings
       *  @developer: Erika Hidalgo
       *  @param: Lead - get Trigger.new and Trigger.old from BookingTrigger of List<Lead> data type
     */
      public static void updateTotalPreviousBookingsOnUpdate(List<Lead> newLeadList, List<Lead> oldLeadList){
          List<Error_Log__c> logs = new List<Error_Log__c>();
          
          Map<Id, Lead> listOfAcctIdsAndLeadsToUpdate = new  Map<Id, Lead>();
          Map<Id, Integer> accountIdTotalBooks = new Map<Id, Integer>();
          Map<Id, Integer> accountIdTotalOppty = new Map<Id, Integer>();
         
          try{
              for(Lead newList : newLeadList){
                  for(Lead oldList: oldLeadList){
                     if(oldList.Account__c != newList.Account__c){
                         if (null != newList.Account__c){ 
                             listOfAcctIdsAndLeadsToUpdate.put(newList.Account__c, newList);
                         }
                     }
                  }
                      
              }
              
              if(listOfAcctIdsAndLeadsToUpdate.size() > 0 ){
                  //AggregateResult[] accountTotalBooks =  [SELECT Account__c acctId, Count(id) totalBooks FROM Booking__c WHERE Lead__r.Account__c != null AND Account__c IN: listOfAcctIdsAndLeadsToUpdate.keySet() GROUP BY Account__c];
                     for(AggregateResult ar : [SELECT Account__c acctId, Count(id) totalBooks FROM Booking__c WHERE Lead__r.Account__c != null AND Account__c IN: listOfAcctIdsAndLeadsToUpdate.keySet() GROUP BY Account__c]){
                         accountIdTotalBooks.put((Id)ar.get('acctId'), (Integer)ar.get('totalBooks'));
                     }
                    
                  //AggregateResult[] accountTotalOppty =  [SELECT Account.id acctId, Count(id) totalOppty FROM Opportunity WHERE Account.id IN: listOfAcctIdsAndLeadsToUpdate.keySet() GROUP BY Account.id];
                  
                     //MC - 2017-02-24 - Error log remediation #SG-439-0. Removed parent object field reference Account.Id to allow the index on AccountId to return a selective query. 
                     //for(AggregateResult ar : [SELECT Account.id acctId, Count(id) totalOppty FROM Opportunity WHERE Account.id IN: listOfAcctIdsAndLeadsToUpdate.keySet() GROUP BY Account.id]){
                     //    accountIdTotalOppty.put((Id)ar.get('acctId'), (Integer)ar.get('totalOppty'));
                     //}
                    
                     for(AggregateResult ar : [SELECT AccountId acctId, Count(id) totalOppty FROM Opportunity WHERE AccountId IN: listOfAcctIdsAndLeadsToUpdate.keySet() GROUP BY AccountId]){
                         accountIdTotalOppty.put((Id)ar.get('acctId'), (Integer)ar.get('totalOppty'));
                     }                                              
              }
              
              for(Lead l : newLeadList){
                  if(accountIdTotalBooks.containsKey(l.Account__c)){
                      l.TotalPreviousBookings__c = accountIdTotalBooks.get(l.Account__c);
                  }
                  
                  if(accountIdTotalOppty.containsKey(l.Account__c)){
                      l.TotalPreviousOpportunities__c = accountIdTotalOppty.get(l.Account__c);
                  }
              } 
              
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'updateTotalPreviousBookingsOnUpdate()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }      
    }
    
     /**
       *  This method is used to update the TotalPreviousBookings field in lead upon insert
       *  @name: updateTotalPreviousBookings
       *  @developer: Erika Hidalgo
       *  @param: Lead - get Trigger.new from BookingTrigger of List<Lead> data type
     */
      public static void updateTotalPreviousBookingsOnInsert(List<Lead> newLeadList){
          List<Error_Log__c> logs = new List<Error_Log__c>();
      
          Map<Id, Lead> listOfAcctIdsAndLeadsToUpdate = new  Map<Id, Lead>();
          Map<Id, Integer> accountIdTotalBooks = new Map<Id, Integer>();
          Map<Id, Integer> accountIdTotalOppty = new Map<Id, Integer>();
         
          try{
              for(Lead newList : newLeadList){
                 if(newList.Account__c != null){
                         listOfAcctIdsAndLeadsToUpdate.put(newList.Account__c, newList);
                  }
              }
              
              if(listOfAcctIdsAndLeadsToUpdate.size() > 0 ){
                  AggregateResult[] accountTotalBooks =  [SELECT Account__c acctId, Count(id) totalBooks FROM Booking__c WHERE /*Lead__r.Account__c != null AND*/ Account__c IN: listOfAcctIdsAndLeadsToUpdate.keySet() GROUP BY Account__c];
                     for(AggregateResult ar : accountTotalBooks){
                         accountIdTotalBooks.put((Id)ar.get('acctId'), (Integer)ar.get('totalBooks'));
                     }
                     
                  AggregateResult[] accountTotalOppty =  [SELECT Account.id acctId, Count(id) totalOppty FROM Opportunity WHERE Account.id IN: listOfAcctIdsAndLeadsToUpdate.keySet() GROUP BY Account.id];
                     for(AggregateResult ar : accountTotalOppty){
                         accountIdTotalOppty.put((Id)ar.get('acctId'), (Integer)ar.get('totalOppty'));
                     }   
              }
              
              for(Lead l : newLeadList){
                  if(accountIdTotalBooks.containsKey(l.Account__c)){
                      l.TotalPreviousBookings__c = accountIdTotalBooks.get(l.Account__c);
                  }
                  
                  if(accountIdTotalOppty.containsKey(l.Account__c)){
                      l.TotalPreviousOpportunities__c = accountIdTotalOppty.get(l.Account__c);
                  }
              }
              
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'updateTotalPreviousBookingsOnInsert()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }   
    }
    
      /**
       *  This method checks if there are Leads with Status equal to Closed-Converted or No Sales
       *  @name: checkStatusUpdates
       *  @developer: Recuerdo Bregente
       *  @param: Lead - get Trigger.new, Trigger.oldMap
     */
     public static void checkStatusUpdates(List<Lead> leadList,  Map<Id,Lead> oldLeadMap)
     {
         System.debug('checkStatusUpdates --- Start');
         List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Set<Id> salesRep = new Set<Id>();
        
        
        try{
        
            for (Lead leadRec : oldLeadMap.values()){
                salesRep.add(leadRec.OwnerId);
            }
            System.debug('checkStatusUpdates --- salesRep: ' +salesRep);
            
            Map<Id, Sales_Agent_Attributes__c> saaMap = new Map<Id, Sales_Agent_Attributes__c>();
            Map<Id, Sales_Agent_Attributes__c> saaToUpdateMap = new Map<Id, Sales_Agent_Attributes__c>();
            
            for(Sales_Agent_Attributes__c saa : [SELECT Id, Sales_Rep__c, Current_Number_of_Open_Leads_Opps__c FROM Sales_Agent_Attributes__c WHERE 
                                                Sales_Rep__c IN :salesRep AND (RecordType.DeveloperName = :ApplicationConstant.USP_SALES_AGENT_DEVNAME OR 
                                                RecordType.DeveloperName = :ApplicationConstant.USP_SALES_MANAGER_DEVNAME)]){
                 
                   if(saa.Current_Number_of_Open_Leads_Opps__c == null){
                       saa.Current_Number_of_Open_Leads_Opps__c = 0;
                   }
                   saaMap.put(saa.Sales_Rep__c, saa);     
            }
            
            // Go through every lead in the trigger
            for (Lead leadRec : leadList){
            
                // Added due to deffect D-0587 By Dee 05/21
                if(leadRec.Status <> oldLeadMap.get(leadRec.Id).Status && (leadRec.Status == ApplicationConstant.LEAD_CLOSED_CONVERTED || 
                        leadRec.Status == ApplicationConstant.LEAD_NO_SALE || leadRec.Status == ApplicationConstant.LEAD_STATUS_DUPLICATE) &&
                        saaMap.containsKey(oldLeadMap.get(leadRec.Id).OwnerId)){
                        if(!saaToUpdateMap.containsKey(oldLeadMap.get(leadRec.Id).OwnerId)){
                            saaToUpdateMap.put(oldLeadMap.get(leadRec.Id).OwnerId, saaMap.get(oldLeadMap.get(leadRec.Id).OwnerId));
                        }
                        
                        if(saaToUpdateMap.get(oldLeadMap.get(leadRec.Id).OwnerId).Current_Number_of_Open_Leads_Opps__c > 0){
                            saaToUpdateMap.get(oldLeadMap.get(leadRec.Id).OwnerId).Current_Number_of_Open_Leads_Opps__c--;
                        }
                }
            }
            
            if(!saaToUpdateMap.isEmpty()){
                Database.SaveResult[] updatedsalesAgentList = database.update(saaToUpdateMap.values(), false);
                logs.addAll(ApplicationConstant.getSaveResultLog(updatedsalesAgentList, 'checkStatusUpdates()', CLASS_NAME, 'Sales Agent Attribute', 'Update'));
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'checkStatusUpdates()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
        System.debug('checkStatusUpdates --- End');
     }
   
     
     /**
       *  This method is used to create an event if the Call Back Date Time is updated 
       *  @name: createEvent
       *  @developer: Jerella Ledesma 04/11/2016
       *  @param: oldLeadList - get Trigger.old from LeadTrigger; of Map<Id, Lead> data type
       @param: leadList - get Trigger.new from LeadTrigger; of Map<Id, Lead> data type
       */
    public static void createUpdateEvent(Map<Id,Lead> leadList, Map<Id,Lead> oldLeadList){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Map<Id, Lead> leadListToUpdate = new Map<Id, Lead>();
        //Map<Id, Event> eventRelatedtoLead = new Map<Id, Event>();
        Set<Id> leadIds = new Set<Id>();
        Map<Id, Set<DateTime>> eventRelatedtoLead = new Map<Id, Set<DateTime>>();
        Map<Id, List<Event>> leadIdToEvents = new Map<Id, List<Event>>();
        List<Event> eventToCreate = new List<Event>();
        List<Event> eventToUpdate = new List<Event>();
        List<Event> eventList = new List<Event>();
        Event event;
        String assignmentOfOwner = '';
        Boolean isEventToUpdate = false;
        
        try{
            User apiUser = [SELECT Id FROM User WHERE Name = 'API User' LIMIT 1];
            if(leadList.size() > 0){
                for(Lead leadRec : leadList.values()){
                    leadIds.add(leadRec.Id);
                }
            }
            
            for(Event eventRec : [SELECT OwnerId, WhoId, StartDateTime, Subject FROM Event WHERE WhoId IN : leadIds AND EventIsClosed__c = false]){
                if(eventRelatedtoLead.containsKey(eventRec.WhoId)){
                    eventRelatedtoLead.get(eventRec.WhoId).add(eventRec.StartDateTime);
                }
                else{
                    eventRelatedtoLead.put(eventRec.WhoId, new Set<DateTime>{eventRec.StartDateTime});
                }
                
                if(leadIdToEvents.containsKey(eventRec.WhoId)){
                    leadIdToEvents.get(eventRec.WhoId).add(eventRec);
                }
                else{
                    leadIdToEvents.put(eventRec.WhoId, new List<Event>{eventRec});
                }
            }
            
            if(leadList.size() > 0){
                for(Lead leadRec : leadList.values()){
                    
                    if(leadRec.CallBackDateTime__c <> null && leadRec.Reminder_Event__c  && leadRec.CallBackDateTime__c > DateTime.Now() &&
                        (leadRec.CallBackDateTime__c <> oldLeadList.get(leadRec.Id).CallBackDateTime__c || leadRec.OwnerId <> oldLeadList.get(leadRec.Id).OwnerId)){  
                        
                        if(String.valueOf(leadRec.OwnerId).startswith('00G')){
                            assignmentOfOwner = apiUser.Id;
                        }
                        else{
                            assignmentOfOwner = leadRec.OwnerId;
                        }
                        event = new Event(
                        OwnerId = assignmentOfOwner,
                        StartDateTime = leadRec.CallBackDateTime__c,
                        EndDateTime = leadRec.CallBackDateTime__c,
                        ReminderDateTime = (leadRec.CallBackDateTime__c).addMinutes(-15),
                        IsReminderSet = true,
                        ActivityDateTime = leadRec.CallBackDateTime__c,
                        Subject = 'Call Back Request',
                        WhoId = leadRec.Id
                        );
                        if(eventRelatedtoLead.containsKey(leadRec.Id)){
                            if(!eventRelatedtoLead.get(leadRec.Id).contains(leadRec.CallBackDateTime__c)){
                                eventToCreate.add(event);
                            }
                        }
                        else{
                            eventToCreate.add(event);
                        }
                        
                        eventList = new List<Event>();
                        //if((!String.valueOf(leadRec.OwnerId).startswith('00G') && leadIdToEvents.containsKey(leadRec.Id)) || ){
                        if(leadIdToEvents.containsKey(leadRec.Id)){
                            eventList = leadIdToEvents.get(leadRec.Id);
                            for(Event ev : eventList){
                                isEventToUpdate = false;
                                if(!String.valueOf(leadRec.OwnerId).startswith('00G') && ev.OwnerId <> leadRec.OwnerId && ev.OwnerId == apiUser.Id && ev.StartDateTime > DateTime.Now()){
                                    ev.OwnerId = leadRec.OwnerId;
                                    //eventToUpdate.add(ev);
                                    isEventToUpdate=true;
                                }
                                
                                if(ev.Subject == 'Call Back Request' && leadRec.CallBackDateTime__c<> oldLeadList.get(leadRec.Id).CallBackDateTime__c && ev.StartDateTime < leadRec.CallBackDateTime__c) {
                                    ev.IsInvalidCallBack__c = true;
                                    ev.StartDateTime = DateTime.Now();
                                    ev.EndDateTime = DateTime.Now();
                                    ev.IsReminderSet = false;
                                    isEventToUpdate=true;
                                }

                                if(isEventToUpdate) {
                                    eventToUpdate.add(ev);
                                }
                            }                        
                        }                    
                    } else if (leadRec.CallBackDateTime__c == null && leadRec.CallBackDateTime__c <> oldLeadList.get(leadRec.Id).CallBackDateTime__c) {
                        
                        eventList = new List<Event>();
                        if(leadIdToEvents.containsKey(leadRec.Id)) {
                        
                            eventList = leadIdToEvents.get(leadRec.Id);
                            for(Event e: eventList) {
                                if(e.Subject == 'Call Back Request') {
                                    e.IsInvalidCallBack__c = true;
                                    e.StartDateTime = DateTime.Now();
                                    e.EndDateTime = DateTime.Now();
                                    e.IsReminderSet = false;
                                    eventToUpdate.add(e);
                                }
                            }
                        }
                    }
                }
            }
        }catch(Exception e){
            //logs.add(ApplicationConstant.getExceptionLog(e, 'createUpdateEvent()', CLASS_NAME, null)); //3.12
            PlatformLogManager.logExceptions(e, 'AP04_LeadTriggerBL', 'createUpdateEvent'); //3.12
        }finally{
            //if(logs.isEmpty()){
                if(eventToCreate.size() > 0){
                    Database.SaveResult[] updateLeadList = Database.insert(eventToCreate, false);
                    //logs.addAll(ApplicationConstant.getSaveResultLog(updateLeadList, 'createUpdateEvent()', CLASS_NAME, ApplicationConstant.LEAD_SOURCE_EVENT, 'Insert')); //3.12
                    PlatformLogManager.logExceptions(updateLeadList, 'AP04_LeadTriggerBL', 'createUpdateEvent', null); //3.12
                }
                
                if(eventToUpdate.size() > 0){
                    Database.SaveResult[] updateLeadList = Database.update(eventToUpdate, false);
                    //logs.addAll(ApplicationConstant.getSaveResultLog(updateLeadList, 'createUpdateEvent()', CLASS_NAME, ApplicationConstant.LEAD_SOURCE_EVENT, 'Update')); //3.12
                    PlatformLogManager.logExceptions(updateLeadList, 'AP04_LeadTriggerBL', 'createUpdateEvent', eventToUpdate); //3.12
                }
            //}
        
            /*if(!logs.isEmpty()){
                Database.insert(logs, false);
            }*/
        }
    }
    

    /**
       *  This method is used to update the default values for Lead record  
       *  @name: populateAccountPhone
       *  @developer: Simon Molloy 03/08/2017
       *  @param: Lead leaRecord
       *          Account accountRecord
       */

    public static boolean populateAccountPhone(Lead leadRecord, Account accountRecord){
        boolean isUpdated = FALSE;
        if (null != leadRecord.Phone && (accountRecord.Phone != leadRecord.Phone)){
            accountRecord.Phone = leadRecord.Phone;
            isUpdated = TRUE;
        }
        if (null != leadRecord.MobilePhone && (accountRecord.PersonMobilephone != leadRecord.MobilePhone)){
            accountRecord.PersonMobilePhone = leadRecord.MobilePhone;
            isUpdated = TRUE;
        }
        if (null != leadRecord.HomePhone__c && (accountRecord.PersonHomePhone != leadRecord.HomePhone__c)){
            accountRecord.PersonHomePhone = leadRecord.HomePhone__c;
            isUpdated = TRUE;
        }

        return isUpdated;
        
    } 

    /**
       *  This method is used to copy account fields to lead
       *  @name: populateAccountDetailsOnLead
       *  @developer: Jerome To
       *  @param: Lead - get Trigger.new List<Lead> data type
       *  @updated by: Tristan Zantua
       *  @date: 5/14/2016
       *  @requirement: D-0533
       *  @description: copy account fields based on account lookup field value
       *  @Modification: Simon Molloy : 16/02/2017 : Include Gender field population from Account to Lead
     */
    
    public static void populateAccountDetailsOnLead(List<Lead> newLeadList, Map<Id,Lead> oldLeadMap){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Map<id,String> leadIdAndEmail= new Map<id,String>();
        Map<id, Account> leadAccountMap = new Map<id, Account>();
        Set<String> personEmailSet = new Set<String>();
        Set<Id> personAccountSet = new Set<Id>();
        Map<String, Account> personEmailAccountMap = new Map<String, Account>();
        Map<Id, Account> personAccountMap = new Map<Id, Account>();
        Map<String, Account> accountsByEmailToSave = new Map<String, Account>();
        Map<Id, Account> accountsByIdToSave = new Map<Id, Account>();
        
        try{
            for(Lead leadRec : newLeadList){
                if(oldLeadMap != null){
                    if(leadRec.Email != null && oldLeadMap.get(leadRec.Id).Email != leadRec.Email){
                        personEmailSet.add(leadRec.Email);
                    } if (leadRec.Account__c != null && leadRec.Email == null && oldLeadMap.get(leadRec.Id).Account__c != leadRec.Account__c) {
                        personAccountSet.add(leadRec.Account__c);
                    } 
                }else{
                    if(leadRec.Email != null){
                        personEmailSet.add(leadRec.Email);
                    } if (leadRec.Account__c != null && leadRec.Email == null) {
                        personAccountSet.add(leadRec.Account__c);
                    } 
                }
            }
            
            if(!personEmailSet.isEmpty() || !personAccountSet.isEmpty()){
                for(Account acct : [SELECT Id, PersonEmail, BillingCity, BillingPostalCode, BillingCountry, BillingState, BillingStreet, PersonMobilePhone, Salutation, FirstName, LastName, PersonHomePhone, Phone, BestTimeToCall__c, DoNotsendviaEmail__c, DoNotsendviaPost__c,
                                       DoNotsendviaSMS__c, Is_PGA__pc, Bond_Holder__pc, BreakpointsAmountAvailable__c, BreakpointsAmountPending__c, NewsletterSignUp__c, CustomerLifetimeValue__c, Value__c, PersonDoNotCall, PersonHasOptedOutOfEmail, 
                                       Gender__c FROM Account WHERE (PersonEmail IN:personEmailSet OR Id IN:personAccountSet) AND IsPersonAccount = true]){
                //for(Account acct : [SELECT Id, PersonEmail, BillingCity, BillingPostalCode, BillingCountry, BillingState, BillingStreet, PersonMobilePhone, Salutation, FirstName, LastName, PersonHomePhone, Phone, BestTimeToCall__c, DoNotsendviaEmail__c, DoNotsendviaPost__c,
                                       //DoNotsendviaSMS__c, BreakpointsAmountAvailable__c, BreakpointsAmountPending__c, NewsletterSignUp__c, CustomerLifetimeValue__c, Value__c, PersonDoNotCall, PersonHasOptedOutOfEmail FROM Account WHERE (PersonEmail IN:personEmailSet OR Id IN:personAccountSet) AND IsPersonAccount = true]){
                    if(!personEmailAccountMap.containsKey(acct.PersonEmail)){
                        personEmailAccountMap.put(acct.PersonEmail, acct);
                    } if(!personAccountMap.containsKey(acct.Id)){
                        personAccountMap.put(acct.Id, acct);
                    }
                }
            }
            
            if(!personEmailAccountMap.isEmpty() || !personAccountMap.isEmpty()){        
                for(Lead leadRecord : newLeadList){ 
                    if(leadRecord.Email != null && personEmailAccountMap.containsKey(leadRecord.Email)){    
                        Account acct = personEmailAccountMap.get(leadRecord.Email);
                        leadRecord.City = acct.BillingCity;
                        leadRecord.PostalCode = acct.BillingPostalCode;
                        leadRecord.Country = acct.BillingCountry;
                        leadRecord.State = acct.BillingState;
                        leadRecord.Street = acct.BillingStreet;
                        leadRecord.Salutation = acct.Salutation;
                        leadRecord.FirstName = acct.FirstName;
                        leadRecord.LastName =  acct.LastName;
                        leadRecord.Account__c =  acct.id;
                        leadRecord.DonotsendviaEmail__c =  acct.DoNotsendviaEmail__c;
                        leadRecord.DoNotsendviaPost__c =  acct.DoNotsendviaPost__c;
                        leadRecord.DoNotsendviaSMS__c =  acct.DoNotsendviaSMS__c;
                        leadRecord.PGA__c =  acct.Is_PGA__pc;
                        //2017-08-03 : SM : NEW Phone Logic
                        /*
                        leadRecord.Phone = acct.Phone;
                        leadRecord.MobilePhone = acct.PersonMobilePhone;
                        leadRecord.HomePhone__c =  acct.PersonHomePhone;
                        */
                        if (populateAccountPhone(leadRecord, acct)){
                            if (!accountsByEmailToSave.containsKey(leadRecord.Email)){
                                accountsByEmailToSave.put(leadRecord.Email, acct);    
                            }
                        }
                        //3.8 
                        /*if (!'Web Callback'.equalsIgnoreCase(leadRecord.LeadSource)){
                            leadRecord.BestTimetoCall__c = acct.BestTimeToCall__c;
                        }*/
                        if(leadRecord.BestTimetoCall__c == null && acct.BestTimeToCall__c != null){
                            leadRecord.BestTimetoCall__c = acct.BestTimeToCall__c; 
                        }
                        
                        leadRecord.BreakpointsAmountAvailable__c = acct.BreakpointsAmountAvailable__c;
                        leadRecord.BreakpointsAmountPending__c = acct.BreakpointsAmountPending__c;
                        String customerLifeTimeValue = String.valueOf(acct.CustomerLifetimeValue__c);
                        leadRecord.CustomerLifetimeValue__c =  Decimal.valueOf(!String.isEmpty(customerLifeTimeValue)? customerLifeTimeValue : '0');
                        leadRecord.ClientValue__c = acct.Value__c;
                        leadRecord.DoNotCall = acct.PersonDoNotCall;
                        leadRecord.HasOptedOutOfEmail = acct.PersonHasOptedOutOfEmail;
                        leadRecord.Gender__c = acct.Gender__c;
                        
                    } if(leadRecord.Account__c != null && leadRecord.Email == null && personAccountMap.containsKey(leadRecord.Account__c)){    
                        Account acct = personAccountMap.get(leadRecord.Account__c);
                        leadRecord.Email = acct.PersonEmail;
                        leadRecord.City = acct.BillingCity;
                        leadRecord.PostalCode = acct.BillingPostalCode;
                        leadRecord.Country = acct.BillingCountry;
                        leadRecord.State = acct.BillingState;
                        leadRecord.Street = acct.BillingStreet;
                        leadRecord.Salutation = acct.Salutation;
                        leadRecord.FirstName = acct.FirstName;
                        leadRecord.LastName =  acct.LastName;
                        leadRecord.DonotsendviaEmail__c =  acct.DoNotsendviaEmail__c;
                        leadRecord.DoNotsendviaPost__c =  acct.DoNotsendviaPost__c;
                        leadRecord.DoNotsendviaSMS__c =  acct.DoNotsendviaSMS__c;
                        leadRecord.PGA__c =  acct.Is_PGA__pc;
                        //2017-08-03 : SM : NEW Phone Logic
                        /*
                        leadRecord.Phone = acct.Phone;
                        leadRecord.MobilePhone = acct.PersonMobilePhone;
                        leadRecord.HomePhone__c =  acct.PersonHomePhone;
                        */
                        if (populateAccountPhone(leadRecord, acct)){
                            if (!accountsByIdToSave.containsKey(leadRecord.Account__c)){
                                accountsByIdToSave.put(leadRecord.Account__c, acct);
                            }
                        }
                        //3.8 
                        /*if (!'Web Callback'.equalsIgnoreCase(leadRecord.LeadSource)){
                            leadRecord.BestTimetoCall__c = acct.BestTimeToCall__c;
                        }*/
                        if(leadRecord.BestTimetoCall__c == null && acct.BestTimeToCall__c != null){
                            leadRecord.BestTimetoCall__c = acct.BestTimeToCall__c; 
                        }
                        
                        leadRecord.BreakpointsAmountAvailable__c = acct.BreakpointsAmountAvailable__c;
                        leadRecord.BreakpointsAmountPending__c = acct.BreakpointsAmountPending__c;
                        String customerLifeTimeValue = String.valueOf(acct.CustomerLifetimeValue__c);
                        leadRecord.CustomerLifetimeValue__c =  Decimal.valueOf(!String.isEmpty(customerLifeTimeValue)? customerLifeTimeValue : '0');
                        leadRecord.ClientValue__c = acct.Value__c;
                        leadRecord.DoNotCall = acct.PersonDoNotCall;
                        leadRecord.HasOptedOutOfEmail = acct.PersonHasOptedOutOfEmail;
                        leadRecord.Gender__c = acct.Gender__c;
                        
                    } 
                }  
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'populateAccountDetailsOnLead()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        } 

        List<Account> accountsToUpdate = new List<Account>();
        accountsToUpdate.addAll(accountsByIdToSave.values());
        accountsToUpdate.addAll(accountsByEmailToSave.values());

        try {
            if (!accountsToUpdate.isEmpty()){
                update accountsToUpdate;
            }
        }catch (Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'populateAccountDetailsOnLead() - updateAccounts', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }
    
    /**
       *  This method is used to update the default values for Lead record  
       *  @name: populateCaseDetails
       *  @developer: Patrick Villarica (ACN) - May 26, 2016
       *  @param: List<Lead> newCaseList from Trigger.New
       *          Map<Id, Lead> oldCaseMap from Trigger.OldMap
       *  @Modification: Simon Molloy : 16/02/2017 : Call to 'populateGenderLead' to make sure Gender field is populated
       */
     public static void populateLeadDetails(List<Lead> newLeadList, Map<Id, Lead> oldLeadMap) {
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        //3.4 - Retrieve lowest level 'Phased Code Removal' settings
        Phased_Code_Removal__c pcr = Phased_Code_Removal__c.getInstance(); 
         
        try{
            for(Lead lead: newLeadList) {
                    
                if(oldLeadMap.ContainsKey(lead.Id)) {
                    
                    if(lead.TECH_NVMCallBackUrgent__c != oldLeadMap.get(lead.Id).TECH_NVMCallBackUrgent__c) {
        
                        lead.Reminder_Event__c = false;
                    } else {
                        if(lead.CallBackDateTime__c <> null && lead.CallBackDateTime__c <> oldLeadMap.get(lead.Id).CallBackDateTime__c) {
                        
                            lead.Reminder_Event__c = true;
                        }
                    }
                }
            }
            
            //3.4 - Check the 'Disable Gender Calculation' before executing
            if(pcr != null && !pcr.Disable_Gender_Calculation__c){            
                //2017-07-25 : SM : Call out to populateGenderLead
                populateGenderLead(newLeadList);
            }

        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'populateLeadDetails()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }     
    }

    //2017-07-25 : SM : private method to set Gender on Lead based on following rules:
    //2017-07-25 : SM : Ms / Miss / Mrs = FEMALE
    //2017-07-25 : SM : All other = MALE
    public static void populateGenderLead(List<Lead> leads){
        if (null != leads){
            for (Lead l : leads){
                if (null != l.Salutation){
                    if ('Ms.'.equalsIgnoreCase(l.Salutation) || 
                        'Mrs.'.equalsIgnoreCase(l.Salutation) ||
                        'Miss.'.equalsIgnoreCase(l.Salutation)){
                        l.Gender__c = GENDER_FEMALE;
                    }else {
                        l.Gender__c = GENDER_MALE;
                    }
                    continue;
                }

                if (null == l.Salutation && null != l.Title){
                    if ('Ms.'.equalsIgnoreCase(l.Title) || 
                        'Mrs.'.equalsIgnoreCase(l.Title) ||
                        'Miss.'.equalsIgnoreCase(l.Title)){
                        l.Gender__c = GENDER_FEMALE;
                    }else {
                        l.Gender__c = GENDER_MALE;
                    }
                    continue;
                }else {
                    l.Gender__c = GENDER_MALE;
                }
            }
        }
    }
    
    public static void changeLeadSource(List<Lead> newLeadList){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        try{
            for(Lead lead: newLeadList) {
                if(lead.LeadSource == 'Twitter' || lead.LeadSource == 'Facebook' || lead.LeadSource == 'LinkedIn' || lead.LeadSource == 'Youtube' || lead.LeadSource == 'Instagram' || lead.LeadSource == 'Pinterest' || lead.LeadSource == 'Google+'){
                    lead.LeadSource = 'Social';
                }else if(lead.LeadSource == 'Other'){    
                    lead.LeadSource = 'Social - Other';   
                }    
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'changeLeadSource()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }     
    }

    //D-1313
    public static void catchDupeLeads(List<Lead> newLeadList){
        List<Error_Log__c> logs = new List<Error_Log__c>(); 
        List<String> LeadEmails = new List<String>(); //get insert lead emails
        //List<Lead<
        List<Lead> ldList = new List<Lead>();        
    
        if(newLeadList == null) {
            newLeadList = new List<Lead> ();
        }
        
        if(!newLeadList.IsEmpty()) {
            for(Lead leaditr : newLeadList){
                if(!String.IsBlank(leaditr.LeadSource) && leaditr.LeadSource.equals(ApplicationConstant.LEAD_SOURCE_WEBSITEFORM) ){
                    LeadEmails.add(leaditr.Email);
                    ldList.add(leaditr);
                }
            }
        }
    
        List<Lead> getWebFormLeads = [SELECT Id, Email, LeadSource, CreatedDate, Status, DuplicateNotaLeadReason__c, SalesRegion__c FROM LEAD WHERE CreatedDate >=: System.Now().addDays(-1) AND LeadSource =: ApplicationConstant.LEAD_SOURCE_WEBSITEFORM AND EMAIL IN: LeadEmails AND EMAIL!=NULL LIMIT 50000];        
        if(!getWebFormLeads.isEmpty()){
            try{
                for(Lead ld : ldList){
                    for(Lead lx : getWebFormLeads){
                        if(!String.IsBlank(ld.Email)  && ld.Email.equals(lx.Email) 
                           && (lx.Status.equals(ApplicationConstant.LEAD_STATUS_NEW) || lx.Status.equals(ApplicationConstant.LEAD_STATUS_CONTACT_ATTEMPTED) )
                           && (!String.IsBlank(ld.SalesRegion__c) && ld.SalesRegion__c.equals(lx.SalesRegion__c))
                          ){
                            ld.Status = ApplicationConstant.LEAD_STATUS_DUPLICATE;
                            ld.DuplicateNotaLeadReason__c = ApplicationConstant.LEAD_DUPLICATE_REASON;
                        }
                    } 
                } 
            }catch(Exception e){
                logs.add(ApplicationConstant.getExceptionLog(e, 'catchDupeLeads()', CLASS_NAME, null));
            }finally{
                if(!logs.isEmpty()){
                    Database.insert(logs, false);
                }
            }
        }
        
    }//End catchDupeLeads() method
}