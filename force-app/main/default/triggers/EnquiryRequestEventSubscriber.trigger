/*
Name:  EnquiryRequestEventSubscriber.trigger
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
 
Event Subscription trigger for the Platform Event : EnquiryRequestEvent__e

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-07-10  Initial development.
*/
trigger EnquiryRequestEventSubscriber on EnquiryRequestEvent__e (after insert) {    
    EnquiryRequestEventSubscriberHandler handler = new EnquiryRequestEventSubscriberHandler(Trigger.isExecuting, Trigger.size);

    /* */    
    if (Trigger.isInsert && Trigger.isAfter){
        handler.onAfterInsert(Trigger.new);
    }
    /* */   
}