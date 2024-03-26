/*
Name: SalesEnquiryHandlerTest.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Test suite for SalesEnquiryHandler.cls
======================================================
======================================================

Tests:
testTerritoryCalcScenario1 - Positive Assertion:Successfully applied correct territory
testTerritoryCalcScenario2 - Negative Assertion:Applied Default (Not enough info provided)
testTerritoryCalcScenario3 - Negative Assertion:Applied Default (Enquiry spans multiple Territories)
testSalesEnquiryDeDupeScenario1 - Positive Assertion:Successfully applied duplicate Opportunity Id
testSalesEnquiryDeDupeScenario2 - Negative Assertion:No dupe found (different client)
testSalesEnquiryDeDupeScenario3 - Negative Assertion:No dupe found (closed opp)
testSalesEnquiryDeDupeScenario4 - Negative Assertion:No dupe found (different territory)
setEnqDefaultsScenario1 - Positive Assertion: Defaults set correctly

History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-05-28  Initial development.
1.1  J Radcliffe   2020-03-27  Fix Tests - DeveloperName Required for Territory__c. Workaround Duplicate Rules
1.2  Mark Cane&    2023-08-22  Bug fixes.
*/
@isTest
public with sharing class SalesEnquiryHandlerTest {
    
    @TestSetup static void createTestData(){

        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
                
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings; 
        
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;


        //Create Business Unit
        Golfbreaks_Business_Unit__c gbu = new Golfbreaks_Business_Unit__c();
        gbu.IsDefault__c = true;
        gbu.Name = 'TestBU';
        gbu.DeveloperName__c = 'TestBU';//1.2+
        insert gbu;
        
        //Confirm a default territory was inserted
        //1.2- system.assertEquals(1,[Select Id From Territory__c Where IsDefault__c = true].size());

        //Create Multiple Territories
        List<Territory__c> territories = new List<Territory__c>();

        Territory__c t2 = new Territory__c();
        t2.BusinessUnit__c = gbu.Id;
        t2.Name = 'Territory1';
        t2.IsDefault__c = false;
        t2.Countries__c = 'England & Wales;Ireland;Scotland';
        t2.DeveloperName__c = 'TestBUT2';//1.1+
        territories.add(t2);

        Territory__c t3 = new Territory__c();
        t3.BusinessUnit__c = gbu.Id;
        t3.Name = 'Territory2';
        t3.IsDefault__c = false;
        t3.Countries__c = 'Spain;Portugal;Italy;Belgium';
        t3.DeveloperName__c = 'TestBUT3';//1.1+
        territories.add(t3);

        Territory__c t4 = new Territory__c();
        t4.BusinessUnit__c = gbu.Id;
        t4.Name = 'Territory3';
        t4.IsDefault__c = false;
        t4.Countries__c = 'Dominican Republic;USA;Thailand';
        t4.DeveloperName__c = 'TestBUT4';//1.1+
        territories.add(t4);

        insert territories;

        system.debug([Select Id, Name From Territory__c]);

        //Create Account
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert acc;

        //Create Opportunity
        Id uncontactedRT = ApplicationConstant.OPP_RECTYPEID_UNCONTACTED;
        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.Territory__c = [Select Id From Territory__c Where Name = 'Territory1' Limit 1][0].Id;
        opp.RecordTypeId = uncontactedRT;
        opp.CloseDate = system.today();
        opp.Name = 'Test Opp';
        opp.StageName = 'New';
        insert opp;

    }

    //Successfully retreieve correct territory
    @isTest static void testTerritoryCalcScenario1(){

        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;

        //Retrieve Any Action Type
        ActionType__mdt actionType = [Select Id, BusinessUnit__c From ActionType__mdt Where isTest__c = true Limit 1][0];
        //Override the Business Unit Value && apply to Enquiry
        actionType.BusinessUnit__c = [Select Id From Golfbreaks_Business_Unit__c Limit 1][0].Id;
        EnquiryManager.Enquiry enq = new EnquiryManager.Enquiry();
        enq.actionType = actionType;
        enq.tripDetails.territoryId = null;
        enq.tripDetails.countries = new List<String>{'England & Wales','Scotland'};
        List<EnquiryManager.Enquiry> enquiries = new List<EnquiryManager.Enquiry>();
        enquiries.add(enq);

        test.startTest();
            SalesEnquiryHandler.calculateSalesEnquiryTerritories(enquiries);
        test.stopTest();

        //Confirm the TerritoryId has been set correctly
        system.assertNotEquals(null, enquiries[0].tripDetails.territoryId);
        system.assertEquals([Select Id From Territory__c Where Name = 'Territory1' Limit 1][0].Id,enq.tripDetails.territoryId);
        
    }
    
    //No Countries - Resort to default
    @isTest static void testTerritoryCalcScenario2(){

        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;

        //Retrieve Any Action Type
        ActionType__mdt actionType = [Select Id, BusinessUnit__c From ActionType__mdt Where isTest__c = true Limit 1][0];
        //Override the Business Unit Value && apply to Enquiry
        actionType.BusinessUnit__c = [Select Id From Golfbreaks_Business_Unit__c Limit 1][0].Id;
        EnquiryManager.Enquiry enq = new EnquiryManager.Enquiry();
        enq.actionType = actionType;
        enq.tripDetails.territoryId = null;
        enq.tripDetails.countries = null;
        List<EnquiryManager.Enquiry> enquiries = new List<EnquiryManager.Enquiry>();
        enquiries.add(enq);

        test.startTest();
            SalesEnquiryHandler.calculateSalesEnquiryTerritories(enquiries);
        test.stopTest();

        //Confirm the TerritoryId has been set correctly
        system.assertNotEquals(null, enquiries[0].tripDetails.territoryId);
        system.assertEquals([Select Id From Territory__c Where IsDefault__c = true Limit 1][0].Id,enq.tripDetails.territoryId);
    }

    //Multiple potential territories - Resort to default
    @isTest static void testTerritoryCalcScenario3(){

        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;

        //Retrieve Any Action Type
        ActionType__mdt actionType = [Select Id, BusinessUnit__c From ActionType__mdt Where isTest__c = true Limit 1][0];
        //Override the Business Unit Value && apply to Enquiry
        actionType.BusinessUnit__c = [Select Id From Golfbreaks_Business_Unit__c Limit 1][0].Id;
        EnquiryManager.Enquiry enq = new EnquiryManager.Enquiry();
        enq.actionType = actionType;
        enq.tripDetails.territoryId = null;
        enq.tripDetails.countries = new List<String>{'England & Wales','Dominican Republic'};
        List<EnquiryManager.Enquiry> enquiries = new List<EnquiryManager.Enquiry>();
        enquiries.add(enq);

        test.startTest();
            SalesEnquiryHandler.calculateSalesEnquiryTerritories(enquiries);
        test.stopTest();

        //Confirm the TerritoryId has been set correctly
        system.assertNotEquals(null, enquiries[0].tripDetails.territoryId);
        system.assertEquals([Select Id From Territory__c Where IsDefault__c = true Limit 1][0].Id,enq.tripDetails.territoryId);
    }

    //Confirm the correct duplicate is retrieved
    @isTest static void testSalesEnquiryDeDupeScenario1(){

        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;

        Id uncontactedRT = ApplicationConstant.OPP_RECTYPEID_UNCONTACTED;
        Id territoryId = [Select Id From Territory__c Where Name = 'Territory1' Limit 1][0].Id;

        Opportunity[] dupeOpps =  [Select Id, AccountId From Opportunity Where RecordTypeId = :uncontactedRT and IsOpen__c = true and Territory__c = :territoryId];
        system.assertNotEquals(null, dupeOpps);
        system.assertEquals(1, dupeOpps.size());
        Id dupeOppId = dupeOpps[0].Id;

        //Retrieve Any Action Type
        ActionType__mdt actionType = [Select Id, RecordTypeId__c From ActionType__mdt Where isTest__c = true Limit 1][0];
        //Override the defauly Record Type
        actionType.RecordTypeId__c = uncontactedRT;

        //Create new (dupe) Enquiry
        EnquiryManager.Enquiry enq = new EnquiryManager.Enquiry();
        enq.actionType = actionType;
        enq.tripDetails.territoryId = territoryId;
        enq.clientDetails.accountId = dupeOpps[0].AccountId;
        List<EnquiryManager.Enquiry> enquiries = new List<EnquiryManager.Enquiry>();
        enquiries.add(enq);

        system.assertEquals(null, enq.duplicateEnquiryId);

        test.startTest();
            //Scenario 1 - Enq is a Dupe
            SalesEnquiryHandler.dedupeSalesEnquiries(enquiries);
        test.stopTest();

        system.assertEquals(dupeOppId, enquiries[0].duplicateEnquiryId);
        

    }

    //Confirm non duplicates are excluded - Different client
    @isTest static void testSalesEnquiryDeDupeScenario2(){

        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        Id uncontactedRT = ApplicationConstant.OPP_RECTYPEID_UNCONTACTED;
        Id territoryId = [Select Id From Territory__c Where Name = 'Territory1' Limit 1][0].Id;

        Opportunity[] dupeOpps =  [Select Id, AccountId From Opportunity Where RecordTypeId = :uncontactedRT and IsOpen__c = true and Territory__c = :territoryId];
        system.assertNotEquals(null, dupeOpps);
        system.assertEquals(1, dupeOpps.size());
        Id dupeOppId = dupeOpps[0].Id;

        //Retrieve Any Action Type
        ActionType__mdt actionType = [Select Id, RecordTypeId__c From ActionType__mdt Where isTest__c = true Limit 1][0];
        //Override the defauly Record Type
        actionType.RecordTypeId__c = uncontactedRT;

        //Create new (dupe) Enquiry
        EnquiryManager.Enquiry enq = new EnquiryManager.Enquiry();
        enq.actionType = actionType;
        enq.tripDetails.territoryId = territoryId;
        //NEW CLIENT
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        acc.LastName = 'Unique';//1.1+
        acc.PersonEmail = 'entirelyUnique123@example.com';//1.1+
        insert acc;
        enq.ClientDetails.accountId = acc.Id;
        List<EnquiryManager.Enquiry> enquiries = new List<EnquiryManager.Enquiry>();
        enquiries.add(enq);

        system.assertEquals(null, enq.duplicateEnquiryId);

        test.startTest();
            //Scenario 2 - Different client
            SalesEnquiryHandler.dedupeSalesEnquiries(enquiries);

        test.stopTest();

        system.assertEquals(null, enquiries[0].duplicateEnquiryId);

    }

    //Confirm non duplicates are excluded - Closed Opp
    @isTest static void testSalesEnquiryDeDupeScenario3(){

        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        Id uncontactedRT = ApplicationConstant.OPP_RECTYPEID_UNCONTACTED;
        Id territoryId = [Select Id From Territory__c Where Name = 'Territory1' Limit 1][0].Id;

        Opportunity[] dupeOpps =  [Select Id, AccountId From Opportunity Where RecordTypeId = :uncontactedRT and IsOpen__c = true and Territory__c = :territoryId];
        system.assertNotEquals(null, dupeOpps);
        system.assertEquals(1, dupeOpps.size());
        Id dupeOppId = dupeOpps[0].Id;

        //CLOSE THE OPP
        dupeOpps[0].StageName = 'Cancelled';
        update dupeOpps;

        //Retrieve Any Action Type
        ActionType__mdt actionType = [Select Id, RecordTypeId__c From ActionType__mdt Where isTest__c = true Limit 1][0];
        //Override the defauly Record Type
        actionType.RecordTypeId__c = uncontactedRT;

        //Create new (dupe) Enquiry
        EnquiryManager.Enquiry enq = new EnquiryManager.Enquiry();
        enq.actionType = actionType;
        enq.tripDetails.territoryId = territoryId;
        enq.clientDetails.accountId = dupeOpps[0].AccountId;
        List<EnquiryManager.Enquiry> enquiries = new List<EnquiryManager.Enquiry>();
        enquiries.add(enq);

        system.assertEquals(null, enq.duplicateEnquiryId);

        test.startTest();
            //Scenario 3 - Closed Opp
            SalesEnquiryHandler.dedupeSalesEnquiries(enquiries);
            
        test.stopTest();

        system.assertEquals(null, enquiries[0].duplicateEnquiryId);
    }

    //Confirm non duplicates are excluded - Different Territory
    @isTest static void testSalesEnquiryDeDupeScenario4(){

        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;

        Id uncontactedRT = ApplicationConstant.OPP_RECTYPEID_UNCONTACTED;
        Id territoryId = [Select Id From Territory__c Where Name = 'Territory1' Limit 1][0].Id;

        Opportunity[] dupeOpps =  [Select Id, AccountId From Opportunity Where RecordTypeId = :uncontactedRT and IsOpen__c = true and Territory__c = :territoryId];
        system.assertNotEquals(null, dupeOpps);
        system.assertEquals(1, dupeOpps.size());
        Id dupeOppId = dupeOpps[0].Id;

        //Retrieve Any Action Type
        ActionType__mdt actionType = [Select Id, RecordTypeId__c From ActionType__mdt Where isTest__c = true Limit 1][0];
        //Override the defauly Record Type
        actionType.RecordTypeId__c = uncontactedRT;

        //Create new (dupe) Enquiry
        EnquiryManager.Enquiry enq = new EnquiryManager.Enquiry();
        enq.actionType = actionType;
        enq.tripDetails.territoryId = [Select Id From Territory__c Where NOT(Name = 'Territory1') Limit 1][0].Id;
        enq.clientDetails.accountId = dupeOpps[0].AccountId;
        List<EnquiryManager.Enquiry> enquiries = new List<EnquiryManager.Enquiry>();
        enquiries.add(enq);

        system.assertEquals(null, enq.duplicateEnquiryId);

        test.startTest();
            //Scneario 3 - Different Territory
            SalesEnquiryHandler.dedupeSalesEnquiries(enquiries);

        test.stopTest();

        system.assertEquals(null, enquiries[0].duplicateEnquiryId);
    }

    @isTest static void setEnqDefaultsScenario1(){

        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        //Create new Enquiry
        List<EnquiryManager.Enquiry> enquiries = new List<EnquiryManager.Enquiry>();
        EnquiryManager.Enquiry enq = new EnquiryManager.Enquiry();
        enq.clientDetails.firstName = 'Test';
        enq.clientDetails.lastName = 'Client';
        system.assertEquals(null, enq.recordName);
        enquiries.add(enq);
        
        test.startTest();
            SalesEnquiryHandler.setDefaults(enquiries);
        test.stopTest();
        system.assertNotEquals(null, enquiries[0].recordName);
        system.assertEquals('Test Client - '+((DateTime)system.today()).format('dd/MM/YYYY'), enquiries[0].recordName);


    }

}