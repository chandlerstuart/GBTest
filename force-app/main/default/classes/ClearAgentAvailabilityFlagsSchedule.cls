/*
Name:  ClearAgentAvailabilityFlagsSchedule.cls
======================================================
======================================================
Purpose:
-------
To automate the clearing of the Weekend Availability flags
on Agent Profiles on a Monday morning. Removing the manual task
for the managers and mitigating any risk of unavailable 
agents remaining as 'available' the following weekend
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.1	 J Radcliffe   04-01-19		Initial Development
*/
global class ClearAgentAvailabilityFlagsSchedule implements Schedulable {
    global void execute(SchedulableContext SC) {
        //Query profiles with 'IsAsavailable' Sat/Sun set to true
        GBWire__AgentProfile__c[] profiles = [Select Id, GBWire__IsAvailableSaturday__c, GBWire__IsAvailableSunday__c From GBWire__AgentProfile__c Where GBWire__IsAvailableSaturday__c = true OR GBWire__IsAvailableSunday__c = true ];
        if(profiles.size()>0){
            //Set flags to false
            for(GBWire__AgentProfile__c ap : profiles){
                ap.GBWire__IsAvailableSaturday__c = false;
                ap.GBWire__IsAvailableSunday__c = false;
            }
        }
        try{
            //Update the Agent Profiles (allOrNone = false)
            database.update(profiles,false);
        }catch(exception e){
            //Log exceptions to the RoutingLogEntry object
            GBWire.RoutingLogHelper.insertLogEntry(e.getMessage(),e.getStackTraceString());
        }
    }
}