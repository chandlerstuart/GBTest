/**
* @author -         Christian Gaylan (Accenture)
* @CreatedDate -           28/04/2016
* @description -    Test AP34_BookingAdminCaseBatchSchedule class 
* #############Change Log#############
* Modified by     Version     Change Date
**/

@isTest(seealldata=false)
public class AP34_BookingAdminCaseBatchSchedule_TEST {
    static testMethod void testScheduleBooking(){
        test.StartTest();
        AP34_BookingAdminCaseBatchSchedule epay = new AP34_BookingAdminCaseBatchSchedule();
        String jobName = 'Test Booking Batch';
        String crony = '0 15 * * * ?';
        String jbId = System.schedule(jobName, crony, epay);
        
        CronTrigger ct = [select id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id = :jbId LIMIT 1];
        System.assertEquals(crony, ct.CronExpression); 
        System.assertEquals(0, ct.TimesTriggered);
        test.StopTest();
    }
}