/**************************************************************
@author - Simon Molloy (Golfbreaks)
@date - 30/06/2017
@description - Test class for OpportunityStageUpdateSchedule
***************************************************************/
@isTest
private class OpportunityStageUpdateSchedule_Test {
    
    static testmethod void test() {
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