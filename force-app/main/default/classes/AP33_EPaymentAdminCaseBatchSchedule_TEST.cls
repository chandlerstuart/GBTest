/**
* @author -         Christian Gaylan (Accenture)
* @CreatedDate -           28/04/2016
* @description -    Test AP33_EPaymentAdminCaseBatchSchedule class 
* #############Change Log#############
* Modified by     Version     Change Date
**/

@isTest(seealldata=false)
public class AP33_EPaymentAdminCaseBatchSchedule_TEST {
    static testMethod void testScheduleEpay(){
        test.StartTest();
        AP33_EPaymentAdminCaseBatchSchedule epay = new AP33_EPaymentAdminCaseBatchSchedule();
        String jobName = 'Test Epay Batch';
        String crony = '0 15 * * * ?';
        String jbId = System.schedule(jobName, crony, epay);
        
        CronTrigger ct = [select id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id = :jbId LIMIT 1];
        System.assertEquals(crony, ct.CronExpression); 
        System.assertEquals(0, ct.TimesTriggered);
        test.StopTest();
    }
}