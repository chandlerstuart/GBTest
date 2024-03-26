/*
Name: OutboundCalloutTest.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Test suite for OutboundCallout related classes and methods.

Coverage for classes below (target 85%):
DataEventTypeManager.cls : 16%
OutboundCalloutEventSubscriberHandler.cls : 100%
OutboundCalloutTriggerHandler.cls : 95%
OutboundCalloutProcessor.cls : 69%
OutboundCalloutSchedulable.cls : 95%

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-09-12  Initial development.
1.1  Mark Cane&    2019-09-22  Added singleTestCase4.
1.2  Mark Cane&    2019-10-09  Added singleTestCase5+6a+b.
1.3  Mark Cane&    2020-08-11  Added singleTestCase6c.
1.4  J Radcliffe   2020-02-15  Added singleTestCase5b.
1.5  Mark Cane&    2022-06-10  Refactored singleTestCase6b following switch of BlockedBy release to @future.
*/
@isTest(SeeAllData=false)
public with sharing class OutboundCalloutTest {
	/*
    Test cases:
        singleTestCase1 - PlatformEvent. OutboundCalloutEventSubscriberHandler test. Insert to OutboundCallout__c.
        singleTestCase2 - ApexTrigger. OutboundCalloutTriggerHandler test. Insert to OutboundCallout__c starts Processor.
        singleTestCase3 - Queueable. OutboundCalloutProcessor test. Processor callouts.
        singleTestCase4 - ScheduledApex. OutboundCalloutSchedulable test. Processor callouts.
        ..
        singleTestCase5a - ApexTrigger. Aborted status set on inserted Outbound callout when duplicate RecordId and DataEventType exists at New/Retrying status.
        singleTestCase5b - ApexTrigger. Aborted status set on inserted Outbound callout when Dupe Check Type = 'URL' and duplicate URL exists at New/Retrying status.
        singleTestCase6a - ApexTrigger. BlockedBy field set when duplicate RecordId exists at New/Retrying status.
        singleTestCase6b - ApexTrigger. Outbound callout processed when BlockedBy field cleared by Blocking request completion.
        singleTestCase6c - ApexTrigger. DET OutboundCalloutsPerProcessorCycle__c handling.
        ..
	*/
	
    @testSetup static void setup(){}
    
    /* **/
    static testMethod void singleTestCase1() {    
        // Test case 1 : PlatformEvent. OutboundCalloutEventSubscriberHandler test. Insert to OutboundCallout__c.

        OutboundCalloutEvent__e oce = new OutboundCalloutEvent__e(Endpoint__c='https://test', Method__c='GET',
                                                                    ContentTypeHeader__c='application/json',AcceptHeader__c='application/json',
                                                                    Body__c='test',DataEventType__c='Account_Update_Async_Queue_Test');

        Test.startTest();
        EventBus.publish(oce);
        Test.stopTest();

        System.assertEquals(1,[select count() from OutboundCallout__c where Status__c=:Label.Picklist_Value_OutboundCallout_Status_New]);
    }
    /* */

    /* **/
    static testMethod void singleTestCase2() {    
        // Test case 2 : ApexTrigger. OutboundCalloutTriggerHandler test. Insert to OutboundCallout__c starts Processor.

        enableProcessor();

        OutboundCallout__c oc = new OutboundCallout__c(Endpoint__c='https://test', Method__c='GET',
                                                        ContentTypeHeader__c='application/json',AcceptHeader__c='application/json',
                                                        Body__c='test',DataEventType__c='Account_Update_Async_Queue_Test');

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('singleTestCase1'));
        
        Test.startTest();
        insert oc;
        Test.stopTest();

        System.assertEquals(1,[select count() from AsyncApexJob where JobType='Queueable' and ApexClass.Name='OutboundCalloutProcessor']);
        System.assertEquals(1,[select count() from OutboundCallout__c where Status__c=:Label.Picklist_Value_OutboundCallout_Status_Complete]);
    }
    /* */

    /* **/
    static testMethod void singleTestCase3() {    
        // Test case 3 : Queueable. OutboundCalloutProcessor test. Processor callouts.

        enableProcessor();

        OutboundCallout__c oc = new OutboundCallout__c(Endpoint__c='https://test', Method__c='GET',
                                                        ContentTypeHeader__c='application/json',AcceptHeader__c='application/json',
                                                        Body__c='test',DataEventType__c='Account_Update_Async_Queue_Test');

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('singleTestCase1'));
        
        Test.startTest();
        insert oc;
        Test.stopTest();

        System.assertEquals(1,[select count() from AsyncApexJob where JobType='Queueable' and ApexClass.Name='OutboundCalloutProcessor']);
        System.assertEquals(1,[select count() from OutboundCallout__c where Status__c=:Label.Picklist_Value_OutboundCallout_Status_Complete]);

        oc = [select Id, ResponseBody__c, ResponseStatusCode__c, LastCalloutDate__c from OutboundCallout__c where Id=:oc.Id];

        System.assertEquals('{ "SalesforceClientID":"001b000000qDVy6AAZ", "GolfbreaksClientID":"ClubhouseIdValue" }',oc.ResponseBody__c);
        System.assertEquals(200,oc.ResponseStatusCode__c);
        System.assert(oc.LastCalloutDate__c!=null);
    }
    /* */

    /* **/
    static testMethod void singleTestCase4() {    
        // Test case 3 : ScheduledApex. OutboundCalloutSchedulable test. Processor callouts.

        insert new OutboundCallout__c(Endpoint__c='https://test', Method__c='GET',
                                                        ContentTypeHeader__c='application/json',AcceptHeader__c='application/json',
                                                        Body__c='test',DataEventType__c='Account_Update_Async_Queue_Test',
                                                        Status__c=Label.Picklist_Value_OutboundCallout_Status_Retrying,
                                                        RetryCount__c=1,
                                                        NextRetryDate__c=Datetime.now().addSeconds(-10));//<---- processor is not enabled.

        System.assertEquals(0,[select count() from OutboundCallout__c where ProcessorJobId__c<>null]);//<-- all oc are null

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('singleTestCase1'));

        Test.startTest();
        Id cronId = System.schedule('Outbound Callout Retry Processor', Datetime.now().addSeconds(10).format('ss mm HH dd M ? yyyy'), new OutboundCalloutSchedulable());
        Test.stopTest();

        System.assertEquals(1,[select count() from AsyncApexJob where JobType='Queueable' and ApexClass.Name='OutboundCalloutProcessor']);
        System.assertEquals(1,[select count() from OutboundCallout__c where ProcessorJobId__c<>null]);//<-- all oc are now not null
    }
    /* */  

    /* **/
    static testMethod void singleTestCase5a() {    
        // Test case 5 : ApexTrigger. Aborted status set on inserted Outbound callout when duplicate RecordId and DataEventType exists at New/Retrying status.

        Account a = new Account(Name='Unit test');
        a.BillingCity = 'Edinburgh';
        a.BillingCountry = 'UK';

        Account a2 = new Account(Name='Unit test 2');
        a2.BillingCity = 'London';
        a2.BillingCountry = 'UK';
        insert new List<Account> { a,a2 };

        insert new OutboundCallout__c(Endpoint__c='https://test', Method__c='GET',
                                        ContentTypeHeader__c='application/json',AcceptHeader__c='application/json',
                                        Body__c='test',DataEventType__c='Account_Update_Async_Queue_Test',
                                        RecordId__c=a.Id);        

        System.assertEquals(1,[select count() from OutboundCallout__c where Status__c=:Label.Picklist_Value_OutboundCallout_Status_New]);

        OutboundCallout__c oc2 = new OutboundCallout__c(Endpoint__c='https://test', Method__c='GET',
                                                        ContentTypeHeader__c='application/json',AcceptHeader__c='application/json',
                                                        Body__c='test',DataEventType__c='Account_Update_Async_Queue_Test',
                                                        RecordId__c=a.Id);//<--- dupe on record Id and DET

        OutboundCallout__c oc3 = new OutboundCallout__c(Endpoint__c='https://test', Method__c='GET',
                                                        ContentTypeHeader__c='application/json',AcceptHeader__c='application/json',
                                                        Body__c='test',DataEventType__c='Account_Update_Async_Queue_Test',
                                                        RecordId__c=a2.Id);
        
        Test.startTest();
        insert new List<OutboundCallout__c>{ oc2,oc3 };
        Test.stopTest();

        System.assertEquals(2,[select count() from OutboundCallout__c where Status__c=:Label.Picklist_Value_OutboundCallout_Status_New]);
        System.assertEquals(1,[select count() from OutboundCallout__c where Status__c=:Label.Picklist_Value_OutboundCallout_Status_Aborted and Id=:oc2.Id]);
    }
    /* */

    /* **/
    static testMethod void singleTestCase5b() {    
        // Test case 5 : ApexTrigger. Aborted status set on inserted Outbound callout when Dupe Check Type = 'URL' and duplicate URL exists at New/Retrying status.

        Account a = new Account(Name='Unit test');
        a.BillingCity = 'Edinburgh';
        a.BillingCountry = 'UK';

        Account a2 = new Account(Name='Unit test 2');
        a2.BillingCity = 'London';
        a2.BillingCountry = 'UK';
        insert new List<Account> { a,a2 };

        insert new OutboundCallout__c(Endpoint__c='https://test', Method__c='GET',
                                        ContentTypeHeader__c='application/json',AcceptHeader__c='application/json',
                                        Body__c='test',DataEventType__c='Lead_Update_Async_Queue_Test_URL_Dupe',
                                        RecordId__c=a.Id);        

        System.assertEquals(1,[select count() from OutboundCallout__c where Status__c=:Label.Picklist_Value_OutboundCallout_Status_New]);

        OutboundCallout__c oc2 = new OutboundCallout__c(Endpoint__c='https://test', Method__c='GET',//<--- dupe URL (a dupe)
                                                        ContentTypeHeader__c='application/json',AcceptHeader__c='application/json',
                                                        Body__c='test',DataEventType__c='Lead_Update_Async_Queue_Test_URL_Dupe',
                                                        RecordId__c=a.Id);

        OutboundCallout__c oc3 = new OutboundCallout__c(Endpoint__c='https://test1', Method__c='GET',//<--- unique url (not a dupe)
                                                        ContentTypeHeader__c='application/json',AcceptHeader__c='application/json',
                                                        Body__c='test',DataEventType__c='Lead_Update_Async_Queue_Test_URL_Dupe',
                                                        RecordId__c=a.Id);
        
        Test.startTest();
        insert new List<OutboundCallout__c>{ oc2,oc3 };
        Test.stopTest();

        System.assertEquals(2,[select count() from OutboundCallout__c where Status__c=:Label.Picklist_Value_OutboundCallout_Status_New]);
        System.assertEquals(1,[select count() from OutboundCallout__c where Status__c=:Label.Picklist_Value_OutboundCallout_Status_Aborted and Id=:oc2.Id]);
    }
    /* */

    /* **/
    static testMethod void singleTestCase6a() {    
        // Test case 6a : ApexTrigger. ApexTrigger. BlockedBy field set when duplicate RecordId exists at New/Retrying status.

        Account a = new Account(Name='Unit test');
        a.BillingCity = 'Edinburgh';
        a.BillingCountry = 'UK';

        Account a2 = new Account(Name='Unit test 2');
        a2.BillingCity = 'London';
        a2.BillingCountry = 'UK';
        insert new List<Account> { a,a2 };

        OutboundCallout__c oc1 = new OutboundCallout__c(Endpoint__c='https://test', Method__c='GET',
                                        ContentTypeHeader__c='application/json',AcceptHeader__c='application/json',
                                        Body__c='test',DataEventType__c='Account_Update_Async_Immediate_Bulk_Test',
                                        RecordId__c=a.Id);        
        insert oc1;

        System.assertEquals(1,[select count() from OutboundCallout__c where Status__c=:Label.Picklist_Value_OutboundCallout_Status_New]);

        OutboundCallout__c oc2 = new OutboundCallout__c(Endpoint__c='https://test', Method__c='GET',
                                                        ContentTypeHeader__c='application/json',AcceptHeader__c='application/json',
                                                        Body__c='test',DataEventType__c='Account_Update_Async_Immediate_Bulk_Test',
                                                        RecordId__c=a.Id);//<--- dupe on record Id

        OutboundCallout__c oc3 = new OutboundCallout__c(Endpoint__c='https://test', Method__c='GET',
                                                        ContentTypeHeader__c='application/json',AcceptHeader__c='application/json',
                                                        Body__c='test',DataEventType__c='Account_Update_Async_Immediate_Bulk_Test',
                                                        RecordId__c=a2.Id);
        
        Test.startTest();
        insert new List<OutboundCallout__c>{ oc2,oc3 };
        Test.stopTest();

        System.assertEquals(3,[select count() from OutboundCallout__c where Status__c=:Label.Picklist_Value_OutboundCallout_Status_New]);        
        System.assertEquals(1,[select count() from OutboundCallout__c where BlockedBy__c<>null and Id=:oc2.Id]);
        System.assertEquals(oc1.Id,[select BlockedBy__c from OutboundCallout__c where Id=:oc2.Id].BlockedBy__c);
    }
    /* */

    /* **/
    static testMethod void singleTestCase6b() {    
        // Test case 6b : ApexTrigger. Outbound callout processed when BlockedBy field cleared by Blocking request completion.

        Account a = new Account(Name='Unit test');
        a.BillingCity = 'Edinburgh';
        a.BillingCountry = 'UK';
        insert a;

        //create oc1 -- with fake processor job Id.
        //create oc2 -- blocked by oc1 with no processor job Id. 
        // execute processor explicity (no async) with override for processorJobId.
        // oc1 should process and fire future.
        // oc2 should be released on Test.stop and then complete (future=>queueable)

        OutboundCallout__c oc1 = new OutboundCallout__c(Endpoint__c='https://test', Method__c='GET',
                                        ContentTypeHeader__c='application/json',AcceptHeader__c='application/json',
                                        Body__c='test',DataEventType__c='Account_Update_Async_Immediate_Bulk_Test',
                                        RecordId__c=a.Id, ProcessorJobId__c=a.Id);
        insert oc1;

        OutboundCallout__c oc2 = new OutboundCallout__c(Endpoint__c='https://test', Method__c='GET',
                                                        ContentTypeHeader__c='application/json',AcceptHeader__c='application/json',
                                                        Body__c='test',DataEventType__c='Account_Update_Async_Immediate_Bulk_Test',
                                                        RecordId__c=a.Id,
                                                        BlockedBy__c=oc1.Id);
        insert oc2;

        System.assertEquals(1,[select count() from OutboundCallout__c where BlockedBy__c<>null and Id=:oc2.Id]);
        
        System.assertEquals(0,[select count() from AsyncApexJob where JobType='Queueable' and ApexClass.Name='OutboundCalloutProcessor']);

        enableProcessor();

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('singleTestCase1'));
        
        Test.startTest();

        OutboundCalloutProcessor p = new OutboundCalloutProcessor();
        p.processorJobIdOverrride = a.Id;
        p.execute(null);

        Test.stopTest();//<---future then queueable execute.
    
        System.assertEquals(1,[select count() from AsyncApexJob where JobType='Queueable' and ApexClass.Name='OutboundCalloutProcessor']);

        //System.debug(LoggingLevel.ERROR, [select Id,Name,ProcessorJobId__c,BlockedBy__c,Status__c from OutboundCallout__c where Id=:oc2.Id ]);

        System.assertEquals(2,[select count() from OutboundCallout__c where Status__c=:Label.Picklist_Value_OutboundCallout_Status_Complete]);
        System.assertEquals(1,[select count() from OutboundCallout__c where BlockedBy__c=null and Id=:oc2.Id]);
    }
    /* */     
    
    /* **/
    static testMethod void singleTestCase6c() {    
        // Test case 6c : ApexTrigger. ApexTrigger. DET OutboundCalloutsPerProcessorCycle__c handling.

        Account a = new Account(Name='Unit test');
        a.BillingCity = 'Edinburgh';
        a.BillingCountry = 'UK';

        Account a2 = new Account(Name='Unit test 2');
        a2.BillingCity = 'Edinburgh';
        a2.BillingCountry = 'UK';
        
        insert new List<Account>{ a,a2 };

        enableProcessor();

        OutboundCallout__c oc1 = new OutboundCallout__c(Endpoint__c='https://test', Method__c='GET',
                                        ContentTypeHeader__c='application/json',AcceptHeader__c='application/json',
                                        Body__c='test',DataEventType__c='Account_Update_Async_Queue_Test',
                                        RecordId__c=a.Id);        

        OutboundCallout__c oc2 = new OutboundCallout__c(Endpoint__c='https://test', Method__c='GET',
                                        ContentTypeHeader__c='application/json',AcceptHeader__c='application/json',
                                        Body__c='test',DataEventType__c='Account_Update_Async_Queue_Test',
                                        RecordId__c=a2.Id);        

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('singleTestCase1'));

        Test.startTest();
        insert new List<OutboundCallout__c>{ oc1,oc2 };

        System.assertEquals(2,[select count() from OutboundCallout__c where Status__c=:Label.Picklist_Value_OutboundCallout_Status_New and ProcessorJobId__c<>null]);

        Test.stopTest();//<---Processor executes twice due to DET OutboundCalloutsPerProcessorCycle__c.

        System.assertEquals(1,[select count() from AsyncApexJob where JobType='Queueable' and ApexClass.Name='OutboundCalloutProcessor']);
        // -- for now the record with the non-existent DET is skipped but set to Complete status this should be Aborted
        System.assertEquals(1,[select count() from OutboundCallout__c where Status__c=:Label.Picklist_Value_OutboundCallout_Status_Complete]);
    }
    /* */     

    private static void enableProcessor(){
        FrameworkSettings__c fs = new FrameworkSettings__c();
        fs.OutboundCalloutProcessorActive__c = true;
        fs.MaxOutboundCalloutRetryCount__c = 2;
        fs.OutboundCalloutsPerProcessorCycle__c = 10;
        fs.OutboundCalloutRetryInterval__c = 10;
        insert fs;
    }

    public class HttpResponseMockImpl implements HttpCalloutMock {
        private String responseBody;
        private Integer responseStatusCode;

        public HttpResponseMockImpl(String testCase){
            
            switch on testCase {
                when 'singleTestCase1' {
                    responseBody='{ "SalesforceClientID":"001b000000qDVy6AAZ", "GolfbreaksClientID":"ClubhouseIdValue" }';
                    responseStatusCode=200;
                }
            }
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            res.setStatusCode(responseStatusCode);
            return res;
        }
    }    
}