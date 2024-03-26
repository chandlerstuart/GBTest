/**
Name:  AP27_LeadAssignmentUtilityTestV2.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test Class for AP27_LeadAssignmentUtility (Version 2)
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail 
1.0  SMolloy   2016-12-23       Created the test class (Version 2)

**/
@isTest
public class  AP27_LeadAssignmentUtilityTestV2 {

    static Id SAArecordtypeId;
    static Profile prof;
    
    @testSetup static void setupData(){
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;

        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;

        List<Object_Field_Mapping__c> allOFMList = AP23_TestDataFactory.getCustomSettingObjectFieldMapping();

        insert allOFMList;
        
        //Set up Team Travel Group Size custom settings
        List<TeamTravelGroupSize__c> ttsList = new List<TeamTravelGroupSize__c>();
        TeamTravelGroupSize__c t1 = new TeamTravelGroupSize__c();
        t1.Name = ApplicationConstant.EUROPE_0_7_TEAM;
        t1.Region_Name__c = ApplicationConstant.SALESREGIONGROUP_EUROPE;
        t1.Minimum_Size__c = 0;
        t1.Maximum_Size__c = 8;
        ttsList.add(t1);
        TeamTravelGroupSize__c t2 = new TeamTravelGroupSize__c();
        t2.Name = ApplicationConstant.EUROPE_8_TEAM;
        t2.Region_Name__c = ApplicationConstant.SALESREGIONGROUP_EUROPE;
        t2.Minimum_Size__c = 9;
        t2.Maximum_Size__c = 9999;
        ttsList.add(t2);
        TeamTravelGroupSize__c t3 = new TeamTravelGroupSize__c();
        t3.Name = ApplicationConstant.UK_AND_IRELAND_9_TEAM;
        t3.Region_Name__c = ApplicationConstant.SALESREGIONGROUP_UK_IRELAND;
        t3.Minimum_Size__c = 9;
        t3.Maximum_Size__c = 9999;
        ttsList.add(t3);
        TeamTravelGroupSize__c t4 = new TeamTravelGroupSize__c();
        t4.Name = ApplicationConstant.UK_AND_IRELAND_0_8_TEAM;
        t4.Region_Name__c = ApplicationConstant.SALESREGIONGROUP_UK_IRELAND;
        t4.Minimum_Size__c = 0;
        t4.Maximum_Size__c = 8;
        ttsList.add(t4);
        
        insert ttsList;
    }

    private static void setData(){
        prof = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User newUser = new User(Alias = 'standt', Email='meow1@test.com',
                        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = prof.Id, TimeZoneSidKey='America/Los_Angeles', 
                        UserName='meow1@test.com');
        insert newUser;

        RecordType personAccountRecType =  [SELECT Id FROM RecordType WHERE IsPersonType = TRUE and SObjectType = 'Account' LIMIT 1];
        SAArecordtypeId = Schema.SObjectType.Sales_Agent_Attributes__c.getRecordTypeInfosByName().get('Sales Agent').getRecordTypeId();
        
        List<Account> accList = AP23_TestDataFactory.createPersonAccount(1); 
        insert accList;
        
        Account perAccount = new Account( FirstName='Joe', LastName='Schmoe', RecordTypeId = personAccountRecType.Id );
        insert perAccount;
        
        Contact perContact = [SELECT Id, Is_PGA__c FROM Contact WHERE AccountId =: perAccount.Id LIMIT 1];
        perContact.Is_PGA__c = TRUE;
        update perContact;
        
        List<Opportunity> oppList = AP23_TestDataFactory.createOpportunity(1, 'Prospecting', accList[0]);
        insert oppList;
    }

    // -- START OF TEST RUNNING METHODS --//
    
    static testMethod void testdoSAAMatchingNoMatch(){
        system.debug('*** -- testdoSAAMatchingNoMatch -- ***');
        setData();
        List<Sales_Agent_Attributes__c> lSAA = new List<Sales_Agent_Attributes__c>();
        Sales_Agent_Attributes__c saa01 = new Sales_Agent_Attributes__c(Online__c = FALSE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = 'S- EU 8+ Sales Team', Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 2, Min_CLV_Threshold__c = 0,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = UserInfo.getUserId(), RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa01);  
                                                                 
        insert lSAA;
        Test.startTest();
        //Account acc = [SELECT Id FROM Account WHERE PersonContactId = NULL LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Lead> lLead = new List<Lead>();
        Lead l01 = new Lead(LastName = 'Test Lead 01', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow01@test.com', CountriesInterested__c = 'USA', Rating = 'Warm', Account__c = acc.Id,
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_EUROPE, TravelGroupSize__c = 9, CustomerLifetimeValue__c = 0);
        lLead.add(l01);
        
        insert lLead;
        
        Lead UpdLead = [SELECT Id, OwnerId, AssignedtoSAA__c FROM Lead WHERE Id=: l01.Id];
        System.AssertEquals(UpdLead.AssignedtoSAA__c, FALSE);
        Group UpdGroup = [SELECT Id, Name FROM Group WHERE Name =: ApplicationConstant.EUROPE_8_TEAM AND Type = 'Queue'];
        
        System.AssertEquals(UpdLead.OwnerId, UpdGroup.Id);
        Test.stopTest();
    
    }

    static testMethod void testdoSAAMatchingSingleMatch(){
        setData();
        List<Sales_Agent_Attributes__c> lSAA = new List<Sales_Agent_Attributes__c>();
        Sales_Agent_Attributes__c saa01 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = 'S- EU 8+ Sales Team', Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 3, Min_CLV_Threshold__c = 0,
                                                                      Max_Items_Diarised_Today__c = 10, Current_Items_Diarised_Today__c = 1,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = UserInfo.getUserId(), RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa01);  
                                                                 
        insert lSAA;
        Test.startTest();
        //Account acc = [SELECT Id FROM Account WHERE PersonContactId = NULL LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Lead> lLead = new List<Lead>();
        Lead l01 = new Lead(LastName = 'Test Lead 01', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow01@test.com', CountriesInterested__c = 'USA', Rating = 'Warm',
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_EUROPE, TravelGroupSize__c = 9, CustomerLifetimeValue__c = 5);
        lLead.add(l01);
        
        insert lLead;
        
        Lead UpdLead = [SELECT Id, OwnerId, AssignedtoSAA__c FROM Lead WHERE Id=: l01.Id];
        System.AssertEquals(UpdLead.AssignedtoSAA__c, TRUE);

        Test.stopTest();
    
    }
    
    static testMethod void testdoSAAMatchingMultipleMatchNoAcc(){
        setData();
        User newUser = [SELECT Id From User LIMIT 1];
    
        List<Sales_Agent_Attributes__c> lSAA = new List<Sales_Agent_Attributes__c>();
        Sales_Agent_Attributes__c saa01 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = 'S- EU 8+ Sales Team', Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 4, Min_CLV_Threshold__c = 0,
                                                                      Max_Items_Diarised_Today__c = 10, Current_Items_Diarised_Today__c = 1,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = UserInfo.getUserId(), RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa01);  
        
        Sales_Agent_Attributes__c saa02 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = 'S- EU 8+ Sales Team;S- EU 0-7 Sales Team', Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 4, Min_CLV_Threshold__c = 0,
                                                                      Max_Items_Diarised_Today__c = 10, Current_Items_Diarised_Today__c = 1,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = newUser.Id, RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa02);                                                             
        insert lSAA;
    
        Test.startTest();
        //Account acc = [SELECT Id FROM Account WHERE PersonContactId = NULL LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Lead> lLead = new List<Lead>();
        Lead l01 = new Lead(LastName = 'Test Lead 01', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow01@test.com', CountriesInterested__c = 'USA', Rating = 'Warm',
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_EUROPE, TravelGroupSize__c = 9, CustomerLifetimeValue__c = 5);
        lLead.add(l01);      
        insert lLead;

        Lead UpdLead = [SELECT Id, OwnerId, AssignedtoSAA__c FROM Lead WHERE Id=: l01.Id];
        System.AssertEquals(UpdLead.AssignedtoSAA__c, TRUE);

        
        Test.stopTest();
    }
    
    static testMethod void testdoSAAMatchingMultipleMatchAcc(){
        setData();
        User newUser = [SELECT Id From User LIMIT 1];
    
        List<Sales_Agent_Attributes__c> lSAA = new List<Sales_Agent_Attributes__c>();
        Sales_Agent_Attributes__c saa01 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = 'S- EU 8+ Sales Team', Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 4, Min_CLV_Threshold__c = 0,
                                                                      Max_Items_Diarised_Today__c = 10, Current_Items_Diarised_Today__c = 1,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = UserInfo.getUserId(), RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa01);  
        
        Sales_Agent_Attributes__c saa02 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = 'S- EU 8+ Sales Team;S- EU 0-7 Sales Team', Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 4, Min_CLV_Threshold__c = 0,
                                                                      Max_Items_Diarised_Today__c = 10, Current_Items_Diarised_Today__c = 1,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = newUser.Id, RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa02);                                                             
        insert lSAA;
        
        Test.startTest();
        //Account acc = [SELECT Id FROM Account WHERE PersonContactId = NULL LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Lead> lLead = new List<Lead>();
        Lead l01 = new Lead(LastName = 'Test Lead 01', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow01@test.com', CountriesInterested__c = 'USA', Rating = 'Warm',  Account__c = acc.Id,
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_EUROPE, TravelGroupSize__c = 9, CustomerLifetimeValue__c = 5);
        lLead.add(l01);      
        insert lLead;

        Lead UpdLead = [SELECT Id, OwnerId, AssignedtoSAA__c FROM Lead WHERE Id=: l01.Id];
        System.AssertEquals(UpdLead.AssignedtoSAA__c, TRUE);

        
        Test.stopTest();
    
    } 
    
    static testMethod void testdoSAAMatchingMultipleMatchAcc2(){
        setData();
        User newUser = [SELECT Id From User LIMIT 1];
    
        List<Sales_Agent_Attributes__c> lSAA = new List<Sales_Agent_Attributes__c>();
        Sales_Agent_Attributes__c saa01 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = 'S- EU 8+ Sales Team', Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 4, Min_CLV_Threshold__c = 0,
                                                                      Max_Items_Diarised_Today__c = 10, Current_Items_Diarised_Today__c = 1,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = UserInfo.getUserId(), RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa01);  
        
        Sales_Agent_Attributes__c saa02 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = 'S- EU 8+ Sales Team;S- EU 0-7 Sales Team', Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 4, Min_CLV_Threshold__c = 0,
                                                                      Max_Items_Diarised_Today__c = 10, Current_Items_Diarised_Today__c = 1,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = newUser.Id, RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa02);                                                             
        insert lSAA;
    
        Test.startTest();
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert acc;
        
        List<Lead> lLead = new List<Lead>();
        Lead l01 = new Lead(LastName = 'Test Lead 01', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow01@test.com', CountriesInterested__c = 'USA', Rating = 'Warm',  Account__c = acc.Id,
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_EUROPE, TravelGroupSize__c = 9, CustomerLifetimeValue__c = 5);
        lLead.add(l01);      
        insert lLead;

        Lead UpdLead = [SELECT Id, OwnerId, AssignedtoSAA__c FROM Lead WHERE Id=: l01.Id];
        System.AssertEquals(UpdLead.AssignedtoSAA__c, TRUE);
        
        Test.stopTest();
    } 
    
    static testMethod void testSpecialistNoSAA(){
        setData();
        User newUser = [SELECT Id From User LIMIT 1];
        RecordType SAARecType =  [SELECT Id FROM RecordType WHERE Name =: ApplicationConstant.LEAD_SALES_AGENT and SObjectType = 'Sales_Agent_Attributes__c' LIMIT 1];
        //ApplicationConstant.LEAD_SALES_AGENT
        List<Sales_Agent_Attributes__c> lSAA = new List<Sales_Agent_Attributes__c>();
        Sales_Agent_Attributes__c saa01 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = ApplicationConstant.LEAD_SPC_SALESTEAM, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 1, Min_CLV_Threshold__c = 0,
                                                                      Max_Items_Diarised_Today__c = 10, Current_Items_Diarised_Today__c = 1,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = UserInfo.getUserId(), RecordTypeId = SAARecType.Id); 
        lSAA.add(saa01);                                                            
        insert lSAA;
    
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE PersonContactId <> NULL LIMIT 1];
        List<Lead> lLead = new List<Lead>();
        Lead l01 = new Lead(LastName = 'Test Lead 01', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow01@test.com', CountriesInterested__c = 'USA', Rating = 'Warm', Account__c = acc.Id,
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_EUROPE, TravelGroupSize__c = 9, CustomerLifetimeValue__c = 5);
        lLead.add(l01);       
        insert lLead;
   
        Lead UpdLead = [SELECT Id, OwnerId, AssignedtoSAA__c FROM Lead WHERE Id=: l01.Id];
        System.AssertEquals(UpdLead.AssignedtoSAA__c, FALSE);
        List<Group> specialistGroup = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND 
                                            Name = :ApplicationConstant.LEAD_SPC_SALESTEAM];
        //System.AssertEquals(UpdLead.OwnerId, specialistGroup[0].Id);
        Test.stopTest();
    }
    
    static testMethod void testSpecialistSAA(){
        setData();
        User newUser = [SELECT Id From User WHERE Email='meow1@test.com' LIMIT 1];
        RecordType SAARecType =  [SELECT Id FROM RecordType WHERE Name =: ApplicationConstant.LEAD_SALES_AGENT and SObjectType = 'Sales_Agent_Attributes__c' LIMIT 1];
        
        List<Sales_Agent_Attributes__c> lSAA = new List<Sales_Agent_Attributes__c>();
        Sales_Agent_Attributes__c saa01 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = ApplicationConstant.LEAD_SPC_SALESTEAM, Current_Number_of_Open_Leads_Opps__c = 1,
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 4, Min_CLV_Threshold__c = 0,
                                                                      Max_Items_Diarised_Today__c = 10, Current_Items_Diarised_Today__c = 1,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = newUser.Id, RecordTypeId = SAARecType.Id,
                                                                      Sales_Agent_ID__c = 'TestAgentId'); 
        lSAA.add(saa01);  
                                                          
        insert lSAA;
    
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE PersonContactId <> NULL LIMIT 1];
        List<Lead> lLead = new List<Lead>();
        Lead l01 = new Lead(LastName = 'Test Lead 01', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow01@test.com', CountriesInterested__c = 'USA', Rating = 'Warm', Account__c = acc.Id,
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_EUROPE, TravelGroupSize__c = 9, CustomerLifetimeValue__c = 5);
        lLead.add(l01);       
        insert lLead;
   
        Lead UpdLead = [SELECT Id, OwnerId, AssignedtoSAA__c FROM Lead WHERE Id=: l01.Id];
        //System.AssertEquals(UpdLead.AssignedtoSAA__c, TRUE);


        Test.stopTest();
    }
    
    static testMethod void testUnknownTeam(){
        setData();
        User newUser = [SELECT Id From User WHERE Email='meow1@test.com' LIMIT 1];
        RecordType SAARecType =  [SELECT Id FROM RecordType WHERE Name =: ApplicationConstant.LEAD_SALES_AGENT and SObjectType = 'Sales_Agent_Attributes__c' LIMIT 1];
        
        List<Sales_Agent_Attributes__c> lSAA = new List<Sales_Agent_Attributes__c>();
        Sales_Agent_Attributes__c saa01 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = ApplicationConstant.LEAD_SPC_SALESTEAM, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 2, Min_CLV_Threshold__c = 0,
                                                                      Max_Items_Diarised_Today__c = 10, Current_Items_Diarised_Today__c = 1,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = newUser.Id, RecordTypeId = SAARecType.Id); 
        lSAA.add(saa01);  
                                                          
        insert lSAA;
    
        Test.startTest();
        //Account acc = [SELECT Id FROM Account WHERE PersonContactId = NULL LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Lead> lLead = new List<Lead>();
        Lead l01 = new Lead(LastName = 'Test Lead 01', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow01@test.com', CountriesInterested__c = 'USA', Rating = 'Warm', Account__c = acc.Id,
                            TravelGroupSize__c = 9, CustomerLifetimeValue__c = 5);
        lLead.add(l01);       
        insert lLead;
   
        Lead UpdLead = [SELECT Id, OwnerId, AssignedtoSAA__c FROM Lead WHERE Id=: l01.Id];
        System.AssertEquals(UpdLead.AssignedtoSAA__c, FALSE);
        List<Group> unknownQueue = [SELECT Id, Name FROM GROUP WHERE Name = :ApplicationConstant.UNKNOWN_SALES_TEAM AND Type = 'Queue'];
        System.AssertEquals(UpdLead.OwnerId, unknownQueue[0].Id);
        Test.stopTest();
    }
    
    static testMethod void testBatch(){
        setData();
        List<Lead> lLead = new List<Lead>();
        Lead l01 = new Lead(LastName = 'Test Lead 01', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow01@test.com', CountriesInterested__c = 'USA', Rating = 'Warm', 
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_EUROPE, TravelGroupSize__c = 9, CustomerLifetimeValue__c = null, 
                            AssignedtoSAA__c = FALSE);
        lLead.add(l01);       
        insert lLead;
        
        List<Group> queueGrp = [SELECT Id, Name FROM GROUP WHERE Name IN :ApplicationConstant.TEAM_SET AND Type = 'Queue' LIMIT 1];
        l01.OwnerId = queueGrp[0].Id;
        update l01;
        
        Test.startTest();
        AP30_ScheduledLeadAssignmentBatch leadbatch = new AP30_ScheduledLeadAssignmentBatch();        
        Database.executeBatch(leadbatch);
        Test.stopTest();
    }
    
    static testMethod void testReturnTraveller(){
        setData();
        List<Sales_Agent_Attributes__c> lSAA = new List<Sales_Agent_Attributes__c>();
        Sales_Agent_Attributes__c saa01 = new Sales_Agent_Attributes__c(Online__c = FALSE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = 'S- EU 8+ Sales Team', Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 2, Min_CLV_Threshold__c = 0,
                                                                      Max_Items_Diarised_Today__c = 10, Current_Items_Diarised_Today__c = 1,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = UserInfo.getUserId(), RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa01);  
                                                                 
        insert lSAA;
        Test.startTest();
        //Account acc = [SELECT Id FROM Account WHERE PersonContactId = NULL LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Lead> lLead = new List<Lead>();
        Lead l01 = new Lead(LastName = 'Test Lead 01', Status = 'New', Diarydate__c = System.Today(), LeadSource = ApplicationConstant.RETURNING_TRAVELLER, 
                            Email = 'meow01@test.com', CountriesInterested__c = 'USA', Rating = 'Warm', Account__c = acc.Id,
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_EUROPE, TravelGroupSize__c = 9, CustomerLifetimeValue__c = 0);
        lLead.add(l01);
        
        insert lLead;
        
        l01.LeadSource = ApplicationConstant.RETURNING_TRAVELLER;
        update l01;
        
        Lead UpdLead = [SELECT Id, OwnerId, AssignedtoSAA__c FROM Lead WHERE Id=: l01.Id];
        System.AssertEquals(UpdLead.AssignedtoSAA__c, FALSE);
        Group returningQueue = [SELECT Id, Name FROM GROUP WHERE Name = :ApplicationConstant.RETURNING_TRAVELLER_TEAM AND Type = 'Queue' LIMIT 1];       
        System.AssertEquals(UpdLead.OwnerId, returningQueue.Id);
        Test.stopTest();
    }
    
    static testMethod void testColdLead(){
        setData();
        List<Sales_Agent_Attributes__c> lSAA = new List<Sales_Agent_Attributes__c>();
        Sales_Agent_Attributes__c saa01 = new Sales_Agent_Attributes__c(Online__c = FALSE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = 'S- EU 8+ Sales Team', Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 2, Min_CLV_Threshold__c = 0,
                                                                      Max_Items_Diarised_Today__c = 10, Current_Items_Diarised_Today__c = 1,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = UserInfo.getUserId(), RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa01);  
                                                                 
        insert lSAA;
        Test.startTest();
        //Account acc = [SELECT Id FROM Account WHERE PersonContactId = NULL LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Lead> lLead = new List<Lead>();
        Lead l01 = new Lead(LastName = 'Test Lead 01', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow01@test.com', CountriesInterested__c = 'USA', Rating = 'Cold', Account__c = acc.Id,
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_EUROPE, TravelGroupSize__c = 9, CustomerLifetimeValue__c = 0);
        lLead.add(l01);
        
        insert lLead;
        
        Lead UpdLead = [SELECT Id, OwnerId, AssignedtoSAA__c FROM Lead WHERE Id=: l01.Id];
        System.AssertEquals(UpdLead.AssignedtoSAA__c, FALSE);
        Group coldQueue = [SELECT Id, Name FROM GROUP WHERE Name = :ApplicationConstant.COLD_TEAM AND Type = 'Queue' LIMIT 1];       
        System.AssertEquals(UpdLead.OwnerId, coldQueue.Id);
        Test.stopTest();
    }
    
    static testMethod void testdoSAAMatchingMultipleMatchNoAccSecondLoop(){
        setData();
        User newUser = [SELECT Id From User LIMIT 1];
    
        List<Sales_Agent_Attributes__c> lSAA = new List<Sales_Agent_Attributes__c>();
        Sales_Agent_Attributes__c saa01 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = 'S- EU 8+ Sales Team', Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Items_Diarised_Today__c = 10, Current_Items_Diarised_Today__c = 1,
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 2, Min_CLV_Threshold__c = 0, nextUp__c = false,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = UserInfo.getUserId(), RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa01);  
        
        Sales_Agent_Attributes__c saa02 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA',
                                                                        Max_Items_Diarised_Today__c = 10, Current_Items_Diarised_Today__c = 1, 
                                                                      Team__c = 'S- EU 8+ Sales Team;S- EU 0-7 Sales Team', Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 2, Min_CLV_Threshold__c = 0, nextUp__c = false,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = newUser.Id, RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa02);                                                             
        insert lSAA;
    
        Test.startTest();
        //Account acc = [SELECT Id FROM Account WHERE PersonContactId = NULL LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Lead> lLead = new List<Lead>();
        Lead l01 = new Lead(LastName = 'Test Lead 01', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow01@test.com', CountriesInterested__c = 'USA', Rating = 'Warm',
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_EUROPE, TravelGroupSize__c = 9, CustomerLifetimeValue__c = 5);
        lLead.add(l01);
        insert lLead;

        Lead UpdLead = [SELECT Id, OwnerId, AssignedtoSAA__c FROM Lead WHERE Id=: l01.Id];
        System.AssertEquals(UpdLead.AssignedtoSAA__c, TRUE);

        
        Test.stopTest();
    }
    
    static testMethod void testdoSAAMatchingMultipleMatchNoAccSecondLoopMaxReached(){
        setData();
        User newUser = [SELECT Id From User LIMIT 1];
        
        User user = new User(Alias = 'AP27', Email='AP27@test.com',
                        EmailEncodingKey='UTF-8', LastName='AP27', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = prof.Id, TimeZoneSidKey='America/Los_Angeles', 
                        UserName='AP27@test.com');
        insert user;
    
        List<Sales_Agent_Attributes__c> lSAA = new List<Sales_Agent_Attributes__c>();
        Sales_Agent_Attributes__c saa01 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = 'S- EU 8+ Sales Team', Current_Number_of_Open_Leads_Opps__c = 1,
                                                                      Max_Items_Diarised_Today__c = 10, Current_Items_Diarised_Today__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 1, Min_CLV_Threshold__c = 0, nextUp__c = false,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = UserInfo.getUserId(), RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa01);  
        
        Sales_Agent_Attributes__c saa02 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA',
                                                                      Max_Items_Diarised_Today__c = 10, Current_Items_Diarised_Today__c = 1, 
                                                                      Team__c = 'S- EU 8+ Sales Team;S- EU 0-7 Sales Team', Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 2, Min_CLV_Threshold__c = 0, nextUp__c = false,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = newUser.Id, RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa02);
        
        Sales_Agent_Attributes__c saa03 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Max_Items_Diarised_Today__c = 10, Current_Items_Diarised_Today__c = 1,
                                                                      Team__c = 'S- EU 8+ Sales Team;S- EU 0-7 Sales Team', Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 2, Min_CLV_Threshold__c = 0, nextUp__c = false,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = user.Id, RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa03);                                                             
        insert lSAA;
    
        Test.startTest();
        //Account acc = [SELECT Id FROM Account WHERE PersonContactId = NULL LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Lead> lLead = new List<Lead>();
        Lead l01 = new Lead(LastName = 'Test Lead 01', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow01@test.com', CountriesInterested__c = 'USA', Rating = 'Warm',
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_EUROPE, TravelGroupSize__c = 9, CustomerLifetimeValue__c = null);
        lLead.add(l01);
        
        Lead l02 = new Lead(LastName = 'Test Lead 02', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow02@test.com', CountriesInterested__c = 'USA', Rating = 'Warm',
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_EUROPE, TravelGroupSize__c = 9, CustomerLifetimeValue__c = null);
        lLead.add(l02);
        
        Lead l03 = new Lead(LastName = 'Test Lead 03', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow03@test.com', CountriesInterested__c = 'USA', Rating = 'Warm',
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_EUROPE, TravelGroupSize__c = 9, CustomerLifetimeValue__c = null);
        lLead.add(l03);
        insert lLead;

        Lead UpdLead = [SELECT Id, OwnerId, AssignedtoSAA__c FROM Lead WHERE Id=: l01.Id];
        System.AssertEquals(UpdLead.AssignedtoSAA__c, TRUE);
        
        Test.stopTest();
    }
    
    static testMethod void testdoSAAMatchingMultipleMatchWithAccMaxReached(){
        setData();
        User newUser = [SELECT Id From User LIMIT 1];
        
        User user = new User(Alias = 'AP27', Email='AP27@test.com',
                        EmailEncodingKey='UTF-8', LastName='AP27', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = prof.Id, TimeZoneSidKey='America/Los_Angeles', 
                        UserName='AP27@test.com');
        insert user;
    
        List<Sales_Agent_Attributes__c> lSAA = new List<Sales_Agent_Attributes__c>();
        Sales_Agent_Attributes__c saa01 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = 'S- EU 8+ Sales Team', Current_Number_of_Open_Leads_Opps__c = 1,
                                                                      Max_Items_Diarised_Today__c = 10, Current_Items_Diarised_Today__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 1, Min_CLV_Threshold__c = 0, nextUp__c = false,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = UserInfo.getUserId(), RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa01);  
        
        Sales_Agent_Attributes__c saa02 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Max_Items_Diarised_Today__c = 10, Current_Items_Diarised_Today__c = 1,
                                                                      Team__c = 'S- EU 8+ Sales Team;S- EU 0-7 Sales Team', Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 2, Min_CLV_Threshold__c = 0, nextUp__c = false,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = newUser.Id, RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa02);
        
        Sales_Agent_Attributes__c saa03 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Max_Items_Diarised_Today__c = 10, Current_Items_Diarised_Today__c = 1,
                                                                      Team__c = 'S- EU 8+ Sales Team;S- EU 0-7 Sales Team', Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 2, Min_CLV_Threshold__c = 0, nextUp__c = false,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = user.Id, RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa03);                                                             
        insert lSAA;
    
        Test.startTest();
        //Account acc = [SELECT Id FROM Account WHERE PersonContactId = NULL LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Lead> lLead = new List<Lead>();
        Lead l01 = new Lead(LastName = 'Test Lead 01', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow01@test.com', CountriesInterested__c = 'USA', Rating = 'Warm', Account__c = acc.Id,
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_EUROPE, TravelGroupSize__c = 9, CustomerLifetimeValue__c = null);
        lLead.add(l01);
        
        Lead l02 = new Lead(LastName = 'Test Lead 02', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow02@test.com', CountriesInterested__c = 'USA', Rating = 'Warm', Account__c = acc.Id,
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_EUROPE, TravelGroupSize__c = 9, CustomerLifetimeValue__c = null);
        lLead.add(l02);
        
        Lead l03 = new Lead(LastName = 'Test Lead 03', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow03@test.com', CountriesInterested__c = 'USA', Rating = 'Warm', Account__c = acc.Id,
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_EUROPE, TravelGroupSize__c = 9, CustomerLifetimeValue__c = null);
        lLead.add(l03);
        insert lLead;

        Lead UpdLead = [SELECT Id, OwnerId, AssignedtoSAA__c FROM Lead WHERE Id=: l01.Id];
        System.AssertEquals(UpdLead.AssignedtoSAA__c, TRUE);
        
        Test.stopTest();
    }
    
    static testMethod void testMapTeamByRegionAndSize(){
    
        List<Lead> lLead = new List<Lead>();
        Lead l01 = new Lead(LastName = 'Test Lead 01', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow01@test.com', CountriesInterested__c = 'USA', Rating = 'Warm',
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_EUROPE, TravelGroupSize__c = 9, CustomerLifetimeValue__c = 5);
        lLead.add(l01);
        
        Lead l02 = new Lead(LastName = 'Test Lead 02', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow02@test.com', CountriesInterested__c = 'USA', Rating = 'Warm',
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_EUROPE, TravelGroupSize__c = 0, CustomerLifetimeValue__c = 5);
        lLead.add(l02);
        Lead l03 = new Lead(LastName = 'Test Lead 03', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow03@test.com', CountriesInterested__c = 'USA', Rating = 'Warm',
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_UK_IRELAND, TravelGroupSize__c = 9, CustomerLifetimeValue__c = 5);
        lLead.add(l03);
        Lead l04 = new Lead(LastName = 'Test Lead 04', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow04@test.com', CountriesInterested__c = 'USA', Rating = 'Warm',
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_UK_IRELAND, TravelGroupSize__c = 0, CustomerLifetimeValue__c = 5);
        lLead.add(l04);
        
        Lead l05 = new Lead(LastName = 'Test Lead 05', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow05@test.com', CountriesInterested__c = 'USA', Rating = 'Warm',
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_MIDHAUL, TravelGroupSize__c = 0, CustomerLifetimeValue__c = 5);
        lLead.add(l05);
        
        Lead l06 = new Lead(LastName = 'Test Lead 06', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow06@test.com', CountriesInterested__c = 'USA', Rating = 'Warm',
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_LONGHAUL, TravelGroupSize__c = 0, CustomerLifetimeValue__c = 5);
        lLead.add(l06);
        
        Lead l07 = new Lead(LastName = 'Test Lead 07', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow07@test.com', CountriesInterested__c = 'USA', Rating = 'Warm',
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_USA, TravelGroupSize__c = 0, CustomerLifetimeValue__c = 5);
        lLead.add(l07);
        
        System.assertEquals(7, AP27_LeadAssignmentUtility.mapTeamByRegionAndSize(lLead).size());
    }
    
    static testMethod void testLeadRouterException(){
        setData();
        
        AP27_LeadAssignmentUtility.leadRouter(null,true);
        
        AP27_LeadAssignmentUtility.doSAAMatching(null, true);
        
        AP27_LeadAssignmentUtility.assignLeadsToQueue(null, null);
        
        AP27_LeadAssignmentUtility.assignSpecialistTeam(null,true);
        
        AP27_LeadAssignmentUtility.assignToUnknownSalesTeam(null);
        
        AP27_LeadAssignmentUtility.assignToReturningTravellerSalesTeam(null);
        
        AP27_LeadAssignmentUtility.findAvailableSaa(null, null, null, 'Test', null, null);
        
        AP27_LeadAssignmentUtility.retrieveTeamAgentsMap(null);
        
        AP27_LeadAssignmentUtility.assignToColdTeam(null);
        
        List<Error_Log__c> logs = [SELECT Id FROM Error_Log__c];
        
        //System.assertEquals(10, logs.size());
        
    }
    
    static testMethod void testCompareMultiSelectReturnFalse(){
        String first = 'Spain;USA';
        String second = 'Ireland';
        
        System.assertEquals(false, AP27_LeadAssignmentUtility.compareMultiSelect(first, second));
    }

}