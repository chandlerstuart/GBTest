/*
Name:  S2SExternalSharingTestSuite.cls
Copyright © 2015  CloudMethods
======================================================
======================================================
Purpose:
-------
Suite of unit tests that exercise (and verify) code behaviour related to S2S External Sharing.

Coverage for classes below (target 85%):
S2SExternalSharingHelper.cls : 82%


Note1, unit tests for S2S are constrained by the inability to create test data, the PNC and PNRC objects
do not support direct DML for update (status), parentIds etc. Records shared in a test context do not get set to Sent status.

Note2, unit test context can see records in PartnerNetworkConnection.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2015-05-06  Initial development.
1.1  Mark Cane&    2015-05-07  Added singleTestCase3+negativeTestCase1.
1.2  Mark Cane&    2015-05-11  Added singleTestCase4+singleTestCase5.
*/
@isTest
private class S2SExternalSharingTestSuite {
  
    /*
    Test cases:
        singleTestCase1 - Account trigger - single record.
        singleTestCase2 - Contact trigger - single record.
        singleTestCase3 - Account trigger - single record - connection Id filter plus record type filter.
        singleTestCase4 - GolfCourse trigger - single record.
        singleTestCase5 - Hotel trigger - single record.
        negativeTestCase1 - Account trigger - single record - parent relationship set causes INVALID_PARTNER_NETWORK_STATUS exception.
        restrictedUserTestCase1 - tbd
        bulkTestCase1 - tbd (bulk record (200) test of the singleTestCase1 logic.) = to be coded in S2SExternalSharingBulkTestSuite.cls
    */
    
    /* **/
    
    static testMethod void singleTestCase1() {
        // Test Case 1 : Account trigger - single record. 
        setup();
                
        Account a = AccountTestHelper.createAccounts(1, 'Acme', false)[0];    
    
    Test.startTest();
    insert a;
    Test.stopTest();
          
    System.assert([select count() from PartnerNetworkRecordConnection where LocalRecordId=:a.Id]>0, 'At least one PNRC should be created');        
    }
    
    /* */    
        
    /* **/
    
    static testMethod void singleTestCase2() {
        // Test Case 2 : Contact trigger - single record. 
        setup();
        
    Contact c = new Contact(FirstName='Sophy', LastName='Grigson');    
    
    Test.startTest();
    insert c;
    Test.stopTest();
          
    System.assert([select count() from PartnerNetworkRecordConnection where LocalRecordId=:c.Id]>0, 'At least one PNRC should be created');        
    }
    
    /* */
    
    /* **/
    
    static testMethod void singleTestCase3() {
        // Test Case 3 : Account trigger - single record - connection Id filter plus record type filter.
        setup();
        
        Id accountRTId = [select Id from RecordType where SobjectType='Account' and isActive=true and isPersontype=false limit 1].Id;
        Id pncId = [select Id from PartnerNetworkConnection where connectionStatus = 'Accepted' limit 1].Id;
        
        S2SExternalSharingSettings__c s2sSettings = S2SExternalSharingSettings__c.getInstance( UserInfo.getOrganizationId() );
        s2sSettings.ConnectionIds__c = pncId;
        s2sSettings.AccountRecordTypeIds__c = accountRTId;
        update s2sSettings;
        
        Account a = AccountTestHelper.createAccounts(1, 'Acme', false)[0];
    a.RecordTypeId=accountRTId;
    
    Test.startTest();
    insert a;
    Test.stopTest();
          
    System.assert([select count() from PartnerNetworkRecordConnection where LocalRecordId=:a.Id]>0, 'At least one PNRC should be created');        
    }
    
    /* */
    
    /* **/
    
    static testMethod void singleTestCase4() {
        // Test Case 4 : GolfCourse trigger - single record. 
        setup();
                
        Account a = AccountTestHelper.createAccounts(1, 'Acme', true)[0];
        GolfCourse__c g = new GolfCourse__c(Account__c=a.Id, Name='Test Course');        
                
    Test.startTest();
    insert g;
    Test.stopTest();
          
        // A PNRC record won't be created as the parent account won't be shared on the connection (unit test limitation).
         // Note, the Account relationship is Master:Detail.
    System.assert([select count() from PartnerNetworkRecordConnection where LocalRecordId=:g.Id]==0, 'PNRC should be not be created');        
    }
    
    /* */    
    
    /* **/
    
    static testMethod void singleTestCase5() {
        // Test Case 5 : Hotel trigger - single record. 
        setup();
                
        Account a = AccountTestHelper.createAccounts(1, 'Acme', true)[0];
        Hotel__c h = new Hotel__c(Account__c=a.Id, Name='Test Hotel');        
                
    Test.startTest();
    insert h;
    Test.stopTest();
          
        // A PNRC record won't be created as the parent account won't be shared on the connection (unit test limitation).
         // Note, the Account relationship is Master:Detail.
    System.assert([select count() from PartnerNetworkRecordConnection where LocalRecordId=:h.Id]==0, 'PNRC should be not be created');        
    }
    
    /* */    
    
    /* **/
    static testMethod void singleTestCase6() {
        // Test Case 2 : OnSupplierAgreement trigger - single record. 
        setup();
        
    Account a = AccountTestHelper.createAccounts(1, 'Acme', false)[0];
    insert a;
    Supplier_Agreement__c sup = new Supplier_Agreement__c(Account__c = a.Id, Name = 'Agreement ' + a.Name, Valid_From__c = Date.today());
    
    Test.startTest();
    insert sup;
    Test.stopTest();
          
    System.assert([select count() from PartnerNetworkRecordConnection where LocalRecordId=:sup.Id]>0, 'At least one PNRC should be created');        
    }
    /* */

    /* **/
    
    static testMethod void singleTestCase7() {
        // Test Case 2 : OnPaymentRule trigger - single record. 
        setup();
        
    Account a = AccountTestHelper.createAccounts(1, 'Acme', false)[0];
    insert a;
    Supplier_Agreement__c sup = new Supplier_Agreement__c(Account__c = a.Id, Name = 'Agreement ' + a.Name, Valid_From__c = Date.today());
    insert sup;
    Payment_Rule__c pay = new Payment_Rule__c(Days__c = 30, Supplier_Agreement__c = sup.Id);
    
    Test.startTest();
    insert pay;
    Test.stopTest();
          
    System.assert([select count() from PartnerNetworkRecordConnection where LocalRecordId=:pay.Id]>0, 'At least one PNRC should be created');        
    }
    
    /* */

    /* **/
    
    static testMethod void negativeTestCase1() {
        // Negative Test Case 1 : Account trigger - single record - parent relationship set causes INVALID_PARTNER_NETWORK_STATUS exception
        setup();
        
        Id accountRTId = [select Id from RecordType where SobjectType='Account' and isActive=true and isPersontype=false limit 1].Id;
        Id pncId = [select Id from PartnerNetworkConnection where connectionStatus = 'Accepted' limit 1].Id;
        
        S2SExternalSharingSettings__c s2sSettings = S2SExternalSharingSettings__c.getInstance( UserInfo.getOrganizationId() );
        s2sSettings.ConnectionIds__c = pncId;
        s2sSettings.AccountRecordTypeIds__c = accountRTId;
        update s2sSettings;
        
        Account p = AccountTestHelper.createAccounts(1, 'Acme Global', true)[0];

    Account a = AccountTestHelper.createAccounts(1, 'Acme', false)[0];        
    a.ParentId=p.Id;
    
    Test.startTest();
    insert a;
    Test.stopTest();
          
    System.assertEquals(1,[select count() from PartnerNetworkRecordConnection where LocalRecordId=:a.Id and ParentRecordId=null], 'One PNRC with no parent should be created');      
    }
    
    /* */    
    
  /* **/
  
    static testMethod void negativeTestCase2() {
        // Negative Test Case 2 : Contact trigger - single record - parent relationship set, but record not shared. 
        setup();
        
        Account a = AccountTestHelper.createAccounts(1, 'Acme', true)[0]; 
        
    Contact c = new Contact(FirstName='Sophy', LastName='Grigson', AccountId=a.Id);    
    
    Test.startTest();
    insert c;
    Test.stopTest();
          
    System.assertEquals(0,[select count() from PartnerNetworkRecordConnection where LocalRecordId=:c.Id], 'No PNRC, Contact requires Account to be Shared (PNRC @ Sent status)');        
    }
    
    /* */    
    /* **/
    static testMethod void testFilterRecords(){
        setup();
        List<Hotel__c> hotelList = new List<Hotel__c>();
        Account a = AccountTestHelper.createAccounts(1, 'Acme', true)[0];
        hotelList.add(new Hotel__c(Account__c=a.Id, Name='Test Hotel'));      
        
        Map<Id, SObject> objMap = S2SExternalSharingHelper.filterRecords(hotelList, 'Hotel__c','Account__c','Account');

        system.assertEquals(FALSE, objMap.isEmpty());

    }
    /* **/
    static testMethod void testScheduledSharing(){
        setup();
        Set<Id> hIds = new Set<Id>();
        Account a = AccountTestHelper.createAccounts(1, 'Acme', true)[0];
        Hotel__c h = new Hotel__c(Account__c=a.Id, Name='Test Hotel');
        insert h;      
        
        hIds.add(h.Id);

        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute() + 10); 
        String ss = String.valueOf(Datetime.now().second());

        //parse to cron expression
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        String jobName = 'Hotel__c' + ' ' + ss + ' ' + min + ' ' + hour;

        Test.startTest();
            S2SExternalSharingSchedule s2sSchedule = new S2SExternalSharingSchedule(hIds, 'Hotel__c', 'Account__c', NULL);
            Id jobId = System.schedule(jobName, nextFireTime, s2sSchedule);
        Test.stopTest();

    }
    /* */
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
          if (null == s2sSettings.Scheduled_Time_Delay__c) s2sSettings.Scheduled_Time_Delay__c = 20;
          insert s2sSettings;
        }   

        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;                  
    }
}