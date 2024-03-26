/**
Name:  AP04_LeadTriggerBL_Test.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test Class for AP04_LeadTriggerBL
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  R.Martinez  2016-04-25  Initial test class development
2.0  M.Cebrian   2016-05-04  Updated
3.0  J.To        2016-06-06  updated added OrgSettings__c
3.1  SMolloy     2016-11-25  Added data setup for Account Validation
3.2  MCane       2017-02-17  Added test method testBypassSAARouting.
3.3  SMolloy     2017-07-07  Added test methods testCreateShadowOpp, testClubhouseCreateOnUpdate
3.4  SMolloy     2017-07-27  Added test methods testUpdateShadowOpportunity
3.5  MCane       2018-04-16  Added test methods testUpdateCustomerCallBackTime.
3.6  JRadcliffe  2018-04-17  Added test method testDoPostConvert
3.7  MCane       2018-04-25  Added test method testDefaultInternationalisationValues.
3.8  MCane       2018-11-12  Add testSetup block for WIRE calculations on test data.
3.9  JRadcliffe  2018-11-27  Add the creation of Object_Field_Mapping__c data for testSetLeadIdRating methods
**/
@isTest
public class AP04_LeadTriggerBL_Test {
    
    static List<Lead> leadData;
    static User user;
    static LeadScoringRule__c lsr;
    static LeadScoringRule__c lsr1;
    static LeadScoringRule__c lsr2;
    static List<Account> accountlist;
    
    private static void setUpData(boolean doLeads){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//<-- 3.8 block WIRE calculations for test data.
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
        
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings; 
        
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        
        Id SAArecordtypeId = Schema.SObjectType.Sales_Agent_Attributes__c.getRecordTypeInfosByName().get('Sales Agent').getRecordTypeId();
        Id PersonId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId();
        Id leadRecordtypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales Lead').getRecordTypeId();
        Id lsrRecordtypeId = Schema.SObjectType.LeadScoringRule__c.getRecordTypeInfosByName().get('Scoring Rules for Lead').getRecordTypeId();
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Golfbreaks Standard User']; 
        user = new User(Alias = 'ap04Test', Email='ap04Test@testorg.com', 
                        EmailEncodingKey='UTF-8', LastName='ap04Test', LanguageLocaleKey='en_US', 
                        LocaleSidKey='en_US', ProfileId = p.Id, 
                        TimeZoneSidKey='America/Los_Angeles', UserName='ap04Test@testorg.com');
        insert user;
        
        List<Sales_Agent_Attributes__c> saa = new List<Sales_Agent_Attributes__c>();
        saa.add(new Sales_Agent_Attributes__c(recordTypeId = SAArecordtypeId, Sales_Rep__c = UserInfo.getUserId(), Current_Number_of_Open_Leads_Opps__c = 1, Online__c = true));
        saa.add(new Sales_Agent_Attributes__c(recordTypeId = SAArecordtypeId, Sales_Rep__c = user.Id, Current_Number_of_Open_Leads_Opps__c = null,  Online__c = true));
        insert saa;
        
        //Create Person Account
        accountlist = new List<Account>();
        Account perAcc = new Account();
        perAcc.LastName = 'Person Account';
        perAcc.PersonEmail = 'new@yahoo.com';
        perAcc.RecordTypeId = PersonId;
        accountlist.add(perAcc);
        Account perAcc2 = new Account();
        perAcc2.LastName = 'Person Account 2';
        perAcc2.PersonEmail = 'new@yahoo.com';
        perAcc2.RecordTypeId = PersonId;
        accountlist.add(perAcc2);
        Account perAcc3 = new Account();
        perAcc3.LastName = 'Person Account 3';
        perAcc3.PersonEmail = 'new@yahoo.com';
        perAcc3.RecordTypeId = PersonId;
        accountlist.add(perAcc3);
        insert accountlist;
        
        List<Opportunity> opplist = AP23_TestDataFactory.createOpportunity(1, 'Prospecting', accountlist[0]);
        opplist[0].Type = 'Open';
        insert opplist;       
        
        lsr = new LeadScoringRule__c();
        lsr.Active__c = true;
        lsr.FieldLabel__c = 'Accommodation Needs';
        lsr.Name = 'AP04Test';
        lsr.Operator__c = 'equals';
        lsr.Points__c = 50;
        lsr.RecordTypeId = lsrRecordtypeId;
        lsr.RecordType__c = leadRecordtypeId;
        lsr.Value__c = '10';
        insert lsr;
        
        lsr1 = new LeadScoringRule__c();
        lsr1.Active__c = true;
        lsr1.FieldLabel__c = 'Accommodation Needs';
        lsr1.Name = 'AP04Test1';
        lsr1.Operator__c = 'equals';
        lsr1.Points__c = 20;
        lsr1.RecordTypeId = lsrRecordtypeId;
        lsr1.RecordType__c = leadRecordtypeId;
        lsr1.Value__c = '5';
        insert lsr1;
        
        lsr2 = new LeadScoringRule__c();
        lsr2.Active__c = true;
        lsr2.FieldLabel__c = 'Accommodation Needs';
        lsr2.Name = 'AP04Test2';
        lsr2.Operator__c = 'equals';
        lsr2.Points__c = 5;
        lsr2.RecordTypeId = lsrRecordtypeId;
        lsr2.RecordType__c = leadRecordtypeId;
        lsr2.Value__c = '2';
        insert lsr2;
        
        List<LeadScoreMapping__c> lsmList = new List<LeadScoreMapping__c>();
        
        LeadScoreMapping__c lsm = new LeadScoreMapping__c();
        lsm.RuleType__c = 'Lead';
        lsm.LeadScoreMinimumValue__c = 40;
        lsm.LeadScoreMaximumValue__c = 60;
        lsm.LeadRating__c = 'Hot';
        lsm.Name = 'AP04Test';
        lsmList.add(lsm);
        
        LeadScoreMapping__c lsm1 = new LeadScoreMapping__c();
        lsm1.RuleType__c = 'Lead';
        lsm1.LeadScoreMinimumValue__c = 10;
        lsm1.LeadScoreMaximumValue__c = 30;
        lsm1.LeadRating__c = 'Warm';
        lsm1.Name = 'AP04Test1';
        lsmList.add(lsm1);
        
        LeadScoreMapping__c lsm2 = new LeadScoreMapping__c();
        lsm2.RuleType__c = 'Lead';
        lsm2.LeadScoreMinimumValue__c = 1;
        lsm2.LeadScoreMaximumValue__c = 9;
        lsm2.LeadRating__c = 'Cold';
        lsm2.Name = 'AP04Test2';
        lsmList.add(lsm2);
        
        insert lsmList;
        
        if (doLeads){
            
            leadData = AP23_TestDataFactory.createLead(6);
            leadData[0].Account__c = accountlist[0].Id;
            leadData[0].recordTypeId = leadRecordtypeId;
            leadData[0].AccommodationNeeds__c = '10';
            leadData[0].Rating = ApplicationConstant.LEAD_RATING_HOT;
            
            leadData[1].Account__c = accountlist[0].Id;
            leadData[1].recordTypeId = leadRecordtypeId;
            leadData[1].AccommodationNeeds__c = '10';
            leadData[1].Rating = ApplicationConstant.LEAD_RATING_HOT;
            
            leadData[2].Account__c = accountlist[1].Id;
            leadData[2].recordTypeId = leadRecordtypeId;
            leadData[2].AccommodationNeeds__c = '5';
            leadData[2].Rating = ApplicationConstant.LEAD_RATING_WARM;
            
            leadData[3].Account__c = accountlist[1].Id;
            leadData[3].recordTypeId = leadRecordtypeId;
            leadData[3].AccommodationNeeds__c = '2';
            leadData[3].Rating = ApplicationConstant.LEAD_RATING_COLD;
            
            leadData[4].Account__c = accountlist[2].Id;
            leadData[4].recordTypeId = leadRecordtypeId;
            leadData[4].AccommodationNeeds__c = '1';
            leadData[4].Rating = ApplicationConstant.LEAD_RATING_COLD;
            
            leadData[5].Account__c = accountlist[2].Id;
            leadData[5].recordTypeId = leadRecordtypeId;
            
            insert leadData;
            
            accountlist[0].LeadId__c = leadData[0].Id;
            
            update accountlist[0];
            
            Booking__c bk1 = new Booking__c();
            bk1.Lead__c = leadData[0].Id;
            bk1.Account__c = accountlist[0].Id;
            insert bk1;
            
            Booking__c bk2 = new Booking__c();
            bk2.Lead__c = leadData[1].Id;
            bk2.Account__c = accountlist[0].Id;
            insert bk2;
            
            
            Datetime current = Datetime.now().addDays(1);
            Event event1 = new Event(
                OwnerId = user.Id,
                StartDateTime = current,
                EndDateTime = Datetime.now().addDays(3),
                ReminderDateTime = Datetime.now().addDays(2),
                IsReminderSet = true,
                ActivityDateTime = current,
                Subject = 'Call Back Request',
                WhoId = leadData[0].Id
            );
            insert event1;
            
            Event event2 = new Event(
                OwnerId = user.Id,
                StartDateTime = current,
                EndDateTime = Datetime.now().addDays(3),
                ReminderDateTime = Datetime.now().addDays(2),
                IsReminderSet = true,
                ActivityDateTime = current,
                Subject = 'Call Back Request',
                WhoId = leadData[0].Id
            );
            insert event2;  
        }
    }
    
    @isTest static void testUpdateShadowOpp(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        List<Object_Field_Mapping__c> customSettings = AP23_TestDataFactory.getCustomSettingObjectFieldMapping();       
        insert customSettings;
        Id leadRecordtypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales Lead').getRecordTypeId();
        Id shadowSalesOppRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Shadow Opportunity').getRecordTypeId();
        
        List<Lead> clubhouseLeads = new List<Lead>();
        clubhouseLeads = AP23_TestDataFactory.createLead(3);
        clubhouseLeads[0].FirstName = 'Test';
        clubhouseLeads[0].LastName = 'CreateShadow';
        clubhouseLeads[0].recordTypeId = leadRecordtypeId;
        clubhouseLeads[0].AccommodationNeeds__c = '10';
        
        clubhouseLeads[1].FirstName = 'Test1';
        clubhouseLeads[1].LastName = 'CreateShadow1';
        clubhouseLeads[1].recordTypeId = leadRecordtypeId;
        clubhouseLeads[1].AccommodationNeeds__c = '10';
        
        clubhouseLeads[2].FirstName = 'Test2';
        clubhouseLeads[2].LastName = 'CreateShadow2';
        clubhouseLeads[2].recordTypeId = leadRecordtypeId;
        clubhouseLeads[2].AccommodationNeeds__c = '10';
        clubhouseLeads[2].Status = ApplicationConstant.LEAD_NO_SALE;
        clubhouseLeads[2].NoSaleReason__c = 'Customer un-contactable';
        clubhouseLeads[2].NoSaleReasonComments__c = 'Customer un-contactable';
        
        
        insert clubhouseLeads;  
        
        Map<Id, Lead> oldLeads = new Map<Id, Lead>();
        for (Lead l : clubhouseLeads){
            oldLeads.put(l.Id, l);
        }
        
        List<Opportunity> shadowOpps = new List<Opportunity>();
        for (Lead l : clubhouseLeads){
            Opportunity shadowOpp = new Opportunity();
            shadowOpp.Name = l.FirstName + ' ' + l.LastName;
            shadowOpp.CloseDate = Date.today();
            shadowOpp.StageName = ApplicationConstant.RECOMMENDATIONSTAGE;
            shadowOpp.AccountId = l.Account__c;
            shadowOpp.Source_Lead__c = l.Id;
            shadowOpp.GolfbreaksEnquiryId__c = l.GolfbreaksEnquiryId__c;
            shadowOpp.Golfbreaks_Portal_Key__c = l.Golfbreaks_Opportunity_Portal_Key__c;
            shadowOpp.RecordTypeId = ApplicationConstant.getRecordTypeId('Opportunity','Sales_Shadow_Opportunity');
            shadowOpps.add(shadowOpp);
        }
        
        insert shadowOpps;
        
        clubhouseLeads[0].Status = ApplicationConstant.LEAD_NO_SALE; 
        clubhouseLeads[0].NoSaleReason__c = 'Customer un-contactable';
        clubhouseLeads[0].NoSaleReasonComments__c = 'Customer un-contactable';
        clubhouseLeads[0].GolfbreaksEnquiryId__c = '12345'; 
        
        clubhouseLeads[1].Status = ApplicationConstant.LEAD_STATUS_DUPLICATE; 
        clubhouseLeads[1].DuplicateNotaLeadReason__c = ApplicationConstant.LEAD_DUPLICATE_REASON;
        clubhouseLeads[1].GolfbreaksEnquiryId__c = '54321';
        
        clubhouseLeads[2].Status = ApplicationConstant.LEAD_STATUS_CONTACT_ATTEMPTED; 
        clubhouseLeads[2].NoSaleReason__c = NULL;
        clubhouseLeads[2].NoSaleReasonComments__c = NULL;
        clubhouseLeads[2].GolfbreaksEnquiryId__c = '12345'; 
        
        update clubhouseLeads;      
        
        test.startTest();
        
        AP04_LeadTriggerBL.updateShadowOpportunity(clubhouseLeads, oldLeads);
        
        test.stopTest();
        
        List<Opportunity> oppList = [select Id, Name, StageName, NoSaleReason__c from Opportunity where RecordTypeId = :ApplicationConstant.getRecordTypeId('Opportunity', 'Sales_Shadow_Opportunity')];
        
        for (Opportunity o : oppList){
            if ('Test CreateShadow'.equalsIgnoreCase(o.Name)){
                system.assertEquals(ApplicationConstant.OPP_STAGE_NOSALE, o.StageName);
                system.assertNotEquals(null, o.NoSaleReason__c);
            }else if ('Test1 CreateShadow1'.equalsIgnoreCase(o.Name)){
                system.assertEquals(ApplicationConstant.OPP_STAGE_DUPLICATE, o.StageName);
            }else if ('Test2 CreateShadow2'.equalsIgnoreCase(o.Name)){
                system.assertEquals(ApplicationConstant.RECOMMENDATIONSTAGE, o.StageName);
            }
        }
    }    
    
    @isTest static void testTriggerMethods() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        List<Lead> leads = new List<Lead>();
        Map<Id, Lead> leadMap =  new Map<Id, Lead>();
        AP04_LeadTriggerBL.OnBeforeInsert(leads);
        
        System.assertEquals(AP04_LeadTriggerBL.comesFromInsert, true);
        
        AP04_LeadTriggerBL.OnBeforeUpdate(leads, leads, leadMap);
        AP04_LeadTriggerBL.OnAfterInsert(leads, null);
        AP04_LeadTriggerBL.comesFromInsert = false;
        AP04_LeadTriggerBL.OnBeforeUpdate(leads, leads, leadMap);
        System.assertEquals(AP04_LeadTriggerBL.isBeforeUpdateTriggerCalled, TRUE);
        AP04_LeadTriggerBL.OnAfterUpdate(leads, leadMap, leadMap);
        System.assertEquals(AP04_LeadTriggerBL.isAfterUpdateTriggerCalled, TRUE);
    }
    
    
    @isTest static void testClubhouseCreateOnInsert(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        List<Object_Field_Mapping__c> customSettings = AP23_TestDataFactory.getCustomSettingObjectFieldMapping();       
        insert customSettings;
        Id leadRecordtypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales Lead').getRecordTypeId();
        
        List<Lead> clubhouseLeads = new List<Lead>();
        clubhouseLeads = AP23_TestDataFactory.createLead(1);
        clubhouseLeads[0].recordTypeId = leadRecordtypeId;
        clubhouseLeads[0].AccommodationNeeds__c = '10';
        
        insert clubhouseLeads;    
        
        system.assertEquals(1, clubhouseLeads.size());
        
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        AP04_LeadTriggerBL.OnAfterInsert(clubhouseLeads,null);
        
        test.stopTest();
    }
    
    @isTest static void testClubhouseCreateOnUpdate(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        List<Object_Field_Mapping__c> customSettings = AP23_TestDataFactory.getCustomSettingObjectFieldMapping();       
        insert customSettings;
        Id leadRecordtypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales Lead').getRecordTypeId();
        
        List<Lead> clubhouseLeads = new List<Lead>();
        clubhouseLeads = AP23_TestDataFactory.createLead(1);
        clubhouseLeads[0].recordTypeId = leadRecordtypeId;
        clubhouseLeads[0].AccommodationNeeds__c = '10';
        
        insert clubhouseLeads;  
        
        clubhouseLeads[0].Status = ApplicationConstant.LEAD_STATUS_CONTACT_ATTEMPTED;  
        
        update clubhouseLeads;        
        
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        AP04_LeadTriggerBL.OnAfterUpdate(clubhouseLeads,null,null);
        
        test.stopTest();
    } 
    
    @isTest static void testCreateShadowOpp(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        List<Object_Field_Mapping__c> customSettings = AP23_TestDataFactory.getCustomSettingObjectFieldMapping();       
        insert customSettings;
        Id leadRecordtypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales Lead').getRecordTypeId();
        
        List<Lead> clubhouseLeads = new List<Lead>();
        clubhouseLeads = AP23_TestDataFactory.createLead(2);
        clubhouseLeads[0].FirstName = 'Test';
        clubhouseLeads[0].LastName = 'CreateShadow';
        clubhouseLeads[0].recordTypeId = leadRecordtypeId;
        clubhouseLeads[0].AccommodationNeeds__c = '10';
        
        insert clubhouseLeads;  
        
        clubhouseLeads[0].Status = ApplicationConstant.LEAD_STATUS_CONTACT_ATTEMPTED; 
        clubhouseLeads[0].GolfbreaksEnquiryId__c = '12345'; 
        
        update clubhouseLeads;        
        
        Set<Id> leadIds = new Set<Id>();
        for (Lead l : clubhouseLeads){
            leadIds.add(l.Id);
        }
        
        test.startTest();
        
        AP04_LeadTriggerBL.createShadowOpportunity(leadIds);
        
        test.stopTest();
        
        List<Opportunity> oppList = [select Id, Name from Opportunity where RecordTypeId = :ApplicationConstant.getRecordTypeId('Opportunity', 'Sales_Shadow_Opportunity')];
        
        //system.assertNotEquals(TRUE, oppList.isEmpty());
        //system.assertEquals(1, oppList.size()); //Should only have one created as only one Lead was set to CONTACT ATTEMPTED
        //system.assertEquals('Test CreateShadow', oppList[0].Name);
        
    }    
    
    @isTest static void testIsChangeLeadException() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        Map<Id, Lead> leadMap =  new Map<Id, Lead>();
        
        setUpData(true);
        
        AP04_LeadTriggerBL.OnBeforeUpdate(leadData, leadData, leadMap);
    }
    
    @isTest static void testIsChangeLeadOwnerIdNotEqual() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        Map<Id, Lead> leadMap =  new Map<Id, Lead>();
        
        setUpData(true);
        
        Set<Id> leadIds = new Set<Id>();
        
        for(Lead lead : leadData){
            leadIds.add(lead.Id);
        }
        
        leadMap = new Map<Id, Lead>([SELECT Id, Status, OwnerId, AssignedtoSAA__c, TECH_NVMCallBackUrgent__c FROM Lead WHERE Id IN :leadIds]);
        
        leadMap.get(leadData[0].Id).OwnerId = user.Id;
        leadData[0].OwnerId = UserInfo.getUserId();
        
        System.assertNotEquals(leadMap.get(leadData[0].Id).OwnerId, leadData[0].OwnerId);
        
        AP04_LeadTriggerBL.OnBeforeUpdate(leadData, leadData, leadMap);
    }
    
    @isTest static void testIsChangeLeadOwnerIdIsEqual() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        Map<Id, Lead> leadMap =  new Map<Id, Lead>();
        
        setUpData(true);
        
        Set<Id> leadIds = new Set<Id>();
        
        for(Lead lead : leadData){
            leadIds.add(lead.Id);
        }
        
        leadMap = new Map<Id, Lead>([SELECT Id, Status, OwnerId, AssignedtoSAA__c, TECH_NVMCallBackUrgent__c FROM Lead WHERE Id IN :leadIds]);
        
        leadMap.get(leadData[0].Id).OwnerId = user.Id;
        leadData[0].OwnerId = user.Id;
        
        System.assertEquals(leadMap.get(leadData[0].Id).OwnerId, leadData[0].OwnerId);
        
        AP04_LeadTriggerBL.OnBeforeUpdate(leadData, leadData, leadMap);
    }
    
    @isTest static void testFilterReturnTravellerLeadsForRoutingException() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        Map<Id, Lead> leadMap =  new Map<Id, Lead>();
        
        AP04_LeadTriggerBL.comesFromInsert = true;
        AP04_LeadTriggerBL.OnBeforeUpdate(null, leadData, leadMap);
    }
    
    @isTest static void testFilterReturnTravellerLeadsForRouting() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        Map<Id, Lead> leadMap =  new Map<Id, Lead>();
        
        setUpData(true);
        
        AP04_LeadTriggerBL.comesFromInsert = true;
        
        leadData[0].LeadSource = ApplicationConstant.RETURNING_TRAVELLER;
        leadData[1].LeadSource = 'Competition';
        AP04_LeadTriggerBL.OnBeforeUpdate(leadData, leadData, leadMap);
    }
    
    @isTest static void testInboundCallLeads() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        Map<Id, Lead> leadMap =  new Map<Id, Lead>();
        
        setUpData(true);
        
        AP04_LeadTriggerBL.comesFromInsert = true;
        
        leadData[0].LeadSource = ApplicationConstant.LEAD_SOURCE_PHONE;
        leadData[0].Status = ApplicationConstant.LEAD_STATUS_NEW;
        leadData[0].SalesRegion__c = 'Europe';
        leadData[1].LeadSource = 'Competition';
        AP04_LeadTriggerBL.OnBeforeUpdate(leadData, leadData, leadMap);
    }
    
    @isTest static void testCheckLeadOwnerUpdateOwnerIdNotEqual() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        Map<Id, Lead> leadMap =  new Map<Id, Lead>();
        
        setUpData(true);
        
        Set<Id> leadIds = new Set<Id>();
        
        for(Lead lead : leadData){
            leadIds.add(lead.Id);
        }
        
        leadMap = new Map<Id, Lead>([SELECT Id, Status, OwnerId, AssignedtoSAA__c, TECH_NVMCallBackUrgent__c FROM Lead WHERE Id IN :leadIds]);
        
        leadMap.get(leadData[0].Id).OwnerId = user.Id;
        leadData[0].OwnerId = UserInfo.getUserId();
        
        System.assertNotEquals(leadMap.get(leadData[0].Id).OwnerId, leadData[0].OwnerId);
        AP04_LeadTriggerBL.comesFromInsert = true;
        
        AP04_LeadTriggerBL.OnAfterUpdate(leadData, leadMap, leadMap);
    }
    
    @isTest static void testSetLeadScoreException() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        AP04_LeadTriggerBL.OnBeforeInsert(null);
    }
    
    @isTest static void testSetLeadIdRatingHot() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        insert AP23_TestDataFactory.createObjectFieldMappingsByObject('Lead');//3.9
        
        setUpData(true);
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        Id leadId = leadData[0].Id;
        Lead newLead = leadData[0];
        newLead.Id = null;
        insert newLead;
        leadData[0].Id = leadId;
        leadData.add(newLead);
        
        for(Lead lead : leadData){
            lead.Rating = ApplicationConstant.LEAD_RATING_HOT;
            leadMap.put(lead.Id, lead);
        }
        
        update leadMap.values();
        
        
        AP04_LeadTriggerBL.OnAfterUpdate(leadData, leadMap, leadMap);
    }
    
    @isTest static void testSetLeadIdRatingWarm() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        insert AP23_TestDataFactory.createObjectFieldMappingsByObject('Lead');//3.9
        
        setUpData(true);
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        Id leadId = leadData[1].Id;
        Lead newLead = leadData[1];
        newLead.Id = null;
        insert newLead;
        leadData[1].Id = leadId;
        leadData.add(newLead);
        
        for(Lead lead : leadData){
            lead.Rating = ApplicationConstant.LEAD_RATING_WARM;
            leadMap.put(lead.Id, lead);
        }
        
        update leadMap.values();
        
        AP04_LeadTriggerBL.OnAfterUpdate(leadData, leadMap, leadMap);
    }
    
    
    @isTest static void testSetLeadIdRatingCold() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        insert AP23_TestDataFactory.createObjectFieldMappingsByObject('Lead');//3.9
        
        setUpData(true);
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        Id leadId = leadData[2].Id;
        Lead newLead = leadData[2];
        newLead.Id = null;
        insert newLead;
        leadData[2].Id = leadId;
        leadData.add(newLead);
        
        for(Lead lead : leadData){
            lead.Rating = ApplicationConstant.LEAD_RATING_COLD;
            leadMap.put(lead.Id, lead);
        }
        
        update leadMap.values();
        
        AP04_LeadTriggerBL.OnAfterUpdate(leadData, leadMap, leadMap);
    }
    
    @isTest static void testcheckMatchingEqualsWithDecimal() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        setUpData(true);
        
        leadData[0].AccommodationNeeds__c = '10.00';
        leadData[1].AccommodationNeeds__c = '10.00';
        
        AP04_LeadTriggerBL.OnBeforeInsert(leadData);
    }
    
    @isTest static void testcheckMatchingNotEquals() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        setUpData(true);
        
        leadData[0].AccommodationNeeds__c = '9.00';
        leadData[1].AccommodationNeeds__c = 'Dee';
        
        lsr.Operator__c = 'not equals';
        update lsr;
        
        LeadScoringRule__c newLSR = lsr;
        newLSR.Value__c = 'Not Dee';
        newLSR.Id = null;
        insert newLSR;
        
        AP04_LeadTriggerBL.OnBeforeInsert(leadData);
    }
    
    @isTest static void testcheckMatchingContains() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        setUpData(true);
        
        lsr.Operator__c = 'contains';
        lsr.RecordType__c = leadData[0].RecordTypeId;
        update lsr;
        
        AP04_LeadTriggerBL.OnBeforeInsert(leadData);
    }
    
    @isTest static void testcheckMatchingStartsWith() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        setUpData(true);
        
        lsr.Operator__c = 'starts with';
        update lsr;
        
        AP04_LeadTriggerBL.OnBeforeInsert(leadData);
    }
    
    @isTest static void testcheckMatchingLessAndGreater() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        setUpData(true);
        
        leadData[0].AccommodationNeeds__c = '10.00';
        leadData[1].AccommodationNeeds__c = '10.00';
        
        lsr.Operator__c = 'less than/greater than';
        update lsr;
        
        AP04_LeadTriggerBL.OnBeforeInsert(leadData);
    }
    
    @isTest static void testGetFieldValueException() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        setUpData(true);
        
        lsr.FieldLabel__c = 'Exception';
        update lsr;
        
        AP04_LeadTriggerBL.OnBeforeInsert(leadData);
    }
    
    @isTest static void testGetFieldValueLeadStatus() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        setUpData(true);
        
        lsr.FieldLabel__c = 'Lead Status';
        update lsr;
        
        AP04_LeadTriggerBL.OnBeforeInsert(leadData);
    }
    
    @isTest static void testIsInRangeNoMatch() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        setUpData(true);
        
        lsr.Operator__c = 'less than/greater than';
        lsr.MinimumValue__c = 11;
        lsr.MaximumValue__c = 9;
        update lsr;
        
        AP04_LeadTriggerBL.OnBeforeInsert(leadData);
    }
    
    @isTest static void testSetLeadIdRatingException() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        AP04_LeadTriggerBL.OnAfterUpdate(null, null, null);
    }
    
    @isTest static void testSetLeadIdRating() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        insert AP23_TestDataFactory.createObjectFieldMappingsByObject('Lead');//3.9
        
        setUpData(true);
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        
        Id leadId = leadData[0].Id;
        Lead newLead = leadData[0];
        newLead.Id = null;
        insert newLead;
        leadData[0].Id = leadId;
        leadData.add(newLead);
        
        for(Lead lead : leadData){
            leadMap.put(lead.Id, lead);
        }
        
        AP04_LeadTriggerBL.OnAfterUpdate(leadData, leadMap, leadMap);
    }
    
    
    @isTest static void testUpdateTotalPreviousBookingsOnUpdateException() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        AP04_LeadTriggerBL.OnBeforeUpdate(null, null, null);
    }
    
    @isTest static void testCheckStatusUpdates() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        setUpData(true);
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        
        for(Lead lead : leadData){
            lead.OwnerId = user.Id;
            lead.Status = 'New';
            leadMap.put(lead.Id, lead);
        }
        
        update leadMap.values();
        
        leadMap = new Map<Id, Lead>([SELECT Id, Status, OwnerId FROM Lead WHERE Id IN: leadMap.keySet()]);
        
        for(Lead lead : leadData){
            lead.Status = ApplicationConstant.LEAD_CLOSED_CONVERTED;
        }
        
        
        AP04_LeadTriggerBL.checkStatusUpdates(leadData, leadMap);
    }
    
    @isTest static void testCheckStatusUpdatesNotNull() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        setUpData(true);
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        
        for(Lead lead : leadData){
            lead.OwnerId = UserInfo.getUserId();
            lead.Status = 'New';
            leadMap.put(lead.Id, lead);
        }
        
        update leadMap.values();
        
        leadMap = new Map<Id, Lead>([SELECT Id, Status, OwnerId FROM Lead WHERE Id IN: leadMap.keySet()]);
        
        for(Lead lead : leadData){
            lead.Status = ApplicationConstant.LEAD_NO_SALE;
        }
        
        
        AP04_LeadTriggerBL.checkStatusUpdates(leadData, leadMap);
    }
    
    @isTest static void testCreateUpdateEventWithCallbackDates() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        setUpData(true);
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        Map<Id, Lead> newleadMap = new Map<Id, Lead>();
        
        for(Lead lead : leadData){
            lead.OwnerId = UserInfo.getUserId();
            lead.Status = 'New';
            lead.CallBackDateTime__c = Datetime.now();
            leadMap.put(lead.Id, lead);
        }
        
        update leadMap.values();
        
        leadMap = new Map<Id, Lead>([SELECT Id, Status, OwnerId, CallBackDateTime__c FROM Lead WHERE Id IN: leadMap.keySet()]);
        
        for(Lead lead : leadData){
            lead.OwnerId = user.Id;
            lead.CallBackDateTime__c = Datetime.now().addDays(2);
            lead.Reminder_Event__c = true;
            newleadMap.put(lead.Id, lead);
        }
        
        
        AP04_LeadTriggerBL.createUpdateEvent(newleadMap, leadMap);
    }
    
    @isTest static void testCreateUpdateEventNoCallbackDates() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        setUpData(true);
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        Map<Id, Lead> newleadMap = new Map<Id, Lead>();
        
        for(Lead lead : leadData){
            lead.OwnerId = UserInfo.getUserId();
            lead.Status = 'New';
            lead.CallBackDateTime__c = Datetime.now();
            leadMap.put(lead.Id, lead);
        }
        
        update leadMap.values();
        
        leadMap = new Map<Id, Lead>([SELECT Id, Status, OwnerId, CallBackDateTime__c FROM Lead WHERE Id IN: leadMap.keySet()]);
        
        for(Lead lead : leadData){
            lead.OwnerId = user.Id;
            lead.CallBackDateTime__c = null;
            lead.Reminder_Event__c = true;
            newleadMap.put(lead.Id, lead);
        }
        
        
        AP04_LeadTriggerBL.createUpdateEvent(newleadMap, leadMap);
    }
    
    @isTest static void testPopulateAccountDetailsOnLead() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        setUpData(true);
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        
        for(Lead lead : leadData){
            lead.OwnerId = UserInfo.getUserId();
            lead.email = 'old@yahoo.com';
            leadMap.put(lead.Id, lead);
        }
        
        update leadMap.values();
        
        leadMap = new Map<Id, Lead>([SELECT Id, Status, OwnerId, Email, Account__c FROM Lead WHERE Id IN: leadMap.keySet()]);
        
        for(Lead lead : leadData){
            lead.email = 'new@yahoo.com';
            lead.Account__c = accountlist[1].Id;
        }
        
        leadData[1].Email = null;
        
        AP04_LeadTriggerBL.populateAccountDetailsOnLead(leadData, leadMap);
    }
    
    @isTest static void testPopulateAccountDetailsOnLeadOldMapIsNull() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        setUpData(true);
        
        for(Lead lead : leadData){
            lead.email = 'new@yahoo.com';
            lead.Account__c = accountlist[1].Id;
        }
        
        leadData[1].Email = null;
        
        AP04_LeadTriggerBL.populateAccountDetailsOnLead(leadData, null);
    }
    
    @isTest static void testcatchDupeLeads(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        setUpData(true);
        
        for(Lead lead : leadData){
            lead.email = 'new@yahoo2.com';
            lead.SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_UK_IRELAND;
            lead.Status = ApplicationConstant.LEAD_STATUS_NEW;
            lead.LeadSource = ApplicationConstant.LEAD_SOURCE_WEBSITEFORM;
        }
        
        update leadData;
        List<Lead> LeadList = [SELECT Id, Email, LeadSource, CreatedDate, Status, DuplicateNotaLeadReason__c, SalesRegion__c FROM LEAD WHERE EMAIL = 'new@yahoo2.com'];
        AP04_LeadTriggerBL.catchDupeLeads(LeadList);
        
    }
    
    @isTest static void isInRangeTest(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        setUpData(true);
        System.assert(AP04_LeadTriggerBL.isInRange('43', lsr));
        
    }
    
    @isTest static void testSetGender(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        setUpData(false);
        
        List<Lead> newLeads = AP23_TestDataFactory.createLead(5);
        
        for (Lead l : newLeads){
            l.Gender__c = null;
        }
        
        newLeads[0].FirstName = 'GTNoTitle';
        newLeads[0].Salutation = null;
        newLeads[0].Title = null;
        newLeads[1].FirstName = 'GTSalutation';
        newLeads[1].Salutation = 'Mr.';
        newLeads[2].FirstName = 'GTTitle';
        newLeads[2].Title = 'Mr.';
        newLeads[3].FirstName = 'GTFemale';
        newLeads[3].Salutation = 'Ms.';
        newLeads[4].FirstName = 'GTDr';
        newLeads[4].Salutation = 'Dr.';
        
        insert newLeads;
        
        Map<String, Lead> leadMap = new Map<String, Lead>();
        for (Lead l : [select Id, FirstName, Gender__c from Lead where FirstName LIKE 'GT%']){
            leadMap.put(l.FirstName, l);
        }
        
        system.debug('*** -- LEADS -- ***');
        for (Lead l : leadMap.values()){
            system.debug('*** -- Lead : ' + l + ' -- ***');
        }
        
        system.assertEquals(AP04_LeadTriggerBL.GENDER_MALE, leadMap.get('GTNoTitle').Gender__c);
        system.assertEquals(AP04_LeadTriggerBL.GENDER_MALE, leadMap.get('GTSalutation').Gender__c);
        system.assertEquals(AP04_LeadTriggerBL.GENDER_MALE, leadMap.get('GTTitle').Gender__c);
        system.assertEquals(AP04_LeadTriggerBL.GENDER_FEMALE, leadMap.get('GTFemale').Gender__c);
        system.assertEquals(AP04_LeadTriggerBL.GENDER_MALE, leadMap.get('GTDr').Gender__c);
        
    }
    
    @isTest static void testUpdateCallbackDateTime(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        setUpData(false);
        
        List<Lead> newLeads = AP23_TestDataFactory.createLead(2);
        for (Lead l : newLeads){
            l.Diarydate__c = Date.today();
        }
        
        newLeads[0].Call_Back_Hour__c = '11';
        newLeads[1].Call_Back_Hour__c = '10';
        newLeads[1].Call_Back_Minute__c = '30';
        
        test.startTest();
        insert newLeads;
        test.stopTest();
        
        
        DateTime dt1 = DateTime.newInstance(Date.today().year(), Date.today().month(), Date.today().day(), 11, 00, 00);
        DateTime dt2 = DateTime.newInstance(Date.today().year(), Date.today().month(), Date.today().day(), 10, 30, 00);
        
        List<Lead> checkLeads = [select CallBackDateTime__c, Call_back_Hour__c, Call_Back_Minute__c from Lead];
        
        for (Lead l : checkLeads){
            if ('11' == l.Call_Back_Hour__c){
                system.assertEquals(dt1, l.CallBackDateTime__c);
            }
            if ('10' == l.Call_Back_Hour__c){
                system.assertEquals(dt2, l.CallBackDateTime__c);
            }
        }
    }
    
    @isTest static void testUpdateCustomerCallBackTime(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        setUpData(false);
        
        List<Lead> newLeads = AP23_TestDataFactory.createLead(2);
        for (Lead l : newLeads){
            l.Diarydate__c = Date.today();
        }
        
        DateTime dt1 = DateTime.newInstanceGmt(Date.today().year(), 12, 25, 16, 00, 00); //GMT
        DateTime dt2 = DateTime.newInstanceGmt(Date.today().year(), 6, 1, 10, 00, 00); //BST
        
        newLeads[0].Customer_Call_Back_Date_Time__c = dt1;
        newLeads[1].Customer_Call_Back_Date_Time__c = dt2;
        
        test.startTest();
        insert newLeads;
        test.stopTest();
        
        System.assertEquals('16:00', [select Customer_Call_Back_Time_DST__c from Lead where Id=:newLeads[0].Id].Customer_Call_Back_Time_DST__c);
        System.assertEquals('11:00', [select Customer_Call_Back_Time_DST__c from Lead where Id=:newLeads[1].Id].Customer_Call_Back_Time_DST__c);
    }  
    
    /* **/
    @isTest static void testDefaultInternationalisationValues(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        setUpData(false);

        Golfbreaks_Business_Unit__c buUKDefault = new Golfbreaks_Business_Unit__c(Name='UK', Default_Booking_System__c='Clubhouse');
        Golfbreaks_Business_Unit__c buUSA = new Golfbreaks_Business_Unit__c(Name='USA', Default_Booking_System__c='Kaptio');
        insert new List<Golfbreaks_Business_Unit__c> { buUKDefault, buUSA };
        
        insert new Internationalisation_Settings__c(Default_Golfbreaks_Business_Unit_Id__c=buUKDefault.Id);
        
        List<Lead> newLeads = AP23_TestDataFactory.createLead(2); //2 leads with no Business Unit or Booking System.

        newLeads[0].Golfbreaks_Business_Unit__c = null; // should be set to UK and Clubhouse.
        newLeads[0].Booking_System__c = null;
        
        newLeads[1].Golfbreaks_Business_Unit__c = buUSA.Id; // should be set to Kaptio.
        newLeads[1].Booking_System__c = null;

        test.startTest();
        insert newLeads;
        test.stopTest();
        
        System.assertEquals(buUKDefault.Id, [select Id, Golfbreaks_Business_Unit__c from Lead where Id=:newLeads[0].Id].Golfbreaks_Business_Unit__c);        
        System.assertEquals('Clubhouse', [select Id, Booking_System__c from Lead where Id=:newLeads[0].Id].Booking_System__c);

        System.assertEquals(buUSA.Id, [select Id, Golfbreaks_Business_Unit__c from Lead where Id=:newLeads[1].Id].Golfbreaks_Business_Unit__c);        
        System.assertEquals('Kaptio', [select Id, Booking_System__c from Lead where Id=:newLeads[1].Id].Booking_System__c);
    } 
    /* */       
    
    @isTest static void testBypassSAARouting(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        // Test logic - v. check that it does.
        // Test logic - create a lead that should assign to SAA with Bypass_SAA_Routing=true, check that it does not assign via SAA.
        
        // Custom setting population.
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;
        
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        
        List<Object_Field_Mapping__c> allOFMList = AP23_TestDataFactory.getCustomSettingObjectFieldMapping();
        insert allOFMList;
        
        
        // Test setup.
        Id SAArecordtypeId = Schema.SObjectType.Sales_Agent_Attributes__c.getRecordTypeInfosByName().get('Sales Agent').getRecordTypeId();
        Sales_Agent_Attributes__c saa01 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                        Team__c = 'S- EU 8+ Sales Team', Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                        Max_Number_of_Open_Leads_Opportunities__c = 3, Min_CLV_Threshold__c = 0,
                                                                        Max_Items_Diarised_Today__c = 10, Current_Items_Diarised_Today__c = 1,
                                                                        CLV_threshold__c = 10, Sales_Rep__c = UserInfo.getUserId(), RecordTypeId = SAArecordtypeId); 
        insert saa01;
        
        
        // Create a lead that should assign to SAA.  
        Lead lead01 = new Lead(LastName = 'Test Lead 01', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                               Email = 'meow01@test.com', CountriesInterested__c = 'USA', Rating = 'Warm',
                               SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_EUROPE, TravelGroupSize__c = 9, CustomerLifetimeValue__c = 5);
        
        insert lead01;       
        
        Lead leadTest = [select Id, OwnerId, AssignedtoSAA__c from Lead where Id=:lead01.Id];
        System.assertEquals(true, leadTest.AssignedtoSAA__c);
        
        
        // Create a lead that should not assign to SAA.
        // First explicitly reset all static guard vars to ensure full trigger context.
        AP03_LeadTriggerHandler.isBeforeUpdateTriggerCalled = FALSE;
        AP03_LeadTriggerHandler.isBeforeInsertTriggerCalled = FALSE;
        AP03_LeadTriggerHandler.isAfterUpdateTriggerCalled = FALSE;
        AP03_LeadTriggerHandler.isAfterInsertTriggerCalled = FALSE;
        
        AP04_LeadTriggerBL.isBeforeUpdateTriggerCalled = FALSE;
        AP04_LeadTriggerBL.isBeforeInsertTriggerCalled = FALSE;
        AP04_LeadTriggerBL.isAfterUpdateTriggerCalled = FALSE;
        AP04_LeadTriggerBL.isAfterInsertTriggerCalled = FALSE;      
        
        Lead lead02 = new Lead(LastName = 'Test Lead 02', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                               Email = 'meow02@test.com', CountriesInterested__c = 'USA', Rating = 'Warm',
                               SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_EUROPE, TravelGroupSize__c = 9, CustomerLifetimeValue__c = 5);
        
        
        lead02.Bypass_SAA_Routing__c=true;
        
        Test.startTest();
        insert lead02;
        Test.stopTest();
        
        leadTest = [select Id, OwnerId, AssignedtoSAA__c from Lead where Id=:lead02.Id];
        System.assertEquals(false, leadTest.AssignedtoSAA__c);
    }   
    
    @isTest static void testDoPostConvert(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//<-- 3.8 block WIRE calculations for test data.
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
        

        List<Object_Field_Mapping__c> ofms = AP23_TestDataFactory.createObjectFieldMappingsByObject('LEAD');
        insert ofms;
        
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings; 
        
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        
        System.debug(LoggingLevel.ERROR,'validationList:'+validationList);
        
        String clientString = ApplicationConstant.RECORD_TYPE_ACCOUNT_CLIENT;
        
        //Create Client Account
        Account acc = new Account();
        acc.FirstName = 'Test';
        acc.LastName = 'Account 1';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(clientString).getRecordTypeId();
        insert acc;
        
        System.debug(LoggingLevel.ERROR,'acc:'+acc);
        
        //Create new Lead
        Lead l = new Lead();
        l.Account__c = acc.Id;
        l.FirstName = acc.FirstName;
        l.LastName = acc.LastName;
        l.EnquiryId__c = '12345';
        l.Email = 'testLead1@example.com';
        l.LeadSource = ApplicationConstant.LEAD_SOURCE_WEBSITEFORM;
        l.CountriesInterested__c = ApplicationConstant.COUNTRY_ENGLAND_WALES;
        l.Status = ApplicationConstant.LEAD_STATUS_NEW;
        insert l;
        
        //Create and link new Shadow Opp
        Opportunity shadowOpp = new Opportunity();
        shadowOpp.Name = l.FirstName + ' ' + l.LastName + ' Shadow';
        shadowOpp.CloseDate = Date.today();
        shadowOpp.StageName = ApplicationConstant.QUOTESENTSTAGE;
        shadowOpp.AccountId = l.Account__c;
        shadowOpp.Source_Lead__c = l.Id;
        shadowOpp.GolfbreaksEnquiryId__c = l.GolfbreaksEnquiryId__c;
        shadowOpp.RecordTypeId = ApplicationConstant.getRecordTypeId('Opportunity','Sales_Shadow_Opportunity');
        insert shadowOpp;
        
        //Requery the Lead
        Lead leadToConvert = [Select Id, ConvertedOpportunityId, IsConverted, ConvertedDate, FirstName, LastName, EnquiryId__c, Email, LeadSource, CountriesInterested__c,Status,Account__c From Lead Where Id = :l.Id][0];
        system.assertNotEquals(null,leadToConvert);


        //Convert the Lead
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadToConvert.id);
        lc.setOpportunityName('ConvertedLeadOpportunity');
        lc.setConvertedStatus(ApplicationConstant.LEAD_CLOSED_CONVERTED);
        lc.setAccountId(acc.Id);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());        
        
        Set<Id> convertedLeadIdSet = new Set<Id>();
        convertedLeadIdSet.add(leadToConvert.Id);

        WorkItemWIREActionIdentifier.isWIRECodeBlocked = false;
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = false;

       
        test.startTest();
        AP04_LeadTriggerBL.doPostConvert(convertedLeadIdSet);
        test.stopTest();        
               
        //Assert values are correct        
        //The conversion should result in the transfer of values from the Shadow Opp to the newly created Opp (and the deletion of the Shadow)
        
        //Query the related Opps
        Opportunity[] linkedOpps = [Select Id, Name, IsDeleted, StageName, RecordType.DeveloperName, Amount, Source_Lead__c From Opportunity Where Source_Lead__c = :leadToConvert.Id ALL ROWS];
        //Confirm two are found (the shadow and new opp)
        system.debug('linkedOpps Retrieved: '+linkedOpps);
        system.assertEquals(2,linkedOpps.size());
        
        //Split the two for assertions 
        Opportunity shadow;
        Opportunity newOpp;
        if(linkedOpps[0].RecordType.DeveloperName == 'Sales_Shadow_Opportunity'){
            shadow = linkedOpps[0];
            newOpp = linkedOpps[1];
        }else{
            if(linkedOpps[1].RecordType.DeveloperName == 'Sales_Shadow_Opportunity'){
                shadow = linkedOpps[1];
                newOpp = linkedOpps[0];
            }
        }
        system.assertNotEquals(null,shadow);
        system.assertNotEquals(null,newOpp);
        
        //Confirm the shadow opp has been deleted
        system.assertEquals(true,shadow.IsDeleted);
        //Confirm the other opportunity was created from the conversion
        system.assertEquals('ConvertedLeadOpportunity',newOpp.Name);
        //Confirm the amounts are the same
        system.assertEquals(shadow.Amount,newOpp.Amount);
        //Confirm the stages match
        system.assertEquals(shadow.StageName,newOpp.StageName);        
    }
}