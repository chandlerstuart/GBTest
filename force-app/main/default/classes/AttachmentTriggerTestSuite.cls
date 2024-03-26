/*
Name: AttachmentTriggerTestSuite.cls
Copyright © 2016  CloudMethods
======================================================
======================================================
Purpose:
-------

Test suite for Trigger Handler class AttachmentTriggerHandler.cls

Coverage for classes below (target 85%):
AttachmentTriggerHandler.cls : 96%

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2016-02-10  Initial development.
*/
@isTest(SeeAllData=false)
public with sharing class AttachmentTriggerTestSuite {
    /*
    Test cases: 
        singleTestCase1 - Standard course - Job Application related attachment deleted.
        neagtiveTestCase2 - Standard course - Non Job Application related attachment not deleted. 
        ..
        bulkTestCase1 - Bulk test. singleTestCase1 - 200 records.
    */
    
    /* **/
    static testMethod void singleTestCase1() {
        // Test case 1 : Standard course - Job Application related attachment deleted.     
        
        Map<String, Id> developerNameToRTId = AppHelper.getRecordTypesByDeveloperName('Account');        
        Id jobApplicantRTId=developerNameToRTId.get('Job_Applicant');                        
                
        Account a = new Account(FirstName='Jo', LastName='Williams');
        a.RecordTypeId=jobApplicantRTId;
        insert a;
               
        Recruitment_Campaign__c rc = new Recruitment_Campaign__c(Name='RC1');
        insert rc;
               
        Job_Title__c t = new Job_Title__c(Name='Test Position');       
        insert t;       
              
        Job__c j = new Job__c(Job_Title__c=t.Id, Recruitment_Campaign__c=rc.Id);
        insert j;
        
        Job_Application__c ja = new Job_Application__c(Application_Date__c=date.today(), Job_Applicant__c=a.Id, Job_Applied_For__c=j.Id, Job_Applicant_Email__c='test@test.com');
        insert ja;
                                
        dsfs__DocuSign_Status__c ds = new dsfs__DocuSign_Status__c(Job_Application__c=ja.Id);
		insert ds;
		
		Attachment d = new Attachment(Name='test', Body=Blob.valueof('CV'), ParentId=ds.Id);
		
		Test.startTest();
		insert d;
		Test.stopTest();
		
		System.assertEquals(0, [select count() from Attachment], 'The inserted attachment should be deleted.');		
    }
    /* */

    /* **/
    static testMethod void negativeTestCase1() {
        // Test case 1 : Standard course - Standard course - Non Job Application related attachment not deleted.     
        
        Map<String, Id> developerNameToRTId = AppHelper.getRecordTypesByDeveloperName('Account');        
        Id jobApplicantRTId=developerNameToRTId.get('Job_Applicant');                        
                
        Account a = new Account(FirstName='Jo', LastName='Williams');
        a.RecordTypeId=jobApplicantRTId;
        insert a;
               
        dsfs__DocuSign_Status__c ds = new dsfs__DocuSign_Status__c(dsfs__Company__c=a.Id);
		insert ds;
		
		Attachment d = new Attachment(Name='test', Body=Blob.valueof('CV'), ParentId=ds.Id);
		
		Test.startTest();
		insert d;
		Test.stopTest();
		
		System.assertEquals(1, [select count() from Attachment], 'The inserted attachment should not be deleted.');		
    }
    /* */
    
	/* **/
    static testMethod void bulkTestCase1() {
        // Test case 1 : Bulk test - singleTestCase1 - 200 records.     
        
        Map<String, Id> developerNameToRTId = AppHelper.getRecordTypesByDeveloperName('Account');        
        Id jobApplicantRTId=developerNameToRTId.get('Job_Applicant');                        
                
        Account a = new Account(FirstName='Jo', LastName='Williams');
        a.RecordTypeId=jobApplicantRTId;
        insert a;
               
        Recruitment_Campaign__c rc = new Recruitment_Campaign__c(Name='RC1');
        insert rc;
               
        Job_Title__c t = new Job_Title__c(Name='Test Position');       
        insert t;       
              
        Job__c j = new Job__c(Job_Title__c=t.Id, Recruitment_Campaign__c=rc.Id);
        insert j;
        
        Job_Application__c ja = new Job_Application__c(Application_Date__c=date.today(), Job_Applicant__c=a.Id, Job_Applied_For__c=j.Id, Job_Applicant_Email__c='test@test.com');
        insert ja;
        
        List<dsfs__DocuSign_Status__c> ds = new List<dsfs__DocuSign_Status__c>();
        for (Integer i=0; i<200; i++){                        
        	ds.add( new dsfs__DocuSign_Status__c(Job_Application__c=ja.Id) );
        }
		insert ds;
		
		List<Attachment> attachments = new List<Attachment>();  		
		for (Integer i=0; i<200; i++){
			attachments.add( new Attachment(Name='test', Body=Blob.valueof('CV'), ParentId=ds[i].Id) );
		}
		
		Test.startTest();
		insert attachments;
		Test.stopTest();
		
		System.assertEquals(0, [select count() from Attachment], 'The inserted attachments should be deleted.');		
    }
    /* */
}