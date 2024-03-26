/*
Name:  JobApplicationTriggerTest.cls
======================================================
======================================================
Purpose:
-------
Test suite for Job Application (Job_Application__c) Trigger Activity 
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-12-08  Initial development.
*/
@isTest
public with sharing class JobApplicationTriggerTest {

    public static final String jobApplicantRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Job_Applicant').getRecordTypeId();
    
    //testScenario1 - Code coverage for Act On It package invocation. Adding support for event based AOI notifications.
    
    @TestSetup static void createTestData(){

        insert new Account(RecordTypeId=jobApplicantRecordTypeId,FirstName='Job',LastName='Applicant',PersonEmail='JobApplicant@example.com');
        insert new Job__c(Name='New Job');

        insert new OrgSettings__c(TriggersActive__c=true);
    }

    @isTest static void testScenario1(){

        Account applicant = [Select Id, PersonEmail From Account];
        Job__c job = [Select Id From Job__c];

        test.startTest();
            insert new Job_Application__c(Job_Applied_For__c=job.Id,Job_Applicant__c=applicant.Id,Job_Applicant_Email__c=applicant.PersonEmail,Application_Date__c=System.today());
        test.stopTest();

        system.assertEquals(1, [Select Count() From Job_Application__c]);
    }
}