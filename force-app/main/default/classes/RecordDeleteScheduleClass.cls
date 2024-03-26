/*
Name:  RecordDeleteScheduleClass.cls
======================================================
======================================================
Purpose:
-------
Schedule class for RecordDeleteBatchClass

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon Molloy  2017-10-18  Initial development.
1.1  J Radcliffe   2023-06-20  Add support for applying threshold based on configured DT field.
*/
public class RecordDeleteScheduleClass implements Schedulable {
    public void execute(SchedulableContext sc) {
        //Determine which records are to be deleted using the RecordDeleteSetting__c custom setting
        Map<String, RecordDeleteSetting__c> recordDeleteSettings = RecordDeleteSetting__c.getAll();
        for (RecordDeleteSetting__c rds : recordDeleteSettings.values()){
            RecordDeleteBatchClass rdbc = new RecordDeleteBatchClass();
            rdbc.objectName = rds.API_Name__c;
            rdbc.numberOfDays = integer.valueOf(rds.Days__c);
            rdbc.fieldName = rds.FieldAPIName__c;
            database.executebatch(rdbc, 2000);
        }
    }
}