/*
Name:  ScheduledEventTypeProcessorActionTest.cls
======================================================
======================================================
Purpose: Test Suite for ScheduledEventTypeProcessorAction.cls

-------

Coverage: ScheduledEventTypeProcessorAction - 92%

======================================================
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2021-09-17  Initial development.
*/
@isTest
public with sharing class ScheduledEventTypeProcessorActionTest {

    public static final String testDETName = 'Test_Content_Stack_Caching_DET';

    //Scenario 1 - Test with Id String Input - Success
    //Scenario 2 - Test with Id List Input - Success
    //Scenario 3 - Test with invalid Id String Input - Failure
    //Scenario 4 - Test with multiple requests - Failure
    
    @isTest static void testScenario1(){

        DataEventType__mdt testDET = [Select Id, IsTest__c, IsActive__c From DataEventType__mdt Where DeveloperName = :testDETName];
        system.assertEquals(true, testDET.IsActive__c);
        system.assertEquals(true, testDET.IsTest__c);

        ScheduledEventTypeProcessorAction.Request request = new ScheduledEventTypeProcessorAction.Request();
        request.dataEventTypeIdString = testDET.Id+';'+UserInfo.getUserId();//Add a valid and invalid DET Id
        
        test.startTest();
            List<ScheduledEventTypeProcessorAction.Result> results = ScheduledEventTypeProcessorAction.execute(new List<ScheduledEventTypeProcessorAction.Request>{request});
        test.stopTest();

        system.assertEquals(1, results.size());
        system.assertEquals(true, results[0].isSuccess);
        system.assertEquals(ScheduledEventTypeProcessorAction.successMessage+'["'+testDET.Id+'"]', results[0].message);//Confirm the valid DET was processed correctly.
    }   

    @isTest static void testScenario2(){

        DataEventType__mdt testDET = [Select Id, IsTest__c, IsActive__c From DataEventType__mdt Where DeveloperName = :testDETName];
        system.assertEquals(true, testDET.IsActive__c);
        system.assertEquals(true, testDET.IsTest__c);

        ScheduledEventTypeProcessorAction.Request request = new ScheduledEventTypeProcessorAction.Request();
        request.dataEventTypeIds = new List<Id>{testDET.Id,UserInfo.getUserId()};//Add a valid and invalid DET Id
        
        test.startTest();
            List<ScheduledEventTypeProcessorAction.Result> results = ScheduledEventTypeProcessorAction.execute(new List<ScheduledEventTypeProcessorAction.Request>{request});
        test.stopTest();

        system.assertEquals(1, results.size());
        system.assertEquals(true, results[0].isSuccess);
        system.assertEquals(ScheduledEventTypeProcessorAction.successMessage+'["'+testDET.Id+'"]', results[0].message);//Confirm the valid DET was processed correctly.
    }

    @isTest static void testScenario3(){

        DataEventType__mdt testDET = [Select Id, IsTest__c, IsActive__c From DataEventType__mdt Where DeveloperName = :testDETName];
        system.assertEquals(true, testDET.IsActive__c);
        system.assertEquals(true, testDET.IsTest__c);

        ScheduledEventTypeProcessorAction.Request request = new ScheduledEventTypeProcessorAction.Request();
        request.dataEventTypeIdString = UserInfo.getUserId();//Add an invalid DET Id (only)
        
        test.startTest();
            List<ScheduledEventTypeProcessorAction.Result> results = ScheduledEventTypeProcessorAction.execute(new List<ScheduledEventTypeProcessorAction.Request>{request});
        test.stopTest();

        system.assertEquals(1, results.size());
        system.assertEquals(false, results[0].isSuccess);
        system.assertEquals(ScheduledEventTypeProcessorAction.failMessageNoDETs, results[0].message);//Confirm the correct error was returned.
    }

    @isTest static void testScenario4(){
        DataEventType__mdt testDET = [Select Id, IsTest__c, IsActive__c From DataEventType__mdt Where DeveloperName = :testDETName];
        system.assertEquals(true, testDET.IsActive__c);
        system.assertEquals(true, testDET.IsTest__c);

        ScheduledEventTypeProcessorAction.Request request = new ScheduledEventTypeProcessorAction.Request();
        request.dataEventTypeIdString = testDET.Id+';'+UserInfo.getUserId();//Add a valid and invalid DET Id
        
        test.startTest();
            List<ScheduledEventTypeProcessorAction.Result> results = ScheduledEventTypeProcessorAction.execute(new List<ScheduledEventTypeProcessorAction.Request>{request,request});//Add two requests!
        test.stopTest();

        system.assertEquals(2, results.size());
        system.assertEquals(false, results[0].isSuccess);
        system.assertEquals(ScheduledEventTypeProcessorAction.failMessageMultipleRequests, results[0].message);//Confirm the correct error was returned.
    }


}