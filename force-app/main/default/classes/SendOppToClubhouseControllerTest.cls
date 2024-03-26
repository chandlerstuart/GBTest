/*
Purpose: Apex Test for for SendOppToClubhouseController
TO DO - This has been thrown together to support a release. Needs deprecating or refining at a later stage
*/
@isTest
public class SendOppToClubhouseControllerTest {
    @testSetup static void createTestData(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
        
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings; 
        
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.StageName = 'New';
        opp.GolfbreaksEnquiryId__c = null;
        opp.CloseDate = system.today().addDays(10);
        opp.Name = 'Test Opp';
        opp.AccountId = acc.Id;
        
        insert opp;
    }
    
    @isTest static void queueActionTest(){
        Opportunity opp = [Select Id, GolfbreaksEnquiryId__c From Opportunity Limit 1];
        test.startTest();
        	SendOppToClubhouseController.queueAction(opp);
        test.stopTest();
        //TO DO - Assertions
    }
    
    @isTest static void queueActionTestError(){
        SendOppToClubhouseController.throwError = true;
        Opportunity opp = [Select Id, GolfbreaksEnquiryId__c From Opportunity Limit 1];
        test.startTest();
        	SendOppToClubhouseController.queueAction(opp);
        test.stopTest();
       
    }
}