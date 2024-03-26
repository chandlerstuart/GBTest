/**
* Class Name: AP01_AccountTriggerHandler_Test
* @author: Jed Samaniego
* @date: 24.05.2016
* @description: Test Class AP01_AccountTriggerHandler
History
------- 
Ver. Author        Date         Detail 
2.0  Atlee         2016-06-03   Bulkified the test class, created assertions
2.1  J Radcliffe   2018-05-21   Bulk Test Setting the Weekly Newsletter when the legacy Newsletter subscription is changed
2.2  J Radcliffe   2019-10-17   Comment Out redundant tests - IFramework Phase 2
2.3  J Radcliffe   2019-10-17   Increase test coverage - New method to test Notification Update Activity
2.4  J Radcliffe   2024-02-13   New test method testAssignPublicIdsOnInsert
**/

@isTest(seeAllData=false)
public class AP01_AccountTriggerHandler_Test{
    @testSetup static void setupData(){
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;  
        
        List<Object_Field_Mapping__c> customSettings = AP23_TestDataFactory.getCustomSettingObjectFieldMapping();
        insert customSettings;

        insert new Phased_Code_Removal__c(ActivatePublicIdGeneration__c = true);//2.4+
        
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        
        Id recordTypeAccountClienttId = ApplicationConstant.getRecordTypeId( ApplicationConstant.OBJECT_TYPE_ACCOUNT, ApplicationConstant.RECORD_TYPE_ACCOUNT_CLIENT);
        
        List<Account> lAcc = new List<Account>();
        for(Integer i = 0; i < 50; i++){
            Account acc = new Account();
            acc.FirstName = 'Test';
            acc.LastName = 'Account';
            acc.RecordTypeId = recordTypeAccountClienttId;
            lAcc.add(acc);
        }
        insert lAcc;

        //START Kingsley
        //QueueId__c queueId = new QueueId__c(User_Id__c = '005b00000016qts'); //2.2-
        //insert queueId;//2.2-
        
        //system.debug('***queueId = ' + queueId);//2.2-
    }

    //2.3+
    @isTest static void testSetNotificationMessage(){

        String message = 'Just another test message!';

        List<Account> accsForUpdate = new List<Account>();
        for(Account acc : [Select Id, Notification_Message__c, Notification_Message_Author__c, Notification_Message_Created__c From Account]){
            system.assertEquals(null, acc.Notification_Message__c);
            system.assertEquals(null, acc.Notification_Message_Author__c);
            system.assertEquals(null, acc.Notification_Message_Created__c);
            //Set Message
            acc.Notification_Message__c = message;
            accsForUpdate.add(acc);
        }

        test.startTest();
            update accsForUpdate;
        test.stopTest();

        for(Account acc : [Select Id, Notification_Message__c, Notification_Message_Author__c, Notification_Message_Created__c From Account]){
            system.assertEquals(message, acc.Notification_Message__c);
            system.assertEquals(UserInfo.getUserId(), acc.Notification_Message_Author__c);
            system.assertNotEquals(null, acc.Notification_Message_Created__c);
        }
    }

    //2.4+
    @isTest static void testAssignPublicIdsOnInsert(){

        //Create 10 accounts
        List<Account> accList = AP23_TestDataFactory.createPersonAccount(10,true);

        test.startTest();
            insert accList;
            Map<Id,Account> accMap = new Map<Id,Account>(accList);
            system.assertEquals(10, [Select Count() From Account Where Id In:accMap.keySet() and PublicId__c != null]);//Confirm PublicId__c is set
        test.stopTest();
    }
    
    
    //Test if request queue records will be created when the last name is updated.
    /*2.2
    static testMethod void testEvents() {
        Test.startTest();
            List<Account> lAcc = [SELECT Id, IsPersonAccount, RecordTypeId FROM Account];
            for(Account acc: lAcc){
                acc.LastName = 'Updated Account'; 
                acc.Notification_Message__c = 'Test Message';   
            }
            update lAcc;
                  
            List<Request_Queue__c> lRC = [SELECT Id FROM Request_Queue__c];
            System.AssertEquals(lRC.size() > 0, TRUE);
        Test.stopTest();
    }*/
    
    /* 2.2
    static testMethod void setWeeklyNewsletterOnIndividualTest(){
        
        //Query Test Client Accounts and Individual records
        Account[] accountList = [Select Id, NewsletterSignUp__c, (Select Id, Account__c, Weekly_Newsletter__c From Individuals__r) From Account Where isPersonAccount = true];
        
        //Confirm expected number of Accounts
        system.assertEquals(50, accountList.size());

		//A Map to store the subscription status of each client before the update        
        Map<Id,Boolean> accountsWithSubscriptionStatus = new Map<Id,Boolean>();
        
        for(Account acc : accountList){
            //Store the Newsletter Sign Up Value
            accountsWithSubscriptionStatus.put(acc.Id,acc.NewsletterSignUp__c);
            //Confirm an Individual was implicitly created during test setup
            system.assertEquals(1,acc.Individuals__r.size());
            //Confirm the NewsletterSignUp matches the Individual Weekly Newsletter field
            system.assertEquals(acc.NewsletterSignUp__c,acc.Individuals__r[0].Weekly_Newsletter__c);
			//Change the NewsletterSignUp Field value
            if(acc.NewsletterSignUp__c){
                acc.NewsletterSignUp__c = false;
            }else{
                acc.NewsletterSignUp__c = true;
            }            
        }
        
        test.startTest();
        //Save Changes
        update accountList;
        test.stopTest();
        
        //Requery Clients and Individual records
        Account[] accountListAfterUpdate = [Select Id, NewsletterSignUp__c, (Select Id, Account__c, Weekly_Newsletter__c From Individuals__r) From Account Where isPersonAccount = true and Id In:accountsWithSubscriptionStatus.keySet()];
        
        for(Account acc: accountListAfterUpdate){
            //Confirm the value has been changed
            system.assertNotEquals(acc.NewsletterSignUp__c, accountsWithSubscriptionStatus.get(acc.Id));
            //Confirm the Weekly Newsletter has been updated to match the new value
            system.assertEquals(acc.NewsletterSignUp__c, acc.Individuals__r[0].Weekly_Newsletter__c);
        }
        
    }*/
    
}