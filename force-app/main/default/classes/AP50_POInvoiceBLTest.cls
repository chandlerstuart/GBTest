/**
Name:   AP50_POInvoiceBLTest.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test Class for  AP50_POInvoiceBL
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail 
1.0  Atlee     2016-05-23   Created the test class

**/
@isTest
public class   AP50_POInvoiceBLTest {

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
        List<MarketingStrategy__c> lMS = AP23_TestDataFactory.createMarketingStrategy(1);
        insert lMS;
        
        //Create campaign
        List<Campaign> lCamp = AP23_TestDataFactory.createCampaign(2, lMS[0].Id);
        for(Campaign campaign : lCamp){
            campaign.RecordTypeId = campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_CAMPAIGN_EVENT);
        }
        insert lCamp;
        
        //Create Marketing Budget
        List<MarketingBudget__c> lMB = AP23_TestDataFactory.createMarketingBudget(1);
        insert lMB;
        
        //Create Nominal Code
        List<Nominal_Code__c> lNC = AP23_TestDataFactory.createNominalCode(1, 100);
        insert lNC;
        
        //Create Budget Cost Center
        List<BudgetCostCenter__c> lBCC = AP23_TestDataFactory.createBudgetCostCenter(2, lMB[0].Id, lNC[0].Id);
        insert lBCC;
        
        //Create Supplier
        List<Account> lAcc = AP23_TestDataFactory.createAccount(1);
        insert lAcc;
        
        //Create Committed Fund
        List<PurchaseOrder__c> lPO = AP23_TestDataFactory.createCommittedFund(2, 5000, lCamp[0].Id, lAcc[0].Id, lBCC[0].Id);
        insert lPO;
    }
    
    //Test updateTotalAmountBUCurrency and CommittedFund
    static testMethod void testInsert1(){
        Map<String, Double> conversionRate = new Map<String, Double>();
        for(CurrencyType ct : [SELECT Isocode, Conversionrate FROM CurrencyType]){
            if(!conversionRate.containsKey(ct.isoCode) && !String.isEmpty(ct.isoCode)){
                conversionRate.put(ct.isoCode , ct.conversionRate);
            }
        }    
        Decimal Conv;
         
        Campaign camp01 = [SELECT Id, Actual_Cost__c FROM Campaign LIMIT 1];        
        BudgetCostCenter__c bcc01 = [SELECT Id, TotalActualCampaignSpend__c, currencyISOCode FROM BudgetCostCenter__c LIMIT 1];
        PurchaseOrder__c PO01 = [SELECT Id, Has_associated_POInvoice__c FROM PurchaseOrder__c LIMIT 1];
        Account Acc = [SELECT Id FROM Account LIMIT 1];
        Nominal_Code__c NM = [SELECT Id FROM Nominal_Code__c LIMIT 1];
        MarketingStrategy__c MS = [SELECT Id FROM MarketingStrategy__c LIMIT 1];
        
        Test.startTest();
        List<POInvoice__c> lPO = AP23_TestDataFactory.createPOInvoice(200, Acc, NM);
        for(Integer i=0; i < 200; i++){
            lPO[i].Campaign__c = camp01.Id;
            lPO[i].BudgetCostCenter__c = bcc01.Id;
            lPO[i].CurrencyIsoCode =  'USD';
            lPO[i].CommittedFund__c = PO01.Id;
        }
        insert lPO;  
        
        lPO = [SELECT Id, Converted_Total_Amount__c, Total_Amount__c FROM POInvoice__c];
        for(POInvoice__c po: lPO){
            Conv = (Decimal)(po.Total_Amount__c * conversionRate.get(bcc01.currencyISOCode));
            System.AssertEquals(po.Converted_Total_Amount__c, conv);
        }
        PO01 = [SELECT Id, Has_associated_POInvoice__c FROM PurchaseOrder__c WHERE Id=: PO01.Id];
        System.AssertEquals(TRUE, PO01.Has_associated_POInvoice__c); 
        Test.stopTest();
    }
/*    
        //Test updateTotalAmountBUCurrency and CommittedFund
    static testMethod void testInsert2(){
        Map<String, Double> conversionRate = new Map<String, Double>();
        for(CurrencyType ct : [SELECT Isocode, Conversionrate FROM CurrencyType]){
            if(!conversionRate.containsKey(ct.isoCode) && !String.isEmpty(ct.isoCode)){
                conversionRate.put(ct.isoCode , ct.conversionRate);
            }
        }    
        Decimal Conv;
         
        Campaign camp01 = [SELECT Id, Actual_Cost__c FROM Campaign LIMIT 1];        
        BudgetCostCenter__c bcc01 = [SELECT Id, TotalActualCampaignSpend__c, currencyISOCode FROM BudgetCostCenter__c LIMIT 1];
        PurchaseOrder__c PO01 = [SELECT Id, Has_associated_POInvoice__c FROM PurchaseOrder__c LIMIT 1];
        Account Acc = [SELECT Id FROM Account LIMIT 1];
        Nominal_Code__c NM = [SELECT Id FROM Nominal_Code__c LIMIT 1];
        MarketingStrategy__c MS = [SELECT Id FROM MarketingStrategy__c LIMIT 1];
        
        Test.startTest();
        List<POInvoice__c> lPO = AP23_TestDataFactory.createPOInvoice(200, Acc, NM);
        for(Integer i=0; i < 200; i++){
            lPO[i].Campaign__c = camp01.Id;
            lPO[i].CurrencyIsoCode =  'USD';

        }
        insert lPO;  
        
        lPO = [SELECT Id, Converted_Total_Amount__c, Total_Amount__c FROM POInvoice__c];
        for(POInvoice__c po: lPO){
            System.AssertEquals(po.Converted_Total_Amount__c, 0);
        }
        
        for(Integer i=0; i < 200; i++){
            lPO[i].Campaign__c = camp01.Id;
            lPO[i].BudgetCostCenter__c = bcc01.Id;
            lPO[i].CurrencyIsoCode =  'USD';
            lPO[i].CommittedFund__c = PO01.Id;
        }
        update lPO;
        
        PO01 = [SELECT Id, Has_associated_POInvoice__c FROM PurchaseOrder__c WHERE Id=: PO01.Id];
        System.AssertEquals(TRUE, PO01.Has_associated_POInvoice__c); 
        Test.stopTest();
    }
    */
   
    static testMethod void testRollup(){
        //Query records
        Campaign camp01 = [SELECT Id, Actual_Cost__c FROM Campaign LIMIT 1];
        BudgetCostCenter__c bcc01 = [SELECT Id, TotalActualCampaignSpend__c FROM BudgetCostCenter__c LIMIT 1];
        PurchaseOrder__c PO01 = [SELECT Id, Has_associated_POInvoice__c FROM PurchaseOrder__c LIMIT 1];
        Account Acc = [SELECT Id FROM Account LIMIT 1];
        Nominal_Code__c NM = [SELECT Id FROM Nominal_Code__c LIMIT 1];
        Test.startTest();


        List<POInvoice__c> lPO = AP23_TestDataFactory.createPOInvoice(1, Acc, NM);
        lPO[0].Campaign__c = camp01.Id;
        lPO[0].BudgetCostCenter__c = bcc01.Id;
        lPO[0].CurrencyIsoCode =  'GBP';
        lPO[0].CommittedFund__c = PO01.Id;
        insert lPO;   

        Integer countPOInvoice = Database.countQuery('SELECT COUNT() FROM POInvoice__c');
        System.assertEquals(countPOInvoice, 1);

        PurchaseOrder__c UpdPO01 = [SELECT Id, Has_associated_POInvoice__c FROM PurchaseOrder__c WHERE Id =: PO01.Id];
        System.AssertEquals(UpdPO01.Has_associated_POInvoice__c, TRUE);
        
        Campaign updcamp01 = [SELECT Id, Actual_Cost__c FROM Campaign WHERE Id =:camp01.Id];
        System.AssertEquals(updcamp01.Actual_Cost__c, lPO[0].Total_Amount__c);
        
        BudgetCostCenter__c Updbcc01 = [SELECT Id, TotalActualCampaignSpend__c FROM BudgetCostCenter__c WHERE Id =: bcc01.Id];
        System.AssertEquals(Updbcc01.TotalActualCampaignSpend__c, lPO[0].Total_Amount__c);
        
        delete lPO;

        countPOInvoice = Database.countQuery('SELECT COUNT() FROM POInvoice__c');
        System.assertEquals(countPOInvoice, 0);

        Campaign updcamp02 = [SELECT Id, Actual_Cost__c FROM Campaign WHERE Id =:camp01.Id];
        System.AssertEquals(updcamp02.Actual_Cost__c, 0);
        
        BudgetCostCenter__c updbcc02 = [SELECT Id, TotalActualCampaignSpend__c FROM BudgetCostCenter__c WHERE Id =:bcc01.Id];
        System.AssertEquals(updbcc02.TotalActualCampaignSpend__c, 0);
        
        Test.stopTest();
    }

    static testMethod void testUpdate(){
        //Query records
        List<Campaign> lCamp = [SELECT Id, Actual_Cost__c FROM Campaign];
        Campaign camp01 = lCamp[0];
        Campaign camp02 = lCamp[1];
        
        List<BudgetCostCenter__c> lBCC = [SELECT Id, TotalActualCampaignSpend__c FROM BudgetCostCenter__c];
        BudgetCostCenter__c bcc01 = lBCC[0];
        BudgetCostCenter__c bcc02 = lBCC[1];
        
        List<PurchaseOrder__c> lPOr = [SELECT Id, Has_associated_POInvoice__c FROM PurchaseOrder__c];
        PurchaseOrder__c PO01 = lPOr[0];
        PurchaseOrder__c PO02 = lPOr[1];

        Account Acc = [SELECT Id FROM Account LIMIT 1];
        Nominal_Code__c NM = [SELECT Id FROM Nominal_Code__c LIMIT 1];
        MarketingStrategy__c MS = [SELECT Id FROM MarketingStrategy__c LIMIT 1];
        
        Test.startTest();


        List<POInvoice__c> lPO = AP23_TestDataFactory.createPOInvoice(1, Acc, NM);
        lPO[0].Campaign__c = camp01.Id;
        lPO[0].BudgetCostCenter__c = bcc01.Id;
        lPO[0].CurrencyIsoCode =  'GBP';
        lPO[0].CommittedFund__c = PO01.Id;
        insert lPO;   
            
        lPO[0].Campaign__c = camp02.Id;
        lPO[0].BudgetCostCenter__c = bcc02.Id;
        lPO[0].CommittedFund__c = PO02.Id;
        update lPO;
        
        PurchaseOrder__c UpdPO01 = new PurchaseOrder__c();
        PurchaseOrder__c UpdPO02 = new PurchaseOrder__c();
        List<PurchaseOrder__c> lUpdPOr = [SELECT Id, Has_associated_POInvoice__c FROM PurchaseOrder__c WHERE Id =: PO01.Id OR Id =: PO02.Id];
        for(PurchaseOrder__c por: lUpdPOr){
            if(por.Id == PO01.Id){
                UpdPO01 = por;
            }
            if(por.Id == PO02.Id){
                UpdPO02 = por;
            }
        }
        System.AssertEquals(UpdPO01.Has_associated_POInvoice__c, FALSE);
        System.AssertEquals(UpdPO02.Has_associated_POInvoice__c, TRUE);
        
        Campaign UpdCamp01 = new Campaign();
        Campaign UpdCamp02 = new Campaign();
        List<Campaign> lUpdCamp = [SELECT Id, Actual_Cost__c FROM Campaign WHERE Id =:camp01.Id OR Id =: camp02.Id];
        for(Campaign cam: lUpdCamp){
            if(cam.Id == camp01.Id){
                UpdCamp01 = cam;
            }
            if(cam.Id == camp02.Id){
                UpdCamp02 = cam;
            }
        }
        System.AssertEquals(Updcamp01.Actual_Cost__c, lPO[0].Total_Amount__c);
        System.AssertEquals(Updcamp02.Actual_Cost__c, 0);
        
        BudgetCostCenter__c UPdbcc01 = new BudgetCostCenter__c();
        BudgetCostCenter__c UPdbcc02 = new BudgetCostCenter__c();
        List<BudgetCostCenter__c> lUpdbcc = [SELECT Id, TotalActualCampaignSpend__c FROM BudgetCostCenter__c WHERE Id =: bcc01.Id OR Id=: bcc02.Id];
        for(BudgetCostCenter__c bcc: lUpdbcc){
            if(bcc.Id == bcc01.Id){
                Updbcc01 = bcc;
            }
            if(bcc.Id == bcc02.Id){
                Updbcc02 = bcc;
            }
        }
        System.AssertEquals(Updbcc01.TotalActualCampaignSpend__c, lPO[0].Total_Amount__c);
        System.AssertEquals(Updbcc02.TotalActualCampaignSpend__c, 0);
        Test.stopTest();
    }

    static testMethod void testError(){
        AP50_POInvoiceBL.updateCommittedFund(null, null);
        AP50_POInvoiceBL.rollUpTotalAmount(null, null);
        List<Error_Log__c> logs = [SELECT Id FROM Error_Log__c];
        
        System.assertEquals(2, logs.size());
    }

}