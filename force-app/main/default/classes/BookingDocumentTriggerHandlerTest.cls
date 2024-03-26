/*
Name:  BookingDocumentTriggerHandlerTest.cls
======================================================
======================================================
Purpose: Test Suite for Booking Document activity
-------

======================================================
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-03-04  Initial development.
*/
@isTest
public with sharing class BookingDocumentTriggerHandlerTest {
    
    @TestSetup static void createTestData(){
        //Account
        Account client = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert client;
        //Opportunity
        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, ApplicationConstant.OPPORTUNITY_STAGENAME_FULL_BALANCE, client)[0];
        insert opp;
        //Booking
        Booking__c booking = AP23_TestDataFactory.createBooking(1, client.Id, opp.Id)[0];
        insert booking;
        //Guest Group
        GuestGroup__c guestGroup = AP23_TestDataFactory.createGuestGroups(1,booking.Id)[0];
        insert guestGroup;
        //Booking Guest
        BookingGuest__c guest = AP23_TestDataFactory.createBookingGuests(1,guestGroup.Id)[0];
        insert guest;

        //Activate Triggers
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;      
    }

    @isTest static void testBookingDocumentSummaryCalculation(){
        
        //Retrieve Booking Guest
        BookingGuest__c guest = [Select Id, GuestGroup__r.Booking__c, NumberOfBookingDocuments__c From BookingGuest__c];
        system.assertEquals(0, guest.NumberOfBookingDocuments__c);

        test.startTest();
            GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;

            //Insert 10 documents
            List<BookingDocument__c> docs = AP23_TestDataFactory.createBookingDocuments(10,guest.GuestGroup__r.Booking__c,guest.Id);
            insert docs;
            system.assertEquals(10, [Select NumberOfBookingDocuments__c From BookingGuest__c Where Id =:guest.Id].NumberOfBookingDocuments__c);

            //Delete 5 documents
            delete [Select Id From BookingDocument__c Where BookingGuest__c = :guest.Id Limit 5];
            system.assertEquals(5, [Select NumberOfBookingDocuments__c From BookingGuest__c Where Id =:guest.Id].NumberOfBookingDocuments__c);
        
        test.stopTest();

    }

}