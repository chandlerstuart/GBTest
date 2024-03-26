/**
  * @author -         Jerome To (ACN)
  * @date -           MAY 11, 2016
  * @description -    Handler for CampaignTrigger
  * #############Change Log#############
  * Modified by     Version     Change Date
  **/

public with sharing class AP46_CampaignTriggerHandler {

    //recursion flags Added By Dee June 4 -- Based on Code Review
    public static Boolean isBeforeUpdateTriggerCalled = FALSE;
    public static Boolean isBeforeInsertTriggerCalled = FALSE;
    public static Boolean isAfterUpdateTriggerCalled = FALSE;
    public static Boolean isAfterDeleteTriggerCalled = FALSE;
    public static Boolean isAfterInsertTriggerCalled = FALSE;

    public AP46_CampaignTriggerHandler() {
        
    }

    public void OnBeforeInsert(List<Campaign> newCampaignList){
        if(!isBeforeInsertTriggerCalled){
            AP51_CampaignTriggerBL.populateChildCampaignField(newCampaignList, null);
            
            isBeforeInsertTriggerCalled = TRUE;
        }
    }   
    
    public void OnBeforeUpdate(List<Campaign> newCampaignList, Map<Id,Campaign> newCampaignMap, List<Campaign> oldCampaignList, Map<Id,Campaign> oldCampaignMap){
        if(!isBeforeUpdateTriggerCalled){
            AP51_CampaignTriggerBL.populateChildCampaignField(newCampaignList, oldCampaignMap);
            
            isBeforeUpdateTriggerCalled = TRUE;
        }
    }
    public void OnAfterInsert(List<Campaign> newCampaignList, Map<Id,Campaign> newCampaignMap, List<Campaign> oldCampaignList, Map<Id,Campaign> oldCampaignMap){
        if(!isAfterInsertTriggerCalled){
            AP51_CampaignTriggerBL.rollUpMarketingProgramForecastedCostAndActualCost(newCampaignList, null);
            
            isAfterInsertTriggerCalled = TRUE;
        }
    }
    
    public void OnAfterUpdate(List<Campaign> newCampaignList, Map<Id,Campaign> newCampaignMap, List<Campaign> oldCampaignList, Map<Id,Campaign> oldCampaignMap){
        if(!isAfterUpdateTriggerCalled){
            AP51_CampaignTriggerBL.rollUpMarketingProgramForecastedCostAndActualCost(newCampaignList, oldCampaignMap);
            
            isAfterUpdateTriggerCalled = TRUE;
        }
    }
    
    public void OnBeforeDelete(List<Campaign> newCampaignList, Map<Id,Campaign> newCampaignMap, List<Campaign> oldCampaignList, Map<Id,Campaign> oldCampaignMap){
        
    }
    
    public void OnAfterDelete(List<Campaign> newCampaignList, Map<Id,Campaign> newCampaignMap, List<Campaign> oldCampaignList, Map<Id,Campaign> oldCampaignMap){
        if(!isAfterDeleteTriggerCalled){
            AP51_CampaignTriggerBL.rollUpMarketingProgramForecastedCostAndActualCost(oldCampaignList, null);
            
            isAfterDeleteTriggerCalled = TRUE;
        }
    }
     
}