/*
Name:  BookingGuestTriggerHandler.cls
======================================================
======================================================
Purpose: Handler for all Booking Guest Trigger Activity
-------

======================================================
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2021-09-13  Initial development.
1.1  J Radcliffe   2021-01-19  New method onAfterUpdate
1.2  J Radcliffe   2024-02-13  Invoke assignPublicId method (GUID Generator) - Create a PublicId__c before insert.
*/
public with sharing class BookingGuestTriggerHandler {

    public static Boolean isFirstAfterInsert = true;
    public static Boolean isFirstBeforeInsert = true;//1.2+
    public static Boolean isFirstBeforeUpdate = true;
    public static Boolean isFirstAfterUpdate = true;

    @testVisible public static DateTime currentDTOverride;

    public static Map<Integer,String> randomCharacterMap;

    public void onAfterInsert(List<BookingGuest__c> bookingGuests){
        try{
            if(isFirstAfterInsert){
                isFirstAfterInsert = false;
                calculateBookingGuestInvitationKey(bookingGuests);
                DataEventTypeTriggerHandler dth = new DataEventTypeTriggerHandler(ApplicationConstant.OBJECT_TYPE_BOOKING_GUEST);
                dth.handleTriggerOperationType();
            }
        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'BookingGuestTriggerHandler','onAfterInsert');
        }
    }

    //1.2+
    public void onBeforeInsert(List<BookingGuest__c> bookingGuests){
        try{
            if(isFirstBeforeInsert){
                isFirstBeforeInsert = false;
                GUIDGenerator.assignPublicId(bookingGuests);
            }
        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'BookingGuestTriggerHandler','onBeforeInsert');
        }
    }

    public void onBeforeUpdate(List<BookingGuest__c> bookingGuests, Map<Id,BookingGuest__c> bookingGuestsMap, List<BookingGuest__c> oldBookingGuests, Map<Id,BookingGuest__c> oldBookingGuestsMap){
        try{
            if(isFirstBeforeUpdate){
                isFirstBeforeUpdate = false;
                //validateInvitationKey(bookingGuests, oldBookingGuestsMap);
                calculateBookingGuestInvitationKey(bookingGuests);
            }
        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'BookingGuestTriggerHandler','onBeforeUpdate');
        }
    }

    public void onAfterUpdate(List<BookingGuest__c> bookingGuests, Map<Id,BookingGuest__c> bookingGuestsMap, List<BookingGuest__c> oldBookingGuests, Map<Id,BookingGuest__c> oldBookingGuestsMap){
        try{
            if(isFirstAfterUpdate){
                isFirstAfterUpdate = false;
                //validateInvitationKey(bookingGuests, oldBookingGuestsMap);
                calculateBookingGuestInvitationKey(bookingGuests);
                DataEventTypeTriggerHandler dth = new DataEventTypeTriggerHandler(ApplicationConstant.OBJECT_TYPE_BOOKING_GUEST);
                dth.handleTriggerOperationType();
            }
        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'BookingGuestTriggerHandler','onAfterUpdate');
        }
    }

    //This method set the Unique Identifier for a Booking Guests' portal invitation (36 characters)
    //Comprised of encoded SF Id interspersed by current D/T values to guarantee it is uniqueness.
    public static void calculateBookingGuestInvitationKey(List<BookingGuest__c> bookingGuests){

        List<BookingGuest__c> bookingGuestsForUpdate = new List<BookingGuest__c>();

        for(BookingGuest__c guest : bookingGuests){
            if(guest.Invitation_Key__c == null){
                DateTime currentDT = (currentDTOverride != null && Test.isRunningTest())?currentDTOverride:system.now();//The key will be derived from both the current date/time and randomly calculated characters
                String encodedId = EncodingUtil.base64Encode(Blob.valueof(guest.Id));              
                String part1 = encodedId.substring(0,encodedId.length()/4);
                String part2 = encodedId.substring(encodedId.length()/4,encodedId.length()/2);
                String part3 = encodedId.substring(encodedId.length()/2,(encodedId.length()/4)*3);
                String part4 = encodedId.substring((encodedId.length()/4)*3,encodedId.length());
                String invitationKey;
                invitationKey = 'G-'+part1;
                invitationKey = invitationKey+'-'+currentDT.millisecond()+currentDT.hour();
                invitationKey = invitationKey+'-'+part2;
                invitationKey = invitationKey+'-'+currentDT.minute()+currentDT.second()+currentDT.year();
                invitationKey = invitationKey+'-'+part3;
                invitationKey = invitationKey+'-'+currentDT.day()+currentDT.month();          
                invitationKey = invitationKey+'-'+part4;    
                if(Trigger.isAfter && Trigger.isInsert){
                    bookingGuestsForUpdate.add(new BookingGuest__c(Id=guest.Id,Invitation_Key__c=invitationKey));//Cannot modify trigger record after insert, create new and update
                }else{
                    guest.Invitation_Key__c = invitationKey;
                }
            }
        }
        if(bookingGuestsForUpdate.size()>0){
            Database.SaveResult[] results = Database.update(bookingGuestsForUpdate,false);
            Golfbreaks.PlatformLogManager.logExceptions(results,'BookingGuestTriggerHandler','calculateBookingGuestInvitationKey',bookingGuestsForUpdate);
        }
    }

}