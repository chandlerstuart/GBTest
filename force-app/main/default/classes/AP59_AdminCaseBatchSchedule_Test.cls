/**
* @author -         Christian Gaylan (Accenture)
* @CreatedDate -           18/08/2016
* @description -    Test AP59_AdminCaseBatchSchedule class 
* #############Change Log#############
* Modified by     Version     Change Date
**/

@isTest(seealldata=false)
public class AP59_AdminCaseBatchSchedule_Test {
    static testMethod void testScheduleCls(){
        test.StartTest();
        AP59_AdminCaseBatchSchedule adCase = new AP59_AdminCaseBatchSchedule();
        String jobName = 'Test Admin Case Batch';
        String crony = '0 15 * * * ?';
        String jbId = System.schedule(jobName, crony, adCase);
        
        CronTrigger ct = [select id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id = :jbId LIMIT 1];
        System.assertEquals(crony, ct.CronExpression); 
        System.assertEquals(0, ct.TimesTriggered);
        test.StopTest();
    }
}