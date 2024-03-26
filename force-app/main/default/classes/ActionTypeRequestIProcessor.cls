/*
Name:  ActionTypeRequestIProcessor.cls
Copyright © 2023  Golfbreaks
======================================================
======================================================
Purpose:
-------

Isolated Processor class for the ActionTypeRequest__c object.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2023-11-22  Initial development.
*/
global with sharing class ActionTypeRequestIProcessor implements System.Queueable {

    private String isolatedActionTypeName;
    @testVisible private static Boolean isForceSchedulable=false;

    global ActionTypeRequestIProcessor(){}

    global ActionTypeRequestIProcessor(String isolatedActionTypeName){ this.isolatedActionTypeName = isolatedActionTypeName; }

    // Queueable
    global void execute(QueueableContext context){
        try {
            
            if (isolatedActionTypeName==null) return;
            
            Integer requestsPerCycleLimit=200;
            ActionType__mdt isolatedActionType;

            List<ActionType__mdt> actionTypes = [select Id, DeveloperName, IsIsolatedRequestProcessor__c, IsTransactionalRequestProcessor__c, MaxRequestsPerProcessor__c from ActionType__mdt where DeveloperName=:isolatedActionTypeName];

            if (actionTypes.size()==1 && actionTypes[0].IsIsolatedRequestProcessor__c && actionTypes[0].IsTransactionalRequestProcessor__c){ 
                isolatedActionType=actionTypes[0];
            } else return;

            if (isolatedActionType.MaxRequestsPerProcessor__c!=null) requestsPerCycleLimit = Integer.valueOf(isolatedActionType.MaxRequestsPerProcessor__c);        

            List<ActionTypeRequest__c> requestsToProcess = [select Id,Name,ActionType__c
                                                                from ActionTypeRequest__c
                                                                where Status__c='Pending'
                                                                    and ActionType__c=:isolatedActionType.DeveloperName
                                                                    and ProcessorJobId__c=:context.getJobId()
                                                                order by Priority__c desc nulls last, CreatedDate asc
                                                                limit :requestsPerCycleLimit];

            if (!requestsToProcess.isEmpty()){
                ActionTypeRequestProcessor.processRequests(requestsToProcess);
                
                requestsToProcess = [select Id,Name,ActionType__c from ActionTypeRequest__c 
                                    where Status__c='Pending'
                                        and ActionType__c=:isolatedActionType.DeveloperName and ProcessorJobId__c=:context.getJobId()
                                        and Id not in:requestsToProcess
                                    order by CreatedDate desc];// -- chaining only occurs if the DSC trigger batch size > requestsPerCycleLimit.

                if (!requestsToProcess.isEmpty()){                                                   
                    Id processorId = ActionTypeRequestIProcessor.runQueueableForIsolatedActionType(isolatedActionType.DeveloperName);
                    if (processorId==null) return;

                    for (ActionTypeRequest__c atr : requestsToProcess){ atr.ProcessorJobId__c = processorId; }
                    update requestsToProcess;
                }
            }            

        } catch(Exception e){ LogHelper.logExceptions(e, 'ActionTypeRequestIProcessor', 'Queueable.execute'); } 
    }

    public static Id runQueueableForisolatedActionType(String isolatedActionTypeName){
        try {
            if (!isForceSchedulable && Limits.getQueueableJobs()<(Limits.getLimitQueueableJobs())){
                return System.enqueueJob(new ActionTypeRequestIProcessor( isolatedActionTypeName ));
            } else return System.schedule('Action Type Requests '+Datetime.now().format('ddMMyyyy-HHmmss')+' IATR', Datetime.now().addSeconds(5).format('ss mm HH dd M ? yyyy'), new ActionTypeRequestSchedulable(true));
        } catch(Exception e){ LogHelper.logExceptions(e, 'ActionTypeRequestIProcessor', 'runQueueableForisolatedActionType'); }
        return null;
    }   
}