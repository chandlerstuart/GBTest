/*
Name:  EmployeeWorkingPatternManager.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Various functions to determine if working patterns are applicable or not
======================================================
======================================================
History
------- 
Ver. Author                Date                  Detail
1.0  Halldór Örn        2014-06-18      Initial development.
1.1  Örn Ingvar         2014-06-20      Code cleanup 
1.2  Halldór Örn        2014-06-20      Added isWorkingDay function
1.3  Halldór Örn        2014-07-09      updated getUserWorkingPatternMapActiveToday function

*/
public with sharing class EmployeeWorkingPatternManager 
{
    public static Boolean isTest = false; //Used to throw exceptions while testing
    /*
    getUserWorkingPatternById
    ------------------------
    Purpose: To get a list of working patterns based on a set of users' Ids
    Input: Set of Ids
    Output: List of EmployeeWorkingPattern__c records
    */
    public static List<EmployeeWorkingPattern__c> getUserWorkingPatternById(Set<Id> userIds){

        List<EmployeeWorkingPattern__c> patterns = new List<EmployeeWorkingPattern__c>();

        try{
            patterns = [ SELECT 
                    Employee__c, EndDate__c, Friday__c, Id, Monday__c,   Saturday__c, StartDate__c, Sunday__c, Thursday__c, Tuesday__c, Wednesday__c 
                FROM 
                    EmployeeWorkingPattern__c 
                WHERE 
                    Employee__c IN: userIds ];
            if(isTest) throw new RuntimeExceptionHelper.testThrownException('Exception thrown while testing');
        }catch(Exception e){
            System.debug('No patterns exist: ' + e);
            RuntimeExceptionHelper.logException(e);
        }

        return patterns;
    }


    /*
    getUserWorkingPatternMapByIdAndPeriod
    ------------------------
    Purpose: To get a map of working patterns based on a set of users' Ids that are active between two dates with the Id as key.
    Input: A set of Ids, startDate, endDate
    Output: A map of lists of EmployeeWorkingPattern__c records with user Id as key
    */
    public static Map<Id, List<EmployeeWorkingPattern__c>> getUserWorkingPatternMapByIdAndPeriod(Set<Id> userIds, Date startDate, Date endDate ){
    
        Map<Id, List<EmployeeWorkingPattern__c>> patternMap = new Map<Id, List<EmployeeWorkingPattern__c>>();   
        List<EmployeeWorkingPattern__c> patterns = new List<EmployeeWorkingPattern__c>();
        
        try{
            patterns = [ SELECT 
                    Employee__c, EndDate__c, Friday__c, Id, Monday__c,   Saturday__c, StartDate__c, Sunday__c, Thursday__c, Tuesday__c, Wednesday__c
                FROM 
                    EmployeeWorkingPattern__c 
                WHERE 
                    Employee__c IN: userIds 
                AND 
                    StartDate__c <=: endDate
                AND
                    EndDate__c >=: startDate];
            if(isTest) throw new RuntimeExceptionHelper.testThrownException('Exception thrown while testing');
        }catch(Exception e){
            System.debug('No patterns exist within the time period of ' + startDate + ' AND ' + endDate +': ' + e);
            RuntimeExceptionHelper.logException(e);
        }

        if(!Utilities.isNullOrEmpty(patterns)){
            for( Id id : userIds ){
                List<EmployeeWorkingPattern__c> tempList = new List<EmployeeWorkingPattern__c>();
                for(EmployeeWorkingPattern__c p : patterns ){
                    if(p.Employee__c == id){
                        tempList.add(p);
                    }
                }
                patternMap.put(id,tempList);
            }
        }   
        return patternMap;
    }

    /*
    getUserWorkingPatternMapActiveToday
    ------------------------
    Purpose: To get all EmployeesWorkingPattern__c records for the Date theDate 
    Input: A date
    Output: A list of EmployeeWorkingPattern__c records
    */
    public static List<EmployeeWorkingPattern__c> getUserWorkingPatternMapActiveToday( Date theDate ) {

        List<EmployeeWorkingPattern__c> result = new List<EmployeeWorkingPattern__c>();
        Set<String> weekend = new Set<String>{'Saturday','Sunday'};
        
        // Do not run for weekends. 
        // If a working pattern contains "normal" weekends we do not need to specify absence on weekends.
        // If needed this can be turned to a boolean parameter.
         
        if(!weekend.contains(CalendarHelper.getDayName(theDate.year(), theDate.month(), theDate.day(), 4))) {
            for( EmployeeWorkingPattern__c p : [ SELECT 
                                                    Employee__c, Employee__r.Name, Employee__r.Title, EndDate__c, Friday__c, Id, Monday__c, Saturday__c, StartDate__c, 
                                                    Sunday__c, Thursday__c, Tuesday__c, Wednesday__c, Employee__r.IsActive
                                                FROM 
                                                    EmployeeWorkingPattern__c 
                                                WHERE 
                                                    StartDate__c <=: theDate
                                                AND
                                                    EndDate__c >=: theDate
                                                AND
                                                    Employee__r.IsActive = true
                                                    ] ) {
                List<EmployeeWorkingPattern__c> tempList = new List<EmployeeWorkingPattern__c>{ p };
                System.debug(LoggingLevel.DEBUG, '=== tempList: '+tempList);
                if(!EmployeeWorkingPatternManager.isWorkingDay(tempList,theDate)) {
                    System.debug(LoggingLevel.DEBUG, '=== got through !EmployeeWorkingPatternManager check');
                    result.add(p);
                }
            }
             
        }
        return result;
    }

    /*
    getUserWorkingPatternByIdAndPeriod
    ------------------------
    Purpose: To get a list of working patterns based on a set of users' Ids that are active between two dates. 
    Input: Set of Ids, startDate, endDate
    Output: List of EmployeeWorkingPattern__c records
    */
    public static List<EmployeeWorkingPattern__c> getUserWorkingPatternByIdAndPeriod(Set<Id> userIds, Date startDate, Date endDate ){
        // Returns a list of working patterns based on a set of users' Ids that are active between two dates.
        List<EmployeeWorkingPattern__c> patterns = new List<EmployeeWorkingPattern__c>();

        try{
            patterns = [ SELECT 
                    Employee__c, EndDate__c, Friday__c, Id, Monday__c,   Saturday__c, StartDate__c, Sunday__c, Thursday__c, Tuesday__c, Wednesday__c
                FROM
                    EmployeeWorkingPattern__c 
                WHERE
                    Employee__c IN: userIds
                AND
                    StartDate__c <=: endDate
                AND
                    EndDate__c >=: startDate];
            if(isTest) throw new RuntimeExceptionHelper.testThrownException('Exception thrown while testing');
        }catch(Exception e){
            System.debug('No patterns exist within the time period of ' + startDate + ' AND ' + endDate +': ' + e);
            RuntimeExceptionHelper.logException(e);
        }	
        return patterns;
    }

    /*
    getUsersWithWorkingPatternByPeriod
    ------------------------
    Purpose: To get a set of ids for those users with an active working pattern within the given period
    Input: Year and month integers
    Output: A set of user ids
    */
    public static Set<Id> getUsersWithWorkingPatternByPeriod( Integer year, Integer month ) {
        Set<Id> result = new Set<Id>();
        Date first = CalendarHelper.firstDateInMonth(year, month);
        Date last = CalendarHelper.lastDateInMonth(year, month);
        
        for( EmployeeWorkingPattern__c p : [ SELECT 
                                                Employee__c, Employee__r.Name, Employee__r.Title, EndDate__c, Friday__c, Id, Monday__c, Saturday__c, StartDate__c, 
                                                Sunday__c, Thursday__c, Tuesday__c, Wednesday__c, Employee__r.IsActive
                                            FROM 
                                                EmployeeWorkingPattern__c 
                                            WHERE 
                                                StartDate__c <=: last
                                            AND
                                                EndDate__c >=: first
                                            AND
                                                Employee__r.IsActive = true] ) {
                result.add(p.Employee__c);
            }
             
        return result;
    }

    /*
    isWorkingDay
    ------------------------
    Purpose: Check if a specific day is a working day taking EmployeeWorkingPattern__c into consideration 
                Assumes patterns owned by single employee.
    Input: A list of EmployeeWorkingPattern__c records, a date
    Output: Boolean value, true if is working day
    */
    public static Boolean isWorkingDay(List<EmployeeWorkingPattern__c> patterns, Date currentDay){
        
        String dayName = CalendarHelper.getDayName(currentDay.year(), currentDay.month(), currentDay.day(), 4);
        System.debug('\n===========================\ndayName: ' + dayName );
        Boolean result = false;
        sObject sPattern;
        for(EmployeeWorkingPattern__c p : patterns ){
            if(p.StartDate__c <= currentDay && p.EndDate__c >= currentDay){
                sPattern = p;
            }
        }
        System.debug('sPattern: ' + sPattern);
        if(sPattern!=null) {
            result = (Boolean)sPattern.get(dayName+'__c');
        }
        
        return result;
    }
}