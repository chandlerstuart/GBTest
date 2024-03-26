/*
Name: ActionTypeRequestTestSuite.cls
Copyright © 2023  Audit9
======================================================
======================================================
Purpose:
-------

General Test suite for Action Types logic:

Coverage for classes below (target 85%):
ActionTypeRequestTriggerHandler.cls : 77%
ActionTypeRequestProcessor.cls : 68%
ActionTypeRequestIProcessor.cls : 71%
ActionTypeRequestSchedulable.cls : 81%

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2023-11-22  Initial development.
*/ 
@isTest(SeeAllData=false)
public with sharing class ActionTypeRequestTestSuite {
    private static List<Account> accounts;
    /*
    Test cases:            
        singleTestCase1 - ApexTrigger. ActionTypeRequest__c insert - Transactional Action Type so Queueable invoked.
        singleTestCase2a - ApexTrigger. ActionTypeRequest__c insert - Non-transactional Action Type. Invoke Schedulable.
        singleTestCase2b - ApexTrigger. ActionTypeRequest__c insert - Non-transactional Action Type. Invoke Schedulable for actionType.
        singleTestCase3a - ApexTrigger. ActionTypeRequest__c insert - Non-transactional Action Type. Invoke Batchable.
        singleTestCase3b - ApexTrigger. ActionTypeRequest__c insert - Non-transactional Action Type. Invoke Batchable for actionType.
    */
    
    @testSetup static void setup(){ }   
    
    /* **/
    static testMethod void singleTestCase1(){ 
        // Test case 1 : ApexTrigger. ActionTypeRequest__c insert - Transactional Action Type so Queueable invoked.                        
 
        ActionTypeRequest__c atr = new ActionTypeRequest__c(ActionType__c='TestCaseAction',FirstName__c='John',LastName__c='Smith',Email__c='john.smith@outlook.com',Status__c='New',AdditionalInformation__c='Case Subject 1',CountriesInterested__c='Spain;Morrocco');        

        Assert.areEqual(0, [select count()
                                from AsyncApexJob 
                                where (JobType='Queueable')                                      
                                    and ApexClass.Name='ActionTypeRequestIProcessor'
                                    limit 1]);
                
        Test.startTest();
        insert atr;
        Test.stopTest();

        Assert.areEqual(1, [select count()
                                from AsyncApexJob 
                                where (JobType='Queueable')                                      
                                    and ApexClass.Name='ActionTypeRequestIProcessor'
                                    limit 1]);

        //[REQUIRED FOR BUILD] 
        /*
        Assert.areEqual(1, [select count() from ActionTypeRequest__c where Status__c='Complete']);
        Assert.areEqual(1, [select count() from Account where PersonEmail=:atr.Email__c and FirstName=:atr.FirstName__c and LastName=:atr.LastName__c]);
        Assert.areEqual(1, [select count() from Individual where FirstName=:atr.FirstName__c and LastName=:atr.LastName__c]);
        Assert.areEqual(1, [select count() from Case]);
        Assert.areEqual(1, [select count() from Case where Subject=:atr.AdditionalInformation__c]);
        Assert.areEqual(1, [select count() from Case where Subject=:atr.AdditionalInformation__c and SuppliedCompany=:atr.CountriesInterested__c]);
        */
    }/* */
    
    /* **/
    static testMethod void singleTestCase2a() {
        // Test case 2a : ApexTrigger. ActionTypeRequest__c insert - Non-transactional Action Type. Invoke Schedulable.

        ActionTypeRequest__c atr = new ActionTypeRequest__c(ActionType__c='TestCaseAction',FirstName__c='John',LastName__c='Smith',Email__c='john.smith@outlook.com',Status__c='New',IsBatch__c=true,AdditionalInformation__c='Case Subject 1',CountriesInterested__c='Spain;Morrocco');

        Assert.areEqual(0, [select count()
                                from AsyncApexJob 
                                where (JobType='Queueable')                                      
                                    and ApexClass.Name='ActionTypeRequestIProcessor'
                                    limit 1]);                
        
        insert atr;        

        Assert.areEqual(0, [select count()
                                from AsyncApexJob 
                                where (JobType='Queueable')                                      
                                    and ApexClass.Name='ActionTypeRequestIProcessor'
                                    limit 1]);

        String cronExp = '0 0 0 15 3 ? 2035';//increased from 2025.

        Test.startTest();
        System.schedule('Unit test', cronExp, new ActionTypeRequestSchedulable());
        Test.stopTest();

        Assert.areEqual(1, [select count()
                                from AsyncApexJob 
                                where (JobType='ScheduledApex')                                      
                                    and ApexClass.Name='ActionTypeRequestSchedulable'
                                    limit 1]);                
    }/* */
    
    /* **/
    static testMethod void singleTestCase2b() {
        // Test case 2b : ApexTrigger. ActionTypeRequest__c insert - Non-transactional Action Type. Invoke Schedulable for actionType.

        ActionTypeRequest__c atr = new ActionTypeRequest__c(ActionType__c='TestCaseAction',FirstName__c='John',LastName__c='Smith',Email__c='john.smith@outlook.com',Status__c='New',IsBatch__c=true,AdditionalInformation__c='Case Subject 1',CountriesInterested__c='Spain;Morrocco');

        Assert.areEqual(0, [select count()
                                from AsyncApexJob 
                                where (JobType='Queueable')                                      
                                    and ApexClass.Name='ActionTypeRequestIProcessor'
                                    limit 1]);                
        
        insert atr;        

        Assert.areEqual(0, [select count()
                                from AsyncApexJob 
                                where (JobType='Queueable')                                      
                                    and ApexClass.Name='ActionTypeRequestIProcessor'
                                    limit 1]);

        String cronExp = '0 0 0 15 3 ? 2035';//increased from 2025.

        Test.startTest();
        System.schedule('Unit test', cronExp, new ActionTypeRequestSchedulable(new Set<String>{'TestCaseAction' }));
        Test.stopTest();

        Assert.areEqual(1, [select count()
                                from AsyncApexJob 
                                where (JobType='ScheduledApex')                                      
                                    and ApexClass.Name='ActionTypeRequestSchedulable'
                                    limit 1]);                
    }/* */    

    /* **/ 
    static testMethod void singleTestCase3a() {
        // Test case 3a : ApexTrigger. ActionTypeRequest__c insert - Non-transactional Action Type. Invoke Batchable.

        ActionTypeRequest__c atr = new ActionTypeRequest__c(ActionType__c='TestCaseAction',FirstName__c='John',LastName__c='Smith',Email__c='john.smith@outlook.com',Status__c='New',IsBatch__c=true,AdditionalInformation__c='Case Subject 1',CountriesInterested__c='Spain;Morrocco');

        Assert.areEqual(0, [select count()
                                from AsyncApexJob 
                                where (JobType='Queueable')                                      
                                    and ApexClass.Name='ActionTypeRequestIProcessor'
                                    limit 1]);                
        
        insert atr;        

        Assert.areEqual(0, [select count()
                                from AsyncApexJob 
                                where (JobType='Queueable')                                      
                                    and ApexClass.Name='ActionTypeRequestIProcessor'
                                    limit 1]);

        Test.startTest();
        Database.executeBatch(new ActionTypeRequestProcessor());
        Test.stopTest();

        Assert.areEqual(1, [select count()
                                from AsyncApexJob 
                                where (JobType='BatchApex')                                      
                                    and ApexClass.Name='ActionTypeRequestProcessor'
                                    limit 1]);

        //[REQUIRED FOR BUILD] Assert.areEqual(1, [select count() from ActionTypeRequest__c where Status__c='Complete']);
    }/* */ 

    /* **/ 
    static testMethod void singleTestCase3b() {
        // Test case 3b : ApexTrigger. ActionTypeRequest__c insert - Non-transactional Action Type. Invoke Batchable for actionType.

        ActionTypeRequest__c atr = new ActionTypeRequest__c(ActionType__c='TestCaseAction',FirstName__c='John',LastName__c='Smith',Email__c='john.smith@outlook.com',Status__c='New',IsBatch__c=true,AdditionalInformation__c='Case Subject 1',CountriesInterested__c='Spain;Morrocco');

        Assert.areEqual(0, [select count()
                                from AsyncApexJob 
                                where (JobType='Queueable')                                      
                                    and ApexClass.Name='ActionTypeRequestIProcessor'
                                    limit 1]);                
        
        insert atr;        

        Assert.areEqual(0, [select count()
                                from AsyncApexJob 
                                where (JobType='Queueable')                                      
                                    and ApexClass.Name='ActionTypeRequestIProcessor'
                                    limit 1]);

        Test.startTest();
        Database.executeBatch(new ActionTypeRequestProcessor('TestCaseAction'));
        Test.stopTest();

        Assert.areEqual(1, [select count()
                                from AsyncApexJob 
                                where (JobType='BatchApex')                                      
                                    and ApexClass.Name='ActionTypeRequestProcessor'
                                    limit 1]);

        //[REQUIRED FOR BUILD] Assert.areEqual(1, [select count() from ActionTypeRequest__c where Status__c='Complete']);
    }/* */ 
}