/*
   @Author: Renz Melecotones
   @name: AP09_BookingTriggerHandler
   @CreateDate: 05.04.2016
   @Description: Handler Class for BookingTrigger
   @Version <1.0>

History
------- 
Ver. Author        Date        Detail
1.1  J.Radcliffe   2018-06-19  Implementing the 'Phased Code Removal' custom setting to support with the phased removal of redundant code (Housekeeping)
1.2  J.Radcliffe   2018-09-19  Disable WIRE triggers on Before Triggers
1.3  J.Radcliffe   2018-10-08  Disabling WIRE triggers on Insert triggers - Instead this functionality will be called via process builder (apex action) AFTER the Business Unit has been set (essential for Preferred Queue/CRP Calculation)
1.4  J.Radcliffe   2018-10-09  Removing/Disabling updateAmendmentCaseStatus method at Shane's request
1.5  J.Radcliffe   2018-11-05  Adding calls to the WIRE Action Identifier and Action Utility in After Trigger Context
1.6  J.Radcliffe   2018-11-06  Retrieving Business Unit/Booking System from Opportunity or Setting Default, if none is specified
1.7  J.Radcliffe   2018-11-08  Adding references to static variables for WIRE recursion control
1.8  J.Radcliffe   2018-12-18  Removing invocaction of Admin Case Development
1.9  J.Radcliffe   2019-07-12  Moving WIRE Trigger Actions to run Asynchronously
1.10 J.Radcliffe   2019-07-15  New method invocation - setBookingTerritory - Calculate and set the Territory based on SalesRegion and Business Unit
1.11 J.Radcliffe   2021-07-26  Passing oldMap to updateOpportunityBookingAmount method (to facilitate trigger optimisation)
1.12 J.Radcliffe   2021-12-16  Enabling Callouts via Int Framework (Data Event Types mdt)
1.13 C Stuart      2023-05-11  Added delay to the WorkItemWIREActionIdentifier.ExecuteWIREActionsQueueable to prevent method running in parallel with the EP Record on upsert
1.14 J Radcliffe   2024-02-13  Invoke assignPublicId method (GUID Generator) - Create a PublicId__c before insert.
 */
public with sharing class AP09_BookingTriggerHandler {

    //recursion flags Added By Dee June 4 -- Based on Code Review
    public static Boolean isAfterUpdateTriggerCalled = FALSE;
    public static Boolean isAfterDeleteTriggerCalled = FALSE;
    public static Boolean isAfterInsertTriggerCalled = FALSE;
    public static Boolean isbeforeUpdateTriggerCalled = FALSE;
    public static Boolean isBeforeInsertTriggerCalled = FALSE;

    public AP09_BookingTriggerHandler() {

    }

    public void OnBeforeInsert(List<Booking__c> newBookingList, Map<Id, Booking__c> newBookingMap, List<Booking__c> oldBookingList, Map<Id, Booking__c> oldBookingMap) {

        //1.2 - Disable WIRE triggers on Before Triggers
        Boolean previousState = GBWire.WorkItemTriggerHandler.DisableWIRETriggers;
        GBWire.WorkItemTriggerHandler.DisableWIRETriggers = true;
        
        if(!isBeforeInsertTriggerCalled){ 

            GUIDGenerator.assignPublicId(newBookingList);//1.14+

            //1.6 - Collate sorted lists for BL processing
            List<Booking__c> defaultBUBookings = new List<Booking__c>();
            //Loop through trigger records
            for(Booking__c b : newBookingList){
                if(b.Golfbreaks_Business_Unit__c == null || b.Booking_System__c == null){
                    defaultBUBookings.add(b);
                }
            }
            if(defaultBUBookings.size()>0){           
                //1.6 - Default Business Unit/Booking System
                AP10_BookingTriggerBL.setDefaultBusinessUnitAndBookingSystem(defaultBUBookings);
            }
            //1.10 - Calculate the Territory based on BU & Sales Region
            //Note - must be after the Business Unit is set
            AP10_BookingTriggerBL.setBookingTerritory(newBookingList, null);
            
            isBeforeInsertTriggerCalled = true;
        }    
        
        //1.2 - Return static to previous state
        GBWire.WorkItemTriggerHandler.DisableWIRETriggers = previousState;

    }

    public void OnBeforeUpdate(List<Booking__c> newBookingList, Map<Id, Booking__c> newBookingMap, List<Booking__c> oldBookingList, Map<Id, Booking__c> oldBookingMap) {
        
        //1.2 - Disable WIRE triggers on Before Triggers
        Boolean previousState = GBWire.WorkItemTriggerHandler.DisableWIRETriggers;
        GBWire.WorkItemTriggerHandler.DisableWIRETriggers = true;
        
        if(!isbeforeUpdateTriggerCalled){
            //AP10_BookingTriggerBL.checkBookingForAdminTasksToClose(newBookingMap, oldBookingMap); <---1.8
                       
            //1.6 - Collate sorted lists for BL processing
            List<Booking__c> defaultBUBookings = new List<Booking__c>();
            //Loop through trigger records
            for(Booking__c b : newBookingList){
                if(b.Golfbreaks_Business_Unit__c == null || b.Booking_System__c == null){
                    defaultBUBookings.add(b);
                }
            }
            if(defaultBUBookings.size()>0){           
                //1.6 - Default Business Unit/Booking System
                AP10_BookingTriggerBL.setDefaultBusinessUnitAndBookingSystem(defaultBUBookings);
            }          
            //1.10 - Calculate the Territory based on BU & Sales Region
            //Note - must be after the Business Unit is set
            AP10_BookingTriggerBL.setBookingTerritory(newBookingList,oldBookingMap);  
            
            isbeforeUpdateTriggerCalled = TRUE;
        }
        
        //1.2 - Return static to previous state
        GBWire.WorkItemTriggerHandler.DisableWIRETriggers = previousState;
        
    }

    public void OnAfterInsert(List<Booking__c> newBookingList, Map<Id, Booking__c> newBookingMap, List<Booking__c> oldBookingList, Map<Id, Booking__c> oldBookingMap) {
        
        Integer delayInMinutes = 2;// <-- 1.13 (Length of delay in minute's)
        Boolean previousIsWIRECodeBlockedValue = WorkItemWIREActionIdentifier.isWIRECodeBlocked;//<--1.7
        
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        //1.3 - Disable WIRE triggers on Insert Trigger
        Boolean previousState = GBWire.WorkItemTriggerHandler.DisableWIRETriggers;
        GBWire.WorkItemTriggerHandler.DisableWIRETriggers = true;
        
        //1.1 - Retrieve lowest level 'Phased Code Removal' settings
        Phased_Code_Removal__c pcr = Phased_Code_Removal__c.getInstance();
        
        if(!isAfterInsertTriggerCalled){
            WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//<--1.7
            AP10_BookingTriggerBL.isTravelDateTodayAndCancelledBooking(newBookingList, new Map<Id, Booking__c>());
            
            //1.1 - Check the 'Disable Total Previous Bookings Calc' setting before executing
            if(pcr != null && !pcr.Disable_Total_Previous_Bookings_Calc__c){
                AP10_BookingTriggerBL.updateTotalPreviousBookingsOnLead(newBookingList);
            }
            
            AP10_BookingTriggerBL.updateOpportunityBookingAmount(null,newBookingList);//1.11~
            
            //Merari Cebrian - Added Update Amendment Case Status May 6, 2016
            /* 1.4 - Removing Ammendment Case Updates at Shane's request - 09/10/2018
             * AP10_BookingTriggerBL.updateAmendmentCaseStatus(newBookingList, oldBookingMap);*/

            DataEventTypeTriggerHandler dth = new DataEventTypeTriggerHandler(ApplicationConstant.OBJECT_TYPE_BOOKING);//1.12+
            dth.handleTriggerOperationType();//1.12+
            
            isAfterInsertTriggerCalled = TRUE; 
            WorkItemWIREActionIdentifier.isWIRECodeBlocked = previousIsWIRECodeBlockedValue;//<--1.7
         }
        
        //1.3 - Return static to previous state 
        GBWire.WorkItemTriggerHandler.DisableWIRETriggers = previousState;
        
        //1.5 - Evaluate Trigger records, identify and invoke required WIRE actions
        if(!WorkItemWIREActionIdentifier.isWIRECodeBlocked){//1.7+
            try{
                WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//1.7+
                Map<Id,GBWire.WorkItemWithActionsWrapper> WIREMap = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
                WIREMap = WorkItemWIREActionIdentifier.processWorkItems(null, newBookingMap, ApplicationConstant.OBJECT_TYPE_BOOKING);
                if(WIREMap != null && WIREMap.keySet().size()>0){ 
                    system.enqueueJob(new WorkItemWIREActionIdentifier.ExecuteWIREActionsQueueable(WIREMap,ApplicationConstant.OBJECT_TYPE_BOOKING), delayInMinutes);//1.9+ //1.13
                }
                WorkItemWIREActionIdentifier.isWIRECodeBlocked = previousIsWIRECodeBlockedValue; //1.7+
            }catch(exception e){
                system.debug('*** -- Exception: ' + e + ' at ' + e.getLineNumber() + ' -- ***');
                PlatformLogManager.logExceptions(e, 'AP09_BookingTriggerHandler', 'OnAfterInsert');
            }
        }          
    }

    public void OnAfterUpdate(List<Booking__c> newBookingList, Map<Id, Booking__c> newBookingMap, List<Booking__c> oldBookingList, Map<Id, Booking__c> oldBookingMap) {
            
        Boolean previousIsWIRECodeBlockedValue = WorkItemWIREActionIdentifier.isWIRECodeBlocked;//<--1.7
        
        List<Error_Log__c> logs = new List<Error_Log__c>();
        //AP10_BookingTriggerBL.checkAdminTask(newBookingMap, oldBookingMap); <----1.8    
        
        if(!isAfterUpdateTriggerCalled){
            WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//<--1.7           
            AP10_BookingTriggerBL.isTravelDateTodayAndCancelledBooking(newBookingList, oldBookingMap);
            AP10_BookingTriggerBL.updateOpportunityBookingAmount(oldBookingMap,newBookingList);//1.11~


            //Merari Cebrian - Added Update Amendment Case Status May 6, 2016
            /* 1.4 - Removing Ammendment Case Updates at Shane's request - 09/10/2018
            AP10_BookingTriggerBL.updateAmendmentCaseStatus(newBookingList, oldBookingMap);*/

            DataEventTypeTriggerHandler dth = new DataEventTypeTriggerHandler(ApplicationConstant.OBJECT_TYPE_BOOKING);//1.12+
            dth.handleTriggerOperationType();//1.12+
            
            isAfterUpdateTriggerCalled = TRUE;
            WorkItemWIREActionIdentifier.isWIRECodeBlocked = previousIsWIRECodeBlockedValue;//<--1.7
        }
        
        //1.5 - Evaluate Trigger records, identify and invoke required WIRE actions
        if(!WorkItemWIREActionIdentifier.isWIRECodeBlocked){//<--1.7
            WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//<---1.7
            Map<Id,GBWire.WorkItemWithActionsWrapper> WIREMap = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            WIREMap = WorkItemWIREActionIdentifier.processWorkItems(oldBookingMap, newBookingMap, ApplicationConstant.OBJECT_TYPE_BOOKING);
            if(WIREMap != null && WIREMap.keySet().size()>0){
                try{
                    GBWire.WorkItemUtility.executeWIRETriggerActions(WIREMap, ApplicationConstant.OBJECT_TYPE_BOOKING);
                }catch(exception e){
                    system.debug('*** -- Exception: ' + e + ' at ' + e.getLineNumber() + ' -- ***');
                    logs.add(ApplicationConstant.getExceptionLog(e, 'executeWIRETriggerActions', 'WorkItemUtility', null));
                }finally{
                    if(!logs.isEmpty()){ 
                        Database.insert(logs, false); 
                    }
                }
            }
            WorkItemWIREActionIdentifier.isWIRECodeBlocked = previousIsWIRECodeBlockedValue;//<--1.7
        }
    }

    public void OnBeforeDelete(List<Booking__c> newBookingList, Map<Id, Booking__c> newBookingMap, List<Booking__c> oldBookingList, Map<Id, Booking__c> oldBookingMap) {
        //1.2 - Disable WIRE triggers on Before Triggers
        Boolean previousState = GBWire.WorkItemTriggerHandler.DisableWIRETriggers;
        GBWire.WorkItemTriggerHandler.DisableWIRETriggers = true;
      
        //Add Trigger Code Here
      
        //1.2
        GBWire.WorkItemTriggerHandler.DisableWIRETriggers = previousState;  
    }

    public void OnAfterDelete(List<Booking__c> newBookingList, Map<Id, Booking__c> newBookingMap, List<Booking__c> oldBookingList, Map<Id, Booking__c> oldBookingMap) {
        
        //1.1 - Retrieve lowest level 'Phased Code Removal' settings
        Phased_Code_Removal__c pcr = Phased_Code_Removal__c.getInstance();
        
        if(!isAfterDeleteTriggerCalled){
            
            //1.1 - Check the 'Disable Total Previous Bookings Calc' setting before executing
            if(pcr != null && !pcr.Disable_Total_Previous_Bookings_Calc__c){
                AP10_BookingTriggerBL.updateTotalPreviousBookingsOnLead(oldBookingList);
            }
            
            isAfterDeleteTriggerCalled = TRUE;
        }
    }

    public void OnAfterUnDelete(List<Booking__c> newBookingList, Map<Id, Booking__c> newBookingMap, List<Booking__c> oldBookingList, Map<Id, Booking__c> oldBookingMap) {

    }

    public void OnUndelete(List<Booking__c> newBookingList, Map<Id, Booking__c> newBookingMap, List<Booking__c> oldBookingList, Map<Id, Booking__c> oldBookingMap) {
        //1.2 - Disable WIRE triggers on Before Triggers
        Boolean previousState = GBWire.WorkItemTriggerHandler.DisableWIRETriggers;
        GBWire.WorkItemTriggerHandler.DisableWIRETriggers = true;
      
        //Add Trigger Code Here 
      
        //1.2 - Return static to previous state
        GBWire.WorkItemTriggerHandler.DisableWIRETriggers = previousState;      
    }
}