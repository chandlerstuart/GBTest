/**
Name:  SalesManagerDashboardControllerTest.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test Class for SalesManagerDashboardController
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Accenture   2016-04-25  Initial test class development
1.1  SMolloy     2016-11-25  Added data setup for Account Validation & object field mapping
**/
@isTest(seeAllData=true)
private class SalesManagerDashboardControllerTest {
    /*
    @testSetup
    static void dataSetup() {
        // Setup test data
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com1234');
        
        System.runAs(u){
            OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
            insert orgSettings; 
            
            Account acc = AP23_TestDataFactory.createAccount(1)[0];
            insert acc;
            
            Contact con = AP23_TestDataFactory.createContactList(1, acc)[0];
            insert con;
            
            List<Opportunity> oppList = new List<Opportunity>();
            Opportunity opp = AP23_TestDataFactory.createOpportunity(1, '1. Recommendations', acc)[0];
            opp.Diarydate__c = Date.today();
            oppList.add(opp); 
            
            Opportunity opp1 = AP23_TestDataFactory.createOpportunity(1, '2. Quote Sent', acc)[0];
            opp1.Diarydate__c = Date.today();
            oppList.add(opp1);
            
            Opportunity opp2 = AP23_TestDataFactory.createOpportunity(1, '3. Close Sale', acc)[0];
            opp2.Diarydate__c = Date.today();
            oppList.add(opp2);
            
            Opportunity opp3 = AP23_TestDataFactory.createOpportunity(1, '4. Customer Accepted', acc)[0];
            opp3.Diarydate__c = Date.today();
            oppList.add(opp3);
            
            insert oppList;

            Lead ld = AP23_TestDataFactory.createLead(1)[0];
            ld.Status = 'New';
            ld.Diarydate__c = Date.today();
            insert ld;
            
            Lead ld1 = AP23_TestDataFactory.createLead(1)[0];
            ld.Diarydate__c = Date.today();
            ld1.Status = 'Contact Attempted';
            insert ld1;
            
            Group g = new Group(type='Queue', Name='S- EU 0-7 Sales Team');
            insert g;
            
            Sales_Agent_Attributes__c saa = new Sales_Agent_Attributes__c(Sales_Rep__c = UserInfo.getUserId(), Team__c = ApplicationConstant.UK_AND_IRELAND_9_TEAM, Product_Knowledge__c=ApplicationConstant.COUNTRY_ENGLAND_WALES, Online__c = true);
            insert saa;
            
            GroupMember GM = new GroupMember(GroupId = g.Id, UserOrGroupId = u.Id);
            insert GM; 
            
            Event t = new Event(Subject = 'Call Back Request', DurationInMinutes = 20, StartDateTime = Date.Today());
            insert t;
            
            Case cse = AP23_TestDataFactory.createCase(1, acc)[0];
            cse.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Case').getRecordTypeId();
            cse.Origin  = 'Email';
            cse.First_Contact_Resolved__c = true;
            cse.NoOfUpdates__c = 5;
            cse.Opportunity__c = oppList[0].Id;
            insert cse;
        }
        
    }
    */

  private static testMethod void test() {
        
        SalesManagerDashboardController con = new SalesManagerDashboardController();
        Test.startTest();
            con.filterPicklist = 'All Teams';
            con.changeFilter();
            con.filterPicklist = 'S- EU 0-7 Sales Team';
            con.changeFilter();
            con.filterPicklist = 'S- EU 8+ Sales Team';
            con.changeFilter();
            con.filterPicklist = 'S- Live Agent';
            con.changeFilter();
        Test.stopTest();
        System.assertEquals(false, con.NoUser);
        
  }
  
  private static testMethod void test2() {
      SalesManagerDashboardController con = new SalesManagerDashboardController();
        Test.startTest();
            con.filterPicklist = 'S- Returning Traveller';
            con.changeFilter();
            con.filterPicklist = 'S- ROW-Long Haul Sales Team';
            con.changeFilter();
            con.filterPicklist = 'S- ROW-Mid Haul Sales Team';
            con.changeFilter();
            con.filterPicklist = 'S- Specialist Sales Team';
            con.changeFilter();
        Test.stopTest();
        System.assertEquals(false, con.NoUser);
  }
  
  private static testMethod void test3() {
      SalesManagerDashboardController con = new SalesManagerDashboardController();
        Test.startTest();
            con.filterPicklist = 'S- UK 0-8 Sales Team';
            con.changeFilter();
            con.filterPicklist = 'S- UK 9+ Sales Team';
            con.changeFilter();
            con.filterPicklist = 'S- Unknown Leads Sales Team';
            con.changeFilter();
            con.filterPicklist = 'test Exception';
            con.changeFilter();
        Test.stopTest();
        System.assertEquals(false, con.NoUser);
  }

}