/**
* Class Name: AP01_CaseTriggerHandler_Test
* @author: Emman Flores
* @date: 07.05.2016
* @description: Test Class AP01_CaseTriggerHandler
*/

@isTest(seeAllData=false)

public class AP01_CaseTriggerHandler_Test{
       
    static testMethod void testEvents() {
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = FALSE);
        insert orgSettings;  
        
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        
        //Create List of Case
        List<Case> caseList = new List<Case>();
        
        //Create Account
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        database.insert(acc);
        
        //Create Opportunity for Cases
        Opportunity opp = AP23_TestDataFactory.createOpportunity(1,ApplicationConstant.CLOSESALESTAGE, acc)[0];
        insert opp;
        
        //Create Cases
        caseList = AP23_TestDataFactory.createCase(10,acc);
        for(Case c : caseList){
            c.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Case').getRecordTypeId(); 
            c.Opportunity__c = opp.Id;
            
        }
        
        orgSettings.TriggersActive__c = TRUE;
        update orgSettings;

        List<Case> newCaseList = new List<Case>(caseList);
        List<Case> oldCaseList = new List<Case>(caseList);
        Map<Id,Case> newCaseMap = new Map<Id,Case>([SELECT Id FROM Case]);
        Map<Id,Case> oldCaseMap = new Map<Id,Case>([SELECT Id FROM Case]);
        
        test.startTest();
            AP01_CaseTriggerHandler casetriggerhandler = new AP01_CaseTriggerHandler();
            database.insert(caseList);
            System.assertEquals(10, [SELECT Count() FROM Case]);
            
            database.update(caseList);
            
            database.delete(caseList);
            System.assertEquals(0, [SELECT Count() FROM Case]);
            // casetriggerhandler.OnBeforeInsert(newCaseList,newCaseMap,oldCaseList,oldCaseMap);
            // casetriggerhandler.OnBeforeUpdate(newCaseList,newCaseMap,oldCaseList,oldCaseMap);
            // casetriggerhandler.OnAfterInsert(newCaseList,newCaseMap,oldCaseList,oldCaseMap);
            // casetriggerhandler.OnAfterUpdate(newCaseList,newCaseMap,oldCaseList,oldCaseMap);
            // casetriggerhandler.OnBeforeDelete(newCaseList,newCaseMap,oldCaseList,oldCaseMap);
            // casetriggerhandler.OnAfterDelete(newCaseList,newCaseMap,oldCaseList,oldCaseMap);
            casetriggerhandler.OnAfterUnDelete(newCaseList,newCaseMap,oldCaseList,oldCaseMap);
            casetriggerhandler.OnUndelete(newCaseList,newCaseMap,oldCaseList,oldCaseMap);
        test.stopTest();  
    }
    
    static testMethod void testEvents2() {
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        //Create List of Case
        List<Case> newCaseList = new List<Case>();
        List<Case> oldCaseList = new List<Case>();
        Map<Id,Case> newCaseMap = new Map<Id,Case>();
        Map<Id,Case> oldCaseMap = new Map<Id,Case>();
        
        //Create Account
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        database.insert(acc);
        
        //Create Opportunity
        Opportunity opp = AP23_TestDataFactory.createOpportunity(1,ApplicationConstant.CLOSESALESTAGE, acc)[0];
        insert opp;
        
        //Create Cases
        Case cas = AP23_TestDataFactory.createCase(1,acc)[0];
        cas.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Case').getRecordTypeId();    
        cas.Opportunity__c = opp.Id;
        database.insert(cas);
            
        newCaseList.add(cas);
        newCaseMap.put(cas.Id,cas);
        oldCaseList.add(cas);
        oldCaseMap.put(cas.Id,cas);
        
        test.startTest();
            AP01_CaseTriggerHandler casetriggerhandler = new AP01_CaseTriggerHandler();
            casetriggerhandler.OnBeforeUpdate(newCaseList,newCaseMap,oldCaseList,oldCaseMap);
        test.stopTest();  
    
    }
    
}