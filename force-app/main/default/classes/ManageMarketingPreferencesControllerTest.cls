/*
Name: ManageMarketingPreferencesControllerTest
======================================================
======================================================
Purpose: Test class for ManageMarketingPreference component controller
======================================================
======================================================
History

Version     Author          Date        Detail
1.0         J Radcliffe     19-03-18    Initial Development
1.1         J Radcliffe     24-02-21    Insert Individual in Test Setup (No longer implicitly created by Account creation)
*/
@isTest
public class ManageMarketingPreferencesControllerTest {
    
    @testSetup static void testSetup(){
                
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;

        //1.1+
        Individual ind = new Individual(LastName='Account');
        insert ind;
        
        //Insert an Account (and implicitly an 'Individual') record
        Account acc = new Account();
        acc.FirstName = 'Test';
        acc.LastName = 'Account';
        acc.PersonEmail = 'testaccount@example.com';
        acc.RecordTypeId = [Select Id From RecordType Where sObjectType = 'Account' and IsPersonType  = true Limit 1].Id;
        acc.PersonIndividualId = ind.Id;
        insert acc;
        
        //Insert a Lead for the Account
        Lead l = new Lead();
        l.Account__c = acc.Id;
        l.LastName = 'Test Lead';
        l.Company = 'Test Company';   
        insert l;        
    }
    
    @isTest static void testGetData(){
        
        //Retrieve the Lead created in testSetup
        Lead l = [Select Id, Account__r.PersonIndividualId, Account__c From Lead Limit 1][0];

        Account acc = new Account(Id=l.Account__c);
        acc.PersonIndividualId = [Select Id From Individual Limit 1].Id;
        update acc;
        
        test.startTest();
            ManageMarketingPreferencesController.mmpcWrapper wrapper = ManageMarketingPreferencesController.getData(l.Id, 'Account__c', ApplicationConstant.LEAD_SOBJECTTYPE,null); 
        test.stopTest();
        
        //Verify expected data is retrieved
        system.assertNotEquals(null, wrapper);
        system.assertNotEquals(null, wrapper.acc);
        system.assertNotEquals(null, wrapper.ind);
        system.assertEquals(wrapper.acc.Id,wrapper.ind.Account__c);
        system.assertEquals('testaccount@example.com',wrapper.acc.PersonEmail);
    }
    
    @isTest static void submitChangesTest(){
        
        //Query records
        Account acc = [Select Id, PersonEmail, PersonMailingStreet, PersonMailingCity, PersonMailingCountry, Mailing_State_County__pc, PersonMailingPostalCode, Phone, PersonMobilePhone, PersonHomePhone, PersonOtherPhone, BillingStreet, BillingCity, BillingCountry, BillingPostalCode, Billing_State_County__c From Account Limit 1][0];
        Individual ind = [Select Id, Account__c, Email__c, Phone__c, SMS__c, Brochure__c, Weekly_Newsletter__c, Quarterly_Newsletter__c, Data_Audit_Last_Completed__c From Individual Limit 1][0];
        
        //Initial Assertions
        system.assertEquals(null,ind.Data_Audit_Last_Completed__c);
        system.assertEquals(null,acc.BillingStreet);
        system.assertEquals(null,acc.BillingCity);
        system.assertEquals(null,acc.BillingCountry);
        system.assertEquals(null,acc.BillingPostalCode);
        system.assertEquals(null,acc.Billing_State_County__c);
        
        //Modify records
        ind.Brochure__c = true;
        ind.Weekly_Newsletter__c = true;
        ind.Email__c = true;
        
        String testStreet = '72 fakemailingstreet';
        String testCity = 'fakemailingcity';
        String testCountry = 'United Kingdom';
        String testPostalCode = 'RG12 2RT';
        String testState = 'fakeCounty';
        
        acc.PersonMailingStreet = testStreet;
        acc.PersonMailingCity = testCity;
        acc.PersonMailingCountry = testCountry;
        acc.PersonMailingPostalCode = testPostalCode;
        acc.Mailing_State_County__pc = testState;
        
        String changeLogString = 'ConsoleChanges';
        
        test.startTest();
            ManageMarketingPreferencesController.submitChanges(ind, acc, changeLogString,null);
        test.stopTest();        
        
        //Re-query records
        Account accAfter = [Select Id, PersonEmail, PersonMailingStreet, PersonMailingCity, PersonMailingCountry, Mailing_State_County__pc, PersonMailingPostalCode, Phone, PersonMobilePhone, PersonHomePhone, PersonOtherPhone, BillingStreet, BillingCity, BillingCountry, BillingPostalCode, Billing_State_County__c From Account Where Id = :acc.Id Limit 1][0];
        Individual indAfter =  [Select Id, Account__c, Phone__c, SMS__c, Brochure__c, Weekly_Newsletter__c, Quarterly_Newsletter__c, Data_Audit_Last_Completed__c From Individual Where Id = :ind.Id Limit 1][0];       
        
        //Assertions
        system.assertEquals(system.today(), indAfter.Data_Audit_Last_Completed__c);
        system.assertEquals(true, indAfter.Brochure__c);
        system.assertEquals(true, indAfter.Weekly_Newsletter__c);
        system.assertEquals(testStreet, accAfter.BillingStreet);
        system.assertEquals(testCity, accAfter.BillingCity);
        system.assertEquals(testCountry, accAfter.BillingCountry);
        system.assertEquals(testPostalCode, accAfter.BillingPostalCode);
        system.assertEquals(testState, accAfter.Billing_State_County__c);

    } 
    
    @isTest static void noChangesRequiredTest(){
        
        //Query individual record
        Individual ind = [Select Id, Data_Audit_Last_Completed__c From Individual Limit 1][0];
        
        //Initial Assertion
        system.assertEquals(null,ind.Data_Audit_Last_Completed__c);
        
        test.startTest();
            ManageMarketingPreferencesController.noChangesRequired(ind.Id);
        test.stopTest();
        
        //Re-query Individual
        Individual indAfter = [Select Id, Data_Audit_Last_Completed__c From Individual Where id=:ind.Id Limit 1][0];
        
        //Assertions
        system.assertEquals(system.today(), indAfter.Data_Audit_Last_Completed__c);
 
    }
    
}