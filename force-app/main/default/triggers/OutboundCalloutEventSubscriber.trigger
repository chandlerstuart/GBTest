/*
Name:  OutboundCalloutEventSubscriber.trigger
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
 
Event Subscription trigger for the Platform Event : OutboundCalloutEvent__e

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-09-06  Initial development.
*/
trigger OutboundCalloutEventSubscriber on OutboundCalloutEvent__e (after insert) {    
    OutboundCalloutEventSubscriberHandler handler = new OutboundCalloutEventSubscriberHandler(Trigger.isExecuting, Trigger.size);

    /* */    
    if (Trigger.isInsert && Trigger.isAfter){
        handler.onAfterInsert(Trigger.new);
    }
    /* */   
}