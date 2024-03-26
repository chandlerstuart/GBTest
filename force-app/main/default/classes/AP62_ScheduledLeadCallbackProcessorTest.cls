/*
Name:  AP62_ScheduledLeadCallbackProcessorTest.cls
Copyright © 2016  Golfbreaks
======================================================
======================================================
Purpose:
-------

Test suite for Trigger Handler class AP62_ScheduledLeadCallbackProcessorBatch.cls

Coverage for classes below (target 85%):
AP62_ScheduledLeadCallbackProcessorBatch.cls : 93%

Todo :
Scheduling unit tests
System testing
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2016-11-30  Initial development.
1.1  Mark Cane&    2016-12-05  Added singleTestCase6/7.
*/
@isTest
private class AP62_ScheduledLeadCallbackProcessorTest {
	
	private static final String CALLBACK_QUEUE_NAME = 'S- Callback Leads';
	private static final String CALLBACK_QUEUE_DEVELOPER_NAME = 'S_Callback_Leads'; // Move constants to ApplicationConstant.cls
	private static final String LEAD_SOURCE_WEBFORM_CALLBACK = 'Web Callback';
	
	/*
    Test cases:
        singleTestCase1 - ApexTrigger. New Webform Callback lead - route to Holding Queue.
        singleTestCase2 - BatchApex. Webform Callback lead - release from Holding Queue and SAA assign.
        singleTestCase3 - BatchApex. Webform Callback lead - Check_Is_Queue_Assigned__c+Notification_User_Ids__c - RULE 1 : notification.
		singleTestCase4 - BatchApex. Webform Callback lead - Agent_Call_Back_Date_Time__c+Notify_Owner__c - RULE 2 : notification.
        singleTestCase5 - ScheduledApex. Scheduling test.
		singleTestCase6 - BatchApex. Webform Callback lead - Agent_Call_Back_Date_Time__c+Notify_Owner_Manager__c - RULE 3 : manager notification.
		singleTestCase7 - BatchApex. Webform Callback lead - Agent_Call_Back_Date_Time__c+Notify_Owner_Manager__c - RULE 4 : minus minutes notification.
        ...
        negativeTestCase1 - ApexTrigger. New Webform Non-Callback lead - do not route to Holding Queue.
        negativeTestCase2 - ApexTrigger. New Phone Callback lead - do not route to Holding Queue.
        negativeTestCase3 - BatchApex. Webform Callback lead - no early release from Holding Queue.
		negativeTestCase4 - BatchApex. Leads outside of the -15+60 window are not processed.
		negativeTestCase5 - BatchApex. Webform Callback lead - no notifications where Agent has called. 
		...
        bulkTestCase1 - tbd.
		...
        restrictedUserTestCase1 - tbd.
    */

	/* **/
	@testSetup static void setup(){
	
		List<User> users;
		System.runAs(new User(Id=UserInfo.getUserId())){
			users = UserTestHelper.createStandardUsers(2, 'Jo', 'Williams');
		}
						
		List<SObject> settings = new List<SObject>();

		CustomerCallbackNotificationListSetting__c ns;	
		ns = new CustomerCallbackNotificationListSetting__c();									
		ns.Elapsed_Minutes__c=15;
		ns.Notification_User_Ids__c=users[0].Id+'|'+users[1].Id;						
		ns.Notify_Owner__c = false; 
		ns.Check_Is_Queue_Assigned__c = true;
		ns.Notification_Subject__c = 'first alert';
		ns.Notification_Body__c = 'first alert';
		ns.Name = 'RULE 1 : first alert';
		settings.add(ns);

		ns = new CustomerCallbackNotificationListSetting__c();									
		ns.Elapsed_Minutes__c=30;							
		ns.Notify_Owner__c = true; 
		ns.Check_Is_Queue_Assigned__c = false;
		ns.Notification_Subject__c = 'second alert';
		ns.Notification_Body__c = 'second alert';
		ns.Name = 'RULE 2 : second alert';
		settings.add(ns);

		ns = new CustomerCallbackNotificationListSetting__c();									
		ns.Elapsed_Minutes__c=45;							
		ns.Notify_Owner_Manager__c = true; 
		ns.Check_Is_Queue_Assigned__c = false;
		ns.Notification_Subject__c = 'third alert';
		ns.Notification_Body__c = 'third alert';
		ns.Name = 'RULE 3 : third alert';
		settings.add(ns);
		
		ns = new CustomerCallbackNotificationListSetting__c();									
		ns.Elapsed_Minutes__c=-15;							
		ns.Notify_Owner__c = true;
		ns.Notify_Owner_Manager__c = true;  
		ns.Check_Is_Queue_Assigned__c = false;
		ns.Notification_Subject__c = 'on assignment alert';
		ns.Notification_Body__c = 'on assignment alert';
		ns.Name = 'RULE 4 : on assignment alert';
		settings.add(ns);
		
		insert settings;
		

        OrgSettings__c orgSettings = OrgSettings__c.getInstance( UserInfo.getOrganizationId() );
    	orgSettings.TriggersActive__c = true;  
    	upsert orgSettings Id;
    	
    	
    	// required to avoid soql query error in Class.LC05_OutboundMessageCreator.buildEnquiryClientRequestWrapper: line 64.
        insert AP23_TestDataFactory.getCustomSettingObjectFieldMapping();

        
		Id SAArecordtypeId = Schema.SObjectType.Sales_Agent_Attributes__c.getRecordTypeInfosByName().get('Sales Agent').getRecordTypeId();

        List<Sales_Agent_Attributes__c> saa = new List<Sales_Agent_Attributes__c>();
        saa.add(new Sales_Agent_Attributes__c(recordTypeId = SAArecordtypeId, 
        			Sales_Rep__c = users[1].Id, Current_Number_of_Open_Leads_Opps__c = 1, 
        			Online__c = true, Product_Knowledge__c = 'Scotland',
        			Team__c = 'S- UK 0-8 Sales Team'));
        insert saa;
        
        
        TeamTravelGroupSize__c teamSetting = new TeamTravelGroupSize__c();
        teamSetting.Name = 'S- UK 0-8 Sales Team';
        teamSetting.Maximum_Size__c = 0;
        teamSetting.Minimum_Size__c = 8;
        teamSetting.Region_Name__c = 'Europe';        
        insert teamSetting;
	}
	/* */
	
	/* **/
	static testMethod void singleTestCase1(){
		// Test Case 1 : ApexTrigger. New Webform Callback lead - route to Holding Queue.
		
		Id apiUserId = [select Id, Name from User where Name=:ApplicationConstant.USER_NAME_API_USER][0].Id;				
		Id callBackQueueId = [select Id from Group where DeveloperName=:CALLBACK_QUEUE_DEVELOPER_NAME and Type='Queue'][0].Id;

		Lead l = AP23_TestDataFactory.createLead(1)[0];
		
		l.LeadSource = LEAD_SOURCE_WEBFORM_CALLBACK;
		l.TravelGroupSize__c = 8;
		l.CountriesInterested__c = 'Scotland';
		l.Customer_Call_Back_Date_Time__c = Datetime.now().addHours(1);		
		l.OwnerId=apiUserId;
		
		Test.startTest();
		insert l;
		Test.stopTest();
		
		System.assertEquals(callBackQueueId, [select Id, OwnerId from Lead where Id=:l.Id].OwnerId, 'Lead should be assigned to the Callback Queue.');
	}
	/* */
	
	/* **/
	static testMethod void singleTestCase2(){
		// Test Case 2 : BatchApex. Webform Callback lead - release from Holding Queue and SAA assign.
		
		Id apiUserId = [select Id, Name from User where Name=:ApplicationConstant.USER_NAME_API_USER][0].Id;				
		Id callBackQueueId = [select Id from Group where DeveloperName=:CALLBACK_QUEUE_DEVELOPER_NAME and Type='Queue'][0].Id;

		Lead l = AP23_TestDataFactory.createLead(1)[0];
		
		l.LeadSource = LEAD_SOURCE_WEBFORM_CALLBACK;
		l.TravelGroupSize__c = 8;
		l.CountriesInterested__c = 'Scotland';
		l.Customer_Call_Back_Date_Time__c = Datetime.now().addMinutes(15);	
		l.OwnerId=apiUserId;
		l.Rating = ApplicationConstant.LEAD_RATING_WARM;
		insert l;
		
		System.assertEquals(callBackQueueId, [select Id, OwnerId from Lead where Id=:l.Id].OwnerId, 'Lead should be assigned to the Callback Queue.');
		
		Test.startTest(); // collect async processes.		
		Database.executeBatch(new AP62_ScheduledLeadCallbackProcessorBatch(), 100);
		Test.stopTest(); // execute async processes.
		
		System.assertNotEquals(callBackQueueId, [select Id, OwnerId from Lead where Id=:l.Id].OwnerId, 'Lead should not be assigned to the Callback Queue.');		
	}
	/* */

	/* **/
	static testMethod void singleTestCase3(){
		// Test Case 3 : BatchApex. Webform Callback lead - Check_Is_Queue_Assigned__c+Notification_User_Ids__c - notification.
		
		Id apiUserId = [select Id, Name from User where Name=:ApplicationConstant.USER_NAME_API_USER][0].Id;				
		Id callBackQueueId = [select Id from Group where DeveloperName=:CALLBACK_QUEUE_DEVELOPER_NAME and Type='Queue'][0].Id;

		Lead l = AP23_TestDataFactory.createLead(1)[0];
		
		l.LeadSource = LEAD_SOURCE_WEBFORM_CALLBACK;
		l.TravelGroupSize__c = 8;
		l.CountriesInterested__c = 'Scotland';
		l.Customer_Call_Back_Date_Time__c = Datetime.now().addMinutes(15);	
		l.OwnerId=apiUserId;
		l.Rating = ApplicationConstant.LEAD_RATING_WARM;
		insert l;
		
		System.assertEquals(callBackQueueId, [select Id, OwnerId from Lead where Id=:l.Id].OwnerId, 'Lead should be assigned to the Callback Queue.');
		
		// Reset recursion guard vars.
		AP03_LeadTriggerHandler.isBeforeUpdateTriggerCalled = false;
    	AP03_LeadTriggerHandler.isBeforeInsertTriggerCalled = false;
    	AP03_LeadTriggerHandler.isAfterUpdateTriggerCalled = false;
    	AP03_LeadTriggerHandler.isAfterInsertTriggerCalled = false;		

    	AP04_LeadTriggerBL.firstRun = true;
    	AP04_LeadTriggerBL.comesFromInsert = false;
	    AP04_LeadTriggerBL.isBeforeUpdateTriggerCalled = false;
	    AP04_LeadTriggerBL.isBeforeInsertTriggerCalled = false;
	    AP04_LeadTriggerBL.isAfterUpdateTriggerCalled = false;
	    AP04_LeadTriggerBL.isAfterInsertTriggerCalled = false;
	    	    	    
	    l = [select Id, Name, CountriesInterested__c, Account__c, AssignedtoSAA__c, TravelGroupSize__c, LastName,
                       FirstName, Company, Status, LeadSource, Email, Phone, Rating, SalesRegion__c, CustomerLifetimeValue__c,
                       IsLeadAssigned__c, SpecialistSales__c, OwnerId,
                       Customer_Call_Back_Date_Time__c,Agent_Call_Back_Date_Time__c
                       from Lead where Id=:l.Id];
                       
		l.Customer_Call_Back_Date_Time__c = Datetime.now().addMinutes(-15);
		update l;
		
		System.assertEquals(callBackQueueId, [select Id, OwnerId from Lead where Id=:l.Id].OwnerId, 'Lead should be assigned to the Callback Queue.');		
		
      	AP62_ScheduledLeadCallbackProcessorBatch b = new AP62_ScheduledLeadCallbackProcessorBatch();				
							
		Test.startTest(); // collect async processes.		
		Database.executeBatch(b, 100);
		Test.stopTest(); // execute async processes.
				
		System.assertEquals(2,AP62_ScheduledLeadCallbackProcessorBatch.messagesToSendCount,'RULE 1 should send 2 emails.');	      		
	}
	/* */
	
	/* **/
	static testMethod void singleTestCase4(){
		// Test Case 4 : BatchApex. Webform Callback lead - Agent_Call_Back_Date_Time__c+Notify_Owner__c - RULE 2 : notification.
		
		Id apiUserId = [select Id, Name from User where Name=:ApplicationConstant.USER_NAME_API_USER][0].Id;				
		Id callBackQueueId = [select Id from Group where DeveloperName=:CALLBACK_QUEUE_DEVELOPER_NAME and Type='Queue'][0].Id;

		Lead l = AP23_TestDataFactory.createLead(1)[0];
		
		l.LeadSource = LEAD_SOURCE_WEBFORM_CALLBACK;
		l.TravelGroupSize__c = 8;
		l.CountriesInterested__c = 'Scotland';
		l.Customer_Call_Back_Date_Time__c = Datetime.now().addMinutes(-30);	
		l.OwnerId=UserInfo.getUserId();
		l.Rating = ApplicationConstant.LEAD_RATING_WARM;
		insert l;
		
		System.assertEquals(UserInfo.getUserId(), [select Id, OwnerId from Lead where Id=:l.Id].OwnerId, 'Lead should not be assigned to the Callback Queue.');
		
      	AP62_ScheduledLeadCallbackProcessorBatch b = new AP62_ScheduledLeadCallbackProcessorBatch();				
							
		Test.startTest(); // collect async processes.		
		Database.executeBatch(b, 100);
		Test.stopTest(); // execute async processes.
				
		System.assertEquals(1,AP62_ScheduledLeadCallbackProcessorBatch.messagesToSendCount,'RULE 2 should send 1 email to the owner.');
		System.assert(AP62_ScheduledLeadCallbackProcessorBatch.messageRecipientIds.contains(UserInfo.getUserId()),'RULE 3 should send 1 email to the owner.');	      		
	}
	/* */	
	
	/* **/
	static testMethod void singleTestCase5(){
		// Test Case 5 : ScheduledApex. New Webform Callback lead - route to Holding Queue.
		Id apiUserId = [select Id, Name from User where Name=:ApplicationConstant.USER_NAME_API_USER][0].Id;				
		Id callBackQueueId = [select Id from Group where DeveloperName=:CALLBACK_QUEUE_DEVELOPER_NAME and Type='Queue'][0].Id;

		Lead l = AP23_TestDataFactory.createLead(1)[0];
		
		l.LeadSource = LEAD_SOURCE_WEBFORM_CALLBACK;
		l.TravelGroupSize__c = 8;
		l.CountriesInterested__c = 'Scotland';
		l.Customer_Call_Back_Date_Time__c = Datetime.now().addMinutes(15);	
		l.OwnerId=apiUserId;
		l.Rating = ApplicationConstant.LEAD_RATING_WARM;
		insert l;
		
		System.assertEquals(callBackQueueId, [select Id, OwnerId from Lead where Id=:l.Id].OwnerId, 'Lead should be assigned to the Callback Queue.');
		
		Test.startTest();

      	// Schedule the test job
      	String CRON_EXP = Datetime.now().addSeconds(5).format('ss mm HH dd M ? yyyy');
      	
      	String jobId = System.schedule('AP62_ScheduledLeadCallbackProcessorBatch',
                        				CRON_EXP,
                        				new AP62_ScheduledLeadCallbackProcessorBatch());
         
      	// Get the information from the CronTrigger API object
      	CronTrigger ct = [select Id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where Id=:jobId];

      	// Verify the expressions are the same
      	System.assertEquals(CRON_EXP, ct.CronExpression);

      	// Verify the job has not run
      	System.assertEquals(0, ct.TimesTriggered);
		
		Test.stopTest();
		
		// Note - Batchable will not execute so further not testing is not possible.
		//System.assertNotEquals(callBackQueueId, [select Id, OwnerId from Lead where Id=:l.Id].OwnerId, 'Lead should not be assigned to the Callback Queue.');
	}
	/* */	
	
	/* **/
	static testMethod void singleTestCase6(){
		// Test Case 6 : BatchApex. Webform Callback lead - Agent_Call_Back_Date_Time__c+Notify_Owner_Manager__c - RULE 3 : manager notification.
		
		User u,m;
		System.runAs(new User(Id=UserInfo.getUserId())){
			m = UserTestHelper.createStandardUsers(1, 'Sophy', 'Grigson')[0];			
			System.debug(LoggingLevel.ERROR,'Manager Id='+m.Id);
			
			u = UserTestHelper.createStandardUsers(1, 'Claire', 'Smythe',false)[0];
			u.ManagerId = m.Id;
			insert u;
		}
				
		Lead l = AP23_TestDataFactory.createLead(1)[0];
		
		l.LeadSource = LEAD_SOURCE_WEBFORM_CALLBACK;
		l.TravelGroupSize__c = 8;
		l.CountriesInterested__c = 'Scotland';
		l.Customer_Call_Back_Date_Time__c = Datetime.now().addMinutes(-45);	
		l.OwnerId=u.Id;
		l.Rating = ApplicationConstant.LEAD_RATING_WARM;
		insert l;
		
		System.assertEquals(u.Id, [select Id, OwnerId from Lead where Id=:l.Id].OwnerId, 'Lead should not be assigned to the Callback Queue.');
		
      	AP62_ScheduledLeadCallbackProcessorBatch b = new AP62_ScheduledLeadCallbackProcessorBatch();				
							
		Test.startTest(); // collect async processes.		
		Database.executeBatch(b, 100);
		Test.stopTest(); // execute async processes.
				
		System.assertEquals(1,AP62_ScheduledLeadCallbackProcessorBatch.messagesToSendCount,'RULE 3 should send 1 email to the manager.');	
		System.assert(AP62_ScheduledLeadCallbackProcessorBatch.messageRecipientIds.contains(m.Id),'RULE 3 should send 1 email to the manager.');				      		
	}
	/* */
	
	/* **/
	static testMethod void singleTestCase7(){
		// Test Case 7 : BatchApex. Webform Callback lead - Agent_Call_Back_Date_Time__c+Notify_Owner_Manager__c - RULE 4 : minus minutes notification.
		
		User u,m;
		System.runAs(new User(Id=UserInfo.getUserId())){
			m = UserTestHelper.createStandardUsers(1, 'Sophy', 'Grigson')[0];
			System.debug(LoggingLevel.ERROR,'Manager Id='+m.Id);
			
			u = UserTestHelper.createStandardUsers(1, 'Claire', 'Smythe',false)[0];
			u.ManagerId = m.Id;
			insert u;
		}
				
		Lead l = AP23_TestDataFactory.createLead(1)[0];
		
		l.LeadSource = LEAD_SOURCE_WEBFORM_CALLBACK;
		l.TravelGroupSize__c = 8;
		l.CountriesInterested__c = 'Scotland';
		l.Customer_Call_Back_Date_Time__c = Datetime.now().addMinutes(15);	
		l.OwnerId=u.Id;
		l.Rating = ApplicationConstant.LEAD_RATING_WARM;
		insert l;

		
		System.assertEquals(u.Id, [select Id, OwnerId from Lead where Id=:l.Id].OwnerId, 'Lead should not be assigned to the Callback Queue.');
		
      	AP62_ScheduledLeadCallbackProcessorBatch b = new AP62_ScheduledLeadCallbackProcessorBatch();				
							
		Test.startTest(); // collect async processes.		
		Database.executeBatch(b, 100);
		Test.stopTest(); // execute async processes.
				
		System.assertEquals(2,AP62_ScheduledLeadCallbackProcessorBatch.messagesToSendCount,'RULE 4 should send 2 emails to the owner and manager.');	
		System.assert(AP62_ScheduledLeadCallbackProcessorBatch.messageRecipientIds.contains(u.Id),'RULE 4 should send 1 email to the owner.');
		System.assert(AP62_ScheduledLeadCallbackProcessorBatch.messageRecipientIds.contains(m.Id),'RULE 4 should send 1 email to the manager.');				      			      		
	}
	/* */

	/* **/
	static testMethod void negativeTestCase1(){
		// Negative Test Case 1 : ApexTrigger. New Webform Non-Callback lead - do not route to Holding Queue.
		
		Id apiUserId = [select Id, Name from User where Name=:ApplicationConstant.USER_NAME_API_USER][0].Id;				
		Id callBackQueueId = [select Id from Group where DeveloperName=:CALLBACK_QUEUE_DEVELOPER_NAME and Type='Queue'][0].Id;

		Lead l = AP23_TestDataFactory.createLead(1)[0];
		
		l.LeadSource = LEAD_SOURCE_WEBFORM_CALLBACK;
		l.TravelGroupSize__c = 8;
		l.CountriesInterested__c = 'Scotland';
		l.Customer_Call_Back_Date_Time__c = null;		
		l.OwnerId=apiUserId;
		
		Test.startTest();
		insert l;
		Test.stopTest();
		
		System.assertNotEquals(callBackQueueId, [select Id, OwnerId from Lead where Id=:l.Id].OwnerId, 'Lead should be assigned to the Callback Queue.');
	}
	/* */
	
	/* **/
	static testMethod void negativeTestCase2(){
		// Negative Test Case 2 : ApexTrigger. New Phone Callback lead - do not route to Holding Queue.
		
		Id apiUserId = [select Id, Name from User where Name=:ApplicationConstant.USER_NAME_API_USER][0].Id;				
		Id callBackQueueId = [select Id from Group where DeveloperName=:CALLBACK_QUEUE_DEVELOPER_NAME and Type='Queue'][0].Id;

		Lead l = AP23_TestDataFactory.createLead(1)[0];
		
		l.LeadSource = ApplicationConstant.LEAD_SOURCE_PHONE;
		l.TravelGroupSize__c = 8;
		l.CountriesInterested__c = 'Scotland';
		l.Customer_Call_Back_Date_Time__c = Datetime.now().addMinutes(60);		
		l.OwnerId=apiUserId;
		
		Test.startTest();
		insert l;
		Test.stopTest();
		
		System.assertNotEquals(callBackQueueId, [select Id, OwnerId from Lead where Id=:l.Id].OwnerId, 'Lead should be assigned to the Callback Queue.');
	}
	/* */		

	/* **/
	static testMethod void negativeTestCase3(){
		// Negative Test Case 3 : BatchApex. Webform Callback lead - no early release from Holding Queue.
		
		Id apiUserId = [select Id, Name from User where Name=:ApplicationConstant.USER_NAME_API_USER][0].Id;				
		Id callBackQueueId = [select Id from Group where DeveloperName=:CALLBACK_QUEUE_DEVELOPER_NAME and Type='Queue'][0].Id;

		Lead l = AP23_TestDataFactory.createLead(1)[0];
		
		l.LeadSource = LEAD_SOURCE_WEBFORM_CALLBACK;
		l.TravelGroupSize__c = 8;
		l.CountriesInterested__c = 'Scotland';
		l.Customer_Call_Back_Date_Time__c = Datetime.now().addMinutes(25);	
		l.OwnerId=apiUserId;
		l.Rating = ApplicationConstant.LEAD_RATING_WARM;
		insert l;
		
		System.assertEquals(callBackQueueId, [select Id, OwnerId from Lead where Id=:l.Id].OwnerId, 'Lead should be assigned to the Callback Queue.');
		
		Test.startTest(); // collect async processes.		
		Database.executeBatch(new AP62_ScheduledLeadCallbackProcessorBatch(), 100);
		Test.stopTest(); // execute async processes.
		
		System.assertEquals(callBackQueueId, [select Id, OwnerId from Lead where Id=:l.Id].OwnerId, 'Lead should be assigned to the Callback Queue.');		
	}
	/* */	
	
	/* **/
	static testMethod void negativeTestCase4(){
		// Negative Test Case 4 : BatchApex. BatchApex. Leads outside of the 2 hour window (-1h to +1h) are not processed.
		
		Id apiUserId = [select Id, Name from User where Name=:ApplicationConstant.USER_NAME_API_USER][0].Id;				
		Id callBackQueueId = [select Id from Group where DeveloperName=:CALLBACK_QUEUE_DEVELOPER_NAME and Type='Queue'][0].Id;

		Lead l = AP23_TestDataFactory.createLead(1)[0];
		
		l.LeadSource = LEAD_SOURCE_WEBFORM_CALLBACK;
		l.TravelGroupSize__c = 8;
		l.CountriesInterested__c = 'Scotland';
		l.Customer_Call_Back_Date_Time__c = Datetime.now().addMinutes(65);	
		l.OwnerId=apiUserId;
		l.Rating = ApplicationConstant.LEAD_RATING_WARM;
		
		Lead l2 = AP23_TestDataFactory.createLead(1)[0];
		
		l2.LeadSource = LEAD_SOURCE_WEBFORM_CALLBACK;
		l2.TravelGroupSize__c = 8;
		l2.CountriesInterested__c = 'Scotland';
		l2.Customer_Call_Back_Date_Time__c = Datetime.now().addMinutes(61);	
		l2.OwnerId=apiUserId;
		l2.Rating = ApplicationConstant.LEAD_RATING_WARM;
		
		insert new List<Lead>{l,l2};		
		
		System.assertEquals(2, [select count() from Lead where OwnerId=:callBackQueueId], 'Leads should be assigned to the Callback Queue.');
		
		Test.startTest(); // collect async processes.		
		Database.executeBatch(new AP62_ScheduledLeadCallbackProcessorBatch(), 100);
		Test.stopTest(); // execute async processes.
		
		System.assertEquals(2, [select count() from Lead where OwnerId=:callBackQueueId], 'Leads should be assigned to the Callback Queue.');		
	}
	/* */		

	/* **/
	static testMethod void negativeTestCase5(){
		// Negative Test Case 5 : BatchApex. Webform Callback lead - no notifications where Agent has called.
		
		Id apiUserId = [select Id, Name from User where Name=:ApplicationConstant.USER_NAME_API_USER][0].Id;				
		Id callBackQueueId = [select Id from Group where DeveloperName=:CALLBACK_QUEUE_DEVELOPER_NAME and Type='Queue'][0].Id;

		Lead l = AP23_TestDataFactory.createLead(1)[0];
		
		l.LeadSource = LEAD_SOURCE_WEBFORM_CALLBACK;
		l.TravelGroupSize__c = 8;
		l.CountriesInterested__c = 'Scotland';
		l.Customer_Call_Back_Date_Time__c = Datetime.now().addMinutes(-30);	
		l.OwnerId=UserInfo.getUserId();
		l.Rating = ApplicationConstant.LEAD_RATING_WARM;
		l.Agent_Call_Back_Date_Time__c = Datetime.now();
		insert l;
		
		System.assertEquals(UserInfo.getUserId(), [select Id, OwnerId from Lead where Id=:l.Id].OwnerId, 'Lead should be assigned to the Callback Queue.');
		
      	AP62_ScheduledLeadCallbackProcessorBatch b = new AP62_ScheduledLeadCallbackProcessorBatch();				
							
		Test.startTest(); // collect async processes.		
		Database.executeBatch(b, 100);
		Test.stopTest(); // execute async processes.
				
		System.assertEquals(0,AP62_ScheduledLeadCallbackProcessorBatch.messagesToSendCount,'RULE 2 should send 0 email.');	      		
	}
	/* */		
}