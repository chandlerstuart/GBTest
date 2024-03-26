/*
Name:  GolfbreaksBusinessUnitTriggerBL_Test
Copyright © 2018  Golfbreaks
======================================================
======================================================
Purpose:
-------

Test Class for Golfbreaks_Business_Unit__c Trigger BL 

======================================================
======================================================
Detail:
Test Scenario 1: New Default Business Unit Selection: Confirm when a new default is selected, the previous default is deselected
Test Scenario 2: New Default Business Unit Creation: Confirm when a new default is inserted, the previous default is deselected
Test Scenario 3: Deselect Default Business Unit: Confirm when the default Business Unit is deselected, the oldest (first created) Business Unit is updated to the default
Test Scenario 4: Block Delete Default: Confirm an error is thrown if a user attempts to delete the Default Business Unit

Summary: These tests should ensure that one (and only one) default Business Unit should exist at any one time. 

History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-05-09  Initial development.
1.1  J Radcliffe   2023-02-13  Developer Name is required. Added support for Entity Locking.
*/
@isTest
public with sharing class GolfbreaksBusinessUnitTriggerBL_Test {
    
    @testSetup static void testSetup(){

        //Enable triggers for testSetup
        OrgSettings__c settings = new OrgSettings__c();
        settings.TriggersActive__c = true;
        insert settings;

        //Create Business Units
        List<Golfbreaks_Business_Unit__c> bUnitsToInsert = new List<Golfbreaks_Business_Unit__c>();
        
        for(integer i=0; i<10; i++){
            Golfbreaks_Business_Unit__c bu = new Golfbreaks_Business_Unit__c();
            bu.Name = 'Test Business Unit '+i;
            bu.DeveloperName__c = 'TBU'+i;//1.1+
            bUnitsToInsert.add(bu);
        }

        insert bUnitsToInsert;
        
        User adminUser = AP23_TestDataFactory.createAdminUsers(1, 'Admin', true)[0];
        Id runningUserId = UserInfo.getUserId();

        //1.1+ Assign edit/delete permissions
        system.runAs(adminUser){
            PermissionSet ps = [Select Id From PermissionSet Where Name = :ApplicationConstant.ENTITY_LOCKING_PERMISSION_SET_NAME];
            insert new PermissionSetAssignment(AssigneeId=runningUserId,PermissionSetId=ps.Id);
        }

        verifySetup();
    }

    //This method verifies the expected data has been created
    private static void verifySetup(){
        
        List<Golfbreaks_Business_Unit__c> businessUnits = [Select Id, IsDefault__c From Golfbreaks_Business_Unit__c];
        system.assertEquals(10, businessUnits.size());
        Integer defaultCount = 0;
        for(Golfbreaks_Business_Unit__c bu : businessUnits){
            if(bu.IsDefault__c) defaultCount = defaultCount+1;
        }
        system.assertEquals(1,defaultCount);
    }

    //Confirm when a new default is selected, the previous default is deselected
    @istest static void testScenario1(){
        
        Golfbreaks_Business_Unit__c newDefault;

        //Retrieve data
        List<Golfbreaks_Business_Unit__c> businessUnits = [Select Id, IsDefault__c From Golfbreaks_Business_Unit__c];

        for(Golfbreaks_Business_Unit__c bu : businessUnits){
            if(!bu.IsDefault__c && newDefault == null) newDefault = bu;
        }

        //Set the new default
        newDefault.IsDefault__c = true;

        test.startTest();
            update newDefault;
        test.stopTest();

        //Confirm the new default has remained the default
        system.assertEquals(true, [Select Id, IsDefault__c From Golfbreaks_Business_Unit__c Where Id =:newDefault.Id LIMIT 1].IsDefault__c);
        //Confirm no other Business Unit has IsDefault set to true
        system.assertEquals(0, [Select Id From Golfbreaks_Business_Unit__c Where (Not Id =:newDefault.Id) and IsDefault__c = true].size());
    }

    //Confirm when a new default is inserted, the previous default is deselected
    @istest static void testScenario2(){
        
        Golfbreaks_Business_Unit__c newDefault = new Golfbreaks_Business_Unit__c();
        newDefault.DeveloperName__c = 'NewDef';//1.1+
        newDefault.IsDefault__c = true;
        newDefault.Name = 'New Test Business Unit';

        //Confirm a default exists prior to the insert
        system.assertEquals(1,[Select Id From Golfbreaks_Business_Unit__c  Where IsDefault__c = true].size());

        test.startTest();
            insert newDefault;
        test.stopTest();

        //Confirm the new default has remained the default after insert
        system.assertEquals(true, [Select Id, IsDefault__c From Golfbreaks_Business_Unit__c Where Id =:newDefault.Id LIMIT 1].IsDefault__c);
        //Confirm no other Business Unit has IsDefault set to true
        system.assertEquals(0, [Select Id From Golfbreaks_Business_Unit__c Where (Not Id =:newDefault.Id) and IsDefault__c = true].size());
    }

    //Confirm when the default Business Unit is deselected, the oldest (first created) Business Unit is updated to the default
    @istest static void testScenario3(){
        
        
        Golfbreaks_Business_Unit__c[] defaults = [Select Id From Golfbreaks_Business_Unit__c Where IsDefault__c = true];
        system.assertEquals(1, defaults.size());

        //Deselect the default
        defaults[0].IsDefault__c = false;

        test.startTest();
            update defaults;
        test.stopTest();

        //Requery the oldest Business Unit record
        Golfbreaks_Business_Unit__c bu = [Select Id, IsDefault__c From Golfbreaks_Business_Unit__c Order by CreatedDate ASC LIMIT 1][0];
        //Confirm the oldest Business Unit has been set as the default
        system.assertEquals(true, bu.IsDefault__c);
        //Confirm no other Business Unit has IsDefault set to true
        system.assertEquals(0, [Select Id From Golfbreaks_Business_Unit__c Where (Not Id =:bu.Id) and IsDefault__c = true].size());
    }

    //Confirm an error is thrown if a user attempts to delete the Default Business Unit
    @istest static void testScenario4(){
        
        
        Golfbreaks_Business_Unit__c[] defaults = [Select Id From Golfbreaks_Business_Unit__c Where IsDefault__c = true];
        system.assertEquals(1, defaults.size());

        test.startTest();
            try{
                delete defaults;
            }catch(DmlException e){
                //Confirm the expected error is thrown
                system.assertEquals(true,e.getMessage().contains(ApplicationConstant.BUSINESS_UNIT_DEFAULT_DELETION_ERROR));
            }
            
        test.stopTest();
    }
}