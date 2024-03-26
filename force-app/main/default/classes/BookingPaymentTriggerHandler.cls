/*
Name:  BookingPaymentTriggerHandler.cls
======================================================
======================================================
Purpose: Handler for all Booking Payment Trigger Activity
-------

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2021-11-02  Initial development.
1.1  J Radcliffe   2022-07-15  Enable Integration Framework (Data Events)
1.2  J Radcliffe   2023-01-19  Bug Fix. calculateBookingGuestAmountPaid replace reference to currency with number (formula). Currency is implicitly converted to the currency of the running user, causing inaccuracies in the results.
*/
public with sharing class BookingPaymentTriggerHandler {
    
    private Boolean isExecuting=false;
    private Integer batchSize;

    public static Boolean isFirstAfterUpdate = true;

    public BookingPaymentTriggerHandler(boolean isExecuting, integer size){
        this.isExecuting = isExecuting;
        this.batchSize = size;
    }

    //& trigger action methods.        
    public void onAfterInsert(List<Booking_Payment__c> insertedRecords, Map<Id, Booking_Payment__c> newMap){    
        calculateBookingGuestAmountPaid(insertedRecords,null);
        DataEventTypeTriggerHandler dth = new DataEventTypeTriggerHandler(ApplicationConstant.OBJECT_TYPE_BOOKING_PAYMENT);//1.1+
        dth.handleTriggerOperationType();//1.1+
    }
    
    public void onAfterUpdate(Booking_Payment__c[] updatedRecords, Map<Id, Booking_Payment__c> newMap, Map<Id, Booking_Payment__c> oldMap){
        if (isFirstAfterUpdate || Test.isRunningTest()){//1.0. Bulk tests require multiple trigger executions (per 200 records).
            isFirstAfterUpdate=false;
            calculateBookingGuestAmountPaid(updatedRecords,oldMap);
            DataEventTypeTriggerHandler dth = new DataEventTypeTriggerHandler(ApplicationConstant.OBJECT_TYPE_BOOKING_PAYMENT);//1.1+
            dth.handleTriggerOperationType();//1.1+
        }
    }
        
    public void onAfterDelete(List<Booking_Payment__c> deletedRecords, Map<Id, Booking_Payment__c> oldMap){
        calculateBookingGuestAmountPaid(deletedRecords,null);
    }
    
    public void onAfterUndelete(List<Booking_Payment__c> undeletedRecords, Map<Id, Booking_Payment__c> newMap){
        calculateBookingGuestAmountPaid(undeletedRecords,null);
    }
    //& End trigger action methods.

    //& Helper methods.
    private void calculateBookingGuestAmountPaid(List<Booking_Payment__c> affectedRecords, Map<Id, Booking_Payment__c> idToUpdatedRecord){
        try {
        
            Boolean isUpdate = (idToUpdatedRecord!=null);
    
            Set<Id> affectedBookingGuestIds = new Set<Id>();
    
            for (Booking_Payment__c bp : affectedRecords){
    
                if (isUpdate){
                    if (bp.Booking_Guest__c!=idToUpdatedRecord.get(bp.Id).Booking_Guest__c){
                        if (bp.Booking_Guest__c!=null) affectedBookingGuestIds.add(bp.Booking_Guest__c);
                        if (idToUpdatedRecord.get(bp.Id).Booking_Guest__c!=null) affectedBookingGuestIds.add(idToUpdatedRecord.get(bp.Id).Booking_Guest__c);
                    } else if (bp.Booking_Guest__c!=null && bp.PaymentAmount__c!=idToUpdatedRecord.get(bp.Id).PaymentAmount__c) affectedBookingGuestIds.add(bp.Booking_Guest__c);
    
                } else if (bp.Booking_Guest__c!=null && bp.PaymentAmount__c!=null && bp.PaymentAmount__c>0) affectedBookingGuestIds.add(bp.Booking_Guest__c);//1.1. Ignore zero payment amounts.
            }
            if (affectedBookingGuestIds.isEmpty()) return;
    
            Id bookingGuestId;
            Decimal totalAmountPaid;
            Map<Id, BookingGuest__c> idToBookingGuestToUpdate = new Map<Id, BookingGuest__c>();
    
            for (Id guestId : affectedBookingGuestIds) idToBookingGuestToUpdate.put(guestId, new BookingGuest__c(Id=guestId,Amount_Paid__c=0));

            for (AggregateResult ar : [select sum(PaymentAmountInt__c) totalPaymentAmount, Booking_Guest__c bookingGuestId//1.2~ Replaced field reference PaymentAmount__c > PaymentAmountInt__c
                                        from Booking_Payment__c
                                        where Booking_Guest__c in:affectedBookingGuestIds
                                        group by Booking_Guest__c]){
            
                bookingGuestId = (Id)ar.get('bookingGuestId');
                idToBookingGuestToUpdate.get(bookingGuestId).Amount_Paid__c = ar.get('totalPaymentAmount')==null ? 0 : (Decimal)ar.get('totalPaymentAmount');
            }
            
            Database.SaveResult[] results = Database.update(idToBookingGuestToUpdate.values(),false);
            Golfbreaks.PlatformLogManager.logExceptions(results,'BookingPaymentTriggerHandler','calculateBookingGuestAmountPaid',idToBookingGuestToUpdate.values());
    
        } catch(Exception e){ for (Booking_Payment__c bp : affectedRecords) { bp.addError(e.getMessage()); } }       
    }    
    //& End Helper methods.
}