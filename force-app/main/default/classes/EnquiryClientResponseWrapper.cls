/**
* @author -         Merari Cebrian (Accenture)
* @date -           14/04/2016
* @description -    A response wrapper class of Client type Enquiry
* #############Change Log#############
* Modified by     Version     Change Date
* Simon M.        2.0         05/12/2016    New property for Portal 2.0 View Enquiry GUID
**/
public with sharing class EnquiryClientResponseWrapper{ 
    public String SalesforceClientID;
    public String GolfbreaksClientID;
    public String GolfbreaksEnquiryID;
    public String GolfbreaksEnquiryKey;
    public String ClientStatus;
    public String Message;
}