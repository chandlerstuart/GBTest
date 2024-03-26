/*
Name:  UpdateLeadOppAmountSchedule.cls
======================================================
======================================================
Purpose:
-------
Scheduled class to run UpdateLeadOppAmountBatch
======================================================
======================================================
History
------- 
Ver. Author             Date         Detail
1.0  Simon Molloy	    2017-11-15   Initial development
*/
global class UpdateLeadOppAmountSchedule implements schedulable {

    global void execute(SchedulableContext sc){
        UpdateLeadOppAmountBatch uloabLead = new UpdateLeadOppAmountBatch();
        UpdateLeadOppAmountBatch uloabOpp = new UpdateLeadOppAmountBatch();
        
        uloabLead.whichObject = 'LEAD';
        uloabOpp.whichObject = 'OPPORTUNITY';

        Database.executeBatch(uloabLead,2000);
        Database.executeBatch(uloabOpp,2000);
    }

}