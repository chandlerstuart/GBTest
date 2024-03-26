/*
Name: AssistedOnlineBookingHandlerTest.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Test suite for AssistedOnlineBookingHandler.cls
======================================================
======================================================

Tests:

History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-05-28  Initial development.
*/
@isTest
public with sharing class AssistedOnlineBookingHandlerTest {

    @TestSetup static void createTestData(){
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
                
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings; 
        
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;

    }
    
    //Note - The AOB Handler leverages the same methods as the Sales Enquiry Handler (for now), which has it's own Test Suite.
    //This method simply runs the 'process enquiries' method for coverage purposes.
    @isTest static void runHandler(){
        List<EnquiryManager.Enquiry> enqList = new List<EnquiryManager.Enquiry>();
        EnquiryManager.Enquiry enq = new EnquiryManager.Enquiry();
        enqList.add(enq);
        test.startTest();
            AssistedOnlineBookingHandler handler = new AssistedOnlineBookingHandler();
            handler.processEnquiries(enqList);
        test.stopTest();
    }

    //Test exception logging
    @isTest static void throwTestException(){
        SalesEnquiryHandler.throwError = true;//Trigger Runtime Exception
        List<EnquiryManager.Enquiry> enqList = new List<EnquiryManager.Enquiry>();
        EnquiryManager.Enquiry enq = new EnquiryManager.Enquiry();
        enqList.add(enq);
        system.assertEquals(0, [Select Id From Golfbreaks__PlatformLog__c].size());
        test.startTest();
            AssistedOnlineBookingHandler handler = new AssistedOnlineBookingHandler();
            handler.processEnquiries(enqList);
        test.stopTest();
        system.assertEquals(1, [Select Id From Golfbreaks__PlatformLog__c].size());
    }

}