/*
-------
Name:
GlobalUtilityTest.cls
========================================================
========================================================
Purpose:
-------
Test suite built to sufficiently test the Global Utitlty Class methods
=========================================================
=========================================================
Verison     Author         Date           Detail
v1.0        C Stuart       26/04/2023     Inital Development - GenerateGuidActionTest method 
*/


@isTest
public with sharing class GlobalUtilityTest {
    
    public class CustomException extends Exception{}

    @isTest
    // generateGuidTest - succesfully generate's GUID's in a BULK format
    static void generateGuidTest(){
    
        Test.startTest();
            List<String> guidList = AP23_TestDataFactory.generateGuid(100);
        Test.stopTest();

        System.assertEquals(100, guidList.size(), 'List should be 100');

        List<String> processedGuids = new List<String>();
        for(String g : guidList){
            System.assertEquals(35, g.length(), 'Guid Should be 35 digit\'s long');    
            if(!processedGuids.contains(g)){
                processedGuids.add(g);
            } else {
                throw new CustomException('Duplicate detected');
            }
        }
    }
}