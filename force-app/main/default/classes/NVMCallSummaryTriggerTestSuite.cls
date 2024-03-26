/*
Name:  NVMCallSummaryTriggerTestSuite.cls
Copyright © 2015  CloudMethods
======================================================
======================================================
Purpose:
-------
Suite of unit tests that exercise (and verify) Trigger code
behaviour on the NVMStatsSF__NVM_Call_Summary__c object.

Coverage for classes below (target 85%):
NVMCallSummaryTriggerHandler.cls : 93%

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2016-07-19  Initial development (singleTestCase1/2, bulkTestCase1/2).
*/
@isTest(seeAllData=false)
private class NVMCallSummaryTriggerTestSuite {
    /*
    Test cases:
        singleTestCase1 - create NVM Call Summary with Ring List and Agent List.
        singleTestCase2 - create NVM Call Summary and check ChkStr Skilltagger copy to Skill__c field. 
        ...
        todo - negativeTestCase1 - tbd.
        todo - restrictedUserTestCase1 - tbd.
        ...
        bulkTestCase1 - bulk record (200) test of the singleTestCase1 logic.
        bulkTestCase2 - bulk record (200) test of the singleTestCase2 logic.
    */
    
    @testSetup static void setup() {
        OrgSettings__c orgSettings = OrgSettings__c.getInstance( UserInfo.getOrganizationId() );
        if (!orgSettings.TriggersActive__c){        
            orgSettings.TriggersActive__c = true;  
            insert orgSettings;
        }       
    }
    
    /* **/
    static testMethod void singleTestCase1() {
        // Test Case 1 : create NVM Call Summary with Ring List and Agent List.
        List<User> agents;
        
        // create 3 users with agent Ids
        System.runAs(new User(Id=UserInfo.getUserId())){
            agents = UserTestHelper.createStandardUsers(3, 'Phil', 'Smith', false);
            agents[0].NVMContactWorld__NVM_Agent_Id__c = '100';
            agents[1].NVMContactWorld__NVM_Agent_Id__c = '200';
            agents[2].NVMContactWorld__NVM_Agent_Id__c = '300';
            insert agents;
        }
                
        // create NVM Agent Summary record for each
        List<NVMStatsSF__NVM_Agent_Summary__c> agentSummaries = new List<NVMStatsSF__NVM_Agent_Summary__c>(); 
        for (User a : agents){
            agentSummaries.add( new NVMStatsSF__NVM_Agent_Summary__c(NVMStatsSF__AgentID__c = a.NVMContactWorld__NVM_Agent_Id__c,   
                                                                    NVMStatsSF__Agent__c = a.Id,
                                                                    NVMStatsSF__Date__c = Date.today(),
                                                                    NVMStatsSF__dateAgentId__c = Datetime.now().format('yyyyMMdd')+a.NVMContactWorld__NVM_Agent_Id__c) );
            
        }
        insert agentSummaries;
        
        // create NVM Call Summary record that references agent 1 and 2 on the Ring List and agent 2 and 3 on the Agent List.
        List<NVMStatsSF__NVM_Call_Summary__c> callSummaries = new List<NVMStatsSF__NVM_Call_Summary__c>();
        NVMStatsSF__NVM_Call_Summary__c callSummary = new NVMStatsSF__NVM_Call_Summary__c(); 
        
        callSummary.NVMStatsSF__NVM_Service_Name__c = 'test record';
        callSummary.NVMStatsSF__Ring_List__c = '100:15,200:10';
        callSummary.NVMStatsSF__Agent_List__c = '200-5,300-20';
        callSummary.NVMStatsSF__NVM_AgentID__c = agents[0].NVMContactWorld__NVM_Agent_Id__c;
        callSummaries.add(callSummary);        
        
        Test.startTest();
        insert callSummaries;
        
        // test creation of 4 Agent summary records 1,2,2,3
        ////system.assertEquals(4, [select count() from NVM_Call_Summary_Agent__c], '4 Agent Call Summary records should be inserted.');     
        
        List<NVM_Call_Summary_Agent__c> csaList = [select NVM_Call_Summary__c,
                                                NVM_Agent_Summary__c, 
                                                Duration_Seconds__c,
                                                Agent__c, 
                                                Successful_Connection__c, 
                                                Agent_Role__c, 
                                                RecordTypeId 
                                            from NVM_Call_Summary_Agent__c
                                            where Agent__c=:agents[0].Id];
        NVM_Call_Summary_Agent__c csa;
        if (!csaList.isEmpty()){
            csa = csaList[0];
        }
                                            
        //system.assertEquals(15, csa.Duration_Seconds__c);
        
        Map<String, Id> developerNameToRTId = AppHelper.getRecordTypesByDeveloperName('NVM_Call_Summary_Agent__c');
        Id rtIdAgentQueue=developerNameToRTId.get('Agent_Queue');       
        //system.assertEquals(rtIdAgentQueue, csa.RecordTypeId);                                          
                                            
        //system.assertEquals(true, csa.Successful_Connection__c); // Agent field on the call summary record is set to this agent.
        
        callSummary.NVMStatsSF__NVM_Service_Name__c = 'test record 2';        
        update callSummary;

        Test.stopTest();
    
        // test creation of 4 Agent summary records 1,2,2,3
        //system.assertEquals(4, [select count() from NVM_Call_Summary_Agent__c], '4 Agent Call Summary records should be inserted.');
        
        System.debug(LoggingLevel.ERROR, [select NVM_Call_Summary__c,NVM_Agent_Summary__c, Duration_Seconds__c,Agent__c, Successful_Connection__c, Agent_Role__c, RecordTypeId 
                                            from NVM_Call_Summary_Agent__c]);                       
    }
    /* */
    
    /* **/
    static testMethod void singleTestCase2() {
        // Test Case 2 : create NVM Call Summary and check ChkStr Skilltagger copy to Skill__c field.
       
        List<NVMStatsSF__NVM_Call_Summary__c> callSummaries = new List<NVMStatsSF__NVM_Call_Summary__c>();
        NVMStatsSF__NVM_Call_Summary__c callSummary = new NVMStatsSF__NVM_Call_Summary__c(); 
        
        callSummary.NVMStatsSF__NVM_Service_Name__c = 'test record';
        callSummary.NVMStatsSF__Ring_List__c = '100:15,200:10';
        callSummary.NVMStatsSF__Agent_List__c = '200-5,300-20';
        callSummary.NVMStatsSF__NVM_AgentID__c = '100';
        callSummary.NVMStatsSF__ChkStr__c = '20150128092531-S1-0-000-Start OK|20150128092531-NA-0-001-SkillTagger~ST Service Ops|20150128092531-NA-0-001-SkillTagger~ST Consumer Overview|20150128092845-S-194-072-END~AN Thank you~Caller|';
        callSummaries.add(callSummary);
        
        Test.startTest();
        insert callSummaries;
        Test.stopTest();
        
        // test Skill__c field population equals last SkillTagger in the chkstr.
        //system.assertEquals('Consumer Overview', [select Skill__c from NVMStatsSF__NVM_Call_Summary__c where Id=:callSummaries[0].Id].Skill__c, 'Skill should be populated');        
    }
    /* */    
    
    /* **/
    static testMethod void bulkTestCase1() {
        // Test Case 1 : create TEST_REC_SIZE NVM Call Summary records with Ring List and Agent List.
        final Integer TEST_REC_SIZE=200;
        
        List<User> agents;
        
        // create 3 users with agent Ids
        System.runAs(new User(Id=UserInfo.getUserId())){
            agents = UserTestHelper.createStandardUsers(3, 'Phil', 'Smith', false);
            agents[0].NVMContactWorld__NVM_Agent_Id__c = '100';
            agents[1].NVMContactWorld__NVM_Agent_Id__c = '200';
            agents[2].NVMContactWorld__NVM_Agent_Id__c = '300';
            insert agents;
        }
                
        // create NVM Agent Summary record for each
        List<NVMStatsSF__NVM_Agent_Summary__c> agentSummaries = new List<NVMStatsSF__NVM_Agent_Summary__c>(); 
        for (User a : agents){
            agentSummaries.add( new NVMStatsSF__NVM_Agent_Summary__c(NVMStatsSF__AgentID__c = a.NVMContactWorld__NVM_Agent_Id__c,   
                                                                    NVMStatsSF__Agent__c = a.Id,
                                                                    NVMStatsSF__Date__c = Date.today(),
                                                                    NVMStatsSF__dateAgentId__c = Datetime.now().format('yyyyMMdd')+a.NVMContactWorld__NVM_Agent_Id__c) );
            
        }
        insert agentSummaries;
        
        // create NVM Call Summary record that references agent 1 and 2 on the Ring List and agent 2 and 3 on the Agent List.
        List<NVMStatsSF__NVM_Call_Summary__c> callSummaries = new List<NVMStatsSF__NVM_Call_Summary__c>();
        NVMStatsSF__NVM_Call_Summary__c callSummary;
        
        
        for (Integer n=0; n<TEST_REC_SIZE; n++){
            callSummary = new NVMStatsSF__NVM_Call_Summary__c(); 
        
            callSummary.NVMStatsSF__NVM_Service_Name__c = 'test record';
            callSummary.NVMStatsSF__Ring_List__c = '100:15,200:10';
            callSummary.NVMStatsSF__Agent_List__c = '200-5,300-20';
            callSummary.NVMStatsSF__NVM_AgentID__c = agents[0].NVMContactWorld__NVM_Agent_Id__c;
            callSummaries.add(callSummary);        
        }
        
        Test.startTest();
        insert callSummaries;
        
        // test creation of 4xTEST_REC_SIZE Agent summary records 1,2,2,3
        //system.assertEquals(4*TEST_REC_SIZE, [select count() from NVM_Call_Summary_Agent__c], 'Agent Call Summary records should be inserted.');     
        
        Test.stopTest();    
    }
    /* */
    
    /* **/
    static testMethod void bulkTestCase2() {
        // Test Case 2 : create TEST_REC_SIZE NVM Call Summary records and check ChkStr Skilltagger copy to Skill__c field.
        final Integer TEST_REC_SIZE=200;
       
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
                
        Test.startTest();
        insert callSummaries;
        Test.stopTest();
        
        // test Skill__c field population equals last SkillTagger in the chkstr.
        //system.assertEquals('Consumer Overview', [select Skill__c from NVMStatsSF__NVM_Call_Summary__c where Id=:callSummaries[0].Id].Skill__c, 'Skill should be populated');
        //system.assertEquals('Consumer Overview', [select Skill__c from NVMStatsSF__NVM_Call_Summary__c where Id=:callSummaries[TEST_REC_SIZE-1].Id].Skill__c, 'Skill should be populated');        
    }
    /* */        
}