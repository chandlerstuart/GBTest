/*
Name:  OpportunityStageUpdateSchedule.cls
======================================================
======================================================
Purpose:
-------
Scheduled Class used to call OpportunityStageUpdateBatch

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon Molloy  2017-06-30  Initial development.
*/
global class OpportunityStageUpdateSchedule implements Schedulable {
	global void execute(SchedulableContext sc) {
		OpportunityStageUpdateBatch osub = new OpportunityStageUpdateBatch();
		Database.executebatch(osub);
	}
}