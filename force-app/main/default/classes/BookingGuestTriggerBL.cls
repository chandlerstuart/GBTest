/*
Name:  BookingGuestTriggerBL.cls
======================================================
======================================================
Purpose: Handles Business Logic for Booking Task related activity
-------

======================================================
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-03-03  Initial development.
*/
public with sharing class BookingGuestTriggerBL {
    
    //Sets the NumberOfIncompleteTasks__c field with a count of open related Booking Tasks
    public static void calculateTotalIncompleteBookingTasks(Set<Id> bookingGuestIds){

        system.debug('calculateTotalIncompleteBookingTasks Start');
 
        if(bookingGuestIds == null) return;
        List<BookingGuest__c> guestsForUpdate = new List<BookingGuest__c>();
        for(BookingGuest__c guest : [Select Id, NumberOfIncompleteTasks__c, (Select Id From Booking_Tasks__r Where Status__c != :ApplicationConstant.BOOKING_TASK_STATUS_NOT_REQUIRED and Status__c != :ApplicationConstant.BOOKING_TASK_STATUS_COMPLETE) From BookingGuest__c Where Id In :bookingGuestIds]){
            if(guest.NumberOfIncompleteTasks__c != guest.Booking_Tasks__r.size()){
                guest.NumberOfIncompleteTasks__c = guest.Booking_Tasks__r.size();
                guestsForUpdate.add(guest);
            }
        }
        if(guestsForUpdate.size()>0){
            system.debug('calculateTotalIncompleteBookingTasks Updating');
            Database.SaveResult[] results = Database.update(guestsForUpdate,false);
            Golfbreaks.PlatformLogManager.logExceptions(results,'BookingGuestTriggerBL','calculateTotalIncompleteBookings',guestsForUpdate);
        }
        system.debug('calculateTotalIncompleteBookingTasks End');

    }

    //Sets the NumberOfBookingDocuments__c field with a count related Booking Documents
    public static void calculateTotalBookingDocuments(Set<Id> bookingGuestIds){
        if(bookingGuestIds == null) return;
        List<BookingGuest__c> guestsForUpdate = new List<BookingGuest__c>();
        for(BookingGuest__c guest : [Select Id, NumberOfBookingDocuments__c, (Select Id From Booking_Documents__r) From BookingGuest__c Where Id In :bookingGuestIds]){
            if(guest.NumberOfBookingDocuments__c != guest.Booking_Documents__r.size()){
                guest.NumberOfBookingDocuments__c = guest.Booking_Documents__r.size();
                guestsForUpdate.add(guest);
            }
        }
        if(guestsForUpdate.size()>0){
            Database.SaveResult[] results = Database.update(guestsForUpdate,false);
            Golfbreaks.PlatformLogManager.logExceptions(results,'BookingGuestTriggerBL','calculateTotalBookingDocuments',guestsForUpdate);
        }
    }

}