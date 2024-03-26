/*
Name:  AP17_QuoteTriggerHandler.cls
======================================================
======================================================
Purpose:
-------
Handler Class for Quote__cTrigger
======================================================
======================================================
History
------- 
Ver. Author             Date         Detail
1.0  Majoy Maliñana     2016-03-10   Initial development
1.1  Simon Molloy       2017-11-01   Changed call to updateOpportunityAmount to updateLeadOpportunityAmount
*/
public with sharing class AP17_QuoteTriggerHandler {

    //recursion flags Added By Dee June 4 -- Based on Code Review
    public static Boolean isAfterUpdateTriggerCalled = FALSE;
    public static Boolean isAfterInsertTriggerCalled = FALSE;

    public AP17_QuoteTriggerHandler(){
        
    }

    public void OnBeforeInsert(List<Quote__c> newQuoteList, Map<Id,Quote__c> newQuoteMap, List<Quote__c> oldQuoteList, Map<Id,Quote__c> oldQuoteMap){
        
    }   
    
    public void OnBeforeUpdate(List<Quote__c> newQuoteList, Map<Id,Quote__c> newQuoteMap, List<Quote__c> oldQuoteList, Map<Id,Quote__c> oldQuoteMap){
        
    }
    
    public void OnAfterInsert(List<Quote__c> newQuoteList, Map<Id,Quote__c> newQuoteMap, List<Quote__c> oldQuoteList, Map<Id,Quote__c> oldQuoteMap){
        if(!isAfterInsertTriggerCalled){
            AP18_QuoteTriggerBL.updateOpportunityStage(newQuoteList);
            AP18_QuoteTriggerBL.updateLeadOpportunityAmount(newQuoteList);
            
            isAfterInsertTriggerCalled = TRUE;
        }
    }
    
    public void OnAfterUpdate(List<Quote__c> newQuoteList, Map<Id,Quote__c> newQuoteMap, List<Quote__c> oldQuoteList, Map<Id,Quote__c> oldQuoteMap){
        if(!isAfterUpdateTriggerCalled){
            AP18_QuoteTriggerBL.updateOpportunityStage(newQuoteList);
            AP18_QuoteTriggerBL.updateLeadOpportunityAmount(newQuoteList);
            
            isAfterUpdateTriggerCalled = TRUE;
        }
    }
    
    public void OnBeforeDelete(List<Quote__c> newQuoteList, Map<Id,Quote__c> newQuoteMap, List<Quote__c> oldQuoteList, Map<Id,Quote__c> oldQuoteMap){
        
    }
    
    public void OnAfterDelete(List<Quote__c> newQuoteList, Map<Id,Quote__c> newQuoteMap, List<Quote__c> oldQuoteList, Map<Id,Quote__c> oldQuoteMap){
        
    }
     
    public void OnAfterUnDelete(List<Quote__c> newQuoteList, Map<Id,Quote__c> newQuoteMap, List<Quote__c> oldQuoteList, Map<Id,Quote__c> oldQuoteMap){
        
    }
    
    public void OnUndelete(List<Quote__c> newQuoteList, Map<Id,Quote__c> newQuoteMap, List<Quote__c> oldQuoteList, Map<Id,Quote__c> oldQuoteMap){
        
    }
}