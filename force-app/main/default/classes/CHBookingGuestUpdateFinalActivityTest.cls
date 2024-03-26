/*
Name:  CHBookingGuestUpdateFinalActivityTest.cls
======================================================
======================================================
Purpose:
-------
Test Suite for CHBookingGuestUpdateFinalActivityHandler.cls

Coverage: CHBookingGuestUpdateFinalActivityHandler - 

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2023-07-26  Initial development.
*/
@isTest
public with sharing class CHBookingGuestUpdateFinalActivityTest {

    public static final String dataEventType = 'CHGuestUpdate';
    
    @testSetup static void testSetup(){

        //Create a Person Account
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert acc;

        //Create an Opportunity
        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, 'New', acc)[0];
        insert opp;

        //Create a Booking
        Booking__c booking = AP23_TestDataFactory.createBooking(1,acc,opp.Id)[0];
        insert booking;

        //Create a Guest Group
        GuestGroup__c guestGroup = AP23_TestDataFactory.createGuestGroups(1,booking.Id)[0];
        insert guestGroup; 

        //Create (Locked) Booking Guests
        List<BookingGuest__c> guests = new List<BookingGuest__c>();
        for(BookingGuest__c guest : AP23_TestDataFactory.createBookingGuests(5,guestGroup.Id)){
            guest.IsLockedSystem__c = true;//Lock the records (as default)
            guests.add(guest);
        }
        insert guests;

        //Create an Outbound Callout record
        insert AP23_TestDataFactory.createOutboundCallout(1, dataEventType, booking.Id)[0];

    }

    @isTest static void testExecute_ValidInput(){

        system.assertEquals(0, [Select Count() From Golfbreaks__PlatformLog__c]);

        OutboundCallout__c oc = [Select Id, RecordId__c, DataEventType__c From OutboundCallout__c];
        
        //No Record Id
        OutboundCallout__c ocNoId = oc.clone();
        ocNoId.RecordId__c = null;
        //No DET
        OutboundCallout__c ocNoDET = oc.clone();
        ocNoDET.DataEventType__c = null;

        DataEventType__mdt det = DataEventType__mdt.getInstance(dataEventType);
        
        test.startTest();
            CHBookingGuestUpdateFinalActivityHandler handler = new CHBookingGuestUpdateFinalActivityHandler();
            handler.execute(det, ocNoId);//Trigger no id failure
            handler.execute(det, ocNoDET);//Trigger no det failure
        test.stopTest();
        
        //Confirm each failure is logged for the attention of the sf team
        system.assertEquals(2, [Select Count() From Golfbreaks__PlatformLog__c Where Golfbreaks__Message__c LIKE '%Error! Insufficient data provided to handler%']); 

    }

    @isTest
    static void testSuccess_FirstRun() {

        Booking__c booking = [Select Id From Booking__c];

        system.assertEquals(5, [Select Count() From BookingGuest__c Where Booking__c = :booking.Id and IsLockedSystem__c = true]);

        OutboundCallout__c oc = [Select Id, RecordId__c, DataEventType__c From OutboundCallout__c];
        DataEventType__mdt det = DataEventType__mdt.getInstance(dataEventType);

        // Call the handleFinalActivity method
        Test.startTest();
            CHBookingGuestUpdateFinalActivityHandler handler = new CHBookingGuestUpdateFinalActivityHandler();
            handler.execute(det, oc);
        Test.stopTest();

        system.assertEquals(0, [Select Count() From BookingGuest__c Where Booking__c = :booking.Id and IsLockedSystem__c = true]);//Confirm the bookings have been unlocked

    }

    @isTest
    static void testSuccess_Retry() {

        
        Booking__c booking = [Select Id From Booking__c];

        system.assertEquals(5, [Select Count() From BookingGuest__c Where Booking__c = :booking.Id and IsLockedSystem__c = true]);

        OutboundCallout__c oc = [Select Id, RecordId__c, DataEventType__c From OutboundCallout__c];
        DataEventType__mdt det = DataEventType__mdt.getInstance(dataEventType);

        // Call the handleFinalActivity method
        Test.startTest();
            CHBookingGuestUpdateFinalActivityHandler handler = new CHBookingGuestUpdateFinalActivityHandler();
            CHBookingGuestUpdateFinalActivityHandler.throwLockingError = true;//Force retry
            handler.execute(det, oc);
        Test.stopTest();

        system.assertEquals(0, [Select Count() From BookingGuest__c Where Booking__c = :booking.Id and IsLockedSystem__c = true]);//Confirm the bookings have still been unlocked

    }

    //Test exception

}