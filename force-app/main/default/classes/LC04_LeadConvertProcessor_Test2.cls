/**
Name:  LC04_LeadConvertProcessor_Test2.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test Class for LC04_LeadConvertProcessor
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.1  J Radcliffe   2019-05-07   Set WIRE package flag to ensure valid routing config is returned in Test context
**/
@isTest
private class LC04_LeadConvertProcessor_Test2 {

    static Account acc = new Account();
    static List<Lead> lLead  = new List<Lead>();
    static List<Lead> lLeadHot  = new List<Lead>();
    static List<Lead> lLeadCold  = new List<Lead>();
    static List<Lead> lLeadWarm  = new List<Lead>();

    private static void setupTestData() {

                GBWire.RoutingConfigurationHelper.isTestConfigurationOverride  = true;//1.1

                OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
                insert orgSettings;
                
                List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());    
                insert validationList;
                
                acc = AP23_TestDataFactory.createAccountWithRecType(1, 'Client')[0];
                insert acc;

                
                Communication_Preference__c cp = new Communication_Preference__c(Communication_Type__c = 'Newsletter', Related_To__c = acc.Id);
                insert cp;
                
                lLead = AP23_TestDataFactory.createLead(5);
                insert lLead;

                lLeadHot = AP23_TestDataFactory.createLead(5, 'Hot');
                insert lLeadHot;

                lLeadCold = AP23_TestDataFactory.createLead(5, 'Cold');
                insert lLeadCold;

                lLeadWarm = AP23_TestDataFactory.createLead(5, 'Warm');
                insert lLeadWarm;

                List<Object_Field_Mapping__c> customSettings = AP23_TestDataFactory.getCustomSettingObjectFieldMapping();
                insert customSettings;
    }

    @isTest static void getLeadRecordTest() {
        
        		GBWire.RoutingConfigurationHelper.isTestConfigurationOverride  = true;//1.1
        
                System.debug('getLeadRecordTest');

                setupTestData();
                //List<Lead> lLead = [Select Id, Rating, OwnerId, Status, Account__c, NewsletterSignUp__c FROM Lead];
                Test.startTest();
                Lead testlead = LC04_LeadConvertProcessor.getLeadRecord(String.valueOf(lLead[0].Id));
                Test.stopTest(); 
                System.assertEquals(testlead.Id, lLead[0].Id);
            }

    @isTest static void convertLeadTest() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride  = true;//1.1
        
                System.debug('convertLeadTest');

                setupTestData();
                List<Lead> updateLead = new List<Lead>();
                List<Lead> lLeadtemp = [Select Id, Rating, OwnerId, Status, Account__c FROM Lead where Rating = ''];
                Id acctId = acc.Id;
                System.debug('>>>TEST_LEAD_SIZE' + lLeadtemp.size());
                for(Lead l: lLeadtemp){
                    l.GolfbreaksEnquiryId__c = '1231231231';
                    l.Account__c = acctId;
                    updateLead.add(l);
                }
                update updateLead;
                Test.startTest();
                    LC04_LeadConvertProcessor.convertLead(String.valueOf(lLead[0].Id), 'Test Opp');
                Test.stopTest();
                // Verify opp items got inserted 
                Integer i = [SELECT COUNT() FROM Opportunity];
                System.assertEquals(i, 1);
    }

    @isTest static void convertLeadTest1() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride  = true;//1.1
        
                System.debug('convertLeadTest1');
                setupTestData();
                List<Lead> updateLead = new List<Lead>();
                List<Lead> lLeadtemp = [Select Id, Rating, OwnerId, Status, Account__c FROM Lead where Rating = 'Warm'] ;
                Id acctId = acc.Id;
                System.debug('>>>TEST_LEAD_SIZE' + lLeadtemp.size());
                for(Lead l: lLeadtemp){
                    l.GolfbreaksEnquiryId__c = '1231231231';
                    l.Account__c = acctId;
                    updateLead.add(l);
                }
                update updateLead;
                Test.startTest();
                    LC04_LeadConvertProcessor.convertLead(String.valueOf(lLeadWarm[0].Id), 'Test Opp');
                Test.stopTest();

                // Verify opp items got inserted 
                Integer i = [SELECT COUNT() FROM Opportunity];
                System.assertEquals(i, 1);
    }

    @isTest static void convertLeadTest2() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride  = true;//1.1
        
                System.debug('convertLeadTest2');
                setupTestData();
                List<Lead> updateLead = new List<Lead>();
                List<Lead> lLeadtemp = [Select Id, Rating, OwnerId, Status, Account__c FROM Lead where Rating = 'Hot'] ;
                Id acctId = acc.Id;
                System.debug('>>>TEST_LEAD_SIZE' + lLeadtemp.size());
                for(Lead l: lLeadtemp){
                    l.GolfbreaksEnquiryId__c = '1231231231';
                    l.Account__c = acctId;
                    updateLead.add(l);
                }
                update updateLead;
                Test.startTest();
                    LC04_LeadConvertProcessor.convertLead(String.valueOf(lLeadHot[0].Id), 'Test Opp');
                Test.stopTest();

                // Verify opp items got inserted 
                Integer i = [SELECT COUNT() FROM Opportunity];
                System.assertEquals(i, 1);
    }

    @isTest static void convertLeadTest3() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride  = true;//1.1
        
                System.debug('convertLeadTest3');
                setupTestData();
                List<Lead> updateLead = new List<Lead>();
                List<Lead> lLeadtemp = [Select Id, Rating, OwnerId, Status, Account__c FROM Lead where Rating = 'Cold'] ;
                Id acctId = acc.Id;
                System.debug('>>>TEST_LEAD_SIZE' + lLeadtemp.size());
                for(Lead l: lLeadtemp){
                    l.GolfbreaksEnquiryId__c = '1231231231';
                    l.Account__c = acctId;
                    updateLead.add(l);
                }
                update updateLead;
                Test.startTest();
                    LC04_LeadConvertProcessor.convertLead(String.valueOf(lLeadCold[0].Id), 'Test Opp');
                Test.stopTest();

                // Verify opp items got inserted 
                Integer i = [SELECT COUNT() FROM Opportunity];
                System.assertEquals(i, 1);
    }

    @isTest static void convertLeadTest4() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride  = true;//1.1
        
                System.debug('convertLeadTest4');
                List<Lead> lLeadtemp = [Select Id, Rating, OwnerId, Status, Account__c FROM Lead];
                Test.startTest();
                Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
                //LC04_LeadConvertProcessor.convertLead(String.valueOf(lLeadtemp[0].Id), 'Test Opp');
                Test.stopTest();
                // Verify opp items got inserted -- none because webservice failure
                Integer i = [SELECT COUNT() FROM Opportunity];
                System.assertEquals(i, 0);   
    }
    



}