/*
Name: EnquiryActionOutput.cls
Copyright @ 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Enquiry Action Output Class Structure.

Todo:
        
    TODO ----> (1) Add modifiers - @InvocableVariable(label='yourLabel' description='yourDescription' required=(true | false))
    TODO ----> (2) ...

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-06-13  Initial development.
*/
global with sharing class EnquiryActionOutput {
    
    @InvocableVariable
    global Boolean isSuccess;
    
    @InvocableVariable
    global Id recordId;
    
    @InvocableVariable
    global Id clientId;
    
    @InvocableVariable
    global String errorMessageString;
    
    @InvocableVariable
    global String sObjectType;

    global EnquiryActionOutput(Boolean isSuccess, Id recordId, Id clientId, Map<String,String> errorMessages, String sObjectType){
        this.isSuccess = isSuccess;
        this.recordId = recordId;
        this.clientId = clientId;
        
        for (String m : errorMessages.keySet()){//1.0 Lists can't be @InvocableVariable - so errors returned as delimited string.
            this.errorMessageString+='|'+m+':'+errorMessages.get(m);
        }
        if (String.isNotBlank(this.errorMessageString)) this.errorMessageString = this.errorMessageString.removeStart('|');
        this.sObjectType = sObjectType;
    }
}