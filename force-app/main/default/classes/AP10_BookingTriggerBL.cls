/*
   @Author: Renz Melecotones/Tristan Zantua
   @name: AP08_BookingTriggerBL
   @CreateDate: 04.04.2016
   @Description: Business Logic Class for AP09_BookingTriggerHandler
   @Version <1.0>
   @Version <2.0> Merari Cebrian       Implemented Code Review Comments
   @Version <3.0> Recuerdo Bregente    Implemented Code Review Comments for error handling
   History
		------- 
	Ver. Author        Date        Detail
	1.1  J Radcliffe   2018-10-09  Disabling WIRE triggers, preventing them from running unecessarily after DML updates originating from a Booking trigger
	1.2  J Radcliffe   2018-10-09  Removing/Disabling updateAmendmentCaseStatus method at Shane's request
	1.3  J Radcliffe   2018-11-06  New Method setDefaultBusinessUnitAndBookingSystem
	1.4  J Radcliffe   2018-11-27  Removing redundant method - updateLastDestinationOnAccount
	1.5  Mark Cane     2018-12-12  Modified isTravelDateTodayAndCancelledBooking to reinstate WIRE behaviour for Cancellation (CRP,PA recalc required).
	1.6  J Radcliffe   2018-12-18  Removing invocation of Admin Case related Development
    1.7  J Radcliffe   2019-05-30  Retrieve Territory__c from parent opp on insert/update
    1.8  J Radcliffe   2019-07-15  New method: setBookingTerritory - Change to Default Territory Logic (1.7) - Calculate Territory based on SalesRegion__c 
    1.9  J Radcliffe   2021-07-26  Increase selectivity of updateOpportunityBookingAmount method + new logging
    1.10  J Radcliffe   2021-07-26  Increase selectivity of isTravelDateTodayAndCancelledBooking method + new logging
   */
public with sharing class AP10_BookingTriggerBL {

    // Used for logging --- Added by Dee 5/15
    public static final String CLASS_NAME = 'AP10_BookingTriggerBL';
    public static final String CANCELLATION_STATUS = 'Cancellation';



    public static void isTravelDateTodayAndCancelledBooking(List<Booking__c> bookingList, Map<Id, Booking__c> oldBookingMap) {
        //List<Error_Log__c> logs = new List<Error_Log__c>(); //1.10-
        
        Set<Id> oppToUpdate = new Set<Id>();        
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> oppsToUpdateMap = new Map<Id, Opportunity>();//1.10+

        try{
            for (Booking__c book : bookingList) {
                oppToUpdate.add(book.TECH_Opportunity__c);
            }
    
            if (!oppToUpdate.isEmpty()) {
            	//MC - 2017-02-24 - Error log remediation #SG-445-1. FOR UPDATE added to reduce lock errors.
                oppMap = new Map<Id, Opportunity>([SELECT Id,
                                                   StageName
                                                   FROM Opportunity
                                                   WHERE Id IN:oppToUpdate
                                                   FOR UPDATE]);
                for (Booking__c bookLoop : bookingList) {
                    if (!oldBookingMap.isEmpty()) {
                        //VCanlas - 7/14: Changed criteria to fit the requirements. 
                        if (oldBookingMap.containsKey(bookLoop.Id) &&
                                //oldBookingMap.get(bookLoop.Id).TravelReturnDate__c != bookLoop.TravelReturnDate__c &&
                                bookLoop.TravelReturnDate__c <= Date.today() &&
                                bookLoop.OpportunityStage__c == ApplicationConstant.PAIDFULLBALANCESTAGE &&
                                bookLoop.Status__c != CANCELLATION_STATUS) {
                            oppMap.get(bookLoop.TECH_Opportunity__c).StageName
                                = ApplicationConstant.OPP_STAGE_TRIPCOMPLETED;
                                oppsToUpdateMap.put(oppMap.get(bookLoop.TECH_Opportunity__c).Id,oppMap.get(bookLoop.TECH_Opportunity__c));//1.10+
                        }
    
                        if (oldBookingMap.containsKey(bookLoop.Id) &&
                               oldBookingMap.get(bookLoop.Id).Status__c != bookLoop.Status__c &&
                                bookLoop.Status__c == CANCELLATION_STATUS) {
                            oppMap.get(bookLoop.TECH_Opportunity__c).StageName
                                = ApplicationConstant.OPP_STATUS_CANCELLED;
                            oppsToUpdateMap.put(oppMap.get(bookLoop.TECH_Opportunity__c).Id,oppMap.get(bookLoop.TECH_Opportunity__c));//1.10+
                        }
                    } else {
                        if (bookLoop.TravelReturnDate__c <= Date.today() &&
                                bookLoop.Status__c != CANCELLATION_STATUS &&
                                bookLoop.OpportunityStage__c == ApplicationConstant.PAIDFULLBALANCESTAGE) {
                            oppMap.get(bookLoop.TECH_Opportunity__c).StageName
                                = ApplicationConstant.OPP_STAGE_TRIPCOMPLETED;
                            oppsToUpdateMap.put(oppMap.get(bookLoop.TECH_Opportunity__c).Id,oppMap.get(bookLoop.TECH_Opportunity__c));//1.10+
                        }
                        if (bookLoop.Status__c == CANCELLATION_STATUS) {
                            oppMap.get(bookLoop.TECH_Opportunity__c).StageName
                                = ApplicationConstant.OPP_STATUS_CANCELLED;
                            oppsToUpdateMap.put(oppMap.get(bookLoop.TECH_Opportunity__c).Id,oppMap.get(bookLoop.TECH_Opportunity__c));//1.10+
                        }
                    }
                }
            }
        }catch(Exception e){
           //logs.add(ApplicationConstant.getExceptionLog(e, 'isTravelDateTodayAndCancelledBooking', CLASS_NAME, null)); //1.10-
           Golfbreaks.PlatformLogManager.logExceptions(e,CLASS_NAME,'isTravelDateTodayAndCancelledBooking');//1.10+
        }finally{
            //if(logs.isEmpty() && oppMap.size() > 0){//1.10-
            if(oppsToUpdateMap.values().size()>0){//1.10+	
            	Boolean previousIsWIRECodeBlockedValue = WorkItemWIREActionIdentifier.isWIRECodeBlocked;//<--1.5
            	
                Boolean previousState = GBWire.WorkItemTriggerHandler.DisableWIRETriggers;//<----1.1
      			GBWire.WorkItemTriggerHandler.DisableWIRETriggers = true;//<----1.1
              
              	WorkItemWIREActionIdentifier.isWIRECodeBlocked = false;//<--1.5
                
                //Database.SaveResult[] updateOppMap = Database.update(oppMap.values(), false); //1.10-
                Database.SaveResult[] updateOppMap = Database.update(oppsToUpdateMap.values(), false);//1.10+ oppsToUpdateMap
				GBWire.WorkItemTriggerHandler.DisableWIRETriggers = previousState;//<----1.1      
                Golfbreaks.PlatformLogManager.logExceptions(updateOppMap,CLASS_NAME,'isTravelDateTodayAndCancelledBooking',oppsToUpdateMap.values());//1.10+          
                //logs.addAll(ApplicationConstant.getSaveResultLog(updateOppMap, 'isTravelDateTodayAndCancelledBooking', CLASS_NAME, 'Opportunity', 'Update'));//1.10-
                
                WorkItemWIREActionIdentifier.isWIRECodeBlocked = previousIsWIRECodeBlockedValue;//<--1.5
            }
        
            //if(!logs.isEmpty()){//1.10-
            //    Database.insert(logs, false);
            //}
        }
    }

    /**
       *  This method is used to update the TotalPreviousBookings field in the associated lead record
       *  @name: updateTotalBookingsAndTotalOpportunitiesOnLead
       *  @developer: Erika Hidalgo
       *  @param: bookingList - get Trigger.new from BookingTrigger of List<Booking__c> data type
       	History
		------- 
		Ver. Author        Date        Detail
		1.1  J Radcliffe   2018-10-09  Disabling WIRE triggers on Lead update
     */
    public static void updateTotalPreviousBookingsOnLead(List<Booking__c> bookingList) {
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Map<Lead, Integer> leadsAndNumOfBookings = new Map<Lead, Integer>();
        Map<Id, Set<Id>> leadAndAcctId = new Map<Id, Set<Id>>();
        List<Lead> listOfLeadsToUpdate = new List<Lead>();

        List<Booking__c> books = new List<Booking__c>();
        Map<Id, Integer> booksPerAcctId = new Map<Id, Integer>();
        List<Id> acctIds = new List<id>();

        Map<Id, Integer> accountIdTotalBooks = new Map<Id, Integer>();

        try{
            //GetAllBookingAccount
            for (Booking__c book : bookingList) {
                if (book.Account__c != null) {
                    acctIds.add(book.Account__c);
                }
            }
            //Get count all books related to booking account
            if (!acctIds.isEmpty()) {
                for (AggregateResult ar : [SELECT Account__c acctId, Count(id) totalBooks FROM Booking__c WHERE Account__c IN: acctIds GROUP BY Account__c]) {
                    accountIdTotalBooks.put((Id)ar.get('acctId'), (Integer)ar.get('totalBooks'));
                }
            }
            //Update Lead based on booking account
            if (!accountIdTotalBooks.isEmpty()) {
                for (Lead l : [SELECT id, Account__c, TotalPreviousBookings__c FROM Lead WHERE IsConverted = false AND Account__c IN: accountIdTotalBooks.keySet()]) {
                    l.TotalPreviousBookings__c = accountIdTotalBooks.get(l.Account__c);
                    listOfLeadsToUpdate.add(l);
                }
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'updateTotalPreviousBookingsOnLead', CLASS_NAME, null));
        }finally{
            if(logs.isEmpty() && listOfLeadsToUpdate.size() > 0){
                
                Boolean previousState = GBWire.WorkItemTriggerHandler.DisableWIRETriggers;//<----1.1
      			GBWire.WorkItemTriggerHandler.DisableWIRETriggers = true;//<----1.1
                Database.SaveResult[] updateLeadList = Database.update(listOfLeadsToUpdate, false);
                GBWire.WorkItemTriggerHandler.DisableWIRETriggers = previousState; //<---- 1.1
                logs.addAll(ApplicationConstant.getSaveResultLog(updateLeadList, 'updateTotalPreviousBookingsOnLead', CLASS_NAME, ApplicationConstant.LEAD_SOBJECTTYPE, 'Update'));
            }
        
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }


    public static void updateOpportunityBookingAmount(Map<Id,Booking__c> oldMap, List<Booking__c> bookingList) {//1.9~ (add the oldMap)
        //List<Error_Log__c> logs = new List<Error_Log__c>();//1.9-
        
        Set<Id> oppToUpdate = new Set<Id>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> oppsToUpdateMap = new Map<Id,Opportunity>();//1.9+

        try{
            for (Booking__c booking : bookingList) {
                if(oldMap != null && oldMap.containsKey(booking.Id)
                && oldMap.get(booking.Id).Sale_Price_Gross__c == booking.Sale_Price_Gross__c
                && oldMap.get(booking.Id).Gross_Profit__c == booking.Gross_Profit__c
                ) continue;//1.9+ Continue to next booking if no changes were made to the booking amount fields.
                oppToUpdate.add(booking.TECH_Opportunity__c);
            }
            

            if(!oppToUpdate.isEmpty()){
                oppMap = new Map<Id, Opportunity>([SELECT Id, BookingAmount__c, BookingProfit__c FROM Opportunity WHERE Id IN:oppToUpdate]);//1.9~ (added BookingProfit__c,BookingAmount__c)
            }
            for (Booking__c booking : bookingList) {
                if (oppMap.containsKey(booking.TECH_Opportunity__c)) {
                    Opportunity oppforUp = oppMap.get(booking.TECH_Opportunity__c);
                    if(oppforUp.BookingAmount__c != booking.Sale_Price_Gross__c
                    || oppforUp.BookingProfit__c != booking.Gross_Profit__c){//1.9+ Only proceed if the amounts don't already align
                        oppforUp.BookingAmount__c = booking.Sale_Price_Gross__c;
                        oppforUp.BookingProfit__c = booking.Gross_Profit__c;
                        oppsToUpdateMap.put(oppforUp.Id,oppforUp);//1.9+ Add to (new) update map
                    }
                }
            }

        }catch(Exception e){
           //logs.add(ApplicationConstant.getExceptionLog(e, 'updateOpportunityBookingAmount', CLASS_NAME, null));//1.9-
           Golfbreaks.PlatformLogManager.logExceptions(e,CLASS_NAME,'updateOpportunityBookingAmount');//1.9+
        }finally{
            //if(logs.isEmpty() && oppMap.values().size() > 0){//1.9-
            if(oppsToUpdateMap.values().size()>0){//1.9+
                Boolean previousState = GBWire.WorkItemTriggerHandler.DisableWIRETriggers;//<----1.1
      			GBWire.WorkItemTriggerHandler.DisableWIRETriggers = true;//<----1.1
                //Database.SaveResult[] UpdatedOpp = Database.update(oppMap.values(), false);//1.9-
                Database.SaveResult[] UpdatedOpp = Database.update(oppsToUpdateMap.values(), false);//1.9+
                GBWire.WorkItemTriggerHandler.DisableWIRETriggers = previousState; //<----1.1
                Golfbreaks.PlatformLogManager.logExceptions(UpdatedOpp,CLASS_NAME,'updateOpportunityBookingAmount',oppsToUpdateMap.values());//1.9+
                //logs.addAll(ApplicationConstant.getSaveResultLog(UpdatedOpp, 'updateOpportunityBookingAmount', CLASS_NAME, 'Opportunity', 'Update'));//1.9+
            }
        
            //if(!logs.isEmpty()){//1.9-
            //    Database.insert(logs, false);
            //}
        }
    }

    //1.3 - This method retrieves the Business Unit/Booking System from the parent Opportunity OR sets as the Default on the Booking, if none is specified.
    //Note - To be run in a Before Trigger Context
    public static void setDefaultBusinessUnitAndBookingSystem(List<Booking__c> bookingList){
        
        //Collate Booking Opportunity Ids for Query
        Set<Id> oppIds = new Set<Id>();
        for(Booking__c b : bookingList){
            if(b.TECH_Opportunity__c != null){
                oppIds.add(b.TECH_Opportunity__c);
            }
        }
        
        //Maps to store the Booking Opportunity's Business Unit and Booking System
        Map<Id,Id> oppIdToGBUId = new Map<Id,Id>();
        Map<Id,String> oppIdToBookingSystem = new Map<Id,String>();
        //Map<Id,Id> oppIdToTerritoryId = new Map<Id,Id>();//1.7
        //Query parent Opportunity and set Maps
        if(oppIds.size()>0){
            for(Opportunity o : [Select Booking_System__c, Golfbreaks_Business_Unit__c, Territory__c From Opportunity Where Id In:oppIds]){
                oppIdToGBUId.put(o.Id,o.Golfbreaks_Business_Unit__c);
                oppIdToBookingSystem.put(o.Id,o.Booking_System__c);
                //oppIdToTerritoryId.put(o.Id,o.Territory__c);//1.7
            }
        }
        
        //Collate a list that require the default (i.e. no parent opp or opp data is not set)
        List<Booking__c> bookingsRequiringDefault = new List<Booking__c>();
        
        for(Booking__c b : bookingList){
            if(b.TECH_Opportunity__c == null){
                bookingsRequiringDefault.add(b);
            }else if(oppIdToGBUId != null && oppIdToGBUId.keySet().contains(b.TECH_Opportunity__c) && oppIdToBookingSystem != null && oppIdToBookingSystem.keySet().contains(b.TECH_Opportunity__c)
                     && oppIdToGBUId.get(b.TECH_Opportunity__c) != null && oppIdToBookingSystem.get(b.TECH_Opportunity__c) != null){
                         
                         b.Golfbreaks_Business_Unit__c = oppIdToGBUId.get(b.TECH_Opportunity__c);   
                         b.Booking_System__c = oppIdToBookingSystem.get(b.TECH_Opportunity__c);
                         //b.Territory__c = oppIdToTerritoryId.get(b.TECH_Opportunity__c); //1.7
                         
                         
                     }else{
                         bookingsRequiringDefault.add(b);
                     }
        }
        
        if(bookingsRequiringDefault.size()>0){
            //Query Default Golfbreaks Business Unit record - This will retrieve the record flagged as default first followed by the 'UK' business unit (if none has been flagged)
            Golfbreaks_Business_Unit__c[] gbus = [Select Id, (Select Id From Territories__r Where IsDefault__c = true Limit 1), Name, Default_Booking_System__c From Golfbreaks_Business_Unit__c WHERE IsDefault__c = true OR Name LIKE '%UK%' ORDER By IsDefault__c ASC LIMIT 2];
            if(gbus.size()>0){
                Id defaultBusinessUnitId = gbus[0].Id;
                String defaultBookingSystem = gbus[0].Default_Booking_System__c;
                for(Booking__c b :bookingsRequiringDefault){
                    if(b.Golfbreaks_Business_Unit__c == null){
                        b.Golfbreaks_Business_Unit__c = defaultBusinessUnitId;
                        b.Booking_System__c = defaultBookingSystem;
                        //if(gbus[0].Territories__r.size()>0) b.Territory__c = gbus[0].Territories__r[0].Id; //1.7
                    }
                }
            }  
        }
        
    }     

    
    public static void setBookingTerritory(List<Booking__c> bookingList, Map<Id,Booking__c> oldBookingMap){

        try{
            List<Booking__c> bookingsToProcess = new List<Booking__c>();
            Set<Id> businessUnitIds = new Set<Id>();
            for(Booking__c b : bookingList){
                //Cannot calculate Territory without a BU 
                if(b.Golfbreaks_Business_Unit__c == null) continue;
                //Don't override existing Territory is explicitly set on Insert
                if(b.Territory__c != null && trigger.IsInsert) continue;
                //Ignore updates that result in NO change to the BU or Sales Region (unless the Territory is null)
                if(trigger.IsUpdate && b.Territory__c != null && oldBookingMap != null && oldBookingMap.get(b.Id) != null
                && oldBookingMap.get(b.Id).Golfbreaks_Business_Unit__c == b.Golfbreaks_Business_Unit__c 
                && oldBookingMap.get(b.Id).Sales_Region__c == b.Sales_Region__c) continue;
                //In all other scenarios, proceed to calculate and set the Territory
                bookingsToProcess.add(b);
                if(!businessUnitIds.contains(b.Golfbreaks_Business_Unit__c)) businessUnitIds.add(b.Golfbreaks_Business_Unit__c);
            }
            
            //Retrieve a Map of Business Units and applicable Territories ensuring the default territory is at the top
            Map<Id,Golfbreaks_Business_Unit__c> buMap = new Map<Id,Golfbreaks_Business_Unit__c>([Select Id, (Select Id, Countries__c, IsDefault__c From Territories__r Order By IsDefault__c desc), Name, Default_Booking_System__c, IsDefault__c From Golfbreaks_Business_Unit__c Where Id In:businessUnitIds]);
            Map<Id,Id> busWithDefaultTerritoryIds = new Map<Id,Id>();
            for(Golfbreaks_Business_Unit__c bu : buMap.values()){
                //The query ensures the default T is at the top. Cache the deafult.
                if(bu.Territories__r.size()>0) busWithDefaultTerritoryIds.put(bu.Id,bu.Territories__r[0].Id);
            }

            //Loop, evalauate and assign
            for(Booking__c b : bookingsToProcess){
                //Set to default if no 'Sales Region' (country) is specified
                if(b.Sales_Region__c == null && busWithDefaultTerritoryIds.containsKey(b.Golfbreaks_Business_Unit__c)){
                    b.Territory__c = busWithDefaultTerritoryIds.get(b.Golfbreaks_Business_Unit__c);
                    continue;
                }else{
                    for(Territory__c t : buMap.get(b.Golfbreaks_Business_Unit__c).Territories__r){
                        //Assign the territory based on matching Countries vs Sales Region
                        if(t.Countries__c != null && t.Countries__c.contains(b.Sales_Region__c)){
                            b.Territory__c = t.Id;
                            break;//Exit as soon as a match is found
                        }else{
                            //Ensure the default is assigned for non matches (to ultimately catch any that have no matching territories at the end of the loop)
                            b.Territory__c = busWithDefaultTerritoryIds.get(b.Golfbreaks_Business_Unit__c);
                        }
                    }
                }
            }
        }catch(exception e){
            system.debug('Error Assigning Territories to Booking: '+e);
            PlatformLogManager.logExceptions(e, 'AP10_BookingTriggerBL', 'setBookingTerritory');
        }
    
    }
    
    /**
       *  This method is used to update Ammendment Case status to 'Check Supplier Confirmation'
       *  @name: updateAmendmentCaseStatus
       *  @developer: Merari Cebrian 06/05/2016
       *  @param: bookingList - get Trigger.new from BookingTrigger of List<Booking__c> Data Type
    **/
    /* 1.2 - Removing Ammendment Case Updates at Shane's request - 09/10/2018
    public static void updateAmendmentCaseStatus(List<Booking__c> bookingList, Map<Id, Booking__c> oldBookingMap) {
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> bookingIdSet = new Set<Id>(); 
        List<Case> updateCaseList = new List<Case>();
        
        try{
            for (Booking__c bookingRec : bookingList) {
                if (!String.isEmpty(bookingRec.Account__c)) {
                    accountIdSet.add(bookingRec.Account__c);
                }
                bookingIdSet.add(bookingRec.Id);
            }
            
            //MC - 2017-02-24 - Error log remediation #SG-445-2. FOR UPDATE added to reduce lock errors.
            for (Case caseRec : [SELECT Id, AccountId, Status, Booking__r.WaitingOnSupplier__c, Booking__r.AgentAttentionRequired__c, IsClosed, OwnerId 
            					FROM Case 
            					WHERE RecordTypeId =: ApplicationConstant.CASERECTYPEID_AMENDMENT AND AccountId IN: accountIdSet AND Booking__r.Id IN: bookingIdSet
            					FOR UPDATE]) {                
                //updateAmendmentCaseStatusToCSC
                if (caseRec.Booking__r.AgentAttentionRequired__c == true &&
                        caseRec.Status <> ApplicationConstant.CASE_STATUS_ONHOLD_WFC &&
                        caseRec.IsClosed == false) {
                    caseRec.Status = ApplicationConstant.CASE_STATUS_CSC;
                    updateCaseList.add(caseRec);
                }
                //updateAmendmentCaseStatusToOnHoldWFS
                if (caseRec.Booking__r.AgentAttentionRequired__c == false &&
                        caseRec.Booking__r.WaitingOnSupplier__c == true &&
                        caseRec.Status <> ApplicationConstant.CASE_STATUS_ONHOLD_WFC &&
                        caseRec.IsClosed == false) {
                    caseRec.Status = ApplicationConstant.CASE_STATUS_ONHOLD_WFS;
                    updateCaseList.add(caseRec);
                }
                //updateAmendmentCaseStatusToClosed
                //2017-02-24 : SM : We cannot close cases that are owned by Groups
                if (!oldBookingMap.isEmpty() &&
                        oldBookingMap.get(caseRec.Booking__r.Id).AgentAttentionRequired__c == true &&
                        caseRec.Booking__r.AgentAttentionRequired__c == false &&
                        caseRec.Booking__r.WaitingOnSupplier__c == false &&
                        caseRec.IsClosed == false && caseRec.Status <> ApplicationConstant.CASE_STATUS_ONHOLD_WFC) {
                    
                    String oId = caseRec.OwnerId;
                    if (!oId.substring(0,3).equalsIgnoreCase('00G')){
                        caseRec.Status = ApplicationConstant.CASE_STATUS_CLOSED;
                        caseRec.AccountableforIssue__c = ApplicationConstant.CASE_ACCOUNTABLE_FOR_ISSUE_NONE;
                        caseRec.CustomerSatisfaction__c = ApplicationConstant.CASE_CUSTOMER_SATISFACTION_NA;
                        caseRec.ClosedSubStatus__c = ApplicationConstant.CASE_CLOSED_SUBSTATUS_ACCEPTED;                
                        updateCaseList.add(caseRec);
                    }
                }
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'updateAmendmentCaseStatus', CLASS_NAME, null));
        }finally{
            if(logs.isEmpty() && !updateCaseList.isEmpty()){
                Database.SaveResult[] ucList = Database.update(updateCaseList, false);
                logs.addAll(ApplicationConstant.getSaveResultLog(ucList, 'updateAmendmentCaseStatus', CLASS_NAME, ApplicationConstant.CASE_SOBJECTTYPE, 'Update'));
            }
        
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }*/
   
    
    /* * /
	public static void isTravelDateTodayAndCancelledBookingOld(List<Booking__c> bookingList, Map<Id, Booking__c> oldBookingMap) {
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Set<Id> oppToUpdate = new Set<Id>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();

        try{
            for (Booking__c book : bookingList) {
                oppToUpdate.add(book.TECH_Opportunity__c);
            }
    
            if (!oppToUpdate.isEmpty()) {
            	//MC - 2017-02-24 - Error log remediation #SG-445-1. FOR UPDATE added to reduce lock errors.
                oppMap = new Map<Id, Opportunity>([SELECT Id,
                                                   StageName
                                                   FROM Opportunity
                                                   WHERE Id IN:oppToUpdate
                                                   FOR UPDATE]);
                for (Booking__c bookLoop : bookingList) {
                    if (!oldBookingMap.isEmpty()) {
                        //VCanlas - 7/14: Changed criteria to fit the requirements. 
                        if (oldBookingMap.containsKey(bookLoop.Id) &&
                                //oldBookingMap.get(bookLoop.Id).TravelReturnDate__c != bookLoop.TravelReturnDate__c &&
                                bookLoop.TravelReturnDate__c <= Date.today() &&
                                bookLoop.OpportunityStage__c == ApplicationConstant.PAIDFULLBALANCESTAGE &&
                                bookLoop.Status__c != CANCELLATION_STATUS) {
                            oppMap.get(bookLoop.TECH_Opportunity__c).StageName
                                = ApplicationConstant.OPP_STAGE_TRIPCOMPLETED;
                        }
    
                        if (oldBookingMap.containsKey(bookLoop.Id) &&
                               oldBookingMap.get(bookLoop.Id).Status__c != bookLoop.Status__c &&
                                bookLoop.Status__c == CANCELLATION_STATUS) {
                            oppMap.get(bookLoop.TECH_Opportunity__c).StageName
                                = ApplicationConstant.OPP_STATUS_CANCELLED;
                        }
                    } else {
                        if (bookLoop.TravelReturnDate__c <= Date.today() &&
                                bookLoop.Status__c != CANCELLATION_STATUS &&
                                bookLoop.OpportunityStage__c == ApplicationConstant.PAIDFULLBALANCESTAGE) {
                            oppMap.get(bookLoop.TECH_Opportunity__c).StageName
                                = ApplicationConstant.OPP_STAGE_TRIPCOMPLETED;
                        }
                        if (bookLoop.Status__c == CANCELLATION_STATUS) {
                            oppMap.get(bookLoop.TECH_Opportunity__c).StageName
                                = ApplicationConstant.OPP_STATUS_CANCELLED;
                        }
                    }
                }
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'isTravelDateTodayAndCancelledBooking', CLASS_NAME, null));
        }finally{
            if(logs.isEmpty() && oppMap.size() > 0){
                Boolean previousState = GBWire.WorkItemTriggerHandler.DisableWIRETriggers;//<----1.1
      			GBWire.WorkItemTriggerHandler.DisableWIRETriggers = true;//<----1.1
                Database.SaveResult[] updateOppMap = Database.update(oppMap.values(), false);
				GBWire.WorkItemTriggerHandler.DisableWIRETriggers = previousState;//<----1.1                
                logs.addAll(ApplicationConstant.getSaveResultLog(updateOppMap, 'isTravelDateTodayAndCancelledBooking', CLASS_NAME, 'Opportunity', 'Update'));
            }
        
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    } 
    /* */   


	/* 1.4 - This method seemingly does nothing except query and update the Booking accounts and is not currently invoked from any class 
	 * Commenting out to assist with code coverage
    public static void updateLastDestinationOnAccount(List<Booking__c> bookingList){
        List<Error_Log__c> logs = new List<Error_Log__c>();

        Set<Id> accIdSet = new Set<Id>();

        for (Booking__c b : bookingList){
            accIdSet.add(b.Account__c);
        }

        Map<Id, Account> accMap = new Map<Id, Account>([select Id, Last_Destination__c from Account where Id in :accIdSet]);
            
        try {

        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'updateLastDestinationOnAccount', CLASS_NAME, null));
        }finally{
            if(logs.isEmpty() && accMap.values().size() > 0){
                Database.SaveResult[] UpdatedAccs = Database.update(accMap.values(), false);
                logs.addAll(ApplicationConstant.getSaveResultLog(UpdatedAccs, 'updateLastDestinationOnAccount', CLASS_NAME, 'Account', 'Update'));
            }
        
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }    
    }*/



    /***************************************************************************************
    Developer -    Patrick Villarica (Accenture)
    Date -         14/04/2016
    Version -      1.0
    Function -     Auto Close Admin Task and Admin Case
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    /*1.6 - Comment Out
    public static void checkAdminTask(Map<Id, Booking__c> bookingNewMap, Map<Id, Booking__c> bookingOldMap) {
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        //Set variables
        Set<Id> bookingIdSet = new Set<Id> ();
        Set<Id> bookingIDeposit = new Set<Id>();
        Set<Id> bookingFDeposit = new Set<Id>();
        Set<Id> bookingFBalance = new Set<Id>();
        Set<Id> bookingTransferDetails = new Set<Id>();
        Set<Id> bookingRoomingSet = new Set<Id>();
        //List variables
        List<Task> forUpdateTaskList = new List<Task>();
        List<Case> forUpdateCaseList = new List<Case>();
        //Map variables
        Map<Id, Task> taskMap = new Map<Id, Task>();
        Map<Id, Case> caseMap = new Map<Id, Case>();
        Map<Id, String> bookingAgentTaskMap = new Map<Id, String>();
        //Integer variables
        Integer closedAdminTask = 0; //Counter to check to auto close the Admin case if no related open task

        try{
            User apiUser = [SELECT Id FROM User WHERE Name =: ApplicationConstant.USER_NAME_API_USER LIMIT 1];
            for (Booking__c booking : bookingNewMap.Values()) {
                if (bookingOldMap.containsKey(booking.Id)) {
                    system.debug('booking.AmountPaid__c new:'+booking.AmountPaid__c);
                    system.debug('booking.AmountPaid__c old:'+bookingOldMap.get(booking.Id).AmountPaid__c);
                    system.debug('booking.Sale_Price_Gross__c new:'+booking.Sale_Price_Gross__c);
                    system.debug('booking.Sale_Price_Gross__c old:'+bookingOldMap.get(booking.Id).Sale_Price_Gross__c);
                    //Get all Booking that have updates related to Admin Case
                    if (booking.AmountPaid__c <> bookingOldMap.get(booking.Id).AmountPaid__c || booking.Sale_Price_Gross__c <> bookingOldMap.get(booking.Id).Sale_Price_Gross__c) {
                        bookingIdSet.add(booking.Id);
                    }
                    //Get all Booking to auto close related Transfer Detail Task
                    /*if (!booking.TransferDetailsRequired__c && booking.TransferDetailsRequired__c <> bookingOldMap.get(booking.Id).TransferDetailsRequired__c) {
                        bookingTransferDetails.add(booking.Id);
                        bookingIdSet.add(booking.Id);
                    }*/
                    //Get all Booking to auto close related Rooming List Task
                    /*if (!booking.RoomingListRequired__c && booking.RoomingListRequired__c <> bookingOldMap.get(booking.Id).RoomingListRequired__c) {
                        bookingRoomingSet.add(booking.Id);
                        bookingIdSet.add(booking.Id);
                    }*/
                    //Get all Booking to auto close related Check ClubHouse Task
                   /* if ((String.isBlank(booking.AgentTaskName__c) || String.isNotBlank(bookingOldMap.get(booking.Id).AgentTaskName__c)) && booking.AgentTaskName__c <> bookingOldMap.get(booking.Id).AgentTaskName__c) {
                        bookingAgentTaskMap.put(booking.Id, bookingOldMap.get(booking.Id).AgentTaskName__c);
                        bookingIdSet.add(booking.Id);
                    }
                }
            }
            for (Expected_Payment__c ep : [SELECT Id, Booking__c, Outstanding_Balance__c, ExpectedPaymentType__c 
                                            FROM Expected_Payment__c 
                                            WHERE ExpectedPaymentType__c IN: ApplicationConstant.EPTYPESET AND Outstanding_Balance__c = 0 AND Booking__c IN: bookingIdSet]) {
                
                //Get all Booking to auto close related Partial Deposit Task
                if (ep.ExpectedPaymentType__c == ApplicationConstant.EPAYMENTTYPEPARTIALDEPOSIT) {
    
                    bookingIDeposit.add(ep.Booking__c);
                }
                //Get all Booking to auto close related Full Deposit Task
                else if (ep.ExpectedPaymentType__c == ApplicationConstant.EPAYMENTTYPEFULLDEPOSIT) {
    
                    bookingFDeposit.add(ep.Booking__c);
                }
                //Get all Booking to auto close related Full Balance Task
                else if (ep.ExpectedPaymentType__c == ApplicationConstant.EPAYMENTTYPEFULLBALANCE) {
    
                    bookingFBalance.add(ep.Booking__c);
                }
            }
            //May 7 2016 Merari Cebrian - Updated criteria from Status <>: ApplicationConstant.CASE_STATUS_CLOSED to IsClosed = false
            for (Case caseRec : [SELECT Id, Type, Status, Booking__c, OwnerId, Is_Case_Assigned__c,
                                (Select ID, Subject FROM Tasks WHERE IsClosed = false ) 
                                FROM Case 
                                WHERE IsClosed = false AND 
                                RecordTypeId = :ApplicationConstant.CASERECTYPEID_ADMIN AND 
                                Type = : ApplicationConstant.CASETYPE_ADMIN AND 
                                Booking__c IN: bookingIdSet]) {
                
                //Check for Open Task related to Case
                if (!caseRec.Tasks.isEmpty()) {
                    closedAdminTask = 0; //Reset the counter for the Admin Task
    
                    for (Task t : caseRec.Tasks) {
                        //Check if there is a Open Initial Deposit Tasku
                        if (t.Subject == ApplicationConstant.GETINITIALDEPOSIT && bookingIDeposit.contains(caseRec.Booking__c)) {
    
                            closedAdminTask++;
                            t.Status = ApplicationConstant.TASKSTATUS_COMPLETED;
                            taskMap.put(t.id, t);
                            forUpdateTaskList.add(t);
                        }
                        //Check if there is a Open Deposit Balance Task
                        else if (t.Subject == ApplicationConstant.GETDEPOSITBALANCE && bookingFDeposit.contains(caseRec.Booking__c)) {
    
                            closedAdminTask++;
                            t.Status = ApplicationConstant.TASKSTATUS_COMPLETED;
                            taskMap.put(t.id, t);
                            forUpdateTaskList.add(t);
                        }
                        //Check if there is a Open Full Balance Task
                        else if (t.Subject == ApplicationConstant.GETFINALBALANCE && bookingFBalance.contains(caseRec.Booking__c)) {
    
                            closedAdminTask++;
                            t.Status = ApplicationConstant.TASKSTATUS_COMPLETED;
                            taskMap.put(t.id, t);
                            forUpdateTaskList.add(t);
                        }
                        //Check if there is a Open Transfer Detail Task
                        /*else if (t.Subject == ApplicationConstant.TASKSUBJ_GETTRANSFER && bookingTransferDetails.contains(caseRec.Booking__c)) {
    
                            closedAdminTask++;
                            t.Status = ApplicationConstant.TASKSTATUS_COMPLETED;
                            taskMap.put(t.id, t);
                            forUpdateTaskList.add(t);
                        }
                        //Check if there is a Open Rooming List Task
                        else if (t.Subject == ApplicationConstant.TASKSUBJ_GETROOMING && bookingRoomingSet.contains(caseRec.Booking__c)) {
    
                            closedAdminTask++;
                            t.Status = ApplicationConstant.TASKSTATUS_COMPLETED;
                            taskMap.put(t.id, t);
                            forUpdateTaskList.add(t);
                        }*/
                        //Check if there is a Open Check Clubhouse Task
         /*1.6             else if (bookingAgentTaskMap.containsKey(caseRec.Booking__c)) {
                            if (t.Subject == ApplicationConstant.TASKSUBJ_CHECKCH + bookingAgentTaskMap.get(caseRec.Booking__c)) {
                                closedAdminTask++;
                                t.Status = ApplicationConstant.TASKSTATUS_COMPLETED;
                                taskMap.put(t.id, t);
                                forUpdateTaskList.add(t);
                            }
                        }
                    }
                    //Check if we can auto close the related Case
                    if (caseRec.Tasks.size() == closedAdminTask) {
                        if(String.valueOf(caseRec.OwnerId).startswith('00G')) {
                            caseRec.OwnerId = apiUser.Id;
                            caseRec.Is_Case_Assigned__c = true;
                        }
                        caseRec.Status = ApplicationConstant.CASE_STATUS_CLOSED;
                        caseMap.put(caseRec.Id, caseRec);
                        forUpdateCaseList.add(caseRec);
                    }
                }
            }
            //Check if we need to update task
            if (!forUpdateTaskList.isEmpty()) {
                Database.update(forUpdateTaskList);                  
            }
    
            if (!forUpdateCaseList.isEmpty()) {
                Boolean previousState = GBWire.WorkItemTriggerHandler.DisableWIRETriggers;//<---- 1.1
        		GBWire.WorkItemTriggerHandler.DisableWIRETriggers = true;//<---- 1.1 
                Database.update(forUpdateCaseList);
                GBWire.WorkItemTriggerHandler.DisableWIRETriggers = previousState;//<---- 1.1 
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'checkAdminTask', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }
	*/
	/*1.6
    public static void checkBookingForAdminTasksToClose(Map<Id, Booking__c> bookingNewMap, Map<Id, Booking__c> bookingOldMap) {
        Set<Id> bookingIdSet = new Set<Id>();
        Set<Id> bookingIdSetWithChagesOnAgentTaskName = new Set<Id>();

        for (Booking__c booking : bookingNewMap.Values()) {
            if (bookingOldMap.containsKey(booking.Id)) {
                if (booking.AmountPaid__c <> bookingOldMap.get(booking.Id).AmountPaid__c || booking.Sale_Price_Gross__c <> bookingOldMap.get(booking.Id).Sale_Price_Gross__c) {
                    booking.Has_Admin_Case_To_Close__c = true;
                }
                
                if ((String.isBlank(booking.AgentTaskName__c) || String.isNotBlank(bookingOldMap.get(booking.Id).AgentTaskName__c)) && booking.AgentTaskName__c <> bookingOldMap.get(booking.Id).AgentTaskName__c) {
                    //bookingAgentTaskMap.put(booking.Id, bookingOldMap.get(booking.Id).AgentTaskName__c);
                    booking.Has_Change_in_Agent_Task_Name__c = true;
                    booking.Has_Admin_Case_To_Close__c = true;
                }
            }
        }

    }*/
    

    
}