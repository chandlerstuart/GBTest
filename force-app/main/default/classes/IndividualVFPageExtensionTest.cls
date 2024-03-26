/*
Name:  IndividualVFPageExtensionTest.cls
======================================================
======================================================
Purpose:
-------
Test Class for the IndividualVFPageExtension 

======================================================
======================================================
History
------- 
Ver. Author           Date        Detail
1.0  James Radcliffe  20/04/2018  Initial Development.
1.1  James Radcliffe  23/10/2019  Remove Reference to redundant properties
*/
@isTest
public class IndividualVFPageExtensionTest {
    
    @testSetup static void createTestData(){

        //Allow the current running test user to insert Client accounts        
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        
        //Create new Account (and Individual)
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert acc;
        
        //Query Individual and create Preference Centre Change History records
        Individual i = [Select Id, Account__c, Weekly_Newsletter__c From Individual Where Account__c = :acc.Id][0];
        
        //Insert Change History record
        List<Preference_Centre_Change__b> changeHistory = new List<Preference_Centre_Change__b>();
        Set<Id> indIds = new Set<Id>{i.Id};
        changeHistory.add(IndividualTriggerHandlerV2.createChangeHistoryEntry(i.Id, i.Account__c, ApplicationConstant.WEEKLY_NEWSLETTER, null, string.valueOf(i.Weekly_Newsletter__c), 'Test Change History'));        
        system.enqueueJob(new IndividualTriggerHandlerV2.PostPreferenceCentreUpdateProcessorClass(changeHistory,indIds/*,null,null*/));
              
        
    }
    
    
    
    //Test the constrcutor populates the Big Object data in the list
    @isTest static void testGetPreferenceCentreChangeHistory(){
        
        //Query Individual and Change History
        Individual[] individuals = [Select Id, Account__c, Weekly_Newsletter__c , (Select Id, Preference__c, New_Value__c, Old_Value__c From PreferenceCentreChange__r) From Individual];
        system.assertEquals(1, individuals.size());      
        
        ApexPages.StandardController sc = new ApexPages.StandardController(individuals[0]);
        IndividualVFPageExtension ext = new IndividualVFPageExtension(sc);
        
        //Cannot run assertions on the creation of the Preference Centre Change records without creating a new Mock Framework. Big Objects are not supported in the standard testing framework.
        

    }

}