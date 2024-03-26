/*
Name:  RecordDeleteScheduleClass_Test.cls
======================================================
======================================================
Purpose:
-------
Test class for RecordDeleteScheduleClass

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon Molloy  2017-10-18  Initial development.
*/
@isTest
private class RecordDeleteScheduleClass_Test {
    
    static testmethod void test() {
        String CRON_EXP = '0 0 0 3 9 ? 2024';
        RecordDeleteSetting__c rds = new RecordDeleteSetting__c(Name = 'UserServicePresence',Days__c = 7, API_Name__c = 'UserServicePresence');
        insert rds;

       Test.startTest();
          // Schedule the test job

          RecordDeleteScheduleClass rdsc = new RecordDeleteScheduleClass();
    
          String jobId = System.schedule('testRecordDeleteSchedule',CRON_EXP, rdsc);
    
          // Get the information from the CronTrigger API object
          CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
    
          // Verify the expressions are the same
          System.assertEquals(CRON_EXP, ct.CronExpression);
    
          // Verify the job has not run
          System.assertEquals(0, ct.TimesTriggered);
    
          // Verify the next time the job will run
          System.assertEquals('2024-09-03 00:00:00', String.valueOf(ct.NextFireTime));
    
       Test.stopTest();
    }
       
}