/*
Name:  OpportunityToEnquiryActionTest.cls
======================================================
======================================================
Purpose:
-------
Test class for OpportunityToEnquiryAction

======================================================
======================================================
History
------- 
Ver. Author           Date        Detail
1.0  James Radcliffe  24/05/2018  Initial Development.
1.1  James Radcliffe  02/07/2018  Commenting out testProcessOpportunitiesExceptionFailure - Explanation below
1.2  James Radcliffe  11/07/2019  Setting Test Override for WIRE Package (so the valid Routing Configs are retrieved)
*/
@isTest
public class OpportunityToEnquiryActionTest {
    
    @testSetup static void testSetup(){
    
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2
        
        //Prep environment (custom settings)
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;  
        
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        
        
        //Create Accounts (x5)
        Account[] accounts = AP23_TestDataFactory.createPersonAccount(5);
        insert accounts;
        
        //Create Opps (x5)
        List<Opportunity> opportunities = new List<Opportunity>();
        String newSalesOpp = ApplicationConstant.OPPORTUNITY_RECORD_NEWSALES;
        String oppLeadSource = ApplicationConstant.OPPORTUNITY_LEAD_SOURCE_BOOKING_REQUEST;
        Id newSalesOppRTId = [Select Id From RecordType Where DeveloperName = :newSalesOpp Limit 1].Id;
        for(Account acc : accounts){
            Opportunity opp = new Opportunity();
            opp.Name = 'Booking Request Test Opp';
            opp.CloseDate = system.today();
            opp.StageName = '1. Recommendations';
            opp.Additionalinformation__c = 'Test Clubhouse Sync';
            opp.AffiliateCampaignId__c = 99999999;
            opp.Nights__c = 5;
            opp.AccountId = acc.Id;
            opp.CountriesInterested__c = 'Spain;Portugal';
            opp.LeadSource = oppLeadSource;
            opp.TravelGroupSize__c = 2;
            opp.RecordTypeId = newSalesOppRTId;
            opp.Venue__c = 'Fake Hotel & Golf';
            opp.PromoCode__c = '12345';
            opportunities.add(opp);            
        }
        insert opportunities;
        
    }
    
    @isTest static void testProcessOpportunitiesSuccess(){
    
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2
        
        //Implement Mock Framework
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseRebar());
        
        //Query Opps
        String oppLeadSource = ApplicationConstant.OPPORTUNITY_LEAD_SOURCE_BOOKING_REQUEST;
        system.debug('oppLeadSource: '+oppLeadSource);
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>( [Select Id, owner.Golfbreaks_Employee_Id__c, owner.Email, owner.FirstName, owner.LastName, AdditionalInformation__c, AffiliateCampaignId__c, Nights__c, AccountId, PreferredTravelDate__c, PromoCode__c, TravelGroupSize__c, Venue__c, CountriesInterested__c, Weekly_Newsletter__c From Opportunity Where LeadSource = :oppLeadSource LIMIT 1] );
        system.assertEquals(1, oppMap.size());       
        
        //Pass list to method
        test.startTest();
        OpportunityToEnquiryAction.sendOppsToClubhouse sc = new OpportunityToEnquiryAction.sendOppsToClubhouse(oppMap); 
        sc.processOpportunities();     
        //OpportunityToEnquiryAction.sendOppstoClubhouse(opps);
        test.stopTest();
        
        //Assert no Error Logs have been inserted for the corresponding class
        Error_Log__c[] logs = [Select Id, Trace__c, Error_Message__c, Class_Name__c From Error_Log__c Where Class_Name__c = 'OpportunityToEnquiryAction'];
        system.debug('should not exist: logs:'+logs);
        system.assertEquals(false,logs.size()>0);
        
    }
    //A method to test failures with the CH integration
    @isTest static void testProcessOpportunitiesFailure(){
    
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2
        
        //Implement Mock Framework (Failure)
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseRebarFailure());
        
        //Query Opps
        String oppLeadSource = ApplicationConstant.OPPORTUNITY_LEAD_SOURCE_BOOKING_REQUEST;
        system.debug('oppLeadSource: '+oppLeadSource);
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>( [Select Id, owner.Golfbreaks_Employee_Id__c, owner.Email, owner.FirstName, owner.LastName, AdditionalInformation__c, AffiliateCampaignId__c, Nights__c, AccountId, PreferredTravelDate__c, PromoCode__c, TravelGroupSize__c, Venue__c, CountriesInterested__c, Weekly_Newsletter__c From Opportunity Where LeadSource = :oppLeadSource LIMIT 1] );
        system.assertEquals(1, oppMap.size());
        
        //Pass list to method
        test.startTest();
        OpportunityToEnquiryAction.sendOppsToClubhouse sc = new OpportunityToEnquiryAction.sendOppsToClubhouse(oppMap); 
        sc.processOpportunities(); 
        test.stopTest(); 
        
        //Assert Error Logs have been created
        Error_Log__c[] logs = [Select Id, Trace__c, Error_Message__c, Class_Name__c From Error_Log__c Where Class_Name__c = 'OpportunityToEnquiryProcessor'];
        system.assertEquals(true,logs.size()>0);
        system.debug('Error Log Record/s: '+logs);
        
    }    
    
  /* 1.1 Creating Error records will not work since it falls in the same scope. All the Database Transactions in that scope will be rolled back.
   * A new means of handling exceptions is required, but for now this method will be removed
    
    //A method to test exception failues
    @isTest static void testProcessOpportunitiesExceptionFailure(){
        
        //Implement Mock Framework
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseRebar());
        //Query Opps without all the required fields for mapping to the enquiry request wrapper (force a failure)
        String oppLeadSource = ApplicationConstant.OPPORTUNITY_LEAD_SOURCE_BOOKING_REQUEST;
        system.debug('oppLeadSource: '+oppLeadSource);
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>( [Select Id From Opportunity Where LeadSource = :oppLeadSource LIMIT 1] );
        system.assertEquals(1, oppMap.size());
        
        //Pass list to method
        test.startTest();
        //Run Test
        OpportunityToEnquiryAction.sendOppsToClubhouse sc = new OpportunityToEnquiryAction.sendOppsToClubhouse(oppMap); 
        sc.processOpportunities(); 
        test.stopTest();
        
        //Assert Error Logs have been created
        Error_Log__c[] logs = [Select Id, Trace__c, Error_Message__c, Class_Name__c From Error_Log__c Where Class_Name__c = 'OpportunityToEnquiryAction'];
        system.assertEquals(true,logs.size()>0);
        system.debug('Error Log Record/s: '+logs);
    } */
    
    //A method to test the getSalesRegionMap method
    @isTest static void testGetSalesRegionMapMethod(){
    
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2
        
        Map<String,String> srMap = OpportunityToEnquiryAction.getSalesRegionMap();
        system.assertEquals(7,srMap.values().size());
        
    }  
    
    //Scheduling a method in a test context counts as a DML statement and results in a callout error. The majority of tests therefore invoke the 'processOpportunities' method
    //which fully tests the functionality. This method runs the full method for test coverage purposes.
    @isTest static void runSendOppsToClubhouse(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.2
        
        String oppLeadSource = ApplicationConstant.OPPORTUNITY_LEAD_SOURCE_BOOKING_REQUEST;
        Opportunity[] oppList = [Select Id From Opportunity Where LeadSource = :oppLeadSource LIMIT 1];
        OpportunityToEnquiryAction.sendOppstoClubhouse(oppList);
        
    }    
    
    
    
}