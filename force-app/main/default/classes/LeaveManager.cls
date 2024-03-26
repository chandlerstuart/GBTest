/*
Name:  LeaveManager.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------

======================================================
======================================================
History
-------
Ver. Author                Date                  Detail
1.0  Halldór Örn        2014-06-18      Initial development.
1.1  Örn Ingvar          2014-06-20      Code cleanup
1.2  Örn Ingvar          2014-06-23      Implemented calculateNumberOfDaysOfLeave and tested
1.3  Örn Ingvar          2014-08-05      Rewrote checkForOverlappingRequests
1.4  Örn Ingvar          2015-05-15      Fixed issue where holidays on weekends were not reduced from total
1.5  J Radcliffe         2019-11-11      Fixed issue where half day public holidays were not being removed from the # of Days Requested Calculation
1.6  J Radcliffe         2019-11-25      New method isWorkingDay - Initially introduced to support the bypassing of public holiday subtraction on non-working days
1.7  J Radcliffe         2020-01-23      Changes to support the globalisation of the Leave Management system (trading 'Holiday' with 'PublicHoliday__c')
1.8  J Radcliffe         2020-01-27      Modification to 'getLeaveByUserIdAndYear' - Return Leave based on parent Leave Year (static value) rather than calendar year
*/
public without sharing class LeaveManager {

    public static Boolean isTest = false;
    /*
    getLeaveType
    ------------------------
    Purpose: To retrieve the values in the custom field Leave__c.LeaveType__c as a select option list
    Input: none
    Output: List of Select options
    */
    public static List<SelectOption> getLeaveType() {
        //Returns
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult =  Schema.sObjectType.Leave__c.fields.LeaveType__c;
        fieldResult = fieldResult.getSObjectField().getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple){
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        return options;
    }

    /*
    getLeaveByUserId
    ------------------------
    Purpose: To get a list of Leave Requests based on a set of user Ids
    Input: Set of Ids
    Output: A list of leave__c records
    */
    public static List<Leave__c> getLeaveByUserId(Set<Id> userIds){

        List<Leave__c> result = new List<Leave__c>();
        try{
            result = [  SELECT
                    Id, Name, NumberOfHolidays__c, AM__c, EmployeeComment__c, EmployeeLeaveYear__c, Employee__c, EndDate__c, LeaveType__c, Manager__c, PMStart__c, PMReturn__c, PublicNote__c, StartDate__c, Status__c
                FROM
                    Leave__c
                WHERE
                    Employee__c IN: userIds];
            if(LeaveManager.isTest) throw new RuntimeExceptionHelper.testThrownException('Exception thrown while testing');
        }catch(Exception e){
            System.debug(LoggingLevel.ERROR, 'No Leave__c for userids '+ userIds +': ' + e);
            RuntimeExceptionHelper.logException(e);
        }
        return result;
    }

    /*
    getPendingLeaveByUserId
    ------------------------
    Purpose: To get a list of pending Leave Requests based on a set of user Ids
    Input: Set of Ids
    Output: A list of leave__c records
    */
    public static List<Leave__c> getPendingLeaveByUserId(Set<Id> userIds){

        List<Leave__c> result = new List<Leave__c>();
        try{
            result = [  SELECT
                    Id, Name, Approver__c, NumberOfHolidays__c, AM__c, EmployeeComment__c, EmployeeLeaveYear__c, Employee__c, EndDate__c, LeaveType__c, Manager__c, PMStart__c, PMReturn__c, PublicNote__c, StartDate__c, Status__c, Employee__r.Name
                FROM
                    Leave__c
                WHERE
                    Employee__c IN: userIds
                AND
                    Status__c = 'Waiting for approval'
                ORDER BY
                    Employee__r.Name, StartDate__c];
            if(LeaveManager.isTest) throw new RuntimeExceptionHelper.testThrownException('Exception thrown while testing');
        }catch(Exception e){
            System.debug(LoggingLevel.ERROR, 'No Leave__c for userids '+ userIds +': ' + e);
            RuntimeExceptionHelper.logException(e);
        }
        return result;
    }

    /*
    getLeaveByUserIdAndYear
    ------------------------
    Purpose: To get a list of Leave Requests based on a set of user Ids and a specified year
    Input: Set of Ids, Integer value of the year
    Output: A list of leave__c records
    */

    public static List<Leave__c> getLeaveByUserIdAndYear(Set<Id> userIds, String year){

        if(year == null || userIds.size()==0) return new List<Leave__c>();//1.8+

        // Returns
        //Date first = Date.newInstance(Integer.valueOf(year), 1, 1); //1.8-
        //Date last = Date.newInstance(Integer.valueOf(year), 12, 31); //1.8-
        List<Leave__c> result = new List<Leave__c>();
        try{
            result = [  SELECT
                    Id, Name, NumberOfHolidays__c, AM__c, EmployeeComment__c, EmployeeLeaveYear__c, Employee__c, EndDate__c, LeaveType__c, Manager__c, PMStart__c, PMReturn__c, PublicNote__c, StartDate__c, Status__c
                FROM
                    Leave__c
                WHERE
                    Employee__c IN: userIds
                /*AND //1.8-
                    StartDate__c >=: first
                AND
                    StartDate__c <=: last*/
                AND 
                    EmployeeLeaveYear__r.Year__c =:year //1.8+
                ORDER BY
                    StartDate__c DESC];
            if(LeaveManager.isTest) throw new RuntimeExceptionHelper.testThrownException('Exception thrown while testing');
        }catch(Exception e){
            System.debug(LoggingLevel.ERROR, 'No Leave__c for userids '+ userIds +': ' + e);
            RuntimeExceptionHelper.logException(e);
        }
        return result;
    }



    /*
    getLeaveByUserIdAndMonth
    ------------------------
    Purpose: To get a list of Leave Requests based on a set of user Ids, a specified year and a specified month.
    Input: Set of Ids, Integer value of the year, Integer value of the month, Boolean value for approved only or all requests
    Output: A list of leave__c records
    */
    public static List<Leave__c> getLeaveByUserIdAndMonth(Set<Id> userIds, Integer year, Integer month, Boolean approvedOnly){
        // Returns
        // Boolean value approvedOnly gives the option of returning only records with Status__c value of "Approved".
        Date startDate = Date.newInstance(year, month, 1);
        Date endDate = Date.newInstance(year, month, Date.daysInMonth(year, month));
        List<Leave__c> result = new List<Leave__c>();
        List<String> statuses = new List<String>{'Approved'};
        if(!approvedOnly){
            statuses.add('Waiting for approval');
        }

        try{
            result = [  SELECT
                            Id, Name, NumberOfHolidays__c, AM__c, EmployeeComment__c, EmployeeLeaveYear__c, Employee__c, EndDate__c, LeaveType__c,
                            Manager__c, PMStart__c, PMReturn__c, PublicNote__c, StartDate__c, Status__c
                        FROM
                            Leave__c
                        WHERE
                            Employee__c IN: userIds
                        AND
                            StartDate__c <=: endDate
                        AND
                            EndDate__c >=: startDate
                        AND
                            Status__c in: statuses
                        ORDER BY
                            StartDate__c
            ];
           if(LeaveManager.isTest) throw new RuntimeExceptionHelper.testThrownException('Exception thrown while testing');
        }catch(Exception e){
            System.debug(LoggingLevel.ERROR, 'No Leave__c for userids '+ userIds +': ' + e);
            RuntimeExceptionHelper.logException(e);
        }
        return result;
    }

    /*
    getLeavesForToday
    ------------------------
    Purpose: To get a list of Leave Requests that are approved and occuring today.
    Input: none
    Output: A list of leave__c records
    */
    public static List<Leave__c> getLeavesForToday(){

        Date today = Date.newInstance(System.today().year(), System.today().month(), System.today().day());
        List<Leave__c> result = new List<Leave__c>();
        try{
            result = [  SELECT
                    Id, Name, NumberOfHolidays__c, AM__c, EmployeeComment__c, EmployeeLeaveYear__c, Employee__c, EndDate__c, LeaveType__c,
                    Manager__c, PMStart__c, PMReturn__c, PublicNote__c, StartDate__c, Status__c, Employee__r.Title, Employee__r.Name, Employee__r.IsActive
                FROM
                    Leave__c
                WHERE
                    StartDate__c <=: today
                AND
                    EndDate__c >=: today
                AND
                    Status__c = 'Approved'
                AND
                    Employee__r.IsActive = true
                ORDER BY
                    Employee__r.Name];
            if(LeaveManager.isTest) throw new RuntimeExceptionHelper.testThrownException('Exception thrown while testing');
        }catch(Exception e){
            System.debug(LoggingLevel.ERROR, 'No Leave__c for today '+ today +': ' + e);
            RuntimeExceptionHelper.logException(e);
        }
        return result;
    }

    /*
    getUsersWithApprovedLeaveThisMonth
    ------------------------
    Purpose: To get a list ids that have approved leave for the specified month and year
    Input: Integer value of the year, Integer value of the month
    Output: A set of user Ids
    */
    public static Set<ID> getUsersWithApprovedLeaveThisMonth(Integer year, Integer month){

        Set<ID> results = new Set<ID>();
        Date first = CalendarHelper.firstDateInMonth(year, month);
        Date last = CalendarHelper.lastDateInMonth(year, month);
        try{
            List<Leave__c> leaves = [   SELECT
                    Id, Employee__c, EndDate__c, StartDate__c, Employee__r.Name
                FROM
                    Leave__c
                WHERE
                    StartDate__c <=: last
                AND
                    EndDate__c >=: first
                AND
                    Status__c = 'approved'
                ORDER BY
                    Employee__r.Name ];
            for(Leave__c l : leaves){
                results.add(l.Employee__c);
            }
            if(LeaveManager.isTest) throw new RuntimeExceptionHelper.testThrownException('Exception thrown while testing');
        }catch(Exception e){
            System.debug(LoggingLevel.ERROR, 'No leaves between '+ first +' and ' + last + ': ' + e);
            RuntimeExceptionHelper.logException(e);
        }
        return results;
    }

    /*
    insertLeaveRequest
    ------------------------
    Purpose: inserting a single leave request
    Input: A leave request to be inserted
    Output: String containing the result of the operation
    */
    public static String insertLeaveRequest(Leave__c leave){
        // Inserts new leave requests
        String result = '';
        try{
            insert leave;
            result = 'success';
            if(LeaveManager.isTest) throw new RuntimeExceptionHelper.testThrownException('Exception thrown while testing');
        }catch(Exception e){
            result = 'failed: ' + e;
            System.debug(LoggingLevel.ERROR, 'insert on Leave request failed: ' + e);
            if(e.getMessage().contains('Leave length 0')){
                /*Don't log exception for this occurrance*/
                System.debug(LoggingLevel.DEBUG, '=== Leave Length 0 not reported to RuntimeExceptionHelper');
            }
            else {
                RuntimeExceptionHelper.logException(e);
            }

        }
        return result;
    }

    /*
    calculateNumberOfDaysOfLeave
    ------------------------
    Purpose: Calculates the number of days requested in a leave request with consideration to holidays, weekends and working patterns.
    Input: Leave request, map of working patterns, map of holidays
    Output: Decimal value - the number of days requested
    */
    public static Decimal calculateNumberOfDaysOfLeave(Leave__c leave, Map<Id, List<EmployeeWorkingPattern__c>> patternMap,
        //Map<Date, List<Holiday>> holidays){//1.7-
        Map<Date,PublicHoliday__c> publicHolidays){//1.7+
        //Authorised leaves are considered work from home and do not count as a reduction in holidays
        if(leave.LeaveType__c == 'Authorised') {
            return 0.0;
        } else if (leave.LeaveType__c.toUpperCase().indexOf('LIEU') > -1 || leave.LeaveType__c == ApplicationConstant.LEAVE_TYPE_WELLNESS_DAY) {
            //Get the absolute number of days without taking into consideration holidays and working pattern
            // and add one day since the end date is included
            Integer noOfDaysBetween = leave.StartDate__c.daysBetween(leave.EndDate__c) + 1;
            System.debug(LoggingLevel.DEBUG, '=== noOfDaysBetween ' + noOfDaysBetween);
            Decimal result = 0.0;
            Decimal difference  = Decimal.valueOf(noOfDaysBetween);
            
            //Boolean that tells wheter the condition checked for in holiday halfday has been reduced already
            Boolean fttHalfDayDone = false;

            //Half days calculations for start and end on the same day. PMReturn is ignored for those calculations.
            if(leave.StartDate__c == leave.EndDate__c) {
                Decimal halfDaySameDay1 = !leave.AM__c && leave.PMStart__c  ? 0.5 : 0;
                Decimal halfDaySameDay2 = leave.AM__c && !leave.PMStart__c  ? 0.5 : 0;
                result = difference - halfDaySameDay1 - halfDaySameDay2;

                System.debug(logginglevel.DEBUG,'=== halfDaySameDay1: ' + halfDaySameDay1);
                System.debug(logginglevel.DEBUG,'=== halfDaySameDay2: ' + halfDaySameDay2);
                fttHalfDayDone = ( halfDaySameDay1 - halfDaySameDay2 ) == -0.5;
                System.debug(logginglevel.DEBUG,'=== fttHalfDayDone: ' + fttHalfDayDone);
            } else {
                Decimal halfday1 = !leave.PMReturn__c ? 0.5 : 0;
                Decimal halfday2 = !leave.AM__c && leave.PMStart__c ? 0.5 : 0;
                Decimal halfday3 = leave.AM__c && !leave.PMStart__c ? 0.5 : 0;

                result = difference - halfday1 - halfday2 - halfday3;
                fttHalfDayDone = ( halfday1 - halfday2 - halfday3 ) == -0.5;
                System.debug(logginglevel.DEBUG,'=== fttHalfDayDone: ' + fttHalfDayDone);
            }
            
            return result;
            
        } else {
            Boolean hasPattern = false;
            //Get the absolute number of days without taking into consideration holidays and working pattern
            // and add one day since the end date is included
            Integer noOfDaysBetween = leave.StartDate__c.daysBetween(leave.EndDate__c) + 1;
            System.debug(LoggingLevel.DEBUG, '=== noOfDaysBetween ' + noOfDaysBetween);
            Decimal result = 0.0;
            Decimal difference  = Decimal.valueOf(noOfDaysBetween);

            //Half day calculations
            /*Possible variations:
                AMStart = false, PMStart = true, PMReturn = false. Half a day
                AMStart = true, PMStart = false, PMReturn = false. Half a day
                AMStart = false, PMStart = true, PMReturn = true. Start and end date on same day = Half a day
                AMStart = false, PMStart = true, PMReturn = true. End date date after start date = whole day.
                AMStart = true, PMStart = false, PMReturn = true. Half a day
                AMStart = true, PMStart = true, PMReturn = false. Half a day
            */
            //Boolean that tells wheter the condition checked for in holiday halfday has been reduced already
            Boolean fttHalfDayDone = false;

            //Half days calculations for start and end on the same day. PMReturn is ignored for those calculations.
            if(leave.StartDate__c == leave.EndDate__c) {
                Decimal halfDaySameDay1 = !leave.AM__c && leave.PMStart__c  ? 0.5 : 0;
                Decimal halfDaySameDay2 = leave.AM__c && !leave.PMStart__c  ? 0.5 : 0;
                result = difference - halfDaySameDay1 - halfDaySameDay2;

                System.debug(logginglevel.DEBUG,'=== halfDaySameDay1: ' + halfDaySameDay1);
                System.debug(logginglevel.DEBUG,'=== halfDaySameDay2: ' + halfDaySameDay2);
                fttHalfDayDone = ( halfDaySameDay1 - halfDaySameDay2 ) == -0.5;
                System.debug(logginglevel.DEBUG,'=== fttHalfDayDone: ' + fttHalfDayDone);
            } else {
                Decimal halfday1 = !leave.PMReturn__c ? 0.5 : 0;
                Decimal halfday2 = !leave.AM__c && leave.PMStart__c ? 0.5 : 0;
                Decimal halfday3 = leave.AM__c && !leave.PMStart__c ? 0.5 : 0;

                result = difference - halfday1 - halfday2 - halfday3;
                fttHalfDayDone = ( halfday1 - halfday2 - halfday3 ) == -0.5;
                System.debug(logginglevel.DEBUG,'=== fttHalfDayDone: ' + fttHalfDayDone);
            }
            Set<String> workDays = new Set<String>();
            if(patternMap.containsKey(leave.Employee__c)){
                hasPattern = true;
                List<EmployeeWorkingPattern__c> patterns = patternMap.get(leave.Employee__c);
                //Add the working pattern days to the set
                for(EmployeeWorkingPattern__c patt: patterns) {
                    if(patt.Monday__c) { workDays.add('Monday'); }
                    if(patt.Tuesday__c) { workDays.add('Tuesday'); }
                    if(patt.Wednesday__c) { workDays.add('Wednesday'); }
                    if(patt.Thursday__c) { workDays.add('Thursday'); }
                    if(patt.Friday__c) { workDays.add('Friday'); }
                    if(patt.Saturday__c) { workDays.add('Saturday'); }
                    if(patt.Sunday__c) { workDays.add('Sunday'); }
                    System.debug(LoggingLevel.DEBUG, '=== workDays: ' + workDays);
                }
            }else{
                //Add the standard working days to the set since there is no working pattern
                workDays.addAll( new List<String>{'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'});
            }

            //Attempt at optimization by not doing repeated calls to CalendarHelper.getDayName
            String firstDayName = '';
            Integer workDayIdx = 0;
            if(!hasPattern) {
                    Date cDate = leave.StartDate__c;
                    firstDayName = CalendarHelper.getDayName(cDate.year(), cDate.month(), cDate.day(), 4);
                    if(firstDayName == 'Monday') workDayIdx = 0;
                    if(firstDayName == 'Tuesday') workDayIdx = 1;
                    if(firstDayName == 'Wednesday') workDayIdx = 2;
                    if(firstDayName == 'Thursday') workDayIdx = 3;
                    if(firstDayName == 'Friday') workDayIdx = 4;
                    if(firstDayName == 'Saturday') workDayIdx = 5;
                    if(firstDayName == 'Sunday') workDayIdx = 6;
                }
            for(Integer i=0; i<noOfDaysBetween; i++) {
                Date currDate = leave.StartDate__c.addDays(i);
                System.debug(LoggingLevel.DEBUG, '== currentDate: ' + currDate);
                //System.debug(LoggingLevel.DEBUG, '=== holidays keySet: ' + holidays.keySet());//1.7=
                if(publicHolidays != null) System.debug(loggingLevel.DEBUG, '=== holidays keySet: ' + publicHolidays.keySet());//1.7+
                //Check the holiday map for a hit
                //if(holidays.containsKey(currDate)) {//1.7-
                if(publicHolidays != null && publicHolidays.containsKey(currDate)) {//1.7+
                    System.debug(LoggingLevel.DEBUG, '=== holidayMap contains key');
                    //Employee does not have a working pattern and the work day index indicates a weekday
                    if(!hasPattern) {
                        System.debug(LoggingLevel.DEBUG, '=== employee does not have a working pattern');
                        System.debug(LoggingLevel.DEBUG, '=== workDayIdx: ' + workDayIdx);
                        if(workDayIdx < 5){
                            System.debug(LoggingLevel.DEBUG, '=== workday index indicates a weekday');
                            //if(holidays.get(currDate)[0].IsAllDay) {//1.7-
                            if(publicHolidays.get(currDate).IsAllDay__c){//1.7+
                                System.debug(LoggingLevel.DEBUG, '=== reducing result by one since a holiday that lands on a working day was found:' + currDate);
                                result = result - 1.0;
                            } else {
                                System.debug(LoggingLevel.DEBUG, '=== reducing result by half since a half day holiday that lands on a working day was found:' + currDate);
                                if(!fttHalfDayDone){
                                    result = result - 0.5;
                                }
                            }
                        }
                        //Holidays that land on non-work days should be reduced from total
                        if(workDayIdx == 5) {
                            System.debug(LoggingLevel.DEBUG, '=== reducing result by one since a holiday that lands on a non-working day was found:' + currDate);
                            result = result - 1.0;
                        }
                        //Reset the working day index after reducing non-working holiday from total
                        else if(workDayIdx == 6) {
                            System.debug(LoggingLevel.DEBUG, '=== reducing result by one since a holiday that lands on a non-working day was found:' + currDate);
                            result = result - 1.0;
                            workDayIdx = 0;
                        //Increment the working day index
                        } else {
                            workDayIdx++;
                        }
                    }
                    //Employee does have a working pattern
                    else {
                        if(isWorkingDay(currDate, leave, patternMap.get(leave.Employee__c))){//1.6+ 
                            //if(holidays.get(currDate)[0].IsAllDay) {//1.7-
                            if(publicHolidays.get(currDate).IsAllDay__c) {//1.7+
                                System.debug(LoggingLevel.DEBUG, '=== reducing result by one since a holiday that lands on a working day was found:' + currDate);
                                result = result - 1.0;
                            } else {
                                System.debug(LoggingLevel.DEBUG, '=== reducing result by half since a half day holiday that lands on a working day was found:' + currDate);
                                //Decimal holidayHalfday = leave.AM__c && leave.PMStart__c && leave.PMReturn__c && !fttHalfDayDone ? 1.0 : 0.5;//1.5-
                                Decimal holidayHalfday = 0.5;//1.5+
                                result = result - holidayHalfday;
                            }
                        }else{//1.6+
                            System.debug(LoggingLevel.DEBUG, '=== reducing result by one since the date is a non working date: ' + currDate);
                            result = result-1;
                        }
                    }
                //Not a holiday
                }else{
                    if(workDays.contains(CalendarHelper.getDayName(currDate.year(), currDate.month(), currDate.day(), 4))) {
                        //Do nothing, day requested for leave falls on a working day
                    }else{
                        //Subtract a day from the requested days since it falls on a non working day
                        System.debug(LoggingLevel.DEBUG, '=== reducing result by one since the date is a non working date: ' + currDate);
                        result = result - 1.0;
                    }
                    //Reset the working day index
                    if(workDayIdx == 6) {
                        workDayIdx = 0;
                    //Increment the working day index
                    } else {
                        workDayIdx++;
                    }
                }
            }

            //No negative numbers should go through. Zero returned if less then zero.
            if(result<0) {
                return 0;
            }
            System.debug(LoggingLevel.DEBUG, '=== result to be returned: ' + result);
            return result;
        }
    }


    /*
    checkForOverLappingRequests
    ------------------------
    Purpose: Checks for requests from a user that would fall on the same period and returns the requests that overlap
    Input: The records to check for overlap
    Output: The records that do overlap
    */
    public static List<Leave__c> checkForOverlappingRequests( List<Leave__c> recordsToCheck ) {
        Date startDate = null;
        Date endDate = null;
        Set<Id> userIds = new Set<Id>();
        Set<Id> leaveIdsToExclude = new Set<Id>();
        Set<String> allowedStatus = new Set<String>{'Approved', 'Waiting for approval'};
        Set<Leave__c> result = new Set<Leave__c>();
        Map<Id, List<Leave__c>> userLeaveMap = new Map<Id,List<Leave__c>>();
        for(Leave__c l : recordsToCheck) {
            leaveIdsToExclude.add(l.Id);
            updateUserLeaveMap(userLeaveMap, l);

            //Find the earliest startdate to limit the query
            if( l.StartDate__c <= startDate || startDate == null ) {
                startDate = l.StartDate__c;
            }
            //Find the latest enddate to limit the query
            if( l.EndDate__c >= endDate || endDate == null ) {
                endDate = l.EndDate__c;
            }
            //Set of user Ids to filter the query by
            userIds.add(l.Employee__c);
        }

        System.debug(LoggingLevel.DEBUG, '=== startDate: ' + startDate);
        System.debug(LoggingLevel.DEBUG, '=== endDate: ' + endDate);
        System.debug(LoggingLevel.DEBUG, '=== allowedStatus: ' + allowedStatus);
        System.debug(LoggingLevel.DEBUG, '=== userIds: ' + userIds);

        try{
            for(Leave__c l: [SELECT StartDate__c, EndDate__c, Employee__c, AM__c, PMReturn__c, PMStart__c FROM Leave__c WHERE
                    ((StartDate__c >= :startDate
                    AND EndDate__c  <= :endDate)
                    OR (EndDate__c >=: startDate
                    AND StartDate__c <=: startDate))
                    AND Status__c IN: allowedStatus
                    AND Employee__c IN: userIds
                    AND Id NOT IN: leaveIdsToExclude
                ]){
                updateUserLeaveMap(userLeaveMap, l);
                if(LeaveManager.isTest) throw new RuntimeExceptionHelper.testThrownException('Exception thrown while testing');
            }
        }catch(Exception e){
            RuntimeExceptionHelper.logException(e);
        }

        Set<Id> setOfKeys = userLeaveMap.keySet();
        System.debug(LoggingLevel.DEBUG, '=== keySet ' + setOfKeys);
        for(Id i: setOfKeys) {
            List<Leave__c> leaveListForUser = userLeaveMap.get(i);
            System.debug(LoggingLevel.DEBUG, '=== leaveListForUser.size(): ' + leaveListForUser.size());
            //No overlap if there is just one record so skip to next user in the map
            if(leaveListForUser.size() <= 1) continue;
            else {
                Leave__c tmpLeave = null;
                for(Leave__c leave: leaveListForUser) {
                    if(tmpLeave == null) {
                        tmpLeave = leave;
                        continue;
                    }
                    if(doesOverlap(leave, tmpLeave)) {
                        result.addAll( new List<Leave__c>{ leave, tmpLeave } );
                    }
                    tmpLeave = leave;
                }
            }
        }

        List<Leave__c> returnList = new List<Leave__c>();
        returnList.addAll(result);
        return returnList;
    }

    /*
    updateUserLeaveMap
    ------------------------
    Purpose: Adds Leave request to a users leave request map
    Input: Map of Leave requests, a single leave request
    Output: none
    */
    private static void updateUserLeaveMap(Map<Id, List<Leave__c>> userLeaveMap, Leave__c l) {
        if(userLeaveMap.containsKey(l.Employee__c)) {
            List<Leave__c> tmpList = userLeaveMap.get(l.Employee__c);
            tmpList.add(l);
            userLeaveMap.put(l.Employee__c, tmpList);
        } else {
            userLeaveMap.put(l.Employee__c, new List<Leave__c>{ l });
        }
    }

    /*
    doesOverLap
    ------------------------
    Purpose: Check for overlap between two leave records
    Input: A pair of leave records with start and end dates set
    Output: True if the two records overlap otherwise false
    */
    private static boolean doesOverlap (Leave__c l1, Leave__c l2) {
        System.debug(LoggingLevel.DEBUG, '\n======= l1 DEBUG =======\nl1.AM__c: ' + l1.AM__c + ' l1.PMStart__c: ' + l1.PMStart__c +
            ' \nl1.StartDate__c: ' + l1.StartDate__c + ' l1.EndDate__c ' + l1.EndDate__c +
            '\n======= l2 DEBUG =======\nl2.AM__c: ' + l2.AM__c + ' l2.PMStart__c: ' + l2.PMStart__c + ' \nl2.StartDate__c: ' + l2.StartDate__c +
            ' l2.EndDate__c ' + l2.EndDate__c);

        //First check if both records are a whole day
        if(l1.AM__c && l1.PMStart__c && l1.PMReturn__c && l2.AM__c && l2.PMStart__c && l2.PMReturn__c) {
            if(l1.StartDate__c > l2.StartDate__c) {
                Leave__c tmpLeave = l1;
                l1 = l2;
                l2 = tmpLeave;
            }
            if(l2.StartDate__c > l1.EndDate__c) {
                System.debug('=== Return FALSE');
                return false;
            }
            System.debug('=== Return TRUE inside if of both are whole days');
            return true;
        //Check for a legal combination of two leaves that are half a day each
        } else if((l1.AM__c && !l1.PMStart__c && !l2.AM__c && l2.PMStart__c) || (!l1.AM__c && l1.PMStart__c && l2.AM__c && !l2.PMStart__c)) {
            //Check if its the same day which means that this is a legal split of the day
            if(l1.StartDate__c == l2.StartDate__c && l1.EndDate__c == l2.EndDate__c) {
                System.debug(LoggingLevel.DEBUG, '=== Return FALSE');
                return false;
            }
            else if(l1.StartDate__c >= l2.StartDate__c) {
                Leave__c tmpLeave = l1;
                l1 = l2;
                l2 = tmpLeave;
            }
            if(l2.StartDate__c >= l1.EndDate__c) {
                System.debug('=== Return FALSE');
                return false;
            }
            System.debug('=== Return TRUE inside else if check for legal half days');
            return true;
        } else {
            if(l1.StartDate__c > l2.StartDate__c) {
                Leave__c tmpLeave = l1;
                l1 = l2;
                l2 = tmpLeave;
            }

            //If l1 ends in the am and l2 starts in the pm, then no overlap.
            if(!l1.PMReturn__c && !l2.AM__c) return false;
            
            if(l2.StartDate__c > l1.EndDate__c) {
                System.debug('=== Return FALSE');
                return false;
            }
            System.debug('=== Return TRUE inside else');
            return true;
        }
    }

    /*
    Wrapper class to be used in communication between javascript remote action and controller
    */
    public class LeaveWrapper{
        public String   employeeName { get; set; }
        public String   employeeLeaveYear { get; set; }
        public String   type { get; set; }
        public Date     startDate { get; set; }
        public Date     endDate { get; set; }
        public Boolean  am { get; set; }
        public Boolean  pmStart { get; set; }
        public Boolean  pmReturn { get; set; }
        public String   employeeComment { get; set; }
        public String   publicNote { get; set; }

        public LeaveWrapper(){
            this.employeeName = '';
            this.employeeLeaveYear = '';
            this.type = '';
            this.startDate = System.today();
            this.endDate = System.today();
            this.am = true;
            this.pmStart = true;
            this.pmReturn = true;
            this.employeeComment = '';
            this.publicNote = '';
        }

        public LeaveWrapper( String employeeName, String employeeLeaveYear, String type, Date startDate, Date endDate, Boolean am, Boolean pmStart, Boolean pmReturn, String employeeComment, String publicNote ){
            this.employeeName = employeeName;
            this.employeeLeaveYear = employeeLeaveYear;
            this.type = type;
            this.startDate = startDate;
            this.endDate = endDate;
            this.am = am;
            this.pmStart = pmStart;
            this.pmReturn = pmReturn;
            this.employeeComment = employeeComment;
            this.publicNote = publicNote;
        }
    }

    //1.6+ - Returns true if the specified date is a working day for the user based on the applicable employee work pattern
    public static Boolean isWorkingDay(DateTime applicableDate, Leave__c leave, List<EmployeeWorkingPattern__c> patternList){

        String dayOfTheWeek = applicableDate.format('E');

        EmployeeWorkingPattern__c pattern;
        if(patternList.size()>0){
            for(EmployeeWorkingPattern__c ewp : patternList){
                if(ewp.Employee__c != leave.Employee__c || ewp.StartDate__c > applicableDate || ewp.EndDate__c < applicableDate){ continue;
                }else{
                    pattern = ewp;
                    break;
                }
            }
        }
        Boolean hasPattern = (pattern == null)?false:true;
            
        if(hasPattern){
            if(dayOfTheWeek.containsIgnoreCase('Mon') && !pattern.Monday__c) return false;
            if(dayOfTheWeek.containsIgnoreCase('Tue') && !pattern.Tuesday__c) return false;
            if(dayOfTheWeek.containsIgnoreCase('Wed') && !pattern.Wednesday__c) return false;
            if(dayOfTheWeek.containsIgnoreCase('Thu') && !pattern.Thursday__c) return false;
            if(dayOfTheWeek.containsIgnoreCase('Fri') && !pattern.Friday__c) return false;
            if(dayOfTheWeek.containsIgnoreCase('Sat') && !pattern.Saturday__c) return false;
            if(dayOfTheWeek.containsIgnoreCase('Sun') && !pattern.Sunday__c) return false;
            return true;//Catch all
        }else{
            return(dayOfTheWeek.containsIgnoreCase('Sat') || dayOfTheWeek.containsIgnoreCase('Sun'))?false:true;
        }
            
    }


}