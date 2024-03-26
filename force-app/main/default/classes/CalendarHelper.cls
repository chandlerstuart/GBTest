/*
Name:  CalendarHelper.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Helper class for various calendar functions 
======================================================
======================================================
History
------- 
Ver. Author                Date                  Detail
1.0  Halldór Örn        2014-06-18      Initial development.
1.1  Örn Ingvar          2014-06-20      Code cleanup 
1.2  Örn Ingvar          2014-06-23      Implemented getPublicHolidaysBetweenDates
1.3  J Radcliffe         2020-01-22      New variant of the getAgentsPublicHolidayBetweenDates method to accommodate the Globalisation of the Leave Management Solution (replacing Holiday with PublicHoliday__c)

*/
public with sharing class CalendarHelper {

    /*
    firstDateInMonth
    ------------------------
    Purpose: Get the first date of the current month as a date
    Input: none
    Output: Date object
    */
    public static Date firstDateInMonth() {
        
        return firstDateInMonth(null, null);
    }

    /*
    firstDateInMonth
    ------------------------
    Purpose: Get the first date of the specified month as a date
    Input: Integer value of the year, Integer value of month
    Output: Date object
    */
    public static Date firstDateInMonth(Integer year, Integer month){
        
        if(Utilities.isNullOrEmpty(year)){
            year = System.Today().Year();
        }
        if(Utilities.isNullOrEmpty(month)){
            month = System.Today().Month();
        }
        return Date.newInstance(year, month, 1);
    } 

    /*
    lastDateInMonth
    ------------------------
    Purpose: Get the last day in the current month as a date
    Input: none
    Output: Date object
    */
    public static Date lastDateInMonth() {
        
        return lastDateInMonth(null, null);
    }
    
    /*
    lastDateInMonth
    ------------------------
    Purpose: Get the last date of the specified month as a date
    Input: Integer value of the year, Integer value of month
    Output: Date object
    */
    public static Date lastDateInMonth(Integer year, Integer month){
        //Returns the last day in the specified month as a date
        if(Utilities.isNullOrEmpty(year)){
            year = System.Today().Year();
        }
        if(Utilities.isNullOrEmpty(month)){
            month = System.Today().Month();
        }
        return Date.newInstance(year, month, Date.daysInMonth(year, month));
    } 

    /*
    getMonthName
    ------------------------
    Purpose: Get full name of month. Substrings up to 3 characters or returns full name.
    Input: Integer value of the year, Integer value of month
    Output: Name of the specified month as string
    */
    public static String getMonthName(Integer month, Integer length ){

        String result = Datetime.newInstance(System.Today().Year(), month, 1).format('MMMM');
        if(length < 4 && length > 0){ // invalid integers return full name
            result = result.substring(0,length);
        }
        return result;
    }

    /*
    getMonthInteger
    ------------------------
    Purpose: Get the number of a specified month in a year
    Input: Month name as string
    Output: Integer
    */
    public static Integer getMonthInteger(String month) {

        Map<String, Integer> monthMap = new Map<String, Integer>();
        monthMap.put('January', 1);
        monthMap.put('February', 2);
        monthMap.put('March', 3);
        monthMap.put('April', 4);
        monthMap.put('May', 5);
        monthMap.put('June', 6);
        monthMap.put('July', 7);
        monthMap.put('August', 8);
        monthMap.put('September', 9);
        monthMap.put('October', 10);
        monthMap.put('November', 11);
        monthMap.put('December', 12);
        return monthMap.get(month);        
    }

    /*
    getMonthStringList
    ------------------------
    Purpose: Get a list of the months' fullname as strings.
    Input: Integer value startMonth, Integer value endMonth
    Output: List of strings
    */
    public static List<String> getMonthStringList(Integer startMonth, Integer endMonth){
        
        List<String> result = new List<String>();
        for(Integer i = startMonth; i <= endMonth; i++){
            result.add(getMonthName(i,4));
        }
        return result;
    }

    /*
    getIntegerList
    ------------------------
    Purpose: Get a list of all integers between the two integer.
    Input: start Integer, end Integer
    Output: List of integers
    
    public static List<Integer> getIntegerList(Integer startInt, Integer endInt){
        
        List<Integer> result = new List<Integer>();
        for(Integer i = startInt; i <= endInt; i++){
            result.add(i);
        }
        return result;
    }
    */
    
    /*
    getDayName
    ------------------------
    Purpose: Get the full name of day. Substrings up to 3 characters or returns full name.  
    Input: Integer value of the year, Integer value of the month, Integer value of the day, Integer indicating lenght of result 
    Output: Name of day as string value
    */
    public static String getDayName(Integer year, Integer month, Integer day, Integer length ){
        
        String result = Datetime.newInstance(year, month, day).format('EEEE');
        if(length < 4 && length > 0){ // invalid integers return full name
            result = result.substring(0,length);
        }
        return result;
    }

    /*
    getYears
    ------------------------
    Purpose: Get an integer list of years between the two dates
    Input: Start date, End dated
    Output: Date object
    */
    public static List<Integer> getYears(Date startDate, Date endDate){
        
        Set<Integer> yearSet = new Set<Integer>();
        if(startDate.year() != endDate.year()) {
            for(Integer i=startDate.year(); i<=endDate.year(); i++) {
                yearSet.add(i);
            }
        }else{
            yearSet.add(startDate.year());
        }
        List<Integer> yearList = new List<Integer>();
        yearList.addAll(yearSet);
        return yearList;
    }
    
    /*
    getPublicHolidaysBetweenDates
    ------------------------
    Purpose: get a map with all holidays between two specified dates. The holiday's date is used as the maps key.
    Input: Start date, End dated
    Output: Map with list of holidays with date as key
    */
    public static Map<Date, List<Holiday>> getPublicHolidaysBetweenDates(Date startDate, Date endDate){
        // Returns a map with all holidays between two specified dates. The holiday's date is used as the maps key.

        System.debug(LoggingLevel.DEBUG, '=== getPublicHolidaysBetweenDates: ' + startDate + ' AND ' + endDate);
        Map<Date, List<Holiday>> holidayMap = new Map<Date, List<Holiday>>();
        List<Holiday> holidays = new List<Holiday>();        
        List<Integer> years = CalendarHelper.getYears(startDate, endDate);
       System.debug(LoggingLevel.DEBUG, '=== years: ' + years);
        try{
            holidays = [SELECT 
                                ActivityDate, 
                                Description, 
                                EndTimeInMinutes, 
                                Id, 
                                IsAllDay, 
                                IsRecurrence, 
                                Name, 
                                RecurrenceDayOfMonth, 
                                RecurrenceDayOfWeekMask, 
                                RecurrenceEndDateOnly, 
                                RecurrenceInstance, 
                                RecurrenceInterval, 
                                RecurrenceMonthOfYear, 
                                RecurrenceStartDate, 
                                RecurrenceType, 
                                StartTimeInMinutes
                            FROM 
                                Holiday];
        }catch(Exception e){
            RuntimeExceptionHelper.logException(e);
            System.debug('No holidays found: ' + e);
        }
        
        //Do a loop just to work with recurring dates that fall on the year(s) 
        for(Holiday holiday: holidays) {
            if(holiday.IsRecurrence) {
                for(Integer i=0; i<years.size(); i++) {
                    Date d = date.newInstance(years[i], getMonthInteger(holiday.RecurrenceMonthOfYear), holiday.RecurrenceDayOfMonth);
                    holidayMap.put(d, new List<Holiday>{holiday});
                }
            }
        }
        //Loop over the holidays to create the map of holidays
        for(Holiday holiday: holidays) {
            if(holidayMap.containsKey(holiday.ActivityDate)){
                List<Holiday> tmpList = holidayMap.get(holiday.ActivityDate);
                tmpList.add(holiday);
                holidayMap.put(holiday.ActivityDate, tmpList);
            }else{
                holidayMap.put(holiday.ActivityDate, new List<Holiday>{holiday});
            }
        }
        
        return holidayMap;
    }

    
    /* 1.3+
    getPublicHolidaysBetweenDates
    ------------------------
    Purpose: Mirrors on the original 'getPublicHolidaysBetweenDates' method. This gets a map with all holidays between two specified dates for each specified user. 
    Input: Start date, End dated, Employee Ids
    Output: Map with a Map of Public Holidays for each user (with date as key) with the User Id as the key
    */
    public static Map<Id,Map<Date, PublicHoliday__c>> getAgentsPublicHolidayBetweenDates(Date startDate, Date endDate, Set<Id> employeeIds){
        try{
            if(employeeIds == null || employeeIds.size()==0) return null;

            //Map to return to the caller - Map<UserIds,Map<HolidayDate,PublicHolidayRecord>>
            Map<Id,Map<Date, PublicHoliday__c>> userIdWithPublicHolidaysMap = new Map<Id,Map<Date, PublicHoliday__c>>();

            //Get the public holiday group for each user
            Map<Id,Id> usersWithPublicHolidayGroupId = new Map<Id,Id>();
            for(EmployeeLeaveYear__c ely : EmployeeLeaveYearManager.getEmployeeLeaveYearsByUsersAndDateValue(employeeIds,endDate).values()){//Get the latest Employee Leave Year (based on specified date range) for users to determine their Public Holiday Group for subsequent query
                if(ely.Employee__c == null || ely.PublicHolidayGroup__c == null) continue;
                if(!usersWithPublicHolidayGroupId.containsKey(ely.Employee__c)) usersWithPublicHolidayGroupId.put(ely.Employee__c,ely.PublicHolidayGroup__c);
            }
            
            //Retrieve the Public Holday within the specified date range and pairs with the appropriate user(s) based on their public holiday group
            Id publicHolidayGroupId;
            for(PublicHoliday__c ph : [Select Id, Name, AM_or_PM__c, Description__c, Date__c, IsAllDay__c, PublicHolidayGroup__c From PublicHoliday__c Where PublicHolidayGroup__c In:usersWithPublicHolidayGroupId.values() and Date__c>=:startDate and Date__c<=:endDate Order By Date__c ASC, LastModifiedDate DESC]){
                for(Id userId : usersWithPublicHolidayGroupId.keySet()){
                    publicHolidayGroupId = usersWithPublicHolidayGroupId.get(userId);
                    //If the public holiday belongs to the same group as the agent store in their holiday map
                    if(ph.PublicHolidayGroup__c == publicHolidayGroupId){
                        if(!userIdWithPublicHolidaysMap.containsKey(userId)) userIdWithPublicHolidaysMap.put(userId,new Map<Date,PublicHoliday__c>());
                        if(userIdWithPublicHolidaysMap.get(userId).containsKey(ph.Date__c)) continue;//Only store a single PH for a given date
                        userIdWithPublicHolidaysMap.get(userId).put(ph.Date__c,ph);//Add Holiday to map for the user
                    }
                }
            }

            return userIdWithPublicHolidaysMap;

        }catch(Exception e){
            PlatformLogManager.logExceptions(e, 'CalendarHelper', 'getPublicHolidaysBetweenDates');
            return null;
        }

    }





}