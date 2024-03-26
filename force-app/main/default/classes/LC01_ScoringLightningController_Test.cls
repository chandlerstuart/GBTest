/**
Name:  LC01_ScoringLightningController_Test.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test Class for LC01_ScoringLightningController
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  M.Cebrian  2016-05-02  Initial test class development - 95% coverage.
**/
@isTest
private class LC01_ScoringLightningController_Test {
    
    @testSetup static void setupTestData() {
        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SobjectType='LeadScoringRule__c' AND Name = 'Scoring Rules for Lead' LIMIT 1];
        List<LeadScoringRule__c> leadScoringRulelist = new List<LeadScoringRule__c>();
        for(Integer i=0; i<5; i++){
            LeadScoringRule__c lsr = new LeadScoringRule__c();
            lsr.RecordTypeId = rt.Id;
            lsr.Active__c = true;
            lsr.MaximumValue__c = i;
            lsr.MinimumValue__c = i;
            lsr.Operator__c = 'equals';
            lsr.Points__c = i;
            lsr.Value__c = 'test';
            lsr.RecordType__c = 'Sales Lead';
            leadScoringRulelist.add(lsr);
        }
        
        rt = [SELECT Id,Name FROM RecordType WHERE SobjectType='LeadScoringRule__c' AND Name = 'Scoring Rules for Cases' LIMIT 1];
        for(Integer i=0; i<5; i++){
            LeadScoringRule__c lsr = new LeadScoringRule__c();
            lsr.RecordTypeId = rt.Id;
            lsr.Active__c = true;
            lsr.MaximumValue__c = i;
            lsr.MinimumValue__c = i;
            lsr.Operator__c = 'equals';
            lsr.Points__c = i;
            lsr.Value__c = 'test';
            lsr.RecordType__c = 'Service Case';
            leadScoringRulelist.add(lsr);
        }
        insert leadScoringRulelist;
    }
    
    @isTest static void validateGetMethods() {
        
        Test.startTest();
        LC01_ScoringLightningController.ReturnItem ri = new LC01_ScoringLightningController.ReturnItem();
        
        ri = LC01_ScoringLightningController.getLeadScoringRules('Lead');
        system.assertEquals(200,ri.statusCode);
        ri = LC01_ScoringLightningController.getLeadScoringRules('Case');
        system.assertEquals(200,ri.statusCode);
        ri = LC01_ScoringLightningController.getLeadScoringRules(null);
        system.assertEquals(400,ri.statusCode);
        
        ri = LC01_ScoringLightningController.getfieldInformation('Case');
        system.assertEquals(200,ri.statusCode);
        ri = LC01_ScoringLightningController.getfieldInformation('Lead');
        system.assertEquals(200,ri.statusCode);
        ri = LC01_ScoringLightningController.getfieldInformation(null); //invokes error
        system.assertEquals(400,ri.statusCode);
        
        ri = LC01_ScoringLightningController.getRecordTypeInformation('Case');
        system.assertEquals(200,ri.statusCode);
        ri = LC01_ScoringLightningController.getRecordTypeInformation('Test'); //invokes error
        system.assertEquals(400,ri.statusCode);
        ri = LC01_ScoringLightningController.getRecordTypeInformation(null); //invokes error
        system.assertEquals(400,ri.statusCode);
        Test.stopTest();
        
    }
    
    @isTest static void validatePostMethods() {
        
        List<LeadScoringRule__c> leadslist = [SELECT Id,Name,Active__c,FieldLabel__c,Operator__c,RecordTypeId,RecordType__c,Value__c,Points__c,MinimumValue__c,MaximumValue__c FROM 
                                              LeadScoringRule__c];
        leadslist[0].Active__c = true;
        leadslist[0].MaximumValue__c = 16;
        leadslist[0].MinimumValue__c = 16;
        leadslist[0].Operator__c = 'contains'; 
        leadslist[0].Points__c = 16;
        leadslist[0].Value__c = 'test123';
        leadslist[0].RecordType__c = 'Service Case';
        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SobjectType='LeadScoringRule__c' AND Name = 'Scoring Rules for Cases' LIMIT 1];
        
        LeadScoringRule__c lsr = new LeadScoringRule__c();
        lsr.RecordTypeId = rt.Id;
        lsr.Active__c = true;
        lsr.MaximumValue__c = 19;
        lsr.MinimumValue__c = 19;
        lsr.Operator__c = 'contains';
        lsr.Points__c = 19;
        lsr.Value__c = 'test123567';
        lsr.RecordType__c = 'Service Case';
        Test.startTest();
        LC01_ScoringLightningController.ReturnItem ri = new LC01_ScoringLightningController.ReturnItem();
        ri = LC01_ScoringLightningController.updateScoringRule(leadslist[0]);
        system.assertEquals(200,ri.statusCode);
        ri = LC01_ScoringLightningController.updateScoringRule(leadslist[1]);   //invokes error
        system.assertEquals(200,ri.statusCode);
        ri = LC01_ScoringLightningController.updateScoringRule(null);  //invokes error
        system.assertEquals(400,ri.statusCode);
        ri = LC01_ScoringLightningController.saveScoringRule(lsr, 'Case');
        system.assertEquals(200,ri.statusCode);
        ri = LC01_ScoringLightningController.saveScoringRule(null, null); //invokes error
        system.assertEquals(400,ri.statusCode);
        ri = LC01_ScoringLightningController.deleteLeadScoringRules(leadslist[1].Id);
        system.assertEquals(200,ri.statusCode);
        Test.stopTest();
        
    }
}