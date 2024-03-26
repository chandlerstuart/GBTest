/*
Name:  WHTealiumIdRetrieveResponseAction.cls
======================================================
======================================================
Purpose: To retrieve reshaped JSON payload (via input or from Outbound Callout
Record) and deserialize into local structure for reference by the
flow handler
-------

https://webapi.golfbreaks.com/tracking/{agent_id}

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane     2020-05-27  Initial Development.
*/
public with sharing class WHTealiumIdRetrieveResponseAction {
    @InvocableMethod(label='Get TealiumId Retrieve Response Response' description='Returns response details following Tealium Id retrieval (in a \'Flow Friendly\' format).' category='User')
    public static List<Result> getData(List<Request> requests) { 

        List<Result> results = new List<Result>();

        Set<Id> calloutIds = new Set<Id>();
        List<String> reshapedPayloads = new List<String>();

        for(Request r : requests){
            system.debug(r);
            if(String.isNotBlank(r.reshapedPayloadBody)){//Prioritise payload body vs the outbound Callout Id
                reshapedPayloads.add(r.reshapedPayloadBody);
            }else{
                if(r.outboundCalloutId != null) calloutIds.add(r.outboundCalloutId);
            }
        }
        if(calloutIds.size()>0){//If IDs are specified (retrieve the payload(s) from the Outbound Callout Object)
            reshapedPayloads = DataEventTypeManager.getReshapedPayloads(calloutIds);
        }

        if(reshapedPayloads.size()>0){
            for(String rp : reshapedPayloads){
                results.add((Result)JSON.deserialize(rp,WHTealiumIdRetrieveResponseAction.Result.class));
            }
        }else{/*TO DO - ELSE THROW INVALID INPUT ERROR/UNABLE TO RETRIEVE RESHAPED PAYLOAD DATA*/}
        
    return results;
  }

    public class Request {
        @InvocableVariable(label='Outbound Callout Id' description='The Id of the Outbound Callout record containing the [reshaped) payload data' required=false)
        public String outboundCalloutId;
        @InvocableVariable(label='Reshaped Payload Body' description='The reshaped payload requiring deserialization into a \'Flow Friendly\' format' required=false)
        public String reshapedPayloadBody;
    }
  
    public class Result {
        @InvocableVariable(label='Tealium Id')
        public String tealiumId;
        @InvocableVariable(label='Caller Id')
        public String callerId;
    }
}