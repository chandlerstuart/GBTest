/**
  * @author -         Jerome To (ACN)
  * @date -           MAY 11, 2016
  * @description -    Handler for POInvoiceTrigger
  * #############Change Log#############
  * Modified by     Version     Change Date
  * Simon Molloy    2.0         05/09/2016  Changed method signature of AP50_POInvoiceBL.updateTotalAmounyBUCurrency
  **/

public with sharing class AP49_POInvoiceHandler {
    public AP49_POInvoiceHandler() {
        
    }

    public void OnBeforeInsert(List<POInvoice__c> newPOInvoiceList){
        AP50_POInvoiceBL.updateTotalAmountBUCurrency(newPOInvoiceList, null);
    }    
    
    public void OnBeforeUpdate(List<POInvoice__c> newPOInvoiceList, Map<Id,POInvoice__c> newPOInvoiceMap, List<POInvoice__c> oldPOInvoiceList, Map<Id,POInvoice__c> oldPOInvoiceMap){
        AP50_POInvoiceBL.updateTotalAmountBUCurrency(newPOInvoiceList, oldPOInvoiceMap);
    }
    
    public void OnAfterInsert(List<POInvoice__c> newPOInvoiceList, Map<Id,POInvoice__c> newPOInvoiceMap, List<POInvoice__c> oldPOInvoiceList, Map<Id,POInvoice__c> oldPOInvoiceMap){
        AP50_POInvoiceBL.rollUpTotalAmount(newPOInvoiceList, null);
        AP50_POInvoiceBL.updateCommittedFund(newPOInvoiceList, null);
    }
    
    public void OnAfterUpdate(List<POInvoice__c> newPOInvoiceList, Map<Id,POInvoice__c> newPOInvoiceMap, List<POInvoice__c> oldPOInvoiceList, Map<Id,POInvoice__c> oldPOInvoiceMap){
        AP50_POInvoiceBL.rollUpTotalAmount(newPOInvoiceList, oldPOInvoiceMap);
        AP50_POInvoiceBL.updateCommittedFund(newPOInvoiceList, oldPOInvoiceMap);
    }
    
    public void OnBeforeDelete(List<POInvoice__c> newPOInvoiceList, Map<Id,POInvoice__c> newPOInvoiceMap, List<POInvoice__c> oldPOInvoiceList, Map<Id,POInvoice__c> oldPOInvoiceMap){
        
    }
    
    public void OnAfterDelete(List<POInvoice__c> newPOInvoiceList, Map<Id,POInvoice__c> newPOInvoiceMap, List<POInvoice__c> oldPOInvoiceList, Map<Id,POInvoice__c> oldPOInvoiceMap){
        AP50_POInvoiceBL.rollUpTotalAmount(oldPOInvoiceList, null);
        AP50_POInvoiceBL.updateCommittedFund(oldPOInvoiceList, null);
    }
}