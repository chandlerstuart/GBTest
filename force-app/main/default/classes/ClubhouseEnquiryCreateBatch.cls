/*
Name:  ClubhouseEnquiryCreateBatch.cls
======================================================
======================================================
Purpose:
-------
Batch class to process Leads at status 'Contact Attempted' that are not yet in Clubhouse (CCU Project)

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon Molloy  2017-07-27  Initial development.
1.1  Simon Molloy  2017-08-01  Added in Preferred Travel Date check into the SOQL as we cannot send enquiries to CH with a Travel Date in the past
*/
global class ClubhouseEnquiryCreateBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    global static String CLASS_NAME = 'ClubhouseEnquiryCreateBatch';
    

    global String query{get; set;}
        
    global Database.QueryLocator start(Database.BatchableContext BC) {
        if (null == query){
            //We not not use GolfbreaksEnquiryId__c = NULL as this is not a selective query
            //We will check in the processing logic if it has already been sent to Clubhouse or not
            query = 'SELECT Id, Status, GolfbreaksEnquiryId__c from Lead WHERE ';
            query += 'Status = \'';
            query += ApplicationConstant.LEAD_STATUS_CONTACT_ATTEMPTED + '\' AND ';
            query += 'PreferredTravelDate__c > TODAY';
        }

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Lead> scope) {
        List<Error_Log__c> logs = new List<Error_Log__c>();
        if (!scope.isEmpty()){
            //Call the method in the utility class
            List<Lead> processedRecords = ClubhouseEnquiryUtilityClass.createClubhouseEnquiryRecords(scope);

            logs.addAll(getResultLogs(Database.update(processedRecords, false), 'Lead', 'Update'));

            //Call Overloaded AP04_LeadTriggerBL.createShadowOpportunity method
            AP04_LeadTriggerBL.createShadowOpportunity(processedRecords);

            if (!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }

    static List<Error_Log__c> getResultLogs(List<Database.SaveResult> listSaveResults, String objName, String dmlOp)   {
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        errorLogs.addAll(ApplicationConstant.getSaveResultLog(listSaveResults, 'execute', CLASS_NAME, objName, dmlOp));
        return errorLogs;
    }
    
}