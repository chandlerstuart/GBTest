/*
Name:  GetActiveCallersDialledNumber.cls
======================================================
======================================================
Purpose:
-------
Apex Action to retrieve the number dialled by the incoming caller.
The dialled number is used to dynamically apply marketing tracking
information to new Opportunities to support with attribution modelling

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2021-11-11  Initial development
*/
public with sharing class GetCallersDialledNumber {

    public static final String getDialledNumberDataEventType = 'GetDialledNumberForActiveCaller';
    public static final String onACallStatusId = '0N5b0000000Gmc5CAC';
    @TestVisible static final String testCallerId = '+447927782111';
    @TestVisible static final String testDialledNumber = '+442039487852';

    @InvocableMethod(label='Get Caller\'s Dialled Number' description='Perform a callout to retrieve the number dialled by the incoming caller')
    public static List<Result> execute(List<Request> requests){

        List<Result> results = new List<Result>();
        try {

            Set<Id> agentsOnACall = new Set<Id>();
            //Retrieve agents on call 
            for(UserServicePresence usp : [Select Id, UserId From UserServicePresence Where IsCurrentState = true and CreatedDate = today and ServicePresenceStatusId = :onACallStatusId]){
                agentsOnACall.add(usp.UserId);
            }
            
            //Prepare request - Only make callout if agent is on a call
            List<DataEventTypeAction.DataEventTypeActionRequest> calloutRequests = new List<DataEventTypeAction.DataEventTypeActionRequest>();
            for(Request req : requests){
                if(agentsOnACall.contains(req.userId) || Test.isRunningTest()) calloutRequests.add(new DataEventTypeAction.DataEventTypeActionRequest(getDialledNumberDataEventType,req.userId));
            }

            //Callout to api via IFramework
            List<DataEventTypeAction.DataEventTypeActionResult> calloutResults = (!Test.isRunningTest())?DataEventTypeAction.invokeDataEventType(calloutRequests):getTestCalloutData(calloutRequests);
            system.debug('calloutResults > '+calloutResults);
            
            //Inspect results - If successful and data retrieved store in map, else skip
            Map<Id,String> calloutResultsMap = new Map<Id,String>();
            for(DataEventTypeAction.DataEventTypeActionResult res : calloutResults){//Add results to results map
                if(res.IsSuccess && res.recordId != null && res.responseBody != null && !calloutResultsMap.containsKey(res.recordId)) calloutResultsMap.put(res.recordId,res.responseBody);
            }
            system.debug('calloutResultsMap > '+calloutResultsMap);

            //Collate results - If data retrieved, deserialize into local response, else return empty result
            Integer counter = 0;
            for(Request req : requests){
                if(calloutResultsMap.containsKey(req.userId) && calloutResultsMap.get(req.userId) != null){
                    results.add((Result)JSON.deserialize(calloutResultsMap.get(req.userId),Result.class));//Deserialize response data into method response variables
                }else{
                    results.add(new Result());
                }
                counter = counter+1;
            }

            return results;

        } catch(Exception ex){ 
            system.debug('ERROR > '+ex.getMessage()+'-'+ex.getStackTraceString());
            Golfbreaks.PlatformLogManager.logExceptions(ex,'getCallersDialledNumber','execute'); }

        return null;
    }

    public class Request {   
        
        @InvocableVariable
        public Id userId;

        public Request(){}
    }

    public class Result {   

        @InvocableVariable
        public String dialledNumber;

        @InvocableVariable
        public String callerId;

        @InvocableVariable
        public String tealiumId;

        @InvocableVariable
        public String error;

        public Result(){}

    }

    public static List<DataEventTypeAction.DataEventTypeActionResult> getTestCalloutData(List<DataEventTypeAction.DataEventTypeActionRequest> reqs){
        List<DataEventTypeAction.DataEventTypeActionResult> data = new List<DataEventTypeAction.DataEventTypeActionResult>();
        for(DataEventTypeAction.DataEventTypeActionRequest req : reqs){
            DataEventTypeAction.DataEventTypeActionResult res = new DataEventTypeAction.DataEventTypeActionResult(req.recordId,true);
            res.responseBody = '{ "tealiumId": "0173900307d7000d2ffacaef678200082004207a00720", "callerId": "'+testCallerId+'", "error": "Not found, agent not on call", "dialledNumber": "'+testDialledNumber+'", "direction": "inbound" }';
            data.add(res);
        }
        return data;
    }

}