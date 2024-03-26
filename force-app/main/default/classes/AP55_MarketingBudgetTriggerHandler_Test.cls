/**
* Class Name: AP55_MarketingBudgetTriggerHandler_Test
* @author: A. Dumangas
* @date: 05/28/2016
* @description: Test Class for AP55_MarketingBudgetTriggerHandler
*/

@isTest

public class AP55_MarketingBudgetTriggerHandler_Test {
    static testMethod void testAP55_MarketingBudgetTriggerHandler() {
        //setup org settings
        OrgSettings__c os = new OrgSettings__c();
        os.TriggersActive__c = true;
        database.insert(os);
        
        List<MarketingBudget__c> mbList = AP23_TestDataFactory.createMarketingBudget(3);
        
        test.startTest();
       		database.insert(mbList);
            System.assertEquals(3, [SELECT Count() FROM MarketingBudget__c]);
            
        	mbList[0].Name = 'update test';
        	database.update(mbList);
        	
        	database.delete(mbList);
        	System.assertEquals(0, [SELECT Count() FROM MarketingBudget__c]);
        
        	AP55_MarketingBudgetTriggerHandler handler = new AP55_MarketingBudgetTriggerHandler();
        	handler.OnAfterUpdate(new List<MarketingBudget__c>(), new Map<Id,MarketingBudget__c>(), new List<MarketingBudget__c>(), new Map<Id,MarketingBudget__c>());
        	handler.OnAfterInsert(new List<MarketingBudget__c>(), new Map<Id,MarketingBudget__c>(), new List<MarketingBudget__c>(), new Map<Id,MarketingBudget__c>());
        	handler.OnAfterDelete(new List<MarketingBudget__c>(), new Map<Id,MarketingBudget__c>(), new List<MarketingBudget__c>(), new Map<Id,MarketingBudget__c>());
        test.stopTest();
    }
}