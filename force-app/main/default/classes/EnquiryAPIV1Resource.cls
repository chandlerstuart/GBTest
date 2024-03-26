/*
Name:  EnquiryAPIV1Resource.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

ApexRest Resource for Enquiry creation.

https://<INSTANCE>.salesforce.com/services/apexrest/v1.0/Enquiry/

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-05-05  Initial development.
1.1  J Radcliffe   2019-05-20  New Enquiry API Request structure.
1.2  Mark Cane&    2019-06-03  Response object constructor change for client property.
1.3  Mark Cane&    2019-06-14  Response construct changes.
1.4  J Radcliffe   2019-06-07  Response object constructor change for sObjectType property.
1.5  J Radcliffe   2019-06-12  Support for logging Request & Response data to the Platform Log Object
1.6  Mark Cane&    2019-06-17  Changed doPost to void - json returned via RestContext to remove escape characters.
1.7  J Radcliffe   2019-07-01  Default overal isSuccess to true
1.8  Mark Cane&    2019-07-01  warningMessages handling added.
*/
@RestResource(urlMapping='/v1.0/Enquiry/*')
global with sharing class EnquiryAPIV1Resource {

    @HttpPost
    global static void doPost(){//1.3~,1.6~

        //1.5
        DateTime startDateTime;
        Integer successCount = 0;
        Integer failCount = 0;
        List<String> errorMessages = new List<String>();

        startDateTime = system.now();//1.4 - cache start time

        EnquiryAPIV1Response res = new EnquiryAPIV1Response();//1.3+
        res.isSuccess = true;//1.7

        try {

            String json = RestContext.request.requestBody.toString();
            List<EnquiryAPIV1Request> enquiries = (List<EnquiryAPIV1Request>)System.JSON.deserialize(json, List<EnquiryAPIV1Request>.class);
        
            List<EnquiryManager.Enquiry> enquiriesToProcess = new List<EnquiryManager.Enquiry>();

            for (EnquiryAPIV1Request e : enquiries){
                enquiriesToProcess.add( new EnquiryManager.Enquiry(e) );
            }

            EnquiryManager em = new EnquiryManager();
            
            for (EnquiryManager.Enquiry e : em.processEnquiries(enquiriesToProcess)){                
                res.enquiryResults.add( new EnquiryAPIV1Response.EnquiryResult( e.isSuccess, e.sfRecordId, e.clientDetails.accountId, e.errorMessages, e.sfRecordObjectType ));//1.2~, 1.3~
                //1.5 - Build request summary
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
                            if(!errorMessages.contains(m) && m != null) errorMessages.add(m);//1.7+ - add to the error messages collection.
                        }
                    }
                }
            }        
            Integer speedInSeconds = (Integer)(system.now().getTime()-startDateTime.getTime())/1000;//1.5 - capture elapsed time between start and finish  
            //Log API Request Summary
            LogHelper.logAPIRequest(json,system.JSON.serializePretty(res),speedInSeconds,successCount,failCount,errorMessages);//1.5
            
            res.isSuccess = true;
        
        } catch (Exception ex){
            res.isSuccess = false;
            res.errorMessage = ex.getMessage();
        }

        RestContext.response.addHeader('Content-Type', 'application/json');//1.6+
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(res));//1.6+         

        return;//1.6~
    }    
}