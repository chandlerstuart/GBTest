/*
Name: DataEventTypeTriggerTest.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Test suite for Data Event Type Trigger methods.

Coverage for classes below (target 85%):
DataEventTypeManager.cls : 52%	
DataEventTypeTriggerHandler.cls : 66%	

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-08-19  Initial development.
1.1  Mark Cane&    2019-09-11  Added singleTestCase2.
1.2  Mark Cane&    2019-10-16  Added negativeTestCase3.
1.3  Mark Cane&    2019-11-27  Modified singleTestCase2 to test OutboundCallout__c.CalloutTime__c field population.
1.4  J Radcliffe   2020-02-25  Test Setup & new method getReshapedPayloadsTest 
1.5  Mark Cane&    2020-02-26  Bug fixes.
1.6  Mark Cane&    2020-03-04  Extended singleTestCase2 to cover Request Format String.
1.7  Mark Cane&    2020-03-23  Added singleTestCase3.
1.8  Mark Cane&    2020-03-23  singleTestCase1 now tests DET [Is Deferred Formats?].
1.9  Mark Cane&    2020-08-12  Extended test method getReshapedPayloadsTest to cover special char escape.
1.10 J Radcliffe   2020-08-18  Added singleTestCase4 and negativeTestCase4 to test Delete DET Conditions.
1.11 J Radcliffe   2020-09-14  Added conditions for singleTestCase3 (Merge) and modified BillingCity to meet Condition 1. Created negativeTestCase5
*/
@isTest(SeeAllData=false)
public with sharing class DataEventTypeTriggerTest {
	/*
    Test cases:
        singleTestCase1 - ApexTrigger - Update. Async Immediate. All Conditions Pass Test. Deferred Formats.
        singleTestCase2 - ApexTrigger - Update. Async Queue. All Conditions Pass Test.
        singleTestCase3 - ApexTrigger - Merge. Async Immediate. All Conditions Pass Test.
        ..
        getReshapedPayloadsTest - Logic - OutboundCallout field deserializeUntype test.
        ..
        negativeTestCase1 - ApexTrigger - Update. Async Immediate. Partial Conditions Pass Test.
        negativeTestCase2 - ApexTrigger - Update. Async Immediate. All Conditions Pass Test. Unpopulated Format String Field.
        negativeTestCase3 - ApexTrigger - Update. Async Immediate. Switch to Async Queue for retries.
	*/
	
    @testSetup static void setup(){
        //1.4+
        Map<String,Object> dataMap = new Map<String,Object>();
        dataMap.put('testAttribute1', Integer.valueOf('1234'));
        dataMap.put('testAttribute2','MyClient');
        dataMap.put('testAttribute3', Decimal.valueOf('12.34'));
        dataMap.put('testAttribute4', system.today());
        dataMap.put('testAttribute5', system.now());
        dataMap.put('testAttribute6', true);
        insert new OutboundCallout__c(ReshapedPayloadBody__c=JSON.serialize(dataMap),//Set the expected reshaped payload property
                                    AcceptHeader__c='application/json',
                                    ContentTypeHeader__c='application/json',
                                    DataEventType__c='TestDataEvent',
                                    Endpoint__c='callout:testNameSpace/api/v1.0/fakeAPI',
                                    Method__c='GET');
    }
    
    /* **/
    static testMethod void singleTestCase1() {
        // Test case 1 : ApexTrigger - Update. Async Immediate. All Conditions Pass Test. Deferred Formats.
        
        //Account_Update_Async_I_Test_Condition_1=>Site,Equals,Test
        //Account_Update_Async_I_Test_Condition_2=>Description,Does not Equal,Test        
        //Account_Update_Async_I_Test_Condition_3=>BillingCity,IsChanged       
        
        Account a = new Account(Name='Unit test');
        a.Site = 'Test';//<---- Condition 1 pass
        a.Description = 'Not test';//<---- Condition 2 pass
        a.BillingCity = 'Edinburgh';
        a.BillingCountry = 'UK';
        insert a;


        DataEventTypeTriggerHandler th = new DataEventTypeTriggerHandler('Account');
        th.isExecuting = true;
        th.triggerOp = System.TriggerOperation.AFTER_UPDATE;// System Enum:BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, and AFTER_UNDELETE.
        th.newMap = new Map<Id,Sobject>{ a.Id=>a };        

        Account a2 = new Account(Id=a.Id, BillingCity='London', Description = 'Not test');
        th.oldMap = new Map<Id,Sobject>{ a2.Id=>a2 };//<---- Condition 2 pass - BillingCity has changed

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('singleTestCase1'));

        System.assertEquals(0,[select count() from OutboundCallout__c where DataEventType__c='Account_Update_Async_Immediate_Test']);

        Test.startTest();
        th.handleTriggerOperationType();
        Test.stopTest();

        System.assert(th.recordIdToChangedFields!=null);
        System.assert(!th.recordIdToChangedFields.isEmpty());
        System.assert(th.recordIdToChangedFields.containsKey(a.Id));
        System.assert(th.recordIdToChangedFields.get(a.Id).contains('BillingCity'));
        System.assert(th.dataEventTypeToRecordIds.containsKey('Account_Update_Async_Immediate_Test'));
        System.assert(th.dataEventTypeToRecordIds.get('Account_Update_Async_Immediate_Test').containsKey(a.Id));
        
        System.assert(th.recordIdToResult.containsKey(a.Id));
        System.assert(th.recordIdToResult.get(a.Id));

        System.assertEquals(1,[select count() from OutboundCallout__c where DataEventType__c='Account_Update_Async_Immediate_Test']);//<--- OC created on success case.

        OutboundCallout__c oc = [select Id,Body__c,Endpoint__c,CalloutTimeout__c from OutboundCallout__c where DataEventType__c='Account_Update_Async_Immediate_Test'];

        System.debug(LoggingLevel.ERROR,oc);

        System.assert(oc.Body__c!=null);
        System.assertEquals('{ "name":"Unit test","country":"UK","Site":"Test" }',oc.Body__c);

        System.assert(oc.Endpoint__c!=null);
        System.assert(oc.Endpoint__c.endsWithIgnoreCase('/name/Unit+test?country=UK&site=Test'));
  	}
    /* */

    /* **/
    static testMethod void singleTestCase2() {
        // Test case 2 : ApexTrigger - Update. Async Queue. All Conditions Pass Test.
        
        //Account_Update_Async_Q_Test_Condition_1=>Site,Equals,AsyncQTest

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

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('singleTestCase2'));

        System.assertEquals(0, [select count() from OutboundCallout__c where DataEventType__c='Account_Update_Async_Queue_Test']);

        Test.startTest();
        th.handleTriggerOperationType();
        Test.stopTest();

        System.assert(th.dataEventTypeToRecordIds.containsKey('Account_Update_Async_Queue_Test'));
        System.assert(th.dataEventTypeToRecordIds.get('Account_Update_Async_Queue_Test').containsKey(a.Id));
        
        System.assert(th.recordIdToResult.containsKey(a.Id));
        System.assert(th.recordIdToResult.get(a.Id));

        System.assertEquals(1, [select count() from OutboundCallout__c where DataEventType__c='Account_Update_Async_Queue_Test']);

        OutboundCallout__c oc = [select Id,Body__c,Endpoint__c,CalloutTimeout__c from OutboundCallout__c where DataEventType__c='Account_Update_Async_Queue_Test'];

        System.debug(LoggingLevel.ERROR,oc);

        System.assert(oc.Body__c!=null);
        System.assertEquals('{ "name":"Unit test","country":"UK","CreatedBy":"'+UserInfo.getFirstName()+' '+UserInfo.getLastName()+'" }',oc.Body__c);
        System.assert(oc.Endpoint__c!=null);
        System.assertEquals('callout:Test/name/Unit+test?country=UK&site=AsyncQTest',oc.Endpoint__c);
        System.assertEquals(31000, oc.CalloutTimeout__c);//<---- set on the Custom Metadata Record.
  	}
    /* */       

    /* **/
    static testMethod void singleTestCase3() {
        // Test case 3 : ApexTrigger - Merge. Async Immediate.
        
        Account masterAccount = new Account(Name='Unit test');
        masterAccount.Site = 'Test';
        masterAccount.Description = 'Not test';
        masterAccount.BillingCity = 'London';
        masterAccount.BillingCountry = 'UK';
        insert masterAccount;

        Account sourceAccount = new Account(Name='Unit2 test2');
        sourceAccount.Site = 'Test2';
        sourceAccount.Description = 'Not test';
        sourceAccount.BillingCity = 'London';
        sourceAccount.BillingCountry = 'United Kingdom';        
        insert sourceAccount;


        DataEventTypeTriggerHandler th = new DataEventTypeTriggerHandler('Account');
        th.isExecuting = true;
        th.overrideMasterRecId = masterAccount.Id;

        th.triggerOp = System.TriggerOperation.AFTER_DELETE;// System Enum:BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, and AFTER_UNDELETE.                
        th.oldMap = new Map<Id,Sobject>{ sourceAccount.Id=>sourceAccount };        

        th.handleTriggerOperationType();

        System.assertNotEquals(null,DataEventTypeTriggerHandler.masterRecordIdToSourceRecordIds);
        System.assert(DataEventTypeTriggerHandler.masterRecordIdToSourceRecordIds.containsKey(masterAccount.Id));
        System.assert(DataEventTypeTriggerHandler.masterRecordIdToSourceRecordIds.get(masterAccount.Id).contains(sourceAccount.Id));

        th = new DataEventTypeTriggerHandler('Account');
        th.isExecuting = true;
        th.triggerOp = System.TriggerOperation.AFTER_UPDATE;// System Enum:BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, and AFTER_UNDELETE.
        th.newMap = new Map<Id,Sobject>{ masterAccount.Id=>masterAccount };        

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('singleTestCase3'));

        System.assertEquals(1,[select count() from OutboundCallout__c]);

        Test.startTest();
        th.handleTriggerOperationType();
        Test.stopTest();

        system.debug('OCS:'+JSON.serialize([Select Id,DataEventType__c From OutboundCallout__c]));

        System.assertEquals(2,[select count() from OutboundCallout__c]);
        System.assertEquals(1,[select count() from OutboundCallout__c where DataEventType__c='Account_Merge_Async_Immediate_Test']);//<--- OC created on success case.
  	}
    /* */     
    
    /* **/
    static testMethod void singleTestCase4() {
        // Test case 4 : ApexTrigger - Delete. Async Immediate.
        
        Account accountRecord = new Account(Name='Unit test');
        accountRecord.Site = 'Test';
        accountRecord.Description = 'Not test';
        accountRecord.BillingCity = 'Edinburgh';//<---- Condition 1 pass
        accountRecord.BillingCountry = 'UK';
        insert accountRecord;


        DataEventTypeTriggerHandler th = new DataEventTypeTriggerHandler('Account');
        th.isExecuting = true;

        th.triggerOp = System.TriggerOperation.AFTER_DELETE;// System Enum:BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, and AFTER_UNDELETE.                
        th.oldMap = new Map<Id,Sobject>{ accountRecord.Id=>accountRecord };        

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('singleTestCase4'));

        System.assertEquals(1,[select count() from OutboundCallout__c]);

        Test.startTest();
        th.handleTriggerOperationType();
        Test.stopTest();

        System.assertEquals(1,[select count() from OutboundCallout__c where DataEventType__c='Account_Delete_Async_Immediate_Test']);//<--- OC created on success case.
  	}
    /* */     

    /* **/
    static testMethod void negativeTestCase1() {
        // Negative Test case 1 : ApexTrigger - Update. Async Immediate. Partial Conditions Pass Test.
        
        //Account_Update_Async_I_Test_Condition_1=>Site,Equals,Test
        //Account_Update_Async_I_Test_Condition_1=>Description,Does not Equal,Test        
        //Account_Update_Async_I_Test_Condition_1=>BillingCity,IsChanged        

        Account a = new Account(Name='Unit test');
        a.Site = 'Test';//<---- Condition 1 pass
        a.Description = 'Test';//<---- Condition 2 does not pass
        a.BillingCity = 'Edinburgh';
        a.BillingCountry = 'UK';
        insert a;

        DataEventTypeTriggerHandler th = new DataEventTypeTriggerHandler('Account');
        th.isExecuting = true;
        th.triggerOp = System.TriggerOperation.AFTER_UPDATE;// System Enum:BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, and AFTER_UNDELETE.
        th.newMap = new Map<Id,Sobject>{ a.Id=>a };    

        Account a2 = new Account(Id=a.Id, BillingCity='London');
        th.oldMap = new Map<Id,Sobject>{ a2.Id=>a2 };//<---- Condition 2 pass - BillingCity has changed

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('negativeTestCase1'));

        Test.startTest();
        th.handleTriggerOperationType();
        Test.stopTest();

        System.assert(!th.dataEventTypeToRecordIds.containsKey('Account_Update_Async_Immediate_Test'));
  	}
    /* */     

    /* **/
    static testMethod void negativeTestCase2() {
        // Negative Test case 1 : ApexTrigger - Update. Async Immediate. All Conditions Pass Test. Unpopulated Format String Field.
        
        //Account_Update_Test_Condition_1=>Site,Equals,Test
        //Account_Update_Test_Condition_2=>Description,Does not Equal,Test        
        //Account_Update_Test_Condition_3=>BillingCity,IsChanged        

        Account a = new Account(Name='Unit test');
        a.Site = 'Test';//<---- Condition 1 pass
        a.Description = 'Not test';//<---- Condition 2 pass
        a.BillingCity = 'Edinburgh';
        a.BillingCountry = null;//<---- Format String field unpopulated.
        insert a;

        DataEventTypeTriggerHandler th = new DataEventTypeTriggerHandler('Account');
        th.isExecuting = true;
        th.triggerOp = System.TriggerOperation.AFTER_UPDATE;// System Enum:BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, and AFTER_UNDELETE.
        th.newMap = new Map<Id,Sobject>{ a.Id=>a };    

        Account a2 = new Account(Id=a.Id, BillingCity='London', Description = 'Not test');
        th.oldMap = new Map<Id,Sobject>{ a2.Id=>a2 };//<---- Condition 2 pass - BillingCity has changed

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('negativeTestCase2'));

        Test.startTest();
        th.handleTriggerOperationType();
        Test.stopTest();

        System.assert(th.recordIdToChangedFields!=null);
        System.assert(!th.recordIdToChangedFields.isEmpty());
        System.assert(th.recordIdToChangedFields.containsKey(a.Id));
        System.assert(th.recordIdToChangedFields.get(a.Id).contains('BillingCity'));
        System.assert(th.dataEventTypeToRecordIds.containsKey('Account_Update_Async_Immediate_Test'));
        System.assert(th.dataEventTypeToRecordIds.get('Account_Update_Async_Immediate_Test').containsKey(a.Id));
        
        System.assert(th.recordIdToResult.containsKey(a.Id));
        System.assert(th.recordIdToResult.get(a.Id));
  	}
    /* */  

    /* **/
    static testMethod void negativeTestCase3() {
        // Test case 3 : ApexTrigger - Update. Async Immediate. Switch to Async Queue for retries.
        
        //Account_Update_Async_I_Test_Condition_1=>Site,Equals,Test
        //Account_Update_Async_I_Test_Condition_2=>Description,Does not Equal,Test        
        //Account_Update_Async_I_Test_Condition_3=>BillingCity,IsChanged        

        Account a = new Account(Name='Unit test');
        a.Site = 'Test';//<---- Condition 1 pass
        a.Description = 'Not test';//<---- Condition 2 pass
        a.BillingCity = 'Edinburgh';
        a.BillingCountry = 'UK';
        insert a;

        DataEventTypeTriggerHandler th = new DataEventTypeTriggerHandler('Account');
        th.isExecuting = true;
        th.triggerOp = System.TriggerOperation.AFTER_UPDATE;// System Enum:BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, and AFTER_UNDELETE.
        th.newMap = new Map<Id,Sobject>{ a.Id=>a };    

        Account a2 = new Account(Id=a.Id, BillingCity='London', Description = 'Not test');
        th.oldMap = new Map<Id,Sobject>{ a2.Id=>a2 };//<---- Condition 2 pass - BillingCity has changed

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('negativeTestCase3'));

        System.assertEquals(0, [select count() from OutboundCallout__c where DataEventType__c='Account_Update_Async_Immediate_Test']);

        Test.startTest();
        th.handleTriggerOperationType();
        Test.stopTest();

        System.assertEquals(1, [select count() from OutboundCallout__c where DataEventType__c='Account_Update_Async_Immediate_Test']);
  	}
    /* */     

    /* **/
    static testMethod void negativeTestCase4() {
        // Test case 4 : ApexTrigger - Delete. Async Immediate.
        
        Account accountRecord = new Account(Name='Unit test');
        accountRecord.Site = 'Test';
        accountRecord.Description = 'Not test';
        accountRecord.BillingCity = 'London';//<---- Condition 1 fail
        accountRecord.BillingCountry = 'UK';
        insert accountRecord;


        DataEventTypeTriggerHandler th = new DataEventTypeTriggerHandler('Account');
        th.isExecuting = true;

        th.triggerOp = System.TriggerOperation.AFTER_DELETE;// System Enum:BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, and AFTER_UNDELETE.                
        th.oldMap = new Map<Id,Sobject>{ accountRecord.Id=>accountRecord };        

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('singleTestCase4'));

        System.assertEquals(1,[select count() from OutboundCallout__c]);

        Test.startTest();
        th.handleTriggerOperationType();
        Test.stopTest();

        System.assertEquals(0,[select count() from OutboundCallout__c where DataEventType__c='Account_Delete_Async_Immediate_Test']);//<--- OC created on success case.
  	}
    /* */

    /* **/
    static testMethod void negativeTestCase5() {
        // Test case 4 : ApexTrigger - Delete. Async Immediate.
        
        Account masterAccount = new Account(Name='Unit test');
        masterAccount.Site = 'Test';
        masterAccount.Description = 'Not test';
        masterAccount.BillingCity = 'Edinburgh';//Fail Condition 1
        masterAccount.BillingCountry = 'UK';
        insert masterAccount;

        Account sourceAccount = new Account(Name='Unit2 test2');
        sourceAccount.Site = 'Test2';
        sourceAccount.Description = 'Not test';
        sourceAccount.BillingCity = 'London';
        sourceAccount.BillingCountry = 'United Kingdom';        
        insert sourceAccount;


        DataEventTypeTriggerHandler th = new DataEventTypeTriggerHandler('Account');
        th.isExecuting = true;
        th.overrideMasterRecId = masterAccount.Id;

        th.triggerOp = System.TriggerOperation.AFTER_DELETE;// System Enum:BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, and AFTER_UNDELETE.                
        th.oldMap = new Map<Id,Sobject>{ sourceAccount.Id=>sourceAccount };        

        th.handleTriggerOperationType();

        System.assertNotEquals(null,DataEventTypeTriggerHandler.masterRecordIdToSourceRecordIds);
        System.assert(DataEventTypeTriggerHandler.masterRecordIdToSourceRecordIds.containsKey(masterAccount.Id));
        System.assert(DataEventTypeTriggerHandler.masterRecordIdToSourceRecordIds.get(masterAccount.Id).contains(sourceAccount.Id));

        th = new DataEventTypeTriggerHandler('Account');
        th.isExecuting = true;
        th.triggerOp = System.TriggerOperation.AFTER_UPDATE;// System Enum:BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, and AFTER_UNDELETE.
        th.newMap = new Map<Id,Sobject>{ masterAccount.Id=>masterAccount };        

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('singleTestCase3'));

        System.assertEquals(1,[select count() from OutboundCallout__c]);

        Test.startTest();
        th.handleTriggerOperationType();
        Test.stopTest();

        system.debug('OCS:'+JSON.serialize([Select Id,DataEventType__c From OutboundCallout__c]));

        System.assertEquals(1,[select count() from OutboundCallout__c]);
        System.assertEquals(0,[select count() from OutboundCallout__c where DataEventType__c='Account_Merge_Async_Immediate_Test']);//<--- OC not created (failed conditions).
    }/* */

    /* **/
    static testMethod void bulkTestCase1() {
        // Bulk Test case 1 : ApexTrigger - Update. Async Queue. All Conditions Pass Test.
        
        //Account_Update_Async_Q_Test_Condition_1=>Site,Equals,AsyncQTest

        List<Account> accountsToInsert = new List<Account>(); 

        Account a = new Account(Name='Unit test');
        a.Site = 'AsyncQTest';//<---- Condition 1 a pass
        a.BillingCity = 'London';
        a.BillingCountry = 'UK';
        accountsToInsert.add(a);

        Account a2 = new Account(Name='Unit test2');
        a2.Site = 'AsyncQTest';//<---- Condition 1 a pass
        a2.BillingCity = 'London';
        a2.BillingCountry = 'UK';
        accountsToInsert.add(a2);        

        insert accountsToInsert;

        DataEventTypeTriggerHandler th = new DataEventTypeTriggerHandler('Account');
        th.isExecuting = true;
        th.triggerOp = System.TriggerOperation.AFTER_UPDATE;// System Enum:BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, and AFTER_UNDELETE.
        th.newMap = new Map<Id,Sobject>{ a.Id=>a, a2.Id=>a2 };
        th.oldMap = new Map<Id,Sobject>{ a.Id=>a, a2.Id=>a2 };    

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('singleTestCase2'));

        System.assertEquals(0, [select count() from OutboundCallout__c where DataEventType__c='Account_Update_Async_Queue_Test']);

        Test.startTest();
        th.handleTriggerOperationType();
        Test.stopTest();

        System.assert(th.dataEventTypeToRecordIds.containsKey('Account_Update_Async_Queue_Test'));
        System.assert(th.dataEventTypeToRecordIds.get('Account_Update_Async_Queue_Test').containsKey(a.Id));
        System.assert(th.dataEventTypeToRecordIds.get('Account_Update_Async_Queue_Test').containsKey(a2.Id));
        
        System.assert(th.recordIdToResult.containsKey(a.Id));
        System.assert(th.recordIdToResult.get(a.Id));

        System.assert(th.recordIdToResult.containsKey(a2.Id));
        System.assert(th.recordIdToResult.get(a2.Id));

        System.assertEquals(2, [select count() from OutboundCallout__c where DataEventType__c='Account_Update_Async_Queue_Test']);

        OutboundCallout__c oc = [select Id,Body__c,Endpoint__c,CalloutTimeout__c from OutboundCallout__c where RecordId__c=:a.Id and DataEventType__c='Account_Update_Async_Queue_Test' ];
        OutboundCallout__c oc2 = [select Id,Body__c,Endpoint__c,CalloutTimeout__c from OutboundCallout__c where RecordId__c=:a2.Id and DataEventType__c='Account_Update_Async_Queue_Test' ];

        System.debug(LoggingLevel.ERROR,oc);
        System.debug(LoggingLevel.ERROR,oc2);

        System.assert(oc.Body__c!=null);
        System.assert(oc2.Body__c!=null);
        System.assertEquals('{ "name":"Unit test","country":"UK","CreatedBy":"'+UserInfo.getFirstName()+' '+UserInfo.getLastName()+'" }',oc.Body__c);
        System.assertEquals('{ "name":"Unit test2","country":"UK","CreatedBy":"'+UserInfo.getFirstName()+' '+UserInfo.getLastName()+'" }',oc2.Body__c);
        System.assert(oc.Endpoint__c!=null);
        System.assert(oc2.Endpoint__c!=null);
        System.assertEquals('callout:Test/name/Unit+test?country=UK&site=AsyncQTest',oc.Endpoint__c);
        System.assertEquals('callout:Test/name/Unit+test2?country=UK&site=AsyncQTest',oc2.Endpoint__c);
        System.assertEquals(31000, oc.CalloutTimeout__c);//<---- set on the Custom Metadata Record.
        System.assertEquals(31000, oc2.CalloutTimeout__c);//<---- set on the Custom Metadata Record.
  	}/* */    
    
    //1.4+
    static testMethod void getReshapedPayloadsTest(){
        OutboundCallout__c oc = [Select Id, ReshapedPayloadBody__c From OutboundCallout__c Limit 1];
        test.startTest();
            Map<String,Object> dataMap = (Map<String,Object>)JSON.deserializeUntyped(DataEventTypeManager.getReshapedPayloads(new Set<Id>{oc.Id})[0]);
        test.stopTest();

        system.assertEquals(true, dataMap.containsKey('testAttribute1'));
        system.assertEquals(true, dataMap.containsKey('testAttribute2'));
        system.assertEquals(true, dataMap.containsKey('testAttribute3'));
        system.assertEquals(true, dataMap.containsKey('testAttribute4'));
        system.assertEquals(true, dataMap.containsKey('testAttribute5'));
        system.assertEquals(true, dataMap.containsKey('testAttribute6'));


        String jsonRequestBody = '{ "kaptioItineraryId" : "a0h4H000009s2MjQAI", "masterAccountId" : "0013z00002TgJj2AAF", "masterOpportunityId" : "0063z000015s4rNAAQ", "bookingNumber" : "SC16450", "currencyISOCode" : "DKK", "salesAgentId" : "005b0000002Fc4vAAC", "salesRegion" : "Portugal", "numberOfGuests" : "4", "travelDate" : "2020-08-30", "travelReturnDate" : "2020-09-04", "description" : "DESCRIPTION:acme';
        jsonRequestBody+='\n \\ | \' -@! %4$^&*()<>??/ er kun rejsedeltagere.2 golftasker ønskes med på fly.Evt. transport fra/til lufthavn.. | GROUP SIZE: 4. | DEPARTURE AIRPORT: Billund (Flights requested). | CALLBACK: No.", "isCancelled" : false, "cancelledDate" : "", "salesPriceGross" : "23392.00", "grossProfit" : "2389.65", "grossProfitBCY" : "1911.72", "costPriceGross" : "21002.35", "costPriceBCY" : "21002.35", "amountPaid" : "23392.00", "grossProfitCCY" : "224.91", "itineraryItemAccountName" : "Hotel Quinta da Marinha" }'; 
        
        jsonRequestBody = WebhookManager.escapeSpecialCharacters(jsonRequestBody);//testvisible.
        
        Boolean isError=false;
        Object originalObject;

        try {
            originalObject = (Map<String,Object>)JSON.deserializeUntyped(jsonRequestBody);
        } catch (Exception e){
            isError=true;
        }
        System.assert(!isError);        
    }   
    
    static testMethod void getJSONSafeFormatStringTest(){

        String formatString = '{ company : {0}, { employees : {1} } }';
        String templateString = '{ company : acme, { employees : 99 } }';

        List<Object> formatParameters = new List<Object>{ 'acme', 99 };

        String formattedString = FormatStringHelper.getJSONSafeFormatString(formatString, formatParameters);

        System.assertEquals(templateString,formattedString);
    }

    public class HttpResponseMockImpl implements HttpCalloutMock {
        private String responseBody;
        private Integer responseStatusCode;

        public HttpResponseMockImpl(String testCase){
            
            switch on testCase {
                when 'singleTestCase1','singleTestCase2','singleTestCase3','singleTestCase4','negativeTestCase1','negativeTestCase2','negativeTestCase4' {
                    responseBody='{ "SalesforceClientID":"001b000000qDVy6AAZ", "GolfbreaksClientID":"ClubhouseIdValue" }';
                    responseStatusCode=200;
                } when 'negativeTestCase3' {
                    responseBody='{ "SalesforceClientID":"001b000000qDVy6AAZ", "GolfbreaksClientID":"ClubhouseIdValue" }';
                    responseStatusCode=423;
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