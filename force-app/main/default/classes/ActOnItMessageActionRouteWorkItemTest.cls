/*
Name:  ActOnItMessageActionRouteWorkItemTest.cls
======================================================
======================================================
Purpose:
-------
Test Suite for ActOnItMessageActionRouteWorkItem.cls
======================================================
======================================================
History
------- 
Ver.  Author            Date        Detail
1.0   J Radcliffe       2021-03-23  Class creation.
*/
@isTest
public with sharing class ActOnItMessageActionRouteWorkItemTest {
    @TestSetup static void  createTestData(){
        
        //Create 100 Accounts
        List<Account> accs = AP23_TestDataFactory.createPersonAccount(100);
        insert accs;

        //Create 100 Opportunities
        List<Opportunity> opps = new List<Opportunity>();
        for(Account acc : accs){
            Opportunity opp = AP23_TestDataFactory.createOpportunity(1,'New',acc)[0];
            opps.add(opp);
        }
        insert Opps;
        
        //Confirm Opps remain assigned to running user after insert
        system.assertEquals(100, [Select Count() From Opportunity Where OwnerId = :UserInfo.getUserId()]);

        //Activate Triggers
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;

        //Set Default Unassigned work Item User
        GBWire__RoutingEngineSettings__c settings = new GBWire__RoutingEngineSettings__c();
        settings.GBWire__IsActive__c = true;
        settings.GBWire__UnassignedWorkItemOwnerId__c = [Select Id From User Where Profile.Name = :ApplicationConstant.PROFILE_SALES_AGENT and IsActive = true Limit 1].Id;
        insert settings;
    }

    @isTest static void testBulkUpdate(){

        Id userId = UserInfo.getUserId();

        List<Id> oppIds = new List<Id>();
        for(Opportunity opp : [Select Id, OwnerId From Opportunity]){
            system.assertEquals(userId, opp.OwnerId);//Confirm the Opp owned by the running user
            oppIds.add(opp.Id);
        }
        system.assertEquals(100, oppIds.size());//Confirm the expected number of opps (created in testSetup)

        test.startTest();
            GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
            ActOnItMessageActionRouteWorkItem action = new ActOnItMessageActionRouteWorkItem();
            ActOnIt.ActOnItMessageActionResult result = action.execute( UserInfo.getUserId(), null, null, null, oppIds);
        test.stopTest();

        system.assertEquals(true, result.isSuccess);//Is Successful
        system.assertEquals(null, result.errorMessage);//No errors returned
        system.assertEquals(null, result.successMessage);//Omit Success Message (so the configured default is used)
        system.assertEquals(null, result.navigateToRecordId);//Null (because there are multiple Opps)
        
        //Confirm all the Opps have been successfully re-assigned elsewhere
        system.assertEquals(0, [Select Count() From Opportunity Where OwnerId =:userId]);

    }
}