/*
Name:  RecordDeleteBatchClass_Test.cls
======================================================
======================================================
Purpose:
-------
Test Class for RecordDeleteBatchClass
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.0  Simon Molloy  2017-10-18   Initial development
*/
@isTest
private class RecordDeleteBatchClass_Test {

    /*@isTest(SeeAllData=TRUE)
    static void testDeleteUSP(){
        //Set up the Custom Setting RecordDeleteSetting__c as we cannot use 'testSetup'
        Map<String, RecordDeleteSetting__c> currentRDS = RecordDeleteSetting__c.getAll();
        RecordDeleteSetting__c rds;
        if (!currentRDS.containsKey('UserServicePresence')){
            rds = new RecordDeleteSetting__c(Name = 'UserServicePresence', Days__c = 7, API_Name__c = 'UserServicePresence');
            insert rds;
        }else {
            rds = currentRDS.get('UserServicePresence');
        }

        RecordDeleteBatchClass rdbc = new RecordDeleteBatchClass();
        rdbc.objectName = rds.Name;
        rdbc.numberOfDays = integer.valueOf(rds.Days__c);
        rdbc.query = 'Select Id from ' + rdbc.objectName + ' where CreatedDate != LAST_N_DAYS:' + rdbc.numberOfDays + ' LIMIT 2000';

        test.startTest();
            Database.executeBatch(rdbc, 2000);
        test.stopTest();

        List<UserServicePresence> uspList = [select Id from UserServicePresence where CreatedDate != LAST_N_DAYS:7 LIMIT 2000];
        
        system.assertEquals(2000, uspList.size());

    }*/

    @isTest(SeeAllData=FALSE)
    static void testDeleteAccount(){
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        //Set up the Custom Setting RecordDeleteSetting__c as we cannot use 'testSetup'
        Map<String, RecordDeleteSetting__c> currentRDS = RecordDeleteSetting__c.getAll();
        RecordDeleteSetting__c rds;
        if (!currentRDS.containsKey('Account')){
            rds = new RecordDeleteSetting__c(Name = 'Account', Days__c = 7, API_Name__c = 'Account');
            insert rds;
        }else {
            rds = currentRDS.get('Account');
        }

        List<Account> accList = AP23_TestDataFactory.createPersonAccount(200);
        for (Account a : accList){
            a.CreatedDate = Date.today().addDays(-14);
        }
        insert accList;

        RecordDeleteBatchClass rdbc = new RecordDeleteBatchClass();
        rdbc.objectName = rds.Name;
        rdbc.numberOfDays = integer.valueOf(rds.Days__c);

        test.startTest();
            Database.executeBatch(rdbc);
        test.stopTest();

        List<Account> checkList = [select Id from Account where CreatedDate != LAST_N_DAYS:7];
        
        system.assertEquals(0, checkList.size());

    }
}