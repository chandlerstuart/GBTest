/*
Name:  VFC11_AccountHighlightsPanel_Test.cls
======================================================
======================================================
Purpose:
-------
Test Class for VFC11_AccountHighlightsPanel
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.0  S.Molloy      2017-06-28   Initial development
1.1  J.Radcliffe   2018-05-09   Added test method: testPreferenceCentreColumn
*/
@isTest
private class VFC11_AccountHighlightsPanel_Test {
    
    
    @testSetup
    static void dataSetup() {
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert acc;
        
        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, '1. Recommendations', acc)[0];
        insert opp;
        
        Booking__c book = AP23_TestDataFactory.createBooking(1, acc.Id, opp.Id)[0];
        book.AmountPaid__c = 5000;
        book.TransferDetailsRequired__c = true;
        book.RoomingListRequired__c = true;
        book.Travel_Date__c = Date.today().addDays(14);
        book.Booking_Date__c = Date.today();
        insert book;
        
        List<Lead> leadList = AP23_TestDataFactory.createLead(1,acc.Id);
        leadlist[0].Email = acc.PersonEmail;
        leadList[0].LastName = acc.LastName;
        leadList[0].FirstName = acc.FirstName;
        insert leadList;
        
        Case cse = AP23_TestDataFactory.createCase(1, acc)[0];
        cse.Opportunity__c = opp.Id;
        cse.Booking__c = book.Id;
        insert cse;
        
        Expected_Payment__c ep = AP23_TestDataFactory.createExpectedPayment(1, book, 'Full Deposit', 5000)[0];
        ep.Expected_Amount__c  = 10000;
        insert ep;
    }
    
    private static testMethod void test() {
        Account acc = [SELECT Id, NewsletterSignup__c FROM Account];
        
        acc.NewsletterSignup__c = TRUE;
        update acc;
        
        PageReference pageRef = Page.VFP11_AccountHighlightsPanel;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(acc);
        
        test.startTest();
        
        VFC11_AccountHighlightsPanel controller = new VFC11_AccountHighlightsPanel(sc);
        
        integer openCaseCount = controller.openCaseCount;
        system.assertNotEquals(null, openCaseCount);
        
        boolean showModal = controller.showModal;
        system.assertEquals(FALSE, showModal);
        
        //String tableColour = controller.tableColour;
        //system.assertEquals('GhostWhite', tableColour);
        
        Case cse = controller.getCaseDetails();
        
        integer caseCount = controller.getNumberOfOpenCases();
        system.assertEquals(1, caseCount);
        
        controller.updateNewsletterSubscribe();
        
        
        test.stopTest();
        
    }
    
    private static testMethod void testVIP() {
        Account acc = [SELECT Id, Is_Concierge__c FROM Account];
        acc.Is_Concierge__c = TRUE;
        update acc;
        
        Client_Profile__c cp = new Client_Profile__c(Account__c = acc.Id, Type__c = 'Critical', Sub_Type__c = 'Booking');
        insert cp;
        
        PageReference pageRef = Page.VFP11_AccountHighlightsPanel;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(acc);
        
        test.startTest();
        
        VFC11_AccountHighlightsPanel controller = new VFC11_AccountHighlightsPanel(sc);
        system.assertEquals(true, controller.showClientProfiles);
        system.assertNotEquals(true, controller.clientProfiles.isEmpty());
        system.assertEquals(1, controller.clientProfileCount);
        
        test.stopTest();
        
    }
    
    private static testMethod void test2(){
        Account acc = [SELECT Id, NewsletterSignup__c FROM Account];
        
        acc.Notification_Message__c = 'TEST MESSAGE';
        update acc;
        
        PageReference pageRef = Page.VFP11_AccountHighlightsPanel;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(acc);
        
        test.startTest();
        
        VFC11_AccountHighlightsPanel controller = new VFC11_AccountHighlightsPanel(sc);
        
        boolean showModal = controller.showModal;
        system.assertEquals(TRUE, showModal);
        
        controller.closeModal();
        system.assertEquals(FALSE, controller.showModal);
        
        test.stopTest();
    }
    
    private static testMethod void test3() {
        Account acc = [SELECT Id, PersonHomePhone, Mailing_State_County__pc, PersonMobilePhone, PersonOtherPhone, PersonEmail, PersonMailingPostalCode, NewsletterSignup__c FROM Account];
        
        PageReference pageRef = Page.VFP11_AccountHighlightsPanel;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(acc);
        VFC11_AccountHighlightsPanel controller = new VFC11_AccountHighlightsPanel(sc);
        
        //Test Exceptions
        controller.acc.PersonHomePhone = '01234567890';
        controller.acc.PersonMobilePhone = '09876543210';
        controller.acc.PersonOtherPhone = '01928374650';
        controller.acc.PersonEmail = 'test.email';
        controller.saveUpdates();
        
        system.assertNotEquals(TRUE, ApexPages.getMessages().isEmpty());
        
        controller.acc.PersonHomePhone = '+441234567890';
        controller.acc.PersonMobilePhone = '+449876543210';
        controller.acc.PersonOtherPhone = '+441928374650';
        controller.acc.PersonEmail = 'test.email@myemail.com';
        controller.saveUpdates();
        
        controller.updateNewsletterSubscribe();
        
        acc = [select Id, PersonHomePhone, PersonMobilePhone, PersonOtherPhone, PersonEmail, NewsletterSignup__c from Account LIMIT 1];
        system.assertEquals('+441234567890', acc.PersonHomePhone);
        system.assertEquals('+449876543210', acc.PersonMobilePhone);
        system.assertEquals('+441928374650', acc.PersonOtherPhone);
        system.assertEquals('test.email@myemail.com', acc.PersonEmail);
        
        controller.clearMessage();
        
        controller.emailBreakpointsInvite();
        boolean hasErrors = controller.hasErrors;
    } 
    
    @isTest static void testPreferenceCentreColumn(){
        
        //Query person account and related individual
        Account acc = [Select Id, PersonHomePhone, Mailing_State_County__pc, PersonMobilePhone, PersonOtherPhone, PersonEmail, PersonMailingPostalCode, (Select Id, Account__c, Data_Audit_Last_Completed__c, Phone__c, Brochure__c, Weekly_Newsletter__c, Quarterly_Newsletter__c, SMS__c From Individuals__r) From Account Where isPersonAccount = true LIMIT 1];   
        system.assertNotEquals(null,acc);
        system.assertEquals(1,acc.Individuals__r.size());
        
        //Set parameters and instanstiate Controller
        Test.setCurrentPage(Page.VFP11_AccountHighlightsPanel);				        
        ApexPages.StandardController sc = new ApexPages.StandardController(acc);             
        
        test.startTest();
        VFC11_AccountHighlightsPanel controller = new VFC11_AccountHighlightsPanel(sc);    
        test.stopTest();
        
        //Confirm the Individual has been set
        system.assertEquals(controller.ind.Id,acc.Individuals__r[0].Id);
        system.assertEquals(controller.ind.Account__c,acc.Id);
        
        //Confirm the Account has been set
        system.assertEquals(controller.acc.Id,acc.Id);
        
        //Confirm the styling variables have been set
        system.assertNotEquals(null, controller.weeklyNewsletterState);
        system.assertNotEquals(null, controller.phoneState);
        system.assertNotEquals(null, controller.smsState);
        system.assertNotEquals(null, controller.quarterlyNewsletterState);
        system.assertNotEquals(null, controller.postState);
        system.assertNotEquals(null, controller.lastAudit);        
        
        
    }
    
}