/**
  * @author -         Jerome To (ACN)
  * @date -           MAY 21, 2016
  * @description -    Logic for Marketing Budget Trigger Handler
  * #############Change Log#############
  * Modified by     Version     Change Date
  * Simon M         2.0         2017-01-30 -- Changed call to getDMLLog as this is now private, call getSaveResultLog instead
**/

public with sharing class AP56_MarketingBudgetTriggerBL {
    static final String CLASS_NAME = 'AP56_MarketingBudgetTriggerBL';

    public static Decimal getConversion(Decimal amount, String currencyISOCode){
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

    public static void rollUpTotalForcastedCampaignSpend(List<MarketingBudget__c> newMarketingBudgetList, Map<Id, MarketingBudget__c> oldMarketingBudgetMap){    
        
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Savepoint sp = Database.setSavePoint();
        Set<Id> aggregatedMarketingBudgetIds = new Set<Id>();
        Set<Id> marketingBudgetIdSet = new Set<Id>();
        List<MarketingBudget__c> marketingBudgetsToUpdate = new List<MarketingBudget__c>();

        try{
            for(MarketingBudget__c marketingBudget : newMarketingBudgetList) {
                if(!String.isEmpty(marketingBudget.Parent_Marketing_Budget__c)){
                    marketingBudgetIdSet.add(marketingBudget.Parent_Marketing_Budget__c);
                }
                if(oldMarketingBudgetMap <> null &&
                   oldMarketingBudgetMap.containsKey(marketingBudget.Id) &&
                   (marketingBudget.Parent_Marketing_Budget__c <> oldMarketingBudgetMap.get(marketingBudget.Id).Parent_Marketing_Budget__c) &&
                   !String.isEmpty(oldMarketingBudgetMap.get(marketingBudget.Id).Parent_Marketing_Budget__c)){
                   marketingBudgetIdSet.add(oldMarketingBudgetMap.get(marketingBudget.Id).Parent_Marketing_Budget__c);
                   marketingBudgetIdSet.add(marketingBudget.Parent_Marketing_Budget__c);
                }
            }

            if(!marketingBudgetIdSet.isEmpty()) {
                AggregateResult[] aggregateResults = [SELECT Parent_Marketing_Budget__c, SUM(TotalForecastedCampaignSpend__c), 
                                                             SUM(TotalCommittedFunds__c), SUM(TotalActualCampaignSpend__c)
                                                      FROM MarketingBudget__c
                                                      WHERE Parent_Marketing_Budget__c IN: marketingBudgetIdSet
                                                      GROUP BY Parent_Marketing_Budget__c];

                Map<Id, MarketingBudget__c> marketingBudgetMap = new Map<Id, MarketingBudget__c>([SELECT Parent_Marketing_Budget__c, Total_Associated_Budget_Forecast_Cost__c, 
                                                                                                         Total_Associated_Committed_Funds__c, Total_Associated_Actual_Campaign_Spend__c,
                                                                                                         CurrencyISOCode
                                                                                                  FROM MarketingBudget__c
                                                                                                  WHERE Id IN:marketingBudgetIdSet]);

                if(!aggregateResults.isEmpty()){
                    for(AggregateResult ar : aggregateResults) {
                        Id marketingBudgetId = String.valueOf(ar.get('Parent_Marketing_Budget__c'));
                        if(marketingBudgetMap.containsKey(marketingBudgetId)) {
                            String forecastedCost = String.valueOf(ar.get('expr0'));
                            String committedFunds = String.valueOf(ar.get('expr1'));
                            String actualCampaignSpend = String.valueOf(ar.get('expr2'));
                            MarketingBudget__c marketingBudget = marketingBudgetMap.get(marketingBudgetId);                            
                            marketingBudget.Total_Associated_Budget_Forecast_Cost__c = getConversion(Decimal.valueOf(!String.isEmpty(forecastedCost)?forecastedCost : '0'), marketingBudget.CurrencyISOCode);
                            marketingBudget.Total_Associated_Committed_Funds__c = getConversion(Decimal.valueOf(!String.isEmpty(committedFunds)?committedFunds : '0'), marketingBudget.CurrencyISOCode);
                            marketingBudget.Total_Associated_Actual_Campaign_Spend__c = getConversion(Decimal.valueOf(!String.isEmpty(actualCampaignSpend)?actualCampaignSpend : '0'), marketingBudget.CurrencyISOCode);
                            marketingBudgetsToUpdate.add(marketingBudget);
                            aggregatedMarketingBudgetIds.add(marketingBudgetId);
                        }
                    }
                }

                for(MarketingBudget__c marketingBudget : marketingBudgetMap.values()) {
                    if(!aggregatedMarketingBudgetIds.contains(marketingBudget.Id)) {
                        marketingBudget.Total_Associated_Budget_Forecast_Cost__c = 0;
                        marketingBudget.Total_Associated_Committed_Funds__c = 0;
                        marketingBudget.Total_Associated_Actual_Campaign_Spend__c = 0;
                        marketingBudgetsToUpdate.add(marketingBudget);
                    }
                }

                if(!marketingBudgetsToUpdate.isEmpty()) {
                    logs.addAll(getResultLogs(Database.update(marketingBudgetsToUpdate, false)));                    
                }
            }
        } catch (Exception e) {
            logs.add(ApplicationConstant.getExceptionLog(e, 'rollUpTotalForcastedCampaignSpend()', CLASS_NAME, null));
            Database.rollback(sp);
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }

    static List<Error_Log__c> getResultLogs(List<Database.SaveResult> listSaveResults)   {
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        //2017-01-30 : SM : getDMLLog is now private so call getSaveResultLog instead
        errorLogs.addAll(ApplicationConstant.getSaveResultLog(listSaveResults, 'rollUpTotalForcastedCampaignSpend', CLASS_NAME, 'Marketing_Budget__c', 'Update'));
        /*Error_Log__c log = new Error_Log__c();              
        for(Database.SaveResult saveResult : listSaveResults){
            log = ApplicationConstant.getDMLLog(saveResult, 'rollUpTotalForcastedCampaignSpend()', CLASS_NAME, 'MarketingBudget__c', 'Update');                    
            errorLogs.add(log);                
        }
        */
        return errorLogs;
    }
}