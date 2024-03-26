//Negative Testing is not covered yet.

@isTest
public class AP48_CampaignForecastBL_Test{ //AP48_CampaignForecastBL

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
        
        //Create Marketing Budget
        List<MarketingBudget__c> lMB = new List<MarketingBudget__c>();
        MarketingBudget__c MB01 = new MarketingBudget__c(Name = 'Test Marketing Budget 01', CurrencyIsoCode = 'GBP');
        lMB.add(MB01); 
        insert lMB;
        
        //Create Nominal Code
        List<Nominal_Code__c> lNC = new List<Nominal_Code__c>();
        Nominal_Code__c NC01 = new Nominal_Code__c(Name = 'Test Nominal Code 01', Nominal_Code_Name__c = 'Test Nominal Code 01', Budget__c = 10000, CurrencyIsoCode = 'GBP');
        lNC.add(NC01);
        insert lNC;
        
        //Create Budget Cost Center
        List<BudgetCostCenter__c> lBCC = new List<BudgetCostCenter__c>();
        BudgetCostCenter__c BCC01 = new BudgetCostCenter__c(Name = 'Test BCC 01', MarketingBudget__c = MB01.Id,  CurrencyIsoCode = 'GBP', Nominal_Code__c = NC01.Id);
        lBCC.add(BCC01);
        insert lBCC;
        
        //Create Supplier
        List<Account> lAcc = AP23_TestDataFactory.createAccount(1);
        insert lAcc;
        
        //Create Committed Fund
        List<PurchaseOrder__c> lPO = new List<PurchaseOrder__c>();
        PurchaseOrder__c PO01 = new PurchaseOrder__c(Name = 'Test Committed Fund 01', Amount__c = 5000, CurrencyIsoCode = 'GBP', Campaign__c = lCamp[0].Id,
                                                     Supplier__c = lAcc[0].Id, BudgetCostCenter__c = BCC01.Id); 
        lPO.add(PO01);
        insert lPO;
    }
    
    static testMethod void rollUpForecastedCost(){
        //Query records
        Campaign camp01 = [SELECT Id, Forecasted_Cost__c FROM Campaign LIMIT 1];
        BudgetCostCenter__c bcc01 = [SELECT Id, TotalForecastedCampaignSpend__c FROM BudgetCostCenter__c LIMIT 1];
        PurchaseOrder__c PO01 = [SELECT Id, Has_associated_POInvoice__c FROM PurchaseOrder__c LIMIT 1];
        Account acct01 = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();

        List<CampaignForecast__c> campaignForecastList = AP23_TestDataFactory.createCampaignForecast(200, acct01, camp01, bcc01);
        for(CampaignForecast__c cmpl : campaignForecastList){
            cmpl.CurrencyIsoCode = ApplicationConstant.GBP_CURRENCY;
            cmpl.ForecastedCost__c = 2000;
        }
        insert campaignForecastList;
        
        Integer countCampaignForecasts = Database.countQuery('SELECT COUNT() FROM CampaignForecast__c');
        System.assertEquals(countCampaignForecasts, 200);

        Campaign updcamp01 = [SELECT Id, Forecasted_Cost__c FROM Campaign WHERE Id =:camp01.Id];
        System.AssertEquals(updcamp01.Forecasted_Cost__c, 200*(campaignForecastList[0].ForecastedCost__c));
        
        BudgetCostCenter__c Updbcc01 = [SELECT Id, TotalForecastedCampaignSpend__c FROM BudgetCostCenter__c WHERE Id =: bcc01.Id];
        System.AssertEquals(Updbcc01.TotalForecastedCampaignSpend__c, 200*(campaignForecastList[0].ForecastedCost__c));

        delete campaignForecastList;

        countCampaignForecasts = Database.countQuery('SELECT COUNT() FROM CampaignForecast__c');
        System.assertEquals(countCampaignForecasts, 0);

        Campaign updcamp02 = [SELECT Id, Forecasted_Cost__c FROM Campaign WHERE Id =:camp01.Id];
        System.AssertEquals(updcamp02.Forecasted_Cost__c, 0);
        
        BudgetCostCenter__c updbcc02 = [SELECT Id, TotalForecastedCampaignSpend__c FROM BudgetCostCenter__c WHERE Id =:bcc01.Id];
        System.AssertEquals(updbcc02.TotalForecastedCampaignSpend__c, 0);

        Test.stopTest();
    }
}