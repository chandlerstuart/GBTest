/*
Name:  LogHelper.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Helper class for log management.

A local class will implement the IEnquiryLogHandler interface and forward data to the local logging function.
The local class name will be specified in the FrameworkSettings custom setting field LogHandlerClassName__c.

TODO: Add local logging fallback/option.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-05-23  Initial development.
1.1  Mark Cane&    2019-06-06  Added logDmlErrors method.
1.2  Mark Cane&    2019-06-10  Interface refactored to align to Platform Log Manager structure.
1.3  J Radcliffe   2019-06-12  Added 'static' to static initializer
1.4  J Radcliffe   2019-06-12  Support for logging Request & Response data to the Platform Log Object
1.5  J Radcliffe   2019-06-12  Support for logging Flow Request & Response data to the Platform Log Object
1.6  J Radcliffe   2019-08-01  Support for Async API Request & Response data to the Platform Log Object
1.7  Mark Cane&    2019-09-16  Support for email enquiry logging.
1.8  J Radcliffe   2019-10-23  Support for Outbound Callout logging
1.9  J Radcliffe   2019-11-04  Change the API Name for Request Logging
*/
public with sharing class LogHelper {
    
    public static IEnquiryLogHandler logHandler;
    public static Boolean logAPIRequests;//1.4
    public static Boolean logFlowRequests;//1.5
    public static Boolean logEmailRequests;//1.7+
    public static Boolean logAPICallouts;//1.8+
    public static final String flowType = 'Flow';
    public static final String apiType = 'Action Type API';
    public static final String emailType = 'Email';

    static {//static initializer. //1.3
        FrameworkSettings__c fs = FrameworkSettings__c.getInstance();
        if (fs!=null && fs.LogAPIRequests__c) logAPIRequests = true;//1.4
        if (fs!=null && fs.LogFlowRequests__c) logFlowRequests = true;//1.5
        if (fs!=null && fs.LogEmailRequests__c) logEmailRequests = true;//1.7+ 
        if (fs!=null && fs.LogOutboundCalloutFailures__c) logAPICallouts = true;//1.8+
        if (fs!=null && String.isNotBlank(fs.LogHandlerClassName__c)){
            try {                        
                Type t; 
                t=Type.forName(null,fs.LogHandlerClassName__c);

                logHandler=(IEnquiryLogHandler)t.newInstance();
            } catch (Exception e) { System.debug(LoggingLevel.ERROR,e); }
        }
    }

    public static void logExceptions(List<Database.SaveResult> saveResults, String className, String methodName, List<sObject> dmlRecords){
        if (logHandler!=null) logHandler.logExceptions(saveResults, className, methodName, dmlRecords);
    }

    public static void logExceptions(System.Exception e, String className, String methodName){
        System.debug(LoggingLevel.ERROR,e.getMessage());
        System.debug(LoggingLevel.ERROR,e.getStackTraceString());
        if (logHandler!=null) logHandler.logExceptions(e, className, methodName);
    }

    //1.4 
    public static void logAPIRequest(String requestBody, String responseBody, Integer speedInSeconds, Integer successCount, Integer failureCount, List<String> errorMessages){
        if (logHandler!=null && logAPIRequests != null && logAPIRequests) logHandler.logAPIRequest(requestBody,responseBody,speedInSeconds,successCount,failureCount,errorMessages, apiType);
    }

    //1.5
    public static void logFlowAPIRequest(String requestBody, String responseBody, Integer speedInSeconds, Integer successCount, Integer failureCount, List<String> errorMessages){
        if (logHandler!=null && logFlowRequests != null && logFlowRequests) logHandler.logAPIRequest(requestBody,responseBody,speedInSeconds,successCount,failureCount,errorMessages, flowType);
    }

    //1.7+
    public static void logEmailRequest(String emailBody, String emailOutcome, Integer speedInSeconds, Integer successCount, Integer failureCount, List<String> errorMessages){
        if (logHandler!=null && logEmailRequests != null && logEmailRequests) logHandler.logAPIRequest(emailBody,emailOutcome,speedInSeconds,successCount,failureCount,errorMessages,emailType);
    }
    
    //1.8+
    public static void logAPICallout(String requestBody, String responseBody, String dataEventType, String recordId, String endpoint, Integer retryCount, Integer failureCount, List<String> errorMessages){
        if (logHandler != null && logAPICallouts != null && logAPICallouts) logHandler.logAPICallout(requestBody, responseBody, dataEventType, recordId, endpoint, retryCount, failureCount, errorMessages);
    }

}