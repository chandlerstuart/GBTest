/**
Name:  AP36_LeadAccountUpdateBatch_Test.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test Class for AP36_LeadAccountUpdateBatch
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  M.Cebrian  2016-05-04  Initial test class development
1.1  S.Molloy   2016-11-25  Created Account Validation rules
**/
@isTest
private class AP36_LeadAccountUpdateBatch_Test {

    @testSetup static void setupTestData() {
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        
        Map<String,Id> accountRecordTypes = AP23_TestDataFactory.getRecordType('Account');
        List<Lead> testLead= AP23_TestDataFactory.createLead(5);
        Account testAccount= new Account(PersonEmail = testLead[0].Email, RecordTypeId = accountRecordTypes.get('Client'), LastName = 'test Account', Phone = '+441231234567');
        insert testLead;
        insert testAccount;
    }
    
    @isTest static void validateBatchValidLeads() {
        Test.startTest();
        AP36_LeadAccountUpdateBatch AP36 = new AP36_LeadAccountUpdateBatch();
        Database.executeBatch(AP36);
        Test.stopTest();
        
        // Verify lead items got inserted 
        Integer i = [SELECT COUNT() FROM Lead];
        System.assertEquals(i, 5);
    }

}