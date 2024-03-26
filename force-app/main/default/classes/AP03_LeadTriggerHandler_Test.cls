/**
Name:  AP04_LeadTriggerBL_Test.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test Class for AP04_LeadTriggerBL
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.0  M.Cebrian     2016-05-05   Initial test class development - 85% Code Coverage
2.0  C.Gaylan      2016-05-17   Improve Coverage - 100%
2.1  J Radcliffe   2018-11-08   Null exception correction - Requerying Lead to ensure IsOpen is selected
2.2  Mark Cane&    2018-11-12   Add testSetup block for WIRE calculations on test data.
**/
@isTest
private class AP03_LeadTriggerHandler_Test {

    @testSetup static void setupTestData() {
    
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
        
        WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//<-- 2.2 block WIRE calculations for test data.
        
        List<Lead> lLead = AP23_TestDataFactory.createLead(10);//<-- reduced from 101 to mitigate CPU exceptions.
        insert lLead;
    }
    
    @isTest static void OnBeforeAndAfterInsertTest() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        WorkItemWIREActionIdentifier.isTestInsert = true; //<--2.1
    
        List<Lead> lLead = AP23_TestDataFactory.createLead(10);
        Map<Id, Lead> mapLead = new Map<Id, Lead>();
        for(Lead ix : lLead){
            mapLead.put(ix.Id,  ix);
        }
        
        List<Lead> lLead2 = lLead;
        Map<Id, Lead> mapLead2 = new Map<Id, Lead>();
        for(Lead ix : lLead){
            mapLead2.put(ix.Id,  ix);
        }
        
        Test.startTest();
        AP03_LeadTriggerHandler x = new AP03_LeadTriggerHandler();
        x.OnBeforeInsert(lLead);
        insert lLead;
        
        x.OnAfterInsert(lLead, mapLead, lLead2, mapLead2);
        Test.stopTest();
        // Verify lead items got inserted 
        Integer i = [SELECT COUNT() FROM Lead];
        System.assertEquals(20, i); //10+10
        
    }
    
    
    
    @isTest static void OnBeforeAndAfterUpdateTest() {
    
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        WorkItemWIREActionIdentifier.isTestInsert = true; //<--2.1
    
        List<Lead> lLead = [SELECT Id, RecordTypeId, Account__c, OwnerId, IsOpen__c, GBWire__RouteWorkItem__c FROM Lead];
        Map<Id, Lead> mapLead = new Map<Id, Lead>();
        for(Lead ix : lLead){
            mapLead.put(ix.Id,  ix);
        }
        
        List<Lead> lLead2 = lLead;
        Map<Id, Lead> mapLead2 = new Map<Id, Lead>();
        for(Lead ix : lLead){
            mapLead2.put(ix.Id,  ix);
        }
        
        for(Lead l: lLead){
            l.lastname = 'Test Lead';
        }
        
        Test.startTest();
        AP03_LeadTriggerHandler x = new AP03_LeadTriggerHandler();
        x.OnBeforeUpdate(lLead, mapLead, lLead2, mapLead2);
        update lLead;
        x.OnAfterUpdate(lLead, mapLead, lLead2, mapLead2); 
        Test.stopTest();
        for(Lead l: lLead){
            System.assertEquals('Test Lead',l.lastname);
        }   
    }
    
    @isTest static void OnBeforeAndAfterDeleteTest() {
    
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
    
        List<Lead> lLead = [SELECT Id FROM Lead];
        Map<Id, Lead> mapLead = new Map<Id, Lead>();
        for(Lead ix : lLead){
            mapLead.put(ix.Id,  ix);
        }
        
        List<Lead> lLead2 = [SELECT Id FROM Lead];
        Map<Id, Lead> mapLead2 = new Map<Id, Lead>();
        for(Lead ix : lLead2){
            mapLead2.put(ix.Id,  ix);
        }
        
        Test.startTest();   
        AP03_LeadTriggerHandler x = new AP03_LeadTriggerHandler();
        x.OnBeforeDelete(lLead, mapLead, lLead2, mapLead2);
        delete lLead;
        mapLead.clear();
        lLead2.clear();
        mapLead2.clear();
        x.OnAfterDelete(lLead, mapLead, lLead2, mapLead2);
        Test.stopTest();
        // Verify lead items got deleted
        Integer i = [SELECT COUNT() FROM Lead];
        System.assertEquals(i, 0);
    }
    
    
    @isTest static void OnUnDeleteTest() {
    
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
    
        List<Lead> lLead = [SELECT Id FROM Lead];
        Map<Id, Lead> mapLead = new Map<Id, Lead>();
        for(Lead ix : lLead){
            mapLead.put(ix.Id,  ix);
        }
        
        List<Lead> lLead2 = lLead;
        Map<Id, Lead> mapLead2 = new Map<Id, Lead>();
        for(Lead ix : lLead){
            mapLead2.put(ix.Id,  ix);
        }
        
        delete lLead;
        Test.startTest();
        AP03_LeadTriggerHandler onUnD = new AP03_LeadTriggerHandler();
        onUnD.OnUndelete(lLead, mapLead, lLead2, mapLead2);
        undelete lLead;
        onUnD.OnAfterUnDelete(lLead, mapLead, lLead2, mapLead2);
        Test.stopTest();
        
        Integer i = [SELECT COUNT() FROM Lead];
        System.assertEquals(i, 10);
    }
}