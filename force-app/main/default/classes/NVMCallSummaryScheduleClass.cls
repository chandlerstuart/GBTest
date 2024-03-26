/*
Name:  NVMCallSummaryScheduleClass.cls
Copyright © 2016  Golfbreaks
======================================================
======================================================
Purpose:
-------
Schedule class for the batch class NVMCallSummaryBatchClass.
======================================================
======================================================
History
------- 
Ver. Author          Date        Detail
1.0  Simon Molloy    2016-09-13  Initial development.
*/
global class NVMCallSummaryScheduleClass implements Schedulable {
    global void execute(SchedulableContext sc) {
        //Make sure we do not run this if the Account Triggers & Workflows are turned ON
        //TODO : Do we need to worry about triggers?
        //OrgSettings__c orgSettings = OrgSettings__c.getInstance();
        //if( orgSettings<> null && orgSettings.TriggersActive__c ){
        //    return;
        //}else {
            NVMCallSummaryBatchClass ncsbc = new NVMCallSummaryBatchClass();

            String query = 'select Id, NVMStatsSF__ChkStr__c, Skill__c, NVMStatsSF__Date__c, NVMStatsSF__Ring_List__c, NVMStatsSF__NVM_AgentID__c, ';
            query += 'NVMStatsSF__Agent_List__c, Batch_Processed__c from NVMStatsSF__NVM_Call_Summary__c where Batch_Processed__c = FALSE ';
            
            ncsbc.query = query;

            Id scheduledBatchId = Database.executeBatch(ncsbc, 200);    
        //}
    }
}