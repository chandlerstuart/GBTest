/*
Name:  EnquiryRequestTrigger.trigger
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
 
Object trigger for the Custom Object : EnquiryRequest__c

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-07-10  Initial development.
*/
trigger EnquiryRequestTrigger on EnquiryRequest__c (after insert) {    
    EnquiryRequestTriggerHandler handler = new EnquiryRequestTriggerHandler(Trigger.isExecuting, Trigger.size);

    /* */    
    if (Trigger.isInsert && Trigger.isAfter){
        handler.onAfterInsert(Trigger.new);
    }
    /* */   
}