/*
Name:  EnquiryAPIV1AsyncResource.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

ApexRest Resource for Asynchronous Enquiry creation.

https://<INSTANCE>.salesforce.com/services/apexrest/v1.0/EnquiryAsync/

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-07-10  Initial development.
1.1  J Radcliffe   2019-07-22  New Custom Setting; 
1.2  J Radcliffe   2019-07-22  Return SaveResults to caller and log exceptions
1.3  J Radcliffe   2019-07-22  Log API Requests
*/
@RestResource(urlMapping='/v1.0/EnquiryAsync/*')
global with sharing class EnquiryAPIV1AsyncResource {

    @HttpPost
    global static void doPost(){

        EnquiryAPIV1Response res = new EnquiryAPIV1Response();
        res.isSuccess = true;

        try {
            //1.3+
            DateTime startDateTime;
            Integer successCount = 0;
            Integer failCount = 0;
            List<String> errorMessages = new List<String>();

            startDateTime = system.now();//1.3 - cache start time

            FrameworkSettings__c settings = FrameworkSettings__c.getOrgDefaults();//1.1+

            Integer enquiriesPerQueueInsert= (settings.EnquiriesPerQueueInsert__c != null && settings.EnquiriesPerQueueInsert__c >0)? (Integer)settings.EnquiriesPerQueueInsert__c:20;//Parallelism. How many Parallel Processors? 200 enquiries / 20 = 10 parallel processors, this number is the 20.//1.1~

            String jsonPayload = RestContext.request.requestBody.toString();
            List<EnquiryAPIV1Request> enquiries = (List<EnquiryAPIV1Request>)System.JSON.deserialize(jsonPayload, List<EnquiryAPIV1Request>.class);
        
            String enquiryJSON;
            List<EnquiryRequestEvent__e> eventsToInsert = new List<EnquiryRequestEvent__e>();

            for (EnquiryAPIV1Request r : enquiries){
                enquiryJSON = System.JSON.serialize(r);

                eventsToInsert.add (new EnquiryRequestEvent__e(EnquiryJSON__c=enquiryJSON, APIVersionNumber__c='1'));

                if (eventsToInsert.size()>=enquiriesPerQueueInsert){
                    if(res.enquiryResults == null) res.enquiryResults = new List<EnquiryAPIV1Response.EnquiryResult>();
                    Database.SaveResult[] srs = Eventbus.publish(eventsToInsert);//1.2~
                    for(Database.SaveResult sr : srs){//1.2+
                        if(sr.isSuccess()){
                            successCount = successCount+1;//1.3+
                            res.enquiryResults.add(new EnquiryAPIV1Response.EnquiryResult(true,sr.getId(),null,null,'EnquiryRequestEvent__e'));
                        }else{
                            failCount = failCount+1;//1.3+
                            Map<String,String> errorMap = new Map<String,String>();
                            errorMap.put('3000',Label.Enquiry_Async_Logging_Error+': '+sr.getErrors()[0].getMessage());
                            res.enquiryResults.add(new EnquiryAPIV1Response.EnquiryResult(false,null,null,errorMap,'EnquiryRequestEvent__e'));
                            if(!errorMessages.contains(sr.getErrors()[0].getMessage())) errorMessages.add(sr.getErrors()[0].getMessage());//1.3+
                        }
                    }
                    eventsToInsert = new List<EnquiryRequestEvent__e>();
                }
            }
            if (!eventsToInsert.isEmpty()){ 
                Database.SaveResult[] srs = Eventbus.publish(eventsToInsert); //1.2~
                for(Database.SaveResult sr : srs){//1.2+
                    if(sr.isSuccess()){
                        successCount = successCount+1;//1.3+
                        res.enquiryResults.add(new EnquiryAPIV1Response.EnquiryResult(true,sr.getId(),null,null,'EnquiryRequestEvent__e'));
                    }else{
                        failCount = failCount+1;//1.3+
                        Map<String,String> errorMap = new Map<String,String>();
                        errorMap.put('3000',Label.Enquiry_Async_Logging_Error+': '+sr.getErrors()[0].getMessage());
                        res.enquiryResults.add(new EnquiryAPIV1Response.EnquiryResult(false,null,null,errorMap,'EnquiryRequestEvent__e'));
                        if(!errorMessages.contains(sr.getErrors()[0].getMessage())) errorMessages.add(sr.getErrors()[0].getMessage());//1.3+
                    }
                }
            }

            Integer speedInSeconds = (Integer)(system.now().getTime()-startDateTime.getTime())/1000;//1.3+ - capture elapsed time between start and finish  
            //Log API Request Summary
            LogHelper.logAPIRequest(jsonPayload,system.JSON.serializePretty(res),speedInSeconds,successCount,failCount,errorMessages);//1.3+

        } catch (Exception ex){
            res.isSuccess = false;
            res.errorMessage = ex.getMessage();
            //[Removed for release] system.debug('Exception error: '+ex.getStackTraceString());
            LogHelper.logExceptions(ex, 'EnquiryAPIV1AsyncResource', 'doPost');//1.2
        }

        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(System.JSON.serialize(res));

        return;
    }    
}