/*
Name:  AbsentEmployeeListTestSuite.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Suite of unit tests that exercise (and verify) Visualforce extension AbsentEmployeeListControllerExt

Future enhancements:

======================================================
======================================================
History
------- 
Ver. Author                               Date                Detail
1.0  Örn Ingvar Ásbjörnsson     2014-07-23    Initial development.
1.1  Örn Ingvar Ásbjörnsson     2014-08-18    Increased code coverage
*/
@isTest
private class AbsentEmployeeListTestSuite {

    @isTest static void testExtension() {
        Account a = new Account(Name='D');
        insert a;
        ApexPages.StandardController stdCont = new ApexPages.StandardController(a);
        AbsentEmployeeListControllerExt cont = new AbsentEmployeeListControllerExt(stdCont);
        cont.initAction();
    }

    @isTest static void testWrapper() {
        //Disable sharing calculations since they don't matter in this test
        UserTriggerHandler.otherTestsRunning = true;
        EmployeeLeaveYearTriggerHandler.otherTestsRunning = true;
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
            UserTestHelper.setupOrgSettings();
            User u = UserTestHelper.createStandardUsers(1, 'Flash', 'Gordon')[0];

            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Employee__c=u.Id, Year__c = String.valueOf(System.today().year()));
            insert leaveYear;

            Leave__c l = new Leave__c(Employee__c=u.Id, StartDate__c=System.today(), EndDate__c=System.today().addDays(2),
                    Status__c='Approved', EmployeeLeaveYear__c=leaveYear.Id);
            insert l;

            AbsentEmployeeListControllerExt.AbsentWrapper wrap = new AbsentEmployeeListControllerExt.AbsentWrapper(l);

            Date startDate = Date.newInstance(2014, 01, 01);
            Date endDate = Date.newInstance(2014, 12, 31);
            EmployeeWorkingPattern__c wp = CalendarTestHelper.createWorkingPattern(u, true, true, true, true, true, false, false, startDate, endDate);

            AbsentEmployeeListControllerExt.AbsentWrapper wrap1 = new AbsentEmployeeListControllerExt.AbsentWrapper(wp);

            System.assertEquals(wrap.compareTo(wrap1), 0);
            wrap1.name = 'Flask Gordon';
            System.assertEquals(wrap.compareTo(wrap1), -1);
            
        }
        UserTriggerHandler.otherTestsRunning = true;
        EmployeeLeaveYearTriggerHandler.otherTestsRunning = false;
    }
    
    @isTest static void testAuraMethod() {
        //Disable sharing calculations since they don't matter in this test
        UserTriggerHandler.otherTestsRunning = true;
        EmployeeLeaveYearTriggerHandler.otherTestsRunning = true;
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {

            User u = UserTestHelper.createStandardUsers(1, 'Flash', 'Gordon')[0];
    
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Employee__c=u.Id, Year__c = String.valueOf(System.today().year()));
            insert leaveYear;
    
            Leave__c l = new Leave__c(Employee__c=u.Id, StartDate__c=System.today(), EndDate__c=System.today().addDays(2),
                    Status__c='Approved', EmployeeLeaveYear__c=leaveYear.Id);
            insert l;
    
            integer yr = integer.valueOf((System.today().year().format()).replace(',',''));
            Date startDate = Date.newInstance(yr, 01, 01);
            Date endDate = Date.newInstance(yr, 12, 31);
            EmployeeWorkingPattern__c wp = CalendarTestHelper.createWorkingPattern(u, true, true, true, true, true, false, false, startDate, endDate);
    
                
            List<AbsentEmployeeListControllerExt.AbsentWrapper> absentList;
            
            test.startTest();
                List<Leave__c> leaveList = [select Id from Leave__c];
                system.assertNotEquals(0, leaveList.size());
                List<EmployeeWorkingPattern__c> wpList = [select Id from EmployeeWorkingPattern__c];
                system.assertNotEquals(0, wpList.size());
                absentList = AbsentEmployeeListControllerExt.getAbsenceList();
            test.stopTest();
            
            system.assertNotEquals(null, absentList);
        }
        
        
    }

}