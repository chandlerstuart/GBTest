/*
Name:  RecordDeleteBatchClass.cls
======================================================
======================================================
Purpose:
-------
Batch Class to run and delete records
Object Name, and the number of days records to keep defined in custom setting
Record Delete Setting
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.0  Simon Molloy  2017-10-23   Initial development
1.1  J Radcliffe   2023-06-20   Add support for applying threshold based on custom DT field + exclude deleted records.
*/
public class RecordDeleteBatchClass implements Database.Batchable<sObject> {
    public static final String CLASS_NAME = 'RecordDeleteBatchClass';
    public List<Error_Log__c> logs {get; set;}
    public String query {get; set;}
    public String objectName {get; set;}
    public integer numberOfDays {get; set;}
    public String fieldName {get;set;} //1.1+
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        //Query value will be determined by the 'objectName' and 'numberOfDays' values above
        if (null == query){ 
            if(fieldName == null) fieldName = 'CreatedDate';//1.1+ Default to created date if null
            query = 'Select Id from ' + objectName + ' where '+fieldName+' != LAST_N_DAYS:' + numberOfDays + ' and IsDeleted = false';//1.1~ replaced created date with fieldName
            system.debug('*** -- Running query : ' + query + ' -- ***');
        }
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        if (!scope.isEmpty()){
            logs = new List<Error_Log__c>();

            logs.addAll(getResultLogs(Database.delete(scope), objectName, 'Delete'));

            if (!logs.isEmpty()){
                Database.insert(logs, false);
            }

            Database.emptyRecycleBin(scope);    
        }
        
    }
    
    public void finish(Database.BatchableContext BC) {

    }

    static List<Error_Log__c> getResultLogs(List<Database.DeleteResult> listDeleteResults, String objName, String dmlOp)   {
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        errorLogs.addAll(ApplicationConstant.getDeleteResultLog(listDeleteResults, 'execute', CLASS_NAME, objName, dmlOp));
        return errorLogs;
    }
    
}