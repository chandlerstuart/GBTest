/**
Name:  AP28_ManualLeadAssignmentBatch_Test.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test class for all trigger operations related to Lead Assignment Batch.
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Ivy A     2016-05-03  Initial development.
2.0  CG		   2016-05-04  Improve coverage.	
**/

@isTest
public class AP28_ManualLeadAssignmentBatch_Test {
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
            ld.TravelGroupSize__c = 9;
        }
        database.insert(leadList);
        
        
        
    }
    static testmethod void testAP28_ManualLeadAssignmentBatch() { 
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
        	
        	AP28_ManualLeadAssignmentBatch c = new AP28_ManualLeadAssignmentBatch(new set<Id>{u.Id});
        	Database.executeBatch(c);
        test.stopTest();
    }
    
    static testmethod void testException() {
        User u = [Select Id From User WHERE isActive = true LIMIT 1];
        
        //generate Exception
        List<Lead> leadList = [SELECT Id, LastName, FirstName, Company, Status, LeadSource, Email, Phone, Rating, SalesRegion__c, TravelGroupSize__c, CustomerLifetimeValue__c FROM LEAD ];
        for(Lead ld : leadList){
            ld.Phone = '34';
        }
        
        Map<Id, Sales_Agent_Attributes__c> salesAgentMap = AP27_LeadAssignmentUtility.retrieveSalesAgentAttribute();
        Map<String, String> teamMap = AP27_LeadAssignmentUtility.mapTeamByRegionAndSize(leadList);
        Map<String, List<Id>> leadAgentMatches = AP27_LeadAssignmentUtility.findMatches(leadList, salesAgentMap, teamMap);
        Map<String, List<Id>> teamAgentsMap = AP27_LeadAssignmentUtility.retrieveTeamAgentsMap(salesAgentMap);
        String leadIdentifier = null;

        test.startTest();
        try{
        	AP28_ManualLeadAssignmentBatch c = new AP28_ManualLeadAssignmentBatch(new set<Id>{u.Id});
        	Database.executeBatch(c);            
        }
        catch(Exception e){
            
        }
        test.stopTest();
    }
}