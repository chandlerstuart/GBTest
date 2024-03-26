/*
Name:  WHBookingCopyRequestAction.cls
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
*/
public with sharing class WHBookingCopyRequestAction {
    @InvocableMethod(label='Get Data' description='Returns details for a Booking passed in a request from the Kaptio Org (in a \'Flow Friendly\' format).' category='Booking')
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
                results.add((Result)JSON.deserialize(res,WHBookingCopyRequestAction.Result.class));
            }
        }else{/*TO DO - ELSE THROW INVALID INPUT ERROR/UNABLE TO RETRIEVE RESHAPED DATA*/}
        
    return results;
  }

    public class Request {
        @InvocableVariable(label='Outbound Callout Id' description='The Id of the Outbound Callout record containing the [reshaped) payload data' required=false)
        public String outboundCalloutId;
        @InvocableVariable(label='Reshaped Payload Body' description='The reshaped payload requiring deserialization into a \'Flow Friendly\' format' required=false)
        public String reshapedPayloadBody;
    }
  
    public class Result {
        @InvocableVariable(label='Cancelled Date')
        public Date cancelledDate;
        @InvocableVariable(label='Is Cancelled')
        public Boolean isCancelled;
        @InvocableVariable(label='Booking Currency (Code)')
        public String currencyISOCode;
        @InvocableVariable(label='Sales Region')
        public String salesRegion;
        @InvocableVariable(label='Sales Price Gross')
        public Double salesPriceGross;
        @InvocableVariable(label='Cost Price Gross')
        public Double costPriceGross;
        @InvocableVariable(label='Cost Price (BCY))')
        public Double costPriceBCY;
        @InvocableVariable(label='Amount Paid')
        public Double amountPaid;
        @InvocableVariable(label='Gross Profit (CCY)')
        public Double grossProfit;
        @InvocableVariable(label='Gross Profit (BCY)')
        public Double grossProfitBCY;
        @InvocableVariable(label='Gross Profit (CCY)')
        public Double grossProfitCCY;
        @InvocableVariable(label='Kaptio Itinerary Id')
        public String kaptioItineraryId;
        @InvocableVariable(label='Master Account Id')
        public String masterAccountId;
        @InvocableVariable(label='Master Opportunity Id')
        public String masterOpportunityId;
        @InvocableVariable(label='Booking Number')
        public String bookingNumber;
        @InvocableVariable(label='Description')
        public String description;
        @InvocableVariable(label='Travel Date')
        public Date travelDate;
        @InvocableVariable(label='Travel Return Date')
        public Date travelReturnDate;
        @InvocableVariable(label='Nights')
        public Integer nights;
        @InvocableVariable(label='Number of Guests')
        public Integer numberOfGuests;
        @InvocableVariable(label='Sales Agent Id')
        public String salesAgentId;
        @InvocableVariable(label='Itinerary Item Account Name')
        public String itineraryItemAccountName;
       
    }

}