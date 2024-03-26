/*
Name:  EmployeeLeaveYearManagerTestSuite.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Suite of unit tests that exercise (and verify) EmployeeLeaveYearManager class

Future enhancements:

======================================================
======================================================
History
------- 
Ver. Author                               Date                Detail
1.0  Örn Ingvar Ásbjörnsson     2014-07-25    Initial development.
1.1  Örn Ingvar Ásbjörnsson     2014-07-29    More detailed assertions
1.2  J Radcliffe                2020-01-31    test method 'getEmployeeLeaveYearsByUsersAndDateValueTest'
*/
@isTest
private class EmployeeLeaveYearManagerTestSuite {
    
    /*
    ======================================================
    ======================================================
    EmployeeLeaveYearManager Tests
    ======================================================
    ======================================================
    */
    @isTest static void testGetEmployeeLeaveYearByUserId() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            List<User> userList = EmployeeLeaveTestHelper.createUsersWithLeaves(1);
            List<EmployeeLeaveYear__c> leaveYears = EmployeeLeaveYearManager.getEmployeeLeaveYearByUserId(userList[0].Id);
            System.assertEquals(leaveYears.size(), 1);
        }
    }

    @isTest static void testGetEmployeeLeaveYearByUserIdAndYear() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            List<User> userList = EmployeeLeaveTestHelper.createUsersWithLeaves(2);
            EmployeeLeaveYear__c leaveYear = EmployeeLeaveYearManager.getEmployeeLeaveYearByUserIdAndYear(userList[0].Id, '2013');
            System.assertEquals(leaveYear, new EmployeeLeaveYear__c());

            EmployeeLeaveYear__c leaveYear1 = EmployeeLeaveYearManager.getEmployeeLeaveYearByUserIdAndYear(userList[0].Id, '2014');
            System.assertNotEquals(leaveYear1, new EmployeeLeaveYear__c());

            //Test the overridden version that takes a set of userIds
            Set<Id> userIdSet = new Set<Id>();
            for(User u: userList) {
                userIdSet.add(u.Id);
            }
            List<EmployeeLeaveYear__c> leaveYears = EmployeeLeaveYearManager.getEmployeeLeaveYearByUserIdAndYear(userIdSet, '2013');
            System.assertEquals(leaveYears.size(), 0);

            List<EmployeeLeaveYear__c> leaveYears1 = EmployeeLeaveYearManager.getEmployeeLeaveYearByUserIdAndYear(userIdSet, '2014');
            System.assertEquals(leaveYears1.size(), 2);
        }
    }

    @isTest static void testGetEmployeeLeaveYearsByUserIdAndYears() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            List<User> userList = EmployeeLeaveTestHelper.createUsersWithLeaves(1);
            List<String> years = new List<String>{'2010','2011','2012'};
            Map<String, EmployeeLeaveYear__c> leaveYearMap = EmployeeLeaveYearManager.getEmployeeLeaveYearsByUserIdAndYears(userList[0].Id, years);
            System.assertEquals(leaveYearMap.containsKey(userList[0].Id), false);

            List<String> years2 = new List<String>{'2014'};
            Map<String, EmployeeLeaveYear__c> leaveYearMap2 = EmployeeLeaveYearManager.getEmployeeLeaveYearsByUserIdAndYears(userList[0].Id, years2);
            System.assert(leaveYearMap2.containsKey('2014'));
        }
    }

    @isTest static void testEmployeeLeaveYearManagerExceptions() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            List<User> userList = EmployeeLeaveTestHelper.createUsersWithLeaves(2);
            List<String> years = new List<String>{'2010','2011','2012'};
            Set<Id> userIdSet = new Set<Id>();
            for(User u: userList) {
                userIdSet.add(u.Id);
            }
            EmployeeLeaveYearManager.isTest = true;
            try {
                List<EmployeeLeaveYear__c> leaveYears = EmployeeLeaveYearManager.getEmployeeLeaveYearByUserId(userList[0].Id);
            } catch (Exception e) {
                System.assert(e.getMessage().contains('thrown while testing'));
            }

            try {
                Map<String, EmployeeLeaveYear__c> leaveYearMap = EmployeeLeaveYearManager.getEmployeeLeaveYearsByUserIdAndYears(userList[0].Id, years);
            } catch (Exception e) {
                System.assert(e.getMessage().contains('thrown while testing'));
            }

            try {
                List<EmployeeLeaveYear__c> leaveYears = EmployeeLeaveYearManager.getEmployeeLeaveYearByUserIdAndYear(userIdSet, '2013');
            } catch (Exception e) {
                System.assert(e.getMessage().contains('thrown while testing'));
            }
            EmployeeLeaveYearManager.isTest = false;
        }
    }

    @isTest static void getEmployeeLeaveYearsByUsersAndDateValueTest(){

        //Create 2 years worth of Leave Year for 2 Users
        List<User> users = AP23_TestDataFactory.createStandardUsers(2, 'TestUser', true);
        User user1 = users[0];
        User user2 = users[1];

        List<EmployeeLeaveYear__c> lyears = new List<EmployeeLeaveYear__c>();
        lyears.add(CalendarTestHelper.createEmployeeLeaveYear(user1,'2019',false));
        lyears.add(CalendarTestHelper.createEmployeeLeaveYear(user1,'2020',false));
        lyears.add(CalendarTestHelper.createEmployeeLeaveYear(user2,'2019',false));
        lyears.add(CalendarTestHelper.createEmployeeLeaveYear(user2,'2020',false));
        insert lyears;

        test.startTest();

            List<EmployeeLeaveYear__c> yearsTwentyNineteen = EmployeeLeaveYearManager.getEmployeeLeaveYearsByUsersAndDateValue(new set<Id>{user1.Id,user2.Id},Date.newInstance(2019,08,01)).values();
            List<EmployeeLeaveYear__c> yearsTwentyTwenty = EmployeeLeaveYearManager.getEmployeeLeaveYearsByUsersAndDateValue(new set<Id>{user1.Id,user2.Id},Date.newInstance(2020,08,01)).values();

        test.stopTest();

        system.assertEquals(2, yearsTwentyNineteen.size());
        system.assertEquals('2019', yearsTwentyNineteen[0].Year__c);
        system.assertEquals('2019', yearsTwentyNineteen[1].Year__c);

        system.assertEquals(2, yearsTwentyTwenty.size());
        system.assertEquals('2020', yearsTwentyTwenty[0].Year__c);
        system.assertEquals('2020', yearsTwentyTwenty[1].Year__c);       

    }
    
}