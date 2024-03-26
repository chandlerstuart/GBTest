/**
   @Author: Abram Vixen Reyes
   @name: AP15_ExpectedPaymentTriggerHandler
   @CreateDate: 10.03.2016
   @Description: Handler Class for Expected_Payment__cTrigger
   @Version <1.0>


History
------- 
Ver. Author        Date         Detail
*/

public with sharing class AP15_ExpectedPaymentTriggerHandler {

    //recursion flags Added By Dee June 4 -- Based on Code Review
    public static Boolean isAfterUpdateTriggerCalled = FALSE;
    public static Boolean isAfterInsertTriggerCalled = FALSE;

    public AP15_ExpectedPaymentTriggerHandler(){
        
    }

    public void OnBeforeInsert(List<Expected_Payment__c> newExPaymentList, Map<Id,Expected_Payment__c> newExPaymentMap, List<Expected_Payment__c> oldExPaymentList, Map<Id,Expected_Payment__c> oldExPaymentMap){
        
    }   
    
    public void OnBeforeUpdate(List<Expected_Payment__c> newExPaymentList, Map<Id,Expected_Payment__c> newExPaymentMap, List<Expected_Payment__c> oldExPaymentList, Map<Id,Expected_Payment__c> oldExPaymentMap){
        
    }
    
    public void OnAfterInsert(List<Expected_Payment__c> newExPaymentList, Map<Id,Expected_Payment__c> newExPaymentMap, List<Expected_Payment__c> oldExPaymentList, Map<Id,Expected_Payment__c> oldExPaymentMap){
        if(!isAfterInsertTriggerCalled){
            AP16_ExpectedPaymentTriggerBL.updateOpportunityStage(newExPaymentList);
            
            isAfterInsertTriggerCalled = TRUE;
        }
    }
    
    public void OnAfterUpdate(List<Expected_Payment__c> newExPaymentList, Map<Id,Expected_Payment__c> newExPaymentMap, List<Expected_Payment__c> oldExPaymentList, Map<Id,Expected_Payment__c> oldExPaymentMap){
        if(!isAfterUpdateTriggerCalled){
            AP16_ExpectedPaymentTriggerBL.updateOpportunityStage(newExPaymentList);
            
            isAfterUpdateTriggerCalled = TRUE;
        }
    }
    
    public void OnBeforeDelete(List<Expected_Payment__c> newExPaymentList, Map<Id,Expected_Payment__c> newExPaymentMap, List<Expected_Payment__c> oldExPaymentList, Map<Id,Expected_Payment__c> oldExPaymentMap){
        
    }
    
    public void OnAfterDelete(List<Expected_Payment__c> newExPaymentList, Map<Id,Expected_Payment__c> newExPaymentMap, List<Expected_Payment__c> oldExPaymentList, Map<Id,Expected_Payment__c> oldExPaymentMap){
        
    }
     
    public void OnAfterUnDelete(List<Expected_Payment__c> newExPaymentList, Map<Id,Expected_Payment__c> newExPaymentMap, List<Expected_Payment__c> oldExPaymentList, Map<Id,Expected_Payment__c> oldExPaymentMap){
        
    }
    
    public void OnUndelete(List<Expected_Payment__c> newExPaymentList, Map<Id,Expected_Payment__c> newExPaymentMap, List<Expected_Payment__c> oldExPaymentList, Map<Id,Expected_Payment__c> oldExPaymentMap){
        
    }
}