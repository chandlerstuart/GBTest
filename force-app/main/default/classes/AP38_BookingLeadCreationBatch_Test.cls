/**
Name:  AP38_BookingLeadCreationBatch_Test.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test Class for AP38_BookingLeadCreationBatch
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  M.Cebrian  2016-04-28  Initial test class development - 100% coverage.
**/
@isTest
private class AP38_BookingLeadCreationBatch_Test {
    
    @testSetup static void setupTestData() {
        List<Account> testAccount= AP23_TestDataFactory.createAccount(1);
        insert testAccount;
        
        List<Opportunity> testOpps = AP23_TestDataFactory.createOpportunity(1,'Prospecting',testAccount.get(0));
        insert testOpps;
        
        List<Booking__c> testBookings = AP23_TestDataFactory.createBooking(3, testAccount.get(0), testOpps.get(0).Id);
        for(Booking__c tb: testBookings) {
            tb.Travel_Date__c = System.today().addDays(-15);
            tb.Nights__c = 1;
        }
        insert testBookings;
    }
    
    @isTest static void validateBatchWithValidAccounts() {
        
        Test.startTest();
        AP38_BookingLeadCreationBatch AP38 = new AP38_BookingLeadCreationBatch();
        Database.executeBatch(AP38);
        Test.stopTest();
        
    }
    
    @isTest static void validateBatchWithInvalidAccounts() {
        Account testAccount = [SELECT Id from Account LIMIT 1];
        
        //insert lead related to account
        List<Lead> testlead = AP23_TestDataFactory.createLead(1);
        for(Lead l: testlead) {
            l.Status = 'Tentative';
            l.Account__c = testAccount.id;
        }
        insert testlead;
        
        
        Test.startTest();
        AP38_BookingLeadCreationBatch AP38 = new AP38_BookingLeadCreationBatch();
        Database.executeBatch(AP38);
        Test.stopTest();
        
        // Verify lead items got inserted 
        Integer i = [SELECT COUNT() FROM Lead];
        System.assertEquals(i, 1);
    }
}