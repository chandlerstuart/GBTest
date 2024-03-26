/*
Name: AddChatterFollowerActionTest.cls
Copyright © 2016  Golfbreaks
======================================================
======================================================
Purpose:
-------

Test suite for Apex Action class AddChatterFollowerAction.cls

Coverage for classes below (target 85%):
AddChatterFollowerAction.cls : 93%

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2016-12-06  Initial development (singleTestCase1 added).
*/
@isTest(SeeAllData=false)
public with sharing class AddChatterFollowerActionTest {
    /*
    Test cases: 
        singleTestCase1 - Standard course - insert case follower.
        ..
        negativeTestCase1 - tbd.
    */
    
    /* **/
    static testMethod void singleTestCase1() {
        // Test case 1 : Standard course - insert case follower.
        
        // create a case
        Account a = AP23_TestDataFactory.createAccount(1)[0];
        insert a;
        
        Case c = AP23_TestDataFactory.createCase(1,a)[0];
        c.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Case').getRecordTypeId(); 
        insert c;
    
        User u;    
        System.runAs(new User(Id=UserInfo.getUserId())){
            u = UserTestHelper.createStandardUsers(1, 'John','Smith')[0];
        }
                
                                
        AddChatterFollowerAction.AddChatterFollowerRequest r = new AddChatterFollowerAction.AddChatterFollowerRequest();
        r.userId=u.Id;
        r.recordId=c.Id;
                
        Test.startTest(); // start collecting async processes.
                    
        for (Boolean b : AddChatterFollowerAction.addChatterFollower(new List<AddChatterFollowerAction.AddChatterFollowerRequest> { r })){
            System.assert(b, 'Add follower request should be successful');                
        }
                    
        Test.stopTest();

        System.assertEquals(1, [select count() from EntitySubscription where SubscriberId=:u.Id and ParentId=:c.Id], 'EntitySubscription record should exist');
    }
    /* */
}