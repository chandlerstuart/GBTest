@isTest(seeAllData = false)
public class AP60_ScheduleDeleteLogs_Test{
    static testMethod void testScheduleEpay(){
        test.StartTest();
        AP60_ScheduleDeleteLogs epay = new AP60_ScheduleDeleteLogs();
        String jobName = 'Test Delete Logs Batch';
        String crony = '0 15 * * * ?';
        String jbId = System.schedule(jobName, crony, epay);
        
        CronTrigger ct = [select id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id = :jbId LIMIT 1];
        System.assertEquals(crony, ct.CronExpression); 
        System.assertEquals(0, ct.TimesTriggered);
        test.StopTest();
    }
}