/**************************************************************
@author - Simon Molloy (Golfbreaks)
@date - 21/11/2016
@description - Test class for NVMCallSummaryScheduleClass
***************************************************************/
@isTest
private class NVMCallSummaryScheduleClassTest {

   static testmethod void testSchedule() {
   String CRON_EXP = '0 0 0 21 11 ? 2022';
   
   Test.startTest();

      // Schedule the test job

      String jobId = System.schedule('testSchedule', CRON_EXP, new NVMCallSummaryScheduleClass());

      // Get the information from the CronTrigger API object
      CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

      // Verify the expressions are the same
      System.assertEquals(CRON_EXP, ct.CronExpression);

      // Verify the job has not run
      System.assertEquals(0, ct.TimesTriggered);

      // Verify the next time the job will run
      System.assertEquals('2022-11-21 00:00:00', String.valueOf(ct.NextFireTime));

   Test.stopTest();

    }
}