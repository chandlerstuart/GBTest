/*
Name:  EmployeeWorkingPatternManagerTestSuite.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Suite of unit tests that exercise (and verify) EmployeeWorkingPatternManager  class

Future enhancements:

======================================================
======================================================
History
------- 
Ver. Author                               Date                Detail
1.0  Örn Ingvar Ásbjörnsson     2014-07-25    Initial development.
1.1  Örn Ingvar Ásbjörnsson     2014-07-29    More detailed assertions
*/
@isTest
private class EmployeeWorkingPatternManagerTestSuite {
    
    /*
    ======================================================
    ======================================================
    EmployeeWorkingPatternManager Tests
    ======================================================
    ======================================================
    */
    @isTest static void testGetUserWorkingPatternById() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            //Call the function with an empty set of user ids
            List<EmployeeWorkingPattern__c> emptyEmpWpList = EmployeeWorkingPatternManager.getUserWorkingPatternById(new Set<Id>());
            System.assertEquals(emptyEmpWpList.size(), 0);

            List<User> userList = EmployeeLeaveTestHelper.createUsersWithLeaves(5);
            Set<Id> userIdSet = new Set<Id>();
            List<EmployeeWorkingPattern__c> wpList = new List<EmployeeWorkingPattern__c>();
            for(User u: userList) {
                userIdSet.add(u.Id);
                EmployeeWorkingPattern__c wp = new EmployeeWorkingPattern__c(StartDate__c=Date.newInstance(2014,01,01),
                    EndDate__c=Date.newInstance(2014,12,31),Monday__c=true,Tuesday__c=true,Wednesday__c=true, Thursday__c=true,
                    Friday__c=true, Saturday__c=false, Sunday__c=false, Employee__c=u.Id);
                wpList.add(wp);
            }
            insert wpList;

            //Call the function with a real set of user ids
            List<EmployeeWorkingPattern__c> empWpList = EmployeeWorkingPatternManager.getUserWorkingPatternById(userIdSet);
            System.assertEquals(empWpList.size(), 5);
        }
    }

    @isTest static void testGetUserWorkingPatternByIdAndPeriod() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            Date startD = Date.newInstance(2014, 05, 11);
            Date endD = Date.newInstance(2014, 05, 31);

            //Call the function with an empty set
            List<EmployeeWorkingPattern__c> emptyEmpWpList = 
                EmployeeWorkingPatternManager.getUserWorkingPatternByIdAndPeriod(new Set<Id>(), startD, endD);
            System.assertEquals(emptyEmpWpList.size(), 0);

            List<User> userList = EmployeeLeaveTestHelper.createUsersWithLeaves(1);
            Set<Id> userIdSet = new Set<Id>();
            List<EmployeeWorkingPattern__c> wpList = new List<EmployeeWorkingPattern__c>();
            for(User u: userList) {
                userIdSet.add(u.Id);
                EmployeeWorkingPattern__c wp = new EmployeeWorkingPattern__c(StartDate__c=Date.newInstance(2014,01,01),
                    EndDate__c=Date.newInstance(2014,12,31),Monday__c=true,Tuesday__c=true,Wednesday__c=true, Thursday__c=true,
                    Friday__c=true, Saturday__c=false, Sunday__c=false, Employee__c=u.Id);
                wpList.add(wp);
            }
            insert wpList;

            //Call the function with userIds
            List<EmployeeWorkingPattern__c> empWpList = EmployeeWorkingPatternManager.getUserWorkingPatternByIdAndPeriod(userIdSet, startD, endD);
        }
    }

    @isTest static void testGetUserWorkingPatternMapByIdAndPeriod() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            Date startDate = Date.newInstance(2014, 01, 01);
            Date endDate = Date.newInstance(2014, 01, 31);
            Map<Id, List<EmployeeWorkingPattern__c>> emptyEmpWpMap = 
                EmployeeWorkingPatternManager.getUserWorkingPatternMapByIdAndPeriod(new Set<Id>(), startDate, endDate);
            System.assertEquals(emptyEmpWpMap.isEmpty(), true);

            List<User> userList = EmployeeLeaveTestHelper.createUsersWithLeaves(4);
            Set<Id> userIdSet = new Set<Id>();
            List<EmployeeWorkingPattern__c> wpList = new List<EmployeeWorkingPattern__c>();
            for(User u: userList) {
                userIdSet.add(u.Id);
                EmployeeWorkingPattern__c wp = new EmployeeWorkingPattern__c(StartDate__c=Date.newInstance(2014,01,01),
                    EndDate__c=Date.newInstance(2014,12,31),Monday__c=true,Tuesday__c=true,Wednesday__c=true, Thursday__c=true,
                    Friday__c=true, Saturday__c=false, Sunday__c=false, Employee__c=u.Id);
                wpList.add(wp);
            }
            insert wpList;
            Map<Id, List<EmployeeWorkingPattern__c>> empWpMap = 
                EmployeeWorkingPatternManager.getUserWorkingPatternMapByIdAndPeriod(userIdSet, startDate, endDate);
            System.assertEquals(empWpMap.keySet().size(), 4);
        }
    }

    @isTest static void testGetUserWorkingPatternMapActiveToday() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            Date startDate = Date.newInstance(2014, 07, 30);
            //Call the function without any data present
            List<EmployeeWorkingPattern__c> emptyEmpWpList = 
                EmployeeWorkingPatternManager.getUserWorkingPatternMapActiveToday(startDate);
            System.assertEquals(emptyEmpWpList.size(), 0);

            List<User> userList = EmployeeLeaveTestHelper.createUsersWithLeaves(3);
            Set<Id> userIdSet = new Set<Id>();
            List<EmployeeWorkingPattern__c> wpList = new List<EmployeeWorkingPattern__c>();
            for(User u: userList) {
                userIdSet.add(u.Id);
                EmployeeWorkingPattern__c wp = new EmployeeWorkingPattern__c(StartDate__c=Date.newInstance(2014,01,01),
                    EndDate__c=Date.newInstance(2014,12,31),Monday__c=false,Tuesday__c=true,Wednesday__c=false, Thursday__c=true,
                    Friday__c=true, Saturday__c=true, Sunday__c=false, Employee__c=u.Id);
                wpList.add(wp);
            }
            insert wpList;
            System.debug('=== wpList: ' + wpList);
            List<EmployeeWorkingPattern__c> empWpList = 
                EmployeeWorkingPatternManager.getUserWorkingPatternMapActiveToday(startDate);
            System.debug('=== wpList after: ' + empWpList);
            System.assertEquals(empWpList.size(), 3);
        }
    }

    @isTest static void testIsWorkingDay() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            User u = UserTestHelper.createStandardUsers(1, 'Flash', 'Gordon')[0];
            EmployeeWorkingPattern__c wp = new EmployeeWorkingPattern__c(StartDate__c=Date.newInstance(2014,01,01),
                    EndDate__c=Date.newInstance(2014,12,31),Monday__c=true,Tuesday__c=true,Wednesday__c=true, Thursday__c=true,
                    Friday__c=true, Saturday__c=false, Sunday__c=false, Employee__c=u.Id);
            insert wp;

            Boolean check = EmployeeWorkingPatternManager.isWorkingDay(new List<EmployeeWorkingPattern__c>{wp}, Date.newInstance(2013, 01, 31));
            System.assertEquals(check, false);

            Boolean check1 = EmployeeWorkingPatternManager.isWorkingDay(new List<EmployeeWorkingPattern__c>{wp}, Date.newInstance(2014, 01, 31));
            System.assertEquals(check1, true);
        }
    }

    @isTest static void testEmployeeWorkingPatternExceptions() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            EmployeeWorkingPatternManager.isTest = true;
            try {
                EmployeeWorkingPatternManager.getUserWorkingPatternById(new Set<Id>());
            } catch (Exception e) {
                System.assert(e.getMessage().contains('thrown while testing'));
            }

            try {
                EmployeeWorkingPatternManager.getUserWorkingPatternByIdAndPeriod(new Set<Id>(), Date.newInstance(2014, 01, 01), 
                    Date.newInstance(2014, 01, 07));
            } catch (Exception e) {
                System.assert(e.getMessage().contains('thrown while testing'));
            }

            try {
                EmployeeWorkingPatternManager.getUserWorkingPatternMapByIdAndPeriod(new Set<Id>(), Date.newInstance(2014, 01, 01), 
                    Date.newInstance(2014, 01, 07));
            } catch (Exception e) {
                System.assert(e.getMessage().contains('thrown while testing'));
            }
        }
    }
    
}