/*
Name:  UserTestSuite.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Suite of unit tests that exercise (and verify) User class

Future enhancements:

======================================================
======================================================
History
------- 
Ver. Author                               Date                Detail
1.0  Örn Ingvar Ásbjörnsson     2014-07-31    Initial development.
*/
@isTest
private class UserTestSuite {

    @TestSetup static void createTestData(){
        //Enable org triggers
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;  
    }

    @isTest static void testGetUsersById() {
        List<User> userList = UserTestHelper.createStandardUsers(10, 'Roy', 'Rogers');
        Set<Id> userIdSet = new Set<Id>();
        for(User u: userList) {
            userIdSet.add(u.Id);
        }
        List<User> retrievedUserList = UserManager.getUsersById(userIdSet);
        System.assertEquals(retrievedUserList.size(), 10);
    }

    @isTest static void testGetUserIdsFromList() {
        List<User> userList = UserTestHelper.createStandardUsers(10, 'Roy', 'Rogers');
        Set<Id> userIdSet = UserManager.getUserIdsFromList(userList);
        System.assertEquals(userIdSet.size(), 10);
    }

}