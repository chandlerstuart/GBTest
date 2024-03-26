/*
Name:  OutboundCalloutEventSubscriberHandler.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Event Subscription handler for the Platform Event : OutboundCalloutEvent__e

======================================================
======================================================
Permissions Model:
-----------------
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-09-06  Initial development.
1.1  Mark Cane&    2019-10-09  RecordId field population added.
1.2  J Radcliffe   2019-10-23  Map new Event Properties to Outbound Callout
1.3  Mark Cane&    2019-11-27  Enhancements. DET level CalloutTimeout__c support (plus OC field).
1.4  Mark Cane&    2020-02-26  Enhancements. Reshaping related field mappings added.
*/
public with sharing class OutboundCalloutEventSubscriberHandler {
    //& indicates whether the script is executing in a Trigger context.
    private Boolean isExecuting = false;
    private Integer batchSize = 0;
    
    public OutboundCalloutEventSubscriberHandler(Boolean isExecuting, Integer size){
        this.isExecuting = isExecuting;
        this.batchSize = size;        
    }
           
    //& trigger action methods.        
    public void onAfterInsert(OutboundCalloutEvent__e[] insertedEvents){         

        List<OutboundCallout__c> recordsToInsert = new List<OutboundCallout__c>();
        for (OutboundCalloutEvent__e e : insertedEvents){
            recordsToInsert.add( new OutboundCallout__c(Endpoint__c=e.Endpoint__c,
                                                        Method__c=e.Method__c,
                                                        ContentTypeHeader__c=e.ContentTypeHeader__c,
                                                        AcceptHeader__c=e.AcceptHeader__c,
                                                        CalloutTimeout__c=e.CalloutTimeout__c,
                                                        Body__c=e.Body__c,
                                                        DataEventType__c=e.DataEventType__c,
                                                        ResponseHandler__c=e.ResponseHandler__c,
                                                        RecordId__c=e.RecordId__c,
                                                        Status__c=(e.Status__c != null)? e.Status__c:Label.Picklist_Value_OutboundCallout_Status_New,//1.2+
                                                        AbortReason__c=e.AbortReason__c,//1.2+
                                                        ResponseBody__c=e.ResponseBody__c,
                                                        ResponseStatusCode__c=(e.ResponseStatusCode__c != null)?Decimal.valueOf(e.ResponseStatusCode__c):null,//1.2+
                                                        FlowResponseHandler__c=e.FlowResponseHandler__c,
                                                        ReshapedPayloadType__c=e.ReshapedPayloadType__c,
                                                        ReshapedPayloadBody__c=e.ReshapedPayloadBody__c) );//1.1~ 1.3~
        }
        if (!recordsToInsert.isEmpty()) insert recordsToInsert;
    }
    //& end trigger action methods.
}