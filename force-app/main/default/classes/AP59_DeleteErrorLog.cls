/**
   @Author: Recuerdo Bregente
   @name: AP59_DeleteErrorLog 
   @CreateDate: 05.07.2016
   @Description: Scheduled batch for deleting old logs
   @Modification: 2017-01-23 : Simon M : Changed the SOQL query to clear ALL error log records, in batch
                  2017-03-03 : Simon M : Reverted SOQL back to original version, to now run daily
   @Version <1.0>
 */ 

global with sharing class AP59_DeleteErrorLog implements Database.Batchable<sObject> {
   
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT id FROM Error_Log__c Where CreatedDate <= N_DAYS_AGO:2' ; 
        //String query = 'SELECT id FROM Error_Log__c' ; 
        System.debug(query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Error_Log__c> scope){

        Database.delete(scope);

        Database.EmptyRecycleBin(scope);
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}