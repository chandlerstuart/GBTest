/**************************************************************
@author - Simon Molloy (Golfbreaks)
@date - 10/10/2016
@description - Batch class to update Parking Spaces avalability due to annual leave etc.
***************************************************************/
global class ParkingSpaceScheduleUpdateClass implements schedulable {

    global void execute(SchedulableContext sc){
        ParkingSpaceBatchUpdateClass psbuc = new ParkingSpaceBatchUpdateClass();
        Database.executeBatch(psbuc, 100);
    }

}