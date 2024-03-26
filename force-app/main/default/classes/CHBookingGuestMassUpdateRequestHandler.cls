/*
Name:  CHBookingGuestMassUpdateRequestHandler.cls
======================================================
======================================================
Purpose: Request Handler for sending all Booking Guest records 
related to the specified booking in a single api call.

Design Note - CH will only accept guest updates for a single booking,
meaning this method should only be called once per booking (expects 1 booking id).
-------
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-06-27  Initial Development.
*/
public with sharing class CHBookingGuestMassUpdateRequestHandler implements IDataEventTypeRequestHandler{

    public class CustomException extends Exception {}
    @TestVisible public static final String singleBookingOnlyError = 'Clubhouse only accepts updates for a single booking. Therefore, only one Booking record can be processed (per request).';
    
    public HttpRequest buildOutboundRequest(String sObjectType, Set<Id> recordIds, HttpRequest r){

        try{
            if(r == null) r = new HttpRequest();
            if(recordIds == null || recordIds.size() == 0) return null;
            if(recordIds.size()>1) throw new CustomException(singleBookingOnlyError);

            String bookingId;
            for(Id recId : recordIds){bookingId=recId;break;}

            List<GuestEntry> guestEntries = new List<GuestEntry>();
            for(BookingGuest__c guest : [Select Id, 
                                                GuestGroup__r.Booking__c,
                                                GolfbreaksBookingGuestId__c,
                                                Account__r.Golfbreaks_Person_Id__c,
                                                Account__r.PersonTitle,
                                                FirstName__c,
                                                Surname__c,
                                                Booking_Guest_Email__c,
                                                Payment_Allocation__c From BookingGuest__c Where GuestGroup__r.Booking__c = :bookingId]){
                
                if(guest.GolfbreaksBookingGuestId__c == null) continue;

                GuestEntry g = new GuestEntry();
                g.GolfbreaksClientID = Integer.valueOf(guest.Account__r.Golfbreaks_Person_Id__c);
                g.GolfbreaksGuestID = Integer.valueOf(guest.GolfbreaksBookingGuestId__c);
                g.Forename = guest.FirstName__c;
                g.Surname = guest.Surname__c;
                g.Title = guest.Account__r.PersonTitle;
                g.GuestEmail = guest.Booking_Guest_Email__c;
                g.ExpectedPayment = guest.Payment_Allocation__c;
                guestEntries.add(g);
            }

            if(guestEntries.size()>0){
                Data requestData = new Data(
                    guestEntries,
                    bookingId
                );
                r.setBody(JSON.serialize(requestData));
                return r;
            }

            return null;

        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'CHBookingGuestMassUpdateRequestHandler','buildOutboundRequest');
            return r;
        }

    }

    public Class Data{
        public String SalesforceBookingId;
        public List<GuestEntry> UpdateGuests;
        public Data(List<GuestEntry> UpdateGuests, String SalesforceBookingId){
            this.UpdateGuests = UpdateGuests;
            this.SalesforceBookingId = SalesforceBookingId;
        }
    }

    public Class GuestEntry{
        public Integer GolfbreaksGuestID;
        public Integer GolfbreaksClientID;
        public String Title;
        public String Forename;
        public String Surname;
        public String GuestEmail;
        public Decimal ExpectedPayment;
        public GuestEntry(){}
    }

}