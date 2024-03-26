/**
* @Class Name: AP13_CaseAssignmentRuleBatchSchedule 
* @developer:  Aldric Seril 
* @date:       04/05/2016
* @description: Call AP14_CaseAssignmentRuleBatch
*/

global class AP13_CaseAssignmentRuleBatchSchedule implements Schedulable{
    global void execute(SchedulableContext sc) {
        AP14_CaseAssignmentRuleBatch reassignQueue = new AP14_CaseAssignmentRuleBatch();
        database.executebatch(reassignQueue);
    }
}