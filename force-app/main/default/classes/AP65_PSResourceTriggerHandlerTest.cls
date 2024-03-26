/*
Name:  AP65_PSResourceTriggerHandlerTest.cls
======================================================
======================================================
Purpose:
-------
Test class for AP65_PSResourceTriggerHandler

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon Molloy  2017-10-30  Initial development.
*/
@isTest
private class AP65_PSResourceTriggerHandlerTest {
    
    @testSetup
    static void setupData(){
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;  

        List<Account> businessAccounts = AP23_TestDataFactory.createBusinessAccount(2);
        insert businessAccounts;
        List<Product_Service__c> psList = new List<Product_Service__c>();
        
        Product_Service__c softwarePS = new Product_Service__c();
        softwarePS.Type__c = 'Software';
        softwarePS.Product_Service_Name__c = 'Salesforce Service Cloud - Performance Edition';
        softwarePS.Annual_Cost__c = 1000;
        softwarePS.Monthly_Cost__c = 83.50;
        psList.add(softwarePS);

        Product_Service__c hardwarePS = new Product_Service__c();
        hardwarePS.Type__c = 'Hardware';
        hardwarePS.Product_Service_Name__c = 'Laptop';
        hardwarePS.Annual_Cost__c = 2000;
        hardwarePS.Monthly_Cost__c = 167;
        psList.add(hardwarePS);

        Product_Service__c hardwarePS2 = new Product_Service__c();
        hardwarePS2.Type__c = 'Hardware';
        hardwarePS2.Product_Service_Name__c = 'Desktop';
        hardwarePS2.Annual_Cost__c = 2500;
        hardwarePS2.Monthly_Cost__c = 208;
        psList.add(hardwarePS2);

        insert psList;

        List<User> userList = [select Id from User where IsActive = TRUE LIMIT 4];
        List<Department__c> deptList = new List<Department__c>();
        List<Employment__c> empList = new List<Employment__c>();

        Department__c dept1 = new Department__c(Name = 'Department 1');
        Department__c dept2 = new Department__c(Name = 'Department 2');
        deptList.add(dept1);
        deptList.add(dept2);
        insert deptList;

        system.debug('*** -- deptList ' + deptList + ' -- ***');

        for (integer i = 0 ; i < userList.size() ; i++){
            User u = userList[i];
            Employment__c e = new Employment__c();
            e.User__c = u.Id;
            if (i < 2) e.Department__c = deptList[0].Id;
            if (i >= 2) e.Department__c = deptList[1].Id;

            e.Start_Date__c = Date.today().addYears(-2);

            empList.add(e);
        }

        system.debug('*** -- empList ' + empList + ' -- ***');

        insert empList;

    }

    static testmethod void testDuplicatesInsert(){
        List<Product_Service_Resource__c> psrList = new List<Product_Service_Resource__c>();
        Map<String, Product_Service__c> psMap = new Map<String, Product_Service__c>();
        for (Product_Service__c ps : [select Id, Type__c from Product_Service__c]){
            psMap.put(ps.Type__c, ps);
        }
        for (Employment__c e : [select Id from Employment__c]){
            Product_Service_Resource__c swPSR = new Product_Service_Resource__c();
            Product_Service_Resource__c hwPSR = new Product_Service_Resource__c();

            swPSR.Employment__c = e.Id;
            hwPSR.Employment__c = e.Id;
            swPSR.Product_Service__c = psMap.get('Software').Id;
            hwPSR.Product_Service__c = psMap.get('Hardware').Id;

            psrList.add(swPSR);
            psrList.add(hwPSR);

        }

        system.debug('*** -- psrList ' + psrList + ' -- ***');

        insert psrList;

        //Now insert duplicates
        List<Product_Service_Resource__c> dupPSRList = new List<Product_Service_Resource__c>();

        for (Employment__c e : [select Id from Employment__c]){
            Product_Service_Resource__c swPSR = new Product_Service_Resource__c();
            Product_Service_Resource__c hwPSR = new Product_Service_Resource__c();

            swPSR.Employment__c = e.Id;
            hwPSR.Employment__c = e.Id;
            swPSR.Product_Service__c = psMap.get('Software').Id;
            hwPSR.Product_Service__c = psMap.get('Hardware').Id;

            dupPSRList.add(swPSR);
            dupPSRList.add(hwPSR);

        }

        test.startTest();
            AP65_PSResourceTriggerHandler handler = new AP65_PSResourceTriggerHandler();
            try {
                handler.checkForDuplicate(dupPSRList,null);
            }catch(Exception e) {
                Boolean expectedExceptionThrown =  (e.getMessage().contains(AP65_PSResourceTriggerHandler.DUPLICATE_PSR_ERROR) ? true : false);
                System.AssertEquals(expectedExceptionThrown, true);
            }
        test.stopTest();

    }

    static testmethod void testDuplicatesUpdate(){
        List<Product_Service_Resource__c> psrList = new List<Product_Service_Resource__c>();
        Map<String, Product_Service__c> psMap = new Map<String, Product_Service__c>();
        for (Product_Service__c ps : [select Id, Type__c, Product_Service_Name__c from Product_Service__c]){
            psMap.put(ps.Product_Service_Name__c, ps);
        }
        for (Employment__c e : [select Id from Employment__c]){
            Product_Service_Resource__c swPSR = new Product_Service_Resource__c();
            Product_Service_Resource__c hwPSR = new Product_Service_Resource__c();
            Product_Service_Resource__c hwPSR1 = new Product_Service_Resource__c();

            swPSR.Employment__c = e.Id;
            hwPSR.Employment__c = e.Id;
            hwPSR1.Employment__c = e.Id;
            swPSR.Product_Service__c = psMap.get('Salesforce Service Cloud - Performance Edition').Id;
            hwPSR.Product_Service__c = psMap.get('Laptop').Id;
            hwPSR1.Product_Service__c = psMap.get('Desktop').Id;


            psrList.add(swPSR);
            psrList.add(hwPSR);
            psrList.add(hwPSR1);

        }

        system.debug('*** -- psrList ' + psrList + ' -- ***');

        insert psrList;


        //Now update to a duplicate
        Map<Id, Product_Service_Resource__c> oldMap = new Map<Id, Product_Service_Resource__c>();
        List<Product_Service_Resource__c> dupPSRList = new List<Product_Service_Resource__c>();

        for (Employment__c e : [select Id from Employment__c]){
            Product_Service_Resource__c dupPSR = psrList[2];
            oldMap.put(dupPSR.Id, dupPSR);
            dupPSR.Product_Service__c = psMap.get('Laptop').Id;
            dupPSRList.add(dupPSR);
        }

        test.startTest();
            AP65_PSResourceTriggerHandler handler = new AP65_PSResourceTriggerHandler();
            try {
                handler.checkForDuplicate(dupPSRList,oldMap);
            }catch(Exception e) {
                Boolean expectedExceptionThrown =  (e.getMessage().contains(AP65_PSResourceTriggerHandler.DUPLICATE_PSR_ERROR) ? true : false);
                System.AssertEquals(expectedExceptionThrown, true);
            }
        test.stopTest();

    }

    static testmethod void test() {
        List<Product_Service_Resource__c> psrList = new List<Product_Service_Resource__c>();
        Map<String, Product_Service__c> psMap = new Map<String, Product_Service__c>();
        for (Product_Service__c ps : [select Id, Type__c from Product_Service__c]){
            psMap.put(ps.Type__c, ps);
        }
        for (Employment__c e : [select Id from Employment__c]){
            Product_Service_Resource__c swPSR = new Product_Service_Resource__c();
            Product_Service_Resource__c hwPSR = new Product_Service_Resource__c();

            swPSR.Employment__c = e.Id;
            hwPSR.Employment__c = e.Id;
            swPSR.Product_Service__c = psMap.get('Software').Id;
            hwPSR.Product_Service__c = psMap.get('Hardware').Id;

            psrList.add(swPSR);
            psrList.add(hwPSR);

        }

        system.debug('*** -- psrList ' + psrList + ' -- ***');

        test.startTest();

            insert psrList;

        test.stopTest();

        for (Product_Service_Resource__c psr : [select Id, Product_Service_Type__c, Product_Service_Annual_Cost__c, 
                                                Product_Service_Monthly_Cost__c from Product_Service_Resource__c]){

            system.assertNotEquals(NULL, psr.Product_Service_Annual_Cost__c);
            system.assertNotEquals(NULL, psr.Product_Service_Monthly_Cost__c);
            system.assertNotEquals(NULL, psr.Product_Service_Type__c);

        }
    }

}