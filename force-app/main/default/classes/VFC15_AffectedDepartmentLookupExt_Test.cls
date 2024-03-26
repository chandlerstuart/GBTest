/*
Name:  VFC15_AffectedDepartmentLookupExt_Test.cls
======================================================
======================================================
Purpose:
-------
Test Class for VFC15_AffectedDepartmentLookupExt
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.0  S.Molloy      2017-11-09   Initial development
*/
@isTest
private class VFC15_AffectedDepartmentLookupExt_Test {
    
    
    @testSetup
    static void dataSetup() {
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;

        List<Change_Request__c> crList = AP23_TestDataFactory.createChangeRequest(null, 1);
        insert crList;

        List<User> userList = [select Id from User where IsActive = TRUE LIMIT 5];
        List<Department__c> deptList = AP23_TestDataFactory.createDepartment(5, userList);
        insert deptList;

        List<Sprint__c> sprintList = AP23_TestDataFactory.createSprint(1);
        insert sprintList;

        List<Sprint_Item__c> siList = AP23_TestDataFactory.createSprintItem(sprintList, crList[0], 5);
        insert siList;
    }
    
    private static testMethod void testSave() {
        
        Sprint_Item__c si = [select Id from Sprint_Item__c LIMIT 1];

        ApexPages.StandardController controller = new ApexPages.StandardController(si);

        PageReference testPage = Page.VFP15_AffectedDepartmentLookup;
        test.setCurrentPage(testPage);

        test.startTest();

        VFC15_AffectedDepartmentLookupExt ext = new VFC15_AffectedDepartmentLookupExt(controller);
        SelectOption dept = ext.departmentSelect[0];
        List<String> deptList = new List<String>();
        deptList.add(dept.getValue());
        ext.selectedDepartments = deptList;

        ext.saveAll();

        test.stopTest();

        List<Affected_Department__c> adList = [select Id, Department__c, Sprint_Item__c from Affected_Department__c];

        system.assertNotEquals(TRUE, adList.isEmpty());

        system.assertEquals(si.Id, adList[0].Sprint_Item__c);

    }

    private static testMethod void testDelete() {
        
        Sprint_Item__c si = [select Id from Sprint_Item__c LIMIT 1];
        Department__c d = [select Id from Department__c LIMIT 1];
        Affected_Department__c ad = new Affected_Department__c(Department__c = d.Id, Sprint_Item__c = si.Id);
        insert ad;

        ApexPages.StandardController controller = new ApexPages.StandardController(si);

        PageReference testPage = Page.VFP15_AffectedDepartmentLookup;
        test.setCurrentPage(testPage);

        test.startTest();

        VFC15_AffectedDepartmentLookupExt ext = new VFC15_AffectedDepartmentLookupExt(controller);
        system.assertNotEquals(TRUE, ext.currentRecords.isEmpty());

        ext.currentRecords[0].isSelected = TRUE;

        ext.deleteSelected();

        test.stopTest();

        List<Affected_Department__c> checkList = [select Id from Affected_Department__c];

        system.assertEquals(TRUE, checkList.isEmpty());

    }
}