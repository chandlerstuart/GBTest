/*
Name:  ClubhouseEnquiryCreateSchedule.cls
======================================================
======================================================
Purpose:
-------
Scheduled Class used to call ClubhouseEnquiryCreateBatch

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon Molloy  2017-07-27  Initial development.
*/
global class ClubhouseEnquiryCreateSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        ClubhouseEnquiryCreateBatch cecb = new ClubhouseEnquiryCreateBatch();
        Database.executebatch(cecb,1);
    }
}