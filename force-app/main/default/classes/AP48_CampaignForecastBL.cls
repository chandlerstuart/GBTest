/**
  * @author -         Jerome To (ACN)
  * @date -           MAY 11, 2016
  * @description -   Business logic Function for AP47_CampaignForecastHandler
  * #############Change Log#############
  * Modified by     Version     Change Date
  * Simon M:        2.0         2017-01-30      Changed call to getDMLLog, to getSaveResultLog as getDMLLog is now private
  **/

public with sharing class AP48_CampaignForecastBL {
    static final String CLASS_NAME = 'AP48_CampaignForecastBL';

    static final Map<String, Id> campaignRecordTypes;
    static{
        campaignRecordTypes = new Map<String, Id>();
        for(RecordType recType : [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Campaign']){
            campaignRecordTypes.put(recType.DeveloperName, recType.Id);
        }
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

    private static Decimal getConversion(Decimal amount, String currencyISOCode){
        return (conversionRate.containsKey(currencyISOCode) ? (Decimal)(amount * conversionRate.get(currencyISOCode)) : 0);
    }

    public static void rollUpForecastedCost(List<CampaignForecast__c> newCampaignForecastList, Map<Id,CampaignForecast__c> oldCampaignForecastMap){
        // For error handling
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Savepoint sp = Database.setSavePoint();

        // list of record Ids to Update
        Set<Id> campaignIdSet = new Set<Id>();
        Set<Id> budgetCostCenterIdSet = new Set<Id>();

        // records to update
        List<Campaign> campaignsToUpdate = new List<Campaign>();
        List<BudgetCostCenter__c> budgetCostCentersToUpdate = new List<BudgetCostCenter__c>();

        Map<Id, Decimal> campaignIdAndForecastedCostMap = new Map<Id, Decimal>();
        Map<Id, Decimal> budgetCostCenterIdAndForecastedCostMap = new Map<Id, Decimal>();
        
        try{
            // get list of record Ids to Update
            for(CampaignForecast__c campaignForecastRec : newCampaignForecastList){
                if(!String.isEmpty(campaignForecastRec.AssociatedCampaign__c)){
                    campaignIdSet.add(campaignForecastRec.AssociatedCampaign__c);
                }
                if(!String.isEmpty(campaignForecastRec.AssociatedBudgetFinancialAccount__c)){
                    budgetCostCenterIdSet.add(campaignForecastRec.AssociatedBudgetFinancialAccount__c);
                }
                                                     
                if(oldCampaignForecastMap <> null && oldCampaignForecastMap.containsKey(campaignForecastRec.Id)) {
                    if((campaignForecastRec.AssociatedCampaign__c <> oldCampaignForecastMap.get(campaignForecastRec.Id).AssociatedCampaign__c) &&
                        !String.isEmpty(oldCampaignForecastMap.get(campaignForecastRec.Id).AssociatedCampaign__c)) {                            
                        campaignIdSet.add(oldCampaignForecastMap.get(campaignForecastRec.Id).AssociatedCampaign__c);
                    }
                    if((campaignForecastRec.AssociatedBudgetFinancialAccount__c <> oldCampaignForecastMap.get(campaignForecastRec.Id).AssociatedBudgetFinancialAccount__c) &&
                        !String.isEmpty(oldCampaignForecastMap.get(campaignForecastRec.Id).AssociatedBudgetFinancialAccount__c)) {                            
                        budgetCostCenterIdSet.add(oldCampaignForecastMap.get(campaignForecastRec.Id).AssociatedBudgetFinancialAccount__c);
                    }
                }       
            }
            
            for(AggregateResult ar : [SELECT AssociatedCampaign__c, SUM(ForecastedCost__c)
                                      FROM CampaignForecast__c
                                      WHERE AssociatedCampaign__c =:campaignIdSet
                                      GROUP BY AssociatedCampaign__c]){           

                Id campaignId = String.valueOf(ar.get('AssociatedCampaign__c'));
                String forecastedCost = String.valueOf(ar.get('expr0'));
                campaignIdAndForecastedCostMap.put(campaignId, Decimal.valueOf(!String.isEmpty(forecastedCost) ? forecastedCost : '0') );
            } 
            
            for(Campaign campaign : [SELECT Id, CurrencyISOCode, Forecasted_Cost__c 
                                     FROM Campaign 
                                     WHERE Id IN: campaignIdSet
                                     AND RecordTypeId =:campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_CAMPAIGN_EVENT)]) {
                if(campaignIdAndForecastedCostMap.containsKey(campaign.Id)){
                    campaign.Forecasted_Cost__c = getConversion(campaignIdAndForecastedCostMap.get(campaign.Id) , campaign.CurrencyISOCode); 
                    
                } else{
                    campaign.Forecasted_Cost__c = 0;
                }

                campaignsToUpdate.add(campaign);
            }
            
            // end Campaign

            // start Budget Cost Center
            for(AggregateResult ar : [SELECT AssociatedBudgetFinancialAccount__c, SUM(ForecastedCost__c)
                                      FROM CampaignForecast__c
                                      WHERE AssociatedBudgetFinancialAccount__c =:budgetCostCenterIdSet
                                      GROUP BY AssociatedBudgetFinancialAccount__c]){           

                Id budgetCostCenterId = String.valueOf(ar.get('AssociatedBudgetFinancialAccount__c'));
                String forecastedCost = String.valueOf(ar.get('expr0'));
                budgetCostCenterIdAndForecastedCostMap.put(budgetCostCenterId, Decimal.valueOf(!String.isEmpty(forecastedCost) ? forecastedCost : '0'));
            } 
            for(BudgetCostCenter__c budgetCostCenter : [SELECT Id, CurrencyISOCode, TotalForecastedCampaignSpend__c  
                                                        FROM BudgetCostCenter__c 
                                                        WHERE Id IN: budgetCostCenterIdSet]){
                if(budgetCostCenterIdAndForecastedCostMap.containsKey(budgetCostCenter.Id)){
                    budgetCostCenter.TotalForecastedCampaignSpend__c = getConversion(budgetCostCenterIdAndForecastedCostMap.get(budgetCostCenter.Id), budgetCostCenter.CurrencyISOCode); 
                } else {
                    budgetCostCenter.TotalForecastedCampaignSpend__c = 0; 
                }
                budgetCostCentersToUpdate.add(budgetCostCenter);
            }
            
            // end Budget Cost Center
                
            if(!campaignsToUpdate.isEmpty()){         
                logs.addAll(getResultLogs(Database.update(campaignsToUpdate, false), 'rollUpForecastedCost()', 'Campaign'));       
            }
            // update on Budget Cost Center
            if(!budgetCostCentersToUpdate.isEmpty()){  
                logs.addAll(getResultLogs(Database.update(budgetCostCentersToUpdate, false), 'rollUpForecastedCost()', 'Budget Cost Center'));       
            } 
        } catch (Exception e) {
            logs.add(ApplicationConstant.getExceptionLog(e, 'rollUpForecastedCost()', CLASS_NAME, null));
            Database.rollback(sp);
        } finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }   
    }

    private static List<Error_Log__c> getResultLogs(List<Database.SaveResult> listSaveResults, String methodName, String objectName)   {
        List<Error_Log__c> resultLogs = new List<Error_Log__c>();
        //2017-01-30 : SM : getDMLLog is now private so call getSaveResultLog instead
        resultLogs.addAll(ApplicationConstant.getSaveResultLog(listSaveResults, methodName, CLASS_NAME, objectName, 'Update'));

        /*Error_Log__c log = new Error_Log__c();                
        for(Database.SaveResult saveResult : listSaveResults){
            log = ApplicationConstant.getDMLLog(saveResult, methodName, CLASS_NAME, objectName, 'Update');                    
            resultLogs.add(log);                
        }*/
        return resultLogs;
    }
}