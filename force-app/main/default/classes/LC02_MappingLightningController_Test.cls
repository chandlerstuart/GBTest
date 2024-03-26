/**
Name:  LC02_MappingLightningController_Test.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test Class for LC02_MappingLightningController
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  M.Cebrian  2016-05-02  Initial test class development - 88% coverage.
**/
@isTest
private class LC02_MappingLightningController_Test {

	@testSetup static void setupTestData() {
	    
        List<LeadScoreMapping__c> leadScoreMappinglist = new List<LeadScoreMapping__c>();
        for(Integer i=0; i<5; i++){
            LeadScoreMapping__c lsm = new LeadScoreMapping__c();
            lsm.RuleType__c = 'Lead';
            lsm.LeadRating__c = 'Warm';
            lsm.LeadScoreMaximumValue__c = i;
            lsm.LeadScoreMinimumValue__c = i;
            lsm.CasePriority__c = 'P1';
            leadScoreMappinglist.add(lsm);
        }
        for(Integer i=0; i<5; i++){
            LeadScoreMapping__c lsm = new LeadScoreMapping__c();
            lsm.RuleType__c = 'Case';
            lsm.LeadRating__c = 'Warm';
            lsm.LeadScoreMaximumValue__c = i;
            lsm.LeadScoreMinimumValue__c = i;
            lsm.CasePriority__c = 'P1';
            leadScoreMappinglist.add(lsm);
        }
        insert leadScoreMappinglist;
    }
	
	@isTest static void validateGetMethods() {
	    
	    Test.startTest();
	        LC02_MappingLightningController.ReturnItem ri = new LC02_MappingLightningController.ReturnItem();
	        ri = LC02_MappingLightningController.getScoreMappings('Case');
	        system.assertEquals(200,ri.statusCode);
	    Test.stopTest();
	    
	}
	
	@isTest static void validatePostMethods() {
	    
	    List<LeadScoreMapping__c> lsmLeadsList = [SELECT Id, Name, RuleType__c, LeadRating__c, LeadScoreMaximumValue__c, LeadScoreMinimumValue__c, CasePriority__c  
                   FROM LeadScoreMapping__c
                   Where RuleType__c = 'Lead'];
	     LeadScoreMapping__c lsm = new LeadScoreMapping__c();
            lsm.RuleType__c = 'Case';
            lsm.LeadRating__c = 'Warm';
            lsm.LeadScoreMaximumValue__c = 123;
            lsm.LeadScoreMinimumValue__c = 123;
            lsm.CasePriority__c = 'P3';
            
	    Test.startTest();
	        LC02_MappingLightningController.ReturnItem ri = new LC02_MappingLightningController.ReturnItem();
	        
	        ri = LC02_MappingLightningController.saveScoreMapping(lsm);
	        system.assertEquals(200,ri.statusCode);
	        
	        ri = LC02_MappingLightningController.deleteLeadScoreMapping(lsmLeadsList[0].id);
	        system.assertEquals(200,ri.statusCode);
	        
	    Test.stopTest();
	    
	}
    @isTest static void invokeErrors() {
	    
	    List<LeadScoreMapping__c> lsmLeadsList = [SELECT Id, Name, RuleType__c, LeadRating__c, LeadScoreMaximumValue__c, LeadScoreMinimumValue__c, CasePriority__c  
	                   FROM LeadScoreMapping__c
	                   Where RuleType__c = 'Lead'];
	        List<LeadScoreMapping__c> lsmCaseList = [SELECT Id, Name, RuleType__c, LeadRating__c, LeadScoreMaximumValue__c, LeadScoreMinimumValue__c, CasePriority__c  
	                   FROM LeadScoreMapping__c
	                   Where RuleType__c = 'Case'];
		     LeadScoreMapping__c lsm = new LeadScoreMapping__c();
	            lsm.RuleType__c = 'Case';
	            lsm.LeadRating__c = 'Warm';
	            lsm.LeadScoreMaximumValue__c = 123;
	            lsm.LeadScoreMinimumValue__c = 123;
	            lsm.CasePriority__c = 'P3';
	            
		    Test.startTest();
		        LC02_MappingLightningController.ReturnItem ri = new LC02_MappingLightningController.ReturnItem();
		        
		        ri = LC02_MappingLightningController.saveScoreMapping(lsm);
		        system.assertEquals(200,ri.statusCode);
		        ri = LC02_MappingLightningController.saveScoreMapping(null); //invokes error
		        system.assertEquals(400,ri.statusCode);
		        ri = LC02_MappingLightningController.saveScoreMapping(lsmCaseList[0]); //invokes error
		        system.assertEquals(400,ri.statusCode);
		        ri = LC02_MappingLightningController.deleteLeadScoreMapping(null);
		        system.assertEquals(400,ri.statusCode);
		        ri = LC02_MappingLightningController.saveScoreMapping(lsmCaseList[1]); //invokes error
		        system.assertEquals(400,ri.statusCode);
		        ri = LC02_MappingLightningController.deleteLeadScoreMapping(lsmLeadsList[0].id);
		        system.assertEquals(200,ri.statusCode);
		        ri = LC02_MappingLightningController.saveScoreMapping(lsmLeadsList[0]); //invokes error
		        system.assertEquals(400,ri.statusCode);
		    Test.stopTest();
	    
	}
}