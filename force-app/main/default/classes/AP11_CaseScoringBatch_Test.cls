/**
Name:   AP11_CaseScoringBatch_Test.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test Class for  AP11_CaseScoringBatch and partially for AP07_CaseScoringLogic
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail 
1.0  Gaylan, C.  2016-05-03    Created
2.0  Atlee       2016-06-03    Updated test setup, added assertions
**/
@isTest
private class AP11_CaseScoringBatch_Test {
    @testSetup static void setupData(){
        List<Account> accList = AP23_testDataFactory.createAccount(1);
        insert accList;
        
        List<Opportunity> oppList = AP23_TestDataFactory.createOpportunity(1,ApplicationConstant.CLOSESALESTAGE,accList[0]);
        insert oppList;
        
        RecordType caseRec = [SELECT Id FROM RecordType WHERE DeveloperName =: ApplicationConstant.CASE_RECORD_TYPE_AMENDMENT AND SObjectType = 'Case' LIMIT 1];
        //create Case -- Record Type = Amendment and Case Origin = Email, Total Points = 71 (R1ADEV)
        List<Case> caseList = AP23_TestDataFactory.createCase(200, accList[0]);
        for(Case cs: caseList){
            cs.RecordTypeId = caseRec.Id;
            cs.Origin = ApplicationConstant.TASK_EMAIL;
            cs.Priority = 'P2';
            cs.CaseScoreAppliedDate__c = Date.Today() - 1;
            cs.Points__c = 15;
            cs.Opportunity__c = oppList[0].Id;
        }
        insert caseList;
        
        LeadScoringRule__c lsr = new LeadScoringRule__c(FieldLabel__c = 'Case Status', RecordType__c = String.ValueOf(caseRec.Id), 
                                                        Active__c = TRUE, Operator__c = 'equals', Value__c = caseList[0].Status, Points__c = 5);
        insert lsr;
        
        LeadScoreMapping__c lsm = new LeadScoreMapping__c(RuleType__c = 'Case', LeadScoreMaximumValue__c = 10, LeadScoreMinimumValue__c = 0, CasePriority__c = 'P1');
        insert lsm;
    } 
    
    //Test if Priority, Points and CaseScoreAppliedDate will get updated with values from the Lead Score
    @isTest static void tstCaseScoring(){
        String query = 'SELECT Id, Priority, CaseScoreAppliedDate__c, Points__c, CaseNumber, AccountId, Type, Status, Origin, BusinessHoursId, Description, Booking__c, Category__c, SubCategory__c, RecordTypeId FROM Case LIMIT 200';
                
        Test.startTest();
        AP11_CaseScoringBatch csBatch = new AP11_CaseScoringBatch(query);
        Database.executeBatch(csBatch);
        Test.stopTest();
        
        List<Case> lCase = [SELECT Id, Priority, CaseScoreAppliedDate__c, Points__c FROM Case LIMIT 200];
        
        for(Case cs: lCase){
            System.AssertEquals(cs.Priority, 'P1');
            System.AssertEquals(cs.Points__c, 5);
            System.AssertEquals(cs.CaseScoreAppliedDate__c, Date.today());
        }
    }
}