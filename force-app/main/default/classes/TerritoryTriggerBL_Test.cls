/*
Name:  TerritoryTriggerBL_Test
Copyright © 2018  Golfbreaks
======================================================
======================================================
Purpose:
-------

Test Class for Territory__c Trigger BL 

======================================================
======================================================
Detail:
Test Scenario 1: New Default Territory Selection: Confirm when a new default is selected, the previous default is deselected
Test Scenario 2: New Default Territory Creation: Confirm when a new default is inserted, the previous default is deselected
Test Scenario 3: Deselect Default Territory: Confirm when the default territory is deselected, the oldest (first created) territory is updated to the default
Test Scenario 4: Block Delete Default: Confirm an error is thrown if a user attempts to delete the Default Territory
Test Scenario 5: Country Spanning Error: Confirm an error is thrown if a user attempts to create/update a territory with a Country that is already assigned to another Territory within the same Business Unit

Summary: These tests should ensure that one (and only one) default territory should exist for each Business Unit. 
They should also verify that no Country can span multiple Territories within a Business Unit

History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-05-08  Initial development.
1.1  J Radcliffe   2023-02-13  Developer Name is required. Added support for Entity Locking.
*/
@isTest
public with sharing class TerritoryTriggerBL_Test {
    
    @testSetup static void testSetup(){

        //Enable triggers for testSetup
        OrgSettings__c settings = new OrgSettings__c();
        settings.TriggersActive__c = true;
        insert settings;

        //Create Business Units and Territories for Tests
        List<Territory__c> territories = new List<Territory__c>();
        Golfbreaks_Business_Unit__c bu = new Golfbreaks_Business_Unit__c();
        bu.Name = 'Test Business Unit';
        bu.DeveloperName__c = 'TestBusinessUnit';//1.1+
        insert bu;

        for(integer i=0; i<10; i++){
            Territory__c t = new Territory__c();
            if(i==0) t.Countries__c = 'Portugal;Spain';
            t.Name = 'Territory '+i;
            t.DeveloperName__c = 'Territory'+i;//1.1+
            t.BusinessUnit__c = bu.Id;
            territories.add(t);
        }

        //Simulate a new transaction
        TerritoryTriggerHandler.isFirstAfterInsert = true;
        insert territories;

        //Create a Control Business Unit (For negative assertions; to verify no unexpected changes occur to other Business Units as changes are made to the Territories)
        List<Territory__c> controlTerritories = new List<Territory__c>();
        Golfbreaks_Business_Unit__c buControl = new Golfbreaks_Business_Unit__c();
        buControl.DeveloperName__c = 'ControlBusinessUnit';//1.1+
        buControl.Name = 'Control Business Unit';
        insert buControl;

        for(integer i=0; i<10; i++){
            Territory__c t = new Territory__c();
            if(i==3) t.IsDefault__c = true;
            t.Name = 'Territory '+i;
            t.DeveloperName__c = 'Territory_'+i;//1.1+
            t.BusinessUnit__c = buControl.Id;
            controlTerritories.add(t);
        }

        //Simulate a new transaction
        TerritoryTriggerHandler.isFirstAfterInsert = true;
        insert controlTerritories;

        for(Territory__c t : [Select Id, Name, IsDefault__c From Territory__c Where BusinessUnit__c = :buControl.Id]){
            system.debug(t.Name+' default:'+t.IsDefault__c);
        }

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
        
        List<Golfbreaks_Business_Unit__c> businessUnits = [Select Id, IsDefault__c, (Select Id, IsDefault__c, BusinessUnit__c, Countries__c From Territories__r) From Golfbreaks_Business_Unit__c Where Name = 'Test Business Unit'];
        system.assertEquals(1, businessUnits.size());
        system.assertEquals(11, businessUnits[0].Territories__r.size());//10 territories plus the 1 that is implicitly created by PB when the BU is inserted
        Integer defaultCount = 0;
        Integer withCountryCount = 0;
        for(Territory__c t : businessUnits[0].Territories__r){
            if(t.IsDefault__c) defaultCount = defaultCount+1;
            if(t.Countries__c == 'Portugal;Spain') withCountryCount = withCountryCount+1;
        }
        system.assertEquals(1,defaultCount);
        system.assertEquals(1,withCountryCount);

        verifyControlGroup();
    }

    //This method verifies no changes are made to the control group (Business Unit)
    private static void verifyControlGroup(){
        List<Golfbreaks_Business_Unit__c> controlBUs = [Select Id, IsDefault__c, (Select Id, Name, IsDefault__c, Countries__c, BusinessUnit__c From Territories__r) From Golfbreaks_Business_Unit__c Where Name = 'Control Business Unit'];
        system.assertEquals(1, controlBUs.size());
        system.assertEquals(11, controlBUs[0].Territories__r.size());//10 territories plus the 1 that is implicitly created by PB when the BU is inserted
        for(Territory__c t : controlBUs[0].Territories__r){
            if(t.Name == 'Territory 3'){
                system.assertEquals(true, t.IsDefault__c);
            }else{
                system.assertEquals(false, t.IsDefault__c);
            }
        }
    }

    //Confirm when a new default is selected, the previous default is deselected
    @istest static void testScenario1(){
        
        Territory__c newDefault;

        //Retrieve data
        List<Golfbreaks_Business_Unit__c> businessUnits = [Select Id, IsDefault__c, (Select Id, IsDefault__c, BusinessUnit__c From Territories__r) From Golfbreaks_Business_Unit__c Where Name = 'Test Business Unit'];

        for(Territory__c t : businessUnits[0].Territories__r){
            if(!t.IsDefault__c && newDefault == null) newDefault = t;
        }

        //Set the new default
        newDefault.IsDefault__c = true;

        test.startTest();
            update newDefault;
        test.stopTest();

        //Confirm the new default has remained the default
        system.assertEquals(true, [Select Id, IsDefault__c From Territory__c Where Id =:newDefault.Id LIMIT 1].IsDefault__c);
        //Confirm no other territory has IsDefault set to true
        system.assertEquals(0, [Select Id From Territory__c Where BusinessUnit__r.Name = 'Test Business Unit' and (Not Id =:newDefault.Id) and IsDefault__c = true].size());
        //Confirm the control group remains unchanged
        verifyControlGroup();
    }

    //Confirm when a new default is inserted, the previous default is deselected
    @istest static void testScenario2(){
        
        Territory__c newDefault = new Territory__c();
        newDefault.IsDefault__c = true;
        newDefault.DeveloperName__c = 'NewDef';
        newDefault.BusinessUnit__c = [Select Id From Golfbreaks_Business_Unit__c Where Name = 'Test Business Unit' Limit 1].Id;
        system.assertNotEquals(null, newDefault.BusinessUnit__c);

        //Confirm a default exists prior to the insert
        system.assertEquals(1,[Select Id From Territory__c Where BusinessUnit__r.Name = 'Test Business Unit' and IsDefault__c = true].size());

        test.startTest();
            insert newDefault;
        test.stopTest();

        //Confirm the new default has remained the default after insert
        system.assertEquals(true, [Select Id, IsDefault__c From Territory__c Where Id =:newDefault.Id LIMIT 1].IsDefault__c);
        //Confirm no other territory has IsDefault set to true
        system.assertEquals(0, [Select Id From Territory__c Where BusinessUnit__r.Name = 'Test Business Unit' and (Not Id =:newDefault.Id) and IsDefault__c = true].size());
        //Confirm the control group remains unchanged
        verifyControlGroup();
    }

    //Confirm when the default territory is deselected, the oldest (first created) territory is updated to the default
    @istest static void testScenario3(){
        
        
        Territory__c[] defaults = [Select Id From Territory__c Where BusinessUnit__r.Name = 'Test Business Unit' and IsDefault__c = true];
        system.assertEquals(1, defaults.size());

        //Deselect the default
        defaults[0].IsDefault__c = false;

        test.startTest();
            update defaults;
        test.stopTest();

        //Requery the oldest territory record related to the Business Unit
        Territory__c t = [Select Id, IsDefault__c From Territory__c Where BusinessUnit__r.Name = 'Test Business Unit' Order by CreatedDate ASC LIMIT 1][0];
        //Confirm the oldest territory has been set as the default
        system.assertEquals(true, t.IsDefault__c);
        //Confirm no other territory has IsDefault set to true (within the same Business Unit)
        system.assertEquals(0, [Select Id From Territory__c Where BusinessUnit__r.Name = 'Test Business Unit' and (Not Id =:t.Id) and IsDefault__c = true].size());
        //Confirm the control group remains unchanged
        verifyControlGroup();
    }

    //Confirm an error is thrown if a user attempts to delete the Default Territory
    @istest static void testScenario4(){
        
        
        Territory__c[] defaults = [Select Id From Territory__c Where BusinessUnit__r.Name = 'Test Business Unit' and IsDefault__c = true];
        system.assertEquals(1, defaults.size());

        test.startTest();
            try{
                delete defaults;
            }catch(DmlException e){
                //Confirm the expected error is thrown
                system.assertEquals(true,e.getMessage().contains(ApplicationConstant.TERRITORY_DEFAULT_DELETION_ERROR));
            }
            
        test.stopTest();

        //Confirm the control group remains unchanged
        verifyControlGroup();
    }

    //Confirm an error is thrown if a user attempts to create/update a territory with a Country that is already assigned to another Territory within the same Business Unit
    @istest static void testScenario5(){
        
        //Retrieve data (excl the territory with existing Countries)
        List<Golfbreaks_Business_Unit__c> businessUnits = [Select Id, IsDefault__c, (Select Id, IsDefault__c, BusinessUnit__c, Countries__c From Territories__r Where Countries__c = null) From Golfbreaks_Business_Unit__c Where Name = 'Test Business Unit'];
        system.assertEquals(1, businessUnits.size());
        system.assertEquals(true, businessUnits[0].Territories__r.size()>0);
        
        //Territory for insert
        Territory__c insertTerritory = new Territory__c();
        insertTerritory.BusinessUnit__c = businessUnits[0].Id;
        insertTerritory.Name = 'New Territory';
        insertTerritory.Countries__c = 'Spain';
        
        //Territory for update
        Territory__c updateTerritory = businessUnits[0].Territories__r[0];
        updateTerritory.Countries__c = 'Portugal';

        test.startTest();
            try{
                update updateTerritory;
            }catch(DmlException e){
                //Confirm the expected error is thrown
                system.debug('error thrown on update: '+e);
                system.assertEquals(true,e.getMessage().contains(ApplicationConstant.TERRITORY_COUNTRY_VALIDATION_ERROR));
            }

            try{
                insert insertTerritory;
            }catch(DmlException e){
                //Confirm the expected error is thrown
                system.debug('error thrown on insert: '+e);
                system.assertEquals(true,e.getMessage().contains(ApplicationConstant.TERRITORY_COUNTRY_VALIDATION_ERROR));
            }
        test.stopTest();

        //Confirm the control group remains unchanged
        verifyControlGroup();
    }
}