/**************************************************************
@author - Simon Molloy (Golfbreaks)
@date - 24/03/2017
@description - Batch class to update Sales Agent Attribute records at shift-end to make sure all users are offline
***************************************************************/
global with sharing class SalesAgentAttributeBatchUpdate implements Database.Batchable<sObject>{
	global static String CLASS_NAME = 'SalesAgentAttributeBatchUpdate';
    global String query {get; set;}

    global Database.QueryLocator start(Database.BatchableContext BC){
    	if (null == query){
            query = 'Select Id, Online__c from Sales_Agent_Attributes__c where Online__c = TRUE';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Sales_Agent_Attributes__c> scope){
    	List<Error_Log__c> logs = new List<Error_Log__c>();
        system.debug('*** -- Processing ' + scope.size() + ' online Sales Agent Attribute Records -- ***');

        for (Sales_Agent_Attributes__c sa : scope){
        	sa.Online__c = FALSE;
        }

        logs.addAll(getResultLogs(Database.update(scope, false), 'Sales_Agent_Attributes__c', 'Update'));

        if (!logs.isEmpty()){
            Database.insert(logs, false);
        }
    }

    global void finish(Database.BatchableContext BC){
        //EMPTY
    }

    static List<Error_Log__c> getResultLogs(List<Database.SaveResult> listSaveResults, String objName, String dmlOp)   {
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        errorLogs.addAll(ApplicationConstant.getSaveResultLog(listSaveResults, 'execute', CLASS_NAME, objName, dmlOp));
        return errorLogs;
    }
}