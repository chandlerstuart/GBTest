/*
Version   Author        Date           Description
2.1       J Radcliffe   2019-05-30     Amendment to 'populateAccountandOppbyBookingId' - set Territory__c from parent Booking
2.2       J Radcliffe   2019-06-07     Amendment to 'populateAccountandOppbyBookingId' - Do not override set Client on insert
2.3       J Radcliffe   2019-06-13     Comment out redundant methods
*/


/**
   @Author: Nicole De Guzman/Renz Melecotones
   @name: AP02_CaseTriggerBL
   @CreateDate: 04.04.2016
   @Description: Business Logic Class for AP01_CaseTriggerHandler
   @Version <1.0>
 */ 
public with sharing class AP02_CaseTriggerBL{        

    /**
       *  This contains case record types
       *  @developer: Jerome To
       *  @history: 05/25/2016 - created
    **/
    static final Map<String, Id> caseRecordTypes;
    static{
        caseRecordTypes = new Map<String, Id>();
        for(RecordType recType : [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Case']){
            caseRecordTypes.put(recType.DeveloperName, recType.Id);
        }
    }

    public static final String CLASS_NAME = 'AP02_CaseTriggerBL';

            /**
       *  This method is used to update the Case Account,Opportunity based on the Case Booking   
       *  @name: populateAccountandOppbyBookingId
       *  @developer: Patrick Villarica (ACN) - May 19, 2016
       *  @param: List<Case> newCaseList from Trigger.New
       *          Map<Id, Case> oldCaseMap from Trigger.OldMap
       */
    public static void populateAccountandOppbyBookingId(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        
        Set<Id> serviceRecordTypes = new Set<Id>{ApplicationConstant.CASERECTYPEID_ADMIN, ApplicationConstant.CASERECTYPEID_AMENDMENT, ApplicationConstant.CASERECTYPEID_COMPLAINT, ApplicationConstant.CASERECTYPEID_SERVICECASE};
        Set<Id> bookingIds = new Set<Id>();
        Map<Id, Booking__c> bookingMap = new Map<Id, Booking__c> ();
        
        for(Case c: newCaseList) {
            if(serviceRecordTypes.contains(c.RecordTypeId) && c.Booking__c <> null && c.Status <> ApplicationConstant.CASE_STATUS_CLOSED) {
                
                if(oldCaseMap == null) {
                    
                    bookingIds.add(c.Booking__c);
                } else {
                    
                    if(oldCaseMap.containsKey(c.Id)) {
                        
                        if(c.Booking__c <> oldCaseMap.get(c.Id).Booking__c) {

                            bookingIds.add(c.Booking__c);
                        }
                    }
                }
            }
        }
        
        if(bookingIds.size() > 0) {
            bookingMap = new Map<Id, Booking__c> ([Select Id, Account__c, Account__r.PersonContactId, Tech_Opportunity__c, Territory__c from Booking__c WHERE Id IN: bookingIds]);
        }
        
        if(bookingMap.size() > 0) {
            for(Case c: newCaseList) {
                
                if(serviceRecordTypes.contains(c.RecordTypeId) && c.Booking__c <> null && c.Status <> ApplicationConstant.CASE_STATUS_CLOSED) {
                    
                    if(bookingMap.containsKey(c.Booking__c)) {
                        if(trigger.isInsert){//2.2
                            //Do not overwrite eixsting Account value (with Lead Booker) on insert
                            if(c.AccountId == null) c.AccountId = bookingMap.get(c.Booking__c).Account__c;
                        }else{
                            c.AccountId = bookingMap.get(c.Booking__c).Account__c;
                        }
                        c.Opportunity__c = bookingMap.get(c.Booking__c).Tech_Opportunity__c;
                        c.Territory__c = bookingMap.get(c.Booking__c).Territory__c;//2.1
                        
                        if(c.AccountId <> null && bookingMap.get(c.Booking__c).Account__r.PersonContactId <> null) {
                            
                            c.ContactId = bookingMap.get(c.Booking__c).Account__r.PersonContactId;
                        }
                    }
                }
            }
        }
    }

    /**
       *  This method is used to assign an entitlement for newly created cases
       *  @name: setEntitlementOnCase
       *  @developer: Renz Melecotones 09/03/2016
       *  @param: caseList - get Trigger.new from CaseTrigger; of List<Case> data type
       *  @history: 05/15/2016 - [RRMJ] Added Start Date and End Date on the SOQL
       *          : 05/23/2016 - [RRMJ] Removed the Filtering on SOQL for Entitlement Start Date and End Date.
    **/
    /* 2.3
    public static void setEntitlementOnCase(List<Case> caseList) {
        List<Error_Log__c> logs = new List<Error_Log__c>();
        List<Entitlement> entList = new List<Entitlement>();
        Map<String, Entitlement> entMap = new Map<String, Entitlement>();
        
        try{
            Map<Id, RecordType> recordTypeMap = new Map<Id, RecordType>([SELECT Id, DeveloperName, Name FROM RecordType WHERE sObjectType =: ApplicationConstant.CASE_SOBJECTTYPE]);
            
            entList = [SELECT Id, Name FROM Entitlement WHERE Status =: ApplicationConstant.ENT_ACTIVE_STATUS];
                
            if(entList.size() > 0){
                for(Entitlement entRec : entList){
                    entMap.put(entRec.Name, entRec);
                }    
            }
            
            if(caseList.size() > 0){    
                for(Case caseRec: caseList){        
                    if(caseRec.RecordTypeId != null){
                        if(entMap.size() > 0){
                            if(entMap.containsKey(recordTypeMap.get(caseRec.RecordTypeId).Name)){   
                                caseRec.EntitlementId = entMap.get(recordTypeMap.get(caseRec.RecordTypeId).Name).Id;                
                            }
                        }                    
                    }           
                }
            } 
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'setEntitlementOnCase', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }    
    }*/

        /**
       *  This method is used to update the Completion date of the CaseMileStone   
       *  @name: updateCaseMileStone
       *  @developer: Jerome To (ACN) - May 8, 2016
       *  @param: Map<Id, Case> 
       */
    
    /* 2.3
    public static void updateCaseMileStone(Map<Id, Case> newCaseMap){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        List<CaseMileStone> caseMileStoneList = new List<CaseMileStone>();
        List<String> mileStoneTypeFilter = new List<String> {ApplicationConstant.MILESTONE_RESOLUTION_TIME, 
                                                             ApplicationConstant.MILESTONE_ABTA_RESOLUTION, 
                                                             ApplicationConstant.MILESTONE_RESPONSE_TIME};

        Set<String> mileStoneTypeFilterOnComplaint = new Set<String> {ApplicationConstant.MILESTONE_RESOLUTION_TIME, 
                                                             ApplicationConstant.MILESTONE_ABTA_RESOLUTION};
 
        Map<String, String> mapCaseAndErrors = new Map<String, String>();

        Set<Id> amendmentAndServiceCaseIds = new Set<Id>{caseRecordTypes.get(ApplicationConstant.CASE_RECORD_TYPE_AMENDMENT), caseRecordTypes.get(ApplicationConstant.CASE_RECORD_TYPE_SERVICE_CASE) };
        Set<String> amendmentAndServiceCaseStatus = new Set<String>{ApplicationConstant.CASE_STATUS_INPROGRESS, ApplicationConstant.CASE_STATUS_NEW};

        try{
            Map<Id, MileStoneType> mileStoneTypeMap = new Map<Id, MileStoneType>([SELECT Name, ID FROM MileStoneType WHERE Name in: mileStoneTypeFilter]);
            for(CaseMileStone cMileStone : [SELECT  CaseId, MilestoneTypeId, CompletionDate  FROM CaseMileStone WHERE CaseId IN: newCaseMap.keySet()]) {                
                if((newCaseMap.get(cMileStone.CaseId).RecordTypeId == caseRecordTypes.get(ApplicationConstant.CASE_RECORD_TYPE_COMPLAINT)) &&
                   (newCaseMap.get(cMileStone.CaseId).Status == ApplicationConstant.CASE_STATUS_CLOSED) &&
                   mileStoneTypeMap.containsKey(cMileStone.MilestoneTypeId) &&
                   mileStoneTypeFilterOnComplaint.contains(mileStoneTypeMap.get(cMileStone.MilestoneTypeId).Name)) {
                        cMileStone.CompletionDate = System.now();
                        caseMileStoneList.add(cMileStone);

                } else if(amendmentAndServiceCaseIds.contains(newCaseMap.get(cMileStone.CaseId).RecordTypeId) && 
                           !amendmentAndServiceCaseStatus.contains(newCaseMap.get(cMileStone.CaseId).Status) &&
                           mileStoneTypeMap.containsKey(cMileStone.MilestoneTypeId) &&
                           mileStoneTypeMap.get(cMileStone.MilestoneTypeId).Name == ApplicationConstant.MILESTONE_RESPONSE_TIME) {                    
                        cMileStone.CompletionDate = System.now();
                        caseMileStoneList.add(cMileStone);
                } else if(cMileStone.CompletionDate == null){
                    cMileStone.CompletionDate = null;
                    caseMileStoneList.add(cMileStone);                    
                }            
            }
            
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'updateCaseMileStone', CLASS_NAME, null));
        }finally{
            if(logs.isEmpty() && caseMileStoneList.size() > 0){
                Database.SaveResult[] updateCaseMilestoneList = Database.update(caseMileStoneList, false);
                logs.addAll(ApplicationConstant.getSaveResultLog(updateCaseMilestoneList, 'updateCaseMileStone', CLASS_NAME, 'CaseMileStone', 'Update'));
            }
        
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }*/
    
    /**
       *  This method is used to update the default values for Case record  
       *  @name: populateCaseDetails
       *  @developer: Patrick Villarica (ACN) - May 26, 2016
       *  @param: List<Case> newCaseList from Trigger.New
       *          Map<Id, Case> oldCaseMap from Trigger.OldMap
       */
    /* 2.3
    public static void populateCaseDetails(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
    
        for(Case c: newCaseList) {
                
            if(oldCaseMap.ContainsKey(c.Id)) {
                
                if(c.TECH_NVMCallBackUrgent__c != oldCaseMap.get(c.Id).TECH_NVMCallBackUrgent__c) {
    
                    c.Reminder_Event__c = false;
                } else {
                    if(c.RequestedCallBackDateAndTime__c <> null && c.RequestedCallBackDateAndTime__c <> oldCaseMap.get(c.Id).RequestedCallBackDateAndTime__c) {
                        
                        c.Reminder_Event__c = true;
                    }
                }
            }
        }    
    }*/

        /**
       *  This method is used to set the Assignment Rules against a case
       *  It has to be run on AfterInsert
       *  @name: setAssingmentRuleOnCase
       *  @developer: Simon Molloy 08/12/2016
       *  @param: caseList - get Trigger.new from CaseTrigger; of List<Case> data type
       *  @history: 08/12/2016 - [SM] Initial Development
    **/

    /* 2.3
    public static void setAssingmentRuleOnCase(List<Case> caseList) {
        Set<Id> caseIdSet = new Set<Id>();
        for (Case c : caseList){
            if(c.subject != null && !c.subject.containsIgnoreCase('GhostCase')){
                caseIdSet.add(c.Id);
            }
        }
        List<Case> cList = [select Id from Case where Id in :caseIdSet];
        AssignmentRule AR;
        Database.DMLOptions dmlOpts;
        
        AR = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
        dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;
        
        for (Case c : cList){
            c.setOptions(dmlOpts);
        }    

        Database.update(cList);
    }
    */
          
    /**
       *  This method is used to create an event if the Call Back Date Time is updated 
       *  @name: createEvent
       *  @developer: Jerella Ledesma 04/11/2016
       *  @param: oldCaseList - get Trigger.old from CaseTrigger; of Map<Id, Case> data type
       * @param: caseList - get Trigger.new from CaseTrigger; of Map<Id, Case> data type
    */
    
    /* 2.3
    public static void createUpdateEvent(Map<Id,Case> caseList, Map<Id,Case> oldCaseList){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Map<Id, Case> caseListToUpdate = new Map<Id, Case>();
        //Map<Id, Event> eventRelatedtoCase = new Map<Id, Event>();
        Set<Id> caseIds = new Set<Id>();
        Map<Id, Set<DateTime>> eventRelatedtoCase = new Map<Id, Set<DateTime>>();
        Map<Id, List<Event>> caseIdToEvents = new Map<Id, List<Event>>();
        List<Event> eventToCreate = new List<Event>();
        List<Event> eventToUpdate = new List<Event>();
        List<Event> eventList = new List<Event>();
        Event event;
        String assignmentOfOwner = '';
        Boolean isEventToUpdate = false;
        
        try{
            User apiUser = [SELECT Id FROM User WHERE Name =: ApplicationConstant.USER_NAME_API_USER LIMIT 1];
            
            if(caseList.size() > 0){
                for(Case caseRec : caseList.values()){
                    caseIds.add(caseRec.Id);
                }
            }
            
            for(Event eventRec : [SELECT OwnerId, WhatId, StartDateTime, Subject FROM Event WHERE WhatId IN : caseIds AND EventIsClosed__c = false]){
                if(eventRelatedtoCase.containsKey(eventRec.WhatId)){
                    eventRelatedtoCase.get(eventRec.WhatId).add(eventRec.StartDateTime);
                }
                else{
                    eventRelatedtoCase.put(eventRec.WhatId, new Set<DateTime>{eventRec.StartDateTime});
                }
                
                if(caseIdToEvents.containsKey(eventRec.WhatId)){
                    caseIdToEvents.get(eventRec.WhatId).add(eventRec);
                }
                else{
                    caseIdToEvents.put(eventRec.WhatId, new List<Event>{eventRec});
                }
            }
            
            if(caseList.size() > 0){
                for(Case caseRec : caseList.values()){
                
                    if(caseRec.RequestedCallBackDateAndTime__c <> null && caseRec.Reminder_Event__c && caseRec.RequestedCallBackDateAndTime__c > DateTime.Now() && 
                        (caseRec.RequestedCallBackDateAndTime__c <> oldCaseList.get(caseRec.Id).RequestedCallBackDateAndTime__c || caseRec.OwnerId <> oldCaseList.get(caseRec.Id).OwnerId)){  
                        
                        if(String.valueOf(caseRec.OwnerId).startswith('00G')){
                            assignmentOfOwner = apiUser.Id;
                        }
                        else{
                            assignmentOfOwner = caseRec.OwnerId;
                        }
                        event = new Event(
                        OwnerId = assignmentOfOwner,
                        StartDateTime = caseRec.RequestedCallBackDateAndTime__c,
                        EndDateTime = caseRec.RequestedCallBackDateAndTime__c,
                        ReminderDateTime = (caseRec.RequestedCallBackDateAndTime__c).addMinutes(-15),
                        IsReminderSet = true,
                        ActivityDateTime = caseRec.RequestedCallBackDateAndTime__c,
                        Subject = 'Call Back Request',
                        WhatId = caseRec.Id
                        );
                        if(eventRelatedtoCase.containsKey(caseRec.Id)){
                            if(!eventRelatedtoCase.get(caseRec.Id).contains(caseRec.RequestedCallBackDateAndTime__c)){
                                eventToCreate.add(event);
                            }
                        }
                        else{
                            eventToCreate.add(event);
                        }
                        
                        //eventList = new List<Event>();
                        //if(!String.valueOf(caseRec.OwnerId).startswith('00G')){
                            if(caseIdToEvents.containsKey(caseRec.Id)){
                                eventList = caseIdToEvents.get(caseRec.Id);
                                for(Event ev : eventList){
                                    isEventToUpdate = false;
                                    if(!String.valueOf(caseRec.OwnerId).startswith('00G') && ev.OwnerId <> caseRec.OwnerId && ev.OwnerId == apiUser.Id && ev.StartDateTime > DateTime.Now()){
                                        ev.OwnerId = caseRec.OwnerId;
                                        //eventToUpdate.add(ev);
                                        isEventToUpdate = true;
                                    }
                                    
                                    system.debug('*** -- Subject ' + ev.Subject + ' -- ***');
                                    system.debug('*** -- caseRec Req ' + caseRec.RequestedCallBackDateAndTime__c + ' -- ***');
                                    system.debug('*** -- OldCaseRec req ' + oldCaseList.get(caseRec.Id).RequestedCallBackDateAndTime__c + ' -- ***');
                                    system.debug('*** -- Event start date time ' + ev.StartDateTime + ' -- ***');
                                    system.debug('*** -- Caserec req again ' + caseRec.RequestedCallBackDateAndTime__c + ' -- ***');


                                    if(ev.Subject == 'Call Back Request' && caseRec.RequestedCallBackDateAndTime__c <> oldCaseList.get(caseRec.Id).RequestedCallBackDateAndTime__c && ev.StartDateTime < caseRec.RequestedCallBackDateAndTime__c) {
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
                        //}                    
                    } else if (caseRec.RequestedCallBackDateAndTime__c == null && caseRec.RequestedCallBackDateAndTime__c <> oldCaseList.get(caseRec.Id).RequestedCallBackDateAndTime__c) {
                        
                        eventList = new List<Event>();
                        if(caseIdToEvents.containsKey(caseRec.Id)) {
                        
                            eventList = caseIdToEvents.get(caseRec.Id);
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
           logs.add(ApplicationConstant.getExceptionLog(e, 'createUpdateEvent', CLASS_NAME, null));
        }finally{
            if(logs.isEmpty()){
                if(eventToCreate.size() > 0){
                    Database.SaveResult[] updateLeadList = Database.insert(eventToCreate, false);
                    logs.addAll(ApplicationConstant.getSaveResultLog(updateLeadList, 'createUpdateEvent', CLASS_NAME, ApplicationConstant.LEAD_SOURCE_EVENT, 'Insert'));
                }
                
                if(eventToUpdate.size() > 0){
                    Database.SaveResult[] updateLeadList = Database.update(eventToUpdate, false);
                    String errorLogDescription;
                    logs.addAll(ApplicationConstant.getSaveResultLog(updateLeadList, 'createUpdateEvent', CLASS_NAME, ApplicationConstant.LEAD_SOURCE_EVENT, 'Update'));
                }
            }
        
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
        
    }*/
    
    
    /**
       *  This method is used to run the ScheduleUpdate Class  
       *  @name: ScheduleReAssigningQueue
       *  @developer: Aldric Seril 04/05/2016
       */

    /*   2.3
    public static void ScheduleReAssigningQueue(){
        AP13_CaseAssignmentRuleBatchSchedule reAssign = new AP13_CaseAssignmentRuleBatchSchedule();
        System.schedule('ReAssignQueueAt20','0 0 8-17 ? * MON-FRI',reAssign);
        System.schedule('ReAssignQueueAt40','0 20 8-17 ? * MON-FRI',reAssign);
        System.schedule('ReAssignQueueAt60','0 40 8-17 ? * MON-FRI',reAssign);
    }
    */
    
     /**
       *  This method is used to update the CaseId field on Account once a case has been created.
       *  @name: updateCaseIdOnAccount
       *  @developer: Renz Melecotones 04/11/2016
       *  @param: caseList - get Trigger.new from CaseTrigger; of List<Case> data type
       *  History :
       *    Jerome To -  May 7,2016 - Code Review Enhancements
       *              - this now checks the latest case id and put it on account's CaseId field
       *              - if there is none, account's caseId is set to empty
       *    
       *    Simon Molloy - 22/02/2017 - Moving this method to the WithoutSharingUtility class to prevent access issues
       *                                See JIRA SG-437
       */

    /*  2.3   
    public static void updateCaseIdOnAccount(List<Case> caseList){
        WithoutSharingUtility.updateCaseIdOnAccount(caseList);       
    }
    
    /**
       *  This method is used to update the Service Agent Assigned field on related Opportunity
       *  @name: updateOpportunityServiceAgentAssigned
       *  @developer: Xen Reyes 04/12/2016
       *  @param: caseList - get Trigger.new from CaseTrigger; of List<Case> data type
       *  @history;
       *    1.0 Jerome To - May 7, 2016 - Code Review enhancements
       *    1.1 Mark Cane - Sep 27, 2016 - WIRE triggers disabled for update.
       */

    /* 2.3
    public static void updateOpportunityServiceAgentAssigned(List<Case> caseList){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Case caseTemp;
        Set<Id> caseIdSet = new Set<Id>();
        Set<Id> opportunityIdSet = new Set<Id>();
        Map<Id, sObject> newCaseMap = Trigger.newMap;
        Map<Id, List<Case>> accIdNewCaseListMap = new Map<Id, List<Case>>();
        Map<Id, List<Case>> accIdCaseListMap = new Map<Id, List<Case>>();
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
        List<Case> caseRef = new List<Case>();
        Set<Id> accountIdSet = new Set<Id>();
        Map<String, String> mapAccAndErrors = new Map<String, String>();
        String errorLogDescription = '';        
        
        try{
            for(Case caseRec : caseList){
                if((caseRec.RecordTypeId == ApplicationConstant.CASERECTYPEID_AMENDMENT || caseRec.RecordTypeId == ApplicationConstant.CASERECTYPEID_COMPLAINT || caseRec.RecordTypeId == ApplicationConstant.CASERECTYPEID_SERVICECASE) 
                    && caseRec.Opportunity__c != NULL ){
                    if(accIdNewCaseListMap.containsKey(caseRec.AccountId)){
                        accIdNewCaseListMap.get(caseRec.AccountId).add(caseRec);
                    } else {
                        accIdNewCaseListMap.put(caseRec.AccountId, new List<Case>{caseRec});
                    }
                    opportunityIdSet.add(caseRec.Opportunity__c);
                    accountIdSet.add(caseRec.AccountId);
                }
            }
    
            opportunityMap = new Map<Id, Opportunity>([SELECT id, Name, ServiceAgentAssigned__c FROM Opportunity WHERE Id IN: opportunityIdSet]);
    
            for(Case caseRec : [SELECT id, AccountId, CreatedDate, Owner.Name FROM Case WHERE AccountId IN: accountIdSet ORDER BY CreatedDate DESC]){
                if(accIdCaseListMap.containsKey(caseRec.AccountId)){
                    accIdCaseListMap.get(caseRec.AccountId).add(caseRec);
                } else {
                    accIdCaseListMap.put(caseRec.AccountId, new List<Case>{caseRec});
                }
            }
    
            for(Id accId : accIdCaseListMap.keySet()){  
                if(accIdCaseListMap.get(accId).size() > accIdNewCaseListMap.get(accId).size()){
                    caseTemp = null;
                    for(Case caseRec : accIdCaseListMap.get(accId)){
                        if(!newCaseMap.containsKey(caseRec.Id)){
                            if(caseTemp != null){
                                if(caseTemp.CreatedDate < caseRec.CreatedDate){
                                    caseTemp = caseRec;
                                }
                            } else {
                                caseTemp = caseRec;
                            }
                        }
                    }
                    
                    for(Case newCaseRec : accIdNewCaseListMap.get(accId)){
                        Opportunity oppGet = opportunityMap.get(newCaseRec.Opportunity__c);
                        if (null != oppGet && null != caseTemp.Owner.Name){
                            oppGet.ServiceAgentAssigned__c = String.valueOf(caseTemp.Owner.Name);    
                        }
                        //2017-03-08 : SM : This line was erroring with ATTEMPT TO DE-REFERENCE A NULL OBJECT error 
                        //opportunityMap.get(newCaseRec.Opportunity__c).ServiceAgentAssigned__c = String.valueOf(caseTemp.Owner.Name);    
                    }       
                } else {
                    for(Case newCaseRec : accIdNewCaseListMap.get(accId)){
                        if(newCaseRec.SalesRegionGroup__c == ApplicationConstant.SALESREGIONGROUP_UK_IRELAND){
                            opportunityMap.get(newCaseRec.Opportunity__c).ServiceAgentAssigned__c = ApplicationConstant.QUEUE_CS_UK;
                        } else if(newCaseRec.SalesRegionGroup__c == ApplicationConstant.SALESREGIONGROUP_EUROPE){
                            opportunityMap.get(newCaseRec.Opportunity__c).ServiceAgentAssigned__c = ApplicationConstant.QUEUE_CS_EU;
                        } else if(newCaseRec.SalesRegionGroup__c == ApplicationConstant.SALESREGIONGROUP_MIDHAUL){
                            opportunityMap.get(newCaseRec.Opportunity__c).ServiceAgentAssigned__c = ApplicationConstant.QUEUE_CS_MIDHAUL;
                        } else if(newCaseRec.SalesRegionGroup__c == ApplicationConstant.SALESREGIONGROUP_LONGHAUL){
                            opportunityMap.get(newCaseRec.Opportunity__c).ServiceAgentAssigned__c = ApplicationConstant.QUEUE_CS_LONGHAUL;
                        }    
                    }       
                }
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'updateOpportunityServiceAgentAssigned', CLASS_NAME, null));
        }finally{
            if(logs.isEmpty() && opportunityMap.size() > 0){
            	
            	Boolean wireTriggerState = GBWire.WorkItemTriggerHandler.disableWIRETriggers;//1.1
                GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;//1.1
            	
                Database.SaveResult[] updateOppMap = Database.update(opportunityMap.values(), false);
                logs.addAll(ApplicationConstant.getSaveResultLog(updateOppMap, 'updateOpportunityServiceAgentAssigned', CLASS_NAME, 'Opportunity', 'Update'));
                
                GBWire.WorkItemTriggerHandler.disableWIRETriggers=wireTriggerState;//1.1                
            }
        
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }*/    
   

}