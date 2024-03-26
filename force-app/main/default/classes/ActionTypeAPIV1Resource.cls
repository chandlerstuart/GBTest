/*
Name:  ActionTypeAPIV1Resource.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

ApexRest Resource for CRM Action Type Activity.

https://<INSTANCE>.salesforce.com/services/apexrest/CRM/v1.0/ActionType/

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-11-04  Initial development.
1.1  J Radcliffe   2020-03-04  Set clientCreatedOrUpdated response property
*/
@RestResource(urlMapping='/CRM/v1.0/ActionType/*')
global with sharing class ActionTypeAPIV1Resource {
    
    @HttpPost
    global static void doPost(){

        DateTime startDateTime;
        Integer successCount = 0;
        Integer failCount = 0;
        List<String> errorMessages = new List<String>();

        startDateTime = system.now();

        ActionTypeAPIV1Response res = new ActionTypeAPIV1Response();
        res.isSuccess = true;

        try {

            String json = RestContext.request.requestBody.toString();
            List<EnquiryAPIV1Request> enquiries = (List<EnquiryAPIV1Request>)System.JSON.deserialize(json, List<EnquiryAPIV1Request>.class);
        
            List<EnquiryManager.Enquiry> enquiriesToProcess = new List<EnquiryManager.Enquiry>();

            for (EnquiryAPIV1Request e : enquiries){
                enquiriesToProcess.add( new EnquiryManager.Enquiry(e) );
            }

            EnquiryManager em = new EnquiryManager();
            
            for (EnquiryManager.Enquiry e : em.processEnquiries(enquiriesToProcess)){                
                res.results.add( new ActionTypeAPIV1Response.ActionTypeResult( e.isSuccess, e.sfRecordId, e.clientDetails.accountId, e.errorMessages, e.sfRecordObjectType, e.clientCreatedOrUpdated ));//1.1~

                if(e.isSuccess){
                    successCount = successCount+1;
                }else{
                    failCount = failCount+1; 
                    if(!e.errorMessages.isEmpty()){
                        for(String m : e.errorMessages.values()){
                            if(!errorMessages.contains(m) && m != null) errorMessages.add(m);
                        }
                    }            
                    if(!e.warningMessages.isEmpty()){
                        for(String m : e.warningMessages.values()){
                            if(!errorMessages.contains(m) && m != null) errorMessages.add(m);
                        }
                    }
                }
            }        
            Integer speedInSeconds = (Integer)(system.now().getTime()-startDateTime.getTime())/1000;
            //Log API Request Summary
            LogHelper.logAPIRequest(json,system.JSON.serializePretty(res),speedInSeconds,successCount,failCount,errorMessages);
            
            res.isSuccess = true;
        
        } catch (Exception ex){
            res.isSuccess = false;
            res.errorMessage = ex.getMessage();
        }

        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(res));        

        return;
    }    
}