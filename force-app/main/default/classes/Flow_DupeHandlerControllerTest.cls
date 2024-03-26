/**
* Class Name: Flow_DupeHandlerControllerTest
* @author: James Radcliffe
* @date: 12-09-19
* @description: Test Class for Flow_DupeHandlerController.cls
* 

History

Version   Author        Date        Detail
***************************************************
1.0       J Radcliffe   12/09/2019    Initial Developement
*/
@isTest
public with sharing class Flow_DupeHandlerControllerTest {

    @testSetup static void createTestData(){

        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//<-- 3.8 block WIRE calculations for test data.
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
        
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings; 
         
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;

        //Create 50 Accounts
        insert AP23_TestDataFactory.createPersonAccount(50,true);
    }

    @isTest static void testGetAccountData(){
        
        Map<Id,Account> accMap = new Map<Id,Account>([Select Id,Name,FirstName,LastName,PersonEmail,PersonMobilePhone,PersonHomePhone,Phone From Account Limit 100]);
        List<Id> accIds = new List<Id>();
        system.assertEquals(50, accMap.values().size());
        for(Id id:accMap.keySet()){
            accIds.add(id);
        }

        List<String> compareFields = new List<String>{'FirstName','LastName','PersonEmail'};
        List<String> displayFields = new List<String>{'PersonMobilePhone','Phone','PersonHomePhone'};

        test.startTest();
            List<Flow_DupeHandlerController.ObjectWrapper> data = Flow_DupeHandlerController.getRecordData('Account', displayFields, compareFields, 'Name', accIds);
        test.stopTest();

        system.assertEquals(50, data.size());
        for(Flow_DupeHandlerController.ObjectWrapper record : data){
            system.assertNotEquals(null, record.recordId);
            system.assertEquals(accMap.get(record.recordId).Name, record.recordName);
            system.assertEquals(3, record.displayFields.size());
            system.assertEquals(3, record.compareFields.size());
            for(Flow_DupeHandlerController.FieldWrapper field : record.displayFields){
                system.assertEquals(true, displayFields.contains(field.fieldName));
                system.assertEquals(accMap.get(record.recordId).get(field.fieldName), field.fieldValue);
            }
            for(Flow_DupeHandlerController.FieldWrapper field : record.compareFields){
                system.assertEquals(true, compareFields.contains(field.fieldName));
                system.assertEquals(accMap.get(record.recordId).get(field.fieldName), field.fieldValue);
            }
        }


    }
}