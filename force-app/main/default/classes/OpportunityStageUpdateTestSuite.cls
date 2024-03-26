/*
Name:  OpportunityStageUpdateTestSuite.cls
======================================================
======================================================
Purpose:
-------
Test Class for Opportunity Stage Update functionality

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon Molloy  2017-06-30  Initial development.
*/
@isTest
private class OpportunityStageUpdateTestSuite {
    @testSetup
    public static void setup() {
    	List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
    	
    	Account client = AP23_TestDataFactory.createPersonAccount(1)[0];
    	insert client;

    	List<Opportunity> oppList = AP23_TestDataFactory.createOpportunity(3,ApplicationConstant.PAIDFULLBALANCESTAGE,client);
    	oppList[0].Name = 'Pre-Today Return';
    	oppList[1].Name = 'Today Return';
    	oppList[2].Name = 'Post-Today Return';

    	insert oppList;

    	List<Booking__c> bookingList = new List<Booking__c>();

    	for (Opportunity o : oppList){
    		Booking__c book = AP23_TestDataFactory.createBooking(1, client, o.Id)[0];
    		if ('Pre-Today Return'.equalsIgnoreCase(o.Name)){
    			book.Travel_Date__c = Date.today().addDays(-14);
    			book.Nights__c = 7;
    		}else if ('Today Return'.equalsIgnoreCase(o.Name)){
    			book.Travel_Date__c = Date.today().addDays(-7);
    			book.Nights__c = 7;
    		}else if ('Post-Today Return'.equalsIgnoreCase(o.Name)){
    			book.Travel_Date__c = Date.today().addDays(7);
    			book.Nights__c = 7;
    		}
    		bookingList.add(book);
    	}

    	insert bookingList;

    }

    static testMethod void testBatchRun() {
		test.startTest();

    	OpportunityStageUpdateBatch osub = new OpportunityStageUpdateBatch();
    	Id jobId = Database.executeBatch(osub);

    	test.stopTest();

    	for (Opportunity o : [select Id, Name, StageName from Opportunity]){
    		if ('Pre-Today Return'.equalsIgnoreCase(o.Name)){
    			system.assertEquals(ApplicationConstant.OPP_STAGE_TRIPCOMPLETED, o.StageName);
    		}else if ('Today Return'.equalsIgnoreCase(o.Name)){
    			system.assertEquals(ApplicationConstant.OPP_STAGE_TRIPCOMPLETED, o.StageName);
    		}else if ('Post-Today Return'.equalsIgnoreCase(o.Name)){
    			system.assertEquals(ApplicationConstant.PAIDFULLBALANCESTAGE, o.StageName);
    		}
    	}	
	}

	static testmethod void testSchedule() {
        String CRON_EXP = '0 0 0 3 9 ? 2022';
       Test.startTest();
          // Schedule the test job
    
          String jobId = System.schedule('testOppStageUpdate',CRON_EXP, new OpportunityStageUpdateSchedule());
    
          // Get the information from the CronTrigger API object
          CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
    
          // Verify the expressions are the same
          System.assertEquals(CRON_EXP, ct.CronExpression);
    
          // Verify the job has not run
          System.assertEquals(0, ct.TimesTriggered);
    
          // Verify the next time the job will run
          System.assertEquals('2022-09-03 00:00:00', String.valueOf(ct.NextFireTime));
    
       Test.stopTest();
    }
}