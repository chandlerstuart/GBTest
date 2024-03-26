/**
Name:  LC05_OutboundMessageCreator_Test.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test Class for LC05_OutboundMessageCreator
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.0  Ana D      2016-05-06   Initial test class development
1.1  Simon M    2017-08-09   Added test for LC05_OutboundMessageCreator.buildAccountManagerRequestWrapper
**/

@isTest(SeeAllData=false)
private class LC05_OutboundMessageCreator_Test {
    @testSetup static void setupTestData() {
                OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
                insert orgSettings;
                
                List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
                insert validationList;
                
                Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
                insert acc;
                
                Communication_Preference__c cp = new Communication_Preference__c(Communication_Type__c = 'Newsletter', Related_To__c = acc.Id);
                insert cp;
                
                List<Lead> lLead = AP23_TestDataFactory.createLead(5);
                insert lLead;
                List<Object_Field_Mapping__c> customSettings = AP23_TestDataFactory.getCustomSettingObjectFieldMapping();
                insert customSettings;
    }
    
    private static testMethod void testLC05_OutboundMessageCreatorEnquiry() {
        //create test data
        Lead lLead = [Select Id, Rating, OwnerId, Status, Account__c FROM Lead LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        LC04_LeadConvertProcessor.convertLead(String.valueOf(lLead.Id), 'Test Opp');
        LC05_OutboundMessageCreator.buildEnquiryClientRequestWrapper(lLead.id, 'ENQUIRY');
        test.stopTest();
        
        // Verify opp items got inserted -- none because webservice failure
        Integer i = [SELECT COUNT() FROM Opportunity];
        System.assertEquals(i, 0);
    }
    
    private static testMethod void testLC05_OutboundMessageCreatorClient() {
        //create test data
        Lead lLead = [Select Id, Rating, OwnerId, Status, Account__c FROM Lead LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        LC04_LeadConvertProcessor.convertLead(String.valueOf(lLead.Id), 'Test Opp');
        LC05_OutboundMessageCreator.buildEnquiryClientRequestWrapper(lLead.id, 'CLIENT');
        test.stopTest();
        
        // Verify opp items got inserted -- none because webservice failure
        Integer i = [SELECT COUNT() FROM Opportunity];
        System.assertEquals(i, 0);
    }

    private static testMethod void testbuildAccountManagerRequestWrapper() {
        //create test data
        Profile salesAgent = [select Id from Profile where Name = 'Golfbreaks Sales User' LIMIT 1];
        Lead lLead = [Select Id, Rating, OwnerId, GolfbreaksEnquiryId__c, Status, Account__c FROM Lead LIMIT 1];
        
        User u = [select Id, Golfbreaks_Employee_Id__c from User where IsActive = TRUE and ProfileId = :salesAgent.Id LIMIT 1];
        u.Golfbreaks_Employee_Id__c = 12345;
        update u;

        lLead.OwnerId = u.Id;
        lLead.GolfbreaksEnquiryId__c = '54321';
        update lLead;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        AccountManagerRequestWrapper requestWrapper = LC05_OutboundMessageCreator.buildAccountManagerRequestWrapper(lLead.id, 'Lead', 1);
        test.stopTest();
        
        // Verify opp items got inserted -- none because webservice failure
        system.assertNotEquals(null, requestWrapper);
        system.assertEquals(1,requestWrapper.AccountManagerEntity);
        system.assertEquals('54321', requestWrapper.EntityGolfbreaksID);
        system.assertEquals(12345,requestWrapper.NewAccountManager.GolfbreaksEmployeeID);
    }
    
}