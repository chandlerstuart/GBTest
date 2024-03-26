/*
Name:  AP66_ProductServiceTriggerHandlerTest.cls
======================================================
======================================================
Purpose:
-------
Test class for AP66_ProductServiceTriggerHandler

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon Molloy  2017-11-03  Initial development.
*/
@isTest
private class AP66_ProductServiceTriggerHandlerTest {
    
	@testSetup
	static void setupData(){
		OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;  

		List<Account> businessAccounts = AP23_TestDataFactory.createBusinessAccount(2);
		insert businessAccounts;

	}

    static testmethod void testInsert() {
    	List<Account> accList = [select Id from Account where RecordType.Name = 'Business Account'];
    	List<Product_Service__c> psList = new List<Product_Service__c>();

    	Product_Service__c softwarePS = new Product_Service__c();
		softwarePS.Type__c = 'Software';
		softwarePS.Product_Service_Name__c = 'Salesforce Service Cloud - Performance Edition';
		softwarePS.Annual_Cost__c = 1000;
		softwarePS.Account__c = accList[0].Id;
		psList.add(softwarePS);

		Product_Service__c hardwarePS = new Product_Service__c();
		hardwarePS.Type__c = 'Hardware';
		hardwarePS.Product_Service_Name__c = 'Laptop';
		hardwarePS.Monthly_Cost__c = 167;
		hardwarePS.Account__c = accList[1].Id;
		psList.add(hardwarePS);


    	test.startTest();

    		insert psList;

    	test.stopTest();

    	for (Product_Service__c ps : [select Id, Annual_Cost__c, Monthly_Cost__c, Type__c from Product_Service__c]){

    		if ('Software'.equalsIgnoreCase(ps.Type__c)) system.assertEquals(ps.Monthly_Cost__c, ps.Annual_Cost__c / 12);
    		if ('Hardware'.equalsIgnoreCase(ps.Type__c)) system.assertEquals(ps.Annual_Cost__c, ps.Monthly_Cost__c * 12);

    	}
    }

    static testmethod void testUpdate() {
    	List<Product_Service__c> psList = new List<Product_Service__c>();

    	Product_Service__c softwarePS = new Product_Service__c();
		softwarePS.Type__c = 'Software';
		softwarePS.Product_Service_Name__c = 'Salesforce Service Cloud - Performance Edition';
		softwarePS.Annual_Cost__c = 1000;
		psList.add(softwarePS);

		Product_Service__c hardwarePS = new Product_Service__c();
		hardwarePS.Type__c = 'Hardware';
		hardwarePS.Product_Service_Name__c = 'Laptop';
		hardwarePS.Monthly_Cost__c = 167;
		psList.add(hardwarePS);

    	insert psList;

		for (Product_Service__c ps : [select Id, Annual_Cost__c, Monthly_Cost__c, Type__c from Product_Service__c]){
			if ('Software'.equalsIgnoreCase(ps.Type__c)){
				ps.Annual_Cost__c = 2000;	
			}else if ('Hardware'.equalsIgnoreCase(ps.Type__c)){
				ps.Monthly_Cost__c = 334;
			}
		}    	

		test.startTest();

		update psList;

		test.stopTest();

    	for (Product_Service__c ps : [select Id, Annual_Cost__c, Monthly_Cost__c, Type__c from Product_Service__c]){

    		if ('Software'.equalsIgnoreCase(ps.Type__c)) system.assertEquals(ps.Monthly_Cost__c, ps.Annual_Cost__c / 12);
    		if ('Hardware'.equalsIgnoreCase(ps.Type__c)) system.assertEquals(ps.Annual_Cost__c, ps.Monthly_Cost__c * 12);

    	}
    }

}