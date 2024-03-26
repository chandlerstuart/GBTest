/**************************************************************
@author - Simon Molloy (Golfbreaks)
@date - 24/03/2017
@description - Test class for SalesAgentAttributeBatchUpdate
***************************************************************/
@isTest
private class SalesAgentAttributeBatchUpdate_Test {
    @testSetup
    public static void setup() {
    	List<Sales_Agent_Attributes__c> saaList = new List<Sales_Agent_Attributes__c>();
    	RecordType salesAgentRT = [select Id from RecordType where 
    								DeveloperName = 'Sales_Agent' and SObjectType = 'Sales_Agent_Attributes__c' LIMIT 1];
    	Profile p = [select Id from Profile where Name = 'Golfbreaks Sales User' LIMIT 1];
    	for (User u : [select Id from User where ProfileId = :p.Id and IsActive = TRUE LIMIT 5]){
    		Sales_Agent_Attributes__c saa = new Sales_Agent_Attributes__c();
    		saa.RecordTypeId = salesAgentRT.Id;
    		saa.Sales_Rep__c = u.Id;
    		saa.Online__c = TRUE;
    		saa.CLV_threshold__c = 10;
    		saa.Max_Number_of_Open_Leads_Opportunities__c = 10;
    		saaList.add(saa);
    	}

    	insert saaList;
    }

    static testMethod void testBatchRun() {
    	List<Sales_Agent_Attributes__c> saaList = [select Id, Online__c from Sales_Agent_Attributes__c];
    	system.assertEquals(5, saaList.size());

    	for (Sales_Agent_Attributes__c saa : saaList){
    		system.assertEquals(true, saa.Online__c);
    	}
    	
    	test.startTest();
    		SalesAgentAttributeBatchUpdate saabu = new SalesAgentAttributeBatchUpdate();
    		Id jobId = Database.executeBatch(saabu,5);
    	test.stopTest();

    	saaList = [select Id, Online__c from Sales_Agent_Attributes__c];
    	system.assertEquals(5, saaList.size());

    	for (Sales_Agent_Attributes__c saa : saaList){
    		system.assertEquals(false, saa.Online__c);
    	}
    }

}