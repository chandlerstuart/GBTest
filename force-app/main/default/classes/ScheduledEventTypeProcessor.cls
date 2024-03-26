/*
Name: ScheduledEventTypeProcessor.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Queries details for the latest active Scheduled Event DET,
generates and queues Outbound Callout records and
and queues itself to process subsequent Scheduled Events

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2021-01-26  Initial development.
1.1  J Radcliffe   2021-02-11  Bug Fix - Inserting OC's implicitly queues the OC Processor. Only one queue per transaction is permissible. Moving subsequent job queueing to @future.
1.2  J Radcliffe   2021-07-14  Added RequestFormat__c to DET query to be accessible to OC generator classes
*/
public with sharing class ScheduledEventTypeProcessor implements Queueable,Database.AllowsCallouts{
    
    List<Id> scheduledEventIds = new List<Id>();
    Id scheduledJobId;//To be set in Outbound Callouts RecordId__c (depending on Callout Sequence Type) triggering the 'Blocked By' feature (see OC Trigger Handler) to sequence callouts accross multiple DETs
    Id queueableJobId;//To be set in Outbound Callouts RecordId__c (depending on Callout Sequence Type) triggering the 'Blocked By' feature (see OC Trigger Handler) to sequence callouts within the scope of the DET
    @TestVisible public static List<OutboundCallout__c> ocList;
    @TestVisible public static List<Id> remainingScheduledEventIds;

    public ScheduledEventTypeProcessor(List<Id> scheduledEventIds, Id scheduledJobId) {
        this.scheduledEventIds = scheduledEventIds;
        this.scheduledJobId = scheduledJobId;
    }

    public void execute(QueueableContext context) {

        try{
            if(scheduledEventIds == null || scheduledEventIds.size()==0) return; 

            queueableJobId = context.getJobId();
            
            //Retrieve the next configuration
            DataEventType__mdt det = [Select Id, OutboundCalloutGeneratorClass__c, EndpointPathFormatString__c,
                                        HttpMethod__c, ContentType__c, ResponseHandler__c, CalloutTimeout__c,
                                        CalloutSequenceType__c, NamedCredentials__c, DeveloperName, RequestFormat__c,//1.2~
                                        (Select Id, Key__c, Value__c From CustomHeaders__r)
                                        From DataEventType__mdt Where Id =:scheduledEventIds[0] and IsTest__c=:Test.isRunningTest()];
            
            //Remove the Id from the list
            scheduledEventIds.remove(0);

            //Generate Outbound Callout records
            if(det.OutboundCalloutGeneratorClass__c == null) return;
            Type t = Type.forName(null,det.OutboundCalloutGeneratorClass__c);
            IOutboundCalloutGenerator handler = (Test.isRunningTest())?null:(IOutboundCalloutGenerator)t.newInstance();
            List<OutboundCallout__c> outboundCallouts = (Test.isRunningTest())?ocList:handler.buildOutboundCalloutList(det,scheduledJobId);
            
            //Insert Outbound Callout records
            if(outboundCallouts?.size()>0){ 
                //Apply the configured settings for null values
                validateOutboundCalloutData(det,outboundCallouts,scheduledJobId,queueableJobId);
                insert outboundCallouts;
            }

            //If there are records remaining, chain the next job
            if(scheduledEventIds.size()>0){
                if(Test.isRunningTest()) remainingScheduledEventIds = scheduledEventIds;
                queueNextJobFuture(scheduledEventIds,scheduledJobId);//1.1+
            }

        }catch(Exception e){
            //Log and exit
            //[Removed for release] system.debug('Apex Exception: '+e);
            LogHelper.logExceptions(e, 'ScheduledEventTypeManager', 'execute');
            return;
        }
    }

    //This method validates the Outbound Callouts and applies the configured settings for any values that are not explicitly set by the Outbound Callout Generator class
    public static void validateOutboundCalloutData(DataEventType__mdt det, List<OutboundCallout__c> outboundCallouts, Id scheduledJobId, Id queueableJobId){
        
        for(OutboundCallout__c oc : outboundCallouts){
            oc.Endpoint__c = (oc.Endpoint__c != null)?oc.Endpoint__c:'callout:'+det.NamedCredentials__c+det.EndpointPathFormatString__c;
            oc.Method__c = (oc.Method__c != null)?oc.Method__c:det.HttpMethod__c;
            oc.ContentTypeHeader__c = (oc.ContentTypeHeader__c != null)?oc.ContentTypeHeader__c:det.ContentType__c;
            oc.DataEventType__c = (oc.DataEventType__c != null)?oc.DataEventType__c:det.DeveloperName;
            oc.ResponseHandler__c = (oc.ResponseHandler__c != null)?oc.ResponseHandler__c:det.ResponseHandler__c;
            oc.Status__c = (oc.Status__c != null)?oc.Status__c:Label.Picklist_Value_OutboundCallout_Status_New;
            oc.CalloutTimeout__c = (oc.CalloutTimeout__c != null)?oc.CalloutTimeout__c:det.CalloutTimeout__c;
            oc.AcceptHeader__c = (oc.AcceptHeader__c != null)?oc.AcceptHeader__c:'*/*';
            oc.RecordId__c = (oc.RecordId__c != null)?oc.RecordId__c:(det.CalloutSequenceType__c==Label.Picklist_Value_Data_Event_Callout_Schedule_Type_All)?scheduledJobId:(det.CalloutSequenceType__c == Label.Picklist_Value_Data_Event_Callout_Schedule_Type_Data_Event)?queueableJobId:null;//Trigger 'Blocked By' behaviour (OC Trigger)
        }

    }

    @future //1.1+
    public static void queueNextJobFuture(List<Id> scheduledEventIds,Id scheduledJobId){
        try{
            System.enqueueJob(new ScheduledEventTypeProcessor(scheduledEventIds,scheduledJobId));
        }catch(Exception e){
            //Log and exit
            //[Removed for release] system.debug('Apex Exception: '+e);
            LogHelper.logExceptions(e, 'ScheduledEventTypeManager', 'queueNextJobFuture');
        }
    }
}