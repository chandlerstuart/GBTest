/**
Name:  AP40_BookingLeadCreationBatchSchedule .cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Scheduler for AP38_BookingLeadCreationBatch
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  M.Cebrian  2016-04-25  Initial development.
**/
global class AP40_BookingLeadCreationBatchSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        AP38_BookingLeadCreationBatch executeBookingLeadCreationBatch = new AP38_BookingLeadCreationBatch();
        database.executebatch(executeBookingLeadCreationBatch );
    }
}