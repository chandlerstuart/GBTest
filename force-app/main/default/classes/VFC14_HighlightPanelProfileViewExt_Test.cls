/*
Name:  VFC14_HighlightPanelProfileViewExt_Test.cls
======================================================
======================================================
Purpose:
-------
Test Class for VFC14_HighlightPanelProfileViewExt
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.0  S.Molloy      2017-09-11   Initial development
*/
@isTest
private class VFC14_HighlightPanelProfileViewExt_Test {
    
    
    @testSetup
    static void dataSetup() {
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;

        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        acc.Is_Concierge__c = TRUE;
        insert acc;
        
        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, '1. Recommendations', acc)[0];
        insert opp;
        
        Case cse = AP23_TestDataFactory.createCase(1, acc)[0];
        cse.Opportunity__c = opp.Id;
        insert cse;

        Client_Profile__c cp = new Client_Profile__c(Account__c = acc.Id, Type__c = 'Critical', Sub_Type__c = 'Booking');
        insert cp;
    }
    
    private static testMethod void test() {
        Account a = [select Id from Account];
        ApexPages.StandardController std = new ApexPages.StandardController(a);
        PageReference testPage = Page.VFP14_HighlightPanelProfileView;
        testPage.getParameters().put('accId',a.Id);
        test.setCurrentPage(testPage);
        List<Client_Profile__c> cpList;
        test.startTest();
            VFC14_HighlightPanelProfileViewExt controller = new VFC14_HighlightPanelProfileViewExt(std);
            cpList = controller.clientProfiles;
        test.stopTest();

        system.assertNotEquals(true, cpList.isEmpty());

    }
}