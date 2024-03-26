@isTest
public class AP47_CampaignForecastHandler_Test{
    private static testMethod void testHandler(){
        List<CampaignForecast__c> newCampaignForecastList = new List<CampaignForecast__c>();
        List<CampaignForecast__c> oldCampaignForecastList = new List<CampaignForecast__c>();
        Map<Id,CampaignForecast__c> newCampaignForecastMap = new Map<Id,CampaignForecast__c>();
        Map<Id,CampaignForecast__c> oldCampaignForecastMap = new Map<Id,CampaignForecast__c>();
        
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;   
        
        //Account as supplier
        List<Account> acc = AP23_TestDataFactory.createAccount(1);
        INSERT acc;
        
        //Create Nominal Code for Budget Cost Center
        Nominal_Code__c nom = new Nominal_Code__c();
        nom.Nominal_Code_Name__c = 'Nominal Code'+System.today();
        nom.Budget__c = 1234;
        nom.CurrencyIsoCode = ApplicationConstant.GBP_CURRENCY;
        nom.Name='123';
        insert nom;
        
        //Marketing Budget for Budget Cost Center
        MarketingBudget__c mrktBdget = new  MarketingBudget__c();
        mrktBdget.Name = 'Golf Philanthropy ßÖ';
        mrktBdget.CurrencyIsoCode = ApplicationConstant.GBP_CURRENCY;
        insert mrktBdget;
        
        //Budget Cost Center for Associated Budget Financial Account
        BudgetCostCenter__c cntre = new BudgetCostCenter__c(Name = 'Golf Philanthropy Marketing Budget');
        cntre.MarketingBudget__c = mrktBdget.Id;
        cntre.CurrencyIsoCode = ApplicationConstant.GBP_CURRENCY;
        cntre.Nominal_Code__c = nom.Id;
        INSERT cntre;
        
        //Marketing Strat for Campaign
        MarketingStrategy__c mktStrat = new MarketingStrategy__c(Name = 'Golf Philanthropy', CurrencyIsoCode= ApplicationConstant.GBP_CURRENCY);
        INSERT mktStrat;
        
        //Cmpaign for Campaign Forecast
        List<Campaign> cmpgn = AP23_TestDataFactory.createCampaign(1, mktStrat.Id);
        INSERT cmpgn;
        
        // newCampaignForecastList.addAll(cpFrcstList);
        // oldCampaignForecastList.addAll(cpFrcstList);
        // newCampaignForecastMap.put(cpFrcstList[0].Id, cpFrcstList[0]);
        // oldCampaignForecastMap.put(cpFrcstList[0].Id, cpFrcstList[0]);
        
        test.startTest();
        AP47_CampaignForecastHandler cmpgnHndler = new AP47_CampaignForecastHandler();
        
        List<CampaignForecast__c> cpFrcstList = AP23_TestDataFactory.createCampaignForecast(199, acc[0], cmpgn[0], cntre);
        for(CampaignForecast__c cmpl : cpFrcstList){
            cmpl.CurrencyIsoCode = ApplicationConstant.GBP_CURRENCY;
        }
        INSERT cpFrcstList;
        
        System.assertEquals(199, [SELECT Id FROM CampaignForecast__c].size());
        
        try{
            UPDATE cpFrcstList;
        }catch(Exception ex){
            System.assert(ex.getMessage().contains('This campaign forecast can no longer be edited.'));
        }
        
        DELETE cpFrcstList;
        System.assertEquals(0, [SELECT Id FROM CampaignForecast__c].size());
        
        
        // cmpgnHndler.OnAfterDelete(newCampaignForecastList, newCampaignForecastMap, oldCampaignForecastList, oldCampaignForecastMap);
        // cmpgnHndler.OnAfterInsert(newCampaignForecastList, newCampaignForecastMap, oldCampaignForecastList, oldCampaignForecastMap);
        // //cmpgnHndler.OnAfterUnDelete(newCampaignForecastList, newCampaignForecastMap, oldCampaignForecastList, oldCampaignForecastMap);
        // cmpgnHndler.OnAfterUpdate(newCampaignForecastList, newCampaignForecastMap, oldCampaignForecastList, oldCampaignForecastMap);
        // cmpgnHndler.OnBeforeDelete(newCampaignForecastList, newCampaignForecastMap, oldCampaignForecastList, oldCampaignForecastMap);
        // cmpgnHndler.OnBeforeInsert(newCampaignForecastList);
        // cmpgnHndler.OnBeforeUpdate(newCampaignForecastList, newCampaignForecastMap, oldCampaignForecastList, oldCampaignForecastMap);
        // //cmpgnHndler.OnUndelete(newCampaignForecastList, newCampaignForecastMap, oldCampaignForecastList, oldCampaignForecastMap);            
        test.stopTest();
    }
}