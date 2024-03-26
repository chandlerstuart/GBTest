/*
Name: Flow_DynamicSearchController_Test.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Test suite for Flow_DynamicSearchController.cls
======================================================
======================================================

History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-06-19  Initial development.
*/
@isTest
public with sharing class Flow_DynamicSearchController_Test {
    
    @testSetup static void createTestData(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
                
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings; 
        
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;

        //Query Account Record Types
        RecordType[] rts = [Select Id From RecordType Where DeveloperName = 'Client' OR DeveloperName = 'PGA_Pro'];
        system.assertEquals(2, rts.size());

        //Create 100 Accounts
        List<Account> newAccs = AP23_TestDataFactory.createPersonAccount(100,true);
        //Divide into PGA & Client Accounts (50/50)
        for(integer i =0; i<100;i++){
            if(i<50){
                newAccs[i].RecordTypeId = rts[0].Id;
            }else{
                newAccs[i].RecordTypeId = rts[1].Id;
            }
        }
        //Insert Accounts
        insert newAccs;
    }

    @isTest static void testGetAllAccounts(){

        //setFixedSearchResults for All Accounts
        List<Id> fixedSearchResults = new List<Id>();
        for(Account acc : [Select Id, Name, Industry, NumberOfEmployees From Account]){
            fixedSearchResults.add(acc.Id);
        } 
        system.assertEquals(100, fixedSearchResults.size());   
        test.setFixedSearchResults(fixedSearchResults);

        String sObjectType = 'Account';
        Integer limitCount = 500;
        String searchString = 'test';
        String soqlString = 'Select Id, Name, Industry, NumberOfEmployees From Account';
        Boolean getFieldNames = true;

        test.startTest();
            Flow_DynamicSearchController.SearchResults results = Flow_DynamicSearchController.startSearch(sObjectType, limitCount, searchString, soqlString, getFieldNames);
        test.stopTest();

        //Confirm results are returned
        system.assertNotEquals(null, results);
        system.assertNotEquals(null, results.data);
        system.assertNotEquals(null, results.columns);

        system.debug('results.data: '+results.data);

        //Confirm the expected number of results are returned
        system.assertEquals(100, results.data.size());
        system.assertEquals(4, results.columns.size());
        //Confirm the SOQL contains the select fields
        for(Flow_DynamicSearchController.Column c : results.columns){
            system.assertEquals(true, soqlString.contains(c.fieldName));
        }

    }
    
    @isTest static void testGetAllAccountsWithFilter(){

        //setFixedSearchResults for All Accounts
        List<Id> fixedSearchResults = new List<Id>();
        for(Account acc : [Select Id, Name, Industry, NumberOfEmployees, CreatedById From Account]){
            fixedSearchResults.add(acc.Id);
        }    
        system.assertEquals(100, fixedSearchResults.size());
        test.setFixedSearchResults(fixedSearchResults);

        String sObjectType = 'Account';
        Integer limitCount = 500;
        String searchString = 'test';
        Id runningUserId = UserInfo.getUserId();
        String soqlString = 'Select Id, Name, Industry, NumberOfEmployees From Account Where RecordType.DeveloperName = \'Client\'';//Where clause added
        system.debug('soqlString:'+soqlString);
        Boolean getFieldNames = true;

        test.startTest();
            Flow_DynamicSearchController.SearchResults results = Flow_DynamicSearchController.startSearch(sObjectType, limitCount, searchString, soqlString, getFieldNames);
        test.stopTest();

        //Confirm results are returned
        system.assertNotEquals(null, results);
        system.assertNotEquals(null, results.data);
        system.assertNotEquals(null, results.columns);

        system.debug('results.data: '+results.data);

        //Confirm the expected number of results are returned
        system.assertEquals(50, results.data.size());//<--Only 50 Client Types
        system.assertEquals(4, results.columns.size());
        //Confirm the SOQL contains the select fields
        for(Flow_DynamicSearchController.Column c : results.columns){
            system.assertEquals(true, soqlString.contains(c.fieldName));
        }
    }

    @isTest static void testGetAllAccountsWithLimit(){

        //setFixedSearchResults for All Accounts
        List<Id> fixedSearchResults = new List<Id>();
        for(Account acc : [Select Id, Name, Industry, NumberOfEmployees, CreatedById From Account]){
            fixedSearchResults.add(acc.Id);
        }    
        system.assertEquals(100, fixedSearchResults.size());
        test.setFixedSearchResults(fixedSearchResults);

        String sObjectType = 'Account';
        Integer limitCount = 15;// Limit Reduced
        String searchString = 'test';
        Id runningUserId = UserInfo.getUserId();
        String soqlString = 'Select Id, Name, Industry, NumberOfEmployees From Account';
        system.debug('soqlString:'+soqlString);
        Boolean getFieldNames = true;

        test.startTest();
            Flow_DynamicSearchController.SearchResults results = Flow_DynamicSearchController.startSearch(sObjectType, limitCount, searchString, soqlString, getFieldNames);
        test.stopTest();

        //Confirm results are returned
        system.assertNotEquals(null, results);
        system.assertNotEquals(null, results.data);
        system.assertNotEquals(null, results.columns);

        system.debug('results.data: '+results.data);

        //Confirm the expected number of results are returned
        system.assertEquals(15, results.data.size());//<--Only 15 Accounts should be returned (based on Limit)
        system.assertEquals(4, results.columns.size());
        //Confirm the SOQL contains the select fields
        for(Flow_DynamicSearchController.Column c : results.columns){
            system.assertEquals(true, soqlString.contains(c.fieldName));
        }
    }

    @isTest static void testGetAllAccountsWithoutColumns(){

        //setFixedSearchResults for All Accounts
        List<Id> fixedSearchResults = new List<Id>();
        for(Account acc : [Select Id, Name, Industry, NumberOfEmployees, CreatedById From Account]){
            fixedSearchResults.add(acc.Id);
        }    
        system.assertEquals(100, fixedSearchResults.size());
        test.setFixedSearchResults(fixedSearchResults);

        String sObjectType = 'Account';
        Integer limitCount = 500;
        String searchString = 'test';
        Id runningUserId = UserInfo.getUserId();
        String soqlString = 'Select Id, Name, Industry, NumberOfEmployees From Account';
        system.debug('soqlString:'+soqlString);
        Boolean getFieldNames = false;//Block the column generation. Building the columns is expensive and should only be performed on the first search

        test.startTest();
            Flow_DynamicSearchController.SearchResults results = Flow_DynamicSearchController.startSearch(sObjectType, limitCount, searchString, soqlString, getFieldNames);
        test.stopTest();

        //Confirm results are returned
        system.assertNotEquals(null, results);
        system.assertNotEquals(null, results.data);
        system.assertNotEquals(null, results.columns);

        system.debug('results.data: '+results.data);

        //Confirm the expected number of results are returned
        system.assertEquals(100, results.data.size());
        system.assertEquals(0, results.columns.size());//No columns should be returned
    }
}