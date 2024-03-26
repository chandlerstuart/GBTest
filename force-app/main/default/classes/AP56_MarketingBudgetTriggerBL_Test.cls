/**
* Class Name: AP56_MarketingBudgetTriggerBL_Test
* @author: Jerome To
* @date: June 7 , 2016
* @description: Test AP56_MarketingBudgetTriggerBL
*/

@isTest(seeAllData=false)
public class AP56_MarketingBudgetTriggerBL_Test{
    
    static final Map<String, Id> campaignRecordTypes;
    static{
        campaignRecordTypes = new Map<String, Id>();
        for(RecordType recType : [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Campaign']){
            campaignRecordTypes.put(recType.DeveloperName, recType.Id);
        }
    }

    @testSetup static void setupData(){
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;  

        //Create Supplier
        List<Account> lAcc = AP23_TestDataFactory.createAccount(1);
        insert lAcc;

        //Create Marketing  Strategy
        List<MarketingStrategy__c> lMS = new List<MarketingStrategy__c>();
        MarketingStrategy__c MS01 = new MarketingStrategy__c(Name = 'Test Marketing Strategy 01', CurrencyIsoCode = 'GBP');
        lMS.add(MS01);
        insert lMS;
        
        //Create campaign
        List<Campaign> lCamp = AP23_TestDataFactory.createCampaign(1, MS01.Id);
        for(Campaign campaign : lCamp){
            campaign.RecordTypeId = campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_CAMPAIGN_EVENT);
        }
        insert lCamp;

        List<MarketingBudget__c> lMB = AP23_TestDataFactory.createMarketingBudget(200);
        insert lMB;

        //Create Nominal Code
        List<Nominal_Code__c> lNC = new List<Nominal_Code__c>();
        Nominal_Code__c NC01 = new Nominal_Code__c(Name = 'Test Nominal Code 01', Nominal_Code_Name__c = 'Test Nominal Code 01', Budget__c = 10000, CurrencyIsoCode = 'GBP');
        lNC.add(NC01);
        insert lNC;

        //Create Budget Cost Center
        List<BudgetCostCenter__c> lBCC = new List<BudgetCostCenter__c>();
        for(Integer ctr=0; ctr< 200; ctr++){ 
            BudgetCostCenter__c BCC01 = new BudgetCostCenter__c(Name = 'Test BCC ' + ctr, MarketingBudget__c = lMB.get(ctr).Id,  CurrencyIsoCode = 'GBP', Nominal_Code__c = NC01.Id);
            lBCC.add(BCC01);
        }
        insert lBCC;

        lBCC = [SELECT Id FROM BudgetCostCenter__c LIMIT 200];
        List<CampaignForecast__c> cmpgnFcList = new List<CampaignForecast__c>();
        for(BudgetCostCenter__c bcc : lBCC){
            List<CampaignForecast__c> campaignForecastRec = AP23_TestDataFactory.createCampaignForecast(1, lAcc.get(0), lCamp.get(0), bcc);
            campaignForecastRec.get(0).CurrencyIsoCode = ApplicationConstant.GBP_CURRENCY;
            campaignForecastRec.get(0).ForecastedCost__c = 2000;
            cmpgnFcList.add(campaignForecastRec.get(0));
        }        
        insert cmpgnFcList;
    }

    static testMethod void bulkifyAndGetParentsTotalForecastedCampaignSpend(){
        Test.startTest();       
        List<MarketingBudget__c> lMB = AP23_TestDataFactory.createMarketingBudget(1);
        insert lMB;

        List<MarketingBudget__c> updateMbList = new List<MarketingBudget__c>();

        MarketingBudget__c parentMarketingBudget = [SELECT Id,Total_Forecasted_Campaign_Spend__c FROM MarketingBudget__c WHERE Id =:lMB.get(0).Id];

        System.assertEquals(parentMarketingBudget.Total_Forecasted_Campaign_Spend__c, 0);
        
        for(MarketingBudget__c mb : [SELECT Id, Total_Forecasted_Campaign_Spend__c, Parent_Marketing_Budget__c 
                                     FROM MarketingBudget__c
                                     WHERE Id <> :parentMarketingBudget.Id]){
            System.assertEquals(mb.Total_Forecasted_Campaign_Spend__c, 2000);
            System.assertEquals(mb.Parent_Marketing_Budget__c, null);
            mb.Parent_Marketing_Budget__c = parentMarketingBudget.Id;
            updateMbList.add(mb);
        }
        update updateMbList;

        parentMarketingBudget = [SELECT Id,Total_Forecasted_Campaign_Spend__c FROM MarketingBudget__c WHERE Id =:parentMarketingBudget.Id];
        System.assertEquals(parentMarketingBudget.Total_Forecasted_Campaign_Spend__c, 2000 * 200);
        
        Test.stopTest();        
    }   
    
    static testMethod void bulkifyAndUpdateParentsTotalForecastedCampaignSpend(){
        //Create Supplier
        List<Account> lAcc = AP23_TestDataFactory.createAccount(1);
        insert lAcc;

        //Create Marketing  Strategy
        List<MarketingStrategy__c> lMS = new List<MarketingStrategy__c>();
        MarketingStrategy__c MS01 = new MarketingStrategy__c(Name = 'Test Marketing Strategy 01', CurrencyIsoCode = 'GBP');
        lMS.add(MS01);
        insert lMS;
        
        
        //Create campaign
        List<Campaign> lCamp = AP23_TestDataFactory.createCampaign(1, MS01.Id);
        for(Campaign campaign : lCamp){
            campaign.RecordTypeId = campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_CAMPAIGN_EVENT);
        }
        insert lCamp;

        List<MarketingBudget__c> parentMarketingBudgetOld = AP23_TestDataFactory.createMarketingBudget(1);
        insert parentMarketingBudgetOld;
        
        List<MarketingBudget__c> lMB = AP23_TestDataFactory.createMarketingBudget(200);
        for(MarketingBudget__c mb : lMB){
            mb.Parent_Marketing_Budget__c = parentMarketingBudgetOld.get(0).Id;
        }
        insert lMB;
        
        //Create Nominal Code
        
        Nominal_Code__c NC01 = [SELECT Name, Nominal_Code_Name__c, Budget__c, CurrencyIsoCode FROM Nominal_Code__c LIMIT 1];
        

        //Create Budget Cost Center
        List<BudgetCostCenter__c> lBCC = new List<BudgetCostCenter__c>();
        for(Integer ctr=0; ctr< 200; ctr++){ 
            BudgetCostCenter__c BCC01 = new BudgetCostCenter__c(Name = 'Test BCC 2 ' + ctr, MarketingBudget__c = lMB.get(ctr).Id,  CurrencyIsoCode = 'GBP', Nominal_Code__c = NC01.Id);
            lBCC.add(BCC01);
        }
        insert lBCC;

        lBCC = [SELECT Id FROM BudgetCostCenter__c LIMIT 200];
        List<CampaignForecast__c> cmpgnFcList = new List<CampaignForecast__c>();
        for(BudgetCostCenter__c bcc : lBCC){
            List<CampaignForecast__c> campaignForecastRec = AP23_TestDataFactory.createCampaignForecast(1, lAcc.get(0), lCamp.get(0), bcc);
            campaignForecastRec.get(0).CurrencyIsoCode = ApplicationConstant.GBP_CURRENCY;
            campaignForecastRec.get(0).ForecastedCost__c = 2000;
            cmpgnFcList.add(campaignForecastRec.get(0));
        }        
        insert cmpgnFcList;

        List<MarketingBudget__c> parentMarketingBudgetNewList = AP23_TestDataFactory.createMarketingBudget(1);
        insert parentMarketingBudgetNewList;

        MarketingBudget__c parentMarketingBudgetNew = [SELECT Id,Total_Forecasted_Campaign_Spend__c FROM MarketingBudget__c WHERE Id =:parentMarketingBudgetNewList.get(0).Id];

        List<MarketingBudget__c> updateMbList = new List<MarketingBudget__c>();
        for(MarketingBudget__c mb : [SELECT Id, Total_Forecasted_Campaign_Spend__c, Parent_Marketing_Budget__c 
                                     FROM MarketingBudget__c
                                     WHERE Parent_Marketing_Budget__c =:parentMarketingBudgetOld.get(0).Id]){  
            System.assertEquals(mb.Parent_Marketing_Budget__c, parentMarketingBudgetOld.get(0).Id);         
            mb.Parent_Marketing_Budget__c = parentMarketingBudgetNew.Id;
            updateMbList.add(mb);
        }        
        update updateMbList;

        Integer ct = 0;
        for(MarketingBudget__c mb : [SELECT Id, Total_Forecasted_Campaign_Spend__c, Parent_Marketing_Budget__c 
                                     FROM MarketingBudget__c
                                     WHERE Parent_Marketing_Budget__c =:parentMarketingBudgetNew.Id]){  
            ct++;
        }

        Test.startTest();   
        MarketingBudget__c oldParentMarketingBudget = [SELECT Id,Total_Forecasted_Campaign_Spend__c FROM MarketingBudget__c WHERE Id =:parentMarketingBudgetOld.get(0).Id];
        System.assertEquals(oldParentMarketingBudget.Total_Forecasted_Campaign_Spend__c, 0);
        Test.stopTest();               
    }
}