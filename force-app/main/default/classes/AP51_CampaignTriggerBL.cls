/**
  * @author -         Jerome To (ACN)
  * @date -           MAY 11, 2016
  * @description -    Business logic Function for AP47_CampaignForecastHandler
  * #############Change Log#############
  * Modified by     Version     Change Date
  * patrick.c.villarica 1.1     May 14, 2016 -- Add a new method to populate the Type and Strategy field from its Parent Campaign
  * Simon M         1.2         Jan 30, 2017 -- Changed call to getDMLLog as this is now private, use getSaveResultLog instead
  **/

public with sharing class AP51_CampaignTriggerBL {

    // Used for logging --- Added by Dee 5/15
    public static final String CLASS_NAME = 'AP51_CampaignTriggerBL';
    
    static final Map<String, Id> campaignRecordTypes;
    static{
        campaignRecordTypes = new Map<String, Id>();
        for(RecordType recType : [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Campaign']){
            campaignRecordTypes.put(recType.DeveloperName, recType.Id);
        }
    }

    static Decimal getConversion(Decimal amount, String currencyISOCode){
        return (conversionRate.containsKey(currencyISOCode) ? (Decimal)(amount * conversionRate.get(currencyISOCode)) : 0);
    }

    static final Map<String, Double> conversionRate;
    static{
        conversionRate = new Map<String, Double>();
        for(CurrencyType ct : [SELECT Isocode, Conversionrate FROM CurrencyType]){
            if(!conversionRate.containsKey(ct.isoCode) && !String.isEmpty(ct.isoCode)){
                conversionRate.put(ct.isoCode , ct.conversionRate);
            }
        }        
    }

    //method for rolling up marketing program forecasted cost and actual cost
    public static void rollUpMarketingProgramForecastedCostAndActualCost(List<Campaign> newCampaignList, Map<Id, Campaign> oldCampaignMap){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Set<Id> campaignIdSet = new Set<Id>();
        List<Campaign> campaignsToUpdate = new List<Campaign>();
        Map<Id, Decimal> campaignIdAndForecastedCostMap = new Map<Id, Decimal>();
        Map<Id, Decimal> campaignIdAndActualCostMap = new Map<Id, Decimal>();

        Savepoint sp = Database.setSavePoint();
        
        try{
            for(Campaign campaignRec : newCampaignList){
                if(campaignRec.RecordTypeId == campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_CAMPAIGN_EVENT)) {                    
                    if(!String.isEmpty(campaignRec.ParentId)){
                       campaignIdSet.add(campaignRec.ParentId);
                    }                                     
                    if(oldCampaignMap <> null &&
                        oldCampaignMap.containsKey(campaignRec.Id) &&
                        (campaignRec.ParentId <> oldCampaignMap.get(campaignRec.Id).ParentId) &&
                        !String.isEmpty(oldCampaignMap.get(campaignRec.Id).ParentId)) {                            
                        campaignIdSet.add(oldCampaignMap.get(campaignRec.Id).ParentId);
                    }                     
                }                  
            }
    
            for(AggregateResult ar : [SELECT ParentId, SUM(Forecasted_Cost__c), SUM(Actual_Cost__c)
                                      FROM Campaign
                                      WHERE ParentId =:campaignIdSet
                                      AND RecordTypeId =:campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_CAMPAIGN_EVENT)
                                      GROUP BY ParentId]){           

                Id campaignId = String.valueOf(ar.get('ParentId'));
                String forecastedCost = String.valueOf(ar.get('expr0'));
                String actualCost = String.valueOf(ar.get('expr1'));
                campaignIdAndForecastedCostMap.put(campaignId, Decimal.valueOf(!String.isEmpty(forecastedCost)? forecastedCost: '0'));                
                campaignIdAndActualCostMap.put(campaignId,Decimal.valueOf(!String.isEmpty(actualCost)? actualCost: '0')); 
            }
            
            for(Campaign campaign : [SELECT Id, Forecasted_Cost__c, Actual_Cost__c, CurrencyISOCode  
                                     FROM Campaign 
                                     WHERE Id IN:campaignIdSet
                                     AND RecordTypeId =:campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_PROGRAM)]){
                if(campaignIdAndForecastedCostMap.containsKey(campaign.Id) &&
                   campaignIdAndActualCostMap.containsKey(campaign.Id) ){
                    campaign.Forecasted_Cost__c = getConversion(campaignIdAndForecastedCostMap.get(campaign.Id), campaign.CurrencyISOCode);
                    campaign.Actual_Cost__c = getConversion(campaignIdAndActualCostMap.get(campaign.Id), campaign.CurrencyISOCode);
                }else {
                    campaign.Forecasted_Cost__c = 0;
                    campaign.Actual_Cost__c = 0; 
                }
                campaignsToUpdate.add(campaign);
            }
                
            if(!campaignsToUpdate.isEmpty()){         
                Database.SaveResult[] updateCampaignMap = Database.update(campaignsToUpdate, false);
                //2017-01-30 : SM : getDMLLog is now private so call getSaveResultLog instead
                logs.addAll(ApplicationConstant.getSaveResultLog(updateCampaignMap, 'rollUpMarketingProgramForecastedCostAndActualCost', CLASS_NAME, ApplicationConstant.CALENDAR_CAMPAIGN, 'Update'));            
                /*Error_Log__c log;            
                for(Database.SaveResult saveResult : updateCampaignMap){
                    log = ApplicationConstant.getDMLLog(saveResult, 'rollUpMarketingProgramForecastedCostAndActualCost()', CLASS_NAME, ApplicationConstant.CALENDAR_CAMPAIGN, 'Update');                    
                    logs.add(log);                    
                }
                */
            }
        } catch (Exception e) {
            logs.add(ApplicationConstant.getExceptionLog(e, 'rollUpMarketingProgramForecastedCostAndActualCost()', CLASS_NAME, null));
            Database.rollback(sp);
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }
    
     /**
       *  This method is used to default field child values from its Parent Campaign'
       *  @name: populateChildCampaignField
       *  @developer: patrick.c.villarica 14/05/2016
       *  @param: newCampList - get Trigger.new from CampaignTrigger of List<Campaign> Data Type
       *        : oldCampMap - get Trigger.oldMap from CampaignTrigger of Map<Id, Campaign> Data Type
    **/
    public static void populateChildCampaignField(List<Campaign> newCampList, Map<Id, Campaign> oldCampMap) {
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        List<Id> parentCampIdList = new List<Id> ();
        Map<Id, Campaign> parentCampdetails = new Map<Id, Campaign> ();
        Savepoint sp = Database.setSavePoint();
        
        try{
            for(Campaign camp: newCampList) {
            
                if(campaignRecordTypes.containsKey(ApplicationConstant.CAMPAIGN_MARKETING_CAMPAIGN_EVENT)) {
                
                    if(campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_CAMPAIGN_EVENT) == camp.RecordTypeId) {
                    
                        if(oldCampMap == null) {
                        
                            if(camp.ParentId <> null) {
                            
                                parentCampIdList.add(camp.ParentId);
                            }
                        } else {
                            if(oldCampMap.containsKey(camp.Id)) {
                                if(camp.ParentId <> oldCampMap.get(camp.Id).ParentId) {
                                    if(camp.ParentId <> null) {
                                        
                                        parentCampIdList.add(camp.ParentId);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            if(parentCampIdList.size() > 0) {
            
                parentCampdetails = new Map<Id, Campaign> ([Select Id, Type, MarketingStrategy__c from Campaign WHERE ID IN: parentCampIdList]);
            }
            
            if(parentCampdetails.size() > 0) {
            
                for(Campaign c: newCampList) {
                
                    if(campaignRecordTypes.containsKey(ApplicationConstant.CAMPAIGN_MARKETING_CAMPAIGN_EVENT)) {
                    
                        if(campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_CAMPAIGN_EVENT) == c.RecordTypeId) {
                        
                            if(c.ParentId <> null && parentCampdetails.containsKey(c.ParentId)) {
                            
                                c.Type = parentCampdetails.get(c.ParentId).Type;
                                c.MarketingStrategy__c = parentCampdetails.get(c.ParentId).MarketingStrategy__c;
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            logs.add(ApplicationConstant.getExceptionLog(e, 'populateChildCampaignField()', CLASS_NAME, null));
            Database.rollback(sp);
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }        
    }
}