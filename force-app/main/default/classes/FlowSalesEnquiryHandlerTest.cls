/*
Name: FlowSalesEnquiryHandlerTest.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Test Suite for FlowSalesEnquiryHandler
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2020-03-27  Initial development.
*/
@isTest
public with sharing class FlowSalesEnquiryHandlerTest {

    //setEnqDefaultsScenario1 - validate the Name is constructed correctly for UK Business Unit
    //setEnqDefaultsScenario2 - validate the Name is constructed correctly for US Business Unit
    
    @TestSetup static void createTestData(){

        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
                
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings; 
        
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;

        //Create UK Business Unit
        Golfbreaks_Business_Unit__c gbu1 = new Golfbreaks_Business_Unit__c();
        gbu1.IsDefault__c = true;
        gbu1.Name = 'US BU';
        gbu1.LocaleSettings__c = 'en-us';
        insert gbu1;

        //Create US Business Unit
        Golfbreaks_Business_Unit__c gbu2 = new Golfbreaks_Business_Unit__c();
        gbu2.IsDefault__c = true;
        gbu2.Name = 'UK BU';
        gbu2.LocaleSettings__c = 'en-gb';
        insert gbu2;
        
        //Create Account
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert acc;

    }


    @isTest static void setEnqDefaultsScenario1(){

        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;

        Id buId = [Select Id From Golfbreaks_Business_Unit__c Where Name = 'UK BU' Limit 1].Id;
        
        //Create new Enquiry
        List<EnquiryManager.Enquiry> enquiries = new List<EnquiryManager.Enquiry>();
        EnquiryManager.Enquiry enq = new EnquiryManager.Enquiry();
        enq.clientDetails.firstName = 'Test';
        enq.clientDetails.lastName = 'Client';
        enq.propertyCache.put('ActionType.businessUnitId',buId);
        system.assertEquals(null, enq.recordName);
        enquiries.add(enq);
        
        test.startTest();
            FlowSalesEnquiryHandler handler = new FlowSalesEnquiryHandler();
            handler.processEnquiries(enquiries);
        test.stopTest();
        system.assertNotEquals(null, enquiries[0].recordName);
        system.assertEquals('Test Client - '+((DateTime)system.today()).format('dd/MM/YYYY'), enquiries[0].recordName);


    }

    
    @isTest static void setEnqDefaultsScenario2(){

        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;

        Id buId = [Select Id From Golfbreaks_Business_Unit__c Where Name = 'US BU' Limit 1].Id;
        
        //Create new Enquiry
        List<EnquiryManager.Enquiry> enquiries = new List<EnquiryManager.Enquiry>();
        EnquiryManager.Enquiry enq = new EnquiryManager.Enquiry();
        enq.clientDetails.firstName = 'Test';
        enq.clientDetails.lastName = 'Client';
        enq.propertyCache.put('ActionType.businessUnitId',buId);
        system.assertEquals(null, enq.recordName);
        enquiries.add(enq);
        
        test.startTest();
            FlowSalesEnquiryHandler handler = new FlowSalesEnquiryHandler();
            handler.processEnquiries(enquiries);
        test.stopTest();
        system.assertNotEquals(null, enquiries[0].recordName);
        system.assertEquals('Test Client - '+((DateTime)system.today()).format('MM/dd/YYYY'), enquiries[0].recordName);


    }
    

    //Test exception logging
    @isTest static void throwTestException(){
        SalesEnquiryHandler.throwError = true;//Trigger Runtime Exception
        List<EnquiryManager.Enquiry> enqList = new List<EnquiryManager.Enquiry>();
        EnquiryManager.Enquiry enq = new EnquiryManager.Enquiry();
        enqList.add(enq);
        system.assertEquals(0, [Select Id From Golfbreaks__PlatformLog__c].size());
        test.startTest();
        FlowSalesEnquiryHandler handler = new FlowSalesEnquiryHandler();
            Boolean isSuccess = handler.processEnquiries(enqList);
        test.stopTest();
        system.assertEquals(1, [Select Id From Golfbreaks__PlatformLog__c].size());
        system.assertEquals(false, isSuccess);
    }


}