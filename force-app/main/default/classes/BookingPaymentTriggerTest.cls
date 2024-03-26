/*
Name: BookingPaymentTriggerTest.cls
Copyright © 2021  Golfbreaks
======================================================
======================================================
Purpose:
-------

Test suite for the ApexTrigger BookingPaymentTrigger.

Coverage for classes below (target 85%):
BookingPaymentTriggerHandler - 92% (at v1.1)

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2021-11-03  Initial development.
1.1  Mark Cane&    2021-11-04  single record and bulk test cases added.
1.2  J Radcliffe   2023-07-06  Bug fixes - Amount_Paid__c default changed from null to 0.00
*/
@isTest
public with sharing class BookingPaymentTriggerTest {

    /*
    Test cases:
        singleTestCase1 - ApexTrigger - Insert. Single record case.
        singleTestCase2a - ApexTrigger - Update. Single record case (Amount Paid change).
        singleTestCase2b - ApexTrigger - Update. Single record case (Amount Paid zeroise).
        singleTestCase2c - ApexTrigger - Update. Single record case (Booking Guest transfer).
        singleTestCase3 - ApexTrigger - Delete. Single record case.
        singleTestCase4 - ApexTrigger - Undelete. Single record case.
        ..
        bulkTestCase1 - ApexTrigger - Insert - 200 record case.
        bulkTestCase2 - ApexTrigger - Update - 200 record case (Payment Amount change).
        bulkTestCase3 - ApexTrigger - 200 record case (Booking Guest transfer - 400 Guests each with 10 Paymments).
	*/

    @testSetup static void setup(){
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
    }
  
    @isTest static void singleTestCase1(){
        // ApexTrigger - Insert. Single record case.
        
        GuestGroup__c guestGroup = [select Id, Booking__c from GuestGroup__c limit 1][0];
        
        List<BookingGuest__c> bookingGuests = AP23_TestDataFactory.createBookingGuests(1,guestGroup.Id);//Create 1 Booking Guest.
        insert bookingGuests;
        
        Id bookingGuestId = bookingGuests[0].Id;

        System.assertEquals(0.00,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuestId].Amount_Paid__c);//1.2~

        Booking_Payment__c bookingPayment = new Booking_Payment__c(Booking_Guest__c=bookingGuestId, Booking__c=guestGroup.Booking__c, PaymentAmount__c=100, PaymentDate__c=Date.today());

        Test.startTest();
        insert bookingPayment;
        Test.stopTest();

        System.assertEquals(100,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuestId].Amount_Paid__c);
    }

    @isTest static void singleTestCase2a(){
        // ApexTrigger - Update. Single record case (Amount Paid change).

        GuestGroup__c guestGroup = [select Id, Booking__c from GuestGroup__c limit 1][0];
        
        List<BookingGuest__c> bookingGuests = AP23_TestDataFactory.createBookingGuests(1,guestGroup.Id);//Create 1 Booking Guest.
        insert bookingGuests;
        
        Id bookingGuestId = bookingGuests[0].Id;

        System.assertEquals(0.00,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuestId].Amount_Paid__c);//1.2~

        Booking_Payment__c bookingPayment = new Booking_Payment__c(Booking_Guest__c=bookingGuestId, Booking__c=guestGroup.Booking__c, PaymentAmount__c=100, PaymentDate__c=Date.today());
        insert bookingPayment;

        System.assertEquals(100,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuestId].Amount_Paid__c);

        bookingPayment.PaymentAmount__c=200;

        BookingPaymentTriggerHandler.isFirstAfterUpdate=true;

        Test.startTest();
        update bookingPayment;
        Test.stopTest();

        System.assertEquals(200,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuestId].Amount_Paid__c);
    }

    @isTest static void singleTestCase2b(){
        // ApexTrigger - Update. Single record case (Amount Paid zeroise).

        GuestGroup__c guestGroup = [select Id, Booking__c from GuestGroup__c limit 1][0];
        
        List<BookingGuest__c> bookingGuests = AP23_TestDataFactory.createBookingGuests(1,guestGroup.Id);//Create 1 Booking Guest.
        insert bookingGuests;
        
        Id bookingGuestId = bookingGuests[0].Id;

        System.assertEquals(0.00,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuestId].Amount_Paid__c);//1.2~

        Booking_Payment__c bookingPayment = new Booking_Payment__c(Booking_Guest__c=bookingGuestId, Booking__c=guestGroup.Booking__c, PaymentAmount__c=100, PaymentDate__c=Date.today());
        insert bookingPayment;

        System.assertEquals(100,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuestId].Amount_Paid__c);

        bookingPayment.PaymentAmount__c=0;

        BookingPaymentTriggerHandler.isFirstAfterUpdate=true;

        Test.startTest();
        update bookingPayment;
        Test.stopTest();

        System.assertEquals(0,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuestId].Amount_Paid__c);
    }    

    @isTest static void singleTestCase2c(){
        // ApexTrigger - Update. Single record case (Booking Guest transfer).

        GuestGroup__c guestGroup = [select Id, Booking__c from GuestGroup__c limit 1][0];
        
        List<BookingGuest__c> bookingGuests = AP23_TestDataFactory.createBookingGuests(2,guestGroup.Id);//Create 2 Booking Guests.
        insert bookingGuests;
        
        Id bookingGuest1Id = bookingGuests[0].Id;
        Id bookingGuest2Id = bookingGuests[1].Id;

        System.assertEquals(0.00,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuest1Id].Amount_Paid__c);//1.2~
        System.assertEquals(0.00,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuest2Id].Amount_Paid__c);//1.2~

        Booking_Payment__c bookingPayment = new Booking_Payment__c(Booking_Guest__c=bookingGuest1Id, Booking__c=guestGroup.Booking__c, PaymentAmount__c=100, PaymentDate__c=Date.today());
        insert bookingPayment;

        System.assertEquals(100,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuest1Id].Amount_Paid__c);
        System.assertEquals(0.00,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuest2Id].Amount_Paid__c);//1.2~

        bookingPayment.Booking_Guest__c=bookingGuest2Id;

        BookingPaymentTriggerHandler.isFirstAfterUpdate=true;

        Test.startTest();
        update bookingPayment;
        Test.stopTest();

        System.assertEquals(0,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuest1Id].Amount_Paid__c);
        System.assertEquals(100,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuest2Id].Amount_Paid__c);
    } 
    
    @isTest static void singleTestCase3(){
        // ApexTrigger - Delete. Single record case.

        GuestGroup__c guestGroup = [select Id, Booking__c from GuestGroup__c limit 1][0];
        
        List<BookingGuest__c> bookingGuests = AP23_TestDataFactory.createBookingGuests(1,guestGroup.Id);//Create 1 Booking Guest.
        insert bookingGuests;
        
        Id bookingGuestId = bookingGuests[0].Id;

        System.assertEquals(0.00,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuestId].Amount_Paid__c);//1.2~

        Booking_Payment__c bookingPayment = new Booking_Payment__c(Booking_Guest__c=bookingGuestId, Booking__c=guestGroup.Booking__c, PaymentAmount__c=100, PaymentDate__c=Date.today());
        insert bookingPayment;

        System.assertEquals(100,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuestId].Amount_Paid__c);

        Test.startTest();
        delete bookingPayment;
        Test.stopTest();

        System.assertEquals(0,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuestId].Amount_Paid__c);
    }

    @isTest static void singleTestCase4(){
        // ApexTrigger - Undelete. Single record case.

        GuestGroup__c guestGroup = [select Id, Booking__c from GuestGroup__c limit 1][0];
        
        List<BookingGuest__c> bookingGuests = AP23_TestDataFactory.createBookingGuests(1,guestGroup.Id);//Create 1 Booking Guest.
        insert bookingGuests;
        
        Id bookingGuestId = bookingGuests[0].Id;

        System.assertEquals(0.00,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuestId].Amount_Paid__c);//1.2~

        Booking_Payment__c bookingPayment = new Booking_Payment__c(Booking_Guest__c=bookingGuestId, Booking__c=guestGroup.Booking__c, PaymentAmount__c=100, PaymentDate__c=Date.today());
        insert bookingPayment;

        System.assertEquals(100,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuestId].Amount_Paid__c);

        delete bookingPayment;
        System.assertEquals(0,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuestId].Amount_Paid__c);

        Test.startTest();
        undelete bookingPayment;
        Test.stopTest();

        System.assertEquals(100,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuestId].Amount_Paid__c);
    } 
    
    @isTest static void bulkTestCase1(){
        // ApexTrigger - Insert - 200 record case.
        
        GuestGroup__c guestGroup = [select Id, Booking__c from GuestGroup__c limit 1][0];
        
        List<BookingGuest__c> bookingGuests = AP23_TestDataFactory.createBookingGuests(200,guestGroup.Id);//Create 200 Booking Guests.
        insert bookingGuests;

        list<Booking_Payment__c> bookingPayments = new list<Booking_Payment__c>();
        for (BookingGuest__c bg : bookingGuests){
            bookingPayments.add(new Booking_Payment__c(Booking_Guest__c=bg.Id, Booking__c=guestGroup.Booking__c, PaymentAmount__c=100, PaymentDate__c=Date.today()) );
        }
        
        System.assertEquals(0.00,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuests[0].Id].Amount_Paid__c);//1.2~
        System.assertEquals(0.00,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuests[199].Id].Amount_Paid__c);//1.2~
        System.assertEquals(0,[select count() from BookingGuest__c where Amount_Paid__c=100]);
        
        Test.startTest();
        insert bookingPayments;
        Test.stopTest();

        System.assertEquals(100,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuests[0].Id].Amount_Paid__c);
        System.assertEquals(100,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuests[199].Id].Amount_Paid__c);
        System.assertEquals(200,[select count() from BookingGuest__c where Amount_Paid__c=100]);
    }

    @isTest static void bulkTestCase2(){
        // ApexTrigger - Update - 200 record case (Payment Amount change).
        
        GuestGroup__c guestGroup = [select Id, Booking__c from GuestGroup__c limit 1][0];
        
        List<BookingGuest__c> bookingGuests = AP23_TestDataFactory.createBookingGuests(200,guestGroup.Id);//Create 200 Booking Guests.
        insert bookingGuests;

        list<Booking_Payment__c> bookingPayments = new list<Booking_Payment__c>();
        for (BookingGuest__c bg : bookingGuests){
            bookingPayments.add(new Booking_Payment__c(Booking_Guest__c=bg.Id, Booking__c=guestGroup.Booking__c, PaymentAmount__c=100, PaymentDate__c=Date.today()) );
        }
        
        System.assertEquals(0.00,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuests[0].Id].Amount_Paid__c);//1.2~
        System.assertEquals(0.00,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuests[199].Id].Amount_Paid__c);//1.2~
        System.assertEquals(0,[select count() from BookingGuest__c where Amount_Paid__c=100]);

        insert bookingPayments;

        System.assertEquals(200,[select count() from BookingGuest__c where Amount_Paid__c=100]);

        for (Booking_Payment__c bp : bookingPayments){
            bp.PaymentAmount__c=200;
        }
        
        BookingPaymentTriggerHandler.isFirstAfterUpdate=true;
        
        Test.startTest();
        update bookingPayments;
        Test.stopTest();

        System.assertEquals(200,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuests[0].Id].Amount_Paid__c);
        System.assertEquals(200,[select Amount_Paid__c from BookingGuest__c where Id=:bookingGuests[199].Id].Amount_Paid__c);
        System.assertEquals(200,[select count() from BookingGuest__c where Amount_Paid__c=200]);        
    }

    @isTest static void bulkTestCase3(){
        // ApexTrigger - 100 record case (Booking Guest transfer - 100 Guests each with 10 Paymments).
        
        GuestGroup__c guestGroup = [select Id, Booking__c from GuestGroup__c limit 1][0];

        List<BookingGuest__c> bookingGuestsAll = AP23_TestDataFactory.createBookingGuests(100,guestGroup.Id);//Create 200 Booking Guests.
        insert bookingGuestsAll;

        List<BookingGuest__c> bookingGuestsFrom = new List<BookingGuest__c>();
        List<BookingGuest__c> bookingGuestsTo = new List<BookingGuest__c>();

        for (BookingGuest__c bg : bookingGuestsAll){
            if (bookingGuestsFrom.size()<50) bookingGuestsFrom.add(bg);
            else bookingGuestsTo.add(bg);
        }

        //List<BookingGuest__c> bookingGuestsAll = new List<BookingGuest__c>();
        //bookingGuestsAll.addAll(bookingGuestsFrom);
        //bookingGuestsAll.addAll(bookingGuestsTo);

        list<Booking_Payment__c> bookingPayments = new list<Booking_Payment__c>();
        for (BookingGuest__c bg : bookingGuestsFrom){
            bookingPayments.add(new Booking_Payment__c(Booking_Guest__c=bg.Id, Booking__c=guestGroup.Booking__c, PaymentAmount__c=101, PaymentDate__c=Date.today()) );
            bookingPayments.add(new Booking_Payment__c(Booking_Guest__c=bg.Id, Booking__c=guestGroup.Booking__c, PaymentAmount__c=102, PaymentDate__c=Date.today()) );
            bookingPayments.add(new Booking_Payment__c(Booking_Guest__c=bg.Id, Booking__c=guestGroup.Booking__c, PaymentAmount__c=103, PaymentDate__c=Date.today()) );
            bookingPayments.add(new Booking_Payment__c(Booking_Guest__c=bg.Id, Booking__c=guestGroup.Booking__c, PaymentAmount__c=104, PaymentDate__c=Date.today()) );
            bookingPayments.add(new Booking_Payment__c(Booking_Guest__c=bg.Id, Booking__c=guestGroup.Booking__c, PaymentAmount__c=105, PaymentDate__c=Date.today()) );
            bookingPayments.add(new Booking_Payment__c(Booking_Guest__c=bg.Id, Booking__c=guestGroup.Booking__c, PaymentAmount__c=106, PaymentDate__c=Date.today()) );
            bookingPayments.add(new Booking_Payment__c(Booking_Guest__c=bg.Id, Booking__c=guestGroup.Booking__c, PaymentAmount__c=107, PaymentDate__c=Date.today()) );
            bookingPayments.add(new Booking_Payment__c(Booking_Guest__c=bg.Id, Booking__c=guestGroup.Booking__c, PaymentAmount__c=108, PaymentDate__c=Date.today()) );
            bookingPayments.add(new Booking_Payment__c(Booking_Guest__c=bg.Id, Booking__c=guestGroup.Booking__c, PaymentAmount__c=109, PaymentDate__c=Date.today()) );            
            bookingPayments.add(new Booking_Payment__c(Booking_Guest__c=bg.Id, Booking__c=guestGroup.Booking__c, PaymentAmount__c=110, PaymentDate__c=Date.today()) );
        }
        
        System.assertEquals(0,[select count() from BookingGuest__c where Amount_Paid__c<>0.00]);

        insert bookingPayments;//1000

        System.assertEquals(50,[select count() from BookingGuest__c where Id in:bookingGuestsFrom and Amount_Paid__c>0]);
        System.assertEquals(0,[select count() from BookingGuest__c where Id in:bookingGuestsTo and Amount_Paid__c!=0.00]);

        Integer bookingPaymentCounter=0,guestIndex=0;
        for (Booking_Payment__c bp : bookingPayments){
            bp.Booking_Guest__c = bookingGuestsTo[guestIndex].Id;
            bookingPaymentCounter++;
            if (bookingPaymentCounter==10){
                bookingPaymentCounter=0;
                guestIndex++;
            }
        }
        
        BookingPaymentTriggerHandler.isFirstAfterUpdate=true;
        
        Test.startTest();
        update bookingPayments;
        Test.stopTest();

        System.assertEquals(50,[select count() from BookingGuest__c where Id in:bookingGuestsFrom and Amount_Paid__c=0]);
        System.assertEquals(50,[select count() from BookingGuest__c where Id in:bookingGuestsTo and Amount_Paid__c>0]);
    }    
}