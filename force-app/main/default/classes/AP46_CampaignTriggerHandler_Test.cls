@isTest
public class AP46_CampaignTriggerHandler_Test{
    private static testMethod void cmpgnHndlrTst(){
        List<Campaign> newCampaignList = new List<Campaign>();
        List<Campaign> oldCampaignList = new List<Campaign>();
        List<MarketingStrategy__c> marketingStrategyList = new List<MarketingStrategy__c>();
        List<Campaign> campaignList = new List<Campaign>();
        
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
        MarketingBudget__c mrktBdget = new  MarketingBudget__c(Name = 'Golf Philanthropy Marketing Instalação');
        mrktBdget.CurrencyIsoCode = ApplicationConstant.GBP_CURRENCY;
        insert mrktBdget;
        
        //Budget Cost Center for Associated Budget Financial Account
        BudgetCostCenter__c cntre = new BudgetCostCenter__c();
        cntre.Name = 'Golf Philanthropy Budget';
        cntre.MarketingBudget__c = mrktBdget.Id;
        cntre.Nominal_Code__c = nom.Id;
        INSERT cntre;
        
        //Marketing Strat for Campaign
        for(integer i=0; i<200; i++){
            MarketingStrategy__c mktStrat = new MarketingStrategy__c(Name = 'Golf Philanthropy');
            marketingStrategyList.add(mktStrat);
        }
        INSERT marketingStrategyList;
        
        test.startTest();
        AP46_CampaignTriggerHandler trgHndler = new AP46_CampaignTriggerHandler();
        //Cmpaign for Campaign Forecast
        for(integer i=0; i<200; i++){
            Campaign cmpgn = AP23_TestDataFactory.createCampaign(1, marketingStrategyList[i].Id)[0];
            campaignList.add(cmpgn);
        }
        INSERT campaignList;
        //Determine if there are 20 inserted campaignss
        System.assertEquals(200, [SELECT Id FROM Campaign].size());
        
        integer ctr = 0;
        campaignList = new List<Campaign>();
        
        for(Campaign c : [SELECT Name FROM Campaign]){
            ctr++;
            c.Name = 'Golfo Estreito Campaign' + ctr;
            campaignList.add(c);
        }
        UPDATE campaignList;
        //Determine if there were 20 campaigns updated
        System.assertEquals([SELECT Name FROM Campaign WHERE Name =: 'Golfo Estreito Campaign200'].Name, 'Golfo Estreito Campaign200');
        
        DELETE campaignList;
        //Determine if there are no more campaigns after deletion
        System.assertEquals(0, [SELECT Id FROM Campaign].size());
        // newCampaignList.addAll(campaignList);
        // oldCampaignList.addAll(campaignList);  
        // Map<Id,Campaign> newCampaignMap = new Map<Id,Campaign>([SELECT Id FROM Campaign]);
        // Map<Id,Campaign> oldCampaignMap = new Map<Id,Campaign>([SELECT Id FROM Campaign]);  
        // trgHndler.OnAfterDelete(newCampaignList, newCampaignMap, oldCampaignList, oldCampaignMap);
        // trgHndler.OnAfterInsert(newCampaignList, newCampaignMap, oldCampaignList, oldCampaignMap);
        // //trgHndler.OnAfterUnDelete(newCampaignList, newCampaignMap, oldCampaignList, oldCampaignMap);
        // trgHndler.OnAfterUpdate(newCampaignList, newCampaignMap, oldCampaignList, oldCampaignMap);
        // trgHndler.OnBeforeDelete(newCampaignList, newCampaignMap, oldCampaignList, oldCampaignMap);
        // trgHndler.OnBeforeInsert(newCampaignList);
        // trgHndler.OnBeforeUpdate(newCampaignList, newCampaignMap, oldCampaignList, oldCampaignMap);
        // //trgHndler.OnUndelete(newCampaignList, newCampaignMap, oldCampaignList, oldCampaignMap);       
        test.stopTest();
    }
}