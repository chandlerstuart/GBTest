/*
Name:  PlatformLogManagerTest.cls
======================================================
======================================================
Purpose:Test Suite for PlatformLogManager Class and
PlatformLogEvent Trigger
-------
======================================================
======================================================

Coverage Target: 85%
Class                       Coverage
PlatformLogManager          97%
PlatformLogEventTrigger     95%

History
------- 
Ver. Author        Date         Detail
1.0  J Radcliffe   2019-02-12   Initial development
1.1  J Radcliffe   2019-06-13   New Test Method: testLogAPIRequest
1.2  J Radcliffe   2019-07-01   Modified testLogAPIRequest to accept 'type' parameter
1.3  J Radcliffe   2019-10-24   New Test Method: testlogAPICallout
2.0  J Radcliffe   2020-06-02   Changes to support the following: Platform Log Manager now passes method inputs through to SUP (Salesforce Utility Package) methods for logging in packaged Platform Log 
*/


/*
2.0
- Replaced references to ApplicationConstants with references to packaged constanst (i.e. Golfbreaks.PlatformLogManager.*Constant*)
- Redirected method to query packaged Platform Log (from : PlatformLog__c to: Golfbreaks__PlatformLog__c)
- Added Namespace prefix to Platform Log Fields (and modified names to align with packaged fields where appropriate (i.e from : Class__c to: Golfbreaks__ApexClass__c))
*/

@isTest
public class PlatformLogManagerTest {
    
    //Setup Method - Inserts 100 Accounts
    @testSetup static void testSetup(){
        
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        
        //Inserting 100 Accounts
        List<Account> accs = new List<Account>();
        for(Integer i =0;i<100;i++){
            Account a = new Account();
            a.Name = 'Test Account'+i;
            accs.add(a);
        }
        insert accs;
        
    }
    
    //Single Runtime Exception test
    @isTest static void testLogRuntimeException(){

        String className = 'PlatformLogManagerTest';
        String nullExcMethodName = 'nullException';
        String dmlExcMethodName = 'dmlException';
        
        test.startTest();
        //Forcing Null exception
        try{
            String s;
            s.toLowerCase(); 
        }catch(exception e){
            PlatformLogManager.logExceptions(e, className, nullExcMethodName);
        }
        
        //Forcing DML exception
        try{
            Account a = new Account();
            insert a;
        }catch(exception e){
            PlatformLogManager.logExceptions(e, className, dmlExcMethodName);
        }
        
        test.stopTest();
        
        //Confirming a log has been inserted for each exception
        Golfbreaks__PlatformLog__c[] logs = [Select Id, Golfbreaks__ApexClass__c, Golfbreaks__Type__c, Golfbreaks__ApexMethod__c, Golfbreaks__LogDetail__c, Golfbreaks__Message__c, RecordType.DeveloperName From Golfbreaks__PlatformLog__c];
        system.assertEquals(2,logs.size());
        
        //Verifying log details
        for(Golfbreaks__PlatformLog__c log : logs){
            if(log.Golfbreaks__ApexMethod__c == nullExcMethodName){         
                system.assertEquals(className, log.Golfbreaks__ApexClass__c);
                system.assertEquals(true, log.Golfbreaks__Message__c.contains('Attempt to de-reference a null object')); 
                system.assertEquals('System.NullPointerException', log.Golfbreaks__Type__c);
                system.assertEquals(Golfbreaks.PlatformLogManager.PLATFORM_LOG_EXCEPTION_RT, log.RecordType.DeveloperName);
            }else{
                system.assertEquals(className, log.Golfbreaks__ApexClass__c);
                system.assertEquals(dmlExcMethodName, log.Golfbreaks__ApexMethod__c);
                system.assertEquals( true, log.Golfbreaks__Message__c.contains('REQUIRED_FIELD_MISSING'));
                system.assertEquals('System.DmlException', log.Golfbreaks__Type__c);
                system.assertEquals(Golfbreaks.PlatformLogManager.PLATFORM_LOG_EXCEPTION_RT, log.RecordType.DeveloperName);
            }
            
        }
            
               
    }
    
    //Mass Update/Insert exception test
    @isTest static void testLogRuntimeExceptionSaveResult(){
        
        //Confirming no logs exist prior to insert
        system.assertEquals(0, [Select Id From Golfbreaks__PlatformLog__c].size());
        
        //Creating 200 Accounts - 100 with no name (Required field)
        List<Account> accs = new List<Account>();
        for(integer i =0;i<200;i++){
            Account acc = new Account();
            if(i<100){
                acc.Name = 'Test Account '+i;
            }
            accs.add(acc);
        }
        
        test.startTest();
            //Inserting records
            Database.SaveResult[] results = database.insert(accs,false);
            String className = 'PlatformLogManagerTest';
            String methodName = 'testLogRuntimeExceptionSaveResult';
            //Invoking Utility method
            PlatformLogManager.logExceptions(results, className , methodName, accs);
        test.stopTest();
        
        //Confirming a single log has been inserted
        Golfbreaks__PlatformLog__c[] logs = [Select Id, Golfbreaks__ApexClass__c, Golfbreaks__Type__c, Golfbreaks__ApexMethod__c, Golfbreaks__LogDetail__c, Golfbreaks__Message__c, RecordType.DeveloperName From Golfbreaks__PlatformLog__c];
        system.assertEquals(1,logs.size());
               
        //Verifying log details
        system.assertEquals(className, logs[0].Golfbreaks__ApexClass__c);
        system.assertEquals(methodName, logs[0].Golfbreaks__ApexMethod__c);
        system.assertEquals('Required fields are missing: [Name]', logs[0].Golfbreaks__Message__c); 
        system.assertEquals(true, logs[0].Golfbreaks__LogDetail__c.contains('Required fields are missing: [Name]'));
        system.assertEquals(true, logs[0].Golfbreaks__LogDetail__c.contains('Summary: 100 out of 200 failed')); 
        system.assertEquals(Golfbreaks.PlatformLogManager.PLATFORM_LOG_EXCEPTION_RT, logs[0].RecordType.DeveloperName);
        system.assertEquals('System.DmlException', logs[0].Golfbreaks__Type__c);
    }
    
    //Mass Upsert exception test
    @isTest static void testLogRuntimeExceptionUpsertResult(){
        
        //Confirming no logs exist prior to upsert
        system.assertEquals(0, [Select Id From Golfbreaks__PlatformLog__c].size());
        
        List<Account> accsForUpsert = new List<Account>();
        
        //Creating 100 new Accounts - 50 with no name (Required field)
        List<Account> accs = new List<Account>();
        for(integer i =0;i<100;i++){
            Account acc = new Account();
            if(i<50){
                acc.Name = 'New Test Account '+i;
            }
            accsForUpsert.add(acc);
        }
        
        //Retrieving 100 existing Accounts - Assigning null to the names of 50 Account records
        Account[] existingAccs = [Select Id, Name From Account];
        system.assertEquals(100,existingAccs.size());
        for(Integer i=0; i<100; i++){
            if(i<50){
                existingAccs[i].Name = null;
            }
        }
        accsForUpsert.addAll(existingAccs);
        
        system.assertEquals(200,accsForUpsert.size());
        
        test.startTest();
            //Upserting records
            Database.UpsertResult[] results = database.upsert(accsForUpsert,false);
            String className = 'PlatformLogManagerTest';
            String methodName = 'testLogRuntimeExceptionUpsertResult';
            //Invoking Utility method
            PlatformLogManager.logExceptions(results, className , methodName,accsForUpsert);
        test.stopTest();
        
        //Confirming a single log has been inserted
        Golfbreaks__PlatformLog__c[] logs = [Select Id, Golfbreaks__ApexClass__c, Golfbreaks__Type__c, Golfbreaks__ApexMethod__c, Golfbreaks__LogDetail__c, Golfbreaks__Message__c, RecordType.DeveloperName From Golfbreaks__PlatformLog__c];
        system.assertEquals(1,logs.size());
        
        system.debug('logs after upsert: '+logs);
        
        //Verifying log details
        system.assertEquals(className, logs[0].Golfbreaks__ApexClass__c);
        system.assertEquals(methodName, logs[0].Golfbreaks__ApexMethod__c);
        system.assertEquals('Required fields are missing: [Name]', logs[0].Golfbreaks__Message__c); 
        system.assertEquals(true, logs[0].Golfbreaks__LogDetail__c.contains('Required fields are missing: [Name]'));
        system.assertEquals(true, logs[0].Golfbreaks__LogDetail__c.contains('Summary: 100 out of 200 failed')); 
        system.assertEquals(Golfbreaks.PlatformLogManager.PLATFORM_LOG_EXCEPTION_RT, logs[0].RecordType.DeveloperName);
        system.assertEquals('System.DmlException', logs[0].Golfbreaks__Type__c);
    }
        
    @IsTest static void testLogAPIRequest(){

        system.assertEquals(0, [Select Id From Golfbreaks__PlatformLog__c].size());

        List<Case> caseList = new List<Case>();
        for(Integer i=0;i<10;i++){
            Case c = new Case();
            c.Subject = 'Test Case '+i;
            c.Status = 'New';
        }
        
        String requestBody = JSON.serialize(caseList);
        String responseBody = '{"Success":"true"}';
        Integer speed = 10;
        Integer successes = 7;
        Integer failures = 3;
        List<String> errors = new List<String>{'Error 1','Error 2','Error 3'};
        String type = 'Flow';//1.2+

        test.startTest();
            PlatformLogManager.logAPIRequest(requestBody, responseBody, speed, successes, failures, errors, type );//1.2+
        test.stopTest();

        Golfbreaks__PlatformLog__c[] logs = [Select Id, Golfbreaks__APIRequestBody__c, Golfbreaks__APIResponseBody__c, Golfbreaks__FailCount__c, Golfbreaks__SuccessCount__c, Golfbreaks__Speed__c, Golfbreaks__LogDetail__c, RecordType.DeveloperName, Golfbreaks__Type__c From Golfbreaks__PlatformLog__c];
        system.assertEquals(1, logs.size());
        system.assertEquals(requestBody, logs[0].Golfbreaks__APIRequestBody__c);        
        system.assertEquals(responseBody, logs[0].Golfbreaks__APIResponseBody__c);
        system.assertEquals(speed, logs[0].Golfbreaks__Speed__c);
        system.assertEquals(successes, logs[0].Golfbreaks__SuccessCount__c);
        system.assertEquals(failures, logs[0].Golfbreaks__FailCount__c);
        for(String error : errors){
            system.assertEquals(true, logs[0].Golfbreaks__LogDetail__c.contains(error));
        }
        system.assertEquals(Golfbreaks.PlatformLogManager.PLATFORM_LOG_API_INBOUND_RT, logs[0].RecordType.DeveloperName);
        system.assertEquals(type,logs[0].Golfbreaks__Type__c);//1.2+
    }

    //1.3
    @IsTest static void testlogAPICallout(){

        system.assertEquals(0, [Select Id From Golfbreaks__PlatformLog__c].size());

        List<Case> caseList = new List<Case>();
        for(Integer i=0;i<10;i++){
            Case c = new Case();
            c.Subject = 'Test Case '+i;
            c.Status = 'New';
        }
        
        String requestBody = JSON.serialize(caseList);
        String responseBody = '{"Success":"false"}';
        Integer retryCount = 10;
        Integer failures = 3;
        List<String> errors = new List<String>{'Error 1','Error 2','Error 3'};
        String dataEventType = 'TestDataEvent';
        String recordId = '012345678910111213';//18 characters
        String endpoint = '/TestAPI/TestEndpoint';


        test.startTest();
            PlatformLogManager.logAPICallout(requestBody, responseBody, dataEventType, recordId, endpoint, retryCount, failures, errors);
        test.stopTest();

        Golfbreaks__PlatformLog__c[] logs = [Select Id, Golfbreaks__APIRequestBody__c, Golfbreaks__APIResponseBody__c, Golfbreaks__FailCount__c, Golfbreaks__LogDetail__c, Golfbreaks__RecordId__c, Golfbreaks__RetryCount__c, Golfbreaks__Endpoint__c , Golfbreaks__APIDataEventType__c, RecordType.DeveloperName, Golfbreaks__Type__c From Golfbreaks__PlatformLog__c];
        system.assertEquals(1, logs.size());
        system.assertEquals(requestBody, logs[0].Golfbreaks__APIRequestBody__c);        
        system.assertEquals(responseBody, logs[0].Golfbreaks__APIResponseBody__c);
        system.assertEquals(retryCount, logs[0].Golfbreaks__RetryCount__c);
        system.assertEquals(endpoint, logs[0].Golfbreaks__Endpoint__c);
        system.assertEquals(failures, logs[0].Golfbreaks__FailCount__c);
        system.assertEquals(recordId, logs[0].Golfbreaks__RecordId__c);
        system.assertEquals(dataEventType, logs[0].Golfbreaks__APIDataEventType__c);
        for(String error : errors){
            system.assertEquals(true, logs[0].Golfbreaks__LogDetail__c.contains(error));
        }
        system.assertEquals(Golfbreaks.PlatformLogManager.PLATFORM_LOG_API_OUTBOUND_RT, logs[0].RecordType.DeveloperName);
        system.assertEquals('Payload',logs[0].Golfbreaks__Type__c);
    }

}