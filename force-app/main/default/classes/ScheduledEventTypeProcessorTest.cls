/*
Name: ScheduledEventTypeProcessorTest.cls
======================================================
======================================================
Purpose:
-------

Test suite for Scheduled Event Type Processing.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J.Radcliffe   2021-02-15  Initial development.
*/
@isTest
public with sharing class ScheduledEventTypeProcessorTest {
    
	/*
    Test cases:
        singleTestCase1a - OutboundCallouts. Test the Outbound Callouts are successfully inserted with defaults copied from the DET's.
        singleTestCase1b - Schedulable. Test the schedulable succesfully builds a list of Active DET Ids to pass to the Processor
        singleTestCase1c - Job Chaining. Test the Processors are successfully chained
        singleTestCase2a - Sequencing. Test sequencing is enforced within the Data Event Type 
        singleTestCase2b - Sequencing. Test sequencing is enforced across the job schedule
	*/

    static testMethod void singleTestCase1a() {    
        // Test case 1a : OutboundCallouts. Test the Outbound Callouts are successfully inserted with defaults applied.
        ScheduledEventTypeProcessor.ocList = new List<OutboundCallout__c>();
        for(Integer i=0;i<10;i++){
            ScheduledEventTypeProcessor.ocList.add(new OutboundCallout__c(
                Endpoint__c = 'callout=Test/Scheduled/12345'
            ));
        }

        DataEventType__mdt scheduledEvent= DataEventType__mdt.getInstance('Scheduled_Event_Type_No_Sequence_Test');
        Id dummyId = '08e8E00000aug2yQAA';

        system.assertEquals(0, [Select Count() From OutboundCallout__c]);

        test.startTest();
            System.enqueueJob(new ScheduledEventTypeProcessor(new List<Id>{scheduledEvent.Id},dummyId));
        test.stopTest();

        List<OutboundCallout__c> outboundCallouts = [Select Id, Endpoint__c, Method__c, ContentTypeHeader__c, DataEventType__c,
                                                    ResponseHandler__c, Status__c, CalloutTimeout__c, AcceptHeader__c, RecordId__c
                                                    From OutboundCallout__c];
        
        //Successfully inserted?
        system.assertEquals(10, outboundCallouts.size());
    
        //Defaults applied? 
        for(OutboundCallout__c oc : outboundCallouts){
            system.assertEquals('callout=Test/Scheduled/12345', oc.Endpoint__c);//<--- confirm the Endpoint is not overwritten
            system.assertEquals('GET', oc.Method__c);
            system.assertEquals('application/json', oc.ContentTypeHeader__c);
            system.assertEquals('Scheduled_Event_Type_No_Sequence_Test', oc.DataEventType__c);
            system.assertEquals('TestHandler', oc.ResponseHandler__c);
            system.assertEquals(120000, oc.CalloutTimeout__c);
            system.assertEquals('*/*', oc.AcceptHeader__c);
            system.assertEquals(null, oc.RecordId__c);
        }
    }

    static testMethod void singleTestCase1b() {    

        // Test case 1b : Schedulable. Test the schedulable succesfully builds a list of Active DET Ids to pass to the Processor

        Integer scheduledEventCount = [Select Count() From DataEventType__mdt Where IsActive__c = true and Order__c != null];

        system.assertEquals(true, scheduledEventCount>0);//Confirm there are active scheduled data events
        system.assertEquals(0, [Select Count() From OutboundCallout__c]);

        test.startTest();
            activateSchedulable();
            String CRON_EXP = '0 0 0 15 3 ? 2035';//increased from 2025.
            System.schedule('ScheduledApexTest', CRON_EXP, new ScheduledEventSchedulable());
        test.stopTest();
        
        //Successfully executed?
        system.assertEquals(scheduledEventCount, ScheduledEventSchedulable.scheduledEventIdsTest.size());

        System.assertEquals(1,[select count() from CronTrigger where State not in ('COMPLETE','ERROR','DELETED') and CronJobDetail.Name=:Label.Apex_Constant_Scheduled_Event_Scheduler]);    
    }

    public static void activateSchedulable(){
        FrameworkSettings__c settings = new FrameworkSettings__c();
        settings.ScheduledProcessorIsActive__c = true;
        insert settings;        
    }

    static testMethod void singleTestCase1c() {    

        // Test case 1c : Job Chaining. Test the Processors are successfully chained 

        ScheduledEventTypeProcessor.ocList = new List<OutboundCallout__c>();
        for(Integer i=0;i<10;i++){
            ScheduledEventTypeProcessor.ocList.add(new OutboundCallout__c(
                Endpoint__c = 'callout=Test/Scheduled/12345'
            ));
        }

        List<Id> scheduledEventIds = new List<Id>();
        for(DataEventType__mdt det : [Select Id From DataEventType__mdt Where IsActive__c = true and Order__c != null]){
            scheduledEventIds.add(det.Id);
        }
        Id dummyId = '08e8E00000aug2yQAA';
        
        test.startTest();
            System.enqueueJob(new ScheduledEventTypeProcessor(scheduledEventIds,dummyId));
        test.stopTest();

        List<OutboundCallout__c> outboundCallouts = [Select Id, Endpoint__c, Method__c, ContentTypeHeader__c, DataEventType__c,
                                                    ResponseHandler__c, Status__c, CalloutTimeout__c, AcceptHeader__c, RecordId__c
                                                    From OutboundCallout__c];

        //Successfully inserted?
        system.assertEquals(10, outboundCallouts.size());

        //Remaining scheduleIds populated?
        system.assertEquals(ScheduledEventTypeProcessor.remainingScheduledEventIds.size(),scheduledEventIds.size()-1);

    }

    static testMethod void singleTestCase2a(){
        
        //Test Case 2a : Sequencing. Test sequencing is enforced within the Data Event Type 

        ScheduledEventTypeProcessor.ocList = new List<OutboundCallout__c>();
        for(Integer i=0;i<10;i++){
            ScheduledEventTypeProcessor.ocList.add(new OutboundCallout__c(
                Endpoint__c = 'callout=Test/Scheduled/12345'
            ));
        }

        DataEventType__mdt scheduledEvent= DataEventType__mdt.getInstance('Scheduled_Event_Type_DET_Sequence_Test');
        Id dummyId = '08e8E00000aug2yQAA';

        system.assertEquals(0, [Select Count() From OutboundCallout__c]);

        test.startTest();
            Id jobId = System.enqueueJob(new ScheduledEventTypeProcessor(new List<Id>{scheduledEvent.Id},dummyId));
        test.stopTest();

        List<OutboundCallout__c> outboundCallouts = [Select Id, Endpoint__c, Method__c, ContentTypeHeader__c, DataEventType__c,
                                                    ResponseHandler__c, Status__c, CalloutTimeout__c, AcceptHeader__c, RecordId__c
                                                    From OutboundCallout__c];
        
        //Successfully inserted?
        system.assertEquals(10, outboundCallouts.size());
    
        //Defaults applied? 
        for(OutboundCallout__c oc : outboundCallouts){
            system.assertEquals('callout=Test/Scheduled/12345', oc.Endpoint__c);//<--- confirm the Endpoint is not overwritten
            system.assertEquals('GET', oc.Method__c);
            system.assertEquals('application/json', oc.ContentTypeHeader__c);
            system.assertEquals('Scheduled_Event_Type_DET_Sequence_Test', oc.DataEventType__c);
            system.assertEquals('TestHandler', oc.ResponseHandler__c);
            system.assertEquals(120000, oc.CalloutTimeout__c);
            system.assertEquals('*/*', oc.AcceptHeader__c);
            system.assertEquals(jobId, oc.RecordId__c);//<!-- Confirm all callouts share the same Record Id (Queueable Job Id)
        }

    }

    static testMethod void singleTestCase2b(){
        
        //Test Case 2b : Sequencing. Test sequencing is enforced across the job schedule

        ScheduledEventTypeProcessor.ocList = new List<OutboundCallout__c>();
        for(Integer i=0;i<10;i++){
            ScheduledEventTypeProcessor.ocList.add(new OutboundCallout__c(
                Endpoint__c = 'callout=Test/Scheduled/12345'
            ));
        }

        DataEventType__mdt scheduledEvent= DataEventType__mdt.getInstance('Scheduled_Event_Type_Job_Sequence_Test');
        Id dummyId = '08e8E00000aug2yQAA';

        system.assertEquals(0, [Select Count() From OutboundCallout__c]);

        test.startTest();
            Id jobId = System.enqueueJob(new ScheduledEventTypeProcessor(new List<Id>{scheduledEvent.Id},dummyId));
        test.stopTest();

        List<OutboundCallout__c> outboundCallouts = [Select Id, Endpoint__c, Method__c, ContentTypeHeader__c, DataEventType__c,
                                                    ResponseHandler__c, Status__c, CalloutTimeout__c, AcceptHeader__c, RecordId__c
                                                    From OutboundCallout__c];
        
        //Successfully inserted?
        system.assertEquals(10, outboundCallouts.size());
    
        //Defaults applied? 
        for(OutboundCallout__c oc : outboundCallouts){
            system.assertEquals('callout=Test/Scheduled/12345', oc.Endpoint__c);//<--- confirm the Endpoint is not overwritten
            system.assertEquals('GET', oc.Method__c);
            system.assertEquals('application/json', oc.ContentTypeHeader__c);
            system.assertEquals('Scheduled_Event_Type_Job_Sequence_Test', oc.DataEventType__c);
            system.assertEquals('TestHandler', oc.ResponseHandler__c);
            system.assertEquals(120000, oc.CalloutTimeout__c);
            system.assertEquals('*/*', oc.AcceptHeader__c);
            system.assertEquals(dummyId, oc.RecordId__c);//<!-- Confirm all callouts share the same Record Id (Schedulable Job Id)
        }

    }
}