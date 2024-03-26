/**
  * @author -         Jerome To (ACN)
  * @date -           MAY 11, 2016
  * @description -    Handler for CampaignForecastTrigger
  * #############Change Log#############
  * Modified by     Version     Change Date
  **/

public with sharing class AP47_CampaignForecastHandler {
    public AP47_CampaignForecastHandler() {
        
    }

    public void OnBeforeInsert(List<CampaignForecast__c> newCampaignForecastList){
        
    }   
    
    public void OnBeforeUpdate(List<CampaignForecast__c> newCampaignForecastList, Map<Id,CampaignForecast__c> newCampaignForecastMap, List<CampaignForecast__c> oldCampaignForecastList, Map<Id,CampaignForecast__c> oldCampaignForecastMap){
    
     }
    
    public void OnAfterInsert(List<CampaignForecast__c> newCampaignForecastList, Map<Id,CampaignForecast__c> newCampaignForecastMap, List<CampaignForecast__c> oldCampaignForecastList, Map<Id,CampaignForecast__c> oldCampaignForecastMap){
        AP48_CampaignForecastBL.rollUpForecastedCost(newCampaignForecastList, null);
    }
    
    public void OnAfterUpdate(List<CampaignForecast__c> newCampaignForecastList, Map<Id,CampaignForecast__c> newCampaignForecastMap, List<CampaignForecast__c> oldCampaignForecastList, Map<Id,CampaignForecast__c> oldCampaignForecastMap){
        AP48_CampaignForecastBL.rollUpForecastedCost(newCampaignForecastList, oldCampaignForecastMap);
    }
    
    public void OnBeforeDelete(List<CampaignForecast__c> newCampaignForecastList, Map<Id,CampaignForecast__c> newCampaignForecastMap, List<CampaignForecast__c> oldCampaignForecastList, Map<Id,CampaignForecast__c> oldCampaignForecastMap){
        
    }
    
    public void OnAfterDelete(List<CampaignForecast__c> newCampaignForecastList, Map<Id,CampaignForecast__c> newCampaignForecastMap, List<CampaignForecast__c> oldCampaignForecastList, Map<Id,CampaignForecast__c> oldCampaignForecastMap){
        AP48_CampaignForecastBL.rollUpForecastedCost(oldCampaignForecastList, null);
    }
     
    //public void OnAfterUnDelete(List<CampaignForecast__c> newCampaignForecastList, Map<Id,CampaignForecast__c> newCampaignForecastMap, List<CampaignForecast__c> oldCampaignForecastList, Map<Id,CampaignForecast__c> oldCampaignForecastMap){
        
    //}
    
    //public void OnUndelete(List<CampaignForecast__c> newCampaignForecastList, Map<Id,CampaignForecast__c> newCampaignForecastMap, List<CampaignForecast__c> oldCampaignForecastList, Map<Id,CampaignForecast__c> oldCampaignForecastMap){
        
    //}
}