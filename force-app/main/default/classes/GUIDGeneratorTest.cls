/*
Name:  GUIDGeneratorTest.cls
======================================================
======================================================
Purpose: Test Suite for GUIDGenerator.cls
-------
======================================================
======================================================
History
------- 
Ver. Author       Date        Detail
1.0  J Radcliffe  2024-02-12  Initial development.
*/
@isTest
private class GUIDGeneratorTest {

    @TestSetup
    static void createTestData(){
        insert new Phased_Code_Removal__c(ActivatePublicIdGeneration__c=true);
    }

    @isTest
    static void testAssignPublicIdSuccess() {
        // Create test records
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            Account acc = new Account(Name = 'Test Account ' + i);
            testAccounts.add(acc);
        }

        // Call the method under test
        Test.startTest();
            GUIDGenerator.assignPublicId(testAccounts);
        Test.stopTest();

        // Verify that PublicId__c field has been assigned for each record
        for (Account acc : testAccounts) {
            System.assertNotEquals(null, acc.PublicId__c, 'PublicId__c should not be null');
        }
    }

    @isTest
    static void testAssignPublicIdFail() {
        
        // Create test records
        List<OutboundCallout__c> testCallouts = new List<OutboundCallout__c>();//<-- Object without PublicId__c field
        for (Integer i = 0; i < 5; i++) {
            testCallouts.add(new OutboundCallout__c());
        }
        
        system.assertEquals(0, [Select Count() From Golfbreaks__PlatformLog__c]);

        // Call the method under test
        Test.startTest();
            GUIDGenerator.assignPublicId(testCallouts);
        Test.stopTest();

        system.assertEquals(1, [Select Count() From Golfbreaks__PlatformLog__c Where Golfbreaks__Message__c = 'PublicId__c field does not exist on object OutboundCallout__c']);
    }
}