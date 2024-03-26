/*
Name: FlowSalesEnquiryHandler.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Local class to process Inbound API Enquiries/Flow Sales Enquiries
and perform activities which require access to the local schema
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2020-03-27  Initial development.
*/
public with sharing class FlowSalesEnquiryHandler implements IEnquiryRecordHandler{
    
    public Boolean processEnquiries(List<EnquiryManager.Enquiry> enquiries) {
        try{
            if(enquiries == null) return true;
            //Set Defaults (i.e. construct the Opportunity Name from the Account details and current date)
            SalesEnquiryHandler.setDefaults(enquiries);
        }catch(exception e){
            PlatformLogManager.logExceptions(e, 'FlowSalesEnquiryHandler', 'processEnquiries');
            return false;
        }
        return true;
    }
}