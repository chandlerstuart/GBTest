/**
* Class Name: AP01_CaseTriggerHandlerTest
* @author: Emman Flores/Tristan Zantua/Ronald Martinez
* @date: 02.04.2016
* @description: Test Class for AP02_CaseTriggerBL
* 

History

Version   Author        Date        Detail
***************************************************
2.1       J Radcliffe   12-06-19    GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true (force Wire to retrieve valid routing configuration)
2.2       J Radcliffe   13-06-19    Removal of redundant test methods
2.3       J Radcliffe   13-06-19    New Test Methods - testSetDefaultsOnCaseInsert/testSetDefaultsOnCaseUpdate
*/

@isTest(seeAllData=false)
public class AP02_CaseTriggerBL_TEST {

    @testSetup static void setupData(){

        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//2.1

        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;

        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;

        //Create 5 Accounts
        insert AP23_TestDataFactory.createPersonAccount(5);

        //Create 5 Business Units, each with a territory
        List<Golfbreaks_Business_Unit__c> bus = AP23_TestDataFactory.createBusinessUnitsAndTerritories(5,1,true);
        List<Territory__c> territories = new List<Territory__c>();
        for(Golfbreaks_Business_Unit__c gbu : bus){
            territories.add(gbu.Territories__r);
        }
        system.assertEquals(5, territories.size());

        //Create an Opportunity for each Account (5)
        List<Opportunity> oppInsertList = new List<Opportunity>();
        for(Account acc : [Select Id From Account]){
            Opportunity o = AP23_TestDataFactory.createOpportunity(1, 'Test Stage', acc)[0];
            //Randomly apply a TerritoryId
            Integer index = (Integer)(Math.random()*5);
            o.Territory__c = territories[index].Id;
            o.Golfbreaks_Business_Unit__c = territories[index].BusinessUnit__c;
            oppInsertList.add(o);
        }
        system.assertEquals(5, oppInsertList.size());
        insert oppInsertList;

        //Create a Booking for each Opportunity and Account (5)
        List<Booking__c> bookingInsertList = new List<Booking__c>();
        for(Opportunity opp : [Select Id, AccountId From Opportunity]){
            bookingInsertList.add(AP23_TestDataFactory.createBooking(1, opp.AccountId, opp.Id)[0]);
        }
        system.assertEquals(5, bookingInsertList.size());
        insert bookingInsertList;

        /*2.2
        //Create Account
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        database.insert(acc);

        //Create Opportunity
        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, 'stage name', acc)[0];
        database.insert(opp);
        
        
        //Create Entitlement
        List<Entitlement> ent = AP23_TestDataFactory.createEntitlement(2, acc);
        database.insert(ent);
        
        RecordType caseRec = [SELECT Id FROM RecordType WHERE DeveloperName =: ApplicationConstant.CASE_RECORD_TYPE_AMENDMENT AND SObjectType = 'Case' LIMIT 1];
        LeadScoringRule__c lsr = new LeadScoringRule__c(FieldLabel__c = 'Case Status', RecordType__c = String.ValueOf(caseRec.Id), 
                                                        Active__c = TRUE, Operator__c = 'equals', Value__c = 'Open', Points__c = 5);
        insert lsr;
        
        LeadScoreMapping__c lsm = new LeadScoreMapping__c(RuleType__c = 'Case', LeadScoreMaximumValue__c = 10, LeadScoreMinimumValue__c = 0, CasePriority__c = 'P1');
        insert lsm; */
    }

    //2.3
    //This method verifies the Account, Opportunity and Territory Id are applied to Cases on insert
    //It also confirms that if an Account is explicitly set, it is not overwritten
    static testMethod void testSetDefaultsOnCaseInsert(){
        
        //Retrieve existing Bookings
        Booking__c[] bookings = [Select Id, Account__c, TECH_Opportunity__c, Territory__c From Booking__c];
        for(Booking__c b : bookings){
            system.assertNotEquals(null, b.Account__c);
            system.assertNotEquals(null, b.TECH_Opportunity__c);
            system.assertNotEquals(null, b.Territory__c);
        }
        system.assertEquals(5, bookings.size());

        Id serviceCaseRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(ApplicationConstant.CASE_RECORD_TYPE_SERVICE_CASE).getRecordTypeId();

        //Create 100 cases randomly distributed accross bookings
        List<Case> newCases = new List<Case>();
        for(integer i=0;i<100;i++){
            Case c = new Case();
            c.Subject = 'Test Case '+i;
            c.Booking__c = bookings[(Integer)(Math.random()*5)].Id;
            c.RecordTypeId = serviceCaseRTId;
            newCases.add(c);
        }
        
        test.startTest();
            insert newCases;
        test.stopTest();

        //Block WIRE Actions for subsequent processing
        WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;

        for(Case c : [Select Id, AccountId, Booking__r.Account__c, Territory__c, Booking__r.Territory__c, Opportunity__c, Booking__r.TECH_Opportunity__c From Case]){
            system.assertEquals(c.Booking__r.Account__c, c.AccountId);
            system.assertNotEquals(null, c.AccountId);
            system.assertEquals(c.Booking__r.TECH_Opportunity__c, c.Opportunity__c);
            system.assertNotEquals(null, c.Opportunity__c);
            system.assertEquals(c.Booking__r.Territory__c, c.Territory__c);
            system.assertNotEquals(null, c.Territory__c);
        }

        //Create a new Account
        Account newAcc = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert newAcc;

        //Confirm the Account is not overwritten if set the new Account on insert (even if it does not match the Account on the Booking)
        Case c = new Case();
        c.Subject = 'Test Case - Not Lead Booker';
        c.Booking__c = bookings[(Integer)(Math.random()*5)].Id;
        c.RecordTypeId = serviceCaseRTId;
        c.AccountId = newAcc.Id;
        //Reset static recursion variables
        AP01_CaseTriggerHandler.isAfterInsertTriggerCalled = false;
        AP01_CaseTriggerHandler.isBeforeInsertTriggerCalled = false;
        insert c;

        Case cAfterInsert = [Select Id, AccountId, Booking__r.Account__c, Territory__c, Booking__r.Territory__c, Opportunity__c, Booking__r.TECH_Opportunity__c From Case Where Id = :c.Id][0];
        system.assertNotEquals(cAfterInsert.Booking__r.Account__c, cAfterInsert.AccountId);
        system.assertNotEquals(null, c.AccountId);
        system.assertEquals(newAcc.Id, cAfterInsert.AccountId);       

    }

    //2.3
    //This method verifies the Account, Opportunity and Territory Id are reset if the Booking is changed on the Case
    static testMethod void testSetDefaultsOnCaseUpdate(){
        //Retrieve existing Bookings
        Booking__c[] bookings = [Select Id, Account__c, TECH_Opportunity__c, Territory__c From Booking__c];
        for(Booking__c b : bookings){
            system.assertNotEquals(null, b.Account__c);
            system.assertNotEquals(null, b.TECH_Opportunity__c);
            system.assertNotEquals(null, b.Territory__c);
        }
        system.assertEquals(5, bookings.size());

        Id serviceCaseRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(ApplicationConstant.CASE_RECORD_TYPE_SERVICE_CASE).getRecordTypeId();

        //Create 20 cases randomly distributed accross bookings
        List<Case> newCases = new List<Case>();
        for(integer i=0;i<20;i++){
            Case c = new Case();
            c.Subject = 'Test Case '+i;
            c.Booking__c = bookings[(Integer)(Math.random()*5)].Id;
            c.RecordTypeId = serviceCaseRTId;
            newCases.add(c);
        }
        
        insert newCases;

        //Requery Cases
        Case[] casesAfterInsert = [Select Id, Booking__c From Case];
        system.assertEquals(20, casesAfterInsert.size());

        //Re-assign Case Bookings at random
        for(Case c : casesAfterInsert){
            c.Booking__c = bookings[(Integer)(Math.random()*5)].Id;
        }

        test.startTest();
            //Reset static recursion variables
            AP01_CaseTriggerHandler.isAfterUpdateTriggerCalled = false;
            AP01_CaseTriggerHandler.isBeforeUpdateTriggerCalled = false;
            update casesAfterInsert;
        test.stopTest();

        //Confirm all Case details match the (new) parent Booking details
        for(Case c : [Select Id, AccountId, Booking__r.Account__c, Territory__c, Booking__r.Territory__c, Opportunity__c, Booking__r.TECH_Opportunity__c From Case]){
            system.assertEquals(c.Booking__r.Account__c, c.AccountId);
            system.assertNotEquals(null, c.AccountId);
            system.assertEquals(c.Booking__r.TECH_Opportunity__c, c.Opportunity__c);
            system.assertNotEquals(null, c.Opportunity__c);
            system.assertEquals(c.Booking__r.Territory__c, c.Territory__c);
            system.assertNotEquals(null, c.Territory__c);
        }
        

    }

    /* 2.2
    static testMethod void testAP02_CaseTriggerBL_PopulateAccount(){

        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//2.1

        List<Account> accList = [Select Id from Account LIMIT 1];
        List<Opportunity> oppList = [Select id from Opportunity LIMIT 1];

        List<Booking__c> bookingList = AP23_TestDataFactory.createBooking(1, accList[0].Id, oppList[0].Id);
        insert bookingList;
        
        //create case
        List<Case> cases = AP23_TestDataFactory.createCase(1, accList[0]);
        for(Case c: cases){
            c.RecordTypeId = ApplicationConstant.CASERECTYPEID_AMENDMENT;
            c.Opportunity__c = oppList[0].Id;
            c.Reminder_Event__c = true;
            c.RequestedCallBackDateAndTime__c = null;
            c.OwnerId = UserInfo.getUserId();
            c.Booking__c = bookingList[0].Id;
            c.Subject = 'Test Case';
        }

        database.insert(cases);

        test.startTest();

        AP02_CaseTriggerBL.populateAccountandOppbyBookingId(cases, null);

        test.stopTest();
    }*/


    /*2.2
    static testMethod void testAP02_CaseTriggerBL_Insert(){

        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//2.1

        List<Account> accList = [Select Id from Account LIMIT 1];
        List<Opportunity> oppList = [Select id from Opportunity LIMIT 1];
        
        //create case
        List<Case> cases = AP23_TestDataFactory.createCase(200, accList[0]);
        for(Case c: cases){
            c.RecordTypeId = ApplicationConstant.CASERECTYPEID_AMENDMENT;
            c.Opportunity__c = oppList[0].Id;
            c.Reminder_Event__c = true;
            c.RequestedCallBackDateAndTime__c = date.today();
            c.Subject = 'Test Case';
        }
        
        List<Event> evntList = AP23_TestDataFactory.createEvent(2, cases[0]);
        database.insert(evntList);
        
        Map<Id, Case> oldCaseMap = new Map<Id, Case>([SELECT Id FROM Case]);

        test.startTest();
        
            database.insert(cases);

        test.stopTest();
        List<Case> lCase = [SELECT Id, Priority, CaseScoreAppliedDate__c, Points__c FROM Case LIMIT 200];
        
        for(Case cs: lCase){
            System.AssertEquals(cs.Priority, 'P1');
            System.AssertEquals(cs.Points__c, 5);
            System.AssertEquals(cs.CaseScoreAppliedDate__c, Date.today());
        }

    }*/   

    /*2.2
    //Test bulk cases and case scoring.
    static testMethod void testAP02_CaseTriggerBL_Schedule() {

        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//2.1

        List<Account> accList = [Select Id from Account LIMIT 1];
        List<Opportunity> oppList = [Select id from Opportunity LIMIT 1];
        
        //create case
        List<Case> cases = AP23_TestDataFactory.createCase(200, accList[0]);
        for(Case c: cases){
            c.RecordTypeId = ApplicationConstant.CASERECTYPEID_AMENDMENT;
            c.Opportunity__c = oppList[0].Id;
            c.Reminder_Event__c = true;
            c.RequestedCallBackDateAndTime__c = date.today();
            c.Subject = 'Test Case';
        }

        database.insert(cases);
        
        test.startTest();
        
            AP02_CaseTriggerBL.ScheduleReAssigningQueue();
            
        test.stopTest();  
    }*/
        
    /* 2.2    
    static testMethod void testAP02_CaseTriggerBL_EventTest() {

        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//2.1

        List<Account> accList = [Select Id from Account LIMIT 1];
        List<Opportunity> oppList = [Select id from Opportunity LIMIT 1];
        
        //create case
        List<Case> cases = AP23_TestDataFactory.createCase(1, accList[0]);
        for(Case c: cases){
            c.RecordTypeId = ApplicationConstant.CASERECTYPEID_AMENDMENT;
            c.Opportunity__c = oppList[0].Id;
            c.Reminder_Event__c = true;
            //c.RequestedCallBackDateAndTime__c = date.today().addDays(1);
            c.RequestedCallBackDateAndTime__c = system.now().addDays(1);
            c.OwnerId = UserInfo.getUserId();
            c.Subject = 'Test Case';
        }

        database.insert(cases);
        
        //List<Event> evntList = AP23_TestDataFactory.createEvent(1, cases[0]);
        //database.insert(evntList);
        
        Map<Id, Case> oldCaseMap = new Map<Id, Case>([SELECT Id, RequestedCallBackDateAndTime__c FROM Case]);
        for (Case c : oldCaseMap.values()){
            //c.RequestedCallBackDateAndTime__c = date.today();
            c.RequestedCallBackDateAndTime__c = system.now();
        }
            
        //List<Case> lCase = [SELECT Id, Priority, CaseScoreAppliedDate__c, Points__c FROM Case LIMIT 200];
        Map<Id, Case> newCaseMap = new Map<Id, Case>();
            
        for(Case c: cases){
            newCaseMap.put(c.Id, c);
        }
        List<Event> eventList = new List<Event>();

        Event inEvent = new Event();            
        inEvent.WhoId = null;
        inEvent.WhatId = cases[0].Id;
        inEvent.DurationInMinutes = 1;
        inEvent.ActivityDateTime = System.now().addDays(1);
        inEvent.Subject = 'Call Back Request';  
        inEvent.Call_Back_Date_and_Time_Activity__c = System.today().addDays(1);
        inEvent.ActivityDate = System.today().addDays(1);
        inEvent.Call_Notes__c = 'abc';
        inEvent.Description = 'description';
        eventList.add(inEvent);

        insert eventList;

        test.startTest();
        
            AP02_CaseTriggerBL.createUpdateEvent(newCaseMap, oldCaseMap);

        test.stopTest();  
    }*/


    /* 2.2
    static testMethod void testAP02_CaseTriggerBL_EventDeleteTest() {

        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//2.1

        List<Account> accList = [Select Id from Account LIMIT 1];
        List<Opportunity> oppList = [Select id from Opportunity LIMIT 1];
        
        //create case
        List<Case> cases = AP23_TestDataFactory.createCase(1, accList[0]);
        for(Case c: cases){
            c.RecordTypeId = ApplicationConstant.CASERECTYPEID_AMENDMENT;
            c.Opportunity__c = oppList[0].Id;
            c.Reminder_Event__c = true;
            c.RequestedCallBackDateAndTime__c = null;
            c.OwnerId = UserInfo.getUserId();
            c.Subject = 'Test Case';
        }

        database.insert(cases);
        
        //List<Event> evntList = AP23_TestDataFactory.createEvent(1, cases[0]);
        //database.insert(evntList);
        
        Map<Id, Case> oldCaseMap = new Map<Id, Case>([SELECT Id, RequestedCallBackDateAndTime__c FROM Case]);
        for (Case c : oldCaseMap.values()){
            c.RequestedCallBackDateAndTime__c = date.today().addDays(1);
        }
            
        //List<Case> lCase = [SELECT Id, Priority, CaseScoreAppliedDate__c, Points__c FROM Case LIMIT 200];
        Map<Id, Case> newCaseMap = new Map<Id, Case>();
            
        for(Case c: cases){
            newCaseMap.put(c.Id, c);
        }

        Event inEvent = new Event();            
        inEvent.WhoId = null;
        inEvent.WhatId = cases[0].Id;
        inEvent.DurationInMinutes = 1;
        inEvent.ActivityDateTime = System.now().addDays(1);
        inEvent.Subject = 'Call Back Request';  
        inEvent.Call_Back_Date_and_Time_Activity__c = System.today().addDays(1);
        inEvent.ActivityDate = System.today().addDays(1);
        inEvent.Call_Notes__c = 'abc';
        inEvent.Description = 'description';
        insert inEvent;

        test.startTest();
        
            AP02_CaseTriggerBL.createUpdateEvent(newCaseMap, oldCaseMap);

        test.stopTest();  
    }*/

       
}