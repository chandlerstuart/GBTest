/*
Name:  S2SExternalSharingBulkTestSuite.cls
Copyright © 2015  CloudMethods
======================================================
======================================================
Purpose:
-------
Suite of unit tests that exercise (and verify) bulk code behaviour related to S2S External Sharing.

Coverage for classes below (target 85%):
S2SExternalSharingHelper.cls : 63%

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2015-05-07  Initial development.
1.1  Simon Molloy  2017-09-06  Added in test methods for Supplier Agreements & Payment Rules
*/
@isTest
private class S2SExternalSharingBulkTestSuite {
  
    /*
    Test cases:
        bulkTestCase1 - Account trigger - 200 records.
        bulkTeseCase2 - OnSupplierAgreement trigger - 200 records.
        bulkTestCase3 - OnPaymentRule trigger - 200 records.
    */
    
    /* **/
    static testMethod void bulkTestCase1() {
        // Test Case 1 : Account trigger - 200 records. 
        setup();
        
        List<Account> accounts = AccountTestHelper.createAccounts(200, 'Acme', false);

    Test.startTest();
    insert accounts;
    Test.stopTest();
          
    System.assertEquals(200,[select count() from PartnerNetworkRecordConnection where LocalRecordId  in:accounts], '200 PNRC should be created');        
    }
    /* */ 

    /* **/
    static testMethod void bulkTestCase2() {
        // Test Case 2 : OnSupplierAgreement trigger - 200 records. 
        setup();
        
        List<Account> accounts = AccountTestHelper.createAccounts(200, 'Acme', false);
        Map<integer, Account> accMap = new Map<integer, Account>();
        for (integer i = 0 ; i < accounts.size() ; i++){
            accounts[i].Name = accounts[i].Name + ' ' + i;
            accMap.put(i, accounts[i]);
        }
        insert accounts;

        List<Supplier_Agreement__c> aggList = new List<Supplier_Agreement__c>();
        for (integer i = 0 ; i < 200 ; i++){
            Supplier_Agreement__c sup = new Supplier_Agreement__c();
            sup.Account__c = accMap.get(i).Id;
            sup.Valid_From__c = Date.today();
            sup.Name = 'Agreement ' + accMap.get(i).Name;
            aggList.add(sup);
        }

    Test.startTest();
    insert aggList;
    Test.stopTest();
          
    //System.assertEquals(200,[select count() from PartnerNetworkRecordConnection where LocalRecordId  in:aggList], '200 PNRC should be created');        
    }
    /* */ 

    /* **/
    static testMethod void bulkTestCase3() {
        // Test Case 3 : OnPaymentRule trigger - 200 records. 
        setup();
        
        List<Account> accounts = AccountTestHelper.createAccounts(200, 'Acme', false);
        Map<integer, Account> accMap = new Map<integer, Account>();
        for (integer i = 0 ; i < accounts.size() ; i++){
            accounts[i].Name = accounts[i].Name + ' ' + i;
            accMap.put(i, accounts[i]);
        }
        insert accounts;

        Map<integer, Supplier_Agreement__c> aggMap = new Map<integer, Supplier_Agreement__c>();
        for (integer i = 0; i < 200 ; i++){
            Supplier_Agreement__c sup = new Supplier_Agreement__c();
            sup.Account__c = accMap.get(i).Id;
            sup.Valid_From__c = Date.today();
            sup.Name = 'Agreement ' + accMap.get(i).Name;
            aggMap.put(i, sup);
        }

        insert aggMap.values();

        List<Payment_Rule__c> paymentRules = new List<Payment_Rule__c>();
        for (integer i = 0 ; i < 200 ; i++){
            paymentRules.add(new Payment_Rule__c(Days__c = 30, Supplier_Agreement__c = aggMap.get(i).Id));
        }

    Test.startTest();
    insert paymentRules;
    Test.stopTest();
          
    System.assertEquals(200,[select count() from PartnerNetworkRecordConnection where LocalRecordId  in:accounts], '200 PNRC should be created');        
    }
    /* */ 
        
    private static void setup(){      
        OrgSettings__c orgSettings = OrgSettings__c.getInstance( UserInfo.getOrganizationId() );
        if (!orgSettings.TriggersActive__c){        
          orgSettings.TriggersActive__c = true;  
          insert orgSettings;
        }

        S2SExternalSharingSettings__c s2sSettings = S2SExternalSharingSettings__c.getInstance( UserInfo.getOrganizationId() );
        if (!s2sSettings.isActive__c){
          s2sSettings.isActive__c=true;
          insert s2sSettings;
        }    

        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;                
    }
}