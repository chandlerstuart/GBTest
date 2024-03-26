/*
Name:  UserTriggerTestSuite.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Suite of unit tests that exercise (and verify) User Trigger

Future enhancements:

======================================================
======================================================
History
------- 
Ver. Author                               Date                Detail
1.0  Örn Ingvar Ásbjörnsson     2014-08-13    Initial development.
*/
@isTest
private class UserTriggerTestSuite {

    @isTest static void testManagerChange() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            UserTestHelper.setupOrgSettings();

            //Create the first and second managers
            User manager = UserTestHelper.createStandardUsers(1, 'Bob', 'Manager')[0];
            User manager2 = UserTestHelper.createStandardUsers(1, 'Rob', 'Manager')[0];

            //Create the employee 
            User employee = UserTestHelper.createStandardUsers(1, 'John', 'Employee')[0];

            //Create the employee leave year when the employee does not have a set manager
            EmployeeLeaveYear__c empLeaveYear = new EmployeeLeaveYear__c(Employee__c=employee.Id, Year__c='2015',StartDate__c=Date.newInstance(2015,1,1),EndDate__c=Date.newInstance(2015,12,31));
            insert empLeaveYear;

            employee.ManagerId = manager.Id;
            update employee;

            employee.ManagerId = manager2.Id;
            update employee;

            EmployeeLeaveYear__Share empShr = [SELECT Id, ParentID, RowCause, UserOrGroupId 
                                                                        FROM EmployeeLeaveYear__Share 
                                                                        WHERE ParentID =: empLeaveYear.Id 
                                                                        AND RowCause = 'Manager_Leave_Request_Access__c'];
            System.assertEquals(empShr.UserOrGroupId, manager2.Id);
        }
    }

    @isTest static void testInsert() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            UserTestHelper.setupOrgSettings();

            //Create the manager
            User manager = UserTestHelper.createStandardUsers(1, 'Bob', 'Manager')[0];

            //Create the employee 
            User employee = UserTestHelper.createStandardUsers(1, 'John', 'Employee')[0];
            
            EmployeeLeaveYear__c empLeaveYear = new EmployeeLeaveYear__c(Employee__c=employee.Id, Year__c='2015',StartDate__c=Date.newInstance(2015,1,1),EndDate__c=Date.newInstance(2015,12,31));
            insert empLeaveYear;

            //No manager access should have been given since the employee releated with the leave year has not manager upon creation
            // of the leave year
            try {
                EmployeeLeaveYear__Share empShr = [SELECT Id, ParentID, RowCause, UserOrGroupId 
                                                                            FROM EmployeeLeaveYear__Share 
                                                                            WHERE ParentID =: empLeaveYear.Id 
                                                                            AND RowCause = 'Manager_Leave_Request_Access__c'];
            } catch (Exception e) {
                System.assert(e.getMessage().contains('List has no rows'));
            }

            //Now associate manager with employee
            employee.ManagerId = manager.Id;
            update employee;

            //Create a new leave year with manager in place for employee
            EmployeeLeaveYear__c empLeaveYear1 = new EmployeeLeaveYear__c(Employee__c=employee.Id, Year__c='2016',StartDate__c=Date.newInstance(2016,1,1),EndDate__c=Date.newInstance(2016,12,31));
            insert empLeaveYear1;

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
            UserTriggerHandler.isTest = true;

            //Create the first and second managers
            User manager = UserTestHelper.createStandardUsers(1, 'Bob', 'Manager')[0];
            User manager2 = UserTestHelper.createStandardUsers(1, 'Rob', 'Manager')[0];

            //Create the employee 
            User employee = UserTestHelper.createStandardUsers(1, 'John', 'Employee')[0];

            EmployeeLeaveYear__c empLeaveYear = new EmployeeLeaveYear__c(Employee__c=employee.Id, Year__c='2015',StartDate__c=Date.newInstance(2015,1,1),EndDate__c=Date.newInstance(2015,12,31));
            insert empLeaveYear;

            employee.ManagerId = manager.Id;
            update employee;

            employee.ManagerId = manager2.Id;
            update employee;
            UserTriggerHandler.otherTestsRunning = false;
        }
    }
}