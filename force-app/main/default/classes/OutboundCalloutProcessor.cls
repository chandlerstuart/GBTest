/*
Name:  OutboundCalloutProcessor.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Isolated Queueable Processor class for the OutboundCallout__c object.

======================================================
======================================================
Permissions Model:
-----------------
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-09-06  Initial development.
1.1  Mark Cane&    2019-09-22  Enhancement. Retries now handled via Schedulable.
1.2  Mark Cane&    2019-10-03  Enhancement. Retry interval now increases as retry count increases.
1.3  Mark Cane&    2019-10-09  Blocked By logic added.
1.4  J Radcliffe   2019-10-21  Default Null Retry Count to 0 to avoid null reference errors
1.5  J Radcliffe   2019-10-21  Scheduled Job must be unique (appending current date & time plus random number)
1.6  J Radcliffe   2019-10-21  Bug Fix - Retry Processor runs 1 time less than it should 
1.7  J Radcliffe   2019-10-22  Bug Fix - Aborting Deleted Schedules, so only Active Scheduled Jobs appear in the setup menu.
1.8  J Radcliffe   2019-10-21  Set 'Abort Reason' on Max Retries
1.9  J Radcliffe   2019-10-24  'Abort' Outbound Callouts stuck in the queue
1.10 Mark Cane&    2019-11-06  Retry switched to single schedulable model.
1.11 Mark Cane&    2019-11-12  Pending Retry status added + Abort records where no runtime errors occur.
1.12 J Radcliffe   2019-11-14  Pending Retry status added to 'catch all' Abort Query
1.13 Mark Cane&    2019-11-27  Enhancements. DET level CalloutTimeout__c support (plus OC field).
1.14 Mark Cane&    2019-11-27  Bug Fixes. AsyncQueue individual send exception handling.
1.15 Mark Cane&    2020-08-11  Enhancements. DET isolation via OutboundCalloutsPerProcessorCycle__c.
1.16 Mark Cane&    2020-08-14  Bug fixes. DET isolation - removed OC must be removed from idToOutboundCallout to avoid abort.
1.17 Mark Cane&    2021-02-02  Bug fixes. Unique Schedule Name for Retry Schedulable.
1.18 J Radcliffe   2020-02-11  Bug fixes. Apply 'Name' to Blocked By Query Order, to ensure even records created at exactly the same time are ordered correctly. 
1.19 Mark Cane&    2022-05-03  Bug fixes for 1.17.
1.20 Mark Cane&    2022-06-10  Bug fixes. Added releaseBlockedCalloutsAsync.
1.21 Mark Cane&    2022-06-10  Bug fixes. releaseBlockedCalloutsAsync now includes processing for up to 100 of the most recent orphaned and blocked callouts.
*/
global with sharing class OutboundCalloutProcessor implements System.Queueable, Database.AllowsCallouts {

    private FrameworkSettings__c frameworkSettings { get; set; }//1.9+
    private Integer outboundCalloutsPerProcessorCycleLimit  { get; set; }//1.9+
    private Integer maxOutboundCalloutRetryCount { get; set; }//1.9+
    private Integer outboundCalloutRetryInterval { get; set; }//1.9+
    private Decimal outboundCalloutRetryMultiplier { get; set; }//1.9+
    @TestVisible Id processorJobIdOverrride { get; set; }//1.20/
    
    global OutboundCalloutProcessor(){
        frameworkSettings = FrameworkSettings__c.getOrgDefaults();
    
        outboundCalloutsPerProcessorCycleLimit = (frameworkSettings!=null && frameworkSettings.OutboundCalloutsPerProcessorCycle__c!=null && frameworkSettings.OutboundCalloutsPerProcessorCycle__c>0) ? (Integer)frameworkSettings.OutboundCalloutsPerProcessorCycle__c : 10;
        maxOutboundCalloutRetryCount = (frameworkSettings!=null && frameworkSettings.MaxOutboundCalloutRetryCount__c!=null && frameworkSettings.MaxOutboundCalloutRetryCount__c>0) ? (Integer)frameworkSettings.MaxOutboundCalloutRetryCount__c : 10;
        outboundCalloutRetryInterval = (frameworkSettings!=null && frameworkSettings.OutboundCalloutRetryInterval__c!=null && frameworkSettings.OutboundCalloutRetryInterval__c>0) ? (Integer)frameworkSettings.OutboundCalloutRetryInterval__c : 30;//1.1+        
        outboundCalloutRetryMultiplier = (frameworkSettings!=null && frameworkSettings.OutboundCalloutRetryMultiplier__c!=null && frameworkSettings.OutboundCalloutRetryMultiplier__c>0) ? frameworkSettings.OutboundCalloutRetryMultiplier__c : 1;//1.2+                    
    }

    // Queueable
    global void execute(QueueableContext context) {
        try {

            if (frameworkSettings==null || !frameworkSettings.OutboundCalloutProcessorActive__c) return;

            Map<Id,OutboundCallout__c> idToOutboundCallout;

            Id processorJobId = processorJobIdOverrride!=null ? processorJobIdOverrride : context.getJobId();//1.20+

            idToOutboundCallout = new Map<Id,OutboundCallout__c>( [select Id,RecordId__c,Endpoint__c,Method__c,ContentTypeHeader__c,AcceptHeader__c,CalloutTimeout__c,
                                                                            Body__c,RetryCount__c,DataEventType__c,ResponseHandler__c,Status__c,AbortReason__c,
                                                                            ReshapedPayloadType__c, FlowResponseHandler__c, ReshapedPayloadBody__c
                                                                        from OutboundCallout__c 
                                                                        where (Status__c=:Label.Picklist_Value_OutboundCallout_Status_New or Status__c=:Label.Picklist_Value_OutboundCallout_Status_Pending_Retry)
                                                                            and ProcessorJobId__c=:processorJobId 
                                                                        order by CreatedDate asc
                                                                        limit :outboundCalloutsPerProcessorCycleLimit] );//1.8~ 1.11~ 1.13~

            if (!idToOutboundCallout.isEmpty()){

                processOutboundCallouts(idToOutboundCallout);//1.9~ -- Status updated to Completed or Aborted or Retrying (with RetryCount__c++ and NextRetryDate__c set).
                
                // Retries first -- all records will retry on the same time path (created at the same time).
                if (1==[select count() from OutboundCallout__c where Status__c=:Label.Picklist_Value_OutboundCallout_Status_Retrying 
                                                                        and ProcessorJobId__c=:processorJobId and NextRetryDate__c<>null limit 1]){//1.20~

                    if (0==[select count() from CronTrigger where State not in ('COMPLETE','ERROR','DELETED') and CronJobDetail.Name like 'Outbound Callout Retry%']){//1.9~ 1.19~

                        Datetime dtScheduleAhead = Datetime.now().addSeconds(2);//1.17+ -- addSeconds(2) to allow for platform latency.

                        Id cronId = System.schedule('Outbound Callout Retry ['+(processorJobId==null ? dtScheduleAhead.format('ddMMyyyy-HHmmss') : processorJobId)+']',dtScheduleAhead.format('ss mm HH dd M ? yyyy'), new OutboundCalloutSchedulable());//1.5~,1.9~ 1.17~ 1.19~ 1.20~
                        //1.19- Id cronId = System.schedule('Outbound Callout Retry Handler ['+dtScheduleAhead.format('ddMMyyyy-HHmmss')+']', dtScheduleAhead.format('ss mm HH dd M ? yyyy'), new OutboundCalloutSchedulable());//1.5~,1.9~ 1.17~
                    }
                }

                // Unprocessed new or pending retry.
                idToOutboundCallout = new Map<Id,OutboundCallout__c>( [select Id 
                                                                            from OutboundCallout__c 
                                                                            where (Status__c=:Label.Picklist_Value_OutboundCallout_Status_New or Status__c=:Label.Picklist_Value_OutboundCallout_Status_Pending_Retry)
                                                                                and ProcessorJobId__c=:processorJobId] );//1.11~ 1.20~

                if (!idToOutboundCallout.isEmpty()){
                                    
                    Id processorId = OutboundCalloutProcessor.runQueueable();
                    if (processorId==null) return;

                    for (OutboundCallout__c oc : idToOutboundCallout.values()){ oc.ProcessorJobId__c = processorId; }

                    List<Database.SaveResult> saveResults = Database.update( idToOutboundCallout.values() );
                    LogHelper.logExceptions(saveResults, 'OutboundCalloutProcessor', 'execute', idToOutboundCallout.values());
                }
            }

            //1.7+ Delete Redundant Jobs
            for(CronTrigger ct : [Select Id From CronTrigger Where NextFireTime = null and PreviousFireTime != null and State = 'DELETED' and CronJobDetail.Name LIKE 'Outbound Callout Retry%']){//1.19~
                system.abortJob(ct.Id);
            }

            abortStuckOutboundCallouts();//1.9+

        } catch(exception e){ LogHelper.logExceptions(e, 'OutboundCalloutProcessor', 'execute'); }
    }

    public static Id runQueueable(){//1.1~,1.2~,1.9~
        try {
            if (Limits.getQueueableJobs()<(Limits.getLimitQueueableJobs())){
                return System.enqueueJob( new OutboundCalloutProcessor() );
            } else {
                //TODO - log limit error
                //[Removed for release] system.debug('Limit Warning: getQueueableJobs'+Limits.getQueueableJobs()+': getLimitQueueableJobs'+Limits.getLimitQueueableJobs());
            }
        } catch(exception e){ LogHelper.logExceptions(e, 'OutboundCalloutProcessor', 'runQueueable'); }
        return null;
    }

    private void processOutboundCallouts(Map<Id,OutboundCallout__c> idToOutboundCallout){//1.9~
        try {
            Map<String, List<OutboundCallout__c>> dataEventTypeToOutboundCallouts = new Map<String, List<OutboundCallout__c>>();
            
            for (Id outboundCalloutId : idToOutboundCallout.keySet()){

                if (!dataEventTypeToOutboundCallouts.containsKey(idToOutboundCallout.get(outboundCalloutId).DataEventType__c)) dataEventTypeToOutboundCallouts.put(idToOutboundCallout.get(outboundCalloutId).DataEventType__c,new List<OutboundCallout__c>());
                
                dataEventTypeToOutboundCallouts.get(idToOutboundCallout.get(outboundCalloutId).DataEventType__c).add(idToOutboundCallout.get(outboundCalloutId));
            }

            if (dataEventTypeToOutboundCallouts.isEmpty()) return;

            //1.15. If any DET has an OutboundCalloutsPerProcessorCycle__c value then only the first is processed by this cycle.
            
            Boolean isIsolatedAdded=false;//1.15+
            Integer calloutsPerProcessorCycleLimit;//1.15+
            Map<String,DataEventType__mdt> developerNameToIsolatedDataEventType = new Map<String,DataEventType__mdt>();//1.15+

            for (DataEventType__mdt det : [select Id, DeveloperName, OutboundCalloutsPerProcessorCycle__c
                                            from DataEventType__mdt
                                            where DeveloperName in:dataEventTypeToOutboundCallouts.keySet()   
                                                and OutboundCalloutsPerProcessorCycle__c<>null
                                                and OutboundCalloutsPerProcessorCycle__c>0
                                            order by DeveloperName asc]){//1.15+
         
                developerNameToIsolatedDataEventType.put(det.DeveloperName,det);
            }
            
            //[Removed for release] System.debug(LoggingLevel.ERROR,'FINDME>dataEventTypeToOutboundCallouts='+dataEventTypeToOutboundCallouts);

            if (!developerNameToIsolatedDataEventType.isEmpty()){
                for (String det : dataEventTypeToOutboundCallouts.keySet().clone()){
                    if (!developerNameToIsolatedDataEventType.containsKey(det) || isIsolatedAdded){

                        for (OutboundCallout__c ocToRemove : dataEventTypeToOutboundCallouts.get(det)){ if (idToOutboundCallout.containsKey(ocToRemove.Id)) idToOutboundCallout.remove(ocToRemove.Id); }//1.16+
                        dataEventTypeToOutboundCallouts.remove(det);
                        continue;
                    }

                    calloutsPerProcessorCycleLimit = (Integer)developerNameToIsolatedDataEventType.get(det).OutboundCalloutsPerProcessorCycle__c;
                    if (calloutsPerProcessorCycleLimit>outboundCalloutsPerProcessorCycleLimit) calloutsPerProcessorCycleLimit = outboundCalloutsPerProcessorCycleLimit;

                    if (dataEventTypeToOutboundCallouts.get(det).size()>calloutsPerProcessorCycleLimit){

                        for (Integer i=(dataEventTypeToOutboundCallouts.get(det).clone().size()-1); i>=calloutsPerProcessorCycleLimit; i--){
                            if (idToOutboundCallout.containsKey(dataEventTypeToOutboundCallouts.get(det)[i].Id)) idToOutboundCallout.remove(dataEventTypeToOutboundCallouts.get(det)[i].Id);//1.16+
                            dataEventTypeToOutboundCallouts.get(det).remove(i);
                        }
                    }
                    isIsolatedAdded=true;
                }
            }
            if (dataEventTypeToOutboundCallouts.isEmpty()) return;

            //[Removed for release] System.debug(LoggingLevel.ERROR,'FINDME>dataEventTypeToOutboundCallouts='+dataEventTypeToOutboundCallouts);


            Set<Id> recordIds = new Set<Id>();//1.3+
            Set<Id> processedIds = new Set<Id>();//1.11+
            List<Database.SaveResult> saveResults;

            DataEventTypeManager detm = new DataEventTypeManager();
            Map<OutboundCallout__c,Boolean> outboundCalloutToIsRetry = detm.processDataEventTypes(dataEventTypeToOutboundCallouts);

            if (outboundCalloutToIsRetry!=null && !outboundCalloutToIsRetry.isEmpty()){//1.11+

                List<OutboundCallout__c> ocToUpdate = new List<OutboundCallout__c>();//1.14+
            
                for (OutboundCallout__c oc : outboundCalloutToIsRetry.keySet()){
                    if (oc.Id==null) continue;

                    processedIds.add(oc.Id);//1.11+

                    if (!outboundCalloutToIsRetry.get(oc)){// -- false = no retry.
                        if (!oc.Status__c.equalsIgnoreCase(Label.Picklist_Value_OutboundCallout_Status_Aborted)) oc.Status__c = Label.Picklist_Value_OutboundCallout_Status_Complete;//1.14+ -- don't overwrite Aborted status.
                        
                        if (String.isNotBlank(oc.RecordId__c)) recordIds.add(oc.RecordId__c);//1.3+

                    } else {// -- true = retry.                        
                        if(oc.RetryCount__c == null) oc.RetryCount__c = 0; //1.4+

                        if ((oc.RetryCount__c+1)>maxOutboundCalloutRetryCount){//1.6~
                            oc.Status__c = Label.Picklist_Value_OutboundCallout_Status_Aborted;
                            oc.AbortReason__c = Label.Picklist_Value_OutboundCallout_Abort_Reason_Max_Retries;//1.8+
                            oc.NextRetryDate__c = null;//1.9+

                            if (String.isNotBlank(oc.RecordId__c)) recordIds.add(oc.RecordId__c);//1.3+

                        } else {
                            oc.Status__c = Label.Picklist_Value_OutboundCallout_Status_Retrying;
                            
                            oc.NextRetryDate__c = (oc.RetryCount__c==0) ? Datetime.now().addSeconds(outboundCalloutRetryInterval) : 
                                                        Datetime.now().addSeconds(Integer.valueOf(outboundCalloutRetryInterval * (oc.RetryCount__c * outboundCalloutRetryMultiplier)));//1.2+,1.9~
                            oc.RetryCount__c=oc.RetryCount__c+1;
                        }
                    }
                    ocToUpdate.add(oc);
                }

                if (!ocToUpdate.isEmpty()){//1.15+
                    saveResults = Database.update( ocToUpdate );
                    LogHelper.logExceptions(saveResults, 'OutboundCalloutProcessor', 'processOutboundCallouts', ocToUpdate);
                }
                
                if (!recordIds.isEmpty() && ([select count() from OutboundCallout__c 
                                                where (Status__c=:Label.Picklist_Value_OutboundCallout_Status_New 
                                                    or Status__c=:Label.Picklist_Value_OutboundCallout_Status_Retrying)
                                                and RecordId__c in:recordIds
                                                and BlockedBy__c!=null]>0)) releaseBlockedCalloutsAsync(recordIds);//1.20+
            }

            List<OutboundCallout__c> ocToAbort = new List<OutboundCallout__c>();//1.11+ -- abort any OC where no processed return.

            for (Id outboundCalloutId : idToOutboundCallout.keySet()){//1.11+

                if (!processedIds.contains(outboundCalloutId)){
                    idToOutboundCallout.get(outboundCalloutId).Status__c = Label.Picklist_Value_OutboundCallout_Status_Aborted;
                    idToOutboundCallout.get(outboundCalloutId).AbortReason__c = Label.Picklist_Value_OutboundCallout_Abort_Reason_Runtime_Error;
                    idToOutboundCallout.get(outboundCalloutId).NextRetryDate__c = null;

                    ocToAbort.add(idToOutboundCallout.get(outboundCalloutId));
                }
            }
            if (!ocToAbort.isEmpty()){//1.11+
                saveResults = Database.update( ocToAbort );
                LogHelper.logExceptions(saveResults, 'OutboundCalloutProcessor', 'processOutboundCallouts', ocToAbort);
            }

        } catch(exception e){ LogHelper.logExceptions(e, 'OutboundCalloutProcessor', 'processOutboundCallouts'); }
    }

    @future public static void releaseBlockedCalloutsAsync(Set<Id> recordIds){//1.20+
        Map<Id,Id> recordIdToOutboundCalloutId = new Map<Id,Id>();
        List<OutboundCallout__c> ocToUpdate = new List<OutboundCallout__c>();

        //1.21. Add up to 100 orphaned and blocked callouts with LMD more than sixty seconds ago.
        for (OutboundCallout__c oc : [select Id, RecordId__c
                                        from OutboundCallout__c 
                                        where (Status__c=:Label.Picklist_Value_OutboundCallout_Status_New 
                                                or Status__c=:Label.Picklist_Value_OutboundCallout_Status_Retrying)
                                            and RecordId__c not in:recordIds
                                            and BlockedBy__c!=null                                        
                                            and (BlockedBy__r.Status__c=:Label.Picklist_Value_OutboundCallout_Status_Complete
                                                    or BlockedBy__r.Status__c=:Label.Picklist_Value_OutboundCallout_Status_Aborted)
                                            and LastModifiedDate<:Datetime.now().addSeconds(-10)
                                        order by RecordId__c asc, CreatedDate asc, Name asc
                                        limit 100]){//1.21+
            recordIds.add(oc.RecordId__c);
        }

        for (OutboundCallout__c oc : [select Id, RecordId__c
                                        from OutboundCallout__c 
                                        where (Status__c=:Label.Picklist_Value_OutboundCallout_Status_New 
                                                or Status__c=:Label.Picklist_Value_OutboundCallout_Status_Retrying)
                                            and RecordId__c in:recordIds
                                            and BlockedBy__c!=null
                                        order by RecordId__c asc, CreatedDate asc, Name asc]){
                                                            
            if (!recordIdToOutboundCalloutId.containsKey(oc.RecordId__c)){
                recordIdToOutboundCalloutId.put(oc.RecordId__c,oc.Id);
                oc.BlockedBy__c = null;
            } else { oc.BlockedBy__c = recordIdToOutboundCalloutId.get(oc.RecordId__c); }

            ocToUpdate.add(oc);
        }

        if (!ocToUpdate.isEmpty()){
            List<Database.SaveResult> saveResults = Database.update( ocToUpdate );
            LogHelper.logExceptions(saveResults, 'OutboundCalloutProcessor', 'releaseBlockedCalloutsAsync', ocToUpdate);
        }
    }

    //1.9 - This method ensures any 'stuck' callouts are Aborted. Thereby preventing any blockages and meeting the Admin Team's attention
    public static void abortStuckOutboundCallouts(){

        try{
        DateTime clearDateTime = system.now().addHours(-3);
        List<OutboundCallout__c> calloutsToAbort = new List<OutboundCallout__c>();
        for(OutboundCallout__c oc : [Select Id, Status__c, AbortReason__c From OutboundCallout__c 
                                    Where CreatedDate >= LAST_N_DAYS:3 and LastCalloutDate__c < :clearDateTime and 
                                    (Status__c = :Label.Picklist_Value_OutboundCallout_Status_Retrying 
                                    or Status__c = :Label.Picklist_Value_OutboundCallout_Status_New
                                    or Status__c=:Label.Picklist_Value_OutboundCallout_Status_Pending_Retry)]){//1.12~
            oc.Status__c = Label.Picklist_Value_OutboundCallout_Status_Aborted;
            oc.AbortReason__c = Label.Picklist_Value_OutboundCallout_Abort_Reason_Stuck_In_Queue;
            calloutsToAbort.add(oc);
        }
        if(calloutsToAbort.size()>0){
            Database.SaveResult[] results = Database.update(calloutsToAbort,false);
            LogHelper.logExceptions(results, 'OutboundCalloutProcessor', 'abortStuckOutboundCallouts', calloutsToAbort);
        }
        }catch(exception e){ LogHelper.logExceptions(e, 'OutboundCalloutProcessor', 'abortStuckOutboundCallouts'); }
    }
}