/*
Name:  CustomParameter.cls
======================================================
======================================================
Purpose:
-------

Used to pass custom variables from Flow to ApexActions.

======================================================
======================================================
History
------- 
Ver. Author       Date        Detail
1.0  Mark Cane&   2024-02-16  Initial development.
*/
public with sharing class CustomParameter {

    public CustomParameter(String parameterName, String parameterValue){
        this.parameterName = parameterName;
        this.parameterValue = parameterValue;
    }

    public CustomParameter(){}
    
    @AuraEnabled
    public String parameterName;

    @AuraEnabled
    public String parameterValue;// --  Inputs should be pre-formatted.
}