/*
Name:  ActOnItMessageActionTakeOwnershipTest.cls
======================================================
======================================================
Purpose:
-------
Test Suite for ActOnItMessageActionTakeOwnership.cls
======================================================
======================================================
History
------- 
Ver.  Author            Date        Detail
1.0   J Radcliffe       2021-03-23  Class creation.
*/
@isTest
public with sharing class ActOnItMessageActionTakeOwnershipTest {
    
    @TestSetup static void  createTestData(){
        
        //Create 100 Accounts
        List<Account> accs = AP23_TestDataFactory.createPersonAccount(100);
        insert accs;

        //Retrieve Active Sales User
        User user = [Select Id From User Where Profile.Name = :ApplicationConstant.PROFILE_SALES_AGENT and IsActive = true Limit 1];

        //Create 100 Opportunities
        List<Opportunity> opps = new List<Opportunity>();
        for(Account acc : accs){
            Opportunity opp = AP23_TestDataFactory.createOpportunity(1,'New',acc)[0];
            opp.OwnerId = user.Id;//Assign Opp to Sales User
            opps.add(opp);
        }
        insert Opps;
        
        //Confirm Opps remain assigned to Sales User after insert
        system.assertEquals(100, [Select Count() From Opportunity Where OwnerId = :user.Id]);

    }

    @isTest static void testBulkUpdate(){

        Id userId = UserInfo.getUserId();

        List<Id> oppIds = new List<Id>();
        for(Opportunity opp : [Select Id, OwnerId From Opportunity]){
            system.assertNotEquals(userId, opp.OwnerId);//Confirm the Opp is not owned by the running user
            oppIds.add(opp.Id);
        }
        system.assertEquals(100, oppIds.size());//Confirm the expected number of opps (created in testSetup)

        test.startTest();
            ActOnItMessageActionTakeOwnership action = new ActOnItMessageActionTakeOwnership();
            ActOnIt.ActOnItMessageActionResult result = action.execute( UserInfo.getUserId(), null, null, null, oppIds);
        test.stopTest();

        system.assertEquals(true, result.isSuccess);//Is Successful
        system.assertEquals(null, result.errorMessage);//No errors returned
        system.assertEquals(null, result.successMessage);//Omit Success Message (so the configured default is used)
        system.assertEquals(null, result.navigateToRecordId);//Null (because there are multiple Opps)
        
        //Confirm all the Opps have been successfully assigned to the running user
        system.assertEquals(100, [Select Count() From Opportunity Where OwnerId =:userId]);

    }
}