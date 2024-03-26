/**
Name:  AP40_BookingLeadCreationBatchSched_Test .cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test Class for AP40_BookingLeadCreationBatchSchedule
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  M.Cebrian  2016-04-28  Initial development.
**/
@isTest
private class AP40_BookingLeadCreationBatchSched_Test {
    
	public static String CRON_EXP = '0 0 0 15 3 ? 2022';
	
	@testSetup static void setupTestData() {
	    List<Account> testAccount= AP23_TestDataFactory.createAccount(1);
	    insert testAccount;
	    
	    List<Opportunity> testOpps = AP23_TestDataFactory.createOpportunity(1,'Prospecting',testAccount.get(0));
	    insert testOpps;
	    
	    List<Booking__c> testBookings = AP23_TestDataFactory.createBooking(3, testAccount.get(0), testOpps.get(0).Id);
	    for(Booking__c tb: testBookings) {
	        tb.Travel_Date__c = System.today().addDays(-15);
	        tb.Nights__c = 1;
	    }
	    insert testBookings;
    }
	
	@isTest static void validateScheduledClass() {
	    AP38_BookingLeadCreationBatch executeBookingLeadCreationBatch = new AP38_BookingLeadCreationBatch();
		Test.startTest();
            // Schedule the test job
            String jobId = System.schedule('ScheduleApexClassTest',CRON_EXP, new AP40_BookingLeadCreationBatchSchedule());
             
            // Get the information from the CronTrigger API object
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
    
            // Verify the expressions are the same
            System.assertEquals(CRON_EXP, ct.CronExpression);
    
            // Verify the job has not run
            System.assertEquals(0, ct.TimesTriggered);
    
            // Verify the next time the job will run
            System.assertEquals('2022-03-15 00:00:00', String.valueOf(ct.NextFireTime));
        Test.stopTest();
	}
	
}