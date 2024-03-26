/*
Name:  TimeZoneHelper.cls
Copyright © 2018  Golfbreaks
======================================================
======================================================
Purpose:
-------

Helper class for common methods and actions related
to timezone calculations 

======================================================
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2020-01-15  Initial development.
*/
public without sharing class TimeZoneHelper{
    
    public static Map<Id,DateTime> getAgentsLocalDateTime(Set<Id> agentIds){
        return getAgentsLocalDateTime(agentIds, System.now());
    }


    //This method accepts a date/time and returns a map of agent Ids with their corresponding local time 
    public static Map<Id,DateTime> getAgentsLocalDateTime(Set<Id> agentIds, DateTime compareDateTime){

        system.debug('compareDateTime: '+compareDateTime);

        compareDateTime = (compareDateTime == null)? system.now():compareDateTime;

        Map<Id,DateTime> agentIdsWithLocalDateTime = new Map<Id,DateTime>();

        TimeZone tz;
        Integer offSet;
        DateTime localDateTime;
        for(User u : [Select Id, TimeZoneSidKey From User Where Id In :agentIds]){
            tz = TimeZone.getTimeZone(u.TimeZoneSidKey);
            offSet = tz.getOffset(compareDateTime);
            localDateTime = compareDateTime.addSeconds(offSet/1000);
            agentIdsWithLocalDateTime.put(u.Id,localDateTime);
        }
        return agentIdsWithLocalDateTime;
    }

}