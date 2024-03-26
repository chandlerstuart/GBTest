/*
Name: Flow_CountryDependentPicklistCont_Test.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Test Suite for Flow_CountryDependentPicklist Controller
======================================================
======================================================

Tests:

History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-06-18  Initial development.
*/
@isTest
public class Flow_CountryDependentPicklistCont_Test {
    
    @TestSetup static void createData(){
        
        List<Golfbreaks_Business_Unit__c> gbus = new List<Golfbreaks_Business_Unit__c>();
        for(integer i=0;i<5;i++){
            Golfbreaks_Business_Unit__c gbu = new Golfbreaks_Business_Unit__c();
            gbu.Name = 'Test Business Unit '+i;
            if(i==0) gbu.IsDefault__c = true;
            gbus.add(gbu);
        }
        insert gbus;

        List<Territory__c> territories = new List<Territory__c>();
        for(Golfbreaks_Business_Unit__c gbu : gbus){
            for(integer i = 0;i<5;i++){
                Territory__c t = new Territory__c();
                t.BusinessUnit__c = gbu.Id;
                t.Name = 'Test Territory '+i;
                territories.add(t);
            }         
        }
        insert territories;
        
    }

    @isTest static void getPicklistDataTest(){
        test.startTest();
            List<Golfbreaks_Business_Unit__c> bus = Flow_CountryDependentPicklistController.getPicklistData();
            system.debug('bus: '+bus);
        test.stopTest();
        system.assertNotEquals(null, bus);
        system.assertEquals(5, bus.size());
        for(Golfbreaks_Business_Unit__c bu :bus){
            system.assertEquals(6, bu.Territories__r.size());
        }
    }
}