/*
Name:  NVMCallSummaryBatchClass.cls
Copyright © 2016  Golfbreaks
======================================================
======================================================
Purpose:
-------
Test class NVMCallSummaryBatchClass
======================================================
======================================================
History
------- 
Ver. Author          Date        Detail
1.0  Simon Molloy    2016-09-13  Initial development.
*/
@isTest
private class NVMCallSummaryBatchClassTest {
    @testSetup
    public static void setup() {
        Integer TEST_REC_SIZE=200;
       
        List<NVMStatsSF__NVM_Call_Summary__c> callSummaries = new List<NVMStatsSF__NVM_Call_Summary__c>();
        NVMStatsSF__NVM_Call_Summary__c callSummary; 
        
        for (Integer n=0; n<TEST_REC_SIZE; n++){
            callSummary = new NVMStatsSF__NVM_Call_Summary__c(); 
        
            callSummary.NVMStatsSF__NVM_Service_Name__c = 'test record';
            callSummary.NVMStatsSF__Ring_List__c = '100:15,200:10';
            callSummary.NVMStatsSF__Agent_List__c = '200-5,300-20';
            callSummary.NVMStatsSF__NVM_AgentID__c = '100';
            callSummary.NVMStatsSF__ChkStr__c = '20150128092531-S1-0-000-Start OK|20150128092531-NA-0-001-SkillTagger~ST Service Ops|20150128092531-NA-0-001-SkillTagger~ST Consumer Overview|20150128092845-S-194-072-END~AN Thank you~Caller|';
            callSummaries.add(callSummary);
        }        
        
        insert callSummaries;

    }

    static testMethod void testBatchRun() {

    	List<NVMStatsSF__NVM_Call_Summary__c> checkList = [select Id, Skill__c, Batch_Processed__c from NVMStatsSF__NVM_Call_Summary__c];
        for (NVMStatsSF__NVM_Call_Summary__c c : checkList){
            system.assertEquals(FALSE, c.Batch_Processed__c);
            system.assertEquals(null , c.Skill__c);
        }

        List<NVM_Call_Summary_Agent__c> agentList = [select Id from NVM_Call_Summary_Agent__c];

        system.debug('*** -- agentList Before = ' + agentList + ' -- ***');

    	test.startTest();
    	NVMCallSummaryBatchClass ncsbc = new NVMCallSummaryBatchClass();
        //String query = 'select Id, NVMStatsSF__ChkStr__c, Skill__c, NVMStatsSF__Date__c, NVMStatsSF__Ring_List__c, NVMStatsSF__NVM_AgentID__c, ';
        //query += 'NVMStatsSF__Agent_List__c, Batch_Processed__c from NVMStatsSF__NVM_Call_Summary__c where Batch_Processed__c = FALSE ';
    	//ncsbc.query = query;
    	Id testBatchId = Database.executeBatch(ncsbc, 200);

    	test.stopTest();

		checkList = [select Id, Skill__c, Batch_Processed__c from NVMStatsSF__NVM_Call_Summary__c];
        for (NVMStatsSF__NVM_Call_Summary__c c : checkList){
            system.assertEquals(TRUE, c.Batch_Processed__c);
            system.assertNotEquals(null , c.Skill__c);
        }

        agentList = [select Id from NVM_Call_Summary_Agent__c];
        system.debug('*** -- agentList after = ' + agentList + ' -- ***');

    }

}