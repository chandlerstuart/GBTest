/*
Name:  ConversationQuickTextUtilControllerTest.cls
Copyright © 2022  Golfbreaks
======================================================
======================================================
Purpose: Test suite for ConversationQuickTextUtilController.cls
-------

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-11-30  Initial development.
*/
@isTest
public with sharing class ConversationQuickTextUtilControllerTest {
    
    @isTest static void getQuickTextOptionsTestSuccess(){

        ConversationQuickTextUtilityController.PageData data;
        test.startTest();
            data = ConversationQuickTextUtilityController.getQuickTextOptions();
        test.stopTest();

        system.assertEquals(6, data.categoryOptions.size());
        system.assertEquals(3, data.quickTextOptions.size());

    }

    @isTest static void getQuickTextOptionsTestFailure(){

        system.assertEquals(0, [Select Count() From Golfbreaks__PlatformLog__c]);//No errors before

        ConversationQuickTextUtilityController.PageData data;
        test.startTest();
            ConversationQuickTextUtilityController.throwException = true;
            try{
            data = ConversationQuickTextUtilityController.getQuickTextOptions();
            }catch(Exception e){}
        test.stopTest();

        system.assertEquals(null, data);//No data is returned
        system.assertEquals(1, [Select Count() From Golfbreaks__PlatformLog__c]);//Error is logged successfully
    }

}