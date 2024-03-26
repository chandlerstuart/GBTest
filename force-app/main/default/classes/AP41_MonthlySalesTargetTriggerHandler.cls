/**
  * @Author: Jerome To (ACN)
  * @name: AP42_MonthlySalesTargetBL
  * @CreateDate: MAY 5, 2016
  * @Description: handler class for MonthlySalesTargetTrigger
  * @Version <1.0>
  * @History
 */ 

public with sharing class AP41_MonthlySalesTargetTriggerHandler {

    //recursion flags Added By Dee June 4 -- Based on Code Review
    public static Boolean isBeforeUpdateTriggerCalled = FALSE;
    public static Boolean isBeforeInsertTriggerCalled = FALSE;
    
    public void OnBeforeInsert(List<Monthly_Sales_Target__c> newMonthlySalesTargetList){
      if(!isBeforeInsertTriggerCalled){
          AP42_MonthlySalesTargetBL.updateRecordOwner(newMonthlySalesTargetList);    
          
          isBeforeInsertTriggerCalled = TRUE;
      }  
    }   
    
    public void OnBeforeUpdate(List<Monthly_Sales_Target__c> newMonthlySalesTargetList, Map<Id,Monthly_Sales_Target__c> newMonthlySalesTargetMap, List<Monthly_Sales_Target__c> oldMonthlySalesTargetList, Map<Id,Monthly_Sales_Target__c> oldMonthlySalesTargetMap){
      if(!isBeforeUpdateTriggerCalled){
          AP42_MonthlySalesTargetBL.updateMonthlySalesTargetRollup(newMonthlySalesTargetMap);
          
          isBeforeUpdateTriggerCalled = TRUE;
      }
    }
    
    public void OnAfterInsert(List<Monthly_Sales_Target__c> newMonthlySalesTargetList, Map<Id,Monthly_Sales_Target__c> newMonthlySalesTargetMap, List<Monthly_Sales_Target__c> oldMonthlySalesTargetList, Map<Id,Monthly_Sales_Target__c> oldMonthlySalesTargetMap){
        
    }
    
    public void OnAfterUpdate(List<Monthly_Sales_Target__c> newMonthlySalesTargetList, Map<Id,Monthly_Sales_Target__c> newMonthlySalesTargetMap, List<Monthly_Sales_Target__c> oldMonthlySalesTargetList, Map<Id,Monthly_Sales_Target__c> oldMonthlySalesTargetMap){
    }
    
    public void OnBeforeDelete(List<Monthly_Sales_Target__c> newMonthlySalesTargetList, Map<Id,Monthly_Sales_Target__c> newMonthlySalesTargetMap, List<Monthly_Sales_Target__c> oldMonthlySalesTargetList, Map<Id,Monthly_Sales_Target__c> oldMonthlySalesTargetMap){
      
    }
    
    public void OnAfterDelete(List<Monthly_Sales_Target__c> newMonthlySalesTargetList, Map<Id,Monthly_Sales_Target__c> newMonthlySalesTargetMap, List<Monthly_Sales_Target__c> oldMonthlySalesTargetList, Map<Id,Monthly_Sales_Target__c> oldMonthlySalesTargetMap){
      
    }
     
    public void OnAfterUnDelete(List<Monthly_Sales_Target__c> newMonthlySalesTargetList, Map<Id,Monthly_Sales_Target__c> newMonthlySalesTargetMap, List<Monthly_Sales_Target__c> oldMonthlySalesTargetList, Map<Id,Monthly_Sales_Target__c> oldMonthlySalesTargetMap){
    }
    
    public void OnUndelete(List<Monthly_Sales_Target__c> newMonthlySalesTargetList, Map<Id,Monthly_Sales_Target__c> newMonthlySalesTargetMap, List<Monthly_Sales_Target__c> oldMonthlySalesTargetList, Map<Id,Monthly_Sales_Target__c> oldMonthlySalesTargetMap){
    }
}