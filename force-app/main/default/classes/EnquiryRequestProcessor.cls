/*
Name:  EnquiryRequestProcessor.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Isolated Processor class for the EnquiryRequest__c object.

======================================================
======================================================
Permissions Model:
-----------------
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-07-10  Initial development.
1.1  J Radcliffe   2019-07-22  Allow callouts from processor
1.2  J Radcliffe   2019-07-22  New Custom Setting
1.3  J Radcliffe   2019-08-01  Log Enquiry Processing failures on Enquiry Request and post record to Platform Log
1.4  J Radcliffe   2019-08-06  Log processor runtime exceptions and capture failures on Enquiry Requests 
1.5  J Radcliffe   2019-08-07  Store processed recs in a static list
1.6  J Radcliffe   2019-08-07  Move processEnquiryRequests to @future
*/
global with sharing class EnquiryRequestProcessor implements System.Queueable, Database.AllowsCallouts {//1.1~

    global static List<EnquiryRequest__c> processedRecs;

    global EnquiryRequestProcessor(){}

    // Queueable
    global void execute(QueueableContext context) {

        try {

            if(processedRecs == null) processedRecs = new List<EnquiryRequest__c>();

            FrameworkSettings__c  settings = FrameworkSettings__c.getOrgDefaults();
            Integer enquiriesPerProcessorCycleLimit=(settings.EnquiriesPerProcessorCycle__c != null && settings.EnquiriesPerProcessorCycle__c>0)?(Integer)settings.EnquiriesPerProcessorCycle__c:50;//Processor workload in consideration to limits. How much work per Parallel Processor?//1.2~

            List<EnquiryRequest__c> recs = [select Id, EnquiryJSON__c, APIVersionNumber__c 
                                                    from EnquiryRequest__c 
                                                    where Status__c='New' and ProcessorJobId__c=:context.getJobId()
                                                    order by CreatedDate asc
                                                    limit :enquiriesPerProcessorCycleLimit];

            if (!recs.isEmpty()){
                List<Id> recIds = new List<Id>();//1.6+
                for(EnquiryRequest__c er : recs){
                    recIds.add(er.Id);
                }
                processEnquiryRequests(recIds);//<-- Status changes to Completed.
                recIds = new List<Id>();//1.6+
                processedRecs.addAll(recs);//1.5+
                
                recs = [select Id from EnquiryRequest__c
                            where Status__c='New' and ProcessorJobId__c=:context.getJobId() and Id not in:processedRecs //1.5~ (replaced recs with processedRecs)
                            order by CreatedDate asc];

                if (!recs.isEmpty()){                                                                        
                    Id processorId = EnquiryRequestProcessor.runQueueable();
                    //[Removed for release] system.debug('processorId: '+processorId);
                    if (processorId==null) return;

                    for (EnquiryRequest__c er : recs){ er.ProcessorJobId__c = processorId; }
                    update recs;
                }
            }
        } catch(Exception e){ 
            //[Removed for release] system.debug('Theres been an error: '+e); 
        }       
    }

    public static Id runQueueable(){
        try {
            if (Limits.getQueueableJobs()<(Limits.getLimitQueueableJobs())){
                return System.enqueueJob( new EnquiryRequestProcessor() );
            } else {
                //todo log limit error
                //[Removed for release] system.debug('Limit Warning: getQueueableJobs'+Limits.getQueueableJobs()+': getLimitQueueableJobs'+Limits.getLimitQueueableJobs());
            }        
        } catch(Exception e){ 
            LogHelper.logExceptions(e, 'EnquiryRequestProcessor', 'runQueueable');
        }

        return null;
    }


    //private void processEnquiryRequests(List<EnquiryRequest__c> recs){ //1.6-
    @future(callout=true)
    private static void processEnquiryRequests(List<Id> recIds){ //1.6+

        List<EnquiryRequest__c> recs = [Select Id, EnquiryJSON__c, Status__c, APIVersionNumber__c From EnquiryRequest__c Where Id In:recIds]; //1.6+
    
        //todo version number handling.
            
        List<EnquiryManager.Enquiry> enquiriesToProcess = new List<EnquiryManager.Enquiry>();

        try{//1.4
            List<Id> cachedIds = new List<Id>();//1.3+
            for (EnquiryRequest__c er : recs){
                if (String.isBlank(er.EnquiryJSON__c)) continue;
                if (!cachedIds.contains(er.Id)) cachedIds.add(er.Id);//1.3+ - Store an ordered list of Enquiry Request Ids
                enquiriesToProcess.add( new EnquiryManager.Enquiry( (EnquiryAPIV1Request)JSON.deserialize(er.EnquiryJSON__c, EnquiryAPIV1Request.class) ) );
            }

            //1.3+
            Integer successCount = 0;
            Integer failCount = 0;
            List<Id> failIds = new List<Id>();
        
            List<EnquiryRequest__c> reqsToUpdate = new List<EnquiryRequest__c>();//1.3+
            Integer loopCounter = 0;//1.3+

            EnquiryManager em = new EnquiryManager();    
            for (EnquiryManager.Enquiry e : em.processEnquiries(enquiriesToProcess)){//1.3~
                if(cachedIds.size()<=loopCounter) break;
                if(e.isSuccess){
                    reqsToUpdate.add(new EnquiryRequest__c(Id=cachedIds[loopCounter],Status__c='Complete'));
                    successCount = successCount+1;
                }else{
                    failIds.add(cachedIds[loopCounter]);//Store the Ids of the record that failed to log to the Platform Log object
                    EnquiryRequest__c er = new EnquiryRequest__c();
                    er.Id = cachedIds[loopCounter];
                    er.Status__c = 'Failed';
                    if(e.errorMessages != null && e.errorMessages.values().size()>0){
                        String errorMessages = '';
                        for(String error: e.errorMessages.keySet()){
                            errorMessages = errorMessages+'Status Code: : Error Message: '+e.errorMessages.get(error)+'\n';
                        }
                        er.ErrorMessages__c = errorMessages;
                    }
                    reqsToUpdate.add(er);
                    failCount = failCount+1;
                }
                loopCounter = loopCounter+1;
            }   

            if(reqsToUpdate.size()>0){
                Database.SaveResult[] results = database.update(reqsToUpdate,false);//Update Enquiry Requests with results ('Complete'/'Fail')
                LogHelper.logExceptions(results, 'EnquiryRequestProcessor', 'processEnquiryRequests', reqsToUpdate);
            }

            if(failCount>0){
                //In addition to updating the Enquiry Requests, log failures to the Platform Log Object to meet the attention of the Salesforce Team
                String error = 'Async Enquiry API Failure! Please see the Enquiry Request records for full details. Ids:'+String.join(failIds,',');
                List<String> errors = new List<String>();
                errors.add(error);
                LogHelper.logAPIRequest(null, null, null, successCount, failCount, errors);
            }
        }catch(exception e){//1.4+
            List<String> errors = new List<String>();
            errors.add(e.getMessage());
            LogHelper.logExceptions(e, 'EnquiryRequestProcessor', 'processEnquiryRequests');
            LogHelper.logAPIRequest(null, null, null, 0, recs.size(), errors);
            for(EnquiryRequest__c er : recs){
                er.Status__c = 'Failed';
                er.ErrorMessages__c = e.getMessage();
            }
            update recs;
        }
    }
}