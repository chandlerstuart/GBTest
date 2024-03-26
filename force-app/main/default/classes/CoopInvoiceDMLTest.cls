/**************************************************************
@description - Test class for CoopInvoiceTriggerDML

Author			Date		Details
J Radcliffe		25/11/2016	Initial Development
M Paddeo		26/10/2020	Added Funding Order data, commented out Opp creation
***************************************************************/
@isTest
public class CoopInvoiceDMLTest {
    
    @testSetup
    //This method builds the initial data ready for testing: 2 conversion rates (DKK), 1 Account, 1 Contact and 1 Opp
    public static void setup(){ 
        
        DatedConversionRate dDKK1 = new DatedConversionRate();
        dDKK1.ConversionRate = 8.10;
        dDKK1.StartDate = system.today().addDays(+3);
        dDKK1.IsoCode = 'DKK';        
        
        DatedConversionRate dDKK2 = new DatedConversionRate();
        dDKK2.ConversionRate = 8.10;
        dDKK2.StartDate = system.today().addDays(-3);
        dDKK2.IsoCode = 'DKK';
        
        Map<String, RecordType> rtMap = new Map<String, RecordType>();
        for (RecordType r : [select Id, DeveloperName from RecordType where IsActive = TRUE and 
                             SObjectType = 'Account']){
                                 
                                 rtMap.put(r.DeveloperName, r);
                             }        
        
        
        Account acc = new Account();
        acc.Name = 'Main Account';
        acc.RecordTypeId = rtMap.get('Supplier').Id;
        
        insert acc;
        
        Contact con = new Contact();
        con.FirstName = 'Test';
        con.LastName = 'Contact';
        con.AccountId = acc.Id;
        insert con;
        
        
        /*Opportunity opp = new Opportunity();
        opp.Name = 'Main Opp';
        opp.AccountId = acc.Id;
        opp.RecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Co_op_Funding' LIMIT 1];
        opp.StageName = 'Proposal Sent';
        opp.Primary_Contact__c = con.Id;
        opp.Type = 'Coop Funding';
        opp.CloseDate = System.Today();   
        opp.Tier_1_Budget__c = 200;
        opp.Accepted_Tier__c = 'Tier 1';
        
        insert opp; */
        
        FundingOrder__c fo = new FundingOrder__c();
        fo.Name = 'Test Funding Order';
        fo.AccountId__c = acc.Id;
        fo.RecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'MarketingPackage' LIMIT 1];
        fo.OrderStage__c = 'Definite';
        fo.PrimaryContact__c = con.Id;
        //fo.Type__c = 'Marketing Package - Bespoke';
        fo.OrderAmount__c = 3000;
        
        insert fo;
        
        
    }
    //This method creates and inserts Co_Op_Invoice__c records of different currencies and asserts that the Invoice_Amount_GBP__c is calculated correctly. It then updates the Amount field and re-asserts the Invoice_Amount_GBP__c field.
    public static testmethod void testInvoiceGBPCurrencyCalculation(){
        
        //Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        FundingOrder__c fo = [SELECT Id FROM FundingOrder__c LIMIT 1];
        List<Co_Op_Invoice__c> invs = new List<Co_Op_Invoice__c>();
        
        Co_Op_Invoice__c cDKK = new Co_Op_Invoice__c();
        //cDKK.Opportunity__c = opp.Id;
        cDKK.FundingOrder__c = fo.Id;
        cDKK.Invoice_Date__c = system.today();
        cDKK.Invoice_Type__c = 'Invoice Cash';
        cDKK.Invoice_Number__c = null;
        cDKK.Amount__c = 2000.00;
        cDKK.Invoice_Amount_GBP__c = null;
        cDKK.CurrencyIsoCode = 'DKK';
        
        invs.add(cDKK);
        
        Co_Op_Invoice__c cGBP = new Co_Op_Invoice__c();
        //cGBP.Opportunity__c = opp.Id;
        cGBP.FundingOrder__c = fo.Id;
        cGBP.Invoice_Date__c = system.today();
        cGBP.Invoice_Type__c = 'Invoice Cash';
        cGBP.Invoice_Number__c = null;
        cGBP.Amount__c = 1000.00;
        cGBP.Invoice_Amount_GBP__c = null;
        cGBP.CurrencyIsoCode = 'GBP';
        
        invs.add(cGBP);
        
        test.startTest();
        
        insert invs;
        
        List<Co_Op_Invoice__c> updateInvs = new List<Co_Op_Invoice__c>();
        
        for(Co_Op_Invoice__c cInv : [SELECT Id, Amount__c, Invoice_Amount_GBP__c, CurrencyISOCode FROM Co_Op_Invoice__c]){
            if(cInv.CurrencyIsoCode == 'GBP'){
                system.assertEquals(cInv.Amount__c, cInv.Invoice_Amount_GBP__c);
            }else{
                system.assertEquals(246.91, cInv.Invoice_Amount_GBP__c );              
            }
            cInv.Amount__c = 2000;
            updateInvs.add(cInv);
        }
        
        update updateInvs;
        
        test.stopTest();
        
        for(Co_Op_Invoice__c cInv : [SELECT Id, Amount__c, Invoice_Amount_GBP__c, CurrencyISOCode FROM Co_Op_Invoice__c]){
            if(cInv.CurrencyIsoCode == 'GBP'){
                system.assertEquals(cInv.Amount__c, cInv.Invoice_Amount_GBP__c);
            }else{
                system.assertEquals(246.91, cInv.Invoice_Amount_GBP__c );              
            }        
        }
    }   
}