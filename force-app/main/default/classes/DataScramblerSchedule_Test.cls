/*
Name:  DataScramblerSchedule_Test.cls
======================================================
======================================================
Purpose:
-------
Test class for DataScramblerScheduleClass

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon Molloy  2017-10-26  Initial development.
*/
@isTest
private class DataScramblerSchedule_Test {
    
    static testmethod void test() {
        String CRON_EXP = '0 0 0 3 9 ? 2022';
        
       Test.startTest();
          // Schedule the test job

          DataScramblerSchedule dss = new DataScramblerSchedule();
    
          String jobId = System.schedule('testDataScramblerSchedule',CRON_EXP, dss);
    
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