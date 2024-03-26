/*
Name:  ScheduledEventTypeProcessorAction.cls
======================================================
======================================================
Purpose: Invocable action for manually queueing the 
ScheduledEventTypeProcessor for select Scheduled Data Events. 

Initially created for use within a screen flow that enables 
marketing users to manually trigger a refresh of the Content Cache in Salesforce
following an update in Content Stack. However, this action can be used for any 
instances of manual trigger for scheduled callouts is required.

-------

======================================================
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2021-09-13  Initial development.
*/
public with sharing class ScheduledEventTypeProcessorAction {

    @TestVisible public static final String successMessage = 'The processor has been queued successfully for the following Data Event Types > ';
    @TestVisible public static final String failMessageNoDETs = 'No active schedulable Data Event Types could be identified from the input';
    @TestVisible public static final String failMessageMultipleRequests = 'This action can only be executed once per transaction';

    @InvocableMethod
    public static List <Result> execute (List<Request> requests) {

        List<Result> results = new List<Result>();

        if(requests.size()>1){//Only 1 request permitted per transaction (designed to be executed once from screen flow)
            for(Request req : requests){
                results.add(new Result(false,failMessageMultipleRequests));
            }
            return results;
        }else{
            //Retrieve active scheduled data event type ids to cross reference with input
            Map<Id,DataEventType__mdt> activeScheduledDataEventTypesMap = new Map<Id,DataEventType__mdt>([Select Id From DataEventType__mdt Where IsActive__c = true and IsTest__c = :Test.isRunningTest() and EventType__c = 'Scheduled Event' ]);
            try{
                List<Id> dataEventTypeIds = new List<Id>();
                if(requests[0].dataEventTypeIdString != null){
                    for(String detId : requests[0].dataEventTypeIdString.split(';')){
                        //Add to list, removing dupes and validating the id is recognised as an active scheduled event
                        if(!dataEventTypeIds.contains(detId.deleteWhitespace()) && activeScheduledDataEventTypesMap.containsKey(detId.deleteWhitespace())) dataEventTypeIds.add(detId.deleteWhitespace());       
                    }
                }
                if(requests[0].dataEventTypeIds != null && requests[0].dataEventTypeIds.size()>0){
                    for(Id detId : requests[0].dataEventTypeIds){
                        //Add to list, removing dupes and validating the id is recognised as an active scheduled event
                        if(!dataEventTypeIds.contains(detId) && activeScheduledDataEventTypesMap.containsKey(detId)) dataEventTypeIds.add(detId);
                    }
                } 
                if(dataEventTypeIds.size()>0){
                    System.enqueueJob(new ScheduledEventTypeProcessor(dataEventTypeIds,null));
                    results.add(new Result(true,successMessage+JSON.serialize(dataEventTypeIds)));
                }else{
                    results.add(new Result(false,failMessageNoDETs));
                }
            }catch(Exception e){
                results.add(new Result(false,e.getMessage()+'-'+e.getStackTraceString()));
            }
            return results;
        }
    }


    public class Request {
        @InvocableVariable(label='Data Event Type Id String' description='A semi-colon separated list of scheduled data event type Ids (simpler format for flows)')
        public String dataEventTypeIdString;
        @InvocableVariable(label='Data Event Type Ids' description='A list of scheduled data event type ids (simpler format for apex)')
        public List<Id> dataEventTypeIds;
    }

    public class Result {
        @InvocableVariable(label='isSuccess')
        public Boolean isSuccess;
        @InvocableVariable(label='Message')
        public String message;
        public Result(Boolean isSuccess,String message){
            this.isSuccess = isSuccess;
            this.message = message;
        }
    }
}