/*
Name: AssistedOnlineBookingHandler.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Local class to process Inbound API Assisted Online Bookings
and perform activities which require access to the local schema
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-05-20  Initial development.
*/
public with sharing class AssistedOnlineBookingHandler implements IEnquiryRecordHandler{
    
    public Boolean processEnquiries(List<EnquiryManager.Enquiry> enquiries) {
        try{
            if(enquiries == null) return true;
            //Calculate the Enquiry.TripDetails.territoryId for de-duplication purposes
            SalesEnquiryHandler.calculateSalesEnquiryTerritories(enquiries);
            //Set Defaults (i.e. construct the Opportunity Name from the Account details and current date)
            SalesEnquiryHandler.setDefaults(enquiries);
        }catch(exception e){
            PlatformLogManager.logExceptions(e, 'AssistedOnlineBookingHandler', 'processEnquiries');
            return false;
        }
        return true;
    }
}