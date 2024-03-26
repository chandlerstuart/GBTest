/**
* Class Name: AP54_SalesAgentAttributeUtility_Test
* @author: Jed Samaniego
* @date: 26.05.2016
* @description: Test Class AP54_SalesAgentAttributeUtility
*/

@isTest(seeAllData=false)

public class AP54_SalesAgentAttributeUtility_Test{

    static testMethod void testEvents() {
    //Create Account Validation rules
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;


     //Create Account
        List<Recordtype> accRT = [SELECT Id FROM Recordtype WHERE SobjectType='Account' AND IsPersonType=True and Developername = 'Client' LIMIT 1];
        Account acc = new Account();
        
        acc.FirstName = 'Test';
        acc.LastName = 'Account';
        acc.RecordTypeId = accRT[0].Id;
        
        database.insert(acc);
        
     //Create Opportunity        
        List<Opportunity> opp = AP23_TestDataFactory.createOpportunity(1,'New',acc);
        opp[0].StageName = ApplicationConstant.OPP_TYPE_OPEN;
        database.insert(opp);
        
    //Create Lead        
        List<Lead> lead = AP23_TestDataFactory.createLead(1);
        
        database.insert(lead);
        lead[0].Status = 'New';
        
        AP54_SalesAgentAttributeUtility.updateCorrespodingSAAofRecOwners(lead, opp);
        
        AP54_SalesAgentAttributeUtility.updateCorrespodingSAAofRecOwners(null, null);
        
    }
    
}