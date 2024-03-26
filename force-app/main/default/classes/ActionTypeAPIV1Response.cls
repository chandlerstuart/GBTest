/*
Name: ActionTypeAPIV1Response.cls
Copyright � 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Action Type API V1 Response Class Structure

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-11-04  Initial development.
1.2  J Radcliffe   2020-03-04  new response property - clientCreatedOrUpdated
*/
global with sharing class ActionTypeAPIV1Response {
    global Boolean isSuccess { get; set; }
    global String errorMessage { get; set; }
    global List<ActionTypeResult> results { get; set; }
    
    global ActionTypeAPIV1Response(){
        results = new List<ActionTypeResult>();
    }

    global class ActionTypeResult {    
        global Boolean isSuccess { get; set; }
        global Id recordId { get; set; }
        global Id clientId { get; set; }
        global List<ActionTypeAPIV1Response.ActionTypeError> errors { get; set; }
        global String sObjectType {get;set;}
        global String clientCreatedOrUpdated {get;set;}//1.2+ - returns 'CREATED'/'UPDATED' depending on whether an existing client record was found
        
        global ActionTypeResult(Boolean isSuccess, Id recordId, Id clientId, Map<String,String> errorMessages, String sObjectType, String clientCreatedOrUpdated){//1.2~
            this.isSuccess=isSuccess;
            this.recordId=recordId;
            this.clientId=clientId;
                    
            this.errors = new List<ActionTypeAPIV1Response.ActionTypeError>();
            if(errorMessages != null){
                for (String errorCode : errorMessages.keySet()){
                    errors.add( new ActionTypeAPIV1Response.ActionTypeError(errorCode,errorMessages.get(errorCode)) );
                }
            }
            this.sObjectType = sObjectType;

            if(clientId != null) this.clientCreatedOrUpdated = clientCreatedOrUpdated;//1.2+ 
        }
    }

    global class ActionTypeError {    
        global String errorCode { get; set; }
        global String errorMessage { get; set; }

        global ActionTypeError(String errorCode, String errorMessage){
            this.errorCode = errorCode;
            this.errorMessage = errorMessage;
        }
    }
}