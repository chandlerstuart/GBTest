/*
-------
Name:
GenerateGuidActionTest.cls
========================================================
========================================================
Purpose:
-------
Test suite built to provide sufficent testing & handling of the GenerateGuidAction in a bulkable format
=========================================================
=========================================================
Verison     Author         Date           Detail
v1.0        C Stuart       26/04/2023     Inital Development -  Created Test method for generateGuidAction
*/

@isTest
public with sharing class GenerateGuidActionTest {
    
    public class CustomException extends Exception{}

    @isTest 
    static void generateGuidActionTest() {

        // New Request object 
        List<GenerateGuidAction.Request> requests = new List<GenerateGuidAction.Request>();
        
        // Create 5 new Request
        for(Integer i=0; i<5; i++){
            requests.add(new GenerateGuidAction.Request());
        }

        // Confirm the Request size  
        system.assertEquals(5,requests.size());

        // 
        List<GenerateGuidAction.Result> results;
        Test.startTest();
            results = GenerateGuidAction.generateGuid(requests);
        Test.stopTest();

        // Confirm the Results size 
        System.assertEquals(5,results.size());

        // Iterate through Results to check length & unique value's
        List<String> generatedGuids = new List<String>();
        for(GenerateGuidAction.Result r : results){
            System.assertEquals(36, r.guid.length(), 'GUID Length should be 36');
            if(!generatedGuids.contains(r.guid)){
                generatedGuids.add(r.guid);
            } else {
                throw new CustomException('Duplicate GUID Detected');
            }
        }
    }

    @isTest
    static void generateGuidTestExceptionHandling(){

        // check no Platform log's have been created prior to the Assertion
        System.assertEquals(0,[SELECT Count() From Golfbreaks__PlatformLog__c Where Golfbreaks__Message__c =: GenerateGuidAction.errorMessage]);
        
        // New Request object 
        List<GenerateGuidAction.Request> requests = new List<GenerateGuidAction.Request>();
        
        // Create 5 new Request
        for(Integer i=0; i<5; i++){
            requests.add(new GenerateGuidAction.Request());
        }

        // Confirm the Request size  
        system.assertEquals(5,requests.size());

        List<GenerateGuidAction.Result> results;
        Test.startTest();
            GenerateGuidAction.throwException = true;
            results = GenerateGuidAction.generateGuid(requests);
        Test.stopTest();

        // check if an Error has been logged in the platform Log
        System.assertEquals(1,[SELECT Count() From Golfbreaks__PlatformLog__c Where Golfbreaks__Message__c =: GenerateGuidAction.errorMessage]);
    }
}