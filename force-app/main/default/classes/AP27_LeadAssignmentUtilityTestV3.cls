/**
Name:  AP27_LeadAssignmentUtilityTestV3.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test Class for debugging an issue with Lead Routing in AP27_LeadAssignmentUtility
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail 
1.0  SMolloy   2017-01-13   Created the test class

**/
@isTest
public class  AP27_LeadAssignmentUtilityTestV3 {

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
   
    static testMethod void testSAAZeroMaxNewLeads(){
        setData();
        List<Sales_Agent_Attributes__c> lSAA = new List<Sales_Agent_Attributes__c>();
        Sales_Agent_Attributes__c saa01 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'France; Portugal; Spain; Belgium; Italy', 
                                                                      Team__c = 'S- EU 0-7 Sales Team', 
                                                                      Current_Number_of_Open_Leads_Opps__c = 0,
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 0, 
                                                                      Current_Items_Diarised_Today__c = 10, 
                                                                      Max_Items_Diarised_Today__c = 80,  
                                                                      Min_CLV_Threshold__c = 0,
                                                                      CLV_threshold__c = 100000000, Sales_Rep__c = UserInfo.getUserId(), RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa01);  
                                                                 
        insert lSAA;

        List<Lead> lLead = new List<Lead>();
        Lead l01 = new Lead(LastName = 'Test Lead 01', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Phone', 
                            Email = 'meow01@test.com', CountriesInterested__c = 'France', Rating = 'Warm',
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_EUROPE, TravelGroupSize__c = 3, CustomerLifetimeValue__c = 0);
        lLead.add(l01);
        
        insert lLead;

        /*system.debug('*** -- testSAAZeroMaxNewLeads info -- ***');
        system.debug('*** -- ' + checkLead + ' -- ***');
        system.debug('*** -- ' + checkSAA + ' -- ***');
        system.debug('*** -- ' + whichGroup + ' -- ***');*/

        //NO AVALABLE AGENT
        AP27_LeadAssignmentUtility.leadRouter(lLead, false, false);

        Lead leadRecord = [select OwnerId, Owner.Name, CountriesInterested__c,
                            CustomerLifetimeValue__c from Lead LIMIT 1];
        Group whichGroup = [select Name from Group where Id = :leadRecord.OwnerId LIMIT 1];

        Sales_Agent_Attributes__c agentRecord = [select Current_Number_of_Open_Leads_Opps__c, 
                                                Max_Number_of_Open_Leads_Opportunities__c, Product_Knowledge__c,Max_Items_Diarised_Today__c,
                                                CLV_threshold__c, Online__c, Min_CLV_Threshold__c, Current_Items_Diarised_Today__c 
                                                from Sales_Agent_Attributes__c LIMIT 1];

        system.debug('*** -- testSAAZeroMaxNewLeads info -- ***');
        system.debug('*** -- ' + leadRecord + ' -- ***');
        system.debug('*** -- ' + agentRecord + ' -- ***');
        system.debug('*** -- ' + whichGroup + ' -- ***');

        agentRecord.Max_Number_of_Open_Leads_Opportunities__c = 1;
        update agentRecord;


        system.assertNotEquals(true, String.isEmpty(leadRecord.CountriesInterested__c));
        system.assertEquals(true, (!String.isEmpty(leadRecord.CountriesInterested__c) && agentRecord.Product_Knowledge__c != null));
        system.assertEquals(true, AP27_LeadAssignmentUtility.compareMultiSelect(leadRecord.CountriesInterested__c, agentRecord.Product_Knowledge__c));

        system.assertEquals(true, agentRecord.Current_Number_of_Open_Leads_Opps__c < agentRecord.Max_Number_of_Open_Leads_Opportunities__c);
        system.assertEquals(true, agentRecord.Min_CLV_Threshold__c <= leadRecord.CustomerLifetimeValue__c);
        system.assertEquals(true, agentRecord.Online__c); 
        system.assertEquals(true, leadRecord.CustomerLifetimeValue__c <= agentRecord.CLV_threshold__c);
        system.assertEquals(true, agentRecord.Max_Items_Diarised_Today__c > agentRecord.Current_Items_Diarised_Today__c); 

        //AVAILABLE AGENT WITH CAPACITY = 1
        AP27_LeadAssignmentUtility.leadRouter(lLead, false, false);

        leadRecord = [select OwnerId, Owner.Name, CountriesInterested__c,
                            CustomerLifetimeValue__c from Lead LIMIT 1];

        //User assigned = [select Name from User where Id = :checkLead.OwnerId LIMIT 1];

        agentRecord = [select Current_Number_of_Open_Leads_Opps__c, 
                        Max_Number_of_Open_Leads_Opportunities__c, Product_Knowledge__c,Max_Items_Diarised_Today__c,
                        CLV_threshold__c, Online__c, Min_CLV_Threshold__c, Current_Items_Diarised_Today__c 
                        from Sales_Agent_Attributes__c LIMIT 1];    

        system.debug('*** -- ' + leadRecord + ' -- ***');
        system.debug('*** -- ' + agentRecord + ' -- ***');
        //system.debug('*** -- ' + assigned + ' -- ***');    

    }

}