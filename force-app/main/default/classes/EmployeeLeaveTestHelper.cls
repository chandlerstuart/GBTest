/*
Name:  EmployeeLeaveTestHelper.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Test Helper class that generates Employee Leave requests
for testing purposes.
======================================================
======================================================
History
------- 
Ver. Author        Date                 Detail
1.0  Örn Ingvar  2014-07-30     Initial development.
1.1  J.Radcliffe 2020-01-28     Ensure Required fields are provided on Employee Leave Year (Start & End Date)
*/
@isTest
public with sharing class EmployeeLeaveTestHelper {

    public static List<User> createUsersWithLeaves() {
        //Create 200 users so that it becomes possible to test next and prev functions
        return createUsersWithLeaves(200);
    }

    public static List<User> createUsersWithLeaves(Integer noOfUsersToCreate) {
        List<User> userList = UserTestHelper.createStandardUsers(noOfUsersToCreate, 'HAL', '900');

        Date startDate = Date.newInstance(2014, 1, 1);//1.1+
        Date endDate = Date.newInstance(2014, 12, 31);//1.1+
        
        //Create Leave Year records for all the newly created users 
        List<EmployeeLeaveYear__c> leaveYearList = new List<EmployeeLeaveYear__c>();
        for(User u: userList) {
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name=u.FirstName+' '+u.LastName+' '+Math.random()*1000,Employee__c=u.Id, Year__c = '2014',StartDate__c=startDate,EndDate__c=endDate);//1.1~
            leaveYearList.add(leaveYear);
        }
        insert leaveYearList;

        //Create leave records for all the newly created users
        List<Leave__c> leaveList = new List<Leave__c>();
        Integer i = 0;
        for(User u: userList) {
            Leave__c l = new Leave__c(Employee__c=u.Id, StartDate__c=Date.newInstance(2014, 08, 01), EndDate__c=Date.newInstance(2014,08,03),
                Status__c='approved', EmployeeLeaveYear__c=leaveYearList[i].Id);
            leaveList.add(l);
            i++;
        }
        insert leaveList;
        return userList;
    }
}