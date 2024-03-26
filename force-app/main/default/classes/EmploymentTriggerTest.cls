/*
Name:  EmploymentTriggerTest.cls
======================================================
======================================================
Purpose:
-------
Test suite for Employment (Employment__c) Trigger Activity 
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-12-08  Initial development.
*/
@isTest
public with sharing class EmploymentTriggerTest {
    
    //testScenario1 - Code coverage for Act On It package invocation. Adding support for event based AOI notifications.
    
    @TestSetup static void createTestData(){
        insert new OrgSettings__c(TriggersActive__c=true);
    }

    @isTest static void testScenario1(){

        test.startTest();
            insert new Employment__c(Start_Date__c=System.today(),User__c=UserInfo.getUserId());
        test.stopTest();

        system.assertEquals(1, [Select Count() From Employment__c]);
    }
}