/*
Name:  ScheduledJobRunner_Test.cls
======================================================
======================================================
Purpose:
-------
Test Class for ScheduledJobRunner
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.0  Simon Molloy  2017-02-01   Initial development
1.1  J Radcliffe   2018-12-19   Removing references to redundant schedules
*/
@isTest
private class ScheduledJobRunner_Test {
  static testMethod void testScheduleAllJobs(){
      test.startTest();
        ScheduledJobRunner.scheduleAllJobs();
      test.stopTest();

      Map<String, CronTrigger> cronTriggerMap = new Map<String, CronTrigger>();

      for (CronTrigger ct : [select CronJobDetail.Name from CronTrigger where CronJobDetail.JobType = '7']){
        cronTriggerMap.put(ct.CronJobDetail.Name, ct);
      }

      //system.assertEquals(true, cronTriggerMap.containsKey('Expected Payment Admin Case Batch_TEST')); <--- 1.1
      //system.assertEquals(true, cronTriggerMap.containsKey('Booking Admin Case Batch_TEST')); <--- 1.1
      //system.assertEquals(true, cronTriggerMap.containsKey('Case Scoring Query Builder Schedule_TEST')); <--- 1.1
      system.assertEquals(true, cronTriggerMap.containsKey('Golfbreaks News Group Members_TEST'));
      system.assertEquals(true, cronTriggerMap.containsKey('NVM Call Summary Schedule_TEST'));
      //system.assertEquals(true, cronTriggerMap.containsKey('AP12_CaseAndLeadJobInitialRunner_TEST')); <--- 1.1
      system.assertEquals(true, cronTriggerMap.containsKey('AP60_ScheduleDeleteLogs_TEST'));
      system.assertEquals(true, cronTriggerMap.containsKey('AP64_BookingToAccountUpdateSchedule_TEST'));
      system.assertEquals(true, cronTriggerMap.containsKey('RecordDeleteBatch_TEST'));
  }
}