/*
Name:  EmployeeLeaveYearTriggerTestSuite.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Suite of unit tests that exercise (and verify) Employee Leave Year Trigger

Future enhancements:

======================================================
======================================================
History
------- 
Ver. Author                               Date                Detail
1.0  Örn Ingvar Ásbjörnsson     2014-08-13    Initial development.
*/
@isTest
private class EmployeeLeaveYearTriggerTestSuite {
    
    @isTest static void testInsertAndUpdate() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            //Disable sharing calculations since they don't matter in this test
            UserTriggerHandler.otherTestsRunning = true;
            UserTestHelper.setupOrgSettings();

            //Create the first and second managers
            User manager = UserTestHelper.createStandardUsers(1, 'Bob', 'Manager')[0];
            User manager2 = UserTestHelper.createStandardUsers(1, 'Rob', 'Manager')[0];

            //Create the employee 
            User employee = UserTestHelper.createStandardUsers(1, 'John', 'Employee')[0];

            EmployeeLeaveYear__c empLeaveYear = new EmployeeLeaveYear__c(Employee__c=employee.Id, Year__c='2015', OwnerId=manager.Id);
            insert empLeaveYear;

            employee.ManagerId = manager.Id;
            update employee;

            update empLeaveYear;

            EmployeeLeaveYear__c queriedLeaveYear = [SELECT Id, OwnerId FROM EmployeeLeaveYear__c WHERE Id =: empLeaveYear.Id];
            System.assertEquals(queriedLeaveYear.OwnerId, employee.Id);
            UserTriggerHandler.otherTestsRunning = false;
        }
    }

    @isTest static void testSharing() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {            
            UserTestHelper.setupOrgSettings();

            //Create the manager
            User manager = UserTestHelper.createStandardUsers(1, 'Bob', 'Manager')[0];

            //Create the employee 
            User employee = UserTestHelper.createStandardUsers(1, 'John', 'Employee')[0];
            employee.ManagerId = manager.Id;
            update employee;

            EmployeeLeaveYear__c empLeaveYear = new EmployeeLeaveYear__c(Employee__c=employee.Id, Year__c='2015');
            insert empLeaveYear;

            EmployeeLeaveYear__Share empShr = [SELECT Id, ParentID, RowCause, UserOrGroupId 
                                                                        FROM EmployeeLeaveYear__Share 
                                                                        WHERE ParentID =: empLeaveYear.Id 
                                                                        AND RowCause = 'Manager_Leave_Request_Access__c'];
            System.assertEquals(empShr.UserOrGroupId, manager.Id);
        }
    }
    
    @isTest static void testExceptions() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            //Disable sharing calculations since they don't matter in this test
            UserTriggerHandler.otherTestsRunning = true;
            UserTestHelper.setupOrgSettings();

            //Create the first and second managers
            User manager = UserTestHelper.createStandardUsers(1, 'Bob', 'Manager')[0];
            User manager2 = UserTestHelper.createStandardUsers(1, 'Rob', 'Manager')[0];

            //Create the employee 
            User employee = UserTestHelper.createStandardUsers(1, 'John', 'Employee')[0];
            EmployeeLeaveYearTriggerHandler.isTest = true;
            EmployeeLeaveYear__c empLeaveYear = new EmployeeLeaveYear__c(Employee__c=employee.Id, Year__c='2015', OwnerId=manager.Id);
            //Throw an exception for an insert
            try {
                insert empLeaveYear;
            } catch (Exception e) {
                System.assert(e.getMessage().contains('thrown while testing'));
            }

            //Do an update to throw an exception for that
            empLeaveYear.Year__c='2014';
            try {
                update empLeaveYear;
            } catch (Exception e) {
                System.assert(e.getMessage().contains('thrown while testing'));
            }

            EmployeeLeaveYearTriggerHandler.isTest = false;
            UserTriggerHandler.otherTestsRunning = false;
        }
    }
}