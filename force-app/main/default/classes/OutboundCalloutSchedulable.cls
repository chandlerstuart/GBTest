/*
Name:  OutboundCalloutSchedulable.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Schedulable Processor class for the OutboundCallout__c object.

======================================================
======================================================
Permissions Model:
-----------------
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-09-22  Initial development.
1.1  Mark Cane&    2019-10-03  Enhancement. Retry interval now increases as retry count increases.
1.2  Mark Cane&    2019-11-06  Retry switched to single schedulable model.
1.3  Mark Cane&    2019-11-12  Pending Retry status added.
1.4  Mark Cane&    2021-10-16  Bug fixes. Unique Schedule Name for Retry Schedulable.
1.5  Mark Cane&    2022-05-03  Bug fixes for 1.4.
*/
global with sharing class OutboundCalloutSchedulable implements System.Schedulable {

    global OutboundCalloutSchedulable(){}

    // Schedulable
    global void execute(SchedulableContext context){
        try {

            System.abortJob(context.getTriggerId());

            // get any OC where NRD is historic and status is Retrying.
            // group by Processor Job Id
            // .. for each create a Queuable, set ProcessorJobId and Update status to New.

            Map<Id,List<OutboundCallout__c>> jobIdToOutboundCallouts = new Map<Id,List<OutboundCallout__c>>();//1.2+

            for (OutboundCallout__c oc : [select Id, ProcessorJobId__c 
                                            from OutboundCallout__c 
                                            where NextRetryDate__c<=:Datetime.now() and Status__c=:Label.Picklist_Value_OutboundCallout_Status_Retrying]){//1.2+

                if (!jobIdToOutboundCallouts.containsKey(oc.ProcessorJobId__c)) jobIdToOutboundCallouts.put(oc.ProcessorJobId__c, new List<OutboundCallout__c>());
                jobIdToOutboundCallouts.get(oc.ProcessorJobId__c).add(oc);
            }

            Id nextProcessorId;//1.2+
            List<OutboundCallout__c> recsToUpdate = new List<OutboundCallout__c>();//1.2+

            for (String processorJobId : jobIdToOutboundCallouts.keySet()){//1.2+

                if (Limits.getQueueableJobs()>=Limits.getLimitQueueableJobs()) break;// -- respect the platform limit - skipped records will be picked up next time.

                nextProcessorId = OutboundCalloutProcessor.runQueueable();
                if (nextProcessorId==null) continue;

                for (OutboundCallout__c oc : jobIdToOutboundCallouts.get(processorJobId)){
                    oc.ProcessorJobId__c = nextProcessorId;
                    oc.Status__c = Label.Picklist_Value_OutboundCallout_Status_Pending_Retry;//1.3~ -- set to Pending Retry, avoids the Schedulable re-processing records already assigned to a Processor to retry.
                    recsToUpdate.add(oc);
                }
            }

            if (!recsToUpdate.isEmpty()){
                List<Database.SaveResult> saveResults = Database.update( recsToUpdate );
                LogHelper.logExceptions(saveResults, 'OutboundCalloutSchedulable', 'execute', recsToUpdate);
            }

            // reschedule
            FrameworkSettings__c frameworkSettings = FrameworkSettings__c.getOrgDefaults();

            Integer maxOutboundCalloutRetryCount = (frameworkSettings!=null && frameworkSettings.MaxOutboundCalloutRetryCount__c!=null && frameworkSettings.MaxOutboundCalloutRetryCount__c>0) ? (Integer)frameworkSettings.MaxOutboundCalloutRetryCount__c : 10;

            Map<Id,OutboundCallout__c> idToOutboundCallout = new Map<Id,OutboundCallout__c>( [select Id, NextRetryDate__c from OutboundCallout__c 
                                                                                                where Status__c=:Label.Picklist_Value_OutboundCallout_Status_Retrying 
                                                                                                    and NextRetryDate__c<>null
                                                                                                    and RetryCount__c<=:maxOutboundCalloutRetryCount
                                                                                                    order by NextRetryDate__c asc limit 1] );// -- earliest next retry date.

            if (!idToOutboundCallout.isEmpty()){

                // if the earliest NRD is historic schedule future.
                Datetime dtScheduleTo = idToOutboundCallout.values()[0].NextRetryDate__c>=Datetime.now().addSeconds(2) ? idToOutboundCallout.values()[0].NextRetryDate__c : Datetime.now().addSeconds(2);

                Id cronId = System.schedule('Outbound Callout Retry ['+(context.getTriggerId()==null ? dtScheduleTo.format('ddMMyyyy-HHmmss') : context.getTriggerId())+']', dtScheduleTo.format('ss mm HH dd M ? yyyy'), new OutboundCalloutSchedulable());//1.2+ 1.4~ 1.5~
                //1.5- Id cronId = System.schedule('Outbound Callout Retry Handler ['+dtScheduleTo.format('ddMMyyyy-HHmmss')+']', new OutboundCalloutSchedulable());//1.2+ 1.4~
            }

        } catch(exception e){ LogHelper.logExceptions(e, 'OutboundCalloutSchedulable', 'execute'); }
    }
}