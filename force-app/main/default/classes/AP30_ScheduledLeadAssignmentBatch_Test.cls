@isTest
public class AP30_ScheduledLeadAssignmentBatch_Test {
    /*@testSetup static void dataSetUp(){
        Profile prof = [SELECT Id FROM Profile WHERE Name='Golfbreaks Sales User'];
        User newUser = new User(Alias = 'standt', Email='meow1@test.com',
                        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = prof.Id, TimeZoneSidKey='America/Los_Angeles', 
                        UserName='meow1@test.com');
        insert newUser;

        RecordType personAccountRecType =  [SELECT Id FROM RecordType WHERE IsPersonType = TRUE and SObjectType = 'Account' LIMIT 1];
        Id SAArecordtypeId = Schema.SObjectType.Sales_Agent_Attributes__c.getRecordTypeInfosByName().get(ApplicationConstant.LEAD_SALES_AGENT).getRecordTypeId();
        
        List<Account> accList = AP23_TestDataFactory.createAccount(1); 
        insert accList;
        
        Account perAccount = new Account( FirstName='Joe', LastName='Schmoe', RecordTypeId = personAccountRecType.Id );
        insert perAccount;
        
        Contact perContact = [SELECT Id, Is_PGA__c FROM Contact WHERE AccountId =: perAccount.Id LIMIT 1];
        perContact.Is_PGA__c = TRUE;
        update perContact;
        
        List<Opportunity> oppList = AP23_TestDataFactory.createOpportunity(1, 'Prospecting', accList[0]);
        insert oppList;
        
        List<Sales_Agent_Attributes__c> lSAA = new List<Sales_Agent_Attributes__c>();
        Sales_Agent_Attributes__c saa01 = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Product_Knowledge__c = 'USA', 
                                                                      Team__c = 'S- EU 8+ Sales Team', Current_Number_of_Open_Leads_Opps__c = 1, 
                                                                      Max_Number_of_Open_Leads_Opportunities__c = 3, Min_CLV_Threshold__c = 0,
                                                                      CLV_threshold__c = 10, Sales_Rep__c = UserInfo.getUserId(), RecordTypeId = SAArecordtypeId); 
        lSAA.add(saa01);  
                                                                 
        insert lSAA;
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE PersonContactId = NULL LIMIT 1];
        List<Lead> lLead = new List<Lead>();
        Lead l01 = new Lead(LastName = 'Test Lead 01', FirstName = 'First', Status = 'New', Diarydate__c = System.Today(), LeadSource = 'Event', 
                            Email = 'meow01@test.com', CountriesInterested__c = 'USA', Rating = 'Warm', Company='company',
                            SalesRegion__c = ApplicationConstant.SALESREGIONGROUP_EUROPE, TravelGroupSize__c = 8, CustomerLifetimeValue__c = 5, 
                            AssignedtoSAA__c = false, IsConverted = false);
        lLead.add(l01);
        
        insert lLead;
    }
    
    @isTest static void testBatchSched(){       
        test.startTest();
        AP30_ScheduledLeadAssignmentBatch ap = new AP30_ScheduledLeadAssignmentBatch();
        List<Lead> ldList = [SELECT Id, FirstName, LastName, Company, Status, Email, Phone, Rating, SalesRegion__c, CountriesInterested__c, TravelGroupSize__c, Owner.Name, Owner.Id, AssignedtoSAA__c FROM Lead LIMIT 122];
        Database.executeBatch(ap);
        test.stopTest();      
        
        List<Lead> ldListUpdated = [SELECT Id, Owner.Name FROM LEAD ORDER BY CreatedDate LIMIT 122];
        System.assertEquals(1, ldListUpdated.size());
        for(Lead ld : ldListUpdated){
            // System.assertEquals(ApplicationConstant.UK_AND_IRELAND_0_8_TEAM, ld.Owner.Name);
        }
    } */
    
     @testSetUp static void createData(){
        User u = [Select Id From User WHERE isActive = true LIMIT 1];
        
        //Sales Agent Attribute
        List<Sales_Agent_Attributes__c> saa = AP23_TestDataFactory.createSalesAgentAttribute(1, u);
        saa[0].recordTypeId = [Select Id From RecordType Where SObjectType = 'Sales_Agent_Attributes__c' AND Name =: ApplicationConstant.LEAD_SALES_AGENT].Id;
        database.insert(saa);
        
        //Lead
    	List<Lead> leadList = AP23_TestDataFactory.createLead(200);
        for(Lead ld: leadList){
            ld.OwnerId = u.id;
            ld.SalesRegion__c =  ApplicationConstant.SALESREGIONGROUP_EUROPE;
            ld.TravelGroupSize__c = 8;
        }
        database.insert(leadList);
        
        
        
    }
    static testmethod void testAP30_ScheduledLeadAssignmentBatch() { 
        //user
        User u = [Select Id From User WHERE isActive = true LIMIT 1];
        List<Lead> leadList = [SELECT Id, LastName, FirstName, Company, Status, LeadSource, Email, Phone, Rating, SalesRegion__c, TravelGroupSize__c, CustomerLifetimeValue__c FROM LEAD LIMIT 200];
        Map<Id, Sales_Agent_Attributes__c> salesAgentMap = AP27_LeadAssignmentUtility.retrieveSalesAgentAttribute();
        Map<String, String> teamMap = AP27_LeadAssignmentUtility.mapTeamByRegionAndSize(leadList);
        Map<String, List<Id>> leadAgentMatches = AP27_LeadAssignmentUtility.findMatches(leadList, salesAgentMap, teamMap);
        Map<String, List<Id>> teamAgentsMap = AP27_LeadAssignmentUtility.retrieveTeamAgentsMap(salesAgentMap);
        String leadIdentifier = leadList[0].LastName+leadList[0].FirstName+leadList[0].Company+leadList[0].Status+leadList[0].LeadSource+leadList[0].Email+leadList[0].Phone+leadList[0].Rating+leadList[0].SalesRegion__c+leadList[0].Id;
        
        system.debug(teamAgentsMap.containsKey(teamMap.get(leadIdentifier)));
        
        test.startTest();
        	
        	AP30_ScheduledLeadAssignmentBatch c = new AP30_ScheduledLeadAssignmentBatch();
        	Database.executeBatch(c, 200);
        test.stopTest();
    }
    
    static testmethod void testJustBatch(){
        Group grp = [select Id from Group where Name = :ApplicationConstant.EUROPE_8_TEAM LIMIT 1];
        List<Lead> leadList = AP23_TestDataFactory.createLead(200);
        for (Lead l : leadList){
            l.SalesRegion__c =  ApplicationConstant.SALESREGIONGROUP_EUROPE;
            l.TravelGroupSize__c = 9;
            l.AssignedtoSAA__c  = false;
            l.OwnerId = grp.Id;
            l.LastName = 'JustBatch';
        }

        insert leadList;

        test.startTest();
            AP30_ScheduledLeadAssignmentBatch c = new AP30_ScheduledLeadAssignmentBatch();
            Database.executeBatch(c, 200);
        test.stopTest();

    }

    static testmethod void testError() { 
        //user
        User u = [Select Id From User WHERE isActive = true LIMIT 1];
      
        List<Lead> leadList = [SELECT Id, LastName, FirstName, Company, Status, LeadSource, Email, Phone, Rating, SalesRegion__c, TravelGroupSize__c, CustomerLifetimeValue__c FROM LEAD ];
        Map<Id, Sales_Agent_Attributes__c> salesAgentMap = AP27_LeadAssignmentUtility.retrieveSalesAgentAttribute();
        Map<String, String> teamMap = AP27_LeadAssignmentUtility.mapTeamByRegionAndSize(leadList);
        Map<String, List<Id>> leadAgentMatches = AP27_LeadAssignmentUtility.findMatches(leadList, salesAgentMap, teamMap);
        Map<String, List<Id>> teamAgentsMap = AP27_LeadAssignmentUtility.retrieveTeamAgentsMap(salesAgentMap);
        String leadIdentifier = leadList[0].LastName+leadList[0].FirstName+leadList[0].Company+leadList[0].Status+leadList[0].LeadSource+leadList[0].Email+leadList[0].Phone+leadList[0].Rating+leadList[0].SalesRegion__c+leadList[0].Id;
        
        system.debug(teamAgentsMap.containsKey(teamMap.get(leadIdentifier)));
        
        test.startTest();
        	
        	AP30_ScheduledLeadAssignmentBatch c = new AP30_ScheduledLeadAssignmentBatch();
        	Database.executeBatch(c);
        test.stopTest();
    }
}