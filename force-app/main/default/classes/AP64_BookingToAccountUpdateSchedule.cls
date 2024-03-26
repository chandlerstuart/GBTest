/**************************************************************
@author - Simon Molloy (Golfbreaks)
@date - 28/03/2017
@description - Scheduled class to run and execute AP63_BookingToAccountBatchUpdate
***************************************************************/
global class AP64_BookingToAccountUpdateSchedule implements schedulable {

    global void execute(SchedulableContext sc){
        AP63_BookingToAccountBatchUpdate btabu = new AP63_BookingToAccountBatchUpdate();
        Database.executeBatch(btabu, 100);
    }

}