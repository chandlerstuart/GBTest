/*
Name: DataEventTypeTriggerBulkTest.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Bulk Test suite for Data Event Type Trigger methods.

Coverage for classes below (target 85%):
DataEventTypeManager.cls : 75%	
DataEventTypeTriggerHandler.cls : 60%	

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-08-19  Initial development.
1.1  Mark Cane&    2019-08-19  Added bulkTestCase3.
1.12 Mark Cane&    2020-06-24  Added bulkTestCase4.
*/
@isTest(SeeAllData=false)
public with sharing class DataEventTypeTriggerBulkTest {
	/*
    Test cases:
        bulkTestCase1 - ApexTrigger - Update. All Conditions Pass Test.
        bulkTestCase2 - ApexTrigger - Update. All Conditions Pass Test Subset test.
        bulkTestCase3 - ApexTrigger - Update. Async Immediate - Bulk. All Conditions Pass Test.
        bulkTestCase4 - ApexTrigger - Update. Async Immediate - Id Test. All Conditions Pass Test.
	*/
	
    @testSetup static void setup(){}
    
    /* **/
    static testMethod void bulkTestCase1() {
        // Test case 1 : ApexTrigger - Update. Async Immediate. All Conditions Pass Test.
        
        //Account_Update_Async_I_Test_Condition_1=>Site,Equals,Test
        //Account_Update_Async_I_Test_Condition_2=>Description,Does not Equal,Test        
        //Account_Update_Async_I_Test_Condition_3=>BillingCity,IsChanged        

        System.debug(LoggingLevel.ERROR,'FINDME Start>'+Limits.getLimitCpuTime()+' < '+Limits.getCpuTime());

        final Integer TEST_REC_SIZE=100;//callout limit is 100.

        Account a;

        List<Account> accounts = new List<Account>();

        for (Integer i=0; i<TEST_REC_SIZE; i++){
            a = new Account(Name='Unit test'+i);
            a.Site = 'Test';//<---- Condition 1 pass
            a.Description = 'Not test';//<---- Condition 2 pass
            a.BillingCity = 'Edinburgh';  
            a.BillingCountry = 'UK';          
            accounts.add(a);
        }
        insert accounts;

        System.debug(LoggingLevel.ERROR,'FINDME After Account Insert>'+Limits.getLimitCpuTime()+' < '+Limits.getCpuTime());

        Map<Id,Account> idToAccountNew = new Map<Id,Account>([select Id, Site, Description, BillingCity from Account where Id in:accounts]);
        Map<Id,Account> idToAccountOld = new Map<Id,Account>([select Id, Site, Description, BillingCity from Account where Id in:accounts]);


        DataEventTypeTriggerHandler th = new DataEventTypeTriggerHandler('Account');
        th.isExecuting = true;
        th.triggerOp = System.TriggerOperation.AFTER_UPDATE;// System Enum:BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, and AFTER_UNDELETE.
        th.newMap = idToAccountNew;    

        for (Account a2 : idToAccountOld.values()){
            a2.BillingCity='London';
        }

        th.oldMap = idToAccountOld;//<---- Condition 2 pass - BillingCity has changed

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl());

        Test.startTest();
        th.handleTriggerOperationType();
        Test.stopTest();

        System.assert(th.dataEventTypeToRecordIds.containsKey('Account_Update_Async_Immediate_Test'));
        System.assertEquals(TEST_REC_SIZE,th.dataEventTypeToRecordIds.get('Account_Update_Async_Immediate_Test').size());

        System.debug(LoggingLevel.ERROR,'FINDME End>'+Limits.getLimitCpuTime()+' < '+Limits.getCpuTime());
  	}
    /* */     

    /* **/
    static testMethod void bulkTestCase2() {
        // Test case 2 : ApexTrigger - Update. Async Immediate. All Conditions Pass Test Subset test.
        
        //Account_Update_Test_Condition_1=>Site,Equals,Test
        //Account_Update_Test_Condition_2=>Description,Does not Equal,Test        
        //Account_Update_Test_Condition_3=>BillingCity,IsChanged        

        final Integer TEST_REC_SIZE=100;//callout limit is 100.

        Account a;

        List<Account> accounts = new List<Account>();

        for (Integer i=0; i<TEST_REC_SIZE; i++){
            a = new Account(Name='Unit test'+i);
            a.Site = 'Test';//<---- Condition 1 pass
            a.Description = 'Not test';//<---- Condition 2 pass
            a.BillingCity = 'Edinburgh';      
            a.BillingCountry = 'UK';      
            accounts.add(a);
        }
        insert accounts;

        Map<Id,Account> idToAccountNew = new Map<Id,Account>([select Id, Site, Description, BillingCity from Account where Id in:accounts]);
        Map<Id,Account> idToAccountOld = new Map<Id,Account>([select Id, Site, Description, BillingCity from Account where Id in:accounts]);


        DataEventTypeTriggerHandler th = new DataEventTypeTriggerHandler('Account');
        th.isExecuting = true;
        th.triggerOp = System.TriggerOperation.AFTER_UPDATE;// System Enum:BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, and AFTER_UNDELETE.
        th.newMap = idToAccountNew;    

        for (Account a2 : idToAccountOld.values()){
            a2.BillingCity='London';
        }

        idToAccountOld.values()[TEST_REC_SIZE-1].BillingCity = 'Edinburgh';//<-- hasn't changed

        th.oldMap = idToAccountOld;//<---- Condition 2 pass - BillingCity has changed

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl());

        Test.startTest();
        th.handleTriggerOperationType();
        Test.stopTest();

        System.assert(th.dataEventTypeToRecordIds.containsKey('Account_Update_Async_Immediate_Test'));
        System.assertEquals(TEST_REC_SIZE-1,th.dataEventTypeToRecordIds.get('Account_Update_Async_Immediate_Test').size());
        System.assert(!th.dataEventTypeToRecordIds.get('Account_Update_Async_Immediate_Test').containsKey(idToAccountOld.values()[TEST_REC_SIZE-1].Id));
  	}
    /* */

    /* **/
    static testMethod void bulkTestCase3() {
        // Test case 3 : ApexTrigger - Update. Async Immediate - Bulk. All Conditions Pass Test.
        
        //Account_Update_Async_IB_Test_Condition_1=>Site,Equals,AsyncBulkTest

        final Integer TEST_REC_SIZE=100;//Max Records per Bulk Payload = 10, so 10 future calls.

        Account a;

        List<Account> accounts = new List<Account>();

        for (Integer i=0; i<TEST_REC_SIZE; i++){
            a = new Account(Name='Unit test'+i);
            a.Site = 'AsyncBulkTest';//<---- Condition 1 pass
            accounts.add(a);
        }
        insert accounts;

        Map<Id,Account> idToAccountNew = new Map<Id,Account>([select Id, Site, Description, BillingCity from Account where Id in:accounts]);
        Map<Id,Account> idToAccountOld = new Map<Id,Account>([select Id, Site, Description, BillingCity from Account where Id in:accounts]);


        DataEventTypeTriggerHandler th = new DataEventTypeTriggerHandler('Account');
        th.isExecuting = true;
        th.triggerOp = System.TriggerOperation.AFTER_UPDATE;// System Enum:BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, and AFTER_UNDELETE.
        th.newMap = idToAccountNew;    

        for (Account a2 : idToAccountOld.values()){
            a2.Site='Test';
        }

        th.oldMap = idToAccountOld;

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl());

        Test.startTest();
        th.handleTriggerOperationType();
        Test.stopTest();

        System.assert(th.dataEventTypeToRecordIds.containsKey('Account_Update_Async_Immediate_Bulk_Test'));
        System.assertEquals(TEST_REC_SIZE,th.dataEventTypeToRecordIds.get('Account_Update_Async_Immediate_Bulk_Test').size());
  	}
    /* */     
    
    /* **/
    static testMethod void bulkTestCase4() {
        // Test case 4 : ApexTrigger - Update. Async Immediate - Id Test. All Conditions Pass Test.
        
        //Account_Update_Async_Immediate_Id_Test=>Site,Equals,IdTest

        final Integer TEST_REC_SIZE=5;

        Account a;

        List<Account> accounts = new List<Account>();

        for (Integer i=0; i<TEST_REC_SIZE; i++){
            a = new Account(Name='Unit test'+i);
            a.Site = 'NotIdTest';//<---- Condition 1 fail
            accounts.add(a);
        }
        insert accounts;

        Map<Id,Account> idToAccountNew = new Map<Id,Account>([select Id, Site, Description, BillingCity from Account where Id in:accounts]);
        Map<Id,Account> idToAccountOld = new Map<Id,Account>([select Id, Site, Description, BillingCity from Account where Id in:accounts]);


        DataEventTypeTriggerHandler th = new DataEventTypeTriggerHandler('Account');
        th.isExecuting = true;
        th.triggerOp = System.TriggerOperation.AFTER_UPDATE;// System Enum:BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, and AFTER_UNDELETE.
        th.newMap = idToAccountNew;    

        for (Account a2 : idToAccountNew.values()){
            a2.Site='IdTest';//<---- Condition 1 pass
        }

        th.oldMap = idToAccountOld;

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl());

        Test.startTest();
        th.handleTriggerOperationType();
        Test.stopTest();

        System.debug(LoggingLevel.ERROR,'th.dataEventTypeToRecordIds='+th.dataEventTypeToRecordIds);

        System.assert(th.dataEventTypeToRecordIds.containsKey('Account_Update_Async_Immediate_Id_Test'));
        System.assertEquals(TEST_REC_SIZE,th.dataEventTypeToRecordIds.get('Account_Update_Async_Immediate_Id_Test').size());

        for (OutboundCallout__c oc : [select Id, Endpoint__c, RecordId__c from OutboundCallout__c where RecordId__c in:idToAccountNew.keySet()]){
            System.debug(LoggingLevel.ERROR,'oc='+oc);
            System.assert(oc.Endpoint__c.endsWithIgnoreCase(oc.RecordId__c));
        }
  	}
    /* */         

    public class HttpResponseMockImpl implements HttpCalloutMock {

        public HttpResponseMockImpl(){}

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('');
            res.setStatusCode(200);
            return res;
        }
    }
}