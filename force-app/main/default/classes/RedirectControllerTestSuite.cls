/*
Name:  RedirectControllerTestSuite.cls
Copyright © 2014  Kaptio ehf.
======================================================
======================================================
Purpose:
-------
Test class for RedirectController.cls, RedirectHelper.cls
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Ragnar   2014-09-04  Class creation.

*/
@isTest
private class RedirectControllerTestSuite {
    
    private static Account testAcc;
    
    private static void initData() {
        
        testAcc = new Account(Name = 'TestAcc');
        insert testAcc;
    }
    
    static testMethod void testRedirectController() {
        
        initData();
        
        RedirectController controller = new RedirectController();
        
        System.Test.StartTest();
        System.assert(controller.redirectUser()==null);
        controller.redirectUser();
        
        ApexPages.currentPage().getParameters().put('object','Opportunity');
        PageReference pageRef = controller.redirectUser();
        system.assert(pageRef!=null);
        
        
        ApexPages.currentPage().getParameters().put('allowRTS','true');
        ApexPages.currentPage().getParameters().put('Name','88345345');
        ApexPages.currentPage().getParameters().put('ID_Account',testAcc.Id);
        ApexPages.currentPage().getParameters().put('Account',testAcc.Id);
        ApexPages.currentPage().getParameters().put('def_account_id',testAcc.Id);
        pageRef = controller.redirectUser();
        system.assertEquals('88345345', pageRef.getParameters().get('CF00NK0000000Yt1b'));
        
        system.assertEquals('Name',RedirectHelper.getLabel('Opportunity', 'Name'));
        System.Test.StopTest();
        
    }
}