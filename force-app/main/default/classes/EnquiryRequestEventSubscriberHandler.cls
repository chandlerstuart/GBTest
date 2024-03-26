/*
Name:  EnquiryRequestEventSubscriberHandler.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Event Subscription handler for the Platform Event : EnquiryRequestEvent__e

======================================================
======================================================
Permissions Model:
-----------------
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-07-10  Initial development.
*/
public with sharing class EnquiryRequestEventSubscriberHandler {
    //& indicates whether the script is executing in a Trigger context.
    private Boolean isExecuting = false;
    private Integer batchSize = 0;
    
    public EnquiryRequestEventSubscriberHandler(Boolean isExecuting, Integer size){
        this.isExecuting = isExecuting;
        this.batchSize = size;        
    }
           
    //& trigger action methods.        
    public void onAfterInsert(EnquiryRequestEvent__e[] insertedEvents){         

        List<EnquiryRequest__c> recordsToInsert = new List<EnquiryRequest__c>();

        for (EnquiryRequestEvent__e e : insertedEvents){
            recordsToInsert.add( new EnquiryRequest__c(EnquiryJSON__c=e.EnquiryJSON__c, APIVersionNumber__c=e.APIVersionNumber__c) );
        }
        if (!recordsToInsert.isEmpty()) insert recordsToInsert;
    }    
    //& end trigger action methods.
}