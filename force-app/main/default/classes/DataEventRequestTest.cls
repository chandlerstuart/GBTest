/*
Name: DataEventRequestTest.cls
Copyright © 2022  Golfbreaks
======================================================
======================================================
Purpose:
-------

Test suite for DataEventRequest related classes and methods.

Coverage for classes below (target 85%):
DataEventRequestTriggerHandler.cls : 93%
DataEventRequestSchedulable.cls : 90%
DeferredDataEventTypeHelper.cls : 88%

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2022-06-20  Initial development.
1.1  Mark Cane&    2022-09-14  Extended singleTestcase3.
*/
@isTest(SeeAllData=false)
public with sharing class DataEventRequestTest {
	/*
    Test cases:
        singleTestCase1a - ApexTrigger - DataEventTypeTrigger. Update. Async Queue.
        singleTestCase1b - ApexTrigger - DataEventTypeTrigger. Update. Async Queue. Parent Record Id.
        singleTestCase2a - ApexTrigger. Insert. DataEventRequestTriggerHandler test.
        singleTestCase2b - ApexTrigger. Insert. DataEventRequestTriggerHandler test. 2nd request for the same record Id/DET.
        singleTestCase2c - ApexTrigger. Update. DataEventRequestTriggerHandler test.
        singleTestCase3 - ScheduledApex. DataEventRequestSchedulable test. Extended to cover DET.DeferredRequestsPerSchedulable__c, which is set to 1 for the DET.
        ..
        negativeTestCase1 - ScheduledApex. DataEventRequestSchedulable test with non-Id recordId.
	*/
	
    @testSetup static void setup(){ }
    
    /* **/
    static testMethod void singleTestCase1a(){
        //ApexTrigger - DataEventTypeTrigger. Update. Async Queue.

        Account a = new Account(Name='Unit test');
        a.Site = 'AsyncQTest';//<---- Condition 1 a pass
        a.BillingCity = 'London';
        a.BillingCountry = 'UK';
        insert a;

        DataEventTypeTriggerHandler th = new DataEventTypeTriggerHandler('Account');
        th.isExecuting = true;
        th.triggerOp = System.TriggerOperation.AFTER_UPDATE;// System Enum:BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, and AFTER_UNDELETE.
        th.newMap = new Map<Id,Sobject>{ a.Id=>a };    

        Account a2 = new Account(Id=a.Id, Site='Test');//<---- Condition 1 previously not a pass
        th.oldMap = new Map<Id,Sobject>{ a2.Id=>a2 };

        DataEventTypeManager.isDeferredOverride = true;

        System.assertEquals(0, [select count() from DataEventRequest__c where RecordId__c=:a.Id and DataEventType__c='Account_Update_Async_Queue_Test']);

        Test.startTest();
        th.handleTriggerOperationType();
        Test.stopTest();

        System.assertEquals(1, [select count() from DataEventRequest__c where RecordId__c=:a.Id and DataEventType__c='Account_Update_Async_Queue_Test']);    
    }/* */

    /* **/
    static testMethod void singleTestCase1b(){
        //ApexTrigger - DataEventTypeTrigger. Update. Async Queue. Parent Record Id.

        Account pa = new Account(Name='Unit test Parent');
        insert pa;

        Account a = new Account(Name='Unit test');
        a.Site = 'AsyncQTest';//<---- Condition 1 a pass
        a.BillingCity = 'London';
        a.BillingCountry = 'UK';
        a.ParentId = pa.Id;
        insert a;

        DataEventTypeTriggerHandler th = new DataEventTypeTriggerHandler('Account');
        th.isExecuting = true;
        th.triggerOp = System.TriggerOperation.AFTER_UPDATE;// System Enum:BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, and AFTER_UNDELETE.
        th.newMap = new Map<Id,Sobject>{ a.Id=>a };    

        Account a2 = new Account(Id=a.Id, Site='Test');//<---- Condition 1 previously not a pass
        th.oldMap = new Map<Id,Sobject>{ a2.Id=>a2 };

        DataEventTypeManager.isDeferredOverride = true;
        DeferredDataEventTypeHelper.parentFieldNameOverride = 'ParentId';

        System.assertEquals(0, [select count() from DataEventRequest__c where RecordId__c=:pa.Id and DataEventType__c='Account_Update_Async_Queue_Test']);

        Test.startTest();
        th.handleTriggerOperationType();
        Test.stopTest();

        System.assertEquals(1, [select count() from DataEventRequest__c where RecordId__c=:pa.Id and DataEventType__c='Account_Update_Async_Queue_Test']);    
    }/* */  
    
    /* **/
    static testMethod void singleTestCase2a(){
        //ApexTrigger. Insert. DataEventRequestTriggerHandler test.

        Account a = new Account(Name='Unit test');
        a.BillingCity = 'London';
        a.BillingCountry = 'UK';
        insert a;

        System.assertEquals(0, [select count() from OutboundCallout__c where DataEventType__c='Account_Update_Async_Queue_Test']);
        System.assertEquals(0, [select count() from CronTrigger where State not in ('COMPLETE','ERROR','DELETED') and CronJobDetail.Name like 'Account_Update_Async_Queue_Test Deferred%']);

        Test.startTest();
        insert new DataEventRequest__c(RecordId__c=a.Id,Status__c='New',CalloutDate__c=Datetime.now().addSeconds(10),DataEventType__c='Account_Update_Async_Queue_Test');
        Test.stopTest();

        //System.assertEquals(1, [select count() from CronTrigger where State in ('COMPLETE','ERROR','DELETED') and CronJobDetail.Name like 'Account_Update_Async_Queue_Test Deferred%']);
        System.assertEquals(1, [select count() from OutboundCallout__c where DataEventType__c='Account_Update_Async_Queue_Test']);

    }/* */     

    /* **/
    static testMethod void singleTestCase2b(){
        //ApexTrigger. Insert. DataEventRequestTriggerHandler test. 2nd request for the same record Id/DET.

        Datetime dt1 = Datetime.now().addSeconds(100);
        Datetime dt2 = Datetime.now().addSeconds(10);

        Account a = new Account(Name='Unit test');
        a.BillingCity = 'London';
        a.BillingCountry = 'UK';
        insert a;

        insert new DataEventRequest__c(RecordId__c=a.Id,Status__c='New',CalloutDate__c=dt1,DataEventType__c='Account_Update_Async_Queue_Test');

        System.debug(LoggingLevel.ERROR,dt1);
        System.debug(LoggingLevel.ERROR,[select Id, NextFireTime from CronTrigger]);
        System.assertEquals(1, [select count() from CronTrigger where NextFireTime=:dt1]);

        Test.startTest();
        insert new DataEventRequest__c(RecordId__c=a.Id,Status__c='New',CalloutDate__c=dt2,DataEventType__c='Account_Update_Async_Queue_Test');
        Test.stopTest();

        System.debug(LoggingLevel.ERROR,dt2);
        System.debug(LoggingLevel.ERROR,[select Id, State, NextFireTime from CronTrigger]);

        //System.assertEquals(0, [select count() from CronTrigger where NextFireTime=:dt1 and CronJobDetail.Name like 'Account_Update_Async_Queue_Test Deferred%']);
        //System.assertEquals(1, [select count() from CronTrigger where NextFireTime=:dt2 and CronJobDetail.Name like 'Account_Update_Async_Queue_Test Deferred%']);
        System.assertEquals(1, [select count() from OutboundCallout__c where DataEventType__c='Account_Update_Async_Queue_Test']);        
    }/* */

    /* **/
    static testMethod void singleTestCase2c(){
        //ApexTrigger. Update. DataEventRequestTriggerHandler test.

        Datetime dt1 = Datetime.now().addSeconds(100);
        Datetime dt2 = Datetime.now().addSeconds(10);

        Account a = new Account(Name='Unit test');
        a.BillingCity = 'London';
        a.BillingCountry = 'UK';
        insert a;

        DataEventRequest__c der = new DataEventRequest__c(RecordId__c=a.Id,Status__c='New',CalloutDate__c=dt1,DataEventType__c='Account_Update_Async_Queue_Test');
        insert der;

        System.debug(LoggingLevel.ERROR,dt1);
        System.debug(LoggingLevel.ERROR,[select Id, NextFireTime from CronTrigger]);
        System.assertEquals(1, [select count() from CronTrigger where NextFireTime=:dt1]);

        der.CalloutDate__c=dt2;

        Test.startTest();
        update der;
        Test.stopTest();

        System.debug(LoggingLevel.ERROR,dt2);
        System.debug(LoggingLevel.ERROR,[select Id, State, NextFireTime from CronTrigger]);

        //System.assertEquals(0, [select count() from CronTrigger where NextFireTime=:dt1 and CronJobDetail.Name like 'Account_Update_Async_Queue_Test Deferred%']);
        //System.assertEquals(1, [select count() from CronTrigger where NextFireTime=:dt2 and CronJobDetail.Name like 'Account_Update_Async_Queue_Test Deferred%']);
        System.assertEquals(1, [select count() from OutboundCallout__c where DataEventType__c='Account_Update_Async_Queue_Test']);        
    }/* */    

    /* **/
    static testMethod void singleTestCase3(){
        //ScheduledApex. DataEventRequestSchedulable test. Extended to cover DET.DeferredRequestsPerSchedulable__c, which is set to 1 for the DET.

        Account a = new Account(Name='Unit test');
        a.BillingCity = 'London';
        a.BillingCountry = 'UK';
        a.Site = 'AsyncQTest';
        insert a;

        Account a2 = new Account(Name='Unit test2');
        a2.BillingCity = 'London2';
        a2.BillingCountry = 'GB';
        a2.Site = 'AsyncQTest2';
        insert a2;        

        Test.startTest();
        insert new List<DataEventRequest__c>{   new DataEventRequest__c(RecordId__c=a.Id,Status__c='New',CalloutDate__c=Datetime.now().addSeconds(100),DataEventType__c='Account_Update_Async_Queue_Test'),
                                                new DataEventRequest__c(RecordId__c=a2.Id,Status__c='New',CalloutDate__c=Datetime.now().addSeconds(90),DataEventType__c='Account_Update_Async_Queue_Test') };
        //DataEventRequestSchedulable s = new DataEventRequestSchedulable('Account_Update_Async_Queue_Test');
        //s.execute(null);        
        Test.stopTest();

        System.assertEquals(1, [select count() from OutboundCallout__c where DataEventType__c='Account_Update_Async_Queue_Test']);

        OutboundCallout__c oc = [select Id,Body__c,Endpoint__c,CalloutTimeout__c from OutboundCallout__c where DataEventType__c='Account_Update_Async_Queue_Test'];

        System.debug(LoggingLevel.ERROR,oc);

        System.assert(oc.Body__c!=null);
        System.assertEquals('{ "name":"Unit test","country":"UK","CreatedBy":"'+UserInfo.getFirstName()+' '+UserInfo.getLastName()+'" }',oc.Body__c);
        System.assert(oc.Endpoint__c!=null);
        System.assertEquals('callout:Test/name/Unit+test?country=UK&site=AsyncQTest',oc.Endpoint__c);
        System.assertEquals(31000, oc.CalloutTimeout__c);//<---- set on the Custom Metadata Record.
        
        System.assertEquals(1, [select count() from DataEventRequest__c where RecordId__c=:a.Id and DataEventType__c='Account_Update_Async_Queue_Test' and Status__c='Complete']);
        System.assertEquals(1, [select count() from DataEventRequest__c where RecordId__c=:a2.Id and DataEventType__c='Account_Update_Async_Queue_Test' and Status__c='New']);
    }/* */ 
    
    /* **/
    static testMethod void negativeTestCase1(){
        //ScheduledApex. ScheduledApex. DataEventRequestSchedulable test with non-Id recordId.

        Account a = new Account(Name='Unit test');
        a.BillingCity = 'London';
        a.BillingCountry = 'UK';
        a.Site = 'AsyncQTest';
        insert a;

        Test.startTest();
        insert new DataEventRequest__c(RecordId__c='NOTANID',Status__c='New',CalloutDate__c=Datetime.now().addSeconds(100),DataEventType__c='Account_Update_Async_Queue_Test');
        DataEventRequestSchedulable s = new DataEventRequestSchedulable('Account_Update_Async_Queue_Test');
        s.execute(null);        
        Test.stopTest();

        System.assertEquals(1, [select count() from DataEventRequest__c where DataEventType__c='Account_Update_Async_Queue_Test' and Status__c='Aborted']);
    }/* */     
}