/*
Name:  IEnquiryLogHandler.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Interface class - provides abstracted pluggable interface for logging logic. 

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-05-23  Initial development.
1.1  Mark Cane&    2019-06-06  Added method logDMLErrors.
1.2  Mark Cane&    2019-06-10  Interface refactored to align to Platform Log Manager structure
1.3  J Radcliffe   2019-06-12  New Interface method for capturing API Request Details
1.4  J Radcliffe   2019-07-01  New parameter for logAPIRequest method; 'type' (either API Or Flow)
1.5  J Radcliffe   2019-10-23  New Interface method for capturing Outbound Callouts
*/
global interface IEnquiryLogHandler {
    void logExceptions(List<Database.SaveResult> saveResults, String className, String methodName, List<sObject> dmlRecords); 
    void logExceptions(System.Exception e, String className, String methodName);
    void logAPIRequest(String requestBody, String responseBody, Integer speedInSeconds, Integer successCount, Integer failureCount, List<String> errorMessages, String type);//1.3
    void logAPICallout(String requestBody, String responseBody, String dataEventType, String recordId, String endpoint, Integer retryCount, Integer failureCount, List<String> errorMessages);//1.5+
}