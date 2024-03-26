/**
* @date -           18/08/2016
* @description -    Implement schedulable for the batch process AP59_AdminCaseBatch 
* #############Change Log#############
* Modified by     Version     Change Date
**/

global class AP59_AdminCaseBatchSchedule implements Schedulable{
    global void execute(SchedulableContext sc) {
        AP59_AdminCaseBatch adBtch = new AP59_AdminCaseBatch();
        database.executebatch(adBtch);
    }
}