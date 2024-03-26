@isTest(seeAllData=false)
public class AP12_CaseAndLeadJobRunner_Test{

    static testmethod void testLeadSchedule(){
        Test.StartTest();
        
        AP12_CaseAndLeadJobRunner sh1 = new AP12_CaseAndLeadJobRunner();
        String sch = '0 10 * * * ?'; 
        String jobId = system.schedule('Test Lead Assignment', sch, sh1); 
        
        CronTrigger ct = [select id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id = :jobId LIMIT 1];
        System.assertEquals(sch, ct.CronExpression); 
        System.assertEquals(0, ct.TimesTriggered);
        
        Test.stopTest(); 
    }
}