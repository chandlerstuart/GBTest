/*
Name:  MarketingCloudClientSyncBatchTest.cls
======================================================
======================================================
Purpose:

Test Suite for MarketingCloudClientSyncBatch Class.
-------
======================================================
======================================================

Coverage Target: 85%
Class                                   Coverage
MarketingCloudClientSyncBatch           92%
MarketingCloudClientSyncBatchSchedule   100%

History
------- 
Ver. Author        Date         Detail
1.0  Mark Cane&    2023-07-13   Initial development
*/
@isTest
public with sharing class MarketingCloudClientSyncBatchTest {

    @testSetup static void testSetup(){
        insert AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert new OrgSettings__c(TriggersActive__c=false);
        insert new Golfbreaks_Business_Unit__c(IsDefault__c=true, DeveloperName__c='UK', Name='UK');
    }
    
    @isTest static void singleTestCase1(){// all records

        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        acc.Is_Operational__c = true;
        acc.IsTest__c = false;
        acc.GolfbreaksBusinessUnit__c = [select Id from Golfbreaks_Business_Unit__c where DeveloperName__c='UK'].Id;
        insert acc;

        Assert.areEqual(1, [select count() from Account where IsMarketingCloudClientSync__c=true]);//<-- default is true.
        Assert.areEqual(1, [select count() from Account where IsMarketingCloudContactSync__pc=true]);//<-- default is true.

        acc.IsMarketingCloudClientSync__c = false;//<-- reset explicitly to false.
        acc.IsMarketingCloudContactSync__pc = false;//<-- reset explicitly to false.
        update acc;

        Assert.areEqual(0, [select count() from Account where IsMarketingCloudClientSync__c=true]);
        Assert.areEqual(0, [select count() from Account where IsMarketingCloudContactSync__pc=true]);            

        Test.startTest();
        Database.executeBatch(new MarketingCloudClientSyncBatch());
        Test.stopTest();

        Assert.areEqual(1, [select count() from Account where IsMarketingCloudClientSync__c=true]);
        Assert.areEqual(1, [select count() from Account where IsMarketingCloudContactSync__pc=true]);
    }

    @isTest static void singleTestCase2(){// fromHours

        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        acc.Is_Operational__c = true;
        acc.IsTest__c = false;
        acc.GolfbreaksBusinessUnit__c = [select Id from Golfbreaks_Business_Unit__c where DeveloperName__c='UK'].Id;
        insert acc;

        Assert.areEqual(1, [select count() from Account where IsMarketingCloudClientSync__c=true]);//<-- default is true.
        Assert.areEqual(1, [select count() from Account where IsMarketingCloudContactSync__pc=true]);//<-- default is true.

        acc.IsMarketingCloudClientSync__c = false;//<-- reset explicitly to false.
        acc.IsMarketingCloudContactSync__pc = false;//<-- reset explicitly to false.
        update acc;

        Assert.areEqual(0, [select count() from Account where IsMarketingCloudClientSync__c=true]);
        Assert.areEqual(0, [select count() from Account where IsMarketingCloudContactSync__pc=true]);            

        Test.startTest();
        Database.executeBatch(new MarketingCloudClientSyncBatch(-10));
        Test.stopTest();

        Assert.areEqual(1, [select count() from Account where IsMarketingCloudClientSync__c=true]);
        Assert.areEqual(1, [select count() from Account where IsMarketingCloudContactSync__pc=true]);
    }  
    
    @isTest static void singleTestCase3(){// fromDate

        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        acc.Is_Operational__c = true;
        acc.IsTest__c = false;
        acc.GolfbreaksBusinessUnit__c = [select Id from Golfbreaks_Business_Unit__c where DeveloperName__c='UK'].Id;
        insert acc;

        Assert.areEqual(1, [select count() from Account where IsMarketingCloudClientSync__c=true]);//<-- default is true.
        Assert.areEqual(1, [select count() from Account where IsMarketingCloudContactSync__pc=true]);//<-- default is true.

        acc.IsMarketingCloudClientSync__c = false;//<-- reset explicitly to false.
        acc.IsMarketingCloudContactSync__pc = false;//<-- reset explicitly to false.
        update acc;

        Assert.areEqual(0, [select count() from Account where IsMarketingCloudClientSync__c=true]);
        Assert.areEqual(0, [select count() from Account where IsMarketingCloudContactSync__pc=true]);            

        Test.startTest();
        Database.executeBatch(new MarketingCloudClientSyncBatch(Date.today()));
        Test.stopTest();

        Assert.areEqual(1, [select count() from Account where IsMarketingCloudClientSync__c=true]);
        Assert.areEqual(1, [select count() from Account where IsMarketingCloudContactSync__pc=true]);
    }

    @isTest static void singleTestCase4(){// schedulable - all records.

        String CRON_EXP = '0 0 0 15 3 ? 2035';//increased from 2025.        

        Test.startTest();
        System.schedule('MarketingCloudClientSyncBatchScheduleTest', CRON_EXP, new MarketingCloudClientSyncBatchSchedule());
        Test.stopTest();

        Assert.areEqual(1,[select count() from CronTrigger where State not in ('COMPLETE','ERROR','DELETED') and CronJobDetail.Name='MarketingCloudClientSyncBatchScheduleTest']);    
    }

    @isTest static void singleTestCase5(){// schedulable - fromHours

        String CRON_EXP = '0 0 0 15 3 ? 2035';//increased from 2025.        

        Test.startTest();
        System.schedule('MarketingCloudClientSyncBatchScheduleTest', CRON_EXP, new MarketingCloudClientSyncBatchSchedule(-10));
        Test.stopTest();

        Assert.areEqual(1,[select count() from CronTrigger where State not in ('COMPLETE','ERROR','DELETED') and CronJobDetail.Name='MarketingCloudClientSyncBatchScheduleTest']);    
    }    
}