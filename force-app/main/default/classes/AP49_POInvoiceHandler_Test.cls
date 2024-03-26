@isTest
public class AP49_POInvoiceHandler_Test{
    private static testMethod void poInvTest(){
        List<POInvoice__c> newPOInvoiceList = new List<POInvoice__c>();
        List<POInvoice__c> oldPOInvoiceList = new List<POInvoice__c>();
        Map<Id,POInvoice__c> newPOInvoiceMap = new Map<Id,POInvoice__c>();
        Map<Id,POInvoice__c> oldPOInvoiceMap = new Map<Id,POInvoice__c>();
        
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;   
        
        //Create account for PO Invoice
        List<Account> accList = AP23_TestDataFactory.createAccount(1);
        insert accList;
        
        //create Nominal Code
        Nominal_Code__c nmCode = new Nominal_Code__c();
        nmCode.Name = 'NM Code';
        nmCode.Budget__c = 1000;
        nmCode.Nominal_Code_Name__c = 'RR0033DDDXXX_05122016';
		insert nmCode;
        
        //Create PO Invoice
        List<POInvoice__c> poInv = AP23_TestDataFactory.createPOInvoice(200, accList[0], nmCode);
        
        // newPOInvoiceList.addAll(poInv);
        // oldPOInvoiceList.addAll(poInv);
        // newPOInvoiceMap.put(poInv[0].Id, poInv[0]);
        // oldPOInvoiceMap.put(poInv[1].Id, poInv[1]);
        
        test.startTest();
        //AP49_POInvoiceHandler poInvTst = new AP49_POInvoiceHandler();
        insert poInv;
        System.assertEquals(200, [SELECT Id FROM POInvoice__c].size());
        
        update poInv;
        
        delete poInv;
        System.assertEquals(0, [SELECT Id FROM POInvoice__c].size());
        // poInvTst.OnAfterDelete(newPOInvoiceList, newPOInvoiceMap, oldPOInvoiceList, oldPOInvoiceMap);
        // poInvTst.OnAfterInsert(newPOInvoiceList, newPOInvoiceMap, oldPOInvoiceList, oldPOInvoiceMap);
        // //poInvTst.OnAfterUnDelete(newPOInvoiceList, newPOInvoiceMap, oldPOInvoiceList, oldPOInvoiceMap);
        // poInvTst.OnAfterUpdate(newPOInvoiceList, newPOInvoiceMap, oldPOInvoiceList, oldPOInvoiceMap);
        // poInvTst.OnBeforeDelete(newPOInvoiceList, newPOInvoiceMap, oldPOInvoiceList, oldPOInvoiceMap);
        // poInvTst.OnBeforeInsert(newPOInvoiceList);
        // poInvTst.OnBeforeUpdate(newPOInvoiceList, newPOInvoiceMap, oldPOInvoiceList, oldPOInvoiceMap);
        // //poInvTst.OnUndelete(newPOInvoiceList, newPOInvoiceMap, oldPOInvoiceList, oldPOInvoiceMap);
        test.stopTest();
    }
}