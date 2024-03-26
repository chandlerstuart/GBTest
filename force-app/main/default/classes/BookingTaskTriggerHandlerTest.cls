/*
Name:  BookingTaskTriggerHandlerTest.cls
======================================================
======================================================
Purpose: Test Suite for Booking Trigger activity
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
public with sharing class BookingTaskTriggerHandlerTest {
    
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

    @isTest static void testIncompleteTaskCalculations(){

        //Retrieve Booking Guest
        BookingGuest__c guest = [Select Id, GuestGroup__r.Booking__c, NumberOfIncompleteTasks__c From BookingGuest__c];
        system.assertEquals(0, guest.NumberOfIncompleteTasks__c);

        //Create 20 tasks
        List<BookingTask__c> tasks = new List<BookingTask__c>();    
        //10 required
        tasks.addAll(AP23_TestDataFactory.createBookingTasks(10,guest.GuestGroup__r.Booking__c,guest.Id));
        //0 not required
        tasks.addAll(AP23_TestDataFactory.createBookingTasks(10,guest.GuestGroup__r.Booking__c,guest.Id,ApplicationConstant.BOOKING_TASK_STATUS_NOT_REQUIRED));
        
        test.startTest(); 
            GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
            system.assertEquals(20, tasks.size());
            //Insert 20 tasks - 10 complete & 10 incomplete
            insert tasks; 
            system.assertEquals(10, [Select NumberOfIncompleteTasks__c From BookingGuest__c Where Id =:guest.Id].NumberOfIncompleteTasks__c);
            //Complete 3 more actions
            List<BookingTask__c> completedTasks = new List<BookingTask__c>();   
            for(BookingTask__c incompleteTask : [Select Id, Status__c From BookingTask__c Where Status__c = :ApplicationConstant.BOOKING_TASK_STATUS_REQUIRED Limit 3]){
                incompleteTask.Status__c = ApplicationConstant.BOOKING_TASK_STATUS_COMPLETE;
                completedTasks.add(incompleteTask); 
            } 
            BookingTaskTriggerHandler.isFirstAfterUpdate = true;
            update completedTasks; 
            system.assertEquals(7, [Select NumberOfIncompleteTasks__c From BookingGuest__c Where Id =:guest.Id].NumberOfIncompleteTasks__c);
            //Re Open 2 more
            List<BookingTask__c> reopenedTasks = new List<BookingTask__c>();   
            for(BookingTask__c completedTask : [Select Id, Status__c From BookingTask__c Where Status__c = :ApplicationConstant.BOOKING_TASK_STATUS_COMPLETE Limit 2]){
                completedTask.Status__c = ApplicationConstant.BOOKING_TASK_STATUS_REQUIRED;
                reopenedTasks.add(completedTask);
            } 
            BookingTaskTriggerHandler.isFirstAfterUpdate = true;
            update reopenedTasks;
            system.assertEquals(9, [Select NumberOfIncompleteTasks__c From BookingGuest__c Where Id =:guest.Id].NumberOfIncompleteTasks__c);
            //Delete 6 incomplete tasks
            delete [Select Id From BookingTask__c Where Status__c = :ApplicationConstant.BOOKING_TASK_STATUS_REQUIRED Limit 6];
            system.assertEquals(3, [Select NumberOfIncompleteTasks__c From BookingGuest__c Where Id =:guest.Id].NumberOfIncompleteTasks__c);
        test.stopTest();

    }

}