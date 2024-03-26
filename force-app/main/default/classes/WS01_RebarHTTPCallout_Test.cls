/**
Name:  WS01_RebarHTTPCallout_Test.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test Class for WS01_RebarHTTPCallout
======================================================
======================================================
History
------- 
Ver. Author         Date         Detail
1.0  Ana D          2016-05-06   Initial test class development
2.0  Simon M.       2017-07-13   New tests to test outboundMessageCallerOpportunity method
2.1  Simon M.       2017-08-09   New test for updateAccountManager web service call
2.2  J Radcliffe    2019-05-07   Set WIRE package flag to ensure valid routing config is returned in Test context
**/

@isTest(SeeAllData=false)
private class WS01_RebarHTTPCallout_Test {

    @testSetup static void setupData() {

        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride  = true;//2.2

        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;  

        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;

        List<Object_Field_Mapping__c> customSettings = AP23_TestDataFactory.getCustomSettingObjectFieldMapping();       

        insert customSettings;

        HTTP_Timeout__c httpTimeout = new HTTP_Timeout__c(Name = 'Lead Convert');
        httpTimeout.Timeout_In_Seconds__c = 15;
        insert httpTimeout;

        HTTP_Timeout__c httpTimeout1 = new HTTP_Timeout__c(Name = 'Opportunity Convert');
        httpTimeout1.Timeout_In_Seconds__c = 15;
        insert httpTimeout1;

        HTTP_Timeout__c httpTimeout2 = new HTTP_Timeout__c(Name = 'Account Manager Change');
        httpTimeout2.Timeout_In_Seconds__c = 15;
        insert httpTimeout2;

    }

    private static testMethod void testWS01_RebarHTTPCallout() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride  = true;//2.2
        
        //create test data
        String salesUserProfile = ApplicationConstant.PROFILE_SALES_AGENT;
        List<User> userList = [SELECT Id FROM User WHERE Profile.Name = :salesUserProfile AND IsActive = true LIMIT 1];
        userList.get(0).Golfbreaks_Employee_Id__c = 1234;
        update userList;

        User testUser = [SELECT Id, Golfbreaks_Employee_Id__c  FROM User WHERE Id=:userList.get(0).Id LIMIT 1];

        Lead lead = AP23_TestDataFactory.createLead(1)[0];
        lead.OwnerId = testUser.Id;
        database.insert(lead);

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        System.assertEquals(true, WS01_RebarHTTPCallout.outboundMessageCreator(lead.Id, 'ENQUIRY').contains('100'));
        test.stopTest();
    }
    
    private static testMethod void testWS01_RebarHTTPCallout2() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride  = true;//2.2
        
        //create test data
        String salesUserProfile = ApplicationConstant.PROFILE_SALES_AGENT;
        List<User> userList = [SELECT Id FROM User WHERE Profile.Name = :salesUserProfile AND IsActive = true LIMIT 1];
        userList.get(0).Golfbreaks_Employee_Id__c = 1234;
        update userList;

        User testUser = [SELECT Id, Golfbreaks_Employee_Id__c  FROM User WHERE Id=:userList.get(0).Id LIMIT 1];

        Lead lead = AP23_TestDataFactory.createLead(1)[0];
        lead.OwnerId = testUser.Id;
        database.insert(lead);
        
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseRebar());
        System.assertEquals(true, WS01_RebarHTTPCallout.outboundMessageCreator(lead.Id, 'ENQUIRY').contains('200'));
        test.stopTest();
    }
    private static testMethod void testWS01_RebarHTTPCallout3() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride  = true;//2.2
        
        //create test data
        String salesUserProfile = ApplicationConstant.PROFILE_SALES_AGENT;
        List<User> userList = [SELECT Id FROM User WHERE Profile.Name = :salesUserProfile AND IsActive = true LIMIT 1];
        userList.get(0).Golfbreaks_Employee_Id__c = 1234;
        update userList;

        User testUser = [SELECT Id, Golfbreaks_Employee_Id__c  FROM User WHERE Id=:userList.get(0).Id LIMIT 1];

        Lead lead = AP23_TestDataFactory.createLead(1)[0];
        lead.OwnerId = testUser.Id;
        database.insert(lead);
        
        test.startTest();
        System.assertEquals(true, String.isEmpty(WS01_RebarHTTPCallout.outboundMessageCreator(lead.Id, 'ENQUIRY') ));
        test.stopTest();
    }
    
    private static testMethod void testWS01_RebarHTTPCallout4() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride  = true;//2.2
        
        //create test data
        String salesUserProfile = ApplicationConstant.PROFILE_SALES_AGENT;
        List<User> userList = [SELECT Id FROM User WHERE Profile.Name = :salesUserProfile AND IsActive = true LIMIT 1];
        userList.get(0).Golfbreaks_Employee_Id__c = 1234;
        update userList;

        User testUser = [SELECT Id, Golfbreaks_Employee_Id__c  FROM User WHERE Id=:userList.get(0).Id LIMIT 1];

        Lead lead = AP23_TestDataFactory.createLead(1)[0];
        lead.OwnerId = testUser.Id;
        database.insert(lead);
        
        List<Account> accList = AP23_TestDataFactory.createPersonAccount(1);
        insert accList;

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        System.assertEquals(false, WS01_RebarHTTPCallout.emailBreakpointsInvite(accList[0].Id));
        test.stopTest();
    }

    private static testMethod void testWS01_RebarHTTPCallout5() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride  = true;//2.2
        
        //create test data
        String salesUserProfile = ApplicationConstant.PROFILE_SALES_AGENT;
        List<User> userList = [SELECT Id FROM User WHERE Profile.Name = :salesUserProfile AND IsActive = true LIMIT 1];
        userList.get(0).Golfbreaks_Employee_Id__c = 1234;
        update userList;

        User testUser = [SELECT Id, Golfbreaks_Employee_Id__c  FROM User WHERE Id=:userList.get(0).Id LIMIT 1];
        
        Account client = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert client;
        Opportunity oppForm = AP23_TestDataFactory.createOpportunity(1,ApplicationConstant.RECOMMENDATIONSTAGE, client)[0];
        oppForm.PreferredTravelDate__c = Date.today().addMonths(3);
        oppForm.Nights__c = 7;
        oppForm.TravelGroupSize__c = 4;
        insert oppForm;

        EnquiryClientRequestWrapper enqClientRequestWrapper = new EnquiryClientRequestWrapper();
        enqClientRequestWrapper.ClientAccountID = client.Id;
        enqClientRequestWrapper.Email = client.PersonEmail;
        enqClientRequestWrapper.FirstName = client.FirstName;
        enqClientRequestWrapper.LastName = client.LastName;
        enqClientRequestWrapper.Title = client.Salutation;
        enqClientRequestWrapper.Salutation = client.Salutation;
        enqClientRequestWrapper.NewsletterSignUp = client.NewsletterSignUp__c; //DO WE SEND THIS?
        enqClientRequestWrapper.Nights = oppForm.Nights__c;
        enqClientRequestWrapper.Phone = client.PersonMobilePhone;
        enqClientRequestWrapper.PreferredTravelDate = oppForm.PreferredTravelDate__c;
        enqClientRequestWrapper.TravelGroupSize = oppForm.TravelGroupSize__c;
        enqClientRequestWrapper.TripRegion = '1';
        enqClientRequestWrapper.VenueAccountIDs = new List<String>(); 


        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseRebar());
        System.assertEquals(true, WS01_RebarHTTPCallout.outboundMessageCallerOpportunity(oppForm,enqClientRequestWrapper).contains('200'));
        test.stopTest();
    }

    private static testMethod void testWS01_RebarHTTPCallout6() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride  = true;//2.2
        
        //create test data
        String salesUserProfile = ApplicationConstant.PROFILE_SALES_AGENT;
        List<User> userList = [SELECT Id FROM User WHERE Profile.Name = :salesUserProfile AND IsActive = true LIMIT 1];
        userList.get(0).Golfbreaks_Employee_Id__c = 1234;
        update userList;

        User testUser = [SELECT Id, Golfbreaks_Employee_Id__c  FROM User WHERE Id=:userList.get(0).Id LIMIT 1];

        Lead lead = AP23_TestDataFactory.createLead(1)[0];
        lead.OwnerId = testUser.Id;
        database.insert(lead);

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseRebar());

        Lead l = WS01_RebarHTTPCallout.outboundMessageCallerLead(String.valueOf(lead.Id));

        System.assertEquals(null, l.Clubhouse_Integration_Error__c);
        test.stopTest();
    }

    private static testMethod void testWS01_RebarHTTPCallout7() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride  = true;//2.2
        
        //create test data
        String salesUserProfile = ApplicationConstant.PROFILE_SALES_AGENT;
        List<User> userList = [SELECT Id FROM User WHERE Profile.Name = :salesUserProfile AND IsActive = true LIMIT 1];
        userList.get(0).Golfbreaks_Employee_Id__c = 1234;
        update userList;

        User testUser = [SELECT Id, Golfbreaks_Employee_Id__c  FROM User WHERE Id=:userList.get(0).Id LIMIT 1];

        Lead lead = AP23_TestDataFactory.createLead(1)[0];
        lead.OwnerId = testUser.Id;
        database.insert(lead);

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseRebar());

        WS01_RebarHTTPCallout.updateAccountManager(String.valueOf(lead.Id));

        test.stopTest();

        Lead checkLead = [select Id, Clubhouse_Integration_Error__c from Lead where Id = :lead.Id];
        System.assertEquals(null, checkLead.Clubhouse_Integration_Error__c);
    }

}