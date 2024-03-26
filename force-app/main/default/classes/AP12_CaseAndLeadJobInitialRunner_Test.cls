@isTest
public class AP12_CaseAndLeadJobInitialRunner_Test{
    @isTest static void tstSchedule(){
        Test.StartTest();
        AP12_CaseAndLeadJobInitialRunner  sh1 = new AP12_CaseAndLeadJobInitialRunner();
        String jobName = 'Test Init JobRunner';
        String crony = '0 15 * * * ?';
        String jbId = System.schedule(jobName, crony, sh1);
        
        CronTrigger ct = [Select Id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id = :jbId LIMIT 1];
        System.assertEquals(crony, ct.CronExpression); 
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest(); 
    }
}