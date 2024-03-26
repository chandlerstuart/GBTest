/*
Name: NewLeadHandler.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Local class to process New Leads generated from Inbound API Enquiries/Flow Enquiries
and perform activities which require access to the local schema
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-07-20  Initial development.
*/
public with sharing class NewLeadHandler implements IEnquiryRecordHandler{

    public Boolean processEnquiries(List<EnquiryManager.Enquiry> enquiries) {
        try{
            if(enquiries == null) return true;
            //Calculate the Enquiry.TripDetails.territoryId
            SalesEnquiryHandler.calculateSalesEnquiryTerritories(enquiries);
        }catch(exception e){
            PlatformLogManager.logExceptions(e, 'NewLeadHandler', 'processEnquiries');
            return false;
        }
        return true;
    }

}