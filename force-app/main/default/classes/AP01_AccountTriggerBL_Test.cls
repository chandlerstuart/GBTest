/**
* @author -         
* @date -           16-10-19
* @description -    Test Suite for AP01_AccountTriggerBL.cls 
* #############Change Log#############
* Modified by     Version     Change Date   Detail
* J.Radcliffe     1.0         16-10-19      Initial Development
* J.Radcliffe     1.1         01-11-19      Merging Marketing Preferences Tests
* J.Radcliffe     1.2         09-11-20      Test formatAccountData
* J.Radcliffe     1.3         09-11-20      Test Class Fixes to support the change in Individual creation (Ind First)
* J.Radcliffe     1.4         05-06-23      New test method testAccountDeletionPermissions
**/
@isTest
public with sharing class AP01_AccountTriggerBL_Test {

    public static Id clientRTId;

    static{
        clientRTId = [Select Id From RecordType Where DeveloperName = :ApplicationConstant.RECORD_TYPE_ACCOUNT_CLIENT][0].Id;
    }
    
    @testSetup static void createTestData(){

        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings; 

        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;

        //Insert 25 Accounts with unique email addresses. Format: uniqueEmail[index]@example.com
        Database.DMLOptions dml = new Database.DMLOptions(); 
        dml.DuplicateRuleHeader.allowSave = true;
        dml.OptAllOrNone = false;

        //1.3+
        List<Individual> individuals = new List<Individual>();
        for(Integer i=0;i<25;i++){
            individuals.add(new Individual(LastName='TestAccount'+i));
        }
        insert individuals;

        List<Account> accList = new List<Account>();
        accList = createNewAccounts(25,true);
        for(Integer i=0;i<25;i++){//1.3+
            accList[i].PersonIndividualId = individuals[i].Id;
        }
        database.insert(accList,dml);
    }

    @isTest static void testBlockDuplicateEmailsOnInsert(){
        
        //Insert 50 Accounts
        //The First 25 will be consistent with those created in test setup and should error
        //The Second 25 will be unique and should save successfully
        List<Account> accList = new List<Account>();
        accList = createNewAccounts(50,true);

        test.startTest();
            Database.DMLOptions dml = new Database.DMLOptions(); 
            dml.DuplicateRuleHeader.allowSave = true;
            dml.OptAllOrNone = false;
            Database.SaveResult[] results = database.insert(accList,dml);
        test.stopTest();

        //Assertions
        Integer successCount = 0;
        Integer failCount = 0;
        for(Database.SaveResult sr : results){
            if(sr.isSuccess()){
                successCount++;
            }else{
                system.assertEquals(Label.Account_Trigger_Matching_Email_Alert_Message_Existing_Client, sr.getErrors()[0].getMessage());
                failCount++;
            }
        }
        system.assertEquals(25, successCount);
        system.assertEquals(25, failCount);

    }

    @isTest static void testBlockDuplicateEmailsOnUpdate(){
        
        //Retrieve existing Accounts
        Account[] accList = [Select Id, PersonEmail From Account];
        system.assertEquals(25, accList.size());

        //Divide into 2 lists
        List<Account> accsToUpdate = new List<Account>();
        List<Account> accsToCopy = new List<Account>();
        for(integer i=0;i<accList.size();i++){
            if(i<(accList.size()/2)){
                accsToCopy.add(accList[i]);
            }else{
                accsToUpdate.add(accList[i]);
            }
        }

        Integer copyCount = (accsToCopy.size()<accsToUpdate.size())?accsToCopy.size():accsToUpdate.size();
        for(integer i=0;i<copyCount;i++){
            accsToUpdate[i].PersonEmail = accsToCopy[i].PersonEmail;
        }

        test.startTest();
            Database.DMLOptions dml = new Database.DMLOptions(); 
            dml.DuplicateRuleHeader.allowSave = true;
            dml.OptAllOrNone = false;

            Database.SaveResult[] results = database.update(accsToUpdate,dml);
        test.stopTest();

        //Assertions
        Integer successCount = 0;
        Integer failCount = 0;
        for(Database.SaveResult sr : results){
            if(sr.isSuccess()){
                successCount++;
            }else{
                system.assertEquals(Label.Account_Trigger_Matching_Email_Alert_Message_Existing_Client, sr.getErrors()[0].getMessage());
                failCount++;
            }
        }
        system.assertEquals(accsToUpdate.size()-copyCount, successCount);
        system.assertEquals(copyCount, failCount);   

    }

    @isTest static void testBlockDuplicateEmailsWithinTrigger(){
        
        //Attempt to create 50 new Accounts with the same email
        List<Account> accList = new List<Account>();
        accList = createNewAccounts(50,false);

        test.startTest();
            Database.DMLOptions dml = new Database.DMLOptions(); 
            dml.DuplicateRuleHeader.allowSave = true;
            dml.OptAllOrNone = false;
            Database.SaveResult[] results = database.insert(accList,dml);
        test.stopTest();

        //Assertions
        Integer successCount = 0;
        Integer failCount = 0;
        for(Database.SaveResult sr : results){
            if(sr.isSuccess()){
                successCount++;
            }else{
                system.assertEquals(Label.Account_Trigger_Matching_Email_Alert_Message_Trigger_List, sr.getErrors()[0].getMessage());
                failCount++;
            }
        }
        //The first Account should succeed, but all subsequent accounts should be blocked because they match the first records email
        system.assertEquals(1, successCount);
        system.assertEquals(49, failCount);
    }

    public static List<Account> createNewAccounts(Integer count, Boolean hasUniqueEmail){
        
        List<Account> accList = new List<Account>();
        for(integer i=0;i<count;i++){
            Account acc = new Account();
            acc.FirstName = 'Test';
            acc.LastName = 'Account'+i;
            acc.PersonEmail = (hasUniqueEmail)? 'uniqueEmail'+i+'@example.com':'notUniqueEmail@example.com';
            acc.RecordTypeId = clientRTId;
            accList.add(acc);
        }
        return accList;
    }

    //1.1
    @isTest static void mergePreferencesNeverAudited(){

        //Retrieve 3 Accounts
        Account[] accs = [Select Id, (Select Id,Data_Audit_Last_Completed__c,Brochure__c,SMS__c,Phone__c,Weekly_Newsletter__c,Quarterly_Newsletter__c From Individuals__r) From Account Limit 3];
        system.assertEquals(3, accs.size());
        Id masterRecordId = accs[0].Id;
        for(Account acc : accs){
            system.assertEquals(1, acc.Individuals__r.size());
            system.assertEquals(null, acc.Individuals__r[0].Data_Audit_Last_Completed__c);
            //Set the preferences (without an audit)
            acc.Individuals__r[0].Brochure__c = true;
            acc.Individuals__r[0].SMS__c = true;
            acc.Individuals__r[0].Phone__c = true;
            acc.Individuals__r[0].Weekly_Newsletter__c = true;
            acc.Individuals__r[0].Quarterly_Newsletter__c = true;
        }

        //Need to re-query without the related Individual Data (for merge)
        Account accToMerge = [Select Id From Account Where Id = :masterRecordId];

        test.startTest();
            merge accToMerge new List<Id>{accs[1].Id,accs[2].Id};
        test.stopTest();

        //Retrieve master record
        Account masterRecord = [Select Id, PersonIndividualId, (Select Id,Data_Audit_Last_Completed__c,Brochure__c,SMS__c,Phone__c,Weekly_Newsletter__c,Quarterly_Newsletter__c From Individuals__r) From Account Where Id =:masterRecordId];
        //confirm the Individuals have been successfully transferred
        system.assertEquals(3, masterRecord.Individuals__r.size());
        for(Individual i : masterRecord.Individuals__r){
            if(i.Id == masterRecord.PersonIndividualId){
                //Confirm the preferences have been cleared
                system.assertEquals(false, i.Brochure__c);
                system.assertEquals(false, i.SMS__c);
                system.assertEquals(false, i.Phone__c);
                system.assertEquals(false, i.Weekly_Newsletter__c);
                system.assertEquals(false, i.Quarterly_Newsletter__c);
                system.assertEquals(null, i.Data_Audit_Last_Completed__c);
            }
        }
    }

    //1.1
    @isTest static void mergePreferencesLastestAudit(){
        //Retrieve 3 Accounts
        Account[] accs = [Select Id, (Select Id,Data_Audit_Last_Completed__c,Brochure__c,SMS__c,Phone__c,Weekly_Newsletter__c,Quarterly_Newsletter__c From Individuals__r) From Account Limit 3];
        system.assertEquals(3, accs.size());
        Id masterRecordId = accs[0].Id;
        for(Account acc : accs){
            system.assertEquals(1, acc.Individuals__r.size());
            system.assertEquals(null, acc.Individuals__r[0].Data_Audit_Last_Completed__c);
            system.assertEquals(false, acc.Individuals__r[0].Brochure__c);
            system.assertEquals(false, acc.Individuals__r[0].SMS__c);
            system.assertEquals(false, acc.Individuals__r[0].Phone__c);
            system.assertEquals(false, acc.Individuals__r[0].Weekly_Newsletter__c);
            system.assertEquals(false, acc.Individuals__r[0].Quarterly_Newsletter__c);
        }

        //Assign assorted preferences to the 3 Accounts      
        List<Individual> indsToUpdate = new List<Individual>();
        //1 - Master Account - First to be Audited
        accs[0].Individuals__r[0].Data_Audit_Last_Completed__c = system.today().addDays(-100);
        accs[0].Individuals__r[0].SMS__c = true;
        accs[0].Individuals__r[0].Phone__c = true;
        accs[0].Individuals__r[0].MarketingSubscriptionChangeReason__c = 'Opt in for SMS and Phone';
        indsToUpdate.add(accs[0].Individuals__r[0]);
        //2 - Never Audited
        accs[1].Individuals__r[0].Data_Audit_Last_Completed__c = null;
        accs[1].Individuals__r[0].Brochure__c = true;
        accs[1].Individuals__r[0].MarketingSubscriptionChangeReason__c = 'Opt in for Brochure';
        indsToUpdate.add(accs[1].Individuals__r[0]);
        //3 - Last to be Audited
        accs[2].Individuals__r[0].Data_Audit_Last_Completed__c = system.today().addDays(-50);
        accs[2].Individuals__r[0].Weekly_Newsletter__c = true;
        accs[2].Individuals__r[0].Quarterly_Newsletter__c = true;
        accs[2].Individuals__r[0].Email__c = true;
        accs[2].Individuals__r[0].MarketingSubscriptionChangeReason__c = 'Opt in for Newsletters';

        indsToUpdate.add(accs[2].Individuals__r[0]);
        
        //Set the preferences
        update indsToUpdate;

        //Need to re-query without the related Individual Data (for merge)
        Account accToMerge = [Select Id From Account Where Id = :masterRecordId];

        test.startTest();
            merge accToMerge new List<Id>{accs[1].Id,accs[2].Id};
        test.stopTest();

        //Retrieve master record
        Account masterRecord = [Select Id, PersonIndividualId, (Select Id,Data_Audit_Last_Completed__c,Brochure__c,SMS__c,Phone__c,Weekly_Newsletter__c,Quarterly_Newsletter__c From Individuals__r) From Account Where Id =:masterRecordId];
        //confirm the Individuals have been successfully transferred
        system.assertEquals(3, masterRecord.Individuals__r.size());
        for(Individual i : masterRecord.Individuals__r){
            if(i.Id == masterRecord.PersonIndividualId){
                //Confirm the existing preferences have been cleared
                system.assertEquals(false, i.Brochure__c);
                system.assertEquals(false, i.SMS__c);
                system.assertEquals(false, i.Phone__c);
                //Confirm the preferences of the latest audit have been copied
                system.assertEquals(true, i.Weekly_Newsletter__c);
                system.assertEquals(true, i.Quarterly_Newsletter__c);
                //Confirm the audit date has been cleared (prompting the agent to conduct a new audit)
                system.assertEquals(null, i.Data_Audit_Last_Completed__c);
            }
        }
    }

    //1.2
    @isTest static void testFormatAccountData(){
        Account acc = new Account(FirstName='tommy',LastName='test');
        test.startTest();
            insert acc;//Trigger formatting

            //Confirm formatting has taken place on Insert
            Account accAfterInsert = [Select Id, FirstName, LastName From Account Where Id = :acc.Id];
            system.assertEquals('Tommy', accAfterInsert.FirstName);
            system.assertEquals('Test', accAfterInsert.LastName);
            system.assertNotEquals('tommy', accAfterInsert.FirstName);

            //Reset Trigger State
            AP01_AccountTriggerHandler.isBeforeUpdateTriggerCalled = false;

            acc.FirstName = 'tommy';
            acc.LastName = 'test';
            update acc;//Attempt to revert changes

            //Confirm formatting has taken place on Update
            Account accAfterUpdate = [Select Id, FirstName, LastName, IsPersonAccount From Account Where Id = :acc.Id];
            system.assertEquals('Tommy', accAfterUpdate.FirstName);
            system.assertEquals('Test', accAfterUpdate.LastName);
            system.assertNotEquals('tommy', accAfterUpdate.FirstName);

        test.stopTest();
    }

    //1.2+
    @isTest static void testFormatAccountDataInternational(){
        Account acc = new Account(FirstName='xavier',LastName='le Monnier');
        test.startTest();
            insert acc;//Trigger formatting

            //Confirm formatting has taken place on Insert
            Account accAfterInsert = [Select Id, FirstName, LastName From Account Where Id = :acc.Id];
            system.assertEquals('Xavier', accAfterInsert.FirstName);//Capitalised
            system.assertEquals('le Monnier', accAfterInsert.LastName);//Unchanged
            system.assertNotEquals('xavier', accAfterInsert.FirstName);

            //Reset Trigger State
            AP01_AccountTriggerHandler.isBeforeUpdateTriggerCalled = false;

            acc.FirstName = 'xavier';
            update acc;//Attempt to revert changes

            //Confirm formatting has taken place on Update
            Account accAfterUpdate = [Select Id, FirstName, LastName, IsPersonAccount From Account Where Id = :acc.Id];
            system.assertEquals('Xavier', accAfterUpdate.FirstName);//Capitalised
            system.assertEquals('le Monnier', accAfterUpdate.LastName);//Unchanged
            system.assertNotEquals('xavier', accAfterUpdate.FirstName);

        test.stopTest();
    }

    //1.4+ - Confirm users are prevented from deleting Account records without the required permissions
    @isTest static void testAccountDeletionPermissions(){

        //Create 100 acccounts
        List<Account> accounts = AP23_TestDataFactory.createPersonAccount(100,true);
        for(Integer i=0; i<50;i++){accounts[i].Bond_Holder__pc=true;}//50 = Bond Holders
        insert accounts;

        Map<Id,Account> accountMap = new Map<Id,Account>();//Store new accounts in a map
        for(Account acc : accounts){accountMap.put(acc.Id,acc);}

        Integer failCount = 0;
        Integer successCount = 0;
            
        Database.DeleteResult[] results = Database.delete(accounts,false);
        System.assertEquals(100, results.size());
        for(Database.DeleteResult result : results){
            if(!accountMap.get(result.getId()).Bond_Holder__pc){
                successCount = successCount+1;
                system.assertEquals(true, result.isSuccess());
            }else{
                failCount = failCount+1;
                system.assertEquals(false, result.isSuccess());
                system.assertEquals(Label.Delete_Bond_Holder_Error_Message, result.getErrors()[0].getMessage());
            }
        }
        system.assertEquals(50, failCount);
        system.assertEquals(50, successCount);

        //Assign permissions to delete bond holders to running user
        User adminUser = [Select Id From User Where IsActive = true and Id != :UserInfo.getUserId() and Profile.Name = 'Golfbreaks System Administrator' limit 1];
        Id userId = UserInfo.getUserId();
        System.runAs(adminUser){//Avoid Mixed DML Op error
        Id psId = [ SELECT ParentId FROM SetupEntityAccess WHERE SetupEntityId IN (SELECT Id FROM CustomPermission WHERE DeveloperName = :ApplicationConstant.CUSTOM_PERMISSION_DELETE_BOND_HOLDER) Limit 1].ParentId;
            insert new PermissionSetAssignment(PermissionSetId=psId,AssigneeId=userId);
        }
        Test.startTest();
            System.runAs(new User(Id = UserInfo.getUserId())){//Avoid Mixed DML Op error

                //Attempt to delete the remaining bond holder accounts 
                delete [Select Id From Account Where Id In:accountMap.keySet()];

                //Confirm the remaining accounts have now been deleted.
                system.assertEquals(0, [Select count() From Account Where Id In:accountMap.keySet()]);
            }
        Test.stopTest();
    }
}