/*
Name:
-----
OutboundCalloutLocalTriggerTest.cls
================================================================
================================================================
Purpose:
------
Test Suite for local Outbound Callout trigger activity
================================================================
================================================================
Verison  Author         Date          Detail
v1.0    C Stuart        20/03/2023    Inital Deployment - Act On It Trigger
*/

@isTest
public with sharing class OutboundCalloutLocalTriggerTest {

   @TestSetup static void createTestData(){
      // Activate Org Triggers
      OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = true);
      insert orgSettings;
   }

   // v1.0 -- Create Outbound Callout Record
   @isTest static void insertOutboundCallout(){

      // Insert a list of outboundCallout Records
      List<OutboundCallout__c> ocList = AP23_TestDataFactory.createOutboundCallout(100);
      Test.startTest();
         insert ocList;
      Test.stopTest();

      // Query inserted Records & verify the actual results with the expected results
      System.assertEquals(100,[select count() FROM OutboundCallout__c WHERE Status__c=:Label.Picklist_Value_OutboundCallout_Status_New]);
   }
}