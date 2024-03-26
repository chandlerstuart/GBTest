/*
Name: EnquiryAPIV1Response.cls
Copyright � 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Enquiry API V1 Response Class Structure

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-05-21  Initial development.
1.1  Mark Cane&    2019-06-03  client property added.
1.2  J Radcliffe   2019-06-07  new response property - sObjectType.
1.3  Mark Cane&    2019-06-14  Complete restructure.
*/
global with sharing class EnquiryAPIV1Response {
    
    global Boolean isSuccess { get; set; }
    global String errorMessage { get; set; }
    global List<EnquiryResult> enquiryResults { get; set; }
    
    global EnquiryAPIV1Response(){
        enquiryResults = new List<EnquiryResult>();
    }

    global class EnquiryResult {    
        global Boolean isSuccess { get; set; }
        global Id recordId { get; set; }
        global Id clientId { get; set; }//1.1+
        global List<EnquiryAPIV1Response.EnquiryError> enquiryErrors { get; set; }
        global String sObjectType {get;set;}//1.2
        
        global EnquiryResult(Boolean isSuccess, Id recordId, Id clientId, Map<String,String> errorMessages, String sObjectType){
            this.isSuccess=isSuccess;
            this.recordId=recordId;
            this.clientId=clientId;//1.1+
                    
            this.enquiryErrors = new List<EnquiryAPIV1Response.EnquiryError>();
            if(errorMessages != null){
                for (String errorCode : errorMessages.keySet()){
                    enquiryErrors.add( new EnquiryAPIV1Response.EnquiryError(errorCode,errorMessages.get(errorCode)) );
                }
            }
            this.sObjectType = sObjectType;//1.2
        }
    }

    global class EnquiryError {    
        global String errorCode { get; set; }
        global String errorMessage { get; set; }

        global EnquiryError(String errorCode, String errorMessage){
            this.errorCode = errorCode;
            this.errorMessage = errorMessage;
        }
    }
}