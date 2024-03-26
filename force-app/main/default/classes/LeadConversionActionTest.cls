/*
Name:  LeadConversionActionTest.cls
======================================================
======================================================
Purpose:
-------
Test Suite for LeadConversionAction.cls

Coverage: 91%

Important! The test framework has issues with Salesforce
Formulas that reference the OrgSettings__c custom settings (e.g. $Setup.OrgSettings__c.ValidationRulesActive__c = TRUE).

This is causing validation and workflow rules to inexplicably fail
during a lead conversion. For example a rule that prevents users
from changing an Account record type is thrown despite the record type remaining
unchanged during the transaction (evident in the debug logs). Manual testing
confirms the process works fine (the lead conversion is successful) and unit tests succeed when 
references to the custom setting within the formulas and validation rules are removed.

Workaround - I am forced to temporarily remove the custom setting references
for the following validation rules and workflow rules during deployment:

Validation Rules:
Account.Cannot_Change_Record_Type
Opportunity.IFW_001_Duplicate_Not_a_Lead_Reason
Opportunity.IFW_006_Other_Member_Enquired_Number

Workflow Rules:
INTL_Denmark - Enquiry Email
INTL_Scandi - New Scandi Enquiry
INTL_Sweden - Enquiry Email
INTL_USA - Enquiry Email
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2023-09-13  Initial development.
*/
@isTest
public with sharing class LeadConversionActionTest {
    
    @testSetup static void createTestData(){

        //Create 3 accounts with leads
        //Note - Lead Conversion is very resource expensive. We'll be optimising the transaction as part of work item: W-002902
        List<Account> accs = AP23_TestDataFactory.createPersonAccount(3);
        insert accs;
        
        //Business Unit and Territories
        Golfbreaks_Business_Unit__c bu = new Golfbreaks_Business_Unit__c(Name='UK',DeveloperName__c='UK');
        insert bu;
        Territory__c t = new Territory__c(BusinessUnit__c=bu.Id,Countries__c='Spain',Name='Europe',DeveloperName__c='UKEurope');
        insert t;

        List<Lead> leads = AP23_TestDataFactory.createLead(3);
        Integer counter = 0;
        for(Lead l : leads){
            l.Account__c = accs[counter].Id;
            l.CountriesInterested__c = 'Spain';
            l.Golfbreaks_Business_Unit__c = bu.Id;
            l.Territory__c = t.Id;
            counter = counter+1;
        }
        insert leads;

        //Set the batch limit to 10
        insert new LeadConversionSettings__c(MaximumBatchSize__c=3);

        //Activate triggers
        insert new OrgSettings__c(TriggersActive__c=true);

    }

    //Confirm leads are converted successfully
    @isTest static void testLeadConversionSuccess(){

        system.assertEquals(0,[SELECT Count() FROM Opportunity]);

        Territory__c t = [Select Id, BusinessUnit__c, Countries__c From Territory__c Where DeveloperName__c = 'UKEurope'];

        List<Lead> testLeads = [Select Id, Account__c From Lead];
        system.assertEquals(3, testLeads.size());

        List<LeadConversionAction.LeadConversionInput> inputList = new List<LeadConversionAction.LeadConversionInput>();
        for (Lead testLead : testLeads) {
            LeadConversionAction.LeadConversionInput input = new LeadConversionAction.LeadConversionInput();
            input.leadId = testLead.Id;
            input.accountId = testLead.Account__c;
            input.opportunityName = null;
            input.ownerId = null;
            input.routeOpportunity = true;
            input.convertedLeadStatus = ApplicationConstant.LEAD_CLOSED_CONVERTED;
            inputList.add(input);
        }

        Test.startTest();
        	GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//Use live routing config
        	// Enqueue the conversion
            LeadConversionAction.convertLeads(inputList);
        Test.stopTest();

        //Confirm no failures
        system.assertEquals(0, [Select Count() From Golfbreaks__PlatformLog__c]);

        // Verify that leads were successfully converted into opps
        List<Opportunity> opps = [Select CountriesInterested__c, Golfbreaks_Business_Unit__c, Territory__c, OwnerId From Opportunity];
        system.assertEquals(3,opps.size());

        //Verify opp details e.g. country, territory, business unit and owner
        for(Opportunity opp : opps){
            system.assertEquals('Spain', opp.CountriesInterested__c);
            system.assertEquals(t.Id,opp.Territory__c);
            system.assertEquals(t.BusinessUnit__c, opp.Golfbreaks_Business_Unit__c);
        }

    }

    //Confirm unexpected exceptions are handled correctly
    @isTest static void testLeadConversionFailException(){

        system.assertEquals(0,[SELECT Count() FROM Opportunity]);

        List<Lead> testLeads = [Select Id, Account__c From Lead];
        system.assertEquals(3, testLeads.size());

        List<LeadConversionAction.LeadConversionInput> inputList = new List<LeadConversionAction.LeadConversionInput>();
        for (Lead testLead : testLeads) {
            LeadConversionAction.LeadConversionInput input = new LeadConversionAction.LeadConversionInput();
            input.leadId = testLead.Id;
            input.accountId = testLead.Account__c;
            input.opportunityName = null;
            input.ownerId = null;
            input.routeOpportunity = true;
            input.convertedLeadStatus = ApplicationConstant.LEAD_CLOSED_CONVERTED;
            inputList.add(input);
        }

        Test.startTest();
        	GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//Use live routing config
            LeadConversionAction.throwException = true;//THROW EXCEPTION
        	// Enqueue the conversion
            LeadConversionAction.convertLeads(inputList);
        Test.stopTest();

        //Confirm the failure is logged for the attention of the Salesforce Team.
        system.assertEquals(1, [Select Count() From Golfbreaks__PlatformLog__c Where Golfbreaks__Message__c LIKE '%Whoops! Something unexpected happened%']);

    }

    //Confirm Lead Conversion failures are handled correctly
    @isTest static void testLeadConversionFailConversionError(){

        system.assertEquals(0,[SELECT Count() FROM Opportunity]);

        List<Lead> testLeads = [Select Id, Account__c From Lead];
        system.assertEquals(3, testLeads.size());

        List<LeadConversionAction.LeadConversionInput> inputList = new List<LeadConversionAction.LeadConversionInput>();
        for (Lead testLead : testLeads) {
            LeadConversionAction.LeadConversionInput input = new LeadConversionAction.LeadConversionInput();
            input.leadId = testLead.Id;
            input.accountId = testLead.Account__c;
            input.opportunityName = null;
            input.ownerId = null;
            input.routeOpportunity = true;
            input.convertedLeadStatus = ApplicationConstant.LEAD_CLOSED_CONVERTED;
            inputList.add(input);
        }

        Test.startTest();
        	GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//Use live routing config
            LeadConversionAction.throwError = true;//THROW ERROR (FOR FIRST LEAD)
        	// Enqueue the conversion
            LeadConversionAction.convertLeads(inputList);
        Test.stopTest();

        //Confirm the failure is logged for the attention of the Salesforce Team.
        system.assertEquals(1, [Select Count() From Golfbreaks__PlatformLog__c]);

        // Verify the one failure did not prevent the remaining leads from being converted into opps
        system.assertEquals(2,[SELECT Count() FROM Opportunity]);

    }

}