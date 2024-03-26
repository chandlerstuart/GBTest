/**
  * @author -         Jerome To (ACN)
  * @date -           MAY 11, 2016
  * @description -   Business logic Function for AP49_POInvoiceHandler
  * #############Change Log#############
  * Modified by     Version     Change Date
  * Simon Molloy (Golfbreaks)   01-SEPT-2016  
  * If CurrencyISOCode of POInvoice == BudgetCostCentre CurrencyISOCode we do NOT convert the values for the totals
  * Simon Molloy (Golfbreaks)   30-JAN-2017
  * Changed call to getDMLLog as this is now private, calling instead getSaveResultLog
  **/

public with sharing class AP50_POInvoiceBL {
    static final String DKK_ISO_CODE = 'DKK';
    static final String GBP_ISO_CODE = 'GBP';
    static final String SEK_ISO_CODE = 'SEK';
    
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

    static final String CLASS_NAME = 'AP50_POInvoiceBL';

    public static void updateTotalAmountBUCurrency(List<POInvoice__c> newPOInvoiceList, Map<Id, POInvoice__c> oldPOInvoiceMap){
        Set<Id> budgetCostCenterIds = new Set<Id>();
        for(POInvoice__c poInvoice : newPOInvoiceList){
            if(!String.isEmpty(poInvoice.BudgetCostCenter__c) && !budgetCostCenterIds.contains(poInvoice.BudgetCostCenter__c)){
                budgetCostCenterIds.add(poInvoice.BudgetCostCenter__c);
            }            
        }

        Map<Id, BudgetCostCenter__c> budgetCostCenterMap = new Map<Id, BudgetCostCenter__c>([SELECT Id, CurrencyISOCode FROM BudgetCostCenter__c WHERE Id IN:budgetCostCenterIds]);

        if(!budgetCostCenterMap.isEmpty()){
            for(POInvoice__c poInvoice : newPOInvoiceList){
                if(!String.isEmpty(poInvoice.BudgetCostCenter__c) && budgetCostCenterMap.containsKey(poInvoice.BudgetCostCenter__c)){
                    //Simon Molloy (Golfbreaks) 01-SEPT-2016 : If the CurrencyISOCodes match on Budegt Cost Centre and PO Invoice, do not convert
                    if (poInvoice.CurrencyISOCode != budgetCostCenterMap.get(poInvoice.BudgetCostCenter__c).CurrencyISOCode){
                        if (poInvoice.Converted_Total_Amount__c == null || (oldPOInvoiceMap.get(poInvoice.Id).Total_Amount__c != poInvoice.Total_Amount__c)){
                            if (SEK_ISO_CODE.equalsIgnoreCase(poInvoice.CurrencyIsoCode)){
                                double gbpAmount = (Decimal)poInvoice.Total_Amount__c / conversionRate.get(SEK_ISO_CODE);
                                poInvoice.Converted_Total_Amount__c = getConversion(gbpAmount, budgetCostCenterMap.get(poInvoice.BudgetCostCenter__c).CurrencyIsoCode);
                            }else {
                                poInvoice.Converted_Total_Amount__c = getConversion(poInvoice.Total_Amount__c, budgetCostCenterMap.get(poInvoice.BudgetCostCenter__c).CurrencyISOCode);                            
                            }
                        }
                    }else {
                        if (poInvoice.Converted_Total_Amount__c == null || (oldPOInvoiceMap.get(poInvoice.Id).Total_Amount__c != poInvoice.Total_Amount__c)){
                            poInvoice.Converted_Total_Amount__c = poInvoice.Total_Amount__c;
                        }
                    }                    
                }        
                if(String.isEmpty(poInvoice.BudgetCostCenter__c)){
                    poInvoice.Converted_Total_Amount__c = 0;
                }   
            }
        }
    }    

    public static void updateCommittedFund(List<POInvoice__c> newPOInvoiceList, Map<Id,POInvoice__c> oldPOInvoiceMap){
        // For error handling
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Savepoint sp = Database.setSavePoint();
        
        Set<Id> committedFundIdSet = new Set<Id>();
        //Set<Id> aggregatedCommittedFundIdSet = new Set<Id>();
        List<PurchaseOrder__c> committedFundsToUpdate = new List<PurchaseOrder__c>();

        Map<Id, Boolean> committedFundIdAndHasAssociatedPOInvoiceMap = new Map<Id, Boolean>();
        
        try{
            // get list of record Ids to Update
            for(POInvoice__c poInvoice : newPOInvoiceList){
                if(!String.isEmpty(poInvoice.CommittedFund__c)){
                    if(!committedFundIdSet.contains(poInvoice.CommittedFund__c)){
                        committedFundIdSet.add(poInvoice.CommittedFund__c);
                    }     
                }            
                if(oldPOInvoiceMap <> null &&
                    oldPOInvoiceMap.containsKey(poInvoice.Id) &&
                    (poInvoice.CommittedFund__c <> oldPOInvoiceMap.get(poInvoice.Id).CommittedFund__c) &&
                    !String.isEmpty(oldPOInvoiceMap.get(poInvoice.Id).CommittedFund__c)) {                            
                    committedFundIdSet.add(oldPOInvoiceMap.get(poInvoice.Id).CommittedFund__c);
                }
            }
            
            for(AggregateResult ar : [SELECT CommittedFund__c, Count(Total_Amount__c)
                                      FROM POInvoice__c
                                      WHERE CommittedFund__c =:committedFundIdSet
                                      GROUP BY CommittedFund__c]){           

                Id committedFundId = String.valueOf(ar.get('CommittedFund__c'));
                String actualCount = String.valueOf(ar.get('expr0'));
                committedFundIdAndHasAssociatedPOInvoiceMap.put(committedFundId, (Decimal.valueOf(!String.isEmpty(actualCount)?actualCount : '0') > 0));
            }
            
            
            for(PurchaseOrder__c committedFund : [SELECT Id, Has_associated_POInvoice__c   
                                                  FROM PurchaseOrder__c 
                                                  WHERE Id IN: committedFundIdSet]) {
                if(committedFundIdAndHasAssociatedPOInvoiceMap.containsKey(committedFund.Id)) {
                    committedFund.Has_associated_POInvoice__c = committedFundIdAndHasAssociatedPOInvoiceMap.get(committedFund.Id); 
                }else{
                    committedFund.Has_associated_POInvoice__c = false;
                }

                committedFundsToUpdate.add(committedFund);
            }
            

            if(!committedFundsToUpdate.isEmpty()){         
                logs.addAll(getResultLogs(Database.update(committedFundsToUpdate, false)));         
            }
        } catch (Exception e) {
            logs.add(ApplicationConstant.getExceptionLog(e, 'updateCommittedFund()', CLASS_NAME, null));
            Database.rollback(sp);
        } finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        } 
    }

    public static void rollUpTotalAmount(List<POInvoice__c> newPOInvoiceList, Map<Id,POInvoice__c> oldPOInvoiceMap){
        // For error handling
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Savepoint sp = Database.setSavePoint();

        // list of record Ids to Update
        Set<Id> campaignIdSet = new Set<Id>();
        Set<Id> budgetCostCenterIdSet = new Set<Id>();
        Set<Id> aggregatedBudgetCostCenterIdSet = new Set<Id>();

        // records to update
        List<Campaign> campaignsToUpdate = new List<Campaign>();
        List<BudgetCostCenter__c> budgetCostCentersToUpdate = new List<BudgetCostCenter__c>();

        Map<Id, Decimal> campaignIdAndActualCostMap = new Map<Id, Decimal>();
        Map<Id, Decimal> budgetCostCenterIdAndTotalAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> budgetCostCenterIdAndConvertedTotalAmountMap = new Map<Id, Decimal>();
        
        try {
            // get list of record Ids to Update
            for(POInvoice__c poInvoice : newPOInvoiceList){
                if(!String.isEmpty(poInvoice.Campaign__c)){
                    campaignIdSet.add(poInvoice.Campaign__c);
                } 
                if(!String.isEmpty(poInvoice.BudgetCostCenter__c)){
                    budgetCostCenterIdSet.add(poInvoice.BudgetCostCenter__c);
                }            
                if(oldPOInvoiceMap <> null && oldPOInvoiceMap.containsKey(poInvoice.Id)) {
                    if((poInvoice.Campaign__c <> oldPOInvoiceMap.get(poInvoice.Id).Campaign__c) &&
                        !String.isEmpty(oldPOInvoiceMap.get(poInvoice.Id).Campaign__c)) {                            
                        campaignIdSet.add(oldPOInvoiceMap.get(poInvoice.Id).Campaign__c);
                    }
                    if((poInvoice.BudgetCostCenter__c <> oldPOInvoiceMap.get(poInvoice.Id).BudgetCostCenter__c) &&
                        !String.isEmpty(oldPOInvoiceMap.get(poInvoice.Id).BudgetCostCenter__c)) {                            
                        budgetCostCenterIdSet.add(oldPOInvoiceMap.get(poInvoice.Id).BudgetCostCenter__c);
                    }
                }
            }
            
            for(AggregateResult ar : [SELECT Campaign__c, SUM(Total_Amount__c)
                                      FROM POInvoice__c
                                      WHERE Campaign__c IN:campaignIdSet
                                      GROUP BY Campaign__c]) {           

                Id campaignId = String.valueOf(ar.get('Campaign__c'));
                String actualCost = String.valueOf(ar.get('expr0'));
                campaignIdAndActualCostMap.put(campaignId, Decimal.valueOf(!String.isEmpty(actualCost)?actualCost : '0')); 
            }
        
            for(Campaign campaign : [SELECT Id, Actual_Cost__c, CurrencyISOCode 
                                     FROM Campaign 
                                     WHERE Id IN: campaignIdSet
                                     AND RecordTypeId =:campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_CAMPAIGN_EVENT)]){
                if(campaignIdAndActualCostMap.containsKey(campaign.Id)){
                    campaign.Actual_Cost__c = getConversion(campaignIdAndActualCostMap.get(campaign.Id), campaign.CurrencyISOCode);
                }else {
                    campaign.Actual_Cost__c = 0;                    
                }
                campaignsToUpdate.add(campaign);
            }
            // end Campaign

            // start Budget Cost Center
            for(AggregateResult ar : [SELECT BudgetCostCenter__c, SUM(Total_Amount__c), SUM(Converted_Total_Amount__c)
                                      FROM POInvoice__c
                                      WHERE BudgetCostCenter__c =:budgetCostCenterIdSet
                                      GROUP BY BudgetCostCenter__c]) {           

                Id budgetCostCenterId = String.valueOf(ar.get('BudgetCostCenter__c'));
                String actualCost = String.valueOf(ar.get('expr0'));
                String totalAmountBUCurrencyCost = String.valueOf(ar.get('expr1'));
                budgetCostCenterIdAndTotalAmountMap.put(budgetCostCenterId, Decimal.valueOf(!String.isEmpty(actualCost)?actualCost : '0'));
                budgetCostCenterIdAndConvertedTotalAmountMap.put(budgetCostCenterId, Decimal.valueOf(!String.isEmpty(totalAmountBUCurrencyCost)?totalAmountBUCurrencyCost : '0'));
            }
            
            for(BudgetCostCenter__c budgetCostCenter : [SELECT Id, TotalActualCampaignSpend__c, 
                                                               Total_Amount_BU_Currency__c, CurrencyISOCode
                                                        FROM BudgetCostCenter__c 
                                                        WHERE Id IN: budgetCostCenterIdSet]){
                if(budgetCostCenterIdAndTotalAmountMap.containsKey(budgetCostCenter.Id) &&
                    budgetCostCenterIdAndConvertedTotalAmountMap.containsKey(budgetCostCenter.Id)) {
                    budgetCostCenter.TotalActualCampaignSpend__c = getConversion(budgetCostCenterIdAndTotalAmountMap.get(budgetCostCenter.Id), budgetCostCenter.CurrencyISOCode);
                    budgetCostCenter.Total_Amount_BU_Currency__c = budgetCostCenterIdAndConvertedTotalAmountMap.get(budgetCostCenter.Id);
                    
                } else {
                    budgetCostCenter.TotalActualCampaignSpend__c = 0; 
                    budgetCostCenter.Total_Amount_BU_Currency__c = 0;
                }
                budgetCostCentersToUpdate.add(budgetCostCenter);
            }
            
            
            // end Budget Cost Center

            // update on Campaign
            if(!campaignsToUpdate.isEmpty()){        
                logs.addAll(getResultLogs(Database.update(campaignsToUpdate, false)));
            } 
            // update on Budget Cost Center
            if(!budgetCostCentersToUpdate.isEmpty()) {         
                logs.addAll(getResultLogs(Database.update(budgetCostCentersToUpdate, false)));
            } 
        } catch (Exception e) {
            logs.add(ApplicationConstant.getExceptionLog(e, 'rollUpTotalAmount()', CLASS_NAME, null));
            Database.rollback(sp);
        } finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }    
    }

    private static List<Error_Log__c> getResultLogs(List<Database.SaveResult> listSaveResults)   {
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        //2017-01-30 : SM : getDMLLog is now private so call getSaveResultLog instead
        errorLogs.addAll(ApplicationConstant.getSaveResultLog(listSaveResults, 'rollUpTotalAmount', CLASS_NAME, 'Campaign','Update'));
        /*Error_Log__c log = new Error_Log__c();              
        for(Database.SaveResult saveResult : listSaveResults){
            log = ApplicationConstant.getDMLLog(saveResult, 'rollUpTotalAmount()', CLASS_NAME, 'Campaign', 'Update');                    
            errorLogs.add(log);                
        }
        */
        return errorLogs;
    }
    
}