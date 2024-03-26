/*
Name:  IEnquiryRecordHandler.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Interface class - provides abstracted pluggable interface for record handling logic. 

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-05-15  Initial development.
1.1  J Radcliffe   2019-06-03  Change return from List<EnquiryManager.Enquiry> to Boolean (runitime exception check)
*/
global interface IEnquiryRecordHandler {
    Boolean processEnquiries(List<EnquiryManager.Enquiry> enquiries);
}