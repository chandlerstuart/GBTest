/**
* Class Name: AP17_QuoteTriggerHandler_Test
* @author: Emman Flores
* @date: 07.05.2016
* @description: Test AP17_QuoteTriggerHandler
*/

@isTest(seeAllData=false)

public class AP17_QuoteTriggerHandler_Test{
       
    static testMethod void testEvents() {
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;  
        //Create List of Quote
        List<Quote__c> quoteList = new List<Quote__c>();
        
        //Create Account
        Account acc = AP23_TestDataFactory.createAccount(1)[0];
        database.insert(acc);

         //Create Opportunity for Cases
        List<Opportunity> oppList = AP23_TestDataFactory.createOpportunity(1,ApplicationConstant.CLOSESALESTAGE, acc);
        insert oppList;
        
        //Create Cases
        Case cas = AP23_TestDataFactory.createCase(1,acc)[0];
        cas.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Case').getRecordTypeId();    
        cas.Opportunity__c = oppList[0].Id;
        database.insert(cas);
        
        //Create Opportunity
        Opportunity opp = AP23_TestDataFactory.createOpportunity(1,'1. Recommendations',acc)[0];
        opp.ServiceAgentAssigned__c = 'Test Agent';
        database.insert(opp);
        
        //Create Quote
        quoteList = AP23_TestDataFactory.createQuote(200, 'Sample Quote', opp, acc);
        
        for(Quote__c qt : quoteList){
            qt.Status__c = 'Accepted';
        }
        
        List<Quote__c> newQuoteMsgList = new List<Quote__c>(quoteList);
        List<Quote__c> oldQuoteMsgList = new List<Quote__c>(quoteList);
        Map<Id,Quote__c> newQuoteMsgMap = new Map<Id,Quote__c>([SELECT Id FROM Quote__c]);
        Map<Id,Quote__c> oldQuoteMsgMap = new Map<Id,Quote__c>([SELECT Id FROM Quote__c]);
        
        test.startTest();
            AP17_QuoteTriggerHandler quotetriggerhandler = new AP17_QuoteTriggerHandler();
            database.insert(quoteList);
            System.assertEquals(200, [SELECT Count() FROM Quote__c]);
            
            database.update(quoteList);
            
            database.delete(quoteList);
            System.assertEquals(0, [SELECT Count() FROM Quote__c]);
            // quotetriggerhandler.OnBeforeInsert(newQuoteMsgList,newQuoteMsgMap,oldQuoteMsgList,oldQuoteMsgMap);
            // quotetriggerhandler.OnBeforeUpdate(newQuoteMsgList,newQuoteMsgMap,oldQuoteMsgList,oldQuoteMsgMap);
            // quotetriggerhandler.OnAfterInsert(newQuoteMsgList,newQuoteMsgMap,oldQuoteMsgList,oldQuoteMsgMap);
            // quotetriggerhandler.OnAfterUpdate(newQuoteMsgList,newQuoteMsgMap,oldQuoteMsgList,oldQuoteMsgMap);
            // quotetriggerhandler.OnBeforeDelete(newQuoteMsgList,newQuoteMsgMap,oldQuoteMsgList,oldQuoteMsgMap);
            // quotetriggerhandler.OnAfterDelete(newQuoteMsgList,newQuoteMsgMap,oldQuoteMsgList,oldQuoteMsgMap);
            quotetriggerhandler.OnAfterUnDelete(newQuoteMsgList,newQuoteMsgMap,oldQuoteMsgList,oldQuoteMsgMap);
            quotetriggerhandler.OnUndelete(newQuoteMsgList,newQuoteMsgMap,oldQuoteMsgList,oldQuoteMsgMap);
        test.stopTest();  
    }
}