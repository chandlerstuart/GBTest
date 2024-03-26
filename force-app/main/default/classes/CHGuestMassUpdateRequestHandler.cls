/*
Name:  CHGuestMassUpdateRequestHandler.cls
======================================================
======================================================
Purpose: Request Handler for CHGuestMassUpdate Data Event
(to update multiple Booking Guests in a single call)

Design Note - Updates originate from the Portal. CH API
accept multiple guests against a single booking so the 
bulk updates must update per booking.
-------
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-05-26  Initial Development.
*/
public with sharing class CHGuestMassUpdateRequestHandler implements IDataEventTypeRequestHandler{
    
    public HttpRequest buildOutboundRequest(String sObjectType, Set<Id> recordIds, HttpRequest r){

        try{
            if(r == null) r = new HttpRequest();
            if(recordIds == null || recordIds.size() == 0) return null;
            if(UserInfo.getUserName().containsIgnoreCase('Clubhouse')) return null;//Prevent callouts for updates that originate from Clubhouse (also addressed by DET Conditions)

            List<GuestEntry> guestEntries = new List<GuestEntry>();
            String bookingId;
            for(BookingGuest__c guest : [Select Id, 
                                                GuestGroup__r.Booking__c,
                                                GolfbreaksBookingGuestId__c,
                                                Account__r.Golfbreaks_Person_Id__c,
                                                Account__r.PersonTitle,
                                                FirstName__c,
                                                Surname__c,
                                                Booking_Guest_Email__c,
                                                Payment_Allocation__c From BookingGuest__c Where Id In :recordIds]){
                
                if(guest.GuestGroup__r.Booking__c == null) continue;
                if(guest.GolfbreaksBookingGuestId__c == null) continue;

                if(bookingId == null) bookingId = guest.GuestGroup__r.Booking__c;

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
            Golfbreaks.PlatformLogManager.logExceptions(e,'CHGuestMassUpdateRequestHandler','buildOutboundRequest');
            return null;
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