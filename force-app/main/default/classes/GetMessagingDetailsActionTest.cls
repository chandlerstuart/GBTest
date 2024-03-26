/*
Name:  GetMessagingDetailsActionTest.cls
======================================================
======================================================
Purpose:
-------
Test suite to facilitate code sufficient code coverage for the 'GetMessagingDetailsAction.cls' Class.
This Test Suite will cover seperate outcome in-which could occur when an AccoundId is passed into the 
request variable. 

Code Coverage at 98%

Test Scenarios
1. Account with an active Opportunity
2. Account with a recently No Sale'd Opportunity
3. Account with multiple active Opportunities
4. Account with an Active Booking
5. Account with a recently Travelled Booking
6. Account with Active Opp & Active Booking
7. Account with multiple active Booking's
8. Exception Handling Coverage
-------
======================================================
======================================================
History
------- 
Ver. Author     Date        Detail
1.0  C Stuart   2024-01-19  Initial development.
*/

@IsTest
public with sharing class GetMessagingDetailsActionTest{

    public class CustomException extends Exception {}

     @IsTest static void testScenario1(){

        // (1) Account with an active Opportunity

        Account client = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert client;

        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, ApplicationConstant.OPP_STAGE_NEW, client)[0];
        insert opp;

        User u = AP23_TestDataFactory.createStandardUsers(1, 'Test', false)[0];
        insert u;

        GBWire__PreferredAgent__c prefAgent = AP23_TestDataFactory.createPreferredAgent(1, client.Id, u.Id, opp.Id, 'GBWire__Opportunity__c', ApplicationConstant.PREFERRED_AGENT_TYPE_SHORT_TERM)[0];
        insert prefAgent;

        Set<Id> clientId = new Set<Id>{client.Id};
        List<GetMessagingDetailsAction.ActionRequest> inputList = getMessagingDetailsActionRequestHelper(clientId);

        Test.startTest();
            List<GetMessagingDetailsAction.ActionResult> resultsList = GetMessagingDetailsAction.getMessagingDetails(inputList);
        Test.stopTest();

        System.assertEquals(0, [SELECT Count() FROM Golfbreaks__PlatformLog__c]); // Confirm No Failures Have Happened
        System.assertEquals(inputList.size(), resultsList.size()); // Confirm Request Input Matches Results Size
 
        for(GetMessagingDetailsAction.ActionResult res : resultsList) {
            System.assertEquals('Opportunity',res.serviceWorkItemDataType, 'Incorrect Work Item Data Type');
            System.assertEquals(opp.Id, res.messagingServiceWorkItemId);
        }
    }

    @IsTest static void testScenario2(){

        // (2) Account with a recently No Sale'd Opportunity

        Account client = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert client;

        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, ApplicationConstant.OPP_STAGE_NOSALE, client)[0];
        opp.RecordTypeId = ApplicationConstant.OPP_RECTYPEID_CONTACTED; // Contacted Record Type Id
        opp.CloseDate = Date.Today(); // Close Date Today
        insert opp;

        User u = AP23_TestDataFactory.createStandardUsers(1, 'Test', false)[0];
        insert u;

        GBWire__PreferredAgent__c prefAgent = AP23_TestDataFactory.createPreferredAgent(1, client.Id, u.Id, opp.Id, 'GBWire__Opportunity__c', ApplicationConstant.PREFERRED_AGENT_TYPE_SHORT_TERM)[0];
        insert prefAgent;
        
        Set<Id> clientId = new Set<Id>{client.Id};
        List<GetMessagingDetailsAction.ActionRequest> inputList = getMessagingDetailsActionRequestHelper(clientId);

        Test.startTest();
            List<GetMessagingDetailsAction.ActionResult> resultsList = GetMessagingDetailsAction.getMessagingDetails(inputList);
        Test.stopTest();

        System.assertEquals(0, [SELECT Count() FROM Golfbreaks__PlatformLog__c]); // Confirm No Failures Have Happened
        System.assertEquals(inputList.size(), resultsList.size()); // Confirm Request Input Matches Results Size

        for(GetMessagingDetailsAction.ActionResult res : resultsList) {
            System.assertEquals('Opportunity',res.serviceWorkItemDataType, 'Incorrect Work Item Data Type');
            System.assertEquals(opp.Id, res.messagingServiceWorkItemId);
        }
    }

    @IsTest static void testScenario3(){

        // (3)  Account with multiple active Opportunities

        Account client = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert client;

        List<Opportunity> opp = AP23_TestDataFactory.createOpportunity(2, ApplicationConstant.OPP_STAGE_NEW, client);
        insert opp;

        User u = AP23_TestDataFactory.createStandardUsers(1, 'Test', false)[0];
        insert u;

        GBWire__PreferredAgent__c prefAgent = AP23_TestDataFactory.createPreferredAgent(2, client.Id, u.Id, opp[0].Id, 'GBWire__Opportunity__c', ApplicationConstant.PREFERRED_AGENT_TYPE_SHORT_TERM)[0];
        insert prefAgent;
    
        Set<Id> clientId = new Set<Id>{client.Id};
        List<GetMessagingDetailsAction.ActionRequest> inputList = getMessagingDetailsActionRequestHelper(clientId);

        Test.startTest();
            List<GetMessagingDetailsAction.ActionResult> resultsList = GetMessagingDetailsAction.getMessagingDetails(inputList);
        Test.stopTest();

        System.assertEquals(0, [SELECT Count() FROM Golfbreaks__PlatformLog__c]);
        System.assertEquals(inputList.size(), resultsList.size());

        for(GetMessagingDetailsAction.ActionResult res : resultsList) {
            System.assertEquals('Opportunity',res.serviceWorkItemDataType, 'Incorrect Work Item Data Type');
        }
    }

    @IsTest static void testScenario4(){

        // (4) - Account with a active Booking

        Account client = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert client;

        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, ApplicationConstant.OPP_STAGE_CP_FULLBALANCE, client)[0];
        opp.RecordTypeId = ApplicationConstant.OPP_RECTYPEID_CONTACTED;
        opp.CloseDate = Date.Today();
        insert opp;

        Booking__c bk = AP23_TestDataFactory.createBooking(1,client, opp.Id)[0];
        bk.Travel_Date__c = Date.Today().addDays(10);
        insert bk;

        User u = AP23_TestDataFactory.createStandardUsers(1, 'Test', false)[0];
        insert u;

        GBWire__PreferredAgent__c prefAgent = AP23_TestDataFactory.createPreferredAgent(1, client.Id, u.Id, opp.Id, 'GBWire__Opportunity__c', ApplicationConstant.PREFERRED_AGENT_TYPE_SHORT_TERM)[0];
        insert prefAgent;

        Set<Id> clientId = new Set<Id>{client.Id};
        List<GetMessagingDetailsAction.ActionRequest> inputList = getMessagingDetailsActionRequestHelper(clientId);

        Test.startTest();
            List<GetMessagingDetailsAction.ActionResult> resultsList = GetMessagingDetailsAction.getMessagingDetails(inputList);
        Test.stopTest();

        System.assertEquals(0, [SELECT Count() FROM Golfbreaks__PlatformLog__c]);
        System.assertEquals(inputList.size(), resultsList.size());
 
        for(GetMessagingDetailsAction.ActionResult res : resultsList) {
            System.assertEquals('Booking__c',res.serviceWorkItemDataType, 'Incorrect Work Item Data Type');
            System.assertEquals(bk.Id, res.messagingServiceWorkItemId);
        }
    }

    @IsTest static void testScenario5(){

        // (5) Test Scenario - Account with a recently Travelled Booking

        Account client = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert client;

        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, ApplicationConstant.OPP_STAGE_TRIPCOMPLETED, client)[0];
        opp.RecordTypeId = ApplicationConstant.OPP_RECTYPEID_CONTACTED;
        opp.CloseDate = Date.Today();
        insert opp;

        Booking__c bk = AP23_TestDataFactory.createBooking(1,client, opp.Id)[0];
        bk.Travel_Date__c = date.today()-5;
        bk.Nights__c = 2; 
        insert bk;

        User u = AP23_TestDataFactory.createStandardUsers(1, 'Test', false)[0];
        insert u;

        GBWire__PreferredAgent__c prefAgent = AP23_TestDataFactory.createPreferredAgent(1, client.Id, u.Id, opp.Id, 'GBWire__Opportunity__c', ApplicationConstant.PREFERRED_AGENT_TYPE_SHORT_TERM)[0];
        insert prefAgent;

        Set<Id> clientId = new Set<Id>{client.Id};
        List<GetMessagingDetailsAction.ActionRequest> inputList = getMessagingDetailsActionRequestHelper(clientId);

        Test.startTest();
            List<GetMessagingDetailsAction.ActionResult> resultsList = GetMessagingDetailsAction.getMessagingDetails(inputList);
        Test.stopTest();

        System.assertEquals(0, [SELECT Count() FROM Golfbreaks__PlatformLog__c]);
        System.assertEquals(inputList.size(), resultsList.size());

        for(GetMessagingDetailsAction.ActionResult res : resultsList) {
            System.assertEquals('Booking__c',res.serviceWorkItemDataType, 'Incorrect Work Item Data Type');
            System.assertEquals(bk.Id, res.messagingServiceWorkItemId);
        }
    }

    @IsTest static void testScenario6(){

        // (6) Account with Active Opp & Active Booking

        Account client = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert client;

        List<Opportunity> opp = AP23_TestDataFactory.createOpportunity(2, ApplicationConstant.OPP_STAGE_NEW, client);
        insert opp;

        Booking__c bk = AP23_TestDataFactory.createBooking(1,client, opp[0].Id)[0];
        bk.Travel_Date__c = Date.Today().addDays(10);
        insert bk;

        User u = AP23_TestDataFactory.createStandardUsers(1, 'Test', false)[0];
        insert u;

        GBWire__PreferredAgent__c prefAgent = AP23_TestDataFactory.createPreferredAgent(1, client.Id, u.Id, opp[0].Id, 'GBWire__Opportunity__c', ApplicationConstant.PREFERRED_AGENT_TYPE_SHORT_TERM)[0];
        insert prefAgent;

        Set<Id> clientId = new Set<Id>{client.Id};
        List<GetMessagingDetailsAction.ActionRequest> inputList = getMessagingDetailsActionRequestHelper(clientId);

        Test.startTest();
            List<GetMessagingDetailsAction.ActionResult> resultsList = GetMessagingDetailsAction.getMessagingDetails(inputList);
        Test.stopTest();

        System.assertEquals(0, [SELECT Count() FROM Golfbreaks__PlatformLog__c]);
        System.assertEquals(inputList.size(), resultsList.size());
 
        for(GetMessagingDetailsAction.ActionResult res : resultsList) {
            System.assertEquals('Opportunity',res.serviceWorkItemDataType, 'Incorrect Work Item Data Type');
        }
    }

    @IsTest static void testScenario7(){

        // (7) - Account with multiple active Booking's

        Account client = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert client;

        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, ApplicationConstant.OPP_STAGE_CP_FULLBALANCE, client)[0];
        opp.RecordTypeId = ApplicationConstant.OPP_RECTYPEID_CONTACTED;
        opp.CloseDate = Date.Today();
        insert opp;
    
        List<Booking__c> bks = AP23_TestDataFactory.createBooking(2,client, opp.Id);
        for(Booking__c bk : bks){
            bk.Travel_Date__c = Date.Today().addDays(5);
            bk.Nights__c = 5;
        }
        insert bks;

        User u = AP23_TestDataFactory.createStandardUsers(1, 'Test', false)[0];
        insert u;

        GBWire__PreferredAgent__c prefAgent = AP23_TestDataFactory.createPreferredAgent(1, client.Id, u.Id, opp.Id, 'GBWire__Opportunity__c', ApplicationConstant.PREFERRED_AGENT_TYPE_SHORT_TERM)[0];
        insert prefAgent;

        Set<Id> clientId = new Set<Id>{client.Id};
        List<GetMessagingDetailsAction.ActionRequest> inputList = getMessagingDetailsActionRequestHelper(clientId);

        Test.startTest();
            List<GetMessagingDetailsAction.ActionResult> resultsList = GetMessagingDetailsAction.getMessagingDetails(inputList);
        Test.stopTest();

        System.assertEquals(0, [SELECT Count() FROM Golfbreaks__PlatformLog__c]);
        System.assertEquals(inputList.size(), resultsList.size());
 
        for(GetMessagingDetailsAction.ActionResult res : resultsList) {
            System.assertEquals(true, res.isSuccess);
        }
    }

    @IsTest static void testScenario8(){

        // (8) - Exception Handling

        Account client = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert client;

        Set<Id> clientId = new Set<Id>{client.Id};
        List<GetMessagingDetailsAction.ActionRequest> inputList = getMessagingDetailsActionRequestHelper(clientId);

        Test.startTest();
            GetMessagingDetailsAction.throwException = true;
            List<GetMessagingDetailsAction.ActionResult> resultsList = GetMessagingDetailsAction.getMessagingDetails(inputList);
        Test.stopTest();

        System.assertEquals(1, [SELECT Count() FROM Golfbreaks__PlatformLog__c]); // Confirm Failures Has Happened
    }

    private static List<GetMessagingDetailsAction.ActionRequest> getMessagingDetailsActionRequestHelper(Set<Id> accIds){

        List<Account> accList = [SELECT Id, (SELECT Id, TECH_Opportunity__c FROM Bookings__r),(SELECT Id,IsClosed FROM Opportunities ORDER BY LastModifiedDate DESC)FROM Account WHERE Id =:accIds];
        List<GetMessagingDetailsAction.ActionRequest> inputList = new List<GetMessagingDetailsAction.ActionRequest>();
        for(Account acc : accList){
            GetMessagingDetailsAction.ActionRequest input = new GetMessagingDetailsAction.ActionRequest();
            input.accountId = acc.Id;
            inputList.add(input);
        }
        return inputList; 
    }

}