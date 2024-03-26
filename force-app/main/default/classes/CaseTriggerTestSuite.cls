/*
Name:  CaseTriggerTestSuite.cls
Copyright © 2014  CloudMethods
======================================================
======================================================
Purpose:
-------

Test suite for Trigger Handler class CaseTriggerHandler.cls

Coverage for classes below (target 85%):
CaseTriggerHandler.cls : 91%

Future enhancements:
1. Additional negative test cases.
2. Restricted user tests cases (Handler class runs with sharing - User Role tests to be applied).

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2014-05-21  Initial development.
1.1  Mark Cane&    2014-05-28  singleTestCase2&3, bulkTestCase2&3 added.
1.2  Mark Cane&    2015-09-10  Moved bulk tests to CaseTriggerBulkTestSuite.cls.
1.3  Mark Cane&    2016-12-23  singleTestCase1 fix - forced assignment rule execution on update.
1.4  Mark Cane&    2017-02-28  bulksingleTestCase4TestCase4, negativeTestCase2 commented-out - Salesforce_Support RT no longer exists.
*/
@isTest
private class CaseTriggerTestSuite {
	private static Id pricingCaseRTId;
    /*
    Test cases:
        singleTestCase1 - processPricingCaseAssignmentRules standard course test.
        singleTestCase2 - checkPricingCaseEntitlementSet standard course test.
        singleTestCase3 - managePricingCaseMilestoneStatus standard cource test.  
        1.4 commented-out - singleTestCase4 - processExternalSalesforceSupportCases standard cource test.
        ...
        negativeTestCase1 - processPricingCaseAssignmentRules negative test. 
		1.4 commented-out - negativeTestCase2 - processExternalSalesforceSupportCases negative test.               
		...
        restrictedUserTestCase1 - tbd.
    */
    
    /* **/
    static testMethod void singleTestCase1() {
        // Test Case 1 : processPricingCaseAssignmentRules standard course test.
        //Steps. Create a Pricing case, set to assigned to pricing, test that ownership has changed.        
        setup();
        
        User u;
        System.runAs(new User(Id=UserInfo.getUserId())){        	
        	u = UserTestHelper.createStandardUsers(1, 'John', 'Smith')[0];	
        }
        
        Case c;
		System.runAs(u){
        	c = CaseTestHelper.createSimpleCase(false);
        	c.RecordTypeId=pricingCaseRTId;
        	insert c;
		}
		
		c = [select Id, OwnerId from Case where Id=:c.Id];		
		System.assertEquals(u.Id, c.OwnerId, 'Case Owner must be the test User');
        
		c.Status = AppConstants.CASE_STATUS_ASSIGNED_TO_PRICING;
		
		System.assertEquals(1, [select count() from AssignmentRule where SobjectType = 'Case' and Active = true], 'No active Case Assignment Rules');

		Database.DMLOptions dmlOpts = new Database.DMLOptions();
		dmlOpts.assignmentRuleHeader.assignmentRuleId = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1].Id;
		c.setOptions(dmlOpts);
		                
		System.runAs(u){		                
	        Test.startTest();
			update c;	
	        Test.stopTest();            
		}
		    
		c = [select Id, OwnerId, RecordTypeId, Status from Case where Id=:c.Id];
		System.debug(LoggingLevel.ERROR, c);		
		System.assertNotEquals(u.Id, c.OwnerId, 'Case Owner should not be the test User');  		
					
		String ownerIdPrefix = c.OwnerId;
		System.assertEquals(AppConstants.ID_PREFIX_QUEUE, ownerIdPrefix.left(3), 'Case Owner should be a Queue');		 
    }
    /* */
    
    /* **/
	@isTest(SeeAllData=true)
    static void singleTestCase2() {
        // Test Case 2 : checkPricingCaseEntitlementSet standard course test.        
        //Steps. Create an Account and Entitlement, then create a Pricing Case without the Entitlement, check the trigger sets this.
        //Note. This test case requires seeAllData=true as entitlement process can't be created in Apex code.        
        setup();
                
        Account a = AccountTestHelper.createAccounts(1, 'Son Parto Resort')[0];

		SlaProcess sla = [select Id from SlaProcess where Name=:AppConstants.ENTITLEMENT_PROCESS_NAME_PRICING_SLA];
        
        Entitlement e = new Entitlement(AccountId=a.Id, Name='Unit Test Entitlement', SlaProcessId=sla.Id);
        insert e;
        
		Case c = CaseTestHelper.createSimpleCase(false);
		c.RecordTypeId=pricingCaseRTId;
        c.AccountId=a.Id;        
        
        Test.startTest();
        insert c;
       	Test.stopTest();
       	
       	c = [select Id, EntitlementId from Case where Id=:c.Id];
       	System.assertEquals(e.Id, c.EntitlementId, 'Trigger Code should assign the entitlement to the Case');	 
    }
    /* */

    /* **/
    @isTest(SeeAllData=true)
    static void singleTestCase3() {
        // Test Case 3 : managePricingCaseMilestoneStatus standard cource test.
        //Steps. create an Account and Pricing Case with Entitlement, change status to [Assigned to Case Creator] check clock stops, then set to [Assigned to Pricing] and check clock starts.
        //Note. This test case requires seeAllData=true as entitlement process can't be created in Apex code.
        setup();
        
        Account a = AccountTestHelper.createAccounts(1, 'Son Parto Resort')[0];

		SlaProcess sla = [select Id from SlaProcess where Name=:AppConstants.ENTITLEMENT_PROCESS_NAME_PRICING_SLA];
        
        Entitlement e = new Entitlement(AccountId=a.Id, Name='Unit Test Entitlement', SlaProcessId=sla.Id);
        insert e;
        
		Case c = CaseTestHelper.createSimpleCase(false);
		c.RecordTypeId=pricingCaseRTId;
        c.AccountId=a.Id;  
        c.EntitlementId=e.Id;      
        insert c;
        
		c.Status = AppConstants.CASE_STATUS_ASSIGNED_TO_PRICING;
		CaseTriggerHandler.firstBeforeUpdateRun=true; //& Always explicitly reset static guard vars in a test case - all code runs in the same Apex transaction.
		CaseTriggerHandler.firstAfterUpdateRun=true;
		update c;

		c = [select Id, Status, IsStopped, SlaStartDate from Case where Id=:c.Id];
		System.assert(c.SlaStartDate!=null, 'Case entitlement process start date should be set.');
		System.assert(!c.IsStopped, 'Case entitlement process should not be stopped.');
		
		c.Status = AppConstants.CASE_STATUS_ASSIGNED_TO_CASE_CREATOR;		        
		CaseTriggerHandler.firstBeforeUpdateRun=true;
		CaseTriggerHandler.firstAfterUpdateRun=true;		
		
        Test.startTest();
		update c;
       	Test.stopTest();	 
       	
       	c = [select Id, Status, IsStopped, SlaStartDate from Case where Id=:c.Id];
		System.assert(c.SlaStartDate!=null, 'Case entitlement process start date should be set.');
		System.assert(c.IsStopped, 'Case entitlement process should be stopped.');    
		
		c.Status = AppConstants.CASE_STATUS_ASSIGNED_TO_PRICING;
		CaseTriggerHandler.firstBeforeUpdateRun=true; //& Always explicitly reset static guard vars in a test case - all code runs in the same Apex transaction.
		CaseTriggerHandler.firstAfterUpdateRun=true;
		update c;

		c = [select Id, Status, IsStopped, SlaStartDate from Case where Id=:c.Id];
		System.assert(c.SlaStartDate!=null, 'Case entitlement process start date should be set.');
		System.assert(!c.IsStopped, 'Case entitlement process should not be stopped.');		   	
    }
    /* */    
   
	/* ** /
    static testMethod void singleTestCase4() {
        // Test Case 4 : processExternalSalesforceSupportCases standard course test.
        setup();
        
		Map<String, Id> developerNameToRTId = AppHelper.getRecordTypesByDeveloperName('Case');						
		Id salesforceSupportCaseRTId=developerNameToRTId.get(AppConstants.CASE_RECORD_TYPE_DEVELOPER_NAME_SALESFORCE_SUPPORT);
        
        Case c;
                
        User u;
        System.runAs(new User(Id=UserInfo.getUserId())){        	
        	u = UserTestHelper.createStandardUsers(1, 'John', 'Smith')[0];	
        }
        
        System.runAs(new User(Id=UserInfo.getUserId())){        	      
        
	        c = CaseTestHelper.createSimpleCase(false); // don't insert
	        c.RecordTypeId = salesforceSupportCaseRTId;
	        c.SuppliedEmail = u.Email;
	        
	        Test.startTest();
	        insert c;  
	        Test.stopTest();	        
        }

        System.assertEquals(u.Id, [select Id, Reporter__c from Case where Id=:c.Id].Reporter__c, 'Case reporter field should be set to the user indicated by the SuppliedEmail address');        
    }
    /* */

    /* **/
    static testMethod void negativeTestCase1() {
        // Negative Test Case 1 : processPricingCaseAssignmentRules negative test.
        //Steps. create a Pricing case, set to In Progress status, test that ownership does not change.
        setup();
        
        User u;
        System.runAs(new User(Id=UserInfo.getUserId())){        	
        	u = UserTestHelper.createStandardUsers(1, 'John', 'Smith')[0];	
        }
        
        Case c;
		System.runAs(u){
        	c = CaseTestHelper.createSimpleCase(false);
        	c.RecordTypeId=pricingCaseRTId;
        	insert c;
		}
		
		c = [select Id, OwnerId from Case where Id=:c.Id];		
		System.assertEquals(u.Id, c.OwnerId, 'Case Owner must be the test User');
        
		c.Status = AppConstants.CASE_STATUS_IN_PROGRESS;
		                
        Test.startTest();
		update c;	
        Test.stopTest();            
    
		c = [select Id, OwnerId from Case where Id=:c.Id];		
		System.assertEquals(u.Id, c.OwnerId, 'Case Owner must be the test User');
		System.debug(LoggingLevel.ERROR, c);
    }					
	/* */

    /* ** /
    static testMethod void negativeTestCase2() {
        // Negative test case 2: Inbound Salesforce Support Case sent by User.
		Map<String, Id> developerNameToRTId = AppHelper.getRecordTypesByDeveloperName('Case');						
		Id salesforceSupportCaseRTId=developerNameToRTId.get(AppConstants.CASE_RECORD_TYPE_DEVELOPER_NAME_SALESFORCE_SUPPORT);

        Case c = CaseTestHelper.createSimpleCase(false); // don't insert
        c.RecordTypeId = salesforceSupportCaseRTId;  
        
        Test.startTest();
		insert c;
        Test.stopTest();	        

        System.assertEquals(null, [select Id, Reporter__c from Case where Id=:c.Id].Reporter__c, 'Case reporter field should not be set to a user');       
    }
    /* */ 
	
	/* * /
    static testMethod void restrictedUserTestCase1() {
        // Restricted User Test Case 1 : tbd
        setup();
        
        Test.startTest();

        Test.stopTest();    
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