/*
Name:  PlatformLogManager.cls
======================================================
======================================================
Purpose:To facilitate the logging of runtime exceptions 
and other log types to the Platform Log Object 
via Platform Log Events
-------

======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.0  J Radcliffe   2019-02-12   Initial development
1.1  J Radcliffe   2019-02-15   Design Change - Each exception will be logged immediately in a single Event. Collections of errors (i.e. DML Result Errors) will be logged in the Detail__c of a single event
1.2  J Radcliffe   2019-02-18   Standard 'Results' classes (SaveResult,UpsertResult etc) do not provide the record Id for DML failures. Workaround: New parameter (List<sObject>) to accept the original DML list to retrieve the Id (if available) and include alongside the individual record error
1.3  J Radcliffe   2019-06-10   Implement the 'IEnquiryLogHandler' interface to it can be called from packaged applications
1.5  J Radcliffe   2019-06-13   New method 'logAPIRequest' which facilitates the logging of API Request Summary Logs
1.6  J Radcliffe   2019-07-01   New parameter for 'logAPIRequest' method, which maps 'type' to the Type__c field
1.7  J Radcliffe   2019-10-23   New method 'logAPICallout' to facilitate the logging of Outbound Callout failures
2.0  J Radcliffe   2020-06-02   Phase 1 introduction of SUP (Salesforce Utility Package). Redirecting all invocations of these methods (from local org and Iframework) to the Utility Package Methods
*/
public class PlatformLogManager implements IEnquiryLogHandler {

    //2.0+
    
    //This method maps exception details to the corresponding Platform Log Events fields publishes the event
    public static void logExceptions(System.Exception error, String className, String methodName){
        golfbreaks.PlatformLogManager.logExceptions(error,className,methodName);
    }     

    public static void logExceptions(List<Database.SaveResult> results, String className, String methodName, List<sObject> dmlRecords){    
        golfbreaks.PlatformLogManager.logExceptions(results,className,methodName,dmlRecords);
    }

    public static void logExceptions(List<Database.UpsertResult> results, String className, String methodName, List<sObject> dmlRecords){    
        golfbreaks.PlatformLogManager.logExceptions(results,className,methodName,dmlRecords);
    }

    public static void logAPIRequest(String requestBody, String responseBody, Integer speedInSeconds, Integer successCount, Integer failureCount, List<String> errorMessages, String type){
        golfbreaks.PlatformLogManager.logAPIInbound(requestBody,responseBody,speedInSeconds,successCount,failureCount,errorMessages,type);
    }

    public static void logAPICallout(String requestBody, String responseBody, String dataEventType, String recordId, String endpoint, Integer retryCount, Integer failureCount, List<String> errorMessages){
        golfbreaks.PlatformLogManager.logAPIOutbound(requestBody,responseBody,dataEventType,recordId,endpoint,retryCount,failureCount,errorMessages);
    }

    /*2.0 -
    //This method maps exception details to the corresponding Platform Log Events fields publishes the event
    public static void logExceptions(System.Exception error, String className, String methodName){    
        system.debug('logExceptions Start');
        
        //Building a concatonated String of all the error detail
        String detail = '';
        detail += 'Error Type: '+error.getTypeName()+'\n';
        detail += 'Class: '+className+'\n';
        detail += 'Method: '+methodName+'\n';
        detail += 'Line: '+error.getLineNumber()+'\n';
        detail += 'Message: '+error.getMessage()+'\n';
        detail += 'Stack Trace: '+error.getStackTraceString();
        
        //Creating new PlatformLogEvent
        PlatformLogEvent__e event = new PlatformLogEvent__e();
        event.Class__c = className;
        event.Method__c = methodName;
        event.Message__c = error.getMessage();
        event.Type__c = error.getTypeName();
        event.Detail__c = detail;
        event.RunningUserId__c = UserInfo.getUserId();
        event.RecordTypeDeveloperName__c = ApplicationConstant.PLATFORM_LOG_EXCEPTION_RT;
        
        //Allowing Field Truncation
        Database.DMLOptions dmlOpt = new Database.DMLOptions();
        dmlOpt.AllowFieldTruncation = TRUE;
        event.setOptions(dmlOpt);
        
        //Publishing Event
        EventBus.publish(event);
        
        system.debug('logExceptions Stop');
    }*/
    
    //This method maps Save Result exception details to the corresponding Platform Log Events fields and publishes the event/s
    //results - The SaveResult array returned from the database.update/insert
    //className - The name of the Class (Source) to be explicitly set by the developer to assist with exception reporting
    //methodName - The name of the Method (Source) to be explcitly set by the developer to assist with exception reporting
    //dmlRecords - The processed sObject records. Used solely to retrieve the Id of the failed records for logging purposes < -- 1.2

    /* 2.0-
    public static void logExceptions(List<Database.SaveResult> results, String className, String methodName, List<sObject> dmlRecords){    
        system.debug('logExceptions Start');
        
        //Creating new PlatformLogEvent
        PlatformLogEvent__e event = new PlatformLogEvent__e();
        event.Class__c = className;
        event.Method__c = methodName;
        event.RunningUserId__c = UserInfo.getUserId();
        event.RecordTypeDeveloperName__c = ApplicationConstant.PLATFORM_LOG_EXCEPTION_RT;
        
        //Building a concatonated String of all the error detail
        String detail = '';
        detail += 'Class: '+className+'\n';
        detail += 'Method: '+methodName+'\n';
        
        //Looping through/evaluating Save Results collating failure detail
        String failureDetail = '';
        Integer successCount = 0;
        Integer failureCount = 0; 
        Integer resultIndex = 0;//1.2
        for(Database.SaveResult sr : results){
            if(sr.isSuccess()){
                successCount++;
                resultIndex++;//1.2
            }else{
                failureCount++;
                //Capturing first error in primary fields
                event.Message__c = sr.getErrors()[0].getMessage();
                event.Type__c = 'System.DmlException';
                //Logging first and subsequent error messages in detail field
                for(Database.Error error : sr.getErrors()){
                    if(dmlRecords != null && dmlRecords[resultIndex].Id != null){ //1.2
                        failureDetail += 'Failure '+failureCount+' Message: '+error.getMessage()+' ID:'+dmlRecords[resultIndex].Id+'\n'; //1.2
                    }else{
                        failureDetail += 'Failure '+failureCount+' Message: '+error.getMessage()+'\n';
                    }
                }
                resultIndex++;//1.2
            }
        }
        
        //Exiting if no errors occurred
        if(failureCount == 0){
            System.debug('No Exceptions Found');
            system.debug('logExceptions Stop');   
            return;
        }
        
        //Adding DML Insert/Update Summary
        detail += 'Summary: '+failureCount+' out of '+(successCount+failureCount)+' failed \n';  
        //Appending failure details to primary detail String
        detail += failureDetail;
        event.Detail__c = detail;
        
        //Allowing Field Truncation
        Database.DMLOptions dmlOpt = new Database.DMLOptions();
        dmlOpt.AllowFieldTruncation = TRUE;
        event.setOptions(dmlOpt);
        
        //Publishing Event
        EventBus.publish(event);
        
        system.debug('logExceptions Stop');
    }*/
    
    //This method maps Upsert Result exception details to the corresponding Platform Log Events fields and publishes the event
    //results - The UpsertResult array returned from the database.upsert
    //className - The name of the Class (Source) to be explicitly set by the developer to assist with exception reporting
    //methodName - The name of the Method (Source) to be explcitly set by the developer to assist with exception reporting
    //dmlRecords - The processed sObject records. Used solely to retrieve the Id of the failed records for logging purposes < -- 1.2
    
    /* 2.0-
    public static void logExceptions(List<Database.UpsertResult> results, String className, String methodName, List<sObject> dmlRecords){    
        
        
        system.debug('logExceptions Start');
        
        //Creating new PlatformLogEvent
        PlatformLogEvent__e event = new PlatformLogEvent__e();
        event.Class__c = className;
        event.Method__c = methodName;
        event.RunningUserId__c = UserInfo.getUserId();
        event.RecordTypeDeveloperName__c = ApplicationConstant.PLATFORM_LOG_EXCEPTION_RT;
        
        //Building a concatonated String of all the error detail
        String detail = '';
        detail += 'Class: '+className+'\n';
        detail += 'Method: '+methodName+'\n';
        
        //Looping through/evaluating Save Results collating failure detail
        String failureDetail = '';
        Integer successCount = 0;
        Integer failureCount = 0; 
        Integer resultIndex = 0;//1.2
        for(Database.UpsertResult r : results){
            if(r.isSuccess()){
                successCount++;
                resultIndex++;//1.2
            }else{
                failureCount++;
                //Capturing first error in primary fields
                event.Message__c = r.getErrors()[0].getMessage();
                event.Type__c = 'System.DmlException';
                //Logging first and subsequent error messages in detail field
                for(Database.Error error : r.getErrors()){
                    if(dmlRecords != null && dmlRecords[resultIndex].Id != null){ //1.2
                        failureDetail += 'Failure '+failureCount+' Message: '+error.getMessage()+' ID:'+dmlRecords[resultIndex].Id+'\n'; //1.2
                    }else{
                        failureDetail += 'Failure '+failureCount+' Message: '+error.getMessage()+'\n';
                    }
                }
                resultIndex++;//1.2
            }
        }
        
        //Exiting if no errors occurred
        if(failureCount == 0){
            System.debug('No Exceptions Found');
            system.debug('logExceptions Stop');   
            return;
        }
        
        //Adding DML Insert/Update Summary
        detail += 'Summary: '+failureCount+' out of '+(successCount+failureCount)+' failed \n';  
        //Appending failure details to primary detail String
        detail += failureDetail;
        event.Detail__c = detail;
        
        //Allowing Field Truncation
        Database.DMLOptions dmlOpt = new Database.DMLOptions();
        dmlOpt.AllowFieldTruncation = TRUE;
        event.setOptions(dmlOpt);
        
        //Publishing Event
        EventBus.publish(event);
        
        system.debug('logExceptions Stop');
        
    }*/
    

    /* 2.0-
    //1.5
    public static void logAPIRequest(String requestBody, String responseBody, Integer speedInSeconds, Integer successCount, Integer failureCount, List<String> errorMessages, String type){//1.6+

        system.debug('logExceptions Start');
        
        //Creating new PlatformLogEvent
        PlatformLogEvent__e event = new PlatformLogEvent__e();
        event.RunningUserId__c = UserInfo.getUserId();
        event.RecordTypeDeveloperName__c = ApplicationConstant.PLATFORM_LOG_API_REQUEST_RT;
        event.APIRequest__c  = requestBody;
        event.APIResponse__c = responseBody;
        event.Speed__c = speedInSeconds;
        event.Successes__c = successCount;
        event.Failures__c = failureCount;
        event.Type__c = type;//1.6
        //Building a concatonated String of all the error detail
        if(!errorMessages.isEmpty()) event.Detail__c = String.join(errorMessages, ',\n');
                
        //Allowing Field Truncation
        Database.DMLOptions dmlOpt = new Database.DMLOptions();
        dmlOpt.AllowFieldTruncation = TRUE;
        event.setOptions(dmlOpt);
        
        //Publishing Event
        EventBus.publish(event);
        
        system.debug('logExceptions Stop');
     

    }*/

    /* 2.0-
    //1.7
    public static void logAPICallout(String requestBody, String responseBody, String dataEventType, String recordId, String endpoint, Integer retryCount, Integer failureCount, List<String> errorMessages){

        system.debug('logExceptions Start');
        
        //Creating new PlatformLogEvent
        PlatformLogEvent__e event = new PlatformLogEvent__e();
        event.RunningUserId__c = UserInfo.getUserId();
        event.RecordTypeDeveloperName__c = ApplicationConstant.PLATFORM_CALLOUT_LOG_RT;
        event.DataEventType__c = dataEventType;
        event.RecordId__c = recordId;
        event.APIRequest__c  = requestBody;
        event.APIResponse__c = responseBody;
        event.Failures__c = failureCount;
        event.Endpoint__c = endpoint;
        event.RetryCount__c = retryCount;
        event.Type__c = (requestBody == null)?ApplicationConstant.DATA_EVENT_TYPE_REQUEST_TYPE_WEBHOOK:ApplicationConstant.DATA_EVENT_TYPE_REQUEST_TYPE_PAYLOAD;
        //Building a concatonated String of all the error detail
        if(!errorMessages.isEmpty()) event.Detail__c = String.join(errorMessages, ',\n');
                
        //Allowing Field Truncation
        Database.DMLOptions dmlOpt = new Database.DMLOptions();
        dmlOpt.AllowFieldTruncation = TRUE;
        event.setOptions(dmlOpt);
        
        //Publishing Event
        EventBus.publish(event);
        
        system.debug('logExceptions Stop');
     
    }
    */
    
}