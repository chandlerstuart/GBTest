/**
* Class Name: AP09_BookingTriggerHandler_Test
* @author: Emman Flores
* @date: 07.05.2016
* @description: Test AP09_BookingTriggerHandler

* History
* Version	Author			Date		Detail
* 1.1		J Radcliffe		15-10-18	Force the use of non-test Routing Configurations.
* 1.2       Mark Cane&      2018-11-12  Add testSetup block for WIRE calculations on test data.
* 1.3       J Radcliffe     2024-02-13  New test method testAssignPublicIdsOnInsert
*/

@isTest(seeAllData=false)
 
public class AP09_BookingTriggerHandler_Test{

    @TestSetup
    static void testSetup(){
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;                

        insert new Phased_Code_Removal__c(ActivatePublicIdGeneration__c = true);//1.3+  

        //Allow the current running test user to insert Client accounts        
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
    }
       
    static testMethod void testEvents() {
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.1
        
        WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//<-- 1.2 block WIRE calculations for test data.
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true; 
        
        //Create Account
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        database.insert(acc);
        
        //Create Opportunity
        Opportunity opp = AP23_TestDataFactory.createOpportunity(1,'1. Recommendations',acc)[0];
        opp.ServiceAgentAssigned__c = 'Test Agent';
        database.insert(opp);
        
        //Create Booking
        List<Booking__c> bookingList = AP23_TestDataFactory.createBooking(50,acc,opp.Id);
        
        
        List<Booking__c> newBookList = new List<Booking__c>(bookingList);
        List<Booking__c> oldBookList = new List<Booking__c>(bookingList);
        Map<Id,Booking__c> newBookMap = new Map<Id,Booking__c>([SELECT Id FROM Booking__c]);
        Map<Id,Booking__c> oldBookMap = new Map<Id,Booking__c>([SELECT Id FROM Booking__c]);
        
        test.startTest();
            AP09_BookingTriggerHandler bookingtriggerhandler = new AP09_BookingTriggerHandler();
            database.insert(bookingList);
            System.assertEquals(50, [SELECT Count() FROM Booking__c]);
            database.update(bookingList);
            
            database.delete(bookingList);
            System.assertEquals(0, [SELECT Count() FROM Booking__c]);
            // bookingtriggerhandler.OnBeforeInsert(newBookList,newBookMap,oldBookList,oldBookMap);
            // bookingtriggerhandler.OnBeforeUpdate(newBookList,newBookMap,oldBookList,oldBookMap);
            // bookingtriggerhandler.OnAfterInsert(newBookList,newBookMap,oldBookList,oldBookMap);
            // bookingtriggerhandler.OnAfterUpdate(newBookList,newBookMap,oldBookList,oldBookMap);
            // bookingtriggerhandler.OnBeforeDelete(newBookList,newBookMap,oldBookList,oldBookMap);
            // bookingtriggerhandler.OnAfterDelete(newBookList,newBookMap,oldBookList,oldBookMap);
            bookingtriggerhandler.OnAfterUnDelete(newBookList,newBookMap,oldBookList,oldBookMap);
            bookingtriggerhandler.OnUndelete(newBookList,newBookMap,oldBookList,oldBookMap);
        test.stopTest();  
    }

    //1.3+
    @isTest static void testAssignPublicIdsOnInsert(){
        
        Account acc = AP23_TestDataFactory.createPersonAccount(1,true)[0];
        insert(acc);

        Opportunity opp = AP23_TestDataFactory.createOpportunity(1,ApplicationConstant.RECOMMENDATIONSTAGE,acc)[0];
        insert opp;

        List<Booking__c> bookingList = AP23_TestDataFactory.createBooking(10,acc,opp.Id); 

        test.startTest();
            insert bookingList;
            Map<Id,Booking__c> bookingMap = new Map<Id,Booking__c>(bookingList);
            system.assertEquals(10, [Select Count() From Booking__c Where Id In:bookingMap.keySet() and PublicId__c != null]);
        test.stopTest();

    }
}