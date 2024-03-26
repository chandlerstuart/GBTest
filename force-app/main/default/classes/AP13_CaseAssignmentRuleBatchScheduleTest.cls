@isTest(seealldata=false)
public class AP13_CaseAssignmentRuleBatchScheduleTest {

    static testmethod void testSchedule() {

        Test.StartTest();
        AP13_CaseAssignmentRuleBatchSchedule  sh1 = new AP13_CaseAssignmentRuleBatchSchedule();
        String sch = '0 0 23 * * ?'; 
        String jbId = System.schedule('Test Territory Check', sch, sh1);
        
        CronTrigger ct = [select id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id = :jbId LIMIT 1];
        System.assertEquals(sch, ct.CronExpression); 
        System.assertEquals(0, ct.TimesTriggered);
        
        Test.stopTest(); 
    }
}