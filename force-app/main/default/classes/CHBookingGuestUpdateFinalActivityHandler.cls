/*
Name:  CHBookingGuestUpdateFinalActivityHandler.cls
======================================================
======================================================
Purpose:
-------
This handler unlocks the booking's related guest records
following a callout.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2023-07-25  Initial development.
1.1  J Radcliffe   2023-08-24  Unlock any 'stuck' guest records. This means more recent updates will recover any failures for unrelated bookings.
*/
global with sharing class CHBookingGuestUpdateFinalActivityHandler implements IDataEventTypeFinalActivityHandler{

    public class CustomException extends Exception{}
    @TestVisible public static Boolean throwLockingError = false;

    public static final String lockError = 'UNABLE_TO_LOCK_ROW';//Standard locking error

    global void execute(DataEventType__mdt det, OutboundCallout__c oc){

        try{
            //Validate input
            if(oc == null || oc.RecordId__c == null || oc.DataEventType__c == null) throw new CustomException('Error! Insufficient data provided to handler > '+oc);
            handleFinalActivity(oc);                
        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'CHBookingGuestUpdateFinalActivityHandler','execute');
        }
    }

    //Lookup pending/processing callouts (Data Event Requests or Outbound Callouts). If no callouts pending, unlock the guest records (IsLockedSystem__c = false).
    public static void handleFinalActivity(OutboundCallout__c oc){
    
        //Exit if there is a pending scheduled callout for the booking (indicating the lock must remain on the guest records and will be released by the callouts response handler).
        DateTime dtThreshold = System.now().addSeconds(-30);
        if([Select Count() From DataEventRequest__c Where 
                                                        RecordId__c = :oc.RecordId__c 
                                                        and DataEventType__c =:oc.DataEventType__c 
                                                        and CalloutDate__c >=:dtThreshold 
                                                        and Status__c = 'New']>0) 
                                                        return;

        //Exit if there is another queued/in-progress callout for the booking (indicating the lock must remain on the guest records and will be released by the callouts response handler).
        if([Select Count() From OutboundCallout__c Where 
                                                        RecordId__c = :oc.RecordId__c 
                                                        and DataEventType__c =:oc.DataEventType__c 
                                                        and Id != :oc.Id and 
                                                        (Status__c = :Label.Picklist_Value_OutboundCallout_Status_New 
                                                        or Status__c = :Label.Picklist_Value_OutboundCallout_Status_Pending_Retry
                                                        or Status__c = :Label.Picklist_Value_OutboundCallout_Status_Retrying)]>0) 
                                                        return;

        //Query and release locked records. //1.1+ Include seemlingly 'stuck' records for unrelated bookings.
        DateTime guestLockReleaseThreshold = System.now().addMinutes(-10);//1.1+
        List<BookingGuest__c> guestsForUpdate = [Select Id, IsLockedSystem__c From BookingGuest__c Where IsLockedSystem__c = true and (Booking__c =:oc.RecordId__c or LastModifiedDate <=:guestLockReleaseThreshold)];
        if(guestsForUpdate.size()>0){
            for(BookingGuest__c guest : guestsForUpdate){
                guest.IsLockedSystem__c = false;//Unlock records
            }
            try{
                if(Test.isRunningTest() && throwLockingError) throw new CustomException(lockError);//Simulate locking error
                update guestsForUpdate;//Attempt update
            }catch(Exception e){
                if(e.getMessage().containsIgnoreCase(lockError)){//If record is locked by SF, queue a retry.
                    system.enqueueJob(new CHBookingGuestUpdateFinalActivityHandlerRetry(oc));
                }else{//Else log and exit.
                    PlatformLogManager.logExceptions(e, 'CHBookingGuestUpdateFinalActivityHandler', 'handleFinalActivity');
                }
            }
        }
    }

    public class CHBookingGuestUpdateFinalActivityHandlerRetry implements Queueable{

        OutboundCallout__c oc;

        public CHBookingGuestUpdateFinalActivityHandlerRetry(OutboundCallout__c oc){
            this.oc = oc;
        }

        public void execute(QueueableContext context) {
            try{
                if(Test.isRunningTest() && throwLockingError) throwLockingError = false;//Switch off locking failure on retry
                handleFinalActivity(oc);                
            }catch(Exception e){
                Golfbreaks.PlatformLogManager.logExceptions(e,'CHBookingGuestUpdateFinalActivityHandlerRetry','execute');
            }
        }
    }


}