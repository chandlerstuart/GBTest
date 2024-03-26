/*
Name:  CalendarTestHelper.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
======================================================
======================================================
History
------- 
Ver. Author                             Date                Detail
1.0  Örn Ingvar Ásbjörnsson   2014-01-27    Initial development. 
1.1  J Radcliffe              2020-01-23    new utility method(s) for creating Public Holiday Data
1.2  J Radcliffe              2020-01-23    new method for creating Employee Leave Years for specified public holiday groups/date ranges/users
1.3  J Radcliffe              2020-01-28    Start and End Date is required for Employee Leave Years
*/
@isTest
public with sharing class CalendarTestHelper {

    /*
        Provides test with a list of User Leave Wrapper
    */
    public static List<UserLeaveWrapper> createUserLeaveWrapper(User u) {
        EmployeeWorkingPattern__c workPattern = createWorkingPattern(u);
        
        //Create an employee leave year record
        EmployeeLeaveYear__c leaveYear = createEmployeeLeaveYear(u,String.valueOf(System.today().year()));//1.3~
        
        //Create a leave record for the user
        Leave__c leave = createLeave(leaveYear, u);

        //Create the user leave wrapper instance
        UserLeaveWrapper userLeaveWrapper = 
            new UserLeaveWrapper(u, new List<EmployeeWorkingPattern__c>{workPattern}, new List<Leave__c>{leave});

        return new List<UserLeaveWrapper>{userLeaveWrapper};
    }
    /* EmployeeWorkingPattern Helpers*/
    public static EmployeeWorkingPattern__c createWorkingPattern(User u) {
        // Create a standard mon-fri working pattern for the user
        return CalendarTestHelper.createWorkingPattern(u, true, true, true, true, true, false, false);
    }

    public static EmployeeWorkingPattern__c createWorkingPattern(User u, Boolean monday, Boolean tuesday, Boolean wednesday, Boolean thursday,
        Boolean friday, Boolean saturday, Boolean sunday) {
        // Create a standard mon-fri working pattern for the user set for one year
        return CalendarTestHelper.createWorkingPattern(u, true, true, true, true, true, false, false, Date.newInstance(2014, 01, 01), 
            Date.newInstance(2014, 12, 31));
    }

    public static EmployeeWorkingPattern__c createWorkingPattern(User u, Boolean monday, Boolean tuesday, Boolean wednesday, Boolean thursday,
        Boolean friday, Boolean saturday, Boolean sunday, Date startDate, Date endDate) {
        EmployeeWorkingPattern__c workPattern = new EmployeeWorkingPattern__c();
        workPattern.Employee__c = u.Id;
        workPattern.StartDate__c = startDate;
        workPattern.EndDate__c = endDate;
        workPattern.Monday__c = monday;
        workPattern.Tuesday__c = tuesday;
        workPattern.Wednesday__c = wednesday;
        workPattern.Thursday__c = thursday;
        workPattern.Friday__c = friday;
        workPattern.Saturday__c= saturday;
        workPattern.Sunday__c = sunday;
        insert workPattern;
        return workPattern;
    }
    /* END EmployeeWorkingPattern Helpers*/

    /* EmployeeLeaveYear Helpers*/
    public static EmployeeLeaveYear__c createEmployeeLeaveYear(User u) {
        return CalendarTestHelper.createEmployeeLeaveYear(u, '2014');
    }

    public static EmployeeLeaveYear__c createEmployeeLeaveYear(User u, String year) {
        return CalendarTestHelper.createEmployeeLeaveYear(u,year,true);
    }

    public static EmployeeLeaveYear__c createEmployeeLeaveYear(User u, String year,Boolean doInsert) {
        EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c();
        leaveYear.Name = u.FirstName+' '+u.LastName+' '+year+' '+Math.random()*1000;
        //leaveYear.CarriedDays__c = 10.0;
        leaveYear.Employee_Leave_Year_ID__c = 98765432;
        leaveYear.Employee__c = u.Id;
        //leaveYear.ExtraDays__c = 3.0;
        leaveYear.StandardDays__c = 24.0;
        //leaveYear.SickDays__c = 24;
        leaveYear.Year__c = year;
        leaveYear.StartDate__c = Date.newInstance(Integer.valueOf(year), 1, 1);//1.3+
        leaveYear.EndDate__c = Date.newInstance(Integer.valueOf(year), 12, 31);//1.3+
        if(doInsert) insert leaveYear;
        return leaveYear;
    }
    /* END EmployeeLeaveYear Helpers*/

    /* Leave Helper*/
    public static Leave__c createLeave(EmployeeLeaveYear__c leaveYear, User u) {
        return CalendarTestHelper.createLeave(leaveYear, u, System.date.today().addDays(30), System.date.today().addDays(35), 'Waiting for approval');
    }

    public static Leave__c createLeave(EmployeeLeaveYear__c leaveYear, User u, Date startDate, Date endDate, String status) {
        return CalendarTestHelper.createLeave(leaveYear, u, UserTestHelper.createStandardUsers(1, 'Adam', 'Gordon')[0], startDate, endDate, status);
    }

    public static Leave__c createLeave(EmployeeLeaveYear__c leaveYear, User u, User approver, Date startDate, Date endDate, String status) {
        return CalendarTestHelper.createLeave(leaveYear, u, approver, startDate, endDate, true, true, true, status);
    }

    public static Leave__c createLeave(EmployeeLeaveYear__c leaveYear, User u, User approver, Date startDate, Date endDate, Boolean am, 
        Boolean pmStart, Boolean pmReturn, String status) {
        return CalendarTestHelper.createLeave(leaveYear, u, approver, startDate, endDate, am, pmStart, pmReturn, status, 'Holiday');
    }

    public static Leave__c createLeave(EmployeeLeaveYear__c leaveYear, User u, User approver, Date startDate, Date endDate, Boolean am,
        Boolean pmStart, Boolean pmReturn, String status, String leaveType) {
        Leave__c leave = new Leave__c();
        //leave.NumberOfHolidays__c = 5.0;
        leave.AM__c = am;
        leave.Approver__c = approver.Id;
        leave.EmployeeComment__c = 'Approve please';
        leave.EmployeeLeaveYear__c = leaveYear.Id;
        leave.Employee__c = u.Id;
        leave.EndDate__c = endDate;
        //leave.HR_Comments__c = 'Ok';
        leave.Leave_Period_ID__c = 101;
        leave.LeaveType__c = leaveType;
        leave.PMStart__c = pmStart;
        leave.PMReturn__c = pmReturn;
        leave.PublicNote__c = 'Text';
        leave.StartDate__c = startDate;
        leave.Status__c = status;
        insert leave;
        return leave;
    }

    //1.1+

    //Input: groupCount - The number of holiday groups generated
    //Input: holidayCount - The number of holidays created for each group
    //Input: minDate - The earliest possible date of the holiday
    //Input: maxDate - The latest possible date of the holiday
    
    //This method returns the specified number of public groups, each with the specified number of holiday randomly assigned accross the date range provided
    //Note - This method won't return more than one holiday for the same day within the same holiday group
    public static List<PublicHolidayGroup__c> createPublicHolidayGroupsWithHoliday(Integer groupCount, Integer holidayCount, Date minDate, Date maxDate){

        if(groupCount==0) return null;
        if(holidayCount > 0 && (minDate==null || maxDate == null || minDate>maxDate)) return null;

        Integer dateRangeCount = (holidayCount==0)?0:minDate.daysBetween(maxDate);
        if(holidayCount>(dateRangeCount+1)) return null;//Not enough days within range for a unique holiday to be applied
        
        //Create specified number of groups
        List<PublicHolidayGroup__c> phGroups = new List<PublicHolidayGroup__c>();
        for(Integer i=0;i<groupCount;i++ ){
            phGroups.add(new PublicHolidayGroup__c(Name='Test Group '+(i+1)));
        }
        system.assertEquals(groupCount, phGroups.size());

        Set<Id> holidayGroupIds = new Set<Id>();
        if(phGroups.size()>0){
            insert phGroups;
            for(PublicHolidayGroup__c phg: phGroups){
                holidayGroupIds.add(phg.Id);
            }
        }
        
        Map<Id,List<Date>> holGroupWithHolidayDates = new Map<Id,List<Date>>();

        //Create specified number of holidays with dates randomly attribute between the min and max dates for each Group
        List<PublicHoliday__c> phs;
        Date holidayDate;
        List<Date> usedDates;
        Set<Id> holidayIds = new Set<Id>();
        if(holidayCount>0){
            phs = new List<PublicHoliday__c>();
            for(PublicHolidayGroup__c phg : phGroups){
                usedDates = new List<Date>();
                holGroupWithHolidayDates.put(phg.Id,new List<Date>());
                for(Integer i=0;i<holidayCount;i++){
                    if(usedDates.size()==0){//Store the Date on the first run (no risk of dupes)
                        holidayDate = (dateRangeCount == 0)?minDate:minDate.addDays((Integer)((Decimal)Math.random()*dateRangeCount).setScale(0,RoundingMode.HALF_DOWN));
                    }else{
                        while(usedDates.contains(holidayDate)){//For subsequent checks randomly find dates within the date range until a unique date is found, then proceed to create record
                            holidayDate = (dateRangeCount == 0)?minDate:minDate.addDays((Integer)((Decimal)Math.random()*dateRangeCount).setScale(0,RoundingMode.HALF_DOWN));
                        }
                    }
                    usedDates.add(holidayDate);
                    phs.add(new PublicHoliday__c(PublicHolidayGroup__c=phg.Id,
                                                IsAllDay__c=true,
                                                Name='Test Holiday for '+phg.Name+' '+(i+1),
                                                Date__c=holidayDate));
                }
            }

            if(phs.size()>0){
                insert phs;
                for(PublicHoliday__c ph : phs){
                    holidayIds.add(ph.Id);
                }
            }
        }

        return [Select Id, Name, (Select Id, Name, Date__c, IsAllDay__c, PublicHolidayGroup__c From PublicHolidays__r) From PublicHolidayGroup__c Where Id IN :holidayGroupIds];
    
    }

    //1.2+
    public static List<EmployeeLeaveYear__c> createEmployeeLeaveYears(Set<Id> userIds, Date startDate, Date endDate, Id publicHolidayGroup, Boolean doInsert){
        
        if(userIds == null || userIds.size()==0) return null;

        List<EmployeeLeaveYear__c> leaveYears = new List<EmployeeLeaveYear__c>();

        for(Id userId : userIds){
            EmployeeLeaveYear__c ly = new EmployeeLeaveYear__c();
            ly.Name = userId+' 2020';
            ly.Employee__c = userId;
            ly.StartDate__c = startDate;
            ly.EndDate__c = endDate;
            ly.StandardDays__c = 24;
            ly.CarriedDays__c = 0;
            ly.SickDays__c = 5;
            ly.PublicHolidayGroup__c = publicHolidayGroup;
            leaveYears.add(ly);
        }

        if(doInsert && leaveYears.size()>0) insert leaveYears;

        return leaveYears;

    }

    /**/

}