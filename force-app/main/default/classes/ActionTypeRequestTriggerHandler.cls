/*
Name:  ActionTypeRequestTriggerHandler.cls
Copyright © 2023  Golfbreaks
======================================================
======================================================
Purpose:
-------

Trigger handler for the Custom Object Trigger : ActionTypeRequestTrigger.

======================================================
======================================================
Permissions Model:
-----------------
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2023-11-22  Initial development.
*/
public with sharing class ActionTypeRequestTriggerHandler {
    //& indicates whether the script is executing in a Trigger context.
    private Boolean isExecuting = false;
    private Integer batchSize = 0;
    public static Boolean isFirstAfterUpdate=true;
    public static Boolean isBlockTriggers=false;

    
    public ActionTypeRequestTriggerHandler(Boolean isExecuting, Integer size){
        this.isExecuting = isExecuting;
        this.batchSize = size;        
    }
           
    //& trigger action methods.        
    public void onAfterInsert(ActionTypeRequest__c[] insertedRecords){
        if (isBlockTriggers) return;

        try {

            processActionTypeRequests(insertedRecords);

        } catch(exception e){ LogHelper.logExceptions(e, 'ActionTypeRequestTriggerHandler', 'onAfterInsert'); }
    }

    public void onAfterUpdate(ActionTypeRequest__c[] updatedRecords, Map<Id,ActionTypeRequest__c> oldMap){
        if (isBlockTriggers) return;
        
        try {                 

            if (isFirstAfterUpdate){

                List<ActionTypeRequest__c> atrSetToNew = new List<ActionTypeRequest__c>();
    
                for (ActionTypeRequest__c atr : updatedRecords){
                    if (atr.Status__c.equalsIgnoreCase('New') && !oldMap.get(atr.Id).Status__c.equalsIgnoreCase('New')) atrSetToNew.add(atr);
                }
                if (!atrSetToNew.isEmpty()) processActionTypeRequests(atrSetToNew);
                isFirstAfterUpdate=false;
            }
    
        } catch(exception e){ LogHelper.logExceptions(e, 'ActionTypeRequestTriggerHandler', 'onAfterUpdate'); }
    }
    //& end trigger action methods.

    //& Helper methods.    
    private void processActionTypeRequests(List<ActionTypeRequest__c> recs){
        
        try {

            Map<String,List<ActionTypeRequest__c>> atToATRs = new Map<String,List<ActionTypeRequest__c>>();

            for (ActionTypeRequest__c atr : recs){
                if (String.isBlank(atr.ActionType__c)) continue;
                if (atr.IsBatch__c) continue;

                if (!atToATRs.containsKey(atr.ActionType__c)) atToATRs.put(atr.ActionType__c, new List<ActionTypeRequest__c>());
                atToATRs.get(atr.ActionType__c).add(atr);
            }
            if (atToATRs.isEmpty()) return;

        
            Map<String,ActionType__mdt> atToActiveActionType = new Map<String,ActionType__mdt>();
            Set<String> isolatedActionTypes = new Set<String>();
            Set<String> transactionalActionTypes = new Set<String>();            

            for (ActionType__mdt at : [select Id, DeveloperName, IsIsolatedRequestProcessor__c, IsTransactionalRequestProcessor__c from ActionType__mdt]){
                if (!atToATRs.containsKey(at.DeveloperName)) continue;

                atToActiveActionType.put(at.DeveloperName,at);

                if (at.IsTransactionalRequestProcessor__c){
                    if (at.IsIsolatedRequestProcessor__c) isolatedActionTypes.add(at.DeveloperName);
                    else transactionalActionTypes.add(at.DeveloperName);
                }
            }
            if (atToActiveActionType.isEmpty()) return;
            
            Id processorJobId;
            Boolean isSchedulable;
            Map<Id,ActionTypeRequest__c> idToATRToUpdate = new Map<Id,ActionTypeRequest__c>();

            if (!isolatedActionTypes.isEmpty()){// handle isolated Action Types.
                for (String isolatedActionType : isolatedActionTypes){

                    //if ([select count() from ActionTypeRequest__c where ActionType__c=:isolatedActionType and Id in:recs and IsBatch__c=false]==0) continue;//next actionType.

                    processorJobId = ActionTypeRequestIProcessor.runQueueableForisolatedActionType(isolatedActionType);
                    isSchedulable = processorJobId==null ? false : processorJobId.getSobjectType().getDescribe().getName().equalsIgnoreCase('CronTrigger');

                    if (processorJobId!=null){
                        for (ActionTypeRequest__c atr : [select Id,Name,ActionType__c from ActionTypeRequest__c where ActionType__c in:atToATRs.keySet() and Id in:recs and IsBatch__c=false]){
                            idToATRToUpdate.put( atr.Id, new ActionTypeRequest__c(Id=atr.Id,Status__c='Pending',ProcessorJobId__c=processorJobId) );
                        }
                    }
                }
            }

            if (!transactionalActionTypes.isEmpty()){// handle transactional-non-isolated Data Services.                        

                //if ([select count() from ActionTypeRequest__c where ActionType__c in:transactionalActionTypes and Id in:recs and IsBatch__c=false]>1){

                    List<ActionTypeRequest__c> transactionalActionTypeRequests = new List<ActionTypeRequest__c>();
                    for (String transactionalActionType : transactionalActionTypes){ transactionalActionTypeRequests.addAll(atToATRs.get(transactionalActionType)); } 

                    processorJobId = ActionTypeRequestProcessor.runQueueable();
                    isSchedulable = processorJobId==null ? false : processorJobId.getSobjectType().getDescribe().getName().equalsIgnoreCase('CronTrigger');
                    
                    for (ActionTypeRequest__c atr : transactionalActionTypeRequests){
                        if (atr.IsBatch__c) continue;
                        idToATRToUpdate.put( atr.Id, new ActionTypeRequest__c(Id=atr.Id,Status__c='Pending',ProcessorJobId__c=(isSchedulable?processorJobId:null)) );
                    }
                //}
            }

            if (recs.size()>idToATRToUpdate.size()){

                for (ActionTypeRequest__c atr : recs){
                    if (!idToATRToUpdate.containsKey(atr.Id)){
                        idToATRToUpdate.put(atr.Id, new ActionTypeRequest__c(Id=atr.Id, IsBatch__c=true, Status__c='New'));
                    }
                }
            }

            if (!idToATRToUpdate.isEmpty()){
                if (!isBlockTriggers) isBlockTriggers=true;
                update idToATRToUpdate.values();
                isBlockTriggers=false;
            }

        } catch (Exception e){
            LogHelper.logExceptions(e, 'ActionTypeRequestTriggerHandler', 'processActionTypeRequests');        
            // Note - all DML operations within the Apex Transaction are rolled back so AuditLogEntry creation is not possible.     
            for (ActionTypeRequest__c atr : recs){ atr.addError(e.getMessage()); }         
        }
    }    
    //& End helper methods.
}