/*
Name:  ActOnItWebhookRequestHandlerTest.cls
======================================================
======================================================
Purpose: Test Suite for ActOnItWebhookRequestHandler.cls
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2020-11-23  Initial development.
*/
@isTest
public with sharing class ActOnItWebhookRequestHandlerTest {

    @TestVisible public static String jsonString = '{"salesforce_id":"{{!AccountId}}","tealium_id":"017d05b6730000191ad542decea100078011e07000547"}';

    @testSetup static void createTestData(){
        //Activate the ActOnIt App
        insert new ActOnIt__ActOnItSettings__c(ActOnIt__IsActive__c=true);

        //Create Message Type
        insert new ActOnIt__MessageType__c(Name='TestMessageType',ActOnIt__DeveloperName__c=ActOnItWebhookRequestHandler.webVisitMessageType,ActOnIt__IconType__c='Utility',ActOnIt__MessageIcon__c='Test');

        //Create Account
        Account acc = AP23_TestDataFactory.createPersonAccount(1,true)[0];
        insert acc;
        //Create Active Opp assigned to running user
        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, 'New', acc)[0];
        opp.OwnerId = UserInfo.getUserId();
        opp.CreatedDate = System.now().addMinutes(-5);
        insert opp;
    }

    @isTest static void handleRequestTestSuccessOnline(){

        Account acc = [Select Id From Account];
        jsonString = jsonString.replace('{{!AccountId}}', acc.Id);

        RestRequest req = new RestRequest();
        req.requestURI = 'https://golfbreaks.my.salesforce.com/services/apexrest/CRM/v1.0/Webhook/tealium-visitor-aoi/';
        req.requestBody = Blob.valueOf(jsonString);
        req.httpMethod = 'POST';

        RestResponse res = new RestResponse();

        Webhook__mdt wh = [Select Id, SuccessResponseStatusCode__c, ErrorResponseStatusCode__c, SuccessResponseFormatFields__c From Webhook__mdt Where PathIdentifier__c = 'tealium-visitor-aoi'];

        String responseString;
        test.startTest();
            ActOnItWebhookRequestHandler aoiHandler = new ActOnItWebhookRequestHandler();
            ActOnItWebhookRequestHandler.isAvailabilityCheckSuccessful = true;
            aoiHandler.handleRequest(req,res,wh);
        test.stopTest();

        system.assertEquals('Message successfully passed data validation', res.responseBody.toString());
        system.assertEquals(wh.SuccessResponseStatusCode__c, res.statusCode);
    }

    @isTest static void handleRequestTestSuccessNotOnline(){

        Account acc = [Select Id From Account];
        jsonString = jsonString.replace('{{!AccountId}}', acc.Id);

        RestRequest req = new RestRequest();
        req.requestURI = 'https://golfbreaks.my.salesforce.com/services/apexrest/CRM/v1.0/Webhook/tealium-visitor-aoi/';
        req.requestBody = Blob.valueOf(jsonString);
        req.httpMethod = 'POST';

        RestResponse res = new RestResponse();

        Webhook__mdt wh = [Select Id, SuccessResponseStatusCode__c, ErrorResponseStatusCode__c, SuccessResponseFormatFields__c From Webhook__mdt Where PathIdentifier__c = 'tealium-visitor-aoi'];

        String responseString;
        test.startTest();
            ActOnItWebhookRequestHandler aoiHandler = new ActOnItWebhookRequestHandler();
            ActOnItWebhookRequestHandler.isAvailabilityCheckSuccessful = true;
            ActOnItWebhookRequestHandler.testAvailabilitySuccessResponse = '{"users":0}';
            aoiHandler.handleRequest(req,res,wh);
        test.stopTest();

        system.assertEquals('Success. Client is no longer online', res.responseBody.toString());
        system.assertEquals(wh.SuccessResponseStatusCode__c, res.statusCode);
        
    }

    @isTest static void handleRequestTestFailureBadRequest(){

        Account acc = [Select Id From Account];
        jsonString = jsonString.replace('{{!AccountId}}', acc.Id);
        jsonString = jsonString.replace('salesforce_id','SFID');//Invalidate expected JSON

        RestRequest req = new RestRequest();
        req.requestURI = 'https://golfbreaks.my.salesforce.com/services/apexrest/CRM/v1.0/Webhook/tealium-visitor-aoi/';
        req.requestBody = Blob.valueOf(jsonString);
        req.httpMethod = 'POST';

        RestResponse res = new RestResponse();

        Webhook__mdt wh = [Select Id, SuccessResponseStatusCode__c, ErrorResponseStatusCode__c, SuccessResponseFormatFields__c From Webhook__mdt Where PathIdentifier__c = 'tealium-visitor-aoi'];

        String responseString;
        test.startTest();
            ActOnItWebhookRequestHandler aoiHandler = new ActOnItWebhookRequestHandler();
            aoiHandler.handleRequest(req,res,wh);
        test.stopTest();

        system.assertEquals('Request Handling Failure > Could not retrieve Account Id from JSON Request', res.responseBody.toString());
        system.assertEquals(wh.ErrorResponseStatusCode__c, res.statusCode);

    }

    @isTest static void handleRequestTestFailureGetAccount(){

        Account acc = [Select Id From Account];
        Id accId = acc.Id;
        jsonString = jsonString.replace('{{!AccountId}}', accId);

        delete acc;//Remove Account from Database

        RestRequest req = new RestRequest();
        req.requestURI = 'https://golfbreaks.my.salesforce.com/services/apexrest/CRM/v1.0/Webhook/tealium-visitor-aoi/';
        req.requestBody = Blob.valueOf(jsonString);
        req.httpMethod = 'POST';

        RestResponse res = new RestResponse();

        Webhook__mdt wh = [Select Id, SuccessResponseStatusCode__c, ErrorResponseStatusCode__c, SuccessResponseFormatFields__c From Webhook__mdt Where PathIdentifier__c = 'tealium-visitor-aoi'];

        String responseString;
        test.startTest();
            ActOnItWebhookRequestHandler aoiHandler = new ActOnItWebhookRequestHandler();
            aoiHandler.handleRequest(req,res,wh);
        test.stopTest();

        system.assertEquals('Request Handling Failure > Unrecognised Client Account (Id:'+accId+')', res.responseBody.toString());
        system.assertEquals(wh.ErrorResponseStatusCode__c, res.statusCode);
    }

    @isTest static void handleRequestTestFailureCannotVerifyAvailability(){

        Account acc = [Select Id From Account];
        Id accId = acc.Id;
        jsonString = jsonString.replace('{{!AccountId}}', accId);

        RestRequest req = new RestRequest();
        req.requestURI = 'https://golfbreaks.my.salesforce.com/services/apexrest/CRM/v1.0/Webhook/tealium-visitor-aoi/';
        req.requestBody = Blob.valueOf(jsonString);
        req.httpMethod = 'POST';

        RestResponse res = new RestResponse();

        Webhook__mdt wh = [Select Id, SuccessResponseStatusCode__c, ErrorResponseStatusCode__c, SuccessResponseFormatFields__c From Webhook__mdt Where PathIdentifier__c = 'tealium-visitor-aoi'];

        String responseString;
        test.startTest();
            ActOnItWebhookRequestHandler aoiHandler = new ActOnItWebhookRequestHandler();
            ActOnItWebhookRequestHandler.isAvailabilityCheckSuccessful = false;
            aoiHandler.handleRequest(req,res,wh);
        test.stopTest();

        system.assertEquals('Request Handling Failure > Unable to verify account is online (Id:'+accId+')', res.responseBody.toString());
        system.assertEquals(wh.ErrorResponseStatusCode__c, res.statusCode);

    }
}