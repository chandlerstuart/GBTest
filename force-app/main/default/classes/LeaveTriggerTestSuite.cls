/*
Name:  LeaveTriggerTestSuite.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Suite of unit tests that exercise (and verify) Leave Trigger

Future enhancements:

======================================================
======================================================
History
------- 
Ver. Author                               Date                Detail
1.0  Örn Ingvar Ásbjörnsson     2014-08-13    Initial development.
1.1  J Radcliffe                2019-10-31    Bug Fix - Static start date and relative end date caused the #days requested to exceed 1000 days (field length limit = 3)
1.2  J Radcliffe                2020-01-23    New Method - testDaysCalculationWithPublicHolidays- Test Holiday Calculation on Insert and Update using new PublicHoliday__c Object 
1.3  J Radcliffe                2020-01-28    Start & End Dates are now required for Employee Leave Years
*/
@isTest
private class LeaveTriggerTestSuite {
    
    @isTest static void testInsert() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {

            Date yearStart = Date.newInstance(2014,1,1);//1.3+
            Date yearEnd = Date.newInstance(2014,12,31);//1.3+

            //Disable sharing calculations since they don't matter in this test
            UserTriggerHandler.otherTestsRunning = true;
            EmployeeLeaveYearTriggerHandler.otherTestsRunning = true;
            UserTestHelper.setupOrgSettings();

            User u = UserTestHelper.createStandardUsers(1, 'Flash', 'Gordon')[0];
            
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year 1',Employee__c=u.Id, Year__c = '2014',StartDate__c=yearStart,EndDate__c=yearEnd);//1.3+
            insert leaveYear;

            Date start = Date.newInstance(2014, 09, 09);
            Leave__c l = new Leave__c(Employee__c=u.Id, StartDate__c=start, EndDate__c=start.addDays(2),
                    Status__c='Approved', EmployeeLeaveYear__c=leaveYear.Id);
            insert l;
            
            //Create a leave with no enddate
            Leave__c l1 = new Leave__c(Employee__c=u.Id, StartDate__c=start.addDays(3), Status__c='Approved', 
                EmployeeLeaveYear__c=leaveYear.Id, AM__c=true, PMStart__c=true, PMReturn__c=true);
            insert l1;

            Leave__c queriedLeave = [SELECT Id, EndDate__c FROM Leave__c WHERE Id =: l1.Id];
            System.assertEquals(queriedLeave.EndDate__c, l1.StartDate__c);
            //TODO: More Asserts
            UserTriggerHandler.otherTestsRunning = false;
            EmployeeLeaveYearTriggerHandler.otherTestsRunning = false;
        }
    }
    
    @isTest static void testUpdate() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {

            Date yearStart = Date.newInstance(system.today().year(),1,1);//1.3+
            Date yearEnd = Date.newInstance(system.today().year(),12,31);//1.3+

            //Disable sharing calculations since they don't matter in this test
            UserTriggerHandler.otherTestsRunning = true;
            EmployeeLeaveYearTriggerHandler.otherTestsRunning = true;
            UserTestHelper.setupOrgSettings();

            User u = UserTestHelper.createStandardUsers(1, 'Flash', 'Gordon')[0];

            //Date start = Date.newInstance(2014, 09, 09);//1.1-
            Date start = system.today().addDays(-7);//1.1+

            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year 2',Employee__c=u.Id, Year__c = String.valueOf(start.year()),StartDate__c=yearStart,EndDate__c=yearEnd);
            insert leaveYear;
            
            Leave__c l = new Leave__c(Employee__c=u.Id, StartDate__c=start, EndDate__c=start.addDays(2),
                    Status__c='Approved', EmployeeLeaveYear__c=leaveYear.Id, AM__c=true, PMStart__c=true, PMReturn__c=true);
            insert l;

            l.EndDate__c = System.today().addDays(3);
            l.HR_Comments__c = 'Added one day as per request';
            update l;

            //TODO: Asserts
            UserTriggerHandler.otherTestsRunning = false;
            EmployeeLeaveYearTriggerHandler.otherTestsRunning = false;
        }
    }

    @isTest static void testParkingSpaceUpdate() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            //Disable sharing calculations since they don't matter in this test
            UserTriggerHandler.otherTestsRunning = true;
            EmployeeLeaveYearTriggerHandler.otherTestsRunning = true;
            UserTestHelper.setupOrgSettings();

            User u = UserTestHelper.createStandardUsers(1, 'Flash', 'Gordon')[0];
            User u1 = UserTestHelper.createStandardUsers(1, 'Dale', 'Arden')[0];
            
            List<Car_Detail__c> carList = new List<Car_Detail__c>();
            
            Car_Detail__c car = new Car_Detail__c(Owner__c = u.Id);
            car.Make__c = 'BMW';
            car.Model__c = '318i';
            car.Colour__c = 'Silver';
            car.Name = 'TC01 CAR';
            carList.add(car);
            
            Car_Detail__c car1 = new Car_Detail__c(Owner__c = u1.Id);
            car1.Make__c = 'BMW';
            car1.Model__c = '318i';
            car1.Colour__c = 'Silver';
            car1.Name = 'TC02 CAR';
            carList.add(car1);
            
            insert carList;
            
            List<Parking_Space__c> psList = new List<Parking_Space__c>();
            
            Parking_Space__c ps = new Parking_Space__c(Owner__c = u.Id);
            ps.Name = '100';
            psList.add(ps);
            
            Parking_Space__c ps1 = new Parking_Space__c(Owner__c = u1.Id);
            ps1.Name = '101';
            ps1.Available_From__c = Date.today().addDays(10);
            ps1.Available_To__c = Date.today().addDays(11);
            psList.add(ps1);
            
            insert psList;
            
            Date start = Date.today().addDays(7);

            List<EmployeeLeaveYear__c> yearList = new List<EmployeeLeaveYear__c>();
            List<Leave__c> leaveList = new List<Leave__c>();

            Date yearStart = Date.newInstance(system.today().year(),1,1);//1.3+
            Date yearEnd = Date.newInstance(system.today().year(),12,31);//1.3+

            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year 3',Employee__c=u.Id, Year__c = String.valueOf(start.year()),StartDate__c=yearStart,EndDate__c=yearEnd);//1.3+
            EmployeeLeaveYear__c leaveYear1 = new EmployeeLeaveYear__c(Name='Test Leave Year 4',Employee__c=u1.Id, Year__c = String.valueOf(start.year()),StartDate__c=yearStart,EndDate__c=yearEnd);//1.3+
            yearList.add(leaveYear);
            yearList.add(leaveYear1);
            insert yearList;
            
            Leave__c l = new Leave__c(Employee__c=u.Id, StartDate__c=start, EndDate__c=start.addDays(7),
                    EmployeeLeaveYear__c=leaveYear.Id, AM__c=true, PMStart__c=true, PMReturn__c=true);
            Leave__c l1 = new Leave__c(Employee__c=u1.Id, StartDate__c=start, EndDate__c=start.addDays(7),
                    EmployeeLeaveYear__c=leaveYear.Id, AM__c=true, PMStart__c=true, PMReturn__c=true);

            leaveList.add(l);
            leaveList.add(l1);
            
            insert leaveList;

            system.debug('*** -- About to update Leave for - ' + l.Employee__c + ' with ' + ps.Owner__c + ' -- ***');
            l.Status__c = 'Approved';
            l.HR_Comments__c = 'Approved';
            l1.Status__c = 'Approved';
            l1.HR_Comments__c = 'Approved';

            update leaveList;

            system.debug('*** -- Update should have run -- ***');

            //TODO: Asserts
            UserTriggerHandler.otherTestsRunning = false;
            EmployeeLeaveYearTriggerHandler.otherTestsRunning = false;
        }
    }
    
    @isTest static void testParkingSpaceDelete() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            //Disable sharing calculations since they don't matter in this test
            UserTriggerHandler.otherTestsRunning = true;
            EmployeeLeaveYearTriggerHandler.otherTestsRunning = true;
            UserTestHelper.setupOrgSettings();

            User u = UserTestHelper.createStandardUsers(1, 'Flash', 'Gordon')[0];
            User u1 = UserTestHelper.createStandardUsers(1, 'Dale', 'Arden')[0];
            
            List<Car_Detail__c> carList = new List<Car_Detail__c>();
            
            Car_Detail__c car = new Car_Detail__c(Owner__c = u.Id);
            car.Make__c = 'BMW';
            car.Model__c = '318i';
            car.Colour__c = 'Silver';
            car.Name = 'TC01 CAR';
            carList.add(car);
            
            Car_Detail__c car1 = new Car_Detail__c(Owner__c = u1.Id);
            car1.Make__c = 'BMW';
            car1.Model__c = '318i';
            car1.Colour__c = 'Silver';
            car1.Name = 'TC02 CAR';
            carList.add(car1);
            
            insert carList;
            
            List<Parking_Space__c> psList = new List<Parking_Space__c>();
            
            Parking_Space__c ps = new Parking_Space__c(Owner__c = u.Id);
            ps.Name = '100';
            psList.add(ps);
            
            Parking_Space__c ps1 = new Parking_Space__c(Owner__c = u1.Id);
            ps1.Name = '101';
            ps1.Available_From__c = Date.today().addDays(10);
            ps1.Available_To__c = Date.today().addDays(11);
            psList.add(ps1);
            
            insert psList;
            
            Date start = Date.today();

            List<EmployeeLeaveYear__c> yearList = new List<EmployeeLeaveYear__c>();
            List<Leave__c> leaveList = new List<Leave__c>();

            Date yearStart = Date.newInstance(start.year(),1,1);//1.3+
            Date yearEnd = Date.newInstance(start.year(),12,31);//1.3+

            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year 5',Employee__c=u.Id, Year__c = String.valueOf(start.year()),StartDate__c=yearStart,EndDate__c=yearEnd);//1.3+
            EmployeeLeaveYear__c leaveYear1 = new EmployeeLeaveYear__c(Name='Test Leave Year 6',Employee__c=u1.Id, Year__c = String.valueOf(start.year()),StartDate__c=yearStart,EndDate__c=yearEnd);//1.3+
            yearList.add(leaveYear);
            yearList.add(leaveYear1);
            insert yearList;
            
            Leave__c l = new Leave__c(Employee__c=u.Id, StartDate__c=start, EndDate__c=start.addDays(7),
                    EmployeeLeaveYear__c=leaveYear.Id, AM__c=true, PMStart__c=true, PMReturn__c=true);
            Leave__c l1 = new Leave__c(Employee__c=u1.Id, StartDate__c=start, EndDate__c=start.addDays(7),
                    EmployeeLeaveYear__c=leaveYear.Id, AM__c=true, PMStart__c=true, PMReturn__c=true);

            leaveList.add(l);
            leaveList.add(l1);
            
            insert leaveList;

            system.debug('*** -- About to update Leave for - ' + l.Employee__c + ' with ' + ps.Owner__c + ' -- ***');
            l.Status__c = 'Approved';
            l.HR_Comments__c = 'Approved';
            l1.Status__c = 'Approved';
            l1.HR_Comments__c = 'Approved';

            update leaveList;

            system.debug('*** -- Update should have run -- ***');
            
            delete leaveList;

            //TODO: Asserts
            UserTriggerHandler.otherTestsRunning = false;
            EmployeeLeaveYearTriggerHandler.otherTestsRunning = false;
        }
    }

    @isTest static void testOverlapCheck() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            //Disable sharing calculations since they don't matter in this test
            UserTriggerHandler.otherTestsRunning = true;
            EmployeeLeaveYearTriggerHandler.otherTestsRunning = true;
            UserTestHelper.setupOrgSettings();

            User u = UserTestHelper.createStandardUsers(1, 'Flash', 'Gordon')[0];

            Date start = Date.newInstance(2014, 09, 09);

            Date yearStart = Date.newInstance(2014,1,1);//1.3+
            Date yearEnd = Date.newInstance(2014,12,31);//1.3+
            
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year 7',Employee__c=u.Id, Year__c = String.valueOf(start.year()),StartDate__c=yearStart,EndDate__c=yearEnd);//1.3+
            insert leaveYear;
            
            //Create two leaves that should overlap
            Leave__c l = new Leave__c(Employee__c=u.Id, StartDate__c=start, EndDate__c=start.addDays(2),
                    Status__c='Approved', EmployeeLeaveYear__c=leaveYear.Id);
            Leave__c l2 = new Leave__c(Employee__c=u.Id, StartDate__c=start, EndDate__c=start.addDays(5),
                    Status__c='Approved', EmployeeLeaveYear__c=leaveYear.Id);
            Leave__c l3 = new Leave__c(Employee__c=u.Id, StartDate__c=start.addDays(2), EndDate__c=start.addDays(3),
                    Status__c='Approved', EmployeeLeaveYear__c=leaveYear.Id);
            try {
                insert new List<Leave__c>{l, l2};
            } catch (Exception e) {
                System.assert(e.getMessage().contains('requests are not allowed to overlap'));
            }

            try {
                insert new List<Leave__c>{l2, l3};
            } catch (Exception e) {
                System.assert(e.getMessage().contains('requests are not allowed to overlap'));
            }
            UserTriggerHandler.otherTestsRunning = false;
            EmployeeLeaveYearTriggerHandler.otherTestsRunning = false;
        }
    }

    //Checks that delegated approver is set as the approver for a user without a manager
    @isTest static void testInsertWithDelegatedApprover() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {

            Date yearStart = Date.newInstance(2014,1,1);//1.3+
            Date yearEnd = Date.newInstance(2014,12,31);//1.3+

            //Disable sharing calculations since they don't matter in this test
            UserTriggerHandler.otherTestsRunning = true;
            EmployeeLeaveYearTriggerHandler.otherTestsRunning = true;
            UserTestHelper.setupOrgSettings();

            User u = UserTestHelper.createStandardUsers(1, 'Flash', 'Gordon')[0];
            User approver = UserTestHelper.createStandardUsers(1, 'Ron', 'Moore')[0];
            u.DelegatedApproverId = approver.Id;
            update u;
            
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year 8',Employee__c=u.Id, Year__c = '2014',StartDate__c=yearStart,EndDate__c=yearEnd);//1.3+
            insert leaveYear;

            Date start = Date.newInstance(2014, 09, 09);
            Leave__c l = new Leave__c(Employee__c=u.Id, StartDate__c=start, EndDate__c=start.addDays(2),
                    Status__c='Approved', EmployeeLeaveYear__c=leaveYear.Id);
            insert l;
            
            Leave__c queriedLeave = [SELECT Id, Approver__c, ManagerId__c FROM Leave__c WHERE Id =: l.Id];
            System.assertNotEquals(queriedLeave.ManagerId__c, approver.Id);
            System.assertEquals(queriedLeave.Approver__c, approver.Id);

            UserTriggerHandler.otherTestsRunning = false;
            EmployeeLeaveYearTriggerHandler.otherTestsRunning = false;
        }
    }

    //1.2+
    //This method validates that public holiday (PublicHoliday__c) is excluded from the employees Holiday's consumption provided the user is in the corresponding PublicHolidayGroup__c
    @isTest static void testDaysCalculationWithPublicHolidays() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            //Disable sharing calculations since they don't matter in this test
            UserTriggerHandler.otherTestsRunning = true;
            EmployeeLeaveYearTriggerHandler.otherTestsRunning = true;
            UserTestHelper.setupOrgSettings();

            User u = UserTestHelper.createStandardUsers(1, 'Flash', 'Gordon')[0];//No employee work pattern

            //Create 2 Public Holiday Groups each with 2 days public Holidays this week
            Date startOfWorkWeek = Date.newInstance(system.today().year(), system.today().month(), system.today().day()).toStartOfWeek();//Monday
            Date endOfWorkWeek = startOfWorkWeek+4;//Friday

            List<PublicHolidayGroup__c> phgs = CalendarTestHelper.createPublicHolidayGroupsWithHoliday(2,2,startOfWorkWeek,endOfWorkWeek);

            Id groupAssignedToUser = phgs[0].Id;
            
            EmployeeLeaveYear__c leaveYear = CalendarTestHelper.createEmployeeLeaveYears(new Set<Id>{u.Id},system.today().addDays(-100),system.today().addDays(100),groupAssignedToUser,true)[0];//Create the Employee Leave Years via the Globalised solution

            //Log leave for the current week
            Leave__c l = new Leave__c(Employee__c=u.Id, StartDate__c=startOfWorkWeek, EndDate__c=endOfWorkWeek,
                    Status__c='Approved', EmployeeLeaveYear__c=leaveYear.Id);
            
            test.startTest();
                insert l;
                
                //Expect Only 3 days holiday consumed (5 days minus public holidays)
                system.assertEquals(3, [Select Id,NumberOfHolidays__c From Leave__c Where Id = :l.Id].NumberOfHolidays__c);

                //Delete 1 Public Holiday for alternative group and confirm no change
                delete [Select Id From PublicHoliday__c Where PublicHolidayGroup__c != :groupAssignedToUser Limit 1];
                l.HR_Comments__c = 'Recalculating Dates';
                update l;//<--Retrigger calc
                system.assertEquals(3, [Select Id,NumberOfHolidays__c From Leave__c Where Id = :l.Id].NumberOfHolidays__c);

                //Delete 1 Public Holiday for relevant group and confirm holiday is incremented
                delete [Select Id From PublicHoliday__c Where PublicHolidayGroup__c = :groupAssignedToUser Limit 1];
                l.HR_Comments__c = 'Recalculating Dates Once More';
                LeaveTriggerHandler.firstBeforeUpdateRun = true;//Reset recursive flags (simulate first update)
                LeaveTriggerHandler.firstAfterUpdateRun = true;
                update l;//<--Retrigger calc
                system.assertEquals(4, [Select Id,NumberOfHolidays__c From Leave__c Where Id = :l.Id].NumberOfHolidays__c);

            test.stopTest();

            UserTriggerHandler.otherTestsRunning = false;
            EmployeeLeaveYearTriggerHandler.otherTestsRunning = false;
        }
    }
    

}