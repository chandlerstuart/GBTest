/*
   @Author: Bhushan Sukumar
   @CreateDate: 13 May 2016
   @Description: Test class for validating Booking Trigger BL class

History
------- 
Ver. Author        Date        Detail
1.1  J.Radcliffe   2018-10-09  Removing tests for updateAmendmentCaseStatus method. Functionality being removed at Shane's request
1.2  J.Radcliffe   2018-10-16  Force the use of non-test Routing Configurations.
1.3  J.Radcliffe   2018-11-09  New Test Method - testSetDefaultBusinessUnit - Asserts the Business Unit is retrieved from the Opportunity (or the default is set) when the Booking is inserted/updated and the BU is null
1.4  Mark Cane&    2018-11-12  Add testSetup block for WIRE calculations on test data - reduced test workload.
1.5  J.Radcliffe   2018-12-18  Removing invocation of Admin Case Test Development
1.6  J.Radcliffe   2019-05-30  Confirm Territory is retrieved from Opp on insert/update
1.7  J.Radcliffe   2019-07-15  Replacing 1.6 with new method - testSetBookingTerritory
*/
@isTest (seeAllData = FALSE)
private class AP10_BookingTriggerBL_Test {

    ////////////////////
    //Test Data Setup //
    ////////////////////

    @testSetup static void setupTestData(){ 
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2
        
        WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//<-- 1.4 block WIRE calculations for test data.
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
        
        //Allow the current running test user to insert Client accounts        
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        
        //creating test accounts
        List<Account> accs = new List<Account>();
        accs.addAll(AP23_TestDataFactory.createPersonAccount(5));
        insert accs;

        //creating test contacts
      /*  List<Contact> cons = new List<Contact>();
        for (Account acc : accs) {
            cons.addAll(AP23_TestDataFactory.createContactList(5, acc));
        }
        insert cons;*/

        //creating Leads
        List<Lead> testLeads = AP23_TestDataFactory.createLead(5);
        insert testLeads;

        //creating opportunities
        //retreiving opp sales stages
        
        // 1.4 Commented out to mitigate CPU timeouts with 185 opportunities (plus B,EP, L and C records).
        //Set<String> oppStages = new Set<String>();
        //Schema.DescribeFieldResult f = Opportunity.StageName.getDescribe();
        //List<Schema.PicklistEntry> p = f.getPicklistValues();
        List<Opportunity> opps = new List<Opportunity>();
        //for (Schema.PicklistEntry pe : p) {
            for (Account acc : accs) {
                opps.addAll(AP23_TestDataFactory.createOpportunity(1, ApplicationConstant.RECOMMENDATIONSTAGE, acc));                
            }
        //}
        // for(Opportunity o : opps){
        //     o.Accepted_Tier__c = 'Tier 1';
        //     o.Tier_1_Budget__c = 10000;
        //     o.Opportunity_Invoice_Date__c  = Date.Today();
        //     o.Payment_Date__c = Date.today() + 5;
        //     o.Payment_Frequency__c = 'Monthly';
        //     o.Payment_Type__c = 'Cash';
        //     o.Invoice_Date__c = Date.Today();
        //     o.Invoice_Number__c = '1234';
        // }
        insert opps;

        //creating bookings
        List<Booking__c> bookings = new List<Booking__c>();
        for (Opportunity opp : opps) {
            bookings.addAll(AP23_TestDataFactory.createBooking(1, opp.AccountId, opp.id));
        }
        for(Booking__c b : bookings){
            b.AgentAttentionRequired__c = true;
        }
        insert bookings;
 
        //Creating expected payments
        List<Expected_Payment__c> expPayments = new List<Expected_Payment__c>();
        for (Booking__c book : bookings) {
            expPayments.addAll(
                AP23_TestDataFactory.createExpectedPayment(
                    1, book, ApplicationConstant.EPAYMENTTYPEFULLDEPOSIT, 2838));
        }
        insert expPayments;

        //creating booking leads
        List<Lead> bookingLeads = new List<Lead>();
        for (Booking__c booking : bookings) {
            bookingLeads.addAll(AP23_TestDataFactory.createLead(1, booking.Account__c));
        }
        insert bookingLeads;

        //create booking cases

        List<Case> caseList = new List<Case>();
        for (Booking__c booking : bookings) {
            caseList.addAll(AP23_TestDataFactory.createCase(1, booking.Account__c, booking.id));
        }
        for (Case c : caseList){
          c.RecordTypeId = ApplicationConstant.CASERECTYPEID_SERVICECASE;
        }
        insert caseList;
    }

    /////////////////
    //Test Methods //
    /////////////////


    /**
     * test method to validate the booking amount on the Opportunity matches with the last
     * booking record created
     * @author  Bhushan Sukumar
     * @date    13 May 2016
     */
        @isTest
    static void test_updateOpportunityBookingAmount() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2
        
        //querying test opportunities
        List<Opportunity> opps = [SELECT Id,
                                  Name,
                                  AccountId
                                  FROM Opportunity
                                  WHERE CreatedDate = TODAY];
        List<Booking__c> bookingsToInsert = new List<Booking__c>();
        //looping through each oppty and setting a new booking to test the insert trigger event
        for (Opportunity opp : opps) {
            bookingsToInsert.addAll(
                AP23_TestDataFactory.createBooking(2, opp.AccountId, opp.Id));
        }

        

        //setting the trigger active flag
        OrgSettings__c orgSetting = new OrgSettings__c();
        orgSetting.TriggersActive__c = true;
        insert orgSetting;

        //running as Admin user.
        //TODO: Not sure if this should be Admin user, we need to run as the intended user
        List<User> adminUser = [SELECT Id,
                                Name
                                FROM User
                                WHERE Profile.Name = : ApplicationConstant.PROFILE_SYSADMIN
                                        AND IsActive = TRUE];
        
        System.runAs(adminUser[0]) {
            for (Integer i = 0 ; i < bookingsToInsert.size() ; i++) {
                bookingsToInsert[i].Sale_Price_Gross__c = bookingsToInsert[i].Sale_Price_Gross__c + (i * 10);
            }
            insert bookingsToInsert;
        }

        List<Opportunity> opptys = [SELECT Id,
                                    BookingAmount__c
                                    FROM Opportunity
                                    WHERE Id = : bookingsToInsert[0].TECH_Opportunity__c];
        Test.startTest();

        //Opportunity booking amount should NOT be same as the first booking related to the oppty
        if (!opptys.isEmpty() && bookingsToInsert[0].TECH_Opportunity__c == opptys[0].id) {
            System.assertNotEquals(bookingsToInsert[0].Sale_Price_Gross__c,
                                   opptys[0].BookingAmount__c);
        }

        //opportunity booking should be the same as the last booking inserted against the oppty
        for (Integer i = 0 ; i < bookingsToInsert.size() ; i++) {
            if (i == bookingsToInsert.size() - 1 &&
                    bookingsToInsert[i].TECH_Opportunity__c == opptys[0].id) {
                System.assertEquals(bookingsToInsert[i].Sale_Price_Gross__c,
                                    opptys[0].BookingAmount__c); 
            }
        }

        Test.stopTest();
    }
    

    /**
     * test method to validate if the booking status and the opprotunity stages are updated as
     * per the Travel Date or booking status on the related booking records
     * @author  Bhushan Sukumar
     * @date    13 May 2016
     */
     
    @isTest
    static void test_isTravelDateTodayAndCancelledBooking() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2
        
        Set<Id> oppIds = new Set<Id>();
        //querying test opportunities created as test setup
        List<Opportunity> opps = [SELECT Id,
                                  Name,
                                  AccountId,
                                  StageName,
                                  (SELECT Id,
                                   TravelReturnDate__c,
                                   TECH_Opportunity__c,
                                   Travel_Date__c,
                                   Nights__c,
                                   Status__c
                                   FROM Bookings__r
                                   ORDER BY CreatedDate DESC LIMIT 1)
                                  FROM Opportunity
                                  WHERE CreatedDate = TODAY LIMIT 2];
        List<Booking__c> bookingsToUpdate = new List<Booking__c>();
        for (Opportunity opp : opps) {
            bookingsToUpdate.addAll(opp.Bookings__r);
        }

        //logic to make the TravelReturnDate on the booking to be today
        for (Booking__c booking : bookingsToUpdate) {
            booking.Travel_Date__c = Date.today() - 1;
            booking.Nights__c = 1;
            oppIds.add(booking.TECH_Opportunity__c);
        }

        Test.startTest();

        OrgSettings__c orgSetting = new OrgSettings__c();
        orgSetting.TriggersActive__c = true;
        insert orgSetting;

        //TODO: Not sure if this should be Admin user, we need to run as the intended user
        List<User> adminUser = [SELECT Id,
                                Name
                                FROM User
                                WHERE Profile.Name = : ApplicationConstant.PROFILE_SYSADMIN
                                        AND IsActive = TRUE];
        System.runAs(adminUser[0]) {
            update bookingsToUpdate;
        }

        List<Opportunity> opptys = [SELECT Id, StageName FROM Opportunity WHERE ID IN : oppIds];
        //Asserting stage
        for (Opportunity opp : opptys) {
            System.assertEquals(ApplicationConstant.CUSTOMERACCEPTEDSTAGE,opp.StageName);
        }

        //updating the status to Cancelled, to trigger the change on the related opportunity
        for (Booking__c booking : bookingsToUpdate) {
            booking.Status__c = ApplicationConstant.BOOKING_STATUS_CANCELLED;
        }

        //TODO: Not sure if this should be Admin user, we need to run as the intended user
        System.runAs(adminUser[0]) {
            update bookingsToUpdate;
        }

        opptys = [SELECT Id, StageName FROM Opportunity WHERE ID IN : oppIds];
        for (Opportunity opp : opptys) {
            //System.assertEquals(opp.StageName, ApplicationConstant.OPP_STAGE_CANCELLED);
        }

        Test.stopTest();
    }
    
    static testMethod void testException(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2
        
        /* 1.1 - Removing Ammendment Case Updates at Shane's request - 09/10/2018
        AP10_BookingTriggerBL.updateAmendmentCaseStatus(null, null);*/
        AP10_BookingTriggerBL.isTravelDateTodayAndCancelledBooking(null, null);
        AP10_BookingTriggerBL.updateTotalPreviousBookingsOnLead(null);
        AP10_BookingTriggerBL.updateOpportunityBookingAmount(null,null);
        //AP10_BookingTriggerBL.checkAdminTask(null, null); <--- 1.5
        
        List<Error_Log__c> logs = [SELECT Id FROM Error_Log__c];
        System.AssertEquals(logs.size(), 1);
    }
    
    
    static testMethod void testCaseClosed(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2
        
        OrgSettings__c orgSetting = new OrgSettings__c();
        orgSetting.TriggersActive__c = true;
        insert orgSetting;
        
        Booking__c bkg = [SELECT Id, AgentAttentionRequired__c, WaitingOnSupplier__c FROM Booking__c LIMIT 1];
        bkg.AgentAttentionRequired__c = TRUE;
        update bkg;
        Case cas = [SELECT Id, IsClosed, Status, AccountableforIssue__c, CustomerSatisfaction__c, ClosedSubStatus__c, Booking__c FROM Case WHERE Booking__c =: bkg.Id LIMIT 1];
        cas.Status = ApplicationConstant.CASESTATUS_NEW;
        update cas;
        Test.startTest();
        bkg.AgentAttentionRequired__c = FALSE;
        bkg.WaitingOnSupplier__c = FALSE;
        update bkg;
        
        Case UpdCase = [SELECT Id, IsClosed, Status, AccountableforIssue__c, CustomerSatisfaction__c, ClosedSubStatus__c, Booking__c FROM Case WHERE Id =: cas.Id LIMIT 1];
        // System.AssertEquals(UpdCase.Status, ApplicationConstant.CASE_STATUS_CLOSED);
        // System.AssertEquals(UpdCase.AccountableforIssue__c, ApplicationConstant.CASE_ACCOUNTABLE_FOR_ISSUE_NONE);
        // System.AssertEquals(UpdCase.CustomerSatisfaction__c, ApplicationConstant.CASE_CUSTOMER_SATISFACTION_NA);
        // System.AssertEquals(UpdCase.ClosedSubStatus__c, ApplicationConstant.CASE_CLOSED_SUBSTATUS_ACCEPTED);
        Test.stopTest();
    }
 
    static testMethod void TravelDateTodayTripCompletedInsert(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2
        
        OrgSettings__c orgSetting = new OrgSettings__c();
        orgSetting.TriggersActive__c = true;
        insert orgSetting; 
        
        Opportunity opp = [SELECT Id, StageName, AccountId FROM Opportunity LIMIT 1];
        
        Test.startTest();            
        Booking__c bkg = new Booking__c(Account__c = opp.AccountId, TECH_Opportunity__c = opp.Id, Travel_Date__c = System.Today() - 2, Nights__c = 2, Status__c = 'New');
        insert bkg;
        
        Opportunity Updopp = [SELECT Id, StageName FROM Opportunity WHERE Id =: bkg.TECH_Opportunity__c LIMIT 1];
        System.AssertEquals(ApplicationConstant.CUSTOMERACCEPTEDSTAGE,Updopp.StageName);
        Test.stopTest();   
    }

    static testMethod void TravelDateTodayTripCancelledInsert(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2
        
        OrgSettings__c orgSetting = new OrgSettings__c();
        orgSetting.TriggersActive__c = true;
        insert orgSetting; 
        
        Opportunity opp = [SELECT Id, StageName, AccountId FROM Opportunity LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();            
        Booking__c bkg = new Booking__c(Account__c = opp.AccountId, TECH_Opportunity__c = opp.Id, Travel_Date__c = System.Today() - 2, Nights__c = 2, Status__c = ApplicationConstant.BOOKING_STATUS_CANCELLED);
        insert bkg;
        
        Opportunity Updopp = [SELECT Id, StageName FROM Opportunity WHERE Id =: bkg.TECH_Opportunity__c LIMIT 1];
        System.AssertEquals(ApplicationConstant.CUSTOMERACCEPTEDSTAGE,Updopp.StageName);
        Test.stopTest();   
    }
    
    static testMethod void TravelDateTodayTripCancelledUpdate(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2
        
        OrgSettings__c orgSetting = new OrgSettings__c();
        orgSetting.TriggersActive__c = true;
        insert orgSetting; 
        
        Opportunity opp = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        
        Booking__c bkg = [SELECT Id, TECH_Opportunity__c, TravelReturnDate__c, Status__c, Travel_Date__c, Nights__c FROM Booking__c WHERE TECH_Opportunity__c =: opp.Id LIMIT 1];
        bkg.Travel_Date__c = System.Today() - 2;
        bkg.Nights__c = 1;
        bkg.Status__c = 'New';
        update bkg;
        
        Test.startTest();
        bkg.Status__c = ApplicationConstant.BOOKING_STATUS_CANCELLED;
        update bkg;
        
        Opportunity Updopp = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        //System.AssertEquals(Updopp.StageName, ApplicationConstant.OPP_STATUS_CANCELLED);
        Test.stopTest();   
    }

   
    static testMethod void TravelDateTodayTripCompletedUpdate(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2
        
        OrgSettings__c orgSetting = new OrgSettings__c();
        orgSetting.TriggersActive__c = true;
        insert orgSetting; 
        
        Opportunity opp = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        
        Booking__c bkg = [SELECT Id, TECH_Opportunity__c, TravelReturnDate__c, Status__c, Travel_Date__c, Nights__c FROM Booking__c WHERE TECH_Opportunity__c =: opp.Id LIMIT 1];
        bkg.Travel_Date__c = System.Today() - 2;
        bkg.Nights__c = 1;
        bkg.Status__c = 'New';
        update bkg;
        
        Test.startTest();
        bkg.Nights__c = 2;
        update bkg;
        
        Opportunity Updopp = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        //System.AssertEquals(Updopp.StageName, ApplicationConstant.OPP_STAGE_TRIPCOMPLETED);
        Test.stopTest();   
    }
    
    /**
     * test method to check if the 'Total Number of Previous bookings' is populated as per
     * requirement when a new booking is created againsts the Account.
     * @author  Bhushan Sukumar
     * @date    13 May 2016
     */
     
    @isTest
    static void test_updateTotalPreviousBookingsOnLead() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2
        
        OrgSettings__c orgSetting = new OrgSettings__c();
        orgSetting.TriggersActive__c = true;
        insert orgSetting;

        //TODO: Not sure if this should be Admin user, we need to run as the intended user
        List<User> adminUser = [SELECT Id,
                                Name
                                FROM User
                                WHERE Profile.Name = : ApplicationConstant.PROFILE_SYSADMIN
                                        AND IsActive = TRUE];

        List<Lead> leads = [SELECT Id,
                            Account__c,
                            TotalPreviousBookings__c
                            FROM Lead
                            WHERE Account__c != '' LIMIT 10];

        Test.startTest();
        List<Booking__c> newBookings = new List<Booking__c>();
        Set<Id> accIds = new Set<Id>();
        System.runAs(adminUser[0]) {
            for (Lead l : leads) {
                newBookings.addAll(AP23_TestDataFactory.createBooking(leads.size(), l.Account__c, null));
                accIds.add(l.Account__c);
            }

            for (Lead l : leads) {
                for (Booking__c book : newBookings) {
                    if (book.Account__c == l.Account__c) {
                        book.Lead__c = l.id;
                    }
                }
            }

            insert newBookings;
        }
        //List<Lead> updatedLeads = ];
        //AggregateResult[] totalBookings = [SELECT Account__c acctId,
        //                                   Count(Id) totalBooks
        //                                   FROM Booking__c
        //                                   WHERE Account__c IN : accIds
        //                                   AND Lead__r.Account__c != ''
        //                                   GROUP BY Account__c];
        Map<Id, Integer> accountIdTotalBooks = new Map<Id, Integer>();

        //test to make sure the number of previous booking number matches the number of bookings
        //against the account via leads
        for (AggregateResult ar : [SELECT Account__c acctId,
                                           Count(Id) totalBooks
                                           FROM Booking__c
                                           WHERE Account__c IN : accIds
                                           AND Lead__r.Account__c != ''
                                           GROUP BY Account__c]) {
            accountIdTotalBooks.put((Id)ar.get('acctId'), (Integer) ar.get('totalBooks'));
        }

        for (Lead l : [SELECT Id,Account__c,
                                   TotalPreviousBookings__c
                                   FROM Lead
                                   WHERE Account__c != '']) {
            if (accountIdTotalBooks.containsKey(l.Account__c)) {
                System.assertEquals(l.TotalPreviousBookings__c,
                                    accountIdTotalBooks.get(l.Account__c));
            }
        }
        Test.stopTest();
    }
    
    /**
     * Simple bulk testing of booking insertion.
     * @author  Bhushan Sukumar
     * @date    13 May 2016
     */
     
    @isTest
    static void test_BulkTestBookingInsert() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2
        
        OrgSettings__c orgSetting = new OrgSettings__c();
        orgSetting.TriggersActive__c = true;
        insert orgSetting;

        //TODO: Not sure if this should be Admin user, we need to run as the intended user
        List<User> adminUser = [SELECT Id,
                                Name
                                FROM User
                                WHERE Profile.Name = : ApplicationConstant.PROFILE_SYSADMIN
                                        AND IsActive = TRUE LIMIT 1];

        List<Account> existingAccs = [SELECT Id,
                                      Name,
                                      (SELECT Id,
                                       Name
                                       FROM Opportunities)
                                      FROM Account
                                      WHERE CreatedDate = TODAY];
        List<Booking__c> bookingsToInsert = new List<Booking__c>();
        for (Account acc : existingAccs) {
            if (!acc.Opportunities.isEmpty()) {
                bookingsToInsert.addAll(
                    AP23_TestDataFactory.createBooking(10, acc.Id, acc.Opportunities[0].id));// size dropped from 20=>10
            }
        }
        Test.startTest();
        System.runAs(adminUser[0]) {
            insert bookingsToInsert;
        }
        Test.stopTest();
    }
    
    /**
     * test method to check if the 'Total Number of Previous bookings' is populated as per
     * requirement when a new booking is created againsts the Account.
     * @author  Bhushan Sukumar
     * @date    13 May 2016
     */
     
    @isTest
    static void test_deleteTotalPreviousBookingsOnLead() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2
        
        OrgSettings__c orgSetting = new OrgSettings__c();
        orgSetting.TriggersActive__c = true;
        insert orgSetting;

        //TODO: Not sure if this should be Admin user, we need to run as the intended user
        List<User> adminUser = [SELECT Id,
                                Name
                                FROM User
                                WHERE Profile.Name = : ApplicationConstant.PROFILE_SYSADMIN
                                        AND IsActive = TRUE];

        List<Lead> leads = [SELECT Id,
                            Account__c,
                            TotalPreviousBookings__c
                            FROM Lead
                            WHERE Account__c != '' LIMIT 10];

        
        List<Booking__c> newBookings = new List<Booking__c>();
        Set<Id> accIds = new Set<Id>();
        System.runAs(adminUser[0]) {
            for (Lead l : leads) {
                newBookings.addAll(AP23_TestDataFactory.createBooking(leads.size(), l.Account__c, null));
                accIds.add(l.Account__c);
            }

            for (Lead l : leads) {
                for (Booking__c book : newBookings) {
                    if (book.Account__c == l.Account__c) {
                        book.Lead__c = l.id;
                    }
                }
            }

            insert newBookings;
        }

        Test.startTest();

        delete newBookings;
        //List<Lead> updatedLeads = ];
        AggregateResult[] totalBookings = [SELECT Account__c acctId,
                                           Count(Id) totalBooks
                                           FROM Booking__c
                                           WHERE Account__c IN : accIds
                                           AND Lead__r.Account__c != ''
                                           GROUP BY Account__c];
        Map<Id, Integer> accountIdTotalBooks = new Map<Id, Integer>();

        //test to make sure the number of previous booking number matches the number of bookings
        //against the account via leads
        for (AggregateResult ar : totalBookings) {
            accountIdTotalBooks.put((Id)ar.get('acctId'), (Integer) ar.get('totalBooks'));
        }

        for (Lead l : [SELECT Id,Account__c,
                                   TotalPreviousBookings__c
                                   FROM Lead
                                   WHERE Account__c != '']) {
            if (accountIdTotalBooks.containsKey(l.Account__c)) {
                System.assertEquals(l.TotalPreviousBookings__c,
                                    accountIdTotalBooks.get(l.Account__c));
            }
        }
        Test.stopTest();
    }

    //1.3
    @isTest static void testSetDefaultBusinessUnit(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2
        
        //Setting the trigger active flag
        OrgSettings__c orgSetting = new OrgSettings__c();
        orgSetting.TriggersActive__c = true;
        insert orgSetting;
        
        //Inserting 5 Business Unit records
        List<Golfbreaks_Business_Unit__c> newBusinessUnits = new List<Golfbreaks_Business_Unit__c>();
        for(Integer i = 0;i<5;i++){
            Golfbreaks_Business_Unit__c bu = new Golfbreaks_Business_Unit__c();
            bu.Name = 'Test BU '+i;
            bu.Default_Booking_System__c = 'Clubhouse';
            bu.IsDefault__c = false;
            newBusinessUnits.add(bu);
        }
        //Setting one of the 5 as the default (at random)
        Integer randomCount = (Integer)Math.random()*4;
        newBusinessUnits[randomCount].isDefault__c = true;
        insert newBusinessUnits;
        
        Id defaultBusinessUnitId = newBusinessUnits[randomCount].Id;
        String defaultBookingSystem = newBusinessUnits[randomCount].Default_Booking_System__c;

        //1.6 Inserting a default Territory for each business unit //1.7-
        /*List<Territory__c> territories = new List<Territory__c>();
        for(Golfbreaks_Business_Unit__c bu : newBusinessUnits){
            Territory__c t = new Territory__c();
            t.Name = 'New Territory';
            t.IsDefault__c = true;
            t.BusinessUnit__c = bu.Id;
            territories.add(t);
        }
        insert territories;*/
        
        Opportunity[] oppsWithBookings = [Select Id,(Select Id, Account__c, Name, Golfbreaks_Business_Unit__c, Booking_System__c, TECH_Opportunity__c From Bookings__r ), Golfbreaks_Business_Unit__c, Booking_System__c From Opportunity LIMIT 2];
        //Confirming 2 Opps and 2 Bookings were retrieved
        system.assertEquals(2,oppsWithBookings.size());
        List<Booking__c> bookingsWithOpps = new List<Booking__c>();
        for(Opportunity o : oppsWithBookings){
            system.assertEquals(1,o.Bookings__r.size());
            bookingsWithOpps.add(o.Bookings__r);
            //Setting the NON Default BU's on the Opportunities (for later verification the BU is retrieved from the Opp and not set as the default)
            if(!newBusinessUnits[0].isDefault__c){
                o.Golfbreaks_Business_Unit__c = newBusinessUnits[0].Id;
                o.Booking_System__c = newBusinessUnits[0].Default_Booking_System__c;
                o.Territory__c = [Select Id From Territory__c Where BusinessUnit__c = :newBusinessUnits[0].Id Limit 1][0].Id;
            }else{
                o.Golfbreaks_Business_Unit__c = newBusinessUnits[1].Id;
                o.Booking_System__c = newBusinessUnits[1].Default_Booking_System__c;
                o.Territory__c = [Select Id From Territory__c Where BusinessUnit__c = :newBusinessUnits[1].Id Limit 1][0].Id;
            }        
        }
        //Saving (Non Default) Business Unit/Booking System on Opportunity
        update oppsWithBookings;
                
		//Collating Bookings for tests
		List<Booking__c> bookingsForUpdate = new List<Booking__c>();
        List<Booking__c> bookingsForInsert = new List<Booking__c>();
		
        Booking__c bookingInsertNoOpp = bookingsWithOpps[0].clone(false,true,false,false);
        bookingInsertNoOpp.TECH_Opportunity__c = null;
        bookingInsertNoOpp.Name = 'BU-bookingInsertNoOpp';
        bookingInsertNoOpp.Golfbreaks_Business_Unit__c = null;
        bookingInsertNoOpp.Booking_System__c = null;
        //bookingInsertNoOpp.Territory__c = null;//1.6+ //1.7-
        bookingsForInsert.add(bookingInsertNoOpp);
        
        Booking__c bookingInsertWithOpp = bookingsWithOpps[1].clone(false,true,false,false);
        bookingInsertWithOpp.Name = 'BU-bookingInsertWithOpp';
        bookingInsertWithOpp.Golfbreaks_Business_Unit__c = null;
        bookingInsertWithOpp.Booking_System__c = null;
        //bookingInsertWithOpp.Territory__c = null;//1.6+ //1.7-
        bookingsForInsert.add(bookingInsertWithOpp);
        
        
        Booking__c bookingUpdateNoOpp = bookingsWithOpps[0];
        bookingUpdateNoOpp.Name = 'BU-bookingUpdateNoOpp';
        bookingUpdateNoOpp.TECH_Opportunity__c = null;
        bookingUpdateNoOpp.Golfbreaks_Business_Unit__c = null;
        bookingUpdateNoOpp.Booking_System__c = null;
        //bookingUpdateNoOpp.Territory__c = null;//1.6+ //1.7-
        bookingsForUpdate.add(bookingUpdateNoOpp);
        
        Booking__c bookingUpdateWithOpp = bookingsWithOpps[1];
        bookingUpdateWithOpp.Name = 'BU-bookingUpdateWithOpp';
        bookingUpdateWithOpp.Golfbreaks_Business_Unit__c = null;
        bookingUpdateWithOpp.Booking_System__c = null;
        //bookingUpdateWithOpp.Territory__c = null;//1.6+ //1.7-
        bookingsForUpdate.add(bookingUpdateWithOpp);
		
		test.startTest();
        	//Inserting New Bookings
        	AP09_BookingTriggerHandler.isbeforeInsertTriggerCalled = false;
        	insert bookingsForInsert;
        	//Updating Existing Bookings
        	AP09_BookingTriggerHandler.isbeforeUpdateTriggerCalled = false;
        	update bookingsForUpdate;
        test.stopTest();
        
        set<Id> bookingIds = new Set<Id>();
        for(Booking__c b:bookingsForUpdate){
            bookingIds.add(b.Id);
        }
        for(Booking__c b:bookingsForInsert){
            bookingIds.add(b.Id);
        }
        
        //Requerying for evaluation
        Booking__c[] bookingsAfterDML = [Select Id, Name, Golfbreaks_Business_Unit__c, Booking_System__c, Territory__c, TECH_Opportunity__c, TECH_Opportunity__r.Golfbreaks_Business_Unit__c, TECH_Opportunity__r.Golfbreaks_Business_Unit__r.IsDefault__c, TECH_Opportunity__r.Booking_System__c, TECH_Opportunity__r.Territory__c From Booking__c Where Id In:bookingIds];
        system.debug('bookingsAfterDML:'+bookingsAfterDML);
        system.assertEquals(4, bookingsAfterDML.size());
        
        //Running assertions
        for(Booking__c b : bookingsAfterDML){
            if(b.Name == 'BU-bookingInsertNoOpp' || b.Name == 'BU-bookingUpdateNoOpp'){
                //Confirming the Booking has remained unparented
                system.assertEquals(null,b.TECH_Opportunity__c);
                //Confirming the BU is not null
                system.assertNotEquals(null,b.Golfbreaks_Business_Unit__c);
                //Confirming the BU has been set to the Default BU
                system.assertEquals(defaultBusinessUnitId, b.Golfbreaks_Business_Unit__c);
                //Confirming the Booking System has been set to the Default
                system.assertEquals(defaultBookingSystem, b.Booking_System__c);
                //Confirm the Default Territory of the Default Business Unit has been applied to the Booking
                //system.assertEquals(defaultBusinessUnitId, [Select Id, BusinessUnit__c From Territory__c Where Id = :b.Territory__c and IsDefault__c = true limit 1][0].BusinessUnit__c);//1.6+ //1.7-
            }else if(b.Name == 'BU-bookingInsertWithOpp' || b.Name == 'BU-bookingUpdateWithOpp'){
                //Confirming the Booking has remained with the Opp
                system.assertNotEquals(null,b.TECH_Opportunity__c);
                //Confirming the BU is not null
                system.assertNotEquals(null,b.Golfbreaks_Business_Unit__c);
                //Confirming the BU has been set to the Parent Opportunity's BU
                system.assertEquals(b.TECH_Opportunity__r.Golfbreaks_Business_Unit__c, b.Golfbreaks_Business_Unit__c);
                //Confirming the Booking System has been set to the Parent Opportunity's BU
                system.assertEquals(b.TECH_Opportunity__r.Booking_System__c, b.Booking_System__c);
                //Confirming the above is in spite of the fact the parent Opportunity's Business Unit is not the default
                system.assertEquals(false, b.TECH_Opportunity__r.Golfbreaks_Business_Unit__r.IsDefault__c);
                //Confirm the correct Territory has been applied to the Booking
                //system.assertEquals(b.TECH_Opportunity__r.Territory__c, b.Territory__c);//1.6+ //1.7-
            }
        }
        
    }
        
    //1.7
    @isTest static void testSetBookingTerritory(){

        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2
        
        //Setting the trigger active flag
        OrgSettings__c orgSetting = new OrgSettings__c();
        orgSetting.TriggersActive__c = true;
        insert orgSetting;

        //Query Account
        Id accId = [Select Id From Account Limit 1][0].Id;

        //Insert a Business Unit with multiple territories
        Golfbreaks_Business_Unit__c bu = new Golfbreaks_Business_Unit__c();
        bu.Name = 'test BU';
        insert bu;

        //Inserting a bu will implicitly create a default. Insert 2 additional territories
        List<Territory__c> territoryList = new List<Territory__c>();
        
        Territory__c t = new Territory__c();
        t.BusinessUnit__c = bu.Id;
        t.Name = 'UK';
        t.DeveloperName__c = 'UK';
        t.Countries__c = 'England & Wales';
        territoryList.add(t);
        
        Territory__c t2 = new Territory__c();
        t2.BusinessUnit__c = bu.Id;
        t2.Name = 'Europe';
        t2.DeveloperName__c = 'Europe';
        t2.Countries__c = 'Spain';
        territoryList.add(t2);
        insert territoryList;

        List<Booking__c> bookingList = new List<Booking__c>();
        Booking__c ukBooking = new Booking__c();
        ukBooking.Account__c = accId;
        ukBooking.Sales_Region__c = 'England & Wales';
        ukBooking.Name='TerritoryTest: Test UK Booking';
        bookingList.add(ukBooking);

        Booking__c euBooking = new Booking__c();
        euBooking.Account__c = accId;
        euBooking.Sales_Region__c = 'Spain';
        euBooking.Name='TerritoryTest: Test EU Booking';
        bookingList.add(euBooking);

        Booking__c unknownBooking = new Booking__c();
        unknownBooking.Account__c = accId;
        unknownBooking.Sales_Region__c = 'Unknown';
        unknownBooking.Name='TerritoryTest: Test Unknown Booking';
        bookingList.add(unknownBooking);

        test.startTest();
            insert bookingList;

            Booking__c[] insertedBookings = [Select Id, Sales_Region__c, Territory__r.Name, Territory__r.IsDefault__c From Booking__c Where Name LIKE 'TerritoryTest:%'];
            for(Booking__c b : insertedBookings){
                system.assertNotEquals(null, b.Territory__c);
                if(b.Sales_Region__c == 'Unknown'){
                    system.assertEquals(true,b.Territory__r.IsDefault__c);
                    //Change to UK
                    b.Sales_Region__c = 'England & Wales';
                }else if(b.Sales_Region__c == 'England & Wales'){
                    system.assertEquals('UK', b.Territory__r.Name);
                    //Change to EU
                    b.Sales_Region__c = 'Spain';
                }else if(b.Sales_Region__c == 'Spain'){
                    system.assertEquals('Europe', b.Territory__r.Name);
                    //Change to Unknown
                    b.Sales_Region__c = 'Unknown';
                }
            }

            //Change Sales Regions on all Bookings
            AP09_BookingTriggerHandler.isbeforeUpdateTriggerCalled = false;
            update insertedBookings;

            Booking__c[] updatedBookings = [Select Id, Sales_Region__c, Territory__r.Name, Territory__r.IsDefault__c From Booking__c Where Name LIKE 'TerritoryTest:%'];
            for(Booking__c b : updatedBookings){
                system.assertNotEquals(null, b.Territory__c);
                if(b.Sales_Region__c == 'Unknown'){
                    system.assertEquals(true,b.Territory__r.IsDefault__c);
                }else if(b.Sales_Region__c == 'England & Wales'){
                    system.assertEquals('UK', b.Territory__r.Name);
                }else if(b.Sales_Region__c == 'Spain'){
                    system.assertEquals('Europe', b.Territory__r.Name);
                }
            }
        test.stopTest();
    }

    /**
     * test method to check if the related case status is updated as per requirement when the
     * 'Agent attention required' is updated on the booking record
     * @author  Bhushan Sukumar
     * @date    13 May 2016
     */
     /* 1.1 - Removing Ammendment Case Updates at Shane's request - 09/10/2018
    @isTest
    static void test_updateAmendmentCaseStatus1() {

		GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2

        //querying bookings test data
        Set<Id> bookingIds = new Set<Id>();
        List<Booking__c> bookings = [SELECT Id,
                                     AgentAttentionRequired__c,
                                     Account__c,
                                     WaitingOnSupplier__c
                                     FROM Booking__c
                                     WHERE CreatedDate = TODAY ORDER BY CreatedDate DESC];

        Test.startTest();
        OrgSettings__c orgSetting = new OrgSettings__c();
        orgSetting.TriggersActive__c = true;
        insert orgSetting;

        //TODO: Not sure if this should be Admin user, we need to run as the intended user
        List<User> adminUser = [SELECT Id,
                                Name
                                FROM User
                                WHERE Profile.Name = : ApplicationConstant.PROFILE_SYSADMIN
                                        AND IsActive = TRUE];
        for (Booking__c booking : bookings) {
            booking.AgentAttentionRequired__c = true;
            bookingIds.add(booking.id);
        }
        System.runAs(adminUser[0]) {
            update bookings;
        }

        //checking to make sure the case status is CSC
        for (Case c : [SELECT Id, Status, AccountableforIssue__c, CustomerSatisfaction__c
                       FROM Case
                       WHERE Booking__c IN : bookingIds]) {
            System.assertEquals(c.Status, ApplicationConstant.CASE_STATUS_CSC);
        }

        Test.stopTest();
    }*/
    
    /**
     * test method to check if the case status is updated as per requirement when 'Waiting For
     * Supplier' is checked on the booking record
     * @author  Bhushan Sukumar
     * @date    13 May 2016
     */
     /* 1.1 - Removing Ammendment Case Updates at Shane's request - 09/10/2018
    @isTest
    static void test_updateAmendmentCaseStatus2() {
		
		GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2

        //querying bookings test data
        Set<Id> bookingIds = new Set<Id>();
        List<Booking__c> bookings = [SELECT Id,
                                     AgentAttentionRequired__c,
                                     Account__c,
                                     WaitingOnSupplier__c
                                     FROM Booking__c
                                     WHERE CreatedDate = TODAY ORDER BY CreatedDate DESC];

        OrgSettings__c orgSetting = new OrgSettings__c();
        orgSetting.TriggersActive__c = true;
        insert orgSetting;

        //TODO: Not sure if this should be Admin user, we need to run as the intended user
        List<User> adminUser = [SELECT Id,
                                Name
                                FROM User
                                WHERE Profile.Name = : ApplicationConstant.PROFILE_SYSADMIN
                                        AND IsActive = TRUE];

        Test.startTest();
        for (Booking__c booking : bookings) {
            booking.AgentAttentionRequired__c = false;
            booking.WaitingOnSupplier__c = true;
        }

        System.runAs(adminUser[0]) {
            update bookings;
        }

        //Case should not be closed and should be set to On Hold WFS
        for (Case c : [SELECT Id, Status, AccountableforIssue__c, CustomerSatisfaction__c
                       FROM Case
                       WHERE Booking__c IN : bookingIds]) {
            System.assertNotEquals(c.Status, ApplicationConstant.CASE_STATUS_CLOSED);
            System.assertEquals(c.Status, ApplicationConstant.CASE_STATUS_ONHOLD_WFS);
        }
        Test.stopTest();

    }*/
    
    /**
     * test method to check if the related cases' status is updated as per requirement when the
     * booking's 'Agent Attention Required' and 'Waiting On Supplier' is unchecked
     * @author  Bhushan Sukumar
     * @date    13 May 2016
     */
     
    /* 1.1 - Removing Ammendment Case Updates at Shane's request - 09/10/2018
    @isTest
    static void test_updateAmendmentCaseStatus3() {

		GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2

        //querying bookings test data
        Set<Id> bookingIds = new Set<Id>();
        List<Booking__c> bookings = [SELECT Id,
                                     AgentAttentionRequired__c,
                                     Account__c,
                                     WaitingOnSupplier__c
                                     FROM Booking__c
                                     WHERE CreatedDate = TODAY ORDER BY CreatedDate DESC];

        OrgSettings__c orgSetting = new OrgSettings__c();
        orgSetting.TriggersActive__c = true;
        insert orgSetting;

        //TODO: Not sure if this should be Admin user, we need to run as the intended user
        List<User> adminUser = [SELECT Id,
                                Name
                                FROM User
                                WHERE Profile.Name = : ApplicationConstant.PROFILE_SYSADMIN
                                        AND IsActive = TRUE];

        Test.startTest();
        for (Booking__c booking : bookings) {
            booking.AgentAttentionRequired__c = false;
            booking.WaitingOnSupplier__c = false;
        }

        System.runAs(adminUser[0]) {
            update bookings;
        }

        for (Case c : [SELECT Id, Status, AccountableforIssue__c, CustomerSatisfaction__c
                       FROM Case
                       WHERE Booking__c IN : bookingIds]) {
            System.assertEquals(c.Status, ApplicationConstant.CASE_STATUS_CLOSED);
            System.assertEquals(c.CustomerSatisfaction__c,
                                ApplicationConstant.CASE_CUSTOMER_SATISFACTION_NA );
            System.assertEquals(c.AccountableforIssue__c,
                                ApplicationConstant.CASE_ACCOUNTABLE_FOR_ISSUE_NONE);
        }
        Test.stopTest();
    }*/
    

    /*//@isTest
    static void test_checkAdmin() {
		
		GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2

        OrgSettings__c orgSetting = new OrgSettings__c();
        orgSetting.TriggersActive__c = true;
        insert orgSetting;

        //TODO: Not sure if this should be Admin user, we need to run as the intended user
        List<User> adminUser = [SELECT Id,
                                Name
                                FROM User
                                WHERE Profile.Name = : ApplicationConstant.PROFILE_SYSADMIN
                                        AND IsActive = TRUE];
    }//*/
  /* 1.5      
    @isTest
    static void test_checkAdmin() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2
        
        OrgSettings__c orgSetting = new OrgSettings__c();
        orgSetting.TriggersActive__c = true;
        insert orgSetting;

        //TODO: Not sure if this should be Admin user, we need to run as the intended user
        List<User> adminUser = [SELECT Id,
                                Name
                                FROM User
                                WHERE Profile.Name = : ApplicationConstant.PROFILE_SYSADMIN
                                        AND IsActive = TRUE];

        List<Account> existingAccs = [SELECT Id,
                                      Name,
                                      (SELECT Id,
                                       Name
                                       FROM Opportunities)
                                      FROM Account
                                      WHERE CreatedDate = TODAY];
        List<Booking__c> bookingsToInsert = new List<Booking__c>();
        for (Account acc : existingAccs) {
            if (!acc.Opportunities.isEmpty()) {
                bookingsToInsert.addAll(
                    AP23_TestDataFactory.createBooking(5, acc.Id, acc.Opportunities[0].id));
            }
        }


        
        System.runAs(adminUser[0]) {
            for(Booking__c book: bookingsToInsert){
              book.AgentTaskName__c = 'TestAgentName';
            }
            insert bookingsToInsert;
        }

        List<Expected_Payment__c> expectedPayList = new List<Expected_Payment__c>();

        Integer i= 0;

        List<Case> caseList = new List<Case>();

        for(Booking__c book: bookingsToInsert){
          Expected_Payment__c exp = new Expected_Payment__c();
          
          if(math.mod(i,2) == 0){
            exp = AP23_TestDataFactory.createExpectedPaymentRecord(book, ApplicationConstant.EPAYMENTTYPEPARTIALDEPOSIT, Decimal.valueOf(10));
          }
          else {
            exp = AP23_TestDataFactory.createExpectedPaymentRecord(book, ApplicationConstant.EPAYMENTTYPEFULLDEPOSIT, Decimal.valueOf(10));
          }
          i++;
          

          expectedPayList.add(exp);
        } 

        System.runAs(adminUser[0]) {
            insert expectedPayList; 
        }      

        Test.startTest();

          for(Booking__c bookings: bookingsToInsert){
            bookings.AmountPaid__c = Decimal.valueOf(10); 
            bookings.TransferDetailsRequired__c = false;
            bookings.RoomingListRequired__c = false;
            bookings.AgentTaskName__c = 'TestName';
          }



          System.runAs(adminUser[0]) {
              update bookingsToInsert; 
          }


        Test.stopTest();
    }
    */
    
    /* 1.5
    @isTest
    static void test_checkAdmin2() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2
        
        OrgSettings__c orgSetting = new OrgSettings__c();
        orgSetting.TriggersActive__c = true;
        insert orgSetting;

        //TODO: Not sure if this should be Admin user, we need to run as the intended user
        List<User> adminUser = [SELECT Id,
                                Name
                                FROM User
                                WHERE Profile.Name = : ApplicationConstant.PROFILE_SYSADMIN
                                        AND IsActive = TRUE];

        List<Account> existingAccs = [SELECT Id,
                                      Name,
                                      (SELECT Id,
                                       Name
                                       FROM Opportunities)
                                      FROM Account
                                      WHERE CreatedDate = TODAY];
        List<Booking__c> bookingsToInsert = new List<Booking__c>();
        for (Account acc : existingAccs) {
            if (!acc.Opportunities.isEmpty()) {
                bookingsToInsert.addAll(
                    AP23_TestDataFactory.createBooking(5, acc.Id, acc.Opportunities[0].id));
            }
        }


        
        System.runAs(adminUser[0]) {
            for(Booking__c book: bookingsToInsert){
              book.AgentTaskName__c = 'TestAgentName';
              book.TransferDetailsRequired__c = false;
              book.RoomingListRequired__c = false;
            }
            insert bookingsToInsert;  
        }
        Expected_Payment__c exp = new Expected_Payment__c(); 
        exp = AP23_TestDataFactory.createExpectedPaymentRecord(bookingsToInsert[0], ApplicationConstant.EPAYMENTTYPEFULLBALANCE, Decimal.valueOf(10));
          

        System.runAs(adminUser[0]) { 
            insert exp; 
        }  

        Case caseAdmin = new Case();
        
        Test.startTest();
        
        System.runAs(adminUser[0]) {
            
            caseAdmin = AP23_TestDataFactory.createCaseAdmin(existingAccs[0].Id, bookingsToInsert[0].Id);
            insert caseAdmin;
        }  
  
        System.runAs(adminUser[0]) {

            List<Task> taskList = new List<Task>();
            taskList = AP23_TestDataFactory.createTaskDynamic(1, caseAdmin, ApplicationConstant.GETFINALBALANCE);
            insert taskList;
        }  

          for(Booking__c bookings: bookingsToInsert){
            bookings.AmountPaid__c = Decimal.valueOf(10); 
            bookings.TransferDetailsRequired__c = true;
            bookings.RoomingListRequired__c = true;
            bookings.AgentTaskName__c = 'TestName';
          }



          System.runAs(adminUser[0]) {
              update bookingsToInsert; 
          }


        Test.stopTest();
    }
*/
    /* 1.5
    static testMethod void checkAdmin3(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2
        
        OrgSettings__c orgSetting = new OrgSettings__c();
        orgSetting.TriggersActive__c = true;
        insert orgSetting;
        
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Booking__c bkg = [SELECT Id, TransferDetailsRequired__c, RoomingListRequired__c, AgentTaskName__c FROM Booking__c LIMIT 1];
        bkg.TransferDetailsRequired__c = TRUE;
        bkg.RoomingListRequired__c = TRUE;
        bkg.AgentTaskName__c= 'Task Name 01';
        update bkg;
        
        Case caseAdmin = AP23_TestDataFactory.createCaseAdmin(acc.Id, bkg.Id);
        insert caseAdmin;
        
        Integer bkNum = 3;
        List<Expected_Payment__c> lEP = AP23_TestDataFactory.createExpectedPayment(bkNum, bkg, '', 100); 
        for(Integer i = 0; i < bkNum; i++){
            if(i == 0){
                lEP[i].ExpectedPaymentType__c = ApplicationConstant.EPAYMENTTYPEPARTIALDEPOSIT;
                lEP[i].Expected_Payment_Date__c = System.Today();
            }
            
            if(i == 1){
                lEP[i].ExpectedPaymentType__c = ApplicationConstant.EPAYMENTTYPEFULLDEPOSIT;
                lEP[i].Expected_Payment_Date__c = System.Today();
            }
            
            if(i == 2){
                lEP[i].ExpectedPaymentType__c = ApplicationConstant.EPAYMENTTYPEFULLBALANCE;
                lEP[i].Expected_Payment_Date__c = System.Today();
            }
        }
        insert lEP;        
        

        
        Test.startTest();
                List<Task> lTask = AP23_TestDataFactory.createTaskDynamic(6, caseAdmin, ApplicationConstant.GETINITIALDEPOSIT);
        for(Integer i = 0; i < 6; i++){
            if(i == 0){
                lTask[i].Subject = ApplicationConstant.GETINITIALDEPOSIT;
            }
            
            if(i == 1){
                lTask[i].Subject = ApplicationConstant.GETDEPOSITBALANCE;
            }
            
            if(i == 2){
                lTask[i].Subject = ApplicationConstant.GETFINALBALANCE;
            }
            
            if(i == 3){
                lTask[i].Subject = ApplicationConstant.TASKSUBJ_GETTRANSFER;
            }
            
            if(i == 4){
                lTask[i].Subject = ApplicationConstant.TASKSUBJ_GETROOMING;
            }
            
            if(i == 5){
                lTask[i].Subject = ApplicationConstant.TASKSUBJ_CHECKCH + bkg.AgentTaskName__c;
            }
        }
        insert lTask;
        
        
        bkg.TransferDetailsRequired__c = FALSE;
        bkg.RoomingListRequired__c = FALSE;
        bkg.AgentTaskName__c= 'Task Name 02';
        update bkg;
        
        Case UpdCase = [SELECT Id, Status FROM Case WHERE Id =: caseAdmin.Id LIMIT 1];
        //System.AssertEquals(UpdCase.Status, ApplicationConstant.CASE_STATUS_CLOSED);
        
        // List<Task> lUpdTask = [SELECT Id, Status, Subject FROM Task WHERE WhatId =: caseAdmin.Id];
        // for(Task tsk: lUpdTask){
        //     if(tsk.Subject == ApplicationConstant.GETINITIALDEPOSIT){
        //         System.AssertEquals(tsk.Status, ApplicationConstant.TASKSTATUS_COMPLETED);
        //     }
            
        //     if(tsk.Subject == ApplicationConstant.GETDEPOSITBALANCE){
        //         System.AssertEquals(tsk.Status, ApplicationConstant.TASKSTATUS_COMPLETED);
        //     }
            
        //     if(tsk.Subject == ApplicationConstant.GETFINALBALANCE){
        //         System.AssertEquals(tsk.Status, ApplicationConstant.TASKSTATUS_COMPLETED);
        //     }
            
        //     if(tsk.Subject == ApplicationConstant.TASKSUBJ_GETTRANSFER){
        //         System.AssertEquals(tsk.Status, ApplicationConstant.TASKSTATUS_COMPLETED);
        //     }
            
        //     if(tsk.Subject == ApplicationConstant.TASKSUBJ_GETROOMING){
        //         System.AssertEquals(tsk.Status, ApplicationConstant.TASKSTATUS_COMPLETED);
        //     }
            
        //     if(tsk.Subject == ApplicationConstant.TASKSUBJ_CHECKCH + bkg.AgentTaskName__c){
        //         System.AssertEquals(tsk.Status, ApplicationConstant.TASKSTATUS_COMPLETED);
        //     }
        // }
        Test.stopTest();
        
    }
*/
    
    /*1.5
    
     @isTest
    static void test_checkAdmin4() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2
        
        OrgSettings__c orgSetting = new OrgSettings__c();
        orgSetting.TriggersActive__c = true;
        insert orgSetting;

        //TODO: Not sure if this should be Admin user, we need to run as the intended user
        List<User> adminUser = [SELECT Id,
                                Name
                                FROM User
                                WHERE Profile.Name = : ApplicationConstant.PROFILE_SYSADMIN
                                        AND IsActive = TRUE];

        List<Account> existingAccs = [SELECT Id,
                                      Name,
                                      (SELECT Id,
                                       Name
                                       FROM Opportunities)
                                      FROM Account
                                      WHERE CreatedDate = TODAY];
        List<Booking__c> bookingsToInsert = new List<Booking__c>();
        for (Account acc : existingAccs) {
            if (!acc.Opportunities.isEmpty()) {
                bookingsToInsert.addAll(
                    AP23_TestDataFactory.createBooking(5, acc.Id, acc.Opportunities[0].id));
            }
        }


        
        System.runAs(adminUser[0]) {
            for(Booking__c book: bookingsToInsert){
              book.AgentTaskName__c = 'TestAgentName';
              book.TransferDetailsRequired__c = false;
              book.RoomingListRequired__c = false;
            }
            insert bookingsToInsert;  
        }
        Expected_Payment__c exp = new Expected_Payment__c(); 
        exp = AP23_TestDataFactory.createExpectedPaymentRecord(bookingsToInsert[0], ApplicationConstant.EPAYMENTTYPEPARTIALDEPOSIT, Decimal.valueOf(10));
          

        System.runAs(adminUser[0]) { 
            insert exp; 
        }  

        Case caseAdmin = new Case();
        System.runAs(adminUser[0]) {
            
            caseAdmin = AP23_TestDataFactory.createCaseAdmin(existingAccs[0].Id, bookingsToInsert[0].Id);
            insert caseAdmin;
        }  
  

        Test.startTest();

        System.runAs(adminUser[0]) {

            List<Task> taskList = new List<Task>();
            taskList = AP23_TestDataFactory.createTaskDynamic(1, caseAdmin, ApplicationConstant.GETINITIALDEPOSIT);
            insert taskList;
        }  

          for(Booking__c bookings: bookingsToInsert){
            bookings.AmountPaid__c = Decimal.valueOf(10); 
            bookings.TransferDetailsRequired__c = true;
            bookings.RoomingListRequired__c = true;
            bookings.AgentTaskName__c = 'TestName';
          }



          System.runAs(adminUser[0]) {
              update bookingsToInsert; 
          }


        Test.stopTest();
    }
    
    */
    

    /* 1.5
    @isTest
    static void test_checkAdmin5() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2
        
        OrgSettings__c orgSetting = new OrgSettings__c();
        orgSetting.TriggersActive__c = true;
        insert orgSetting;

        //TODO: Not sure if this should be Admin user, we need to run as the intended user
        List<User> adminUser = [SELECT Id,
                                Name
                                FROM User
                                WHERE Profile.Name = : ApplicationConstant.PROFILE_SYSADMIN
                                        AND IsActive = TRUE];

        List<Account> existingAccs = [SELECT Id,
                                      Name,
                                      (SELECT Id,
                                       Name
                                       FROM Opportunities)
                                      FROM Account
                                      WHERE CreatedDate = TODAY];
        List<Booking__c> bookingsToInsert = new List<Booking__c>();
        for (Account acc : existingAccs) {
            if (!acc.Opportunities.isEmpty()) {
                bookingsToInsert.addAll(
                    AP23_TestDataFactory.createBooking(5, acc.Id, acc.Opportunities[0].id));
            }
        }


        
        System.runAs(adminUser[0]) {
            for(Booking__c book: bookingsToInsert){
              book.AmountPaid__c = Decimal.valueOf(10);
              book.AgentTaskName__c = 'TestAgentName';
              book.TransferDetailsRequired__c = true;
              book.RoomingListRequired__c = true;
            }
            insert bookingsToInsert;  
        }
        Map<Id, Booking__c> oldBookingMap = new Map<Id, Booking__c>([SELECT Id FROM Booking__c]);
        
        Expected_Payment__c exp = new Expected_Payment__c(); 
        exp = AP23_TestDataFactory.createExpectedPaymentRecord(bookingsToInsert[0], ApplicationConstant.EPAYMENTTYPEFULLDEPOSIT, Decimal.valueOf(10));
          

        System.runAs(adminUser[0]) { 
            insert exp; 
        }  

        Case caseAdmin = new Case();
        
        Test.startTest();
        
        System.runAs(adminUser[0]) {
            
            caseAdmin = AP23_TestDataFactory.createCaseAdmin(existingAccs[0].Id, bookingsToInsert[0].Id);
            insert caseAdmin;
        }  

        System.runAs(adminUser[0]) {

            List<Task> taskList = new List<Task>();
            taskList = AP23_TestDataFactory.createTaskDynamic(1, caseAdmin, ApplicationConstant.TASKSUBJ_GETTRANSFER);
            insert taskList;
        }  

          for(Booking__c bookings: bookingsToInsert){
            bookings.AmountPaid__c = Decimal.valueOf(10); 
            bookings.TransferDetailsRequired__c = false;
            bookings.RoomingListRequired__c = false;
            bookings.AgentTaskName__c = 'TestName';
          }

          System.runAs(adminUser[0]) {
              update bookingsToInsert; 
          }
         Map<Id, Booking__c> newBookingMap = new Map<Id, Booking__c>([SELECT Id FROM Booking__c]); 
         
         AP10_BookingTriggerBL.checkAdminTask(newBookingMap, oldBookingMap);
          


        Test.stopTest();
    }

*/
    

}