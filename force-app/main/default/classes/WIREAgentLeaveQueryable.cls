/*
Name:  WIREAgentLeaveQueryable.cls
Copyright © 2018  Golfbreaks
======================================================
======================================================
Purpose:
-------

WIRE Plug-in - Agent Leave logic.

======================================================
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2018-07-08  Initial development.
1.1  Mark Cane&    2018-07-31  New interface definition.
1.2  J Radcliffe   2020-01-14  Globalised the solution (ensured leave respects local timezone).
1.3  J Radcliffe   2020-02-06  New method getAgentsOnCompanyHoliday 
2.1  J Radcliffe   2020-05-11  Change in logic. If localDT < routingExclusionStartHour check todays Leave. If localDT > routingExclusionStartHour check tomorrow's Leave
2.2  J Radcliffe   2020-05-13  Implements GBWire.IAgentLeaveQueryable to GBWire.IAgentLeaveQueryable2
2.3  J Radcliffe   2023-05-03  Add support for half day leave.
2.4  J Radcliffe   2023-05-22  Optimization. No need to check for two leave requests for the same day. This is implicitly handled when leave is evaluated individually
2.5  J Radcliffe   2023-01-29  Collect leave data into maps (agentsOnLeaveMap & agentsOnCompanyLeaveMap) for reference by dependent classes.
*/
global without sharing class WIREAgentLeaveQueryable implements GBWire.IAgentLeaveQueryable2 { 
//global with sharing class WIREAgentLeaveQueryable {
       
    @testVisible private static Datetime currentDateTimeOverride;//1.1 used in unit testing to remove depending on the current time.    

    public Map<Id,Leave__c> agentsOnLeaveMap = new Map<Id,Leave__c>();//2.5+
    public Map<Id,PublicHoliday__c> agentsOnCompanyLeaveMap = new Map<Id,PublicHoliday__c>();//2.5+

    /*  ======================================================
        Method: getAgentsOnLeave
        Params: Set of Agents to check
                isIncludeNextDay - include Agents onleave on the next day.
                routingExclusionStartHour - if an Agent is on leave the next day stop routing at this hour on the previous day. 
        Returns: Set of Agents (User Ids) on leave
        Purpose: Local leave calculation.
        
        Approved Lead periods only.
        Half days ignored.
                  
        ----------------
        Revision History
        ----------------
        Ver. Author        Date        Detail
        1.0  J Radcliffe   2020-01-14  Initial development.
        ======================================================
    */  
    global Set<Id> getAgentsOnLeave(Set<Id> agentIds, Boolean isIncludeNextDay, Integer routingExclusionStartHour){

        //APPROACH -
        //We need to calculate the date for the local users
        //We need to check their local d/t against the routingExclusionStartHour to determine whether to check today's or tomorrow's leave 
        //We then need to query all approved leave for yesterday, today and tomorrow to ensure we cover a full 24 hour period for all timezones
        //If the current date for the employee is within the leave window, the agent should be considered 'on leave' and returned to the caller
        
        //2.3+ Consider half day holidays as follows:
        //AM__c = On Leave in the AM
        //PMStart__c = On Leave in the PM
        //PMReturn__c = Returning to work in the afternoon of the end date.

        Set<Id> agentsOnLeave = new Set<Id>();  
        agentsOnLeaveMap = new Map<Id,Leave__c>();
        
        try{

            Date startDate = Date.today()-1;// CHANGED (-1) Get Yesterdays, Todays
            Date endDate = Date.today()+1;//CHANGED (+1) And tomorrows
            
            //Retrieve the current date/time for each user based on their local timezones
            Map<Id,DateTime> agentIdsWithLocalDateTime = TimeZoneHelper.getAgentsLocalDateTime(agentIds,currentDateTimeOverride);        

            //2.3+ Retrieve custom settings
            GBWire__RoutingEngineSettings__c settings = GBWire__RoutingEngineSettings__c.getOrgDefaults();
            //At what time should work items stop being routed to agents who will be absent in the afternoon?
            Integer halfDayRoutingStopHour = (settings?.GBWire__HalfDayAvailabilityStopHour__c != null)?Integer.valueOf(settings.GBWire__HalfDayAvailabilityStopHour__c):11;
            //At what time should work items start being routed to agents returning to work in the afternoon?
            Integer halfDayRoutingStartHour = (settings?.GBWire__HalfDayAvailabilityStartHour__c != null)?Integer.valueOf(settings.GBWire__HalfDayAvailabilityStartHour__c):13;
            
            //A map of agents ids with a list of every day (date) where the agent has more than one half day leave request for that day (i.e. it is a full day's leave)
            //Map<Id,List<Date>> agentsWithDoubleHalfDayLeave = getAgentsWithDoubleHalfDayLeave(agentIds,startDate,endDate); //2.4-

            // ... on leave today.
            DateTime employeeLocalDateTime;
            Date employeeLocalDate;
            Date employeelocalDateTomorrow;//2.1+
            DateTime nextDayAvailabilityStartDateTime;//2.1+ 
            Boolean isOnLeaveAM;//Indicates whether the employee is on leave in the morning - 2.3+
            Boolean isOnLeavePM;//Indicates whether the employee is on leave in the afternoon - 2.3+
            Integer currentHourLocalTime;//The current hour according to the employee (12:47pm = 12) - 2.3+
            Boolean isHalfDayHoliday;
            
            for (Leave__c leavePeriod : [select Id, Employee__c, Employee__r.Name, StartDate__c, EndDate__c, AM__c, PMStart__c, PMReturn__c, FormattedEndDate__c  from Leave__c 
                                            where Employee__c in: agentIds
                                            and StartDate__c <=: endDate
                                            and EndDate__c >=: startDate
                                            and Status__c = 'Approved'
                                        order by Employee__c]){  

                isOnLeaveAM = (leavePeriod.AM__c)?true:false;//2.3+
                isOnLeavePM = (leavePeriod.PMStart__c)?true:false;//2.3+
                isHalfDayHoliday = (!isOnLeaveAM || !isOnLeavePM)?true:false;//Is this a half day leave request?

                //If the user has more than one half day's leave request for the same date, treat as fully absent that day (half day = false).
                //if(isHalfDayHoliday && agentsWithDoubleHalfDayLeave.containsKey(leavePeriod.Employee__c) && agentsWithDoubleHalfDayLeave.get(leavePeriod.Employee__c).contains(leavePeriod.StartDate__c)) isHalfDayHoliday = false; //2.4-

                //Identify current date/time according to the employee and the employee's next day availability cut-off d/t
                employeeLocalDateTime = agentIdsWithLocalDateTime.get(leavePeriod.Employee__c);
                if(routingExclusionStartHour != null) nextDayAvailabilityStartDateTime = Datetime.newInstanceGmt(employeeLocalDateTime.year(),employeeLocalDateTime.month(),employeeLocalDateTime.day(),Integer.valueOf(routingExclusionStartHour),0,0);//2.1+
                
                //Identify the current (and following) date according to the employee
                employeeLocalDate = Date.newInstance(employeeLocalDateTime.year(), employeeLocalDateTime.month(), employeeLocalDateTime.day());
                employeelocalDateTomorrow = employeeLocalDate.addDays(1);//2.1+
                
                if(!isIncludeNextDay || nextDayAvailabilityStartDateTime == null || employeeLocalDateTime < nextDayAvailabilityStartDateTime){//2.1+ - Determine whether to check today's holiday or tomorrow's based on configured threshold
                    
                    //2.3+
                    currentHourLocalTime = employeeLocalDateTime.hourGmt();

                    //If the employees current date sits within the leave window, they can be considered 'on leave' and should be added to the return set
                    if(leavePeriod.StartDate__c<= employeeLocalDate
                    && leavePeriod.EndDate__c>= employeeLocalDate ){ 
                        
                        //2.3+ Check against DT of the user (.hourGMT() hour of the day) vs the half day config i.e. is it before or after 12 pm local time and how does that compare to the leave half day config?
                        if(isHalfDayHoliday){

                            system.debug('isOnLeaveAM > '+isOnLeaveAM);
                            system.debug('isOnLeavePM > '+isOnLeavePM);
                            system.debug('isHalfDayHoliday > '+isHalfDayHoliday);
                            system.debug('currentHourLocalTime > '+currentHourLocalTime);
                            system.debug('halfDayRoutingStartHour > '+halfDayRoutingStartHour);

                            //If the agent is on leave in the am (returning in the pm) and the current time is AFTER the pm routing start time, don't add to absentee list (they should start receiving new work items)
                            if(isOnLeaveAM && !isOnLeavePM && currentHourLocalTime >= halfDayRoutingStartHour) continue;
                            //If the agent is on leave in the pm and the current time is before the routing stop time i.e. they are still working that morning and should continue to receive new work items, don't add to absentee list.
                            if(isOnLeavePM && !isOnLeaveAM && currentHourLocalTime < halfDayRoutingStopHour) continue;
                        }
                        agentsOnLeave.add(leavePeriod.Employee__c);
                        agentsOnLeaveMap.put(leavePeriod.Employee__c,leavePeriod);//2.5+
                    }     
                }else{//2.1+
                    //If the employees date tomorrow sits within the leave window, they can be considered 'on leave' and should be added to the return set
                    if(leavePeriod.StartDate__c<= employeelocalDateTomorrow
                    && leavePeriod.EndDate__c>= employeelocalDateTomorrow ){ 
                        //2.3 - If they are not on leave in the am, continue (don't add to absentee list)
                        if(!isOnLeaveAM) continue;
                        agentsOnLeave.add(leavePeriod.Employee__c);
                        agentsOnLeaveMap.put(leavePeriod.Employee__c,leavePeriod);//2.5+
                    }    
                }                     
            }  

            return agentsOnLeave;//2.1+

            /* 2.1-
            System.debug(LoggingLevel.ERROR,'agentsOnLeave TODAY:'+agentsOnLeave);     
            if (isIncludeNextDay==null || !isIncludeNextDay) return agentsOnLeave;
                    
            System.debug(LoggingLevel.ERROR,'routingExclusionStartHour:'+routingExclusionStartHour);
            
            Map<Id,Date> agentIdsWithTomorrowDate = new Map<Id,Date>();

            if (routingExclusionStartHour!=null && routingExclusionStartHour>0){


                //APPROACH
                //Next Availability Start DT is a static value representing the hour from which tomorrows leave should be assessed (do not route work items to users who are on leave the next day after 'X' hour)
                //We need to assess the local time and see whether the current local time is less than the time of the cut off hour for their timezone.
                //If the local date time is greater than the cut of time, the user will need to be added to the list and their next day availability will be reviewed
            
                DateTime nextDayAvailabilityStartDt;
                Datetime localTimeDt;
                DateTime localTimeNextDayDT;

                for(Id agentId : agentIds){
                    localTimeDt = (agentIdsWithLocalDateTime.containsKey(agentId))? agentIdsWithLocalDateTime.get(agentId):system.now();//If unidentifiable default to UTC
                    nextDayAvailabilityStartDt = Datetime.newInstanceGmt(localTimeDt.year(),localTimeDt.month(),localTimeDt.day(),Integer.valueOf(routingExclusionStartHour),0,0);
                    if(nextDayAvailabilityStartDt>localTimeDt) continue;

                    //Next Day Availability Check Required
                    localTimeNextDayDT = localTimeDt.addDays(1);
                    agentIdsWithTomorrowDate.put(agentId,date.newinstance(localTimeNextDayDT.year(), localTimeNextDayDT.month(), localTimeNextDayDT.day()));
                }

                if(agentIdsWithTomorrowDate.keySet().size()==0) return agentsOnLeave;
                
            }
        
            //APPROACH 
            //We need to assess if they have any holiday on the following day (relative to the agent)

            startDate = Date.today();
            endDate = Date.today().addDays(2);      
            
            Date tomorrowsDate;
            for (Leave__c leavePeriod : [select Id, Employee__c, StartDate__c , EndDate__c from Leave__c 
                                            where Employee__c in: agentIdsWithTomorrowDate.keySet()
                                            and StartDate__c <=: endDate
                                            and EndDate__c >=: startDate
                                            and Status__c = 'Approved'
                                            and Employee__c != null
                                        order by Employee__c]){     
                tomorrowsDate = agentIdsWithTomorrowDate.get(leavePeriod.Employee__c);
                if(leavePeriod.StartDate__c<=tomorrowsDate
                && leavePeriod.EndDate__c>=tomorrowsDate){
                    agentsOnLeave.add(leavePeriod.Employee__c);
                }
            }       
            System.debug(LoggingLevel.ERROR,'agentsOnLeave NEXTDAY:'+agentsOnLeave);

            
            return agentsOnLeave;*/
        
        }catch(Exception e){
            PlatformLogManager.logExceptions(e, 'WIREAgentLeaveQueryable', 'getAgentsOnLeave');
            return null;
        }

        return agentsOnLeave;

    }

    //2.3+ This method retursn a map of user id and the days in which they have two (half day) leave requests for the same day (and should be treated as absent all day)
    /* 2.4- This will be implicitly handled when the leave requests are evaluated individually. 
    private static Map<Id,List<Date>> getAgentsWithDoubleHalfDayLeave(Set<Id> agentIds, Date startDate, Date endDate){
        Map<Id,List<Date>> agentIdsToDoubleHalfDayDatesMap = new Map<Id,List<Date>>();

        if(agentIds == null || startDate == null || endDate == null) return agentIdsToDoubleHalfDayDatesMap;

        List<AggregateResult> results = [select Employee__c employeeId, StartDate__c leaveDate, Count(Id) from Leave__c Where
                                            StartDate__c <= :startDate
                                            and EndDate__c >= :endDate
                                            and Status__c = 'Approved'
                                            and ((AM__c = false and PMStart__c = true) or (AM__c = true and PMStart__c = false))//Half day leave only
                                            Group By Employee__c, StartDate__c //Per agent, per leave date
                                            Having Count(Id) >1//More than 1 leave requests for a given date
                                        ];
        if(results.size()>0){
            for(AggregateResult result : results){
                Id agentId = (Id)result.get('employeeId');
                Date leaveDate = (Date)result.get('leaveDate');
                if(agentId == null || leaveDate == null) continue;
                if(!agentIdsToDoubleHalfDayDatesMap.containsKey(agentId)) agentIdsToDoubleHalfDayDatesMap.put(agentId,new List<Date>());
                agentIdsToDoubleHalfDayDatesMap.get(agentId).add(leaveDate);
            }
        }

        return agentIdsToDoubleHalfDayDatesMap;
    }*/


    /*  ======================================================
        Method: getAgentsOnCompanyHoliday
        Params: Set of Agents to check
                isIncludeNextDay - include Agents on Company Leave on the next day.
                routingExclusionStartHour - if an Agent is on Company leave the next day stop routing at this hour on the previous day. 
        Returns: Set of Agents (User Ids) on leave
        Purpose: Local leave calculation.
        
        Approved Lead periods only.
        Half days ignored.
                  
        ----------------
        Revision History
        ----------------
        Ver. Author        Date        Detail
        1.0  J Radcliffe   2020-01-14  Initial development.
        ======================================================
    */  
    global Set<Id> getAgentsOnCompanyHoliday(Set<Id> agentIds, Boolean isIncludeNextDay, Integer routingExclusionStartHour){
        

        //Get Active Leave Years to Get Holiday Group - Store in Map<agentId,GroupId>()
        //Get Local Date/Time for Users
        //Query Public Holiday yest,today and tomorrow - Store in Map<GroupId,List<UTCDate>>
        //Loop through users
            //Get Holiday Group
            //Get Holiday
            //Compare Holiday Date with Agent Local Date

        Set<Id> agentsOnCompanyLeave = new Set<Id>();      
        agentsOnCompanyLeaveMap = new Map<Id,PublicHoliday__c>();

        //2.5+
        Map<Id,Map<Date,PublicHoliday__c>> publicHolidayGroupToDateAndHolidayMap = new Map<Id,Map<Date,PublicHoliday__c>>();

        try{

            //Retrieve the current date/time for each user based on their local timezones
            Map<Id,DateTime> agentIdsWithLocalDateTime = TimeZoneHelper.getAgentsLocalDateTime(agentIds,currentDateTimeOverride);

            //Get Active Leave Years to identify Agent Holiday Groups
            Map<Id,EmployeeLeaveYear__c> userIdsWithActiveLeaveYear = EmployeeLeaveYearManager.getEmployeeLeaveYearsByUsersAndDateValue(agentIds,System.today()); 
            Map<Id,Id> agentIdWithHolidayGroup = new Map<Id,Id>();
            for(EmployeeLeaveYear__c ely : userIdsWithActiveLeaveYear.values()){
                if(ely.Employee__c != null && ely.PublicHolidayGroup__c != null && !agentIdWithHolidayGroup.containsKey(ely.Employee__c)) agentIdWithHolidayGroup.put(ely.Employee__c,ely.PublicHolidayGroup__c);
            }

            system.debug('agentIdWithHolidayGroup>'+agentIdWithHolidayGroup);

            //Query yest,today and tomorrow Company Holiday for the relevant groups - Store in Map<Id,List<Date>>
            Date yesterdaysDate = Date.today()-1;//Get Yesterday's, Today's
            Date tomorrowsDate = Date.today()+2;//Tomorrow's and the next days Holiday (Spanning enough days to cover all timezones for the current and next days date)
            Map<Id,List<Date>> holidayGroupIdWithHolidayDates = new Map<Id,List<Date>>();
            for (PublicHoliday__c compHol : [select Id, Date__c, PublicHolidayGroup__c from PublicHoliday__c 
                                            where PublicHolidayGroup__c in: agentIdWithHolidayGroup.values()
                                            and Date__c <=: tomorrowsDate
                                            and Date__c >=: yesterdaysDate
                                            order by PublicHolidayGroup__c]){     
                
                if(!holidayGroupIdWithHolidayDates.containsKey(compHol.PublicHolidayGroup__c)) holidayGroupIdWithHolidayDates.put(compHol.PublicHolidayGroup__c,new List<Date>());      
                
                //2.5+
                if(!publicHolidayGroupToDateAndHolidayMap.containsKey(compHol.PublicHolidayGroup__c)) publicHolidayGroupToDateAndHolidayMap.put(compHol.PublicHolidayGroup__c,new Map<Date,PublicHoliday__c>());
                if(!publicHolidayGroupToDateAndHolidayMap.get(compHol.PublicHolidayGroup__c).containsKey(compHol.Date__c)) publicHolidayGroupToDateAndHolidayMap.get(compHol.PublicHolidayGroup__c).put(compHol.Date__c,compHol);                 
                
                holidayGroupIdWithHolidayDates.get(compHol.PublicHolidayGroup__c).add(compHol.Date__c);                                
            }     

            system.debug('holidayGroupIdWithHolidayDates>'+holidayGroupIdWithHolidayDates);

            //Assess whether the agent is on Company Leave
            Id publicHolidayGroupId;
            DateTime employeeLocalDateTime;
            Date employeeLocalDate;
            Date employeelocalDateTomorrow;//2.1+
            DateTime nextDayAvailabilityStartDateTime;//2.1+ 
            for(Id agentId : agentIds){
                if(!agentIdWithHolidayGroup.containsKey(agentId)) continue; //Continue if Public Holiday Group could not be identified
                publicHolidayGroupId = agentIdWithHolidayGroup.get(agentId);
                if(!holidayGroupIdWithHolidayDates.containsKey(publicHolidayGroupId)) continue; //Continue if there is no holiday for this group 
                //Identify current date/time for agent (according to local date/time) and Next Day Cut-off Date/Time
                employeeLocalDateTime = (agentIdsWithLocalDateTime.containsKey(agentId))? agentIdsWithLocalDateTime.get(agentId):system.now();//If unidentifiable default to UTC
                if(routingExclusionStartHour != null) nextDayAvailabilityStartDateTime = Datetime.newInstanceGmt(employeeLocalDateTime.year(),employeeLocalDateTime.month(),employeeLocalDateTime.day(),Integer.valueOf(routingExclusionStartHour),0,0);//2.1+
                
                //Use the local date/time to identify the current (and tomorrow's) date according to the employee
                employeeLocalDate = Date.newInstance(employeeLocalDateTime.year(), employeeLocalDateTime.month(), employeeLocalDateTime.day());
                employeelocalDateTomorrow = employeeLocalDate.addDays(1);//2.1+

                if(!isIncludeNextDay || nextDayAvailabilityStartDateTime == null || employeeLocalDateTime < nextDayAvailabilityStartDateTime){//2.1+ - Determine whether to check today's holiday or tomorrow's based on configured threshold
                    if(!holidayGroupIdWithHolidayDates.get(publicHolidayGroupId).contains(employeeLocalDate)) continue; //Continue if none of the holiday falls on the current date (for the agent)
                    agentsOnCompanyLeave.add(agentId);//Agent is on Company Leave Today
                    agentsOnCompanyLeaveMap.put(agentId,publicHolidayGroupToDateAndHolidayMap.get(publicHolidayGroupId).get(employeeLocalDate));//2.5+
                }else{//2.1+
                    if(!holidayGroupIdWithHolidayDates.get(publicHolidayGroupId).contains(employeelocalDateTomorrow)) continue; //Continue if none of the holiday falls on tomorrow's date (for the agent)
                    agentsOnCompanyLeave.add(agentId);//Agent is on Company Leave Today
                    agentsOnCompanyLeaveMap.put(agentId,publicHolidayGroupToDateAndHolidayMap.get(publicHolidayGroupId).get(employeelocalDateTomorrow));//2.5+
                }
            }

            return agentsOnCompanyLeave;//2.1+

            /*2.1-
            System.debug(LoggingLevel.ERROR,'agentsOnCompanyLeave TODAY:'+agentsOnCompanyLeave);     
            if (isIncludeNextDay==null || !isIncludeNextDay) return agentsOnCompanyLeave;
                    
            System.debug(LoggingLevel.ERROR,'routingExclusionStartHour:'+routingExclusionStartHour);
            

            Map<Id,Date> agentIdsWithTomorrowDate = new Map<Id,Date>();

            if (routingExclusionStartHour!=null && routingExclusionStartHour>0){
                
                DateTime nextDayAvailabilityStartDt;
                Datetime localTimeDt;
                DateTime localTimeNextDayDT;

                for(Id agentId : agentIds){
                    
                    localTimeDt = (agentIdsWithLocalDateTime.containsKey(agentId))? agentIdsWithLocalDateTime.get(agentId):system.now();//If unidentifiable default to UTC
                    nextDayAvailabilityStartDt = Datetime.newInstanceGmt(localTimeDt.year(),localTimeDt.month(),localTimeDt.day(),Integer.valueOf(routingExclusionStartHour),0,0);
                    if(nextDayAvailabilityStartDt>localTimeDt) continue;

                    //Next Day Availability Check Required
                    localTimeNextDayDT = localTimeDt.addDays(1);
                    agentIdsWithTomorrowDate.put(agentId,date.newinstance(localTimeNextDayDT.year(), localTimeNextDayDT.month(), localTimeNextDayDT.day()));
                }

                if(agentIdsWithTomorrowDate.keySet().size()==0) return agentsOnCompanyLeave;                
            }

            //Assess whether the agent is on Company Leave
            Date tomorrowDateLocal;
            for(Id agentId : agentIds){
                if(!agentIdsWithTomorrowDate.containsKey(agentId)) continue; //Continue if Agent is not in included in the check for next day availability (not in the agentIdsWithTomorrowDate map) 
                if(!agentIdWithHolidayGroup.containsKey(agentId)) continue; //Continue if Public Holiday Group could not be identified
                publicHolidayGroupId = agentIdWithHolidayGroup.get(agentId);
                if(!holidayGroupIdWithHolidayDates.containsKey(publicHolidayGroupId)) continue; //Continue if there is no holiday for this group 
                //Retrieve tomorrow's date for agent according to local date/time
                tomorrowDateLocal = agentIdsWithTomorrowDate.get(agentId);
                if(!holidayGroupIdWithHolidayDates.get(publicHolidayGroupId).contains(tomorrowDateLocal)) continue; //Continue if none of the holiday falls on the tomorrow's date (for the agent's timezone)
                agentsOnCompanyLeave.add(agentId);//Agent is on Company Leave Tomorrow
            }

            
            return agentsOnCompanyLeave;*/

        }catch(Exception e){
            PlatformLogManager.logExceptions(e, 'WIREAgentLeaveQueryable', 'getAgentsOnCompanyHoliday');
        }

        return agentsOnCompanyLeave;        

    }

}