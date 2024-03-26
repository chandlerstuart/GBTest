@isTest(seealldata=false)
public class AP61_CsScrngQueryBlderSched_Test {
    static testMethod void testScheduleEpay(){
        test.StartTest();
        AP61_CaseScoringQueryBuilderSchedule sched = new AP61_CaseScoringQueryBuilderSchedule();
        String jobName = 'Test Epay Batch';
        String crony = '0 15 * * * ?';
        String jbId = System.schedule(jobName, crony, sched);
        
        CronTrigger ct = [select id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id = :jbId LIMIT 1];
        System.assertEquals(crony, ct.CronExpression); 
        System.assertEquals(0, ct.TimesTriggered);
        test.StopTest();
    }
}