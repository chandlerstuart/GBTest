/*
Name:  WHTripCopyRequestAction.cls
======================================================
======================================================
Purpose: To retrieve reshaped JSON payload (via input or from Outbound Callout
Record) and deserialize into local structure for reference by the
flow handler
-------
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2020-03-06  Initial Development.
1.1  J Radcliffe   2020-08-11  New property - 'apiSource' - Serves to provide context to the request handler
*/
public with sharing class WHTripCopyRequestAction {
    @InvocableMethod(label='Get Data' description='Returns details for a Trip from the Kaptio Org (in a \'Flow Friendly\' format).' category='Opportunity')
    public static List<Result> getData(List<Request> requests) {

        List<Result> results = new List<Result>();

        Set<Id> calloutIds = new Set<Id>();
        List<String> reshapedPayloads = new List<String>();

        for(Request r : requests){
            if(r.reshapedPayloadBody != null){//Prioritise payload body vs the outbound Callout Id
                reshapedPayloads.add(r.reshapedPayloadBody);
            }else{
                if(r.outboundCalloutId != null) calloutIds.add(r.outboundCalloutId);
            }
        }
        if(calloutIds.size()>0){//If IDs are specified (retrieve the payload from the Outbound Callout Object)
            reshapedPayloads = DataEventTypeManager.getReshapedPayloads(calloutIds);
        }

        if(reshapedPayloads.size()>0){
            for(String res : reshapedPayloads){
                results.add((Result)JSON.deserialize(res,WHTripCopyRequestAction.Result.class));
            }
        }else{/*TO DO - ELSE THROW INVALID INPUT ERROR/UNABLE TO RETRIEVE RESHAPED RESPONSE DATA*/}
        
    return results;
  }

    public class Request {
        @InvocableVariable(label='Outbound Callout Id' description='The Id of the Outbound Callout record containing the [reshaped) response data' required=false)
        public String outboundCalloutId;
        @InvocableVariable(label='Reshaped Payload Body' description='The reshaped payload requiring deserialization into a \'Flow Friendly\' format' required=false)
        public String reshapedPayloadBody;
    }
  
    public class Result {
        @InvocableVariable(label='Master Opportunity Id')
        public String masterOpportunityId;
        @InvocableVariable(label='Trip Amount')
        public Double tripAmount;
        @InvocableVariable(label='Trip Amount BCY')
        public Double tripAmountBCY;
        @InvocableVariable(label='Trip Status')
        public String tripStatus;
        @InvocableVariable(label='API Source')
        public String apiSource;
    }

}