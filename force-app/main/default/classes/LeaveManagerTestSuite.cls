/*
Name:  LeaveManagerTestSuite.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Suite of unit tests that exercise (and verify)  LeaveManager class

Future enhancements:

======================================================
======================================================
History
------- 
Ver. Author                               Date                Detail
1.0  Örn Ingvar Ásbjörnsson     2014-07-25    Initial development.
1.1  Örn Ingvar Ásbjörnsson     2014-07-29    More detailed assertions
1.2  Örn Ingvar Ásbjörnsson     2015-05-15    Added a test for holidays on weekends
1.3  J Radcliffe                2020-01-27    Substantial changes to existing methods to replace references to 'Holiday' with 'Public Holiday'
1.4  J Radcliffe                2020-01-28    Start and End Dates are now required for the Employee Leave Year records
*/
@isTest
private class LeaveManagerTestSuite {
    
    /*
    ======================================================
    ======================================================
    LeaveManager Tests
    ======================================================
    ======================================================
    */
    @isTest static void testGetLeaveType() {
        System.assert(LeaveManager.getLeaveType().size()>0);
    }
    
    @isTest static void testGetLeaveByUserId() {
        List<Leave__c> leaveList = LeaveManager.getLeaveByUserId(LeaveManagerTestSuite.getUserIdsWithLeaves());
        System.assertEquals(leaveList.size(), 20);
    }
    
    @isTest static void testGetPendingLeaveByUserId() {
        List<Leave__c> leaveList = LeaveManager.getPendingLeaveByUserId(LeaveManagerTestSuite.getUserIdsWithLeaves());
        System.assertEquals(leaveList.size(), 0);
    }

    @isTest static void testGetLeaveByUserIdAndYear() {
        List<Leave__c> leaveList = LeaveManager.getLeaveByUserIdAndYear(LeaveManagerTestSuite.getUserIdsWithLeaves(), '2014');
        System.assertEquals(leaveList.size(), 20);
    }

    @isTest static void testGetLeaveByUserIdAndMonth() {
        List<Leave__c> leaveList = LeaveManager.getLeaveByUserIdAndMonth(LeaveManagerTestSuite.getUserIdsWithLeaves(), 2014, 08, false);
        System.assertEquals(leaveList.size(), 20);
    }

    @isTest static void testGetLeavesForToday() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {

            Date yearStart = Date.newInstance(System.today().year(), 1, 1);//1.4+
            Date yearEnd = Date.newInstance(System.today().year(), 12, 31);//1.4+

            //Need to create a leave that is set for today to be able to test this properly
            User u = UserTestHelper.createStandardUsers(1, 'Flash', 'Gordon')[0];
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year',Employee__c=u.Id, Year__c = String.valueOf(System.today().year()),StartDate__c=yearStart, EndDate__c=yearEnd);//1.4~
            insert leaveYear;
            Leave__c l = new Leave__c(Employee__c=u.Id, StartDate__c=System.today(), EndDate__c=System.today().addDays(2),
                    Status__c='approved', EmployeeLeaveYear__c=leaveYear.Id);
            insert l;
            List<Leave__c> leaveList = LeaveManager.getLeavesForToday();
            System.assertEquals(leaveList.size(), 1);
        }
    }

    @isTest static void testGetUsersWithApprovedLeaveThisMonth() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            EmployeeLeaveTestHelper.createUsersWithLeaves(10);
            Set<Id> userIdSet = LeaveManager.getUsersWithApprovedLeaveThisMonth(2014, 08);
            System.assertEquals(userIdSet.size(), 10);
        }
    }

    @isTest static void testInsertLeaveRequest() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            //Call the helper since that inserts an Employee Leave Year for the created users
            User u = EmployeeLeaveTestHelper.createUsersWithLeaves(1)[0];
            EmployeeLeaveYear__c leaveYear = [SELECT Id FROM EmployeeLeaveYear__c WHERE Employee__c =: u.Id AND Year__c = '2014'];

            //Create a record that should be inserted without error
            Leave__c l = new Leave__c(
                Employee__c=u.Id,
                EmployeeLeaveYear__c=leaveYear.Id, 
                StartDate__c=Date.newInstance(2014,08,01),
                EndDate__c=Date.newInstance(2014,08,03)
                );
            System.AssertEquals('success', LeaveManager.insertLeaveRequest(l));

            //Create a record without an Employee Leave which should make the function return a failure
            Leave__c l2 = new Leave__c(
                Employee__c=u.Id,
                StartDate__c=Date.newInstance( 2014, 08, 01 ),
                EndDate__c=Date.newInstance( 2014, 08, 03 )
                );
            System.Assert(LeaveManager.insertLeaveRequest(l2).contains('failed'));
        }
    }

    //Do a test where an employee with a mon-fri working pattern asks for a three day request where one day falls on a holiday
    @isTest static void testCalculateNumberOfDaysOfLeave() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {

            //Create Public Holiday Group with Holiday //1.3+
            Date testHoliday = Date.newInstance(2014, 08, 04);
            PublicHolidayGroup__c phg = CalendarTestHelper.createPublicHolidayGroupsWithHoliday(1,1,testHoliday, testHoliday)[0];

            Date startDate = Date.newInstance(2014, 01, 01);
            Date endDate = Date.newInstance(2014, 12, 31);

            User u = UserTestHelper.createStandardUsers(1, 'Roy', 'Rogers')[0];
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year 1',Employee__c=u.Id, Year__c = '2014',StartDate__c=startDate, EndDate__c=endDate,PublicHolidayGroup__c=phg.Id);// SD, ED & PHG1.3~
            insert leaveYear;

            User approver = UserTestHelper.createStandardUsers(1, 'Arby', 'Dox')[0];
            //Create a working pattern for employee
            EmployeeWorkingPattern__c wp = CalendarTestHelper.createWorkingPattern(u, true, true, true, true, true, false, false, startDate, endDate);
            //Create the leave
            Leave__c l = CalendarTestHelper.createLeave(leaveYear, u, approver, Date.newInstance(2014,08,04), Date.newInstance(2014,08,06), true, true, 
                true, 'Waiting for approval');
            
            List<EmployeeWorkingPattern__c> workPatternList = new List<EmployeeWorkingPattern__c>{wp};
            Map<Id, List<EmployeeWorkingPattern__c>> patternMap = new Map<Id, List<EmployeeWorkingPattern__c>>();
            patternMap.put(u.Id, workPatternList);

            /*Date testHoliday = Date.newInstance(2014, 08, 04);
            Holiday holiday = new Holiday();
            holiday.Name = 'Holiday';
            holiday.ActivityDate = testHoliday;
            holiday.IsAllDay = true;
            insert holiday;

            Map<Date, List<Holiday>> holidayMap = new Map<Date, List<Holiday>>();
            holidayMap.put(testHoliday, new List<Holiday>{holiday});*/

            Map<Id,Map<Date,PublicHoliday__c>> holidayMap = CalendarHelper.getAgentsPublicHolidayBetweenDates(Date.newInstance(2014,08,04),Date.newInstance(2014,08,06), new Set<Id>{u.Id});//1.3+
            system.assertEquals(1, holidayMap.size());//1.3+
            system.assertEquals(true, holidayMap.containsKey(u.Id));//1.3+
            system.assertEquals(phg.PublicHolidays__r[0].Id, holidayMap.get(u.Id).get(testHoliday).Id);//1.3+
            
            Decimal noOfDays = LeaveManager.calculateNumberOfDaysOfLeave(l, patternMap, holidayMap.get(l.Employee__c));//1.3+

            //Decimal noOfDays = LeaveManager.calculateNumberOfDaysOfLeave(l, patternMap, holidayMap);//1.3-
            System.assertEquals(noOfDays, 2.0);
        }
    }

    //Do a test for an employee without a working pattern (resorts to default mon-fri days)
    @isTest static void testCalculateNumberOfDaysOfLeave1() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {

            //Create Public Holiday Group with Holiday //1.3+
            Date testHoliday = Date.newInstance(2014, 08, 04);
            PublicHolidayGroup__c phg = CalendarTestHelper.createPublicHolidayGroupsWithHoliday(1,1,testHoliday, testHoliday)[0];

            Date startDate = Date.newInstance(2014, 01, 01);
            Date endDate = Date.newInstance(2014, 12, 31);
            User u = UserTestHelper.createStandardUsers(1, 'Roy', 'Rogers')[0];
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year 2',Employee__c=u.Id, Year__c = '2014',StartDate__c=startDate, EndDate__c=endDate,PublicHolidayGroup__c=phg.Id);// SD, ED & PHG1.3~
            insert leaveYear;

            User approver = UserTestHelper.createStandardUsers(1, 'Arby', 'Dox')[0];
            Leave__c l = CalendarTestHelper.createLeave(leaveYear, u, approver, Date.newInstance(2014,08,01), Date.newInstance(2014,08,06), true, true, 
                true, 'Waiting for approval');
            
            List<EmployeeWorkingPattern__c> workPatternList = new List<EmployeeWorkingPattern__c>{};
            Map<Id, List<EmployeeWorkingPattern__c>> patternMap = new Map<Id, List<EmployeeWorkingPattern__c>>();
            patternMap.put(null, workPatternList);

            /*Holiday holiday = new Holiday();
            holiday.Name = 'Holiday';
            holiday.ActivityDate = Date.newInstance(2014, 08, 04);
            insert holiday;

            Map<Date, List<Holiday>> holidayMap = new Map<Date, List<Holiday>>();
            holidayMap.put(startDate, new List<Holiday>{holiday});*/

            Map<Id,Map<Date,PublicHoliday__c>> holidayMap = CalendarHelper.getAgentsPublicHolidayBetweenDates(Date.newInstance(2014,08,01),Date.newInstance(2014,08,06), new Set<Id>{u.Id});//1.3+
            system.assertEquals(1, holidayMap.size());//1.3+
            system.assertEquals(true, holidayMap.containsKey(u.Id));//1.3+
            system.assertEquals(phg.PublicHolidays__r[0].Id, holidayMap.get(u.Id).get(testHoliday).Id);//1.3+
            
            Decimal noOfDays = LeaveManager.calculateNumberOfDaysOfLeave(l, patternMap, holidayMap.get(l.Employee__c));//1.3+

            //Decimal noOfDays = LeaveManager.calculateNumberOfDaysOfLeave(l, patternMap, holidayMap);//1.3-
            System.assertEquals(noOfDays, 3.0);
        }
    }

    //Do a test where two leave requests are created on the same day and one is authorised work form home which should not
    // be deducted from leave days.
    @isTest static void testCalculateNumberOfDaysOfLeave2() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {

            //Create Public Holiday Group with Holiday //1.3+
            Date testHoliday = Date.newInstance(2014, 12, 25);
            PublicHolidayGroup__c phg = CalendarTestHelper.createPublicHolidayGroupsWithHoliday(1,1,testHoliday, testHoliday)[0];

            Date startDate = Date.newInstance(2014, 01, 01);
            Date endDate = Date.newInstance(2014, 12, 31);
            User u = UserTestHelper.createStandardUsers(1, 'Roy', 'Rogers')[0];
            //EmployeeLeaveYear__c leaveYear = CalendarTestHelper.createEmployeeLeaveYear(u);//1.3-
            EmployeeLeaveYear__c leaveYear = CalendarTestHelper.createEmployeeLeaveYears(new Set<Id>{u.Id}, startDate, endDate, phg.Id, true)[0];//1.3+
            
            //Create a working pattern for employee
            EmployeeWorkingPattern__c wp = CalendarTestHelper.createWorkingPattern(u, true, true, true, true, true, false, false, startDate, endDate);

            User approver = UserTestHelper.createStandardUsers(1, 'Arby', 'Dox')[0];
            Leave__c l = CalendarTestHelper.createLeave(leaveYear, u, approver, Date.newInstance(2014,08,04), Date.newInstance(2014,08,04), true, false, 
                true, 'Waiting for approval', 'Authorised');

            Leave__c l2 = CalendarTestHelper.createLeave(leaveYear, u, approver, Date.newInstance(2014,08,04), Date.newInstance(2014,08,04), false, true, 
                false, 'Waiting for approval');
            
            List<EmployeeWorkingPattern__c> workPatternList = new List<EmployeeWorkingPattern__c>{wp};
            Map<Id, List<EmployeeWorkingPattern__c>> patternMap = new Map<Id, List<EmployeeWorkingPattern__c>>();
            patternMap.put(u.Id, workPatternList);

            /*Holiday holiday = new Holiday();
            holiday.Name = 'Holiday';
            holiday.ActivityDate = Date.newInstance(2014, 12, 25);
            insert holiday;

            Map<Date, List<Holiday>> holidayMap = new Map<Date, List<Holiday>>();
            holidayMap.put(startDate, new List<Holiday>{holiday});*/

            Map<Id,Map<Date,PublicHoliday__c>> holidayMap = CalendarHelper.getAgentsPublicHolidayBetweenDates(Date.newInstance(2014,08,04),Date.newInstance(2014,08,04), new Set<Id>{u.Id});//1.3+

            //Decimal lnoOfDays = LeaveManager.calculateNumberOfDaysOfLeave(l, patternMap, holidayMap);//1.3-
            Decimal lnoOfDays = LeaveManager.calculateNumberOfDaysOfLeave(l, patternMap, holidayMap.get(l.Employee__c));//1.3+
            System.assertEquals(lnoOfDays, 0.0);
            //Decimal l2noOfDays = LeaveManager.calculateNumberOfDaysOfLeave(l2, patternMap, holidayMap);//1.3-
            Decimal l2noOfDays = LeaveManager.calculateNumberOfDaysOfLeave(l2, patternMap, holidayMap.get(l2.Employee__c));//1.3+
            System.assertEquals(l2noOfDays, 0.5);

            //Update to trigger the leave year calculations
            l.Status__c = 'Approved';
            l.HR_Comments__c = 'Done';
            l.NumberOfHolidays__c = lnoOfDays;
            l2.Status__c = 'Approved';
            l2.HR_Comments__c = 'Done';
            l2.NumberOfHolidays__c = l2noOfDays;
            update new List<Leave__c>{l, l2};

            EmployeeLeaveYear__c queriedLeaveYear = [SELECT Id, HolidaysRemaining__c FROM EmployeeLeaveYear__c WHERE ID =: leaveYear.Id];
            System.assertEquals(queriedLeaveYear.HolidaysRemaining__c, 23.5);
        }
    }

    //Do a test for an employee without a working pattern for a longer period
    @isTest static void testCalculateNumberOfDaysOfLeave3() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {

            //Create Public Holiday Group with Holiday //1.3+
            Date testHoliday = Date.newInstance(2014, 08, 04);
            PublicHolidayGroup__c phg = CalendarTestHelper.createPublicHolidayGroupsWithHoliday(1,1,testHoliday, testHoliday)[0];

            Date startDate = Date.newInstance(2014, 01, 01);
            Date endDate = Date.newInstance(2014, 12, 31);
            User u = UserTestHelper.createStandardUsers(1, 'Roy', 'Rogers')[0];
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year 3',Employee__c=u.Id, Year__c = '2014',StartDate__c=startDate, EndDate__c=endDate,PublicHolidayGroup__c=phg.Id);// SD, ED & PHG 1.3~
            insert leaveYear;
            

            User approver = UserTestHelper.createStandardUsers(1, 'Arby', 'Dox')[0];
            Leave__c l = CalendarTestHelper.createLeave(leaveYear, u, approver, Date.newInstance(2014,08,01), Date.newInstance(2014,08,16), true, true, 
                true, 'Waiting for approval');
            
            List<EmployeeWorkingPattern__c> workPatternList = new List<EmployeeWorkingPattern__c>{};
            Map<Id, List<EmployeeWorkingPattern__c>> patternMap = new Map<Id, List<EmployeeWorkingPattern__c>>();
            patternMap.put(null, workPatternList);

            /*Holiday holiday = new Holiday();
            holiday.Name = 'Holiday';
            holiday.ActivityDate = Date.newInstance(2014, 08, 04);
            insert holiday;

            Map<Date, List<Holiday>> holidayMap = new Map<Date, List<Holiday>>();
            holidayMap.put(startDate, new List<Holiday>{holiday});*/

            Map<Id,Map<Date,PublicHoliday__c>> holidayMap = CalendarHelper.getAgentsPublicHolidayBetweenDates(Date.newInstance(2014,08,01), Date.newInstance(2014,08,16), new Set<Id>{u.Id});//1.3+
            system.assertEquals(1, holidayMap.size());//1.3+
            system.assertEquals(true, holidayMap.containsKey(u.Id));//1.3+
            system.assertEquals(phg.PublicHolidays__r[0].Id, holidayMap.get(u.Id).get(testHoliday).Id);//1.3+
            
            Decimal noOfDays = LeaveManager.calculateNumberOfDaysOfLeave(l, patternMap, holidayMap.get(l.Employee__c));//1.3+

            //Decimal noOfDays = LeaveManager.calculateNumberOfDaysOfLeave(l, patternMap, holidayMap);//1.3-
            System.assertEquals(noOfDays, 10.0);
        }
    }

    //Test half day calculations where PMStart and PMEnd are checked 
    @IsTest static void testCalculateNumberOfDaysOfLeave4() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {

            //Create Public Holiday Group with Holiday //1.3+
            Date testHoliday = Date.newInstance(2014, 08, 04);
            PublicHolidayGroup__c phg = CalendarTestHelper.createPublicHolidayGroupsWithHoliday(1,0,null, null)[0];

            User u = UserTestHelper.createStandardUsers(1, 'Roy', 'Rogers')[0];
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year 4',Employee__c=u.Id, Year__c = '2014',StartDate__c=Date.newInstance(2014,1,1), EndDate__c=Date.newInstance(2014,12,31),PublicHolidayGroup__c=phg.Id);// SD, ED & PHG 1.3~
            insert leaveYear;
            
            User approver = UserTestHelper.createStandardUsers(1, 'Arby', 'Dox')[0];
            Leave__c l = CalendarTestHelper.createLeave(leaveYear, u, approver, 
                Date.newInstance(2014,09,01), Date.newInstance(2014,09,01), 
                false, true, true, 'Waiting for approval');
            
            //Leave the pattern empty
            List<EmployeeWorkingPattern__c> workPatternList = new List<EmployeeWorkingPattern__c>();
            Map<Id, List<EmployeeWorkingPattern__c>> patternMap = new Map<Id, List<EmployeeWorkingPattern__c>>();
            patternMap.put(null, workPatternList);

            //Add no holiday
            /*Map<Date, List<Holiday>> holidayMap = new Map<Date, List<Holiday>>();
            holidayMap.put(null, new List<Holiday>());*/

            Map<Id,Map<Date,PublicHoliday__c>> holidayMap = CalendarHelper.getAgentsPublicHolidayBetweenDates(Date.newInstance(2014,09,01),Date.newInstance(2014,09,01), new Set<Id>{u.Id});//1.3+
            system.assertEquals(0, holidayMap.keySet().size());

            Decimal noOfDays = LeaveManager.calculateNumberOfDaysOfLeave(l, patternMap, new Map<Date,PublicHoliday__c>());
            System.assertEquals(noOfDays, 0.5);

            //Test leave that does not have same start and end date
            Leave__c l1 = CalendarTestHelper.createLeave(leaveYear, u, approver, 
                Date.newInstance(2014,09,01), Date.newInstance(2014,09,02), 
                false, true, true, 'Waiting for approval');

            Decimal noOfDays1 = LeaveManager.calculateNumberOfDaysOfLeave(l1, patternMap, new Map<Date,PublicHoliday__c>());
            System.assertEquals(noOfDays1, 1.5);

            /*
            Date dec24 = Date.newInstance(2014, 12, 24);
            //Create a half day holiday on december 24
            Holiday holiday = new Holiday();
            holiday.Name = 'Holiday';
            holiday.ActivityDate = dec24;
            holiday.IsAllDay = false;
            holiday.StartTimeInMinutes = 720;
            holiday.EndTimeInMinutes = 1020;
            insert holiday;

            Map<Date, List<Holiday>> holidayMap1 = new Map<Date, List<Holiday>>();
            holidayMap1.put(dec24, new List<Holiday>{holiday});*/

            PublicHoliday__c ph = new PublicHoliday__c(Date__c=Date.newInstance(2014,12,24),IsAllDay__c=false,PublicHolidayGroup__c=phg.Id);
            insert ph;

            holidayMap = CalendarHelper.getAgentsPublicHolidayBetweenDates(Date.newInstance(2014,12,24),Date.newInstance(2014,12,24), new Set<Id>{u.Id});//1.3+
            system.assertEquals(1, holidayMap.size());//1.3+
            system.assertEquals(true, holidayMap.containsKey(u.Id));//1.3+
            system.assertEquals(0,phg.PublicHolidays__r.size());//1.3+
            
            //Test leave that does not have same start and end date
            Leave__c l2 = CalendarTestHelper.createLeave(leaveYear, u, approver, 
                Date.newInstance(2014,12,19), Date.newInstance(2014,12,24), 
                false, true, true, 'Waiting for approval');

            Decimal noOfDays2 = LeaveManager.calculateNumberOfDaysOfLeave(l2, patternMap, holidayMap.get(u.Id));
            System.assertEquals(noOfDays2, 3.5);

            //Test leave that does not have same start and end date
            Leave__c l3 = CalendarTestHelper.createLeave(leaveYear, u, approver, 
                Date.newInstance(2014,12,12), Date.newInstance(2014,12,24), 
                false, true, true, 'Waiting for approval');

            Decimal noOfDays3 = LeaveManager.calculateNumberOfDaysOfLeave(l3, patternMap, holidayMap.get(u.Id));
            System.assertEquals(noOfDays3, 8.5);

            //Test leave that does not have same start and end date
            Leave__c l4 = CalendarTestHelper.createLeave(leaveYear, u, approver, 
                Date.newInstance(2014,12,22), Date.newInstance(2014,12,24), 
                false, true, true, 'Waiting for approval');

            Decimal noOfDays4 = LeaveManager.calculateNumberOfDaysOfLeave(l4, patternMap, holidayMap.get(u.Id));
            System.assertEquals(noOfDays4, 2.5);

            //Test leave that does not have same start and end date
            Leave__c l5 = CalendarTestHelper.createLeave(leaveYear, u, approver, 
                Date.newInstance(2014,03,10), Date.newInstance(2014,03,13), 
                false, true, true, 'Waiting for approval');

            Decimal noOfDays5 = LeaveManager.calculateNumberOfDaysOfLeave(l5, patternMap, holidayMap.get(u.Id));
            System.assertEquals(noOfDays5, 3.5);
        }
    }

    //Test half day calculations where AM is false, PMStart true and PMEnd false
    @IsTest static void testCalculateNumberOfDaysOfLeave5() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            
            Date yearStart = Date.newInstance(2014, 1, 1);//1.4+
            Date yearEnd = Date.newInstance(2014, 12, 31);//1.4+

            User u = UserTestHelper.createStandardUsers(1, 'Roy', 'Rogers')[0];
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year 5',Employee__c=u.Id, Year__c = '2014',StartDate__c=yearStart, EndDate__c=yearEnd);//1.4~
            insert leaveYear;

            User approver = UserTestHelper.createStandardUsers(1, 'Arby', 'Dox')[0];
            Leave__c l = CalendarTestHelper.createLeave(leaveYear, u, approver, Date.newInstance(2014,09,01), Date.newInstance(2014,09,01), false, true, 
                false, 'Waiting for approval');
            
            //Leave the pattern empty
            List<EmployeeWorkingPattern__c> workPatternList = new List<EmployeeWorkingPattern__c>();
            Map<Id, List<EmployeeWorkingPattern__c>> patternMap = new Map<Id, List<EmployeeWorkingPattern__c>>();
            patternMap.put(null, workPatternList);

            //Add no holiday
            /*Map<Date, List<Holiday>> holidayMap = new Map<Date, List<Holiday>>(); //1.3-
            holidayMap.put(null, new List<Holiday>());*/
            Map<Date, PublicHoliday__c> holidayMap = new Map<Date, PublicHoliday__c>();//1.3+

            Decimal noOfDays = LeaveManager.calculateNumberOfDaysOfLeave(l, patternMap, holidayMap);
            System.assertEquals(noOfDays, 0.5);

            //Test leave that does not have same start and end date
            Leave__c l1 = CalendarTestHelper.createLeave(leaveYear, u, approver, Date.newInstance(2014,09,01), Date.newInstance(2014,09,02), false, true, 
                false, 'Waiting for approval');

            Decimal noOfDays1 = LeaveManager.calculateNumberOfDaysOfLeave(l1, patternMap, holidayMap);
            System.assertEquals(noOfDays1, 1.0);
        }
    }

    //Test half day calculations where AM is true, PMStart false and PMEnd false
    @IsTest static void testCalculateNumberOfDaysOfLeave6() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {

            Date yearStart = Date.newInstance(2014, 1, 1);//1.4+
            Date yearEnd = Date.newInstance(2014, 12, 31);//1.4+

            User u = UserTestHelper.createStandardUsers(1, 'Roy', 'Rogers')[0];
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year 6',Employee__c=u.Id, Year__c = '2014',StartDate__c=yearStart, EndDate__c=yearEnd);//1.4~
            insert leaveYear;

            User approver = UserTestHelper.createStandardUsers(1, 'Arby', 'Dox')[0];
            Leave__c l = CalendarTestHelper.createLeave(leaveYear, u, approver, 
                Date.newInstance(2014,09,01), Date.newInstance(2014,09,01), true, false, false, 'Waiting for approval');
            
            //Leave the pattern empty
            List<EmployeeWorkingPattern__c> workPatternList = new List<EmployeeWorkingPattern__c>();
            Map<Id, List<EmployeeWorkingPattern__c>> patternMap = new Map<Id, List<EmployeeWorkingPattern__c>>();
            patternMap.put(null, workPatternList);

            //Add no holiday
            /*Map<Date, List<Holiday>> holidayMap = new Map<Date, List<Holiday>>(); //1.3-
            holidayMap.put(null, new List<Holiday>());*/
            Map<Date, PublicHoliday__c> holidayMap = new Map<Date, PublicHoliday__c>();//1.3+

            Decimal noOfDays = LeaveManager.calculateNumberOfDaysOfLeave(l, patternMap, holidayMap);
            System.assertEquals(noOfDays, 0.5);

            //Test leave that does not have same start and end date
            Leave__c l1 = CalendarTestHelper.createLeave(leaveYear, u, approver, 
                Date.newInstance(2014,09,01), Date.newInstance(2014,09,02), true, false, false, 'Waiting for approval');

            Decimal noOfDays1 = LeaveManager.calculateNumberOfDaysOfLeave(l1, patternMap, holidayMap);
            System.assertEquals(noOfDays1, 1.0);
        }
    }

    //Test half day calculations where AM is true, PMStart false and PMEnd false
    @IsTest static void testCalculateNumberOfDaysOfLeave7() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            Date yearStart = Date.newInstance(2014, 1, 1);//1.4+
            Date yearEnd = Date.newInstance(2014, 12, 31);//1.4+

            User u = UserTestHelper.createStandardUsers(1, 'Roy', 'Rogers')[0];
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year 7',Employee__c=u.Id, Year__c = '2014',StartDate__c=yearStart, EndDate__c=yearEnd);//1.4~
            insert leaveYear;

            User approver = UserTestHelper.createStandardUsers(1, 'Arby', 'Dox')[0];
            Leave__c l = CalendarTestHelper.createLeave(leaveYear, u, approver, 
                Date.newInstance(2014,09,01), Date.newInstance(2014,09,01), true, false, true, 'Waiting for approval');
            
            //Leave the pattern empty
            List<EmployeeWorkingPattern__c> workPatternList = new List<EmployeeWorkingPattern__c>();
            Map<Id, List<EmployeeWorkingPattern__c>> patternMap = new Map<Id, List<EmployeeWorkingPattern__c>>();
            patternMap.put(null, workPatternList);

            //Add no holiday
            /*Map<Date, List<Holiday>> holidayMap = new Map<Date, List<Holiday>>(); //1.3-
            holidayMap.put(null, new List<Holiday>());*/
            Map<Date, PublicHoliday__c> holidayMap = new Map<Date, PublicHoliday__c>();//1.3+

            Decimal noOfDays = LeaveManager.calculateNumberOfDaysOfLeave(l, patternMap, holidayMap);
            System.assertEquals(noOfDays, 0.5);

            //Test leave that does not have same start and end date
            Leave__c l1 = CalendarTestHelper.createLeave(leaveYear, u, approver, 
                Date.newInstance(2014,09,01), Date.newInstance(2014,09,02), true, false, true, 'Waiting for approval');

            Decimal noOfDays1 = LeaveManager.calculateNumberOfDaysOfLeave(l1, patternMap, holidayMap);
            System.assertEquals(noOfDays1, 1.5);
        }
    }

    //Test that recurring holidays landing on a weekend are reduced like normal weekend days
    @IsTest static void testCalculateNumberOfDaysOfLeave8() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {

            //Create Public Holiday Group with Holiday //1.3+
            PublicHolidayGroup__c phg = CalendarTestHelper.createPublicHolidayGroupsWithHoliday(1,0,null, null)[0];

            User u = UserTestHelper.createStandardUsers(1, 'Roy', 'Rogers')[0];
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year 8',Employee__c=u.Id, Year__c = '2015',StartDate__c=Date.newInstance(2015,1,1), EndDate__c=Date.newInstance(2015,12,31),PublicHolidayGroup__c=phg.Id);// SD, ED & PHG 1.3~
            insert leaveYear;

            User approver = UserTestHelper.createStandardUsers(1, 'Arby', 'Dox')[0];
            Leave__c l = CalendarTestHelper.createLeave(leaveYear, u, approver, 
                Date.newInstance(2015,12,24), Date.newInstance(2015,12,31), true, true, true, 'Waiting for approval');
            
            //Leave the pattern empty
            List<EmployeeWorkingPattern__c> workPatternList = new List<EmployeeWorkingPattern__c>();
            Map<Id, List<EmployeeWorkingPattern__c>> patternMap = new Map<Id, List<EmployeeWorkingPattern__c>>();
            patternMap.put(null, workPatternList);

            List<PublicHoliday__c> phs = new List<PublicHoliday__c>();//1.3+
            phs.add(new PublicHoliday__c(PublicHolidayGroup__c=phg.Id,Date__c=Date.newInstance(2015,12,24),IsAllDay__c=false));
            phs.add(new PublicHoliday__c(PublicHolidayGroup__c=phg.Id,Date__c=Date.newInstance(2015,12,25),IsAllDay__c=true));
            phs.add(new PublicHoliday__c(PublicHolidayGroup__c=phg.Id,Date__c=Date.newInstance(2015,12,26),IsAllDay__c=true));
            phs.add(new PublicHoliday__c(PublicHolidayGroup__c=phg.Id,Date__c=Date.newInstance(2015,12,28),IsAllDay__c=true));
            phs.add(new PublicHoliday__c(PublicHolidayGroup__c=phg.Id,Date__c=Date.newInstance(2015,12,31),IsAllDay__c=false));
            insert phs;
            
            
            /*Date dec24 = Date.newInstance(2015, 12, 24);
            Holiday holiday0 = new Holiday();
            holiday0.Name = 'Holiday';
            holiday0.ActivityDate = dec24;
            holiday0.IsAllDay = false;
            holiday0.StartTimeInMinutes = 720;
            holiday0.EndTimeInMinutes = 1020;
            insert holiday0;

            Date dec25 = Date.newInstance(2015, 12, 25);
            Holiday holiday1 = new Holiday();
            holiday1.Name = 'Holiday';
            holiday1.ActivityDate = dec25;
            holiday1.IsAllDay = true;
            insert holiday1;

            //Add 26 dec, a saturday, as a holiday
            Date dec26 = Date.newInstance(2015, 12, 26);
            Holiday holiday2 = new Holiday();
            holiday2.Name = 'Holiday';
            holiday2.ActivityDate = dec26;
            holiday2.IsAllDay = true;
            insert holiday2;

            Date dec28 = Date.newInstance(2015, 12, 28);
            Holiday holiday3 = new Holiday();
            holiday3.Name = 'Holiday';
            holiday3.ActivityDate = dec28;
            holiday3.IsAllDay = true;
            insert holiday3;

            Date dec31 = Date.newInstance(2015, 12, 31);
            Holiday holiday4 = new Holiday();
            holiday4.Name = 'Holiday';
            holiday4.ActivityDate = dec31;
            holiday4.IsAllDay = false;
            holiday4.StartTimeInMinutes = 720;
            holiday4.EndTimeInMinutes = 1020;
            insert holiday4;

            Map<Date, List<Holiday>> holidayMap = new Map<Date, List<Holiday>>();
            holidayMap.put(dec24, new List<Holiday>{holiday0});
            holidayMap.put(dec25, new List<Holiday>{holiday1});
            holidayMap.put(dec26, new List<Holiday>{holiday2});
            holidayMap.put(dec28, new List<Holiday>{holiday3});
            holidayMap.put(dec31, new List<Holiday>{holiday4});*/

            Map<Id,Map<Date,PublicHoliday__c>> holidayMap = CalendarHelper.getAgentsPublicHolidayBetweenDates(Date.newInstance(2015,12,01), Date.newInstance(2015,12,31), new Set<Id>{u.Id});//1.3+
            system.assertEquals(1, holidayMap.size());//1.3+
            system.assertEquals(true, holidayMap.containsKey(u.Id));//1.3+
            system.assertEquals(5,holidayMap.get(u.Id).values().size());//1.3+

            Decimal noOfDays = LeaveManager.calculateNumberOfDaysOfLeave(l, patternMap, holidayMap.get(u.Id));//1.3~
            System.assertEquals(noOfDays, 3);
        }
    }

    @isTest static void testCalculateNumberOfDaysOfLeaveEndPM() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {

            Date yearStart = Date.newInstance(2014, 1, 1);//1.4+
            Date yearEnd = Date.newInstance(2014, 12, 31);//1.4+

            User u = UserTestHelper.createStandardUsers(1, 'Roy', 'Rogers')[0];
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year 9',Employee__c=u.Id, Year__c = '2014',StartDate__c=yearStart, EndDate__c=yearEnd);//1.4~
            insert leaveYear;

            User approver = UserTestHelper.createStandardUsers(1, 'Arby', 'Dox')[0];
            Leave__c l = CalendarTestHelper.createLeave(leaveYear, u, approver, 
                Date.newInstance(2014,03,04), Date.newInstance(2014,03,05), false, true, false, 'Waiting for approval');
            
            //Leave the pattern empty
            List<EmployeeWorkingPattern__c> workPatternList = new List<EmployeeWorkingPattern__c>();
            Map<Id, List<EmployeeWorkingPattern__c>> patternMap = new Map<Id, List<EmployeeWorkingPattern__c>>();
            patternMap.put(null, workPatternList);

            //Add no holiday
            /*Map<Date, List<Holiday>> holidayMap = new Map<Date, List<Holiday>>(); //1.3-
            holidayMap.put(null, new List<Holiday>());*/
            Map<Date, PublicHoliday__c> holidayMap = new Map<Date, PublicHoliday__c>();//1.3+

            Decimal noOfDays = LeaveManager.calculateNumberOfDaysOfLeave(l, patternMap, holidayMap);
            System.assertEquals(noOfDays, 1.0);

            //Test leave that does not have same start and end date
            Leave__c l1 = CalendarTestHelper.createLeave(leaveYear, u, approver, 
                Date.newInstance(2014,12,08), Date.newInstance(2014,12,09), false, true, false, 'Waiting for approval');

            Decimal noOfDays1 = LeaveManager.calculateNumberOfDaysOfLeave(l1, patternMap, holidayMap);
            System.assertEquals(noOfDays1, 1.0);
        }
    }

    //Test half day calculations on december 24
    @IsTest static void testCalculateNumberOfDaysOfLeaveOnDec24() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {

            //Create Public Holiday Group with Holiday //1.3+
            PublicHolidayGroup__c phg = CalendarTestHelper.createPublicHolidayGroupsWithHoliday(1,0,null, null)[0];

            User u = UserTestHelper.createStandardUsers(1, 'Roy', 'Rogers')[0];
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year 10',Employee__c=u.Id, Year__c = '2014',StartDate__c=Date.newInstance(2014,1,1), EndDate__c=Date.newInstance(2014,12,31),PublicHolidayGroup__c=phg.Id);// SD, ED & PHG 1.3~
            insert leaveYear;

            Date dec24 = Date.newInstance(2014, 12, 24);
            Date dec25 = Date.newInstance(2014, 12, 25);
            Date dec26 = Date.newInstance(2014, 12, 26);
            Date dec31 = Date.newInstance(2014, 12, 31);

            User approver = UserTestHelper.createStandardUsers(1, 'Arby', 'Dox')[0];
            Leave__c l = CalendarTestHelper.createLeave(leaveYear, u, approver, 
                dec24, dec24, true, true, true, 'Waiting for approval');
            
            //Leave the pattern empty
            List<EmployeeWorkingPattern__c> workPatternList = new List<EmployeeWorkingPattern__c>();
            Map<Id, List<EmployeeWorkingPattern__c>> patternMap = new Map<Id, List<EmployeeWorkingPattern__c>>();
            patternMap.put(null, workPatternList);

            

            /*
            Holiday christmasEve = new Holiday();
            christmasEve.Name = 'Christmas Eve 2014';
            christmasEve.ActivityDate = dec24;
            christmasEve.IsAllDay = false;
            christmasEve.StartTimeInMinutes = 720;
            christmasEve.EndTimeInMinutes = 1020;
            insert christmasEve;

            Holiday christmasDay = new Holiday();
            christmasDay.Name = 'Christmas Day';
            christmasDay.isAllDay = true;
            christmasDay.ActivityDate = dec25;
            insert christmasDay;

            Holiday boxingDay = new Holiday();
            boxingDay.Name = 'Boxing Day';
            boxingDay.IsAllDay = true;
            boxingDay.ActivityDate = dec26;
            insert boxingDay;

            Holiday newYearsEve = new Holiday();
            newYearsEve.Name = 'New Years Eve';
            newYearsEve.IsAllDay = false;
            newYearsEve.ActivityDate = dec31;
            newYearsEve.StartTimeInMinutes = 720;
            newYearsEve.EndTimeInMinutes = 1020;
            insert newYearsEve;

            Map<Date, List<Holiday>> holidayMap = new Map<Date, List<Holiday>>();
            holidayMap.put(dec24, new List<Holiday>{christmasEve});
            holidayMap.put(dec25, new List<Holiday>{christmasDay});
            holidayMap.put(dec26, new List<Holiday>{boxingDay});
            holidayMap.put(dec31, new List<Holiday>{newYearsEve});*/

            List<PublicHoliday__c> phs = new List<PublicHoliday__c>();//1.3+
            phs.add(new PublicHoliday__c(PublicHolidayGroup__c=phg.Id,Date__c=Date.newInstance(2014,12,24),IsAllDay__c=false));
            phs.add(new PublicHoliday__c(PublicHolidayGroup__c=phg.Id,Date__c=Date.newInstance(2014,12,25),IsAllDay__c=true));
            phs.add(new PublicHoliday__c(PublicHolidayGroup__c=phg.Id,Date__c=Date.newInstance(2014,12,26),IsAllDay__c=true));
            phs.add(new PublicHoliday__c(PublicHolidayGroup__c=phg.Id,Date__c=Date.newInstance(2014,12,31),IsAllDay__c=false));
            insert phs;

            Map<Id,Map<Date,PublicHoliday__c>> holidayMap = CalendarHelper.getAgentsPublicHolidayBetweenDates(Date.newInstance(2014,12,01), Date.newInstance(2014,12,31), new Set<Id>{u.Id});//1.3+
            system.assertEquals(1, holidayMap.size());//1.3+
            system.assertEquals(true, holidayMap.containsKey(u.Id));//1.3+
            system.assertEquals(4,holidayMap.get(u.Id).values().size());//1.3+

            Decimal noOfDays = LeaveManager.calculateNumberOfDaysOfLeave(l, patternMap, holidayMap.get(l.Employee__c));//1.3~
            System.assertEquals(noOfDays, 0.5);

            //Test leave that does not have same start and end date
            Leave__c l1 = CalendarTestHelper.createLeave(leaveYear, u, approver, 
                Date.newInstance(2014,12,23), dec24, true, true, true, 'Waiting for approval');

            Decimal noOfDays1 = LeaveManager.calculateNumberOfDaysOfLeave(l1, patternMap, holidayMap.get(l.Employee__c));//1.3~
            System.assertEquals(noOfDays1, 1.5);

            //Test leave that does not have same start and end date
            Leave__c l2 = CalendarTestHelper.createLeave(leaveYear, u, approver, 
                dec24, Date.newInstance(2014,12,31), true, true, true, 'Waiting for approval');

            Decimal noOfDays2 = LeaveManager.calculateNumberOfDaysOfLeave(l2, patternMap, holidayMap.get(l.Employee__c));//1.3~
            System.assertEquals(noOfDays2, 3.0);
        }
    }

    @isTest static void testCheckForOverlappingRequests() {
        
        /*
        Record that should overlap:
        User A Leave A - with a start date of 2 March and and end date of the 29 March
        User A Leave B - with a start date of the 1st Feb and an end date of the 28 March
        User B Leave A - with a start date of the 2nd March and an end date of the 28 April
        User B Leave B - with a start date of the 1st Jan and an end date of the 30 April
        User B Leave C - with a start date of 2 March and an end date of the 29 March
        User C Leave A - with a start date of 4 August and an end date of 4 August
        User C Leave B - with a start date of 4 August and an end date of 4 August
        Records that should not overlap:
        User C Leave C - with a start date of 1st May and end date of 11 May
        User C Leave D- with a start date of 15 May and end date of 31 May
        User C Leave E - with a start date of 12 April and end date of 13 April
        User A Leave C - with a start date of 1 January and end date of 5 January
        User A Leave D - with a start date of 4 August (morning) and end date 4 August (noon)
        User A Leave E - with a start date of 4 August (noon) and end date 4 August (afternoon)
        */
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            Date aaStart = Date.newInstance(2014, 3, 2);
            Date aaEnd = Date.newInstance(2014, 3, 29);
            
            Date abStart = Date.newInstance(2014, 2, 1);
            Date abEnd = Date.newInstance(2014, 3, 28);
            
            Date acStart = Date.newInstance(2014, 01, 01);
            Date acEnd = Date.newInstance(2014, 01, 05);

            Date adStart = Date.newInstance(2014, 08, 04);
            Date adEnd = Date.newInstance(2014, 08, 04);

            Date baStart = Date.newInstance(2014, 3, 2);
            Date baEnd = Date.newInstance(2014, 4, 28);
            
            Date bbStart = Date.newInstance(2014, 1, 1);
            Date bbEnd = Date.newInstance(2014, 4, 30);

            Date ccStart = Date.newInstance(2014, 5, 1);
            Date ccEnd = Date.newInstance(2014, 5, 11);
            
            Date cdStart = Date.newInstance(2014, 05, 15);
            Date cdEnd = Date.newInstance(2014, 05, 31);

            Date ceStart = Date.newInstance(2014, 04, 12);
            Date ceEnd = Date.newInstance(2014, 04, 13);

            User userA = UserTestHelper.createStandardUsers(1, 'Buck', 'Rogers')[0];
            User userAApprover = UserTestHelper.createStandardUsers(1, 'Jim', 'Rogers')[0];

            User userB =  UserTestHelper.createStandardUsers(1, 'Roy', 'Rogers')[0];
            User userBApprover =  UserTestHelper.createStandardUsers(1, 'Ben', 'Rogers')[0];

            User userC =  UserTestHelper.createStandardUsers(1, 'Kelis', 'Rogers')[0];
            User userCApprover =  UserTestHelper.createStandardUsers(1, 'Kelly', 'Rogers')[0];

            EmployeeLeaveYear__c userALeaveYear = CalendarTestHelper.createEmployeeLeaveYear(userA);
            EmployeeLeaveYear__c userBLeaveYear = CalendarTestHelper.createEmployeeLeaveYear(userB);
            EmployeeLeaveYear__c userCLeaveYear = CalendarTestHelper.createEmployeeLeaveYear(userC);

            String waitStatus = 'Waiting for approval';
            String leaveType = 'Authorised';

            Leave__c userALeaveA = CalendarTestHelper.createLeave(userALeaveYear, userA, userAApprover, aaStart, aaEnd, waitStatus);
            Leave__c userALeaveB = CalendarTestHelper.createLeave(userALeaveYear, userA, userAApprover, abStart, abEnd, waitStatus);
            Leave__c userALeaveC = CalendarTestHelper.createLeave(userALeaveYear, userA, userAApprover, acStart, acEnd, waitStatus);
            Leave__c userALeaveD = CalendarTestHelper.createLeave(userALeaveYear, userA, userAApprover, adStart, adEnd, true, false, true, waitStatus);
            Leave__c userALeaveE = CalendarTestHelper.createLeave(userALeaveYear, userA, userAApprover, adStart, adEnd, false, true, true, waitStatus);

            Leave__c userBLeaveA = CalendarTestHelper.createLeave(userBLeaveYear, userB, userBApprover, baStart, baEnd, waitStatus);
            Leave__c userBLeaveB = CalendarTestHelper.createLeave(userBLeaveYear, userB, userBApprover, bbStart, bbEnd, waitStatus);
            Leave__c userBLeaveC = CalendarTestHelper.createLeave(userBLeaveYear, userB, userBApprover, aaStart, aaEnd, waitStatus);

            Leave__c userCLeaveA = CalendarTestHelper.createLeave(userCLeaveYear, userC, userCApprover, adStart, adEnd, waitStatus);
            Leave__c userCLeaveB = CalendarTestHelper.createLeave(userCLeaveYear, userC, userCApprover, adStart, adEnd, waitStatus);
            //Create a leave not added to the list of leaves to check so that it is queried by the function
            Leave__c userCLeaveC = CalendarTestHelper.createLeave(userCLeaveYear, userC, userCApprover, ccStart, ccEnd, waitStatus);
            Leave__c userCLeaveD = CalendarTestHelper.createLeave(userALeaveYear, userA, userAApprover, cdStart, cdEnd, true, true, true, waitStatus);
            Leave__c userCLeaveE = CalendarTestHelper.createLeave(userALeaveYear, userA, userAApprover, ceStart, ceEnd, true, true, true, waitStatus);

            List<Leave__c> leaveList = new List<Leave__c>{userALeaveA, userALeaveB, userALeaveC, userALeaveD, userALeaveE, userBLeaveA, userBLeaveB, 
                userBLeaveC, userCLeaveA, userCLeaveB, userCLeaveD, userCLeaveE};
            List<Leave__c> resultList = LeaveManager.checkForOverlappingRequests( leaveList );
            System.assertEquals(resultList.size(), 7);
        }
    }

    @isTest static void testCheckForOverlappingRequests2() {
        /*
        Records that should overlap:
        User A Leave A - with a start date of 2 March and and end date of the 29 March
        User A Leave B - with a start date of the 1st Feb and an end date of the 28 March
        User B Leave A- with a start date of the 2nd March and an end date of the 28 April
        User B Leave B - with a start date of the 1st Jan and an end date of the 30 April
        User B Leave C- with a start date of 2 March and an end date of the 29 March
        Records that should not overlap:
        User A Leave C - with a start date of 1 January and end date of 5 January
        User A Leave D- with a start date of 4 August (morning) and end date 4 August (noon)
        User A Leave E - with a start date of 4 August (noon) and end date 4 August (afternoon)
        */
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            Date aaStart = Date.newInstance(2014, 3, 2);
            Date aaEnd = Date.newInstance(2014, 3, 29);
            
            Date abStart = Date.newInstance(2014, 2, 1);
            Date abEnd = Date.newInstance(2014, 3, 28);
            
            Date acStart = Date.newInstance(2014, 01, 01);
            Date acEnd = Date.newInstance(2014, 01, 05);

            Date adStart = Date.newInstance(2014, 08, 04);
            Date adEnd = Date.newInstance(2014, 08, 04);

            Date baStart = Date.newInstance(2014, 3, 2);
            Date baEnd = Date.newInstance(2014, 4, 28);
            
            Date bbStart = Date.newInstance(2014, 1, 1);
            Date bbEnd = Date.newInstance(2014, 4, 30);

            Date bcStart = Date.newInstance(2014, 3, 2);
            Date bcEnd = Date.newInstance(2014, 3, 29);

            User userA = UserTestHelper.createStandardUsers(1, 'Buck', 'Rogers')[0];
            User userAApprover = UserTestHelper.createStandardUsers(1, 'Jim', 'Rogers')[0];

            User userB =  UserTestHelper.createStandardUsers(1, 'Roy', 'Rogers')[0];
            User userBApprover =  UserTestHelper.createStandardUsers(1, 'Ben', 'Rogers')[0];

            EmployeeLeaveYear__c userALeaveYear = CalendarTestHelper.createEmployeeLeaveYear(userA);
            EmployeeLeaveYear__c userBLeaveYear = CalendarTestHelper.createEmployeeLeaveYear(userB);

            String waitStatus = 'Waiting for approval';
            String leaveType = 'Authorised';

            Leave__c userALeaveA = CalendarTestHelper.createLeave(userALeaveYear, userA, userAApprover, aaStart, aaEnd, waitStatus);
            Leave__c userALeaveB = CalendarTestHelper.createLeave(userALeaveYear, userA, userAApprover, abStart, abEnd, waitStatus);
            Leave__c userALeaveC = CalendarTestHelper.createLeave(userALeaveYear, userA, userAApprover, acStart, acEnd, waitStatus);
            Leave__c userALeaveD = CalendarTestHelper.createLeave(userALeaveYear, userA, userAApprover, adStart, adEnd, true, false, true, waitStatus);
            Leave__c userALeaveE = CalendarTestHelper.createLeave(userALeaveYear, userA, userAApprover, adStart, adEnd, false, true, true, waitStatus);

            Leave__c userBLeaveA = CalendarTestHelper.createLeave(userBLeaveYear, userB, userBApprover, baStart, baEnd, waitStatus);
            Leave__c userBLeaveB = CalendarTestHelper.createLeave(userBLeaveYear, userB, userBApprover, bbStart, bbEnd, waitStatus);
            Leave__c userBLeaveC = CalendarTestHelper.createLeave(userBLeaveYear, userB, userBApprover, bcStart, bcEnd, waitStatus);

            List<Leave__c> leaveList = new List<Leave__c>{ userALeaveA, userALeaveB, userALeaveC, userALeaveD, userALeaveE, userBLeaveA, userBLeaveB, 
                userBLeaveC };

            List<Leave__c> resultList = LeaveManager.checkForOverlappingRequests( leaveList );
            System.assertEquals(resultList.size(), 5);
        }
    }

    @isTest static void testLeaveWrapperClassWithValues() {
        String employeeName = 'Flash Gordon';
        String employeeLeaveYear = '2014';
        String type = 'Type';
        Date startDate = Date.newInstance(2014, 07, 31);
        Date endDate = Date.newInstance(2014, 08, 03);
        Boolean am = false;
        Boolean pmstart = false;
        Boolean pmReturn = false;
        String employeeComment = 'Comment';
        String publicNote = 'Will be away';

        LeaveManager.LeaveWrapper wrapper = new LeaveManager.LeaveWrapper(employeeName, employeeLeaveYear, type, startDate, endDate, am, 
            pmstart, pmReturn, employeeComment, publicNote);
        System.assertEquals(wrapper.employeeName, employeeName);
        System.assertEquals(wrapper.employeeLeaveYear, employeeLeaveYear);
        System.assertEquals(wrapper.type, type);
        System.assertEquals(wrapper.startDate, startDate);
        System.assertEquals(wrapper.endDate, endDate);
        System.assertEquals(wrapper.am, am);
        System.assertEquals(wrapper.pmStart, pmstart);
        System.assertEquals(wrapper.pmReturn, pmReturn);
        System.assertEquals(wrapper.employeeComment, employeeComment);
        System.assertEquals(wrapper.publicNote, publicNote);
    }

    @isTest static void testLeaveWrapperClassWithDefaultValues() {
        LeaveManager.LeaveWrapper wrapper = new LeaveManager.LeaveWrapper();
        System.assertEquals(wrapper.employeeName, '');
        System.assertEquals(wrapper.employeeLeaveYear, '');
        System.assertEquals(wrapper.type, '');
        System.assertEquals(wrapper.startDate, System.today());
        System.assertEquals(wrapper.endDate, System.today());
        System.assertEquals(wrapper.am, true);
        System.assertEquals(wrapper.pmStart, true);
        System.assertEquals(wrapper.pmReturn, true);
        System.assertEquals(wrapper.employeeComment, '');
        System.assertEquals(wrapper.publicNote, '');
    }

    private static Set<Id> getUserIdsWithLeaves() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Set<Id> userIdSet = new Set<Id>();
        System.runAs (thisUser) {
            List<User> userList = EmployeeLeaveTestHelper.createUsersWithLeaves(20);
            for(User u: userList) {
                userIdSet.add(u.Id);
            }
        }
        return userIdSet;
    }

    @isTest static void testLeaveManagerExceptions() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            LeaveManager.isTest = true;
            Set<Id> userIds = LeaveManagerTestSuite.getUserIdsWithLeaves();
            try {
                List<Leave__c> leaveList = LeaveManager.getLeaveByUserId(userIds);
            } catch (Exception e) {
                System.assert(e.getMessage().contains('thrown while testing'));
            } 

            try {
                List<Leave__c> leaveList = LeaveManager.getPendingLeaveByUserId(userIds);
            } catch (Exception e) {
                System.assert(e.getMessage().contains('thrown while testing'));
            }

            try {
                List<Leave__c> leaveList = LeaveManager.getLeaveByUserIdAndYear(userIds, '2014');
            } catch (Exception e) {
                System.assert(e.getMessage().contains('thrown while testing'));
            }

            try {
                List<Leave__c> leaveList = LeaveManager.getLeaveByUserIdAndMonth(userIds, 2014, 08, false);
            } catch (Exception e) {
                System.assert(e.getMessage().contains('thrown while testing'));
            }

            try {
                List<Leave__c> leaveList = LeaveManager.getLeavesForToday();
            } catch (Exception e) {
                System.assert(e.getMessage().contains('thrown while testing'));
            }

            try {
                Set<Id> userIdSet = LeaveManager.getUsersWithApprovedLeaveThisMonth(2014, 08);
            } catch (Exception e) {
                System.assert(e.getMessage().contains('thrown while testing'));
            } 

            try {
                LeaveManager.checkForOverlappingRequests(new List<Leave__c>());
            } catch (Exception e) {
                System.assert(e.getMessage().contains('thrown while testing'));
            }

            LeaveManager.isTest = false;
        }
    }
    
}