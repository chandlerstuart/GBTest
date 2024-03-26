/*
Name: InviteToBreakpointsControllerTest
======================================================
======================================================
Purpose: Test for InviteToBreakpoints component. The I2B
callout is tested elsewhere, this class ensures the functionality is called correctly
and exceptions are thrown/handled for invalid component config
======================================================
======================================================
History

Version		Author			Date		Detail
1.0			J Radcliffe		19-03-21	Initial Development
*/
@isTest
public class InviteToBreakpointsControllerTest {
    
    @testSetup static void createTestData(){
        
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        //Insert Account
        Account acc = new Account();
        acc.FirstName = 'Test';
        acc.LastName = 'Account';
        acc.RecordTypeId = [Select Id From RecordType Where sObjectType = 'Account' and IsPersonType = true Limit 1].Id;
        insert acc;
        
        //Insert Opportunity
        Opportunity o = new Opportunity();
        o.Name = 'Test Opp';
        o.AccountId = acc.Id;
        o.StageName = 'Testing';
        o.CloseDate = system.today().addDays(30);
        insert o;
    }
    
    @isTest static void testInviteFromAccount(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        //Query Account
        Account[] accs = [Select Id From Account];
        system.assertEquals(1, accs.size());
        test.startTest();
        InviteToBreakpointsController.sendInvite('Id','Account',accs[0].Id);
        test.stopTest();
    }
    
    @isTest static void testInviteFromOpportunity(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        //Query Opportunity
        Opportunity[] opps = [Select Id From Opportunity];
        system.assertEquals(1, opps.size());
        test.startTest();
        InviteToBreakpointsController.sendInvite('AccountId','Opportunity',opps[0].Id);
        test.stopTest();
    }
    
    @isTest static void exceptionThrownForInvalidConfig(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        //Query Opportunity
        Opportunity[] opps = [Select Id From Opportunity];
        system.assertEquals(1, opps.size());
        test.startTest();
        try{
            InviteToBreakpointsController.sendInvite('InvalidFieldName','Opportunity',opps[0].Id);
        }catch(exception e){
            system.debug('Exception: '+e); 
            system.assertEquals('System.AuraHandledException', e.getTypeName()); 
        }      	
        test.stopTest();
        
    }    
    
}