/*
Name:  OpportunityCreationWizardController_Test.cls
======================================================
======================================================
Purpose:
-------
Test class for OpportunityCreationWizardController.cls

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon Molloy  2017-07-04  Initial development.
*/
@isTest
private class OpportunityCreationWizardController_Test {
    @testSetup
    public static void setup() {
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;

        Account client = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert client;

        SalesOpportunityStages__c oppStage = new SalesOpportunityStages__c();
        oppStage.Name = '1. Recommendations';
        oppStage.Stage_Value__c = '1. Recommendations';
        insert oppStage;

        SalesLeadSource__c leadSource = new SalesLeadSource__c();
        leadSource.Name = 'Phone';
        leadSource.Lead_Source__c = 'Phone';
        insert leadSource;

        CountryOrdering__c co = new CountryOrdering__c();
        co.Name = 'UK & Ireland';
        co.Order__c = 1;
        insert co;
    }

    static testMethod void testExisting() {
        Account client = [select Id from Account LIMIT 1];
        PageReference testPage = Page.OpportunityCreationWizard;
        testPage.getParameters().put('accid',client.id);
        test.setCurrentPage(testPage);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseRebar());
        test.startTest();
            OpportunityCreationWizardController controller = new OpportunityCreationWizardController();

            controller.oppForm.SalesRegion__c = 'UK & Ireland';

            List<String> selectedCountries = new List<String>();
            selectedCountries.add('England & Wales');
            selectedCountries.add('Scotland');
            controller.selectedCountries = selectedCountries;

            controller.next(); //Page 1
            
            system.assertEquals(2, controller.page);
            system.assertEquals(FALSE, controller.showNewsletterSignup);
            system.assertEquals(FALSE, controller.showIsPGA);

            controller.finish(); //Finish

        test.stopTest();

    }

    static testMethod void testExistingWithChanges() {
        Account client = [select Id from Account LIMIT 1];
        PageReference testPage = Page.OpportunityCreationWizard;
        testPage.getParameters().put('accid',client.id);
        test.setCurrentPage(testPage);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseRebar());
        test.startTest();
            OpportunityCreationWizardController controller = new OpportunityCreationWizardController();

            controller.enquiryForm.Salutation = 'Mrs.';
            controller.enquiryForm.FirstName = 'Change';
            controller.enquiryForm.LastName = 'Testing';
            controller.enquiryForm.Email = 'change.testing@myemail.com';
            controller.enquiryForm.MobilePhone = '+447999999999';
            controller.enquiryForm.Phone = '+441111111111';
            controller.enquiryForm.NewsletterSignup__c = TRUE;
            controller.enquiryForm.PGA__c = TRUE;
            controller.enquiryForm.Street = '123 New Street';
            controller.enquiryForm.PostalCode = 'NE1 2EW';
            controller.inviteToBreakpoints = TRUE;

            controller.oppForm.SalesRegion__c = 'UK & Ireland';

            List<String> selectedCountries = new List<String>();
            selectedCountries.add('England & Wales');
            selectedCountries.add('Scotland');
            controller.selectedCountries = selectedCountries;

            Date travelDate = Date.today().addMonths(3);
            Date diaryDate = Date.today();
            controller.travelDate = ('0' + travelDate.day()).right(2) + '/' + ('0' + travelDate.month()).right(2) + '/' + travelDate.year();
            controller.diaryDate = ('0' + diaryDate.day()).right(2) + '/' + ('0' + diaryDate.month()).right(2) + '/' + diaryDate.year();

            controller.next(); //Page 1
            controller.finish(); //Finish

        test.stopTest();

        Account checkAccount = [select FirstName, LastName, PersonEmail, PersonMobilePhone, PersonHomePhone, NewsletterSignup__c, Is_PGA__pc,
                                PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode,
                                PersonMailingCountry from Account LIMIT 1];

        system.assertEquals('Change',checkAccount.FirstName);
        system.assertEquals('Testing',checkAccount.LastName);
        system.assertEquals('change.testing@myemail.com',checkAccount.PersonEmail);
        system.assertEquals('+447999999999',checkAccount.PersonMobilePhone);
        system.assertEquals('+441111111111',checkAccount.PersonHomePhone);
        system.assertEquals(TRUE,checkAccount.NewsletterSignup__c);
        system.assertEquals('123 New Street',checkAccount.PersonMailingStreet);
        system.assertEquals('NE1 2EW',checkAccount.PersonMailingPostalCode);

        //system.assertEquals(Date.today().addMonths(3), controller.oppForm.PreferredTravelDate__c);
        //system.assertEquals(Date.today(), controller.oppForm.DiaryDate__c);


    }

    static testMethod void testNew(){
        PageReference testPage = Page.OpportunityCreationWizard;
        test.setCurrentPage(testPage);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseRebar());
        test.startTest();
            OpportunityCreationWizardController controller = new OpportunityCreationWizardController();

            controller.next(); //Page 1
            controller.finish(); //Finish
            system.assertEquals(TRUE, controller.showNewsletterSignup);

        test.stopTest();
    
    }

    static testMethod void testCollections(){
        PageReference testPage = Page.OpportunityCreationWizard;
        test.setCurrentPage(testPage);

        test.startTest();
            OpportunityCreationWizardController controller = new OpportunityCreationWizardController();
            List<SelectOption> oppStages = controller.oppStages;
            List<SelectOption> leadSources = controller.leadSources;
            List<SelectOption> leadBookerOpts = controller.leadBookerOpts;
            Map<String, String> countryMap = controller.countryMap;
            List<SelectOption> regionOptions = controller.regionOptions;
            List<SelectOption> salesUsers = controller.salesUsers;
            boolean showInviteToBreakpoints = controller.showInviteToBreakpoints;

            PageReference getCountries = controller.getCountries();
            controller.oppForm.SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_UK_IRELAND;
            getCountries = controller.getCountries();
            system.assertNotEquals(true, controller.countryOptions.isEmpty());

            String tarfbagInput = controller.tarfbagInput;


        test.stopTest();    
    }

}