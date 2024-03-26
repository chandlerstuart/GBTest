/*
Name:  VFC16_EmployeeProductServiceSetupTest.cls
======================================================
======================================================
Purpose:
-------
Test Class for VFC16_EmployeeProductServiceSetup
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.0  S.Molloy      2017-11-10   Initial development
*/
@isTest
private class VFC16_EmployeeProductServiceSetupTest {
    
    @testSetup
    static void dataSetup() {
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;

        List<Account> businessAccounts = AP23_TestDataFactory.createBusinessAccount(2);
        businessAccounts[0].Name = 'Software Account';
        businessAccounts[1].Name = 'Hardware Account';
        insert businessAccounts;

        List<Product_Service__c> psList = new List<Product_Service__c>();

        Product_Service__c softwarePS = new Product_Service__c();
        softwarePS.Type__c = 'Software';
        softwarePS.Product_Service_Name__c = 'Salesforce Service Cloud - Performance Edition';
        softwarePS.Annual_Cost__c = 1000;
        softwarePS.Account__c = businessAccounts[0].Id;
        psList.add(softwarePS);

        Product_Service__c hardwarePS = new Product_Service__c();
        hardwarePS.Type__c = 'Hardware';
        hardwarePS.Product_Service_Name__c = 'Laptop';
        hardwarePS.Monthly_Cost__c = 167;
        hardwarePS.Account__c = businessAccounts[1].Id;
        psList.add(hardwarePS);
        insert psList;

        List<Change_Request__c> crList = AP23_TestDataFactory.createChangeRequest(null, 1);
        insert crList;

        List<User> userList = [select Id from User where IsActive = TRUE LIMIT 5];
        List<Department__c> deptList = AP23_TestDataFactory.createDepartment(5, userList);
        insert deptList;

        List<Employment__c> empList = AP23_TestDataFactory.createEmployment(3, deptList);
        List<User> empUserList = [select Id from User where IsActive = TRUE AND Id NOT in :userList LIMIT 15];
        for (integer i = 0 ; i < empList.size() ; i++){
            empList[i].User__c = empUserList[i].Id;
        }
        insert empList;
    }
    
    private static testMethod void testController() {
        List<Employment__c> empList = [select Id, User__c from Employment__c];
        List<Product_Service__c> psList = [select Id, Product_Service_Name__c from Product_Service__c];
        List<Product_Service_Resource__c> psrList = new List<Product_Service_Resource__c>();
        for (integer i = 0 ; i < 3 ; i++){
            Product_Service_Resource__c psr = new Product_Service_Resource__c();
            psr.Employment__c = empList[i].Id;
            psr.Product_Service__c = psList[0].Id;
            psrList.add(psr);
        }
        for (integer i = 3 ; i < 6 ; i++){
            Product_Service_Resource__c psr = new Product_Service_Resource__c();
            psr.Employment__c = empList[i].Id;
            psr.Product_Service__c = psList[1].Id;
            psrList.add(psr);
        }

        insert psrList;

        PageReference testPage = Page.VFP16_EmployeeProductServiceSetup;
        test.setCurrentPage(testPage);    
        VFC16_EmployeeProductServiceSetup controller = new VFC16_EmployeeProductServiceSetup();

        List<SelectOption> departments = controller.departments;
        List<SelectOption> employees = controller.employees;
        String debugSoql = controller.debugSoql;
        
        Integer productListSize = controller.productListSize;

        controller.toggleSort();
        controller.clearEmployees();

        controller.selectedDepartment = departments[1].getValue();
        employees = controller.employees;

        controller.selectedEmployee = empList[0].Id;
        controller.getCurrentRecords();

        system.assertEquals(1, controller.currentRecords.size());

        for (VFC16_EmployeeProductServiceSetup.ResourceWrapper rw : controller.currentRecords){
            rw.isSelected = TRUE;
        }

        controller.deleteSelected();

        system.assertEquals(TRUE, controller.currentRecords.isEmpty());
        
        controller.clearDeptEmp();
        
        system.assertEquals(NULL, controller.selectedDepartment);
        system.assertEquals(NULL, controller.selectedEmployee);
        system.assertEquals(TRUE, controller.currentRecords.isEmpty());
        
        controller.fetchDefaults();
        
        Map<String, String> defaultFieldMap = controller.defaultFieldMap;
        List<SelectOption> defaultSelectios = controller.defaultSelections;

    }

    private static testMethod void testSearch1(){
        List<Product_Service__c> psList = [select Id, Product_Service_Name__c, Account__r.Name from Product_Service__c];
        
        PageReference testPage = Page.VFP16_EmployeeProductServiceSetup;
        testPage.getParameters().put('productName',psList[0].Product_Service_Name__c.substring(0,3));
        testPage.getParameters().put('accountName','');
        test.setCurrentPage(testPage);    
        VFC16_EmployeeProductServiceSetup controller = new VFC16_EmployeeProductServiceSetup();
        
        controller.runSearch();

        system.assertEquals(1, controller.productWrappers.size());
    }

    private static testMethod void testSearch2(){
        List<Product_Service__c> psList = [select Id, Product_Service_Name__c, Account__r.Name from Product_Service__c];
        
        PageReference testPage = Page.VFP16_EmployeeProductServiceSetup;
        testPage.getParameters().put('productName','');
        testPage.getParameters().put('accountName',psList[0].Account__r.Name.substring(0,3));
        test.setCurrentPage(testPage);    
        VFC16_EmployeeProductServiceSetup controller = new VFC16_EmployeeProductServiceSetup();
        
        controller.runSearch();

        system.assertEquals(1, controller.productWrappers.size());
    }

    private static testMethod void testSave(){
        List<Employment__c> empList = [select Id, User__c from Employment__c LIMIT 1];
        List<Product_Service__c> psList = [select Id, Product_Service_Name__c, Account__r.Name from Product_Service__c];

        PageReference testPage = Page.VFP16_EmployeeProductServiceSetup;
        test.setCurrentPage(testPage);    
        VFC16_EmployeeProductServiceSetup controller = new VFC16_EmployeeProductServiceSetup();
        
        for (VFC16_EmployeeProductServiceSetup.ProductServiceWrapper psw : controller.productWrappers){
            psw.isSelected = TRUE;
        }

        controller.saveSelection();

        controller.selectedEmployee = empList[0].Id;

        controller.saveSelection();

        List<Product_Service_Resource__c> psrList = [select Id from Product_Service_Resource__c];
        system.assertNotEquals(TRUE, psrList.isEmpty());
    }
}