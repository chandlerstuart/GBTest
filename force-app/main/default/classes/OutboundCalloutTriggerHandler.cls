/*
Name:  OutboundCalloutTriggerHandler.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Trigger handler for the Custom Object Trigger : OutboundCalloutTrigger

======================================================
======================================================
Permissions Model:
-----------------
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-09-06  Initial development.
1.1  Mark Cane&    2019-10-07  Blocked By / De-duplication logic added.
1.2  J Radcliffe   2019-10-23  Set 'Abort Reason' on Insert & Dupe
1.3  J Radcliffe   2019-10-23  Set Last Callout Date for instant Successes & 'No Retry' failures
1.4  J Radcliffe   2019-10-23  Log Aborted Callouts to the Local Logging Object
1.5  J Radcliffe   2019-11-14  Change to Existing Callout Query for dupe check - Incl 'Pending Retry' status in query & limit to records created 24 hours (in case of blockages)
1.6  J Radcliffe   2019-12-11  Bug Fix - Don't log Aborted Callouts if reason = 'Duplicate Entry'
1.7  Mark Cane&    2020-03-16  Enhancement. Abort duplicate requests only where Request Type=Webhook.
1.8  J Radcliffe   2020-02-04  Enhancement. Support for Dupe Check Types & Sequential Processing (Blocked By) for non Payload Types
1.9  J Radcliffe   2020-02-08  Enhancement. Dupe Check within Trigger record list (not just existing queued records)
*/
public with sharing class OutboundCalloutTriggerHandler {
    //& indicates whether the script is executing in a Trigger context.
    private Boolean isExecuting = false;
    private Integer batchSize = 0;
    
    public OutboundCalloutTriggerHandler(Boolean isExecuting, Integer size){
        this.isExecuting = isExecuting;
        this.batchSize = size;        
    }
           
    //& trigger action methods.        
    public void onBeforeInsert(OutboundCallout__c[] insertedRecords){//1.1+ -- before insert event added - validation - set duplicates to Aborted and set BlockedBy.
        try {

            Set<Id> recordIds = new Set<Id>();
            set<String> urls = new Set<String>();//1.8+
            
            for (OutboundCallout__c oc : insertedRecords){
                if(oc.Status__c==Label.Picklist_Value_OutboundCallout_Status_Complete 
                    || (oc.Status__c==Label.Picklist_Value_OutboundCallout_Status_Aborted 
                            && oc.AbortReason__c==Label.Picklist_Value_OutboundCallout_Abort_Reason_No_Retries)){
                
                    oc.LastCalloutDate__c = Datetime.now();//1.3+
                }
                
                //if (String.isBlank(oc.RecordId__c) || String.isBlank(oc.DataEventType__c)) continue;//1.8-
                if(String.isBlank(oc.DataEventType__c)) continue;//1.8+
                if(!String.isBlank(oc.RecordId__c)) recordIds.add(oc.RecordId__c);//1.8~
                if(!String.isBlank(oc.Endpoint__c)) urls.add(oc.Endpoint__c);//1.8+
            }

            Set<String> webHookDataEventTypeNames = new Set<String>();//1.7+
            Map<String,String> dataEventTypeNameToDupeCheckType = new Map<String,String>();//1.8+ Store Dupe Check Types against DET

            for (DataEventType__mdt det : [select Id, DeveloperName, RequestType__c, DupeCheckType__c//1.8+ added DupeCheckType
                                            from DataEventType__mdt
                                            where IsActive__c=true and IsTest__c=:Test.isRunningTest()                                                      
                                            order by DeveloperName asc]){//1.7+ -- retrieve all Webhook data event types.
         
                if (det.RequestType__c==Label.Picklist_Value_Data_Event_Request_Type_Webhook) webHookDataEventTypeNames.add(det.DeveloperName);
                
                //Add dupe check type to Map - Treat nulls as 'Record Id' Type
                if(det.DupeCheckType__c != null) dataEventTypeNameToDupeCheckType.put(det.DeveloperName,det.DupeCheckType__c);
                else dataEventTypeNameToDupeCheckType.put(det.DeveloperName,Label.Picklist_Value_Data_Event_Dupe_Check_Type_Record_Id);
            }

            if (recordIds.isEmpty() && urls.isEmpty()) return;//1.8~ 

            Set<String> dupeKeySet = new Set<String>();//Set of strings 
            String dupeCheckKey;

            DateTime elapsedTimeStartDT = system.now().addHours(-24);//1.5+
            for (OutboundCallout__c oc : [select Id, RecordId__c, DataEventType__c, Endpoint__c//1.8~ added Endpoint__c
                                            from OutboundCallout__c 
                                            where (Status__c=:Label.Picklist_Value_OutboundCallout_Status_New 
                                                    or Status__c=:Label.Picklist_Value_OutboundCallout_Status_Retrying
                                                    or Status__c=:Label.Picklist_Value_OutboundCallout_Status_Pending_Retry)//1.5+
                                                and (RecordId__c in:recordIds or Endpoint__c in:urls)//1.8~ added Endpoint__c condition
                                                and CreatedDate>=:elapsedTimeStartDT
                                            order by CreatedDate asc]){//1.5+ 1.7~ -- oldest created records first.  

                    if(oc.DataEventType__c == null || !dataEventTypeNameToDupeCheckType.containsKey(oc.DataEventType__c)) continue;
                    if(dataEventTypeNameToDupeCheckType.get(oc.DataEventType__c) == Label.Picklist_Value_Data_Event_Dupe_Check_Type_Record_Id && oc.RecordId__c == null) continue;
                    if(dataEventTypeNameToDupeCheckType.get(oc.DataEventType__c) == Label.Picklist_Value_Data_Event_Dupe_Check_Type_URL && oc.Endpoint__c == null) continue;
                    
                    dupeCheckKey = oc.DataEventType__c+'-';
                    dupeCheckKey = (dataEventTypeNameToDupeCheckType.get(oc.DataEventType__c) == Label.Picklist_Value_Data_Event_Dupe_Check_Type_Record_Id)?dupeCheckKey+oc.RecordId__c:dupeCheckKey+oc.Endpoint__c;
                    if(!dupeKeySet.contains(dupeCheckKey)) dupeKeySet.add(dupeCheckKey);

            }
            
            for (OutboundCallout__c oc : insertedRecords){

                if(oc.DataEventType__c == null || oc.Status__c == Label.Picklist_Value_OutboundCallout_Status_Aborted) continue;

                if(webHookDataEventTypeNames?.contains(oc.DataEventType__c) || !dataEventTypeNameToDupeCheckType.containsKey(oc.DataEventType__c)){//Only check dupes for Webhook Request Types
                    
                    if(dataEventTypeNameToDupeCheckType.get(oc.DataEventType__c) == Label.Picklist_Value_Data_Event_Dupe_Check_Type_Record_Id && oc.RecordId__c == null) continue;
                    if(dataEventTypeNameToDupeCheckType.get(oc.DataEventType__c) == Label.Picklist_Value_Data_Event_Dupe_Check_Type_URL && oc.Endpoint__c == null) continue;
                    
                    dupeCheckKey = oc.DataEventType__c+'-';
                    dupeCheckKey = (dataEventTypeNameToDupeCheckType.get(oc.DataEventType__c) == Label.Picklist_Value_Data_Event_Dupe_Check_Type_Record_Id)?dupeCheckKey+oc.RecordId__c:dupeCheckKey+oc.Endpoint__c;

                        if(dupeKeySet.contains(dupeCheckKey)){
                            //Abort the Dupe
                            oc.Status__c = Label.Picklist_Value_OutboundCallout_Status_Aborted;
                            oc.AbortReason__c = Label.Picklist_Value_OutboundCallout_Abort_Reason_Duplicate;
                        }else{
                            //Add Dupe Check key to Set (for assessing subsequent trigger records)
                            dupeKeySet.add(dupeCheckKey);
                        }

                }
            }
        } catch(exception e){ LogHelper.logExceptions(e, 'OutboundCalloutTriggerHandler', 'onBeforeInsert'); }
    }

    public void onAfterInsert(OutboundCallout__c[] insertedRecords){
        try {

            logFailures(insertedRecords,null);//1.4+

            Set<Id> recordIds = new Set<Id>();
            for(OutboundCallout__c oc :insertedRecords){
                if(oc.RecordId__c != null && !recordIds.contains(oc.RecordId__c)) recordIds.add(oc.RecordId__c);
            }

            //Pending OC Callout Map (Record Id + Det key > oldest OC record Id)
            //Map<String,Id> recordAndDETKeyWithOCId = new Map<String,Id>();
            Map<Id,Id> recordIdToOCId = new Map<Id,Id>();

            //Query Pending OCs Sorted by Created Date ASC
            DateTime elapsedTimeStartDT = system.now().addHours(-24);//1.5+
            //String recordIdDETKey;
            for (OutboundCallout__c oc : [select Id, RecordId__c, DataEventType__c
                                            from OutboundCallout__c 
                                            where (Status__c=:Label.Picklist_Value_OutboundCallout_Status_New 
                                                    or Status__c=:Label.Picklist_Value_OutboundCallout_Status_Retrying
                                                    or Status__c=:Label.Picklist_Value_OutboundCallout_Status_Pending_Retry)
                                                and RecordId__c in:recordIds
                                                and CreatedDate>=:elapsedTimeStartDT
                                            order by CreatedDate asc, Name asc]){//oldest created records first.  

                    if(oc.RecordId__c != null && !recordIdToOCId.containsKey(oc.RecordId__c)) recordIdToOCId.put(oc.RecordId__c,oc.Id);//Store first active OC per Record Id

            }

            Integer ocToProcessCount=0;//1.1+ -- skip Aborted or Blocked outbound callouts.

            Map<Id,OutboundCallout__c> blockedCalloutsMap = new Map<Id,OutboundCallout__c>();
            for (OutboundCallout__c oc : insertedRecords){//1.1+
                if (oc.Status__c==Label.Picklist_Value_OutboundCallout_Status_Aborted) continue;
                if (oc.BlockedBy__c!=null) continue;

                //If a pending OC exists with a matching Id apply sequence (set Blocked By) and continue
                if(oc.RecordId__c != null 
                    && recordIdToOCId.containsKey(oc.RecordId__c)
                    && recordIdToOCId.get(oc.RecordId__c) != oc.Id){
                    blockedCalloutsMap.put(oc.Id,new OutboundCallout__c(Id=oc.Id,BlockedBy__c=recordIdToOCId.get(oc.RecordId__c)));
                    continue;
                } 

                ocToProcessCount++;
            }

            //Apply Callout Sequence (Set Blocked By values)
            if(blockedCalloutsMap.values().size()>0) update blockedCalloutsMap.values();
            
            if (ocToProcessCount==0) return;    
            
            FrameworkSettings__c  settings = FrameworkSettings__c.getOrgDefaults();
            if (settings==null || !settings.OutboundCalloutProcessorActive__c) return;

            Id processorJobId = OutboundCalloutProcessor.runQueueable();// one processor per ApexTrigger transaction.
            if (processorJobId==null) return;

            List<OutboundCallout__c> ocToUpdate = new List<OutboundCallout__c>();

            for (OutboundCallout__c oc : insertedRecords){

                if (oc.Status__c==Label.Picklist_Value_OutboundCallout_Status_Aborted) continue;//1.1+
                if (blockedCalloutsMap.containsKey(oc.Id)) continue;

                OutboundCallout__c occ = oc.clone(true,false,false,true);
                occ.ProcessorJobId__c = processorJobId;
                ocToUpdate.add(occ);
            }
            if (!ocToUpdate.isEmpty()) update ocToUpdate;

        } catch(exception e){ LogHelper.logExceptions(e, 'OutboundCalloutTriggerHandler', 'onAfterInsert'); }
    }

    public void onBeforeUpdate(OutboundCallout__c[] updatedRecords, Map<Id,OutboundCallout__c> oldMap){//1.1+
        try {

            logFailures(updatedRecords,oldMap);//1.4+

            FrameworkSettings__c  settings = FrameworkSettings__c.getOrgDefaults();
            if (settings==null || !settings.OutboundCalloutProcessorActive__c) return;

            List<OutboundCallout__c> ocToProcess = new List<OutboundCallout__c>();

            for (OutboundCallout__c oc : updatedRecords){//1.1+
                if (oc.Status__c==Label.Picklist_Value_OutboundCallout_Status_New
                    && oc.BlockedBy__c==null
                    && oldMap.get(oc.Id).BlockedBy__c!=null) ocToProcess.add(oc);            
            }
            if (ocToProcess.isEmpty()) return;

            Id processorJobId = OutboundCalloutProcessor.runQueueable();// one processor per ApexTrigger transaction.

            if (processorJobId!=null){// all updated records are allocated to the processor job Id.
                for (OutboundCallout__c oc : ocToProcess){ oc.ProcessorJobId__c = processorJobId; }
            }
        } catch(exception e){ LogHelper.logExceptions(e, 'OutboundCalloutTriggerHandler', 'onBeforeUpdate'); }
    }    

    //1.4+
    public static void logFailures(List<OutboundCallout__c> newList, Map<Id,OutboundCallout__c> oldMap){
        if((Trigger.isInsert || Trigger.isUpdate) && newList == null) return;
        if(Trigger.isUpdate && oldMap == null) return;

        try{
        
        List<OutboundCallout__c> abortedCallouts = new List<OutboundCallout__c>();
        Set<Id> abortedCalloutIds = new Set<Id>();
        List<String> errors = new List<String>();
        for(OutboundCallout__c oc : newList){
            if(oc.Id == null) continue;//Only run in a Context where the Id is accessible
            if(oc.Status__c != Label.Picklist_Value_OutboundCallout_Status_Aborted) continue;//Only log 'Aborted'
            if(oc.AbortReason__c == Label.Picklist_Value_OutboundCallout_Abort_Reason_Duplicate) continue;//Do not log duplicate entries //1.6~
            if(Trigger.isInsert){
                abortedCalloutIds.add(oc.Id);
                abortedCallouts.add(oc); 
                if(oc.AbortReason__c != null && !errors.contains(oc.AbortReason__c)) errors.add(oc.AbortReason__c);
                continue;
            }else if(Trigger.isUpdate){
                if(oldMap != null && (!oldMap.containsKey(oc.Id) || oldMap.get(oc.Id).Status__c == Label.Picklist_Value_OutboundCallout_Status_Aborted)) continue;//Only Add if NEWLY Aborted
                abortedCalloutIds.add(oc.Id);
                abortedCallouts.add(oc);
                if(oc.AbortReason__c != null && !errors.contains(oc.AbortReason__c)) errors.add(oc.AbortReason__c);
            }
        }

        if(abortedCallouts.size()>0){
            if(abortedCallouts.size()==1){
                OutboundCallout__c oc = abortedCallouts[0];
                Integer retryCount = (oc.RetryCount__c == null)?0:Integer.valueOf(oc.RetryCount__c);
                LogHelper.logAPICallout(oc.Body__c, oc.ResponseBody__c, oc.DataEventType__c, oc.RecordId__c, oc.Endpoint__c, retryCount, 1, errors);
            }else{
                String message = 'Multiple Failures ('+abortedCallouts.size()+'). '+Label.Error_Logging_Multiple_Failures_Message+JSON.serialize(abortedCalloutIds);
                LogHelper.logAPICallout(message, null, abortedCallouts[0].DataEventType__c, null, null, 0, abortedCallouts.size() , errors);
            }
        }

        }catch(exception e){ LogHelper.logExceptions(e, 'OutboundCalloutTriggerHandler', 'logFailures'); }

    }

    //& end trigger action methods.
}