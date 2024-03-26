/**************************************************************
@author - Simon Molloy (Golfbreaks)
@date - 24/03/2017
@description - Schedule class to schedule SalesAgentAttributeBatchUpdate class
***************************************************************/
global class SalesAgentAttributeScheduleUpdate implements schedulable {

    global void execute(SchedulableContext sc){
        SalesAgentAttributeBatchUpdate saabu = new SalesAgentAttributeBatchUpdate();
        Database.executeBatch(saabu, 100);
    }

}