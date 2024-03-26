/*
Name:  CallTrackingUtilityControllerTest.cls
======================================================
======================================================
Purpose: Test Suite for Apex CallTrackingUtilityController.cls 

-------
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-05-29  Initial Development.
*/
@isTest
public with sharing class CallTrackingUtilityControllerTest {

    public static String agentStatusJSON = '{"meta":{"page":1,"count":173,"pageCount":1,"totalCount":173},"items":[{"agentId":"286","presence":{"since":"2022-05-26T15:29:40.000Z","name":"Ready","description":"Ready","eligibleForRouting":true},"workload":{"since":"2022-05-26T15:32:17.277Z","calls":1,"semiLive":0,"nonLive":0},"interaction":[{"guid":"018100ff-40a6-c03c-82d0-254a08350cb0","channelGuid":null,"since":"2022-05-26T15:29:40.000Z","medium":"Phone","mediumManager":"VCC","direction":"Outbound","state":"Connected","reason":null}]}]}';
    public static String callDetailJSON = '{"tealiumId":"","dialledNumber":"+441873666222","callerId":"+44794932323","direction":"inbound"}';

    @TestSetup static void createTestData(){

        insert new ActOnIt__ActOnItSettings__c(ActOnIt__IsActive__c=true);

        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        acc.FirstName = 'Bobby';
        acc.LastName = 'Brown';
        acc.PersonMobilePhone = '+44794932323';
        insert acc;

        Opportunity opp = AP23_TestDataFactory.createOpportunity(1,'New',acc)[0];
        insert opp;

        ActOnIt__MessageType__c type = new ActOnIt__MessageType__c();
        type.Name = 'Test Message Type';
        type.ActOnIt__DefaultMessage__c = 'This is your default \'Act On It\' Alert message!';
        type.ActOnIt__IconType__c = 'standard';
        type.ActOnIt__MessageIcon__c = 'standard:opportunity';
        type.ActOnIt__MessageIconColour__c = 'red';
        type.ActOnIt__SenderIsRunnningUser__c = true;
        type.ActOnIt__IsActive__c = true;
        type.ActOnIt__DeveloperName__c = 'Test_Message_Type';
        insert type;
    }

    //Test Success
    @isTest static void testSuccess(){

        ActOnIt__MessageType__c type = [Select Id, ActOnIt__DeveloperName__c From ActOnIt__MessageType__c];

        CallTrackingUtilityController.TrackingData response;
        test.startTest();
            CallTrackingUtilityController.currentTimeOverride = DateTime.newInstanceGMT(2022,05,26,15,29,55);//15 seconds after connected call time
            CallTrackingUtilityController.testAgentStatusJSON = agentStatusJSON;//Callout 1 response
            CallTrackingUtilityController.testCallDetailJSON = callDetailJSON;//Callout 2 response

            response = CallTrackingUtilityController.executeCallTracking(null, 10, 15, type.ActOnIt__DeveloperName__c, null);

        test.stopTest();

        system.assertEquals('Message Published',response.message);

    }

    //Test Minimum Connected Call Time
    @isTest static void testUnderMinimumConnectedCallTime(){

        ActOnIt__MessageType__c type = [Select Id, ActOnIt__DeveloperName__c From ActOnIt__MessageType__c];

        CallTrackingUtilityController.TrackingData response;
        test.startTest();
            CallTrackingUtilityController.currentTimeOverride = DateTime.newInstanceGMT(2022,05,26,15,29,45);//5 seconds after conected call time (less than the minimum (10))
            CallTrackingUtilityController.testAgentStatusJSON = agentStatusJSON;//Callout 1 response
            CallTrackingUtilityController.testCallDetailJSON = callDetailJSON;//Callout 2 response

            response = CallTrackingUtilityController.executeCallTracking(null, 10, 15, type.ActOnIt__DeveloperName__c, null);

        test.stopTest();

        system.assertEquals('Connected time is less than confgured minimum by 5 seconds',response.message);
        system.assertEquals(5,response.nextAttemptInSeconds);//Rescheduled for 5 seconds from now


    }

    //Test Not Yet Connected
    @isTest static void testNotYetConnected(){

        ActOnIt__MessageType__c type = [Select Id, ActOnIt__DeveloperName__c From ActOnIt__MessageType__c];

        CallTrackingUtilityController.TrackingData response;
        test.startTest();
            CallTrackingUtilityController.currentTimeOverride = DateTime.newInstanceGMT(2022,05,26,15,29,55);//15 seconds after connected call time
            CallTrackingUtilityController.testAgentStatusJSON = agentStatusJSON.replace('Connected','Ringing');//Callout 1 response
            CallTrackingUtilityController.testCallDetailJSON = callDetailJSON;//Callout 2 response

            response = CallTrackingUtilityController.executeCallTracking(null, 10, 15, type.ActOnIt__DeveloperName__c, null);

        test.stopTest();

        system.assertEquals('No connected call > Ringing',response.message);

    }
    
    //Test Unrecognised Account
    @isTest static void testUnrecognisedAccount(){ 

        ActOnIt__MessageType__c type = [Select Id, ActOnIt__DeveloperName__c From ActOnIt__MessageType__c];

        delete [Select Id From Account];

        CallTrackingUtilityController.TrackingData response;
        test.startTest();
            CallTrackingUtilityController.currentTimeOverride = DateTime.newInstanceGMT(2022,05,26,15,29,55);//15 seconds after connected call time
            CallTrackingUtilityController.testAgentStatusJSON = agentStatusJSON;//Callout 1 response
            CallTrackingUtilityController.testCallDetailJSON = callDetailJSON;//Callout 2 response

            response = CallTrackingUtilityController.executeCallTracking(null, 10, 15, type.ActOnIt__DeveloperName__c, null);

        test.stopTest();

        system.assertEquals('Phone number not recognised > +44794932323',response.message);

    }

    //Test Retry Method
    @isTest static void testRetryCustomerNumber(){

        ActOnIt__MessageType__c type = [Select Id, ActOnIt__DeveloperName__c From ActOnIt__MessageType__c];

        Opportunity opp = [Select Id From Opportunity];

        CallTrackingUtilityController.TrackingData response;
        test.startTest();
            response = CallTrackingUtilityController.retryPhoneNumber(null, '+44794932323', opp.Id , type.ActOnIt__DeveloperName__c, null);
        test.stopTest();

        system.assertEquals('Message Published',response.message);

    }

}