/**
   @Author: Recuerdo Bregente/MaJoy Maliñana
   @name: AP11_CaseScoringBatch
   @CreateDate: 04.05.2016
   @Description: Calls CaseScoringLogic for priority update of all cases.
   @Version <1.0>
 **/
 
 global with sharing class AP11_CaseScoringBatch implements Database.Batchable<sObject>{
    
    private String query = '';
    
    global AP11_CaseScoringBatch(String query){
        this.query = query;
    }
    
    /* Start method of Interface */
    global Database.QueryLocator start(Database.BatchableContext BC){
        //Retrieves the query from the UTIL_Constants class
        
        return Database.getQueryLocator(query);
    }
      
    /* Script statements to run on scope */
    global void execute(Database.BatchableContext BC, List<Case> cases){
    
        AP07_CaseScoringLogic.setCaseScore(cases, false);
        
    }
    
    /* Any post-processing will be run here */
    global void finish(Database.BatchableContext BC){
        // Logic to be Executed at finish
    }
}