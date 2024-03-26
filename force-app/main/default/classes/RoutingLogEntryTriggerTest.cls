/*
Name:
-----
RoutingLogEntryTriggerTest.cls
================================================================
================================================================
Purpose:
------
Test class for the Routing Log Entry Trigger
================================================================
================================================================
Verison  Author         Date          Detail
v1.0    C Stuart        20/03/2023    Inital Deployment v1.0 - Act On It Trigger 
*/

@isTest
public with sharing class RoutingLogEntryTriggerTest{

    /*
        insertRoutingLogEntry :This method verifies log entries are successfully created in bulk. Initially introduced to confirm that invoking the Act On It application does not cause any disruption to the logging of routing errors.
    */
    
    @TestSetup
    static void createTestData(){
        // Activate Org Triggers
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = true);
        insert orgSettings;
    }

    //v1.0 -- Create Routing Log Entry
    @isTest static void insertRoutingLogEntry(){

        // Insert 100 Routing Log Entries
        List<GBWire__RoutingLogEntry__c> routeLogEntryList = AP23_TestDataFactory.createRoutingLogEntry(100);
        Test.startTest();
            insert routeLogEntryList;
        Test.stopTest();

        // Query inserted Records & verify the actual results with the expected results
        List<GBWire__RoutingLogEntry__c> insertedRecords = [SELECT Id FROM GBWire__RoutingLogEntry__c WHERE Id IN :routeLogEntryList];
        System.assertEquals(100, insertedRecords.size());
    }
}