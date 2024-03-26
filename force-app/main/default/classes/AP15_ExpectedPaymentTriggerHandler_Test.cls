/**
* Class Name: AP15_ExpectedPaymentTriggerHandler_Test
* @author: Emman Flores
* @date: 07.05.2016
* @description: Test AP15_ExpectedPaymentTriggerHandler
*/

@isTest(seeAllData=false)

public class AP15_ExpectedPaymentTriggerHandler_Test{
    
    @testSetup static void setup(){
        OrgSettings__c orgset = new OrgSettings__c(TriggersActive__c = true);
        insert orgset;
    }
       
    static testMethod void testEvents() {
        //Create List of Quote
        List<Expected_Payment__c> expectedPaymentList = new List<Expected_Payment__c>();
        
        //Create Account
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        database.insert(acc);
        
        //Create Opportunity
        Opportunity opp = AP23_TestDataFactory.createOpportunity(1,'1. Recommendations',acc)[0];
        opp.ServiceAgentAssigned__c = 'Test Agent';
        database.insert(opp);
        
        //Create Booking
        Booking__c booking = AP23_TestDataFactory.createBooking(1,acc,opp.Id)[0];
        booking.AmountPaid__c = 1;
        database.insert(booking);
        
        //Create Expected payment
        expectedPaymentList = AP23_TestDataFactory.createExpectedPayment(200, booking ,'Partial Deposit', 1);
        
        for(Expected_Payment__c ep : expectedPaymentList){
            ep.ExpectedPaymentType__c = 'Full Deposit';
        }
        
        List<Expected_Payment__c> newExPayList = new List<Expected_Payment__c>(expectedPaymentList);
        List<Expected_Payment__c> oldExPayList = new List<Expected_Payment__c>(expectedPaymentList);
        Map<Id,Expected_Payment__c> newExPayMap = new Map<Id,Expected_Payment__c>([SELECT Id FROM Expected_Payment__c]);
        Map<Id,Expected_Payment__c> oldExPayMap = new Map<Id,Expected_Payment__c>([SELECT Id FROM Expected_Payment__c]);
        
        test.startTest();
            AP15_ExpectedPaymentTriggerHandler expPaymenttriggerhandler = new AP15_ExpectedPaymentTriggerHandler();
            
            database.insert(expectedPaymentList);
            System.assertEquals(200, [SELECT Count() FROM Expected_Payment__c]);
            
            database.update(expectedPaymentList);
            
            database.delete(expectedPaymentList);
            System.assertEquals(0, [SELECT Count() FROM Expected_Payment__c]);
            // expPaymenttriggerhandler.OnBeforeInsert(newExPayList,newExPayMap,oldExPayList,oldExPayMap);
            // expPaymenttriggerhandler.OnBeforeUpdate(newExPayList,newExPayMap,oldExPayList,oldExPayMap);
            // expPaymenttriggerhandler.OnAfterInsert(newExPayList,newExPayMap,oldExPayList,oldExPayMap);
            // expPaymenttriggerhandler.OnAfterUpdate(newExPayList,newExPayMap,oldExPayList,oldExPayMap);
            // expPaymenttriggerhandler.OnBeforeDelete(newExPayList,newExPayMap,oldExPayList,oldExPayMap);
            // expPaymenttriggerhandler.OnAfterDelete(newExPayList,newExPayMap,oldExPayList,oldExPayMap);
            expPaymenttriggerhandler.OnAfterUnDelete(newExPayList,newExPayMap,oldExPayList,oldExPayMap);
            expPaymenttriggerhandler.OnUndelete(newExPayList,newExPayMap,oldExPayList,oldExPayMap);
        test.stopTest();  
        
    }
}