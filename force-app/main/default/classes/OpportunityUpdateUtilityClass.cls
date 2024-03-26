/*
Name:  OpportunityUpdateUtilityClass.cls
======================================================
======================================================
Purpose:
-------
Utility class offering various methods to update Opportunity records

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon Molloy  2017-06-28  Initial development.
1.1  J Radcliffe   2019-07-10  Replaced local constant with App Constant
*/
public with sharing class OpportunityUpdateUtilityClass {
  //public static final String OPP_STAGE_TRIP_COMPLETED = '6c. Trip Completed'; 1.1-
  //2017-06-28 : SM : This method takes in a List of Opportunities, pulls in related Bookings,
  //2016-06-28 : SM : and if the Travel Return Date is today, set the Opportunity stage to Trip Completed
  public static List<Opportunity> updateToTripComplete(List<Opportunity> oppList){
    Set<Id> oppIdSet = new Set<Id>();
    Map<Id, Booking__c> bookingMap = new Map<Id, Booking__c>();

    for (Opportunity o : oppList){
      oppIdSet.add(o.Id);
    }

    for (Booking__c b : [select Id, TECH_Opportunity__c from Booking__c where TravelReturnDate__c <= TODAY and TECH_Opportunity__c in :oppIdSet]){
      bookingMap.put(b.TECH_Opportunity__c, b);
    }

    for (Opportunity o : oppList){
      if (null != bookingMap.get(o.Id)){
        //o.StageName = OPP_STAGE_TRIP_COMPLETED; //1.1-
        o.StageName = ApplicationConstant.OPP_STAGE_TRIPCOMPLETED; //1.1
      }
    }

    return opplist;

  }


}