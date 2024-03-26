/*
Name:  BookingDocumentTriggerHandler.cls
======================================================
======================================================
Purpose: Handler for Booking Document Trigger activity
-------

======================================================
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-03-03  Initial development.
*/
public with sharing class BookingDocumentTriggerHandler {
    
    public static Boolean isFirstAfterInsert = true;
    public static Boolean isFirstAfterUpdate = true;
    public static Boolean isFirstAfterDelete = true;

    public void onAfterInsert(List<BookingDocument__c> newList, Map<Id,BookingDocument__c> newMap){
        try{
            if(isFirstAfterInsert){
                isFirstAfterInsert = false;
                calculateParentRecordSummaryTotals(null, newMap);
            }
        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'BookingDocumentTriggerHandler','onAfterInsert');
        }
    }

    public void onAfterDelete(List<BookingDocument__c> oldList, Map<Id,BookingDocument__c> oldMap){
        try{
            if(isFirstAfterDelete){
                isFirstAfterDelete = false;
                calculateParentRecordSummaryTotals(oldMap, null);
            }
        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'BookingDocumentTriggerHandler','onAfterDelete');
        }
    }

    //Evaluates record changes and triggers a recalculation of parent record summaries when required
    public void calculateParentRecordSummaryTotals(Map<Id,BookingDocument__c> oldMap, Map<Id,BookingDocument__c> newMap){

        if(newMap == null && oldMap == null) return;

        Set<Id> bookingGuestIds = new Set<Id>();
        
        Boolean isInsert = (oldMap == null && newMap != null)?true:false;
        Boolean isDelete = (oldMap != null && newMap == null)?true:false;
 
        if(isDelete){
            for(BookingDocument__c doc : oldMap.values()){
                if(doc.BookingGuest__c != null && !bookingGuestids.contains(doc.BookingGuest__c)) bookingGuestIds.add(doc.BookingGuest__c);
            }
        }else if(isInsert){
            for(BookingDocument__c doc : newMap.values()){
                //New doc has related guest record
                if(doc.BookingGuest__c != null && !bookingGuestIds.contains(doc.BookingGuest__c)) bookingGuestIds.add(doc.BookingGuest__c);
            }
        }
        if(bookingGuestIds.size()>0){
            BookingGuestTriggerBL.calculateTotalBookingDocuments(bookingGuestIds);
        }
    }
}