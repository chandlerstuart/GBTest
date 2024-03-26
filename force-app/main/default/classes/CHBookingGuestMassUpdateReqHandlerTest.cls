/*
Name:  CHBookingGuestMassUpdateReqHandlerTest.cls
======================================================
======================================================
Purpose: CHBookingGuestMassUpdateRequestHandler Test Suite
-------
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-06-27  Initial Development.
*/
@isTest
public with sharing class CHBookingGuestMassUpdateReqHandlerTest {
    
    @TestSetup static void createTestData(){
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert acc;
        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, ApplicationConstant.PAIDFULLBALANCESTAGE, acc)[0];
        insert opp;
        Booking__c booking = AP23_TestDataFactory.createBooking(1,acc.Id,opp.Id)[0];
        insert booking;
        GuestGroup__c guestGroup = AP23_TestDataFactory.createGuestGroups(1,booking.Id)[0];
        insert guestGroup;
        List<BookingGuest__c> guests = AP23_TestDataFactory.createBookingGuests(5,guestGroup.Id);
        insert guests;
    }

    @isTest static void testRequestHandlerSuccess(){

        Id bookingId = [Select Id From Booking__c].Id;

        Test.startTest();
            CHBookingGuestMassUpdateRequestHandler handler = new CHBookingGuestMassUpdateRequestHandler();
            HttpRequest request = handler.buildOutboundRequest('Booking__c',new set<Id>{bookingId},new HttpRequest());
        Test.stopTest();

        CHBookingGuestMassUpdateRequestHandler.Data data = (CHBookingGuestMassUpdateRequestHandler.Data)JSON.deserialize(request.getBody(),CHBookingGuestMassUpdateRequestHandler.Data.class);
        system.assertEquals(bookingId, data.SalesforceBookingId);
        system.assertEquals(5, data.UpdateGuests.size());
    }

    @isTest static void testRequestHandlerMultiRecordFailure(){

        Id bookingId = [Select Id From Booking__c].Id;

        Test.startTest();
            CHBookingGuestMassUpdateRequestHandler handler = new CHBookingGuestMassUpdateRequestHandler();
            HttpRequest request = handler.buildOutboundRequest('Booking__c',new set<Id>{bookingId,UserInfo.getUserId()},new HttpRequest());//Pass an additional id. User Id = Pseudo booking id
        Test.stopTest();

        //Confirm the failure is logged
        system.assertEquals(1, [Select Count() From Golfbreaks__PlatformLog__c Where Golfbreaks__Message__c =: CHBookingGuestMassUpdateRequestHandler.singleBookingOnlyError]);

    }
}