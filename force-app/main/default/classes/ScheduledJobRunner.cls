/*
Name:  ScheduledJobRunner.cls
======================================================
======================================================
Purpose:
-------
Utility class to re-schedule jobs that are deleted
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.0  Simon Molloy  2017-01-31   Initial development
1.1  J Radcliffe   2018-12-19   Removing references to redundant schedules
*/
public with sharing class ScheduledJobRunner {
  
  //Schedules ALL jobs using CRON_EXPRESSION values
  public static void scheduleAllJobs(){
    Map<Id, String> jobIdMap = new Map<Id, String>();
    String CRON_EXP = '';
    String JOB_NAME = '';
    //First get a list of those jobs that are already scheduled so we don't try and schedule ones already done
    Map<String, CronTrigger> currentJobMap = new Map<String, CronTrigger>();
    for (CronTrigger ct : [select Id, CronExpression, CronJobDetail.Name from CronTrigger where CronJobDetail.JobType = '7']){
        currentJobMap.put(ct.CronJobDetail.Name, ct);
    }

    //AP60_ScheduleDeleteLogs
    CRON_EXP = '0 0 4 ? * 1,2,3,4,5,6,7';
    JOB_NAME = (test.isRunningTest() ? 'AP60_ScheduleDeleteLogs_TEST' : 'AP60_ScheduleDeleteLogs');
    
    if (!currentJobMap.containsKey(JOB_NAME)){
        jobIdMap.put(system.schedule(JOB_NAME, CRON_EXP, new AP60_ScheduleDeleteLogs()), JOB_NAME);
    }
    
    //Web Callback Lead Batch-01/03/2017 18:00
    CRON_EXP = '0 0 18 1 */1 ?';
    JOB_NAME = (test.isRunningTest() ? 'Web Callback Lead Batch-01/03/2017 18:00_TEST' : 'Web Callback Lead Batch-01/03/2017 18:00');
    
    if (!currentJobMap.containsKey(JOB_NAME)){
       // jobIdMap.put(system.schedule(JOB_NAME, CRON_EXP, new AP62_ScheduledLeadCallbackProcessorBatch()), JOB_NAME); <--- 1.1
    }
    

    //AP12_CaseAndLeadJobInitialRunner
    //This job needs to run on the 'next' hour
    String hr = System.now().hour().format();
    CRON_EXP = '0 0 ' + hr + ' ? * 1,2,3,4,5,6,7';
    JOB_NAME = (test.isRunningTest() ? 'AP12_CaseAndLeadJobInitialRunner_TEST' : 'AP12_CaseAndLeadJobInitialRunner');

    if (!currentJobMap.containsKey(JOB_NAME)){
       // jobIdMap.put(system.schedule(JOB_NAME, CRON_EXP, new AP12_CaseAndLeadJobInitialRunner()), JOB_NAME); <--- 1.1
    }
    
    //Expected Payment Admin Case Batch
    CRON_EXP = '0 0 5,9,13,17 ? * MON-FRI *';
    JOB_NAME = (test.isRunningTest() ? 'Expected Payment Admin Case Batch_TEST' : 'Expected Payment Admin Case Batch');

    if (!currentJobMap.containsKey(JOB_NAME)){
      //  jobIdMap.put(system.schedule(JOB_NAME, CRON_EXP, new AP33_EPaymentAdminCaseBatchSchedule()), JOB_NAME); <--- 1.1
    }

    //Booking Admin Case Batch
    CRON_EXP = '0 30 5,9,13,17 ? * MON-FRI *';
    JOB_NAME = (test.isRunningTest() ? 'Booking Admin Case Batch_TEST' : 'Booking Admin Case Batch');

    if (!currentJobMap.containsKey(JOB_NAME)){
      //  jobIdMap.put(system.schedule(JOB_NAME, CRON_EXP, new AP34_BookingAdminCaseBatchSchedule()), JOB_NAME); <--- 1.1
    }

    //Case Scoring Query Builder Schedule
    CRON_EXP = '0 0 8,10,12,14,16,18,20 ? * MON-FRI *';
    JOB_NAME = (test.isRunningTest() ? 'Case Scoring Query Builder Schedule_TEST' : 'Case Scoring Query Builder Schedule');

    if (!currentJobMap.containsKey(JOB_NAME)){
      //  jobIdMap.put(system.schedule(JOB_NAME, CRON_EXP, new AP61_CaseScoringQueryBuilderSchedule()), JOB_NAME); <--- 1.1s
    }

    //Golfbreaks News Group Members
    CRON_EXP = '0 0 7 ? * 1,2,3,4,5,6,7';
    JOB_NAME = (test.isRunningTest() ? 'Golfbreaks News Group Members_TEST' : 'Golfbreaks News Group Members');

    if (!currentJobMap.containsKey(JOB_NAME)){
        jobIdMap.put(system.schedule(JOB_NAME, CRON_EXP, new EmpCommunity_GBNewsGroupUpdate()), JOB_NAME);
    }

    //NVM Call Summary Schedule
    CRON_EXP = '0 0 23 ? * 1,2,3,4,5,6,7';
    JOB_NAME = (test.isRunningTest() ? 'NVM Call Summary Schedule_TEST' : 'NVM Call Summary Schedule');

    if (!currentJobMap.containsKey(JOB_NAME)){
        jobIdMap.put(system.schedule(JOB_NAME, CRON_EXP, new NVMCallSummaryScheduleClass()), JOB_NAME);
    }

    //NVM Call Summary Schedule
    CRON_EXP = '0 0 6 ? * 1,2,3,4,5,6,7';
    JOB_NAME = (test.isRunningTest() ? 'AP64_BookingToAccountUpdateSchedule_TEST' : 'AP64_BookingToAccountUpdateSchedule');

    if (!currentJobMap.containsKey(JOB_NAME)){
        jobIdMap.put(system.schedule(JOB_NAME, CRON_EXP, new AP64_BookingToAccountUpdateSchedule()), JOB_NAME);
    }

    //Record Delete Batch class
    CRON_EXP = '0 0 4 ? * 2,3,4,5,6';
    JOB_NAME = (test.isRunningTest() ? 'RecordDeleteBatch_TEST' : 'RecordDeleteBatch');

    if (!currentJobMap.containsKey(JOB_NAME)){
        jobIdMap.put(system.schedule(JOB_NAME, CRON_EXP, new RecordDeleteScheduleClass()), JOB_NAME);
    }

    system.debug('*** -- SCHEDULED FOLLOWING JOBS -- ***');
    for (Id i : jobIdMap.keySet()){
      system.debug('*** -- Job Name = ' + jobIdMap.get(i) + ' Id = ' + i + ' -- ***');
    }

  }

}