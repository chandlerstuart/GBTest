/*
Name:  EnquiryRequestTriggerHandler.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Trigger handler for the Custom Object Trigger : EnquiryRequestTrigger

======================================================
======================================================
Permissions Model:
-----------------
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-07-10  Initial development.
1.1  J Radcliffe   2019-07-22  Trigger.new is 'Read Only'. Cloning before update
*/
public with sharing class EnquiryRequestTriggerHandler {
    //& indicates whether the script is executing in a Trigger context.
    private Boolean isExecuting = false;
    private Integer batchSize = 0;
    
    public EnquiryRequestTriggerHandler(Boolean isExecuting, Integer size){
        this.isExecuting = isExecuting;
        this.batchSize = size;        
    }
           
    //& trigger action methods.        
    public void onAfterInsert(EnquiryRequest__c[] insertedRecords){         
                
        List<EnquiryRequest__c> erToUpdate = new List<EnquiryRequest__c>();

        Id processorJobId = EnquiryRequestProcessor.runQueueable();// one processor per trigger ApexTransaction.

        if (processorJobId!=null){// all inserted records are allocated to the processor job Id.
            for (EnquiryRequest__c er : insertedRecords){
                EnquiryRequest__c req = er.clone(true,false,false,true);//1.1+
                req.ProcessorJobId__c = processorJobId;//1.1~
                erToUpdate.add(req);//1.1~
            }
        }
        if (!erToUpdate.isEmpty()) update erToUpdate;                                            
    }    
    //& end trigger action methods.
}