/*
Name: ScheduledEventSchedulable.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
This schedulable launches a chain of processors each handling
a Scheduled Event (Outbound Callout Configuration)

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2021-01-26  Initial development.
1.1  Mark Cane&    2021-06-22  Enhancements. Schedule Group support added.
1.2  Mark Cane&    2021-07-21  Bug fixes. getNextProcessingTimeGmtByScheduleGroup hour check now uses currentTimeGmt and not thisScheduledDateGmt.
1.3  Mark Cane&    2021-07-21  Bug fixes. jobToleranceSeconds implementation.
1.4  J Radcliffe   2023-11-14  Bug fixes. jobToleranceSeconds increased from 30 to 90 seconds.
*/
global without sharing class ScheduledEventSchedulable implements Schedulable{

    @TestVisible public static List<Id> scheduledEventIdsTest;
    @TestVisible private Integer jobToleranceSeconds = 90;//1.3+//1.4~
    @TestVisible private Integer jobScheduleStartDelaySeconds = 10;//1.3+
    
    global void execute(SchedulableContext sc) {

        try {

            System.abortJob(sc.getTriggerId());//1.x. Scheduling model switch from recurring to abort/reschedule.


            //Check Application's Custom Setting - If Inactive, exit
            FrameworkSettings__c settings = FrameworkSettings__c.getOrgDefaults();
            if(settings == null || !settings.ScheduledProcessorIsActive__c) return;


            //1.1. Gather Schedule Profiles where the current GMT time matches the calculated Next Processing Time.            
            Datetime currentTimeGmt=Datetime.now();
            Map<Id,Datetime> scheduleGroupIdToDt = getNextProcessingTimeGmtByScheduleGroup(currentTimeGmt);
            
            Set<Id> scheduleGroupIdsToProcess = new Set<Id>();
            Datetime thisProcessingTimeGmt,nextProcessingTimeGmt;//1.3. for the ScheduleGroup.

            for (Id scheduleGroupId : scheduleGroupIdToDt.keySet()){
                thisProcessingTimeGmt = scheduleGroupIdToDt.get(scheduleGroupId);//1.3. next time (minutes==0,seconds==0) the schedule group should process.

                if (Test.isRunningTest() ||
                    (currentTimeGmt>thisProcessingTimeGmt
                    && currentTimeGmt<=thisProcessingTimeGmt.addSeconds(jobToleranceSeconds))){                                        
                    //1.3- thisProcessingTimeGmt>=currentTimeGmt.addSeconds(-30)
                    //1.3- && thisProcessingTimeGmt<=currentTimeGmt.addSeconds(45))){//1 minute~ tolerance - 30 seconds before or 45 seconds after.
                    
                    scheduleGroupIdsToProcess.add(scheduleGroupId);

                    if (nextProcessingTimeGmt==null) nextProcessingTimeGmt = thisProcessingTimeGmt.addDays(1);//Default only if not set; schedule to the same time the next day if no other Schedule Profiles.
                
                } else if (nextProcessingTimeGmt==null || thisProcessingTimeGmt<nextProcessingTimeGmt) nextProcessingTimeGmt = thisProcessingTimeGmt;
            }
            if (nextProcessingTimeGmt==null) nextProcessingTimeGmt = currentTimeGmt.addDays(1);//Schedule to the same time the next day if no Schedule Profiles.
        
            if (!scheduleGroupIdsToProcess.isEmpty()){
                List<Id> scheduleEventIds = new List<Id>();
                for(DataEventType__mdt det : [select Id, ScheduleGroup__c, Order__c from DataEventType__mdt where IsActive__c=true and ScheduleGroup__c in:scheduleGroupIdsToProcess and Order__c!=null and IsTest__c=:Test.isRunningTest() order by ScheduleGroup__c asc, Order__c asc]){
                    scheduleEventIds.add(det.Id);
                }

                if (!scheduleEventIds.isEmpty()){
                    if (Test.isRunningTest()) scheduledEventIdsTest=scheduleEventIds;//Cache scheduledEventIds for test assertions
                
                    //Queue Processor, passing the Ids for all applicable Scheduled Events
                    System.enqueueJob( new ScheduledEventTypeProcessor(scheduleEventIds,sc.getTriggerId()));
                }
            }
            if (nextProcessingTimeGmt!=null){

                if (nextProcessingTimeGmt<=Datetime.now()) nextProcessingTimeGmt.addSeconds(jobScheduleStartDelaySeconds);//1.3+ -- add if necessary only.
                
                if (nextProcessingTimeGmt>Datetime.now()){//Gmt to Gmt comparison.
                    String cron = nextProcessingTimeGmt.format('ss mm HH dd M ? yyyy');//1.1. <-- schedules as the user's timezone representation for the Gmt time.
                    System.schedule(Label.Apex_Constant_Scheduled_Event_Scheduler, cron, new ScheduledEventSchedulable());
                }
            }
        } catch(Exception e){ LogHelper.logExceptions(e, 'ScheduledEventSchedulable', 'execute'); }
    }

    private Map<Id,Datetime> getNextProcessingTimeGmtByScheduleGroup(Datetime currentTimeGmt){
        Map<Id,Datetime> scheduleGroupIdToDt = new Map<Id,Datetime>();
        Datetime nextProcessingTimeGmt;

        Integer currentDayNumber = Integer.valueOf(currentTimeGmt.format('u'));//1 for Monday
        Datetime thisScheduledDateGmt=null;
        Datetime nextScheduledDateGmt=null;
        Integer startHour;

        try {

            for(ScheduleGroup__mdt scheduleGroup : [select Id, RecurrenceType__c, StartHour__c, IsMonday__c, IsTuesday__c, IsWednesday__c, IsThursday__c, IsFriday__c, IsSaturday__c, IsSunday__c 
                                                        from ScheduleGroup__mdt
                                                        where RecurrenceType__c<>null and StartHour__c<>null and IsTest__c=:Test.isRunningTest()]){//1.x~ 
                
                startHour = Integer.valueOf(scheduleGroup.StartHour__c);

                if (scheduleGroup.RecurrenceType__c.equalsIgnoreCase(Label.Picklist_Value_Schedule_Group_Recurrence_Type_Daily)){
                    
                    thisScheduledDateGmt=null;
                    nextScheduledDateGmt=null;
                    nextProcessingTimeGmt=null;
                    
                    if (currentDayNumber==1){//Monday
                        if (scheduleGroup.IsMonday__c) thisScheduledDateGmt=currentTimeGmt.dateGmt();
                        if (scheduleGroup.IsTuesday__c) nextScheduledDateGmt=currentTimeGmt.addDays(1).dateGmt();
                        if (scheduleGroup.IsWednesday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(2).dateGmt();
                        if (scheduleGroup.IsThursday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(3).dateGmt();
                        if (scheduleGroup.IsFriday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(4).dateGmt();
                        if (scheduleGroup.IsSaturday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(5).dateGmt();
                        if (scheduleGroup.IsSunday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(6).dateGmt();
                        
                    } else if (currentDayNumber==2){//Tuesday
                        if (scheduleGroup.IsTuesday__c) thisScheduledDateGmt=currentTimeGmt.dateGmt();
                        if (scheduleGroup.IsWednesday__c) nextScheduledDateGmt=currentTimeGmt.addDays(1).dateGmt();
                        if (scheduleGroup.IsThursday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(2).dateGmt();
                        if (scheduleGroup.IsFriday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(3).dateGmt();
                        if (scheduleGroup.IsSaturday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(4).dateGmt();
                        if (scheduleGroup.IsSunday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(5).dateGmt();
                        if (scheduleGroup.IsMonday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(6).dateGmt();
                    } else if (currentDayNumber==3){//Wednesday
                        if (scheduleGroup.IsWednesday__c) thisScheduledDateGmt=currentTimeGmt.dateGmt();
                        if (scheduleGroup.IsThursday__c) nextScheduledDateGmt=currentTimeGmt.addDays(1).dateGmt();
                        if (scheduleGroup.IsFriday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(2).dateGmt();
                        if (scheduleGroup.IsSaturday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(3).dateGmt();
                        if (scheduleGroup.IsSunday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(4).dateGmt();
                        if (scheduleGroup.IsMonday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(5).dateGmt();
                        if (scheduleGroup.IsTuesday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(6).dateGmt();
                    } else if (currentDayNumber==4){//Thursday
                        if (scheduleGroup.IsThursday__c) thisScheduledDateGmt=currentTimeGmt.dateGmt();
                        if (scheduleGroup.IsFriday__c) nextScheduledDateGmt=currentTimeGmt.addDays(1).dateGmt();
                        if (scheduleGroup.IsSaturday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(2).dateGmt();
                        if (scheduleGroup.IsSunday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(3).dateGmt();
                        if (scheduleGroup.IsMonday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(4).dateGmt();
                        if (scheduleGroup.IsTuesday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(5).dateGmt();
                        if (scheduleGroup.IsWednesday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(6).dateGmt();
                    } else if (currentDayNumber==5){//Friday
                        if (scheduleGroup.IsFriday__c) thisScheduledDateGmt=currentTimeGmt.dateGmt();
                        if (scheduleGroup.IsSaturday__c) nextScheduledDateGmt=currentTimeGmt.addDays(1).dateGmt();
                        if (scheduleGroup.IsSunday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(2).dateGmt();
                        if (scheduleGroup.IsMonday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(3).dateGmt();
                        if (scheduleGroup.IsTuesday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(4).dateGmt();
                        if (scheduleGroup.IsWednesday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(5).dateGmt();
                        if (scheduleGroup.IsThursday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(6).dateGmt();
                    } else if (currentDayNumber==6){//Saturday
                        if (scheduleGroup.IsSaturday__c) thisScheduledDateGmt=currentTimeGmt.dateGmt();
                        if (scheduleGroup.IsSunday__c) nextScheduledDateGmt=currentTimeGmt.addDays(1).dateGmt();
                        if (scheduleGroup.IsMonday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(2).dateGmt();
                        if (scheduleGroup.IsTuesday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(3).dateGmt();
                        if (scheduleGroup.IsWednesday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(4).dateGmt();
                        if (scheduleGroup.IsThursday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(5).dateGmt();
                        if (scheduleGroup.IsFriday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(6).dateGmt();
                    } else if (currentDayNumber==7){//Sunday
                        if (scheduleGroup.IsSunday__c) thisScheduledDateGmt=currentTimeGmt.dateGmt();
                        if (scheduleGroup.IsMonday__c) nextScheduledDateGmt=currentTimeGmt.addDays(1).dateGmt();
                        if (scheduleGroup.IsTuesday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(2).dateGmt();
                        if (scheduleGroup.IsWednesday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(3).dateGmt();
                        if (scheduleGroup.IsThursday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(4).dateGmt();
                        if (scheduleGroup.IsFriday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(5).dateGmt();
                        if (scheduleGroup.IsSaturday__c && nextScheduledDateGmt==null) nextScheduledDateGmt=currentTimeGmt.addDays(6).dateGmt();
                    }

                    if (nextScheduledDateGmt==null && thisScheduledDateGmt!=null) nextScheduledDateGmt=thisScheduledDateGmt.addDays(7).dateGmt();

                    if (thisScheduledDateGmt!=null){//processing today.

                        if ((startHour==currentTimeGmt.hourGmt() && (currentTimeGmt.minuteGmt()>0 || currentTimeGmt.secondGmt()>jobToleranceSeconds))
                                || currentTimeGmt.hourGmt()>startHour){//1.3~ 1.2~ - time is after StartHour use nextScheduledDateGmt (could be next week or tomorrow).

                            nextProcessingTimeGmt = Datetime.newInstanceGmt(nextScheduledDateGmt.dateGmt(), Time.newInstance(startHour,0,0,0));

                        } else nextProcessingTimeGmt = Datetime.newInstanceGmt(thisScheduledDateGmt.dateGmt(), Time.newInstance(startHour,0,0,0));//before or on the StartHour use today.
                    
                    } else if (nextScheduledDateGmt!=null) nextProcessingTimeGmt = Datetime.newInstanceGmt(nextScheduledDateGmt.dateGmt(), Time.newInstance(startHour,0,0,0));
                }
                if (nextProcessingTimeGmt!=null) scheduleGroupIdToDt.put(scheduleGroup.Id,nextProcessingTimeGmt);
            }
        } catch(Exception e){ throw e; }
        return scheduleGroupIdToDt;
    }
}