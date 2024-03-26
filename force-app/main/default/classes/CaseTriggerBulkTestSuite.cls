/*
Name: CaseTriggerBulkTestSuite.cls
Copyright © 2015  CloudMethods
======================================================
======================================================
Purpose:
-------

Bulk Test suite for Trigger Handler class CaseTriggerHandler.cls

Coverage for classes below (target 85%):
CaseTriggerHandler.cls : 90%

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2015-09-10  Initial development.
1.1  Mark Cane&    2016-12-23  bulkTestCase1 fix - forced assignment rule execution on update. bulkTestCase3 - fied record count at 100 due to CPU timeout exception.
1.2  Mark Cane&    2017-02-28  bulkTestCase4 commented-out - Salesforce_Support RT no longer exists.
*/
@isTest(SeeAllData=false)
public with sharing class CaseTriggerBulkTestSuite {
	private static Id pricingCaseRTId;
	private static Integer REC_COUNT = 100; //1.2 dropped from 200 to avoid CPU timeout sporadic errors.
	
	/*
    Test cases:	
        ...
        bulkTestCase1 - bulk record test of processPricingCaseAssignmentRules logic.
        bulkTestCase2 - bulk record test of checkPricingCaseEntitlementSet logic.
        bulkTestCase3 - bulk record test of managePricingCaseMilestoneStatus logic..
        ...        
        bulkTestCase4 - Bulk record test of processExternalSalesforceSupportCases logic.
        ...
    */
    
    /* **/
    static testMethod void bulkTestCase1() {
        // Bulk Test Case 1 : bulk record (REC_COUNT) test of the singleTestCase1 logic.
		setup();
        
        User u;
        System.runAs(new User(Id=UserInfo.getUserId())){        	
        	u = UserTestHelper.createStandardUsers(1, 'John', 'Smith')[0];	
        }
        
        List<Case> casesToInsert = new List<Case>();   
        Case cti;     
		System.runAs(u){
			for (Integer i=0; i<REC_COUNT; i++){
				cti = CaseTestHelper.createSimpleCase(false);
				cti.RecordTypeId=pricingCaseRTId;
				casesToInsert.add(cti);
			}
			insert casesToInsert;
		}
		
		System.assertEquals(1, [select count() from AssignmentRule where SobjectType = 'Case' and Active = true], 'No active Case Assignment Rules');

		Database.DMLOptions dmlOpts = new Database.DMLOptions();
		dmlOpts.assignmentRuleHeader.assignmentRuleId = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1].Id;				
				
		List<Case> casesToUpdate = new List<Case>();
		for (Case c : [select Id, OwnerId from Case where Id in:casesToInsert]){
			System.assertEquals(u.Id, c.OwnerId, 'Case Owner must be the test User');	
			c.Status = AppConstants.CASE_STATUS_ASSIGNED_TO_PRICING;
			
			c.setOptions(dmlOpts);
			
			casesToUpdate.add(c);
		}
		
        Test.startTest();
		update casesToUpdate;
        Test.stopTest();   
    
		for (Case c : [select Id, OwnerId from Case where Id in:casesToUpdate]){	
			System.assertNotEquals(u.Id, c.OwnerId, 'Case Owner should not be the test User');  
			System.debug(LoggingLevel.ERROR, c);
			
					
			String ownerIdPrefix = c.OwnerId;
			System.assertEquals(AppConstants.ID_PREFIX_QUEUE, ownerIdPrefix.left(3), 'Case Owner should be a Queue');	
		}
    }
    /* */
    
    /* **/
    @isTest(SeeAllData=true)
    static void bulkTestCase2() {
        // Bulk Test Case 2 : bulk record (REC_COUNT) test of the singleTestCase2 logic.
		setup();
		
		SlaProcess sla = [select Id from SlaProcess where Name=:AppConstants.ENTITLEMENT_PROCESS_NAME_PRICING_SLA];
		
		List<Account> accounts = AccountTestHelper.createAccounts(REC_COUNT, 'Son Parto Resort');

		List<Entitlement> entitlementsToInsert = new List<Entitlement>();	
		List<Case> casesToInsert = new List<Case>();	
		Case cti;    
		
		for (Account a : accounts){
        	entitlementsToInsert.add(new Entitlement(AccountId=a.Id, Name='Unit Test Entitlement', SlaProcessId=sla.Id));
			
			cti = CaseTestHelper.createSimpleCase(false);
			cti.RecordTypeId=pricingCaseRTId;
			cti.AccountId=a.Id;
			casesToInsert.add(cti);        	
		}
        insert entitlementsToInsert;
        
        Test.startTest();
		insert casesToInsert;
       	Test.stopTest();
       	
       	for (Case c : [select Id, EntitlementId from Case where Id in :casesToInsert]){
       		System.assert(c.EntitlementId!=null, 'Trigger Code should assign a entitlement to the Case');			
       	}		
    }
    /* */
    
    /* **/
    @isTest(SeeAllData=true)
    static void bulkTestCase3() {
        // Bulk Test Case 3 : bulk record (REC_COUNT) test of the singleTestCase3 logic.
		setup();
		
		REC_COUNT = 50; //1.2 dropped from 100 to avoid CPU timeout sporadic errors.
		
		SlaProcess sla = [select Id from SlaProcess where Name=:AppConstants.ENTITLEMENT_PROCESS_NAME_PRICING_SLA];
		
		List<Account> accounts = AccountTestHelper.createAccounts(REC_COUNT, 'Son Parto Resort');

		List<Entitlement> entitlementsToInsert = new List<Entitlement>();	
		List<Case> casesToInsert = new List<Case>();	
		Case cti;    
		
		for (Account a : accounts){
        	entitlementsToInsert.add(new Entitlement(AccountId=a.Id, Name='Unit Test Entitlement', SlaProcessId=sla.Id));
			
			cti = CaseTestHelper.createSimpleCase(false);
			cti.RecordTypeId=pricingCaseRTId;
			cti.AccountId=a.Id;
			casesToInsert.add(cti);        	
		}
        insert entitlementsToInsert;        
		insert casesToInsert;
       
       	List<Case> casesToUpdate = new List<Case>();
		for (Case c : [select Id, EntitlementId from Case where Id in :casesToInsert]){
			c.Status = AppConstants.CASE_STATUS_ASSIGNED_TO_PRICING;
			casesToUpdate.add(c);			
		}

		CaseTriggerHandler.firstBeforeUpdateRun=true; //& Always explicitly reset static guard vars in a test case - all code runs in the same Apex transaction.
		CaseTriggerHandler.firstAfterUpdateRun=true;
		update casesToUpdate;

		for (Case c : [select Id, Status, IsStopped, SlaStartDate from Case where Id in :casesToInsert]){		
			System.assert(c.SlaStartDate!=null, 'Case entitlement process start date should be set.');
			System.assert(!c.IsStopped, 'Case entitlement process should not be stopped.');
		}

		casesToUpdate = new List<Case>();
		for (Case c : [select Id, EntitlementId from Case where Id in :casesToInsert]){
			c.Status = AppConstants.CASE_STATUS_ASSIGNED_TO_CASE_CREATOR;
			casesToUpdate.add(c);			
		}

		CaseTriggerHandler.firstBeforeUpdateRun=true; //& Always explicitly reset static guard vars in a test case - all code runs in the same Apex transaction.
		CaseTriggerHandler.firstAfterUpdateRun=true;
		
		Test.startTest();
		update casesToUpdate;
		Test.stopTest();
	
		for (Case c : [select Id, Status, IsStopped, SlaStartDate from Case where Id in :casesToInsert]){		
			System.assert(c.SlaStartDate!=null, 'Case entitlement process start date should be set.');
			System.assert(c.IsStopped, 'Case entitlement process should be stopped.');
		}
    }
    /* */	    
    
 	/* ** /
    static testMethod void bulkTestCase4() {
        // Bulk test case 1: Bulk test of processExternalSalesforceSupportCases logic.
        setup();
		Map<String, Id> developerNameToRTId = AppHelper.getRecordTypesByDeveloperName('Case');						
		Id salesforceSupportCaseRTId=developerNameToRTId.get(AppConstants.CASE_RECORD_TYPE_DEVELOPER_NAME_SALESFORCE_SUPPORT);
        
        Case c;
        List<Case> casesToInsert = new List<Case>();

        List<User> fromUsers;
        System.runAs(new User(Id=UserInfo.getUserId())){        	
        	fromUsers = UserTestHelper.createStandardUsers(REC_COUNT, 'John', 'Smith');	
        }
        
        System.runAs(new User(Id=UserInfo.getUserId())){        	      
        
            for (Integer i=0; i<REC_COUNT; i++){
            	c = CaseTestHelper.createSimpleCase(false); // don't insert
        		c.RecordTypeId = salesforceSupportCaseRTId;
        		c.SuppliedEmail = fromUsers[i].Email;                	
    			casesToInsert.add(c);
    		}

	        Test.startTest();
    		insert casesToInsert;
	        Test.stopTest();	        
        }

        System.assertEquals(REC_COUNT, [select count() from Case where Reporter__c<>null], 'Case reporter field should be set on all records');            
   	}
    /* */
    
	private static void setup(){  	
        OrgSettings__c orgSettings = OrgSettings__c.getInstance( UserInfo.getOrganizationId() );
        if (!orgSettings.TriggersActive__c){        
        	orgSettings.TriggersActive__c = true;  
        	insert orgSettings;
        }
        
        Map<String, Id> developerNameToRTId = AppHelper.getRecordTypesByDeveloperName('Case');						
		pricingCaseRTId=developerNameToRTId.get(AppConstants.CASE_RECORD_TYPE_DEVELOPER_NAME_PRICING);    		        
    }
}