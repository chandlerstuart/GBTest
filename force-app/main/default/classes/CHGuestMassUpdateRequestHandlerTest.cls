/*
Name:  CHGuestMassUpdateRequestHandlerTest.cls
======================================================
======================================================
Purpose: CHGuestMassUpdateRequestHandler
-------
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-05-26  Initial Development.
*/
@isTest
public with sharing class CHGuestMassUpdateRequestHandlerTest {
    
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

        Set<Id> recordIds = new Map<Id,BookingGuest__c>([Select Id From BookingGuest__c]).keySet();
        system.assertEquals(5,recordIds.size());

        Test.startTest();
            CHGuestMassUpdateRequestHandler handler = new CHGuestMassUpdateRequestHandler();
            HttpRequest request = handler.buildOutboundRequest('BookingGuest__c',recordIds,new HttpRequest());
        Test.stopTest();

        CHGuestMassUpdateRequestHandler.Data data = (CHGuestMassUpdateRequestHandler.Data)JSON.deserialize(request.getBody(),CHGuestMassUpdateRequestHandler.Data.class);
        system.assertEquals(bookingId, data.SalesforceBookingId);
        system.assertEquals(5, data.UpdateGuests.size());
    }
}