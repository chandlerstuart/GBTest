/*
Name:  ClubhouseEnquiryUtilityClass.cls
======================================================
======================================================
Purpose:
-------
Utility class offering various methods to update Lead records

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon Molloy  2017-07-27  Initial development.
*/
public with sharing class ClubhouseEnquiryUtilityClass {
	
	//2017-07-27 : SM : This method takes in a list of Leads, and for each one calls out to Clubhouse to create an Enquiry
	//2017-07-27 : SM : No save is done in the callout method as we are running a web service.  Save will be done in the calling class
	public static List<Lead> createClubhouseEnquiryRecords(List<Lead> leadList){
		List<Lead> clubhouseLeads = new List<Lead>();
		
		for (Lead l : leadList){
			if (test.isRunningTest()){
				clubhouseLeads.add(WS01_RebarHTTPCallout.outboundMessageCallerLead(l.Id));	
			}else {
				if (null == l.GolfbreaksEnquiryId__c){
					clubhouseLeads.add(WS01_RebarHTTPCallout.outboundMessageCallerLead(l.Id));
				}	
			}
		}

		return clubhouseLeads;
	}


}