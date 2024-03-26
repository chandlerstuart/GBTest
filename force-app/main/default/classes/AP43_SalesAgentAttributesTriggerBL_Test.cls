/**
Name:  AP43_SalesAgentAttributesTriggerBL_Test.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test Class for AP43_SalesAgentAttributesTriggerBL
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  M.Cebrian  2016-05-04  Initial test class development
1.1  S.Molloy   2016-11-25  Created Account Validation rules
**/
@isTest
public class AP43_SalesAgentAttributesTriggerBL_Test{

    static Id SAArecordtypeId;
    static Profile prof;
    
    @testSetup static void setupData(){
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;

        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
    }

    private static void setData(){
        prof = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User newUser = new User(Alias = 'standt', Email='gbtest@test.com',
                        EmailEncodingKey='UTF-8', LastName='Breaks', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = prof.Id, TimeZoneSidKey='America/Los_Angeles', 
                        UserName='gbtest@test.com');
        insert newUser;

        RecordType personAccountRecType =  [SELECT Id FROM RecordType WHERE IsPersonType = TRUE and SObjectType = 'Account' LIMIT 1];
        SAArecordtypeId = ApplicationConstant.getRecordTypeId(ApplicationConstant.USP_OBJECT, ApplicationConstant.USP_SALES_AGENT_DEVNAME);
        //Schema.SObjectType.Sales_Agent_Attributes__c.getRecordTypeInfosByName().get('Sales Agent').getRecordTypeId();
        
        List<Account> accList = AP23_TestDataFactory.createAccount(1); 
        insert accList;
        
        Account perAccount = new Account( FirstName='Joe', LastName='Schmoe', RecordTypeId = personAccountRecType.Id );
        insert perAccount;
        
        Contact perContact = [SELECT Id, Is_PGA__c FROM Contact WHERE AccountId =: perAccount.Id LIMIT 1];
        perContact.Is_PGA__c = TRUE;
        update perContact;
        
        List<Opportunity> oppList = AP23_TestDataFactory.createOpportunity(1, ApplicationConstant.RECOMMENDATIONSTAGE, accList[0]);
        insert oppList;
    }

    static testMethod void testInsertSales(){
        setData();
        User newUser = [SELECT Id From User LIMIT 1];
    
        List<Sales_Agent_Attributes__c> lSAA = new List<Sales_Agent_Attributes__c>();
        Sales_Agent_Attributes__c saa01 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = ApplicationConstant.EUROPE_8_TEAM, Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 4, Min_CLV_Threshold__c = 0,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = UserInfo.getUserId(), RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa01);  
        
        Sales_Agent_Attributes__c saa02 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = 'S- EU 8+ Sales Team;S- EU 0-7 Sales Team', Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 4, Min_CLV_Threshold__c = 0,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = newUser.Id, RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa02);                                                             
            
        Test.startTest();
            insert lSAA;

        Test.stopTest();
        System.assertEquals(2, [SELECT Count() FROM Sales_Agent_Attributes__c]);
    
    }

    static testMethod void testUpdateSales(){
        setData();
        User newUser = [SELECT Id From User LIMIT 1];
    
        List<Sales_Agent_Attributes__c> lSAA = new List<Sales_Agent_Attributes__c>();
        Sales_Agent_Attributes__c saa01 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = ApplicationConstant.EUROPE_8_TEAM, Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 4, Min_CLV_Threshold__c = 0,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = UserInfo.getUserId(), RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa01);  
        
        Sales_Agent_Attributes__c saa02 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = ApplicationConstant.EUROPE_8_TEAM +';' + ApplicationConstant.EUROPE_0_7_TEAM, Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 4, Min_CLV_Threshold__c = 0,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = newUser.Id, RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa02);                                                             
        insert lSAA;

        for(Sales_Agent_Attributes__c saa: lSAA){
            saa.Team__c = ApplicationConstant.LEAD_SPC_SALESTEAM;
        }

        Test.startTest();
            
        update lSAA;

        Test.stopTest();
        System.assertEquals(2, [SELECT Count() FROM Sales_Agent_Attributes__c]);
    
    }

    static testMethod void testUpdateSalesError(){
        setData();
        User newUser = [SELECT Id From User LIMIT 1];
    
        List<Sales_Agent_Attributes__c> lSAA = new List<Sales_Agent_Attributes__c>();
        Sales_Agent_Attributes__c saa01 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = ApplicationConstant.EUROPE_8_TEAM, Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 4, Min_CLV_Threshold__c = 0,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = UserInfo.getUserId(), RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa01);  
        
        Sales_Agent_Attributes__c saa02 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = ApplicationConstant.EUROPE_8_TEAM +';' + ApplicationConstant.EUROPE_0_7_TEAM, Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 4, Min_CLV_Threshold__c = 0,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = newUser.Id, RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa02);                                                             
        insert lSAA;

        for(Sales_Agent_Attributes__c saa: lSAA){
            saa.Team__c =  ApplicationConstant.LEAD_SPC_SALESTEAM;
            saa.Sales_Rep__c = null;
        }

        Test.startTest();
            
                update lSAA;
            
        Test.stopTest();
        System.assertEquals(2, [SELECT Count() FROM Sales_Agent_Attributes__c]);
    
    }

    static testMethod void testInsertSalesError(){
        setData();
        User newUser = [SELECT Id From User LIMIT 1];
    
        List<Sales_Agent_Attributes__c> lSAA = new List<Sales_Agent_Attributes__c>();
        Sales_Agent_Attributes__c saa01 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = ApplicationConstant.EUROPE_8_TEAM, Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 4, Min_CLV_Threshold__c = 0,
                                                                      CLV_threshold__c = 10, RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa01);  
        
        Sales_Agent_Attributes__c saa02 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = ApplicationConstant.EUROPE_8_TEAM +';' + ApplicationConstant.EUROPE_0_7_TEAM, Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 4, Min_CLV_Threshold__c = 0,
                                                                      CLV_threshold__c = 10, RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa02);                                                             
            
        Test.startTest();
            
                insert lSAA;
            
        Test.stopTest();
    
    }
}