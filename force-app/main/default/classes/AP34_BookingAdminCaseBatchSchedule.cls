/**
* @author -         Patrick Villarica (Accenture)
* @date -           14/04/2016
* @description -    Implement schedulable for the batch process AP31_BookingAdminCaseBatch 
* #############Change Log#############
* Modified by     Version     Change Date
**/

global class AP34_BookingAdminCaseBatchSchedule implements Schedulable{
    global void execute(SchedulableContext sc) {
        AP31_BookingAdminCaseBatch executeBookingAdminCaseBatch = new AP31_BookingAdminCaseBatch();
        database.executebatch(executeBookingAdminCaseBatch );
    }
}