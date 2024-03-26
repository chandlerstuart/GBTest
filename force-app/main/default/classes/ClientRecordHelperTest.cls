/*
Name: ClientRecordHelperTest.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Test suite for Client Record Helper  functions.

Coverage for classes below (target 85%):
ClientRecordHelper.cls : 93%	

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-06-10  Initial development.
1.1  J Radcliffe   2019-08-21  Replacing Client Record Helper with DuplicateManagementHelper
*/
@isTest(SeeAllData=false)
public with sharing class ClientRecordHelperTest {
	/*
    Test cases:
        singleTestCase1 - BusinessLogic. Email-based Client lookup test.
        ..
        negativeTestCase1 - BusinessLogic. Email-based Client lookup fail test.        
	*/
	
    @testSetup static void setup(){}
    
    /* **/
    /*1.1
    static testMethod void singleTestCase1() {
        // Test case 1 : BusinessLogic. Email-based Client lookup test.

        String emailFieldName =  Schema.sObjectType.Account.fields.getMap().containsKey( 'isPersonAccount' ) ? 'PersonEmail' : 'Fax';
        String identifierFieldName =  Schema.sObjectType.Account.fields.getMap().containsKey( 'Golfbreaks_Person_Id__c' ) ? 'Golfbreaks_Person_Id__c' : 'Description';

        Account a = new Account(Name='Unit test');
        a.put(emailFieldName,'sg@unittest.golfbreaks.com');
        a.put(identifierFieldName,'TEST123456');        
        insert a;

        EnquiryManager.Enquiry e = new EnquiryManager.Enquiry();
        e.clientDetails.firstName = 'Sophie';
        e.clientDetails.lastName = 'Grigson';
        e.clientDetails.email = 'sg@unittest.golfbreaks.com';

        List<EnquiryManager.Enquiry> enquiriesWithCustomers = new List<EnquiryManager.Enquiry> { e };        

		Test.startTest();    
        System.assert(ClientRecordHelper.queryExistingClients(enquiriesWithCustomers));
		Test.stopTest();
        
        System.assertNotEquals(null, e.clientDetails.accountId);
        System.assertNotEquals(null, e.bookingSystemClientId);        
  	}*/
    /* */    

    
    /* **/
    /*1.1
    static testMethod void negativeTestCase1() {
        // Negative Test case 1 : BusinessLogic. Email-based Client lookup fail test.

        String emailFieldName =  Schema.sObjectType.Account.fields.getMap().containsKey( 'isPersonAccount' ) ? 'PersonEmail' : 'Fax';
        String identifierFieldName =  Schema.sObjectType.Account.fields.getMap().containsKey( 'Golfbreaks_Person_Id__c' ) ? 'Golfbreaks_Person_Id__c' : 'Description';

        Account a = new Account(Name='Unit test');
        a.put(emailFieldName,'sg2@unittest.golfbreaks.com');//<---different email.
        a.put(identifierFieldName,'TEST123456');   
        insert a;

        EnquiryManager.Enquiry e = new EnquiryManager.Enquiry();
        e.clientDetails.firstName = 'Sophie';
        e.clientDetails.lastName = 'Grigson';
        e.clientDetails.email = 'sg@unittest.golfbreaks.com';

        List<EnquiryManager.Enquiry> enquiriesWithCustomers = new List<EnquiryManager.Enquiry> { e };        

		Test.startTest();    
        System.assert(ClientRecordHelper.queryExistingClients(enquiriesWithCustomers));
		Test.stopTest();
        
        System.assertEquals(null, e.clientDetails.accountId);
        System.assertEquals(null, e.bookingSystemClientId);
  	}*/
    /* */       
}