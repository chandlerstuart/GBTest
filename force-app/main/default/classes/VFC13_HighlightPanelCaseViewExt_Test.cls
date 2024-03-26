/*
Name:  VFC13_HighlightPanelCaseViewExt_Test.cls
======================================================
======================================================
Purpose:
-------
Test Class for VFC13_HighlightPanelCaseViewExt
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.0  S.Molloy      2017-06-28   Initial development
*/
@isTest
private class VFC13_HighlightPanelCaseViewExt_Test {
    
    
    @testSetup
    static void dataSetup() {
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;

        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert acc;
        
        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, '1. Recommendations', acc)[0];
        insert opp;
        
        Case cse = AP23_TestDataFactory.createCase(1, acc)[0];
        cse.Opportunity__c = opp.Id;
        insert cse;
    }
    
    private static testMethod void test() {
        Account a = [select Id from Account];
        ApexPages.StandardController std = new ApexPages.StandardController(a);
        PageReference testPage = Page.VFP13_HighlightPanelCaseView;
        testPage.getParameters().put('accId',a.Id);
        test.setCurrentPage(testPage);
        List<Case> caseList;
        test.startTest();
            VFC13_HighlightPanelCaseViewExt controller = new VFC13_HighlightPanelCaseViewExt(std);
            caseList = controller.cases;
        test.stopTest();

        system.assertNotEquals(true, caseList.isEmpty());
    }
}