/*
Name:  ClubhouseEnquiryCreateTestSuite.cls
======================================================
======================================================
Purpose:
-------
Test Class for Lead / Enquiry Create functionality

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon Molloy  2017-07-27  Initial development.
*/
@isTest
private class ClubhouseEnquiryCreateTestSuite {
    @testSetup
    public static void setup() {
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;

        List<Object_Field_Mapping__c> customSettings = AP23_TestDataFactory.getCustomSettingObjectFieldMapping();
        insert customSettings;
        
        List<Lead> leadList = new List<Lead>();
        //NEW Lead
        Lead leadNew = new Lead();
        leadNew.FirstName = 'New';
        leadNew.LastName = 'Lead';
        leadNew.Email = 'new.lead@myemail.com';
        leadNew.MobilePhone = '+447911111111';
        leadNew.SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_UK_IRELAND;
        leadNew.CountriesInterested__c = ApplicationConstant.COUNTRY_ENGLAND_WALES;
        leadNew.Status = ApplicationConstant.LEAD_STATUS_NEW;
        leadNew.PreferredTravelDate__c = Date.today().addMonths(3);

        leadList.add(leadNew);

        //Contact Attempted Lead
        Lead leadCA = new Lead();
        leadCA.FirstName = 'CA';
        leadCA.LastName = 'Lead';
        leadCA.Email = 'ca.lead@myemail.com';
        leadCA.MobilePhone = '+447911111112';
        leadCA.GolfbreaksEnquiryId__c = '12345';
        leadCA.SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_UK_IRELAND;
        leadCA.CountriesInterested__c = ApplicationConstant.COUNTRY_ENGLAND_WALES;
        leadCA.Status = ApplicationConstant.LEAD_STATUS_CONTACT_ATTEMPTED;
        leadCA.PreferredTravelDate__c = Date.today().addMonths(3);

        leadList.add(leadCA);

        //No Sale Lead
        Lead leadNS = new Lead();
        leadNS.FirstName = 'NS';
        leadNS.LastName = 'Lead';
        leadNS.Email = 'ns.lead@myemail.com';
        leadNS.MobilePhone = '+447911111113';
        leadNS.NoSaleReason__c = 'Price';
        leadNS.SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_UK_IRELAND;
        leadNS.CountriesInterested__c = ApplicationConstant.COUNTRY_ENGLAND_WALES;
        leadNS.Status = ApplicationConstant.LEAD_NO_SALE;
        leadNS.PreferredTravelDate__c = Date.today().addMonths(3);

        leadList.add(leadNS);

        //Contacted In Progress Lead
        Lead leadCIP = new Lead();
        leadCIP.FirstName = 'CIP';
        leadCIP.LastName = 'Lead';
        leadCIP.Email = 'cip.lead@myemail.com';
        leadCIP.MobilePhone = '+447911111114';
        leadCIP.SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_UK_IRELAND;
        leadCIP.CountriesInterested__c = ApplicationConstant.COUNTRY_ENGLAND_WALES;
        leadCIP.Status = ApplicationConstant.LEADE_STATUS_CONTACTED_INPROGRESS;
        leadCIP.PreferredTravelDate__c = Date.today().addMonths(3);

        leadList.add(leadCIP);

        //Duplicate Lead
        Lead leadDUP = new Lead();
        leadDUP.FirstName = 'DUP';
        leadDUP.LastName = 'Lead';
        leadDUP.Email = 'dup.lead@myemail.com';
        leadDUP.MobilePhone = '+447911111115';
        leadDUP.DuplicateNotaLeadReason__c = 'Special event';
        leadDUP.SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_UK_IRELAND;
        leadDUP.CountriesInterested__c = ApplicationConstant.COUNTRY_ENGLAND_WALES;
        leadDUP.Status = ApplicationConstant.LEAD_STATUS_DUPLICATE;
        leadDUP.PreferredTravelDate__c = Date.today().addMonths(3);

        leadList.add(leadDUP);

        insert leadList;

    }

    static testMethod void testBatchRun() {
        test.startTest();

        ClubhouseEnquiryCreateBatch cecb = new ClubhouseEnquiryCreateBatch();
        Id jobId = Database.executeBatch(cecb);

        test.stopTest();

        List<Opportunity> oppList = [select Id from Opportunity where RecordTypeId = :ApplicationConstant.getRecordTypeId('Opportunity','Sales_Shadow_Opportunity')];

        //We should only have ONE Shadow Opp created, as there is only ONE Lead at Contact Attempted Status in this test
        //system.assertEquals(1, oppList.size());

    }

    static testmethod void testSchedule() {
        String CRON_EXP = '0 0 0 3 9 ? 2022';
       Test.startTest();
          // Schedule the test job
    
          String jobId = System.schedule('testClubhouseEnquirySchedule',CRON_EXP, new ClubhouseEnquiryCreateSchedule());
    
          // Get the information from the CronTrigger API object
          CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
    
          // Verify the expressions are the same
          System.assertEquals(CRON_EXP, ct.CronExpression);
    
          // Verify the job has not run
          System.assertEquals(0, ct.TimesTriggered);
    
          // Verify the next time the job will run
          System.assertEquals('2022-09-03 00:00:00', String.valueOf(ct.NextFireTime));
    
       Test.stopTest();
    }
}