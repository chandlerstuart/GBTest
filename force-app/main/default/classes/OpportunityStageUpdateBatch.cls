/*
Name:  OpportunityStageUpdateBatch.cls
======================================================
======================================================
Purpose:
-------
Class to run and update Opportunity stages in batch using OpportunityUpdateUtilityClass

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon Molloy  2017-06-28  Initial development.
*/
global class OpportunityStageUpdateBatch implements Database.Batchable<sObject> {
	global static String CLASS_NAME = 'OpportunityStageUpdateBatch';
	

	global String query{get; set;}
		
	global Database.QueryLocator start(Database.BatchableContext BC) {
		if (null == query){
			query = 'SELECT Id, StageName from Opportunity WHERE ';
			query += 'StageName = \'';
			query += ApplicationConstant.PAIDFULLBALANCESTAGE + '\'';
		}

		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
   		List<Error_Log__c> logs = new List<Error_Log__c>();
   		if (!scope.isEmpty()){
	   		//Call the method in the utility class
			List<Opportunity> processedRecords = OpportunityUpdateUtilityClass.updateToTripComplete(scope);

			logs.addAll(getResultLogs(Database.update(processedRecords, false), 'Opportunity', 'Update'));

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