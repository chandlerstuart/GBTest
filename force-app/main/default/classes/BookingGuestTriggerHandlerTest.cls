/*
Name:  BookingGuestTriggerHandlerTest.cls
======================================================
======================================================
Purpose: Test Suite for BookingGuestTriggerHandler.cls
-------

Coverage - BookingTriggerHandler - 90%
           BookingTrigger - 90%

======================================================
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2021-09-13  Initial development.
1.1  J Radcliffe   2024-02-13  New test method testAssignPublicIdsOnInsert.
*/
@isTest
public with sharing class BookingGuestTriggerHandlerTest {

    @TestSetup static void  createTestData(){
        //Create Person Account
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert acc;
        //Create Opportunity
        Opportunity opp = AP23_TestDataFactory.createOpportunity(1,ApplicationConstant.PAIDFULLBALANCESTAGE,acc)[0];
        insert opp;
        //Create Booking
        Booking__c booking = AP23_TestDataFactory.createBooking(1, acc, opp.Id)[0];
        insert booking;
        //Create Guest Group
        GuestGroup__c guestGroup = AP23_TestDataFactory.createGuestGroups(1,booking.Id)[0];
        insert guestGroup;

        //Activate Triggers
        OrgSettings__c settings = new OrgSettings__c();
        settings.TriggersActive__c = true;
        insert settings;

        //Activate Generate Public Id Automation
        insert new Phased_Code_Removal__c(ActivatePublicIdGeneration__c = true);//1.1+  
    }
  
    @isTest static void calculateBookingGuestInvitationKeyTest(){

        //Create 100 Booking Guests
        GuestGroup__c guestGroup = [Select Id From GuestGroup__c];
        List<BookingGuest__c> guests = AP23_TestDataFactory.createBookingGuests(100,guestGroup.Id);
        
        test.startTest();
            BookingGuestTriggerHandler.currentDTOverride = DateTime.newInstanceGmt(2021, 09, 13, 14, 42, 00);
            insert guests;

            List<BookingGuest__c> guestsAfterInsert = [Select Id, Invitation_Key__c From BookingGuest__c];
            system.assertEquals(100, guestsAfterInsert.size());
            //Confirm the Ids are calculated correctly
            for(BookingGuest__c guest : guestsAfterInsert){
                system.assertNotEquals(null, guest.Invitation_Key__c);
                String encodedId = EncodingUtil.base64Encode(Blob.valueof(guest.Id)); 
                String expectedKey = 'G-'+encodedId.substring(0,encodedId.length()/4)+'-015-'+encodedId.substring(encodedId.length()/4,encodedId.length()/2)+'-4202021-'+encodedId.substring(encodedId.length()/2,(encodedId.length()/4)*3)+'-139-'+encodedId.substring((encodedId.length()/4)*3,encodedId.length());
                system.assertEquals(expectedKey,guest.Invitation_Key__c);
                guest.Invitation_Key__c = null;//Clear the values
            }
            //Reset the current time
            BookingGuestTriggerHandler.currentDTOverride = DateTime.newInstanceGmt(2021, 10, 18, 21, 49, 00);
            //Reset Trigger State
            BookingGuestTriggerHandler.isFirstBeforeUpdate = true;
            //Update the Booking Guests (clearing the values and forcing a recalculation)
            update guestsAfterInsert;

            List<BookingGuest__c> guestsAfterUpdate = [Select Id, Invitation_Key__c From BookingGuest__c];
            system.assertEquals(100, guestsAfterUpdate.size());
            //Confirm the Ids are recalculated incorporating the NEW D/T (ensuring their uniqueness)
            for(BookingGuest__c guest : guestsAfterUpdate){
                system.assertNotEquals(null, guest.Invitation_Key__c);
                String encodedId = EncodingUtil.base64Encode(Blob.valueof(guest.Id)); 
                String expectedKey = 'G-'+encodedId.substring(0,encodedId.length()/4)+'-022-'+encodedId.substring(encodedId.length()/4,encodedId.length()/2)+'-4902021-'+encodedId.substring(encodedId.length()/2,(encodedId.length()/4)*3)+'-1810-'+encodedId.substring((encodedId.length()/4)*3,encodedId.length());
                system.assertEquals(expectedKey,guest.Invitation_Key__c);
            }
        test.stopTest();
    }

    //1.1+
    @isTest static void testAssignPublicIdsOnInsert(){
        //Create 10 Booking Guests
        GuestGroup__c guestGroup = [Select Id From GuestGroup__c];
        List<BookingGuest__c> guests = AP23_TestDataFactory.createBookingGuests(10,guestGroup.Id);
        
        test.startTest();
            insert guests;
            Map<Id,BookingGuest__c> guestMap = new Map<Id,BookingGuest__c>(guests);
            system.assertEquals(10, [Select Count() From BookingGuest__c Where Id In:guestMap.keySet() and PublicId__c != null]);
        test.stopTest();
    }
}