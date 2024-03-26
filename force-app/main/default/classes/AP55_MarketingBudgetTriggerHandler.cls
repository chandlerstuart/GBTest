/**
  * @author -         Jerome To (ACN)
  * @date -           MAY 21, 2016
  * @description -    Handler for Marketing Budget Trigger
  * #############Change Log#############
  * Modified by     Version     Change Date
  **/

public with sharing class AP55_MarketingBudgetTriggerHandler {

    //recursion flags Added By Dee June 4 -- Based on Code Review
    public static Boolean isAfterUpdateTriggerCalled = FALSE;
    public static Boolean isAfterDeleteTriggerCalled = FALSE;
    public static Boolean isAfterInsertTriggerCalled = FALSE;
    
    
    public void OnAfterInsert(List<MarketingBudget__c> newMarketingBudgetList, Map<Id,MarketingBudget__c> newMarketingBudgetMap, List<MarketingBudget__c> oldMarketingBudgetList, Map<Id,MarketingBudget__c> oldMarketingBudgetMap){
      if(!isAfterInsertTriggerCalled){
          AP56_MarketingBudgetTriggerBL.rollUpTotalForcastedCampaignSpend(newMarketingBudgetList, null);
          
          isAfterInsertTriggerCalled = TRUE;
      }
    }
    
    public void OnAfterUpdate(List<MarketingBudget__c> newMarketingBudgetList, Map<Id,MarketingBudget__c> newMarketingBudgetMap, List<MarketingBudget__c> oldMarketingBudgetList, Map<Id,MarketingBudget__c> oldMarketingBudgetMap){
      if(!isAfterUpdateTriggerCalled){
          AP56_MarketingBudgetTriggerBL.rollUpTotalForcastedCampaignSpend(newMarketingBudgetList, oldMarketingBudgetMap);
          
          isAfterUpdateTriggerCalled = TRUE;
      }
    }
    
    public void OnAfterDelete(List<MarketingBudget__c> newMarketingBudgetList, Map<Id,MarketingBudget__c> newMarketingBudgetMap, List<MarketingBudget__c> oldMarketingBudgetList, Map<Id,MarketingBudget__c> oldMarketingBudgetMap){
      if(!isAfterDeleteTriggerCalled){
          AP56_MarketingBudgetTriggerBL.rollUpTotalForcastedCampaignSpend(oldMarketingBudgetList, null);
          
          isAfterDeleteTriggerCalled = TRUE;
      }
    }
    
}