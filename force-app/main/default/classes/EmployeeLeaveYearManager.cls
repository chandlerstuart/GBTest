/*
Name:  LeaveManager.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Manager class for EmployeeLeaveYear__c

======================================================
======================================================
History
------- 
Ver. Author                Date                  Detail
1.0  Halldór Örn        2014-04-28      Initial development.
1.1  J Radcliffe        2020-01-22      getEmployeeLeaveYearsByUsersAndDateValue - New method to return Active Employee Leave Years for the specified users based on Date param
1.2  J Radcliffe        2021-01-20      Switch to without sharing - Users require the ability to see ELY in calendar view but should not be given access to the records themselves.
1.3  J Radcliffe        2023-07-17      New query field for getEmployeeLeaveYearsByUsersAndDateValue method (WellbeingLeavePeriod__c)
*/
public without sharing class EmployeeLeaveYearManager {

    public static Boolean isTest = false;
    /*
    getEmployeeLeaveYearByUserId
    ------------------------
    Purpose: Get a list of Employee Leave Years linked to a user's Id
    Input: User id 
    Output: List of EmployeeLeaveYear__c records
    */
    public static List<EmployeeLeaveYear__c> getEmployeeLeaveYearByUserId(String userId){
        
        List<EmployeeLeaveYear__c> result = new List<EmployeeLeaveYear__c>();
        try{
            result = [  SELECT 
                            Id, Name, CarriedDays__c, Employee__c, ExtraDays__c, SickDaysAllotted__c, SickDaysApproved__c, SickDaysRemaining__c, StandardDays__c, SickDays__c, HolidaysAllotted__c, HolidaysApproved__c, HolidaysRemaining__c, Year__c
                        FROM EmployeeLeaveYear__c
                        WHERE
                            Employee__c =: userId
                        ];
            if(isTest) throw new RuntimeExceptionHelper.testThrownException('Exception thrown while testing');
        }catch(Exception e){
            System.debug('No EmployeeLeaveYear__c with userId '+ userId +': ' + e);
            RuntimeExceptionHelper.logException(e);
        }
        return result;
    }   

    /*
    getEmployeeLeaveYearByUserIdAndYear
    ------------------------
    Purpose: Get an Employee Leave Year linked to a user's Id for a specified year
    Input: User Id, String value of year
    Output: Output: EmployeeLeaveYear__c record
    */
    public static EmployeeLeaveYear__c getEmployeeLeaveYearByUserIdAndYear(String userId, String year){

        EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c();
        try{
            leaveYear = [   SELECT 
                                Id, Name, CarriedDays__c, Employee__c, ExtraDays__c, SickDaysAllotted__c, SickDaysApproved__c, SickDaysRemaining__c, StandardDays__c, SickDays__c, HolidaysAllotted__c, HolidaysApproved__c, HolidaysRemaining__c, Year__c
                            FROM EmployeeLeaveYear__c
                            WHERE
                                Employee__c =: userId
                            AND 
                                Year__c =: year
                            LIMIT 1
                            ];
            if(isTest) throw new RuntimeExceptionHelper.testThrownException('Exception thrown while testing');
        }catch(Exception e){
            String retStr = 'No Leave Year for userid '+ userId +' and Year ' + year + ': ' + e; 
            System.debug(retStr);
            //throw new RuntimeExceptionHelper.testThrownException(retStr);
            //RuntimeExceptionHelper.logException(e);
        }
        return leaveYear;
    }

    /*
    getEmployeeLeaveYearByUserIdAndYear
    ------------------------
    Purpose: Get a list of Employee Leave Years linked to a set of users' Ids and a specified year
    Input: User id, String value of year
    Output: List of EmployeeLeaveYear__c records
    */  
    public static List<EmployeeLeaveYear__c> getEmployeeLeaveYearByUserIdAndYear(Set<ID> userIds, String year){

        List<EmployeeLeaveYear__c> leaveYears = new List<EmployeeLeaveYear__c>();
        try{
            leaveYears = [  SELECT 
                                Id, Name, CarriedDays__c, Employee__c, ExtraDays__c, SickDaysAllotted__c, SickDaysApproved__c, SickDaysRemaining__c, StandardDays__c, SickDays__c, HolidaysAllotted__c, HolidaysApproved__c, HolidaysRemaining__c, Year__c
                            FROM EmployeeLeaveYear__c
                            WHERE
                                Employee__c IN: userIds
                            AND 
                                Year__c =: year
                            ];
            if(isTest) throw new RuntimeExceptionHelper.testThrownException('Exception thrown while testing');
        }catch(Exception e){
            String retStr = 'No Leave Years for users '+ userIds +' and Year ' + year + ': ' + e;
            System.debug(retStr);
            //throw new RuntimeExceptionHelper.testThrownException(retStr);
            //RuntimeExceptionHelper.logException(e);
        }
        return leaveYears;
    }   

    /*
    getEmployeeLeaveYearsByUserIdAndYears
    ------------------------
    Purpose: Get a map of Employee Leave Years linked to a set of users' Ids and Set of years
    Input: User id, List of string values of years
    Output:  Map of Employee Leave Years, Year used as key
    */  
    public static Map<String,EmployeeLeaveYear__c> getEmployeeLeaveYearsByUserIdAndYears(String userId, List<String> years){
        
        Map<String,EmployeeLeaveYear__c> leaveMap = new Map<String,EmployeeLeaveYear__c>();
        List<EmployeeLeaveYear__c> leaveYears = new List<EmployeeLeaveYear__c>();
        try{
            leaveYears = [  SELECT 
                                Id, Name, CarriedDays__c, Employee__c, ExtraDays__c, SickDaysAllotted__c, SickDaysApproved__c, SickDaysRemaining__c, StandardDays__c, SickDays__c, HolidaysAllotted__c, HolidaysApproved__c, HolidaysRemaining__c, Year__c
                            FROM EmployeeLeaveYear__c
                            WHERE
                                Employee__c =: userId
                            AND 
                                Year__c IN: years                           
                            ];
                if(isTest) throw new RuntimeExceptionHelper.testThrownException('Exception thrown while testing');
            for(EmployeeLeaveYear__c l : leaveYears){
                leaveMap.put(l.Year__c, l);
            }
        }catch(Exception e){
                System.debug('No Leave Years for userid '+ userId +' and Years ' + years + ': ' + e);
                RuntimeExceptionHelper.logException(e);
        }
        return leaveMap;
    }

    //Returns Map of EmployeeLeaveYears active on the specified date with the corresponding Employee Id as the Map's Key - Globalised Equivalent for getEmployeeLeaveYearByUserIdAndYear method
    public static Map<Id,EmployeeLeaveYear__c> getEmployeeLeaveYearsByUsersAndDateValue(Set<Id> userIds, Date dateInput){
        try{
            Map<Id,EmployeeLeaveYear__c> userIdsWithLeaveYears = new Map<Id,EmployeeLeaveYear__c>();
            for(EmployeeLeaveYear__c ely : [Select Id, Year__c, StartDate__c, EndDate__c, PublicHolidayGroup__c, Employee__c, Lieu_Days_Holiday__c,Lieu_Days_Pay__c,
                                            StandardDays__c, CarriedDays__c, ExtraDays__c, HolidaysAllotted__c, HolidaysRemaining__c, EmployeeWorkingPattern__c, 
                                            SickDaysAllotted__c, SickDaysApproved__c, SickDaysRemaining__c, HolidaysApproved__c, WellnessDayLimit__c, WellbeingLeavePeriod__c//1.3~
                                            From EmployeeLeaveYear__c Where Employee__c In:userIds and StartDate__c <=:dateInput and EndDate__c >=:dateInput Order By EndDate__c DESC]){//Ensure the latest ELY floats to the top
                if(ely.Employee__c != null && !userIdsWithLeaveYears.containsKey(ely.Employee__c)) userIdsWithLeaveYears.put(ely.Employee__c,ely);
            }
            return userIdsWithLeaveYears;
        }catch(Exception e){
            PlatformLogManager.logExceptions(e, 'EmployeeLeaveYearManager', 'getEmployeeLeaveYearsByUsersAndDateValue');
            return null;
        }
    }


}