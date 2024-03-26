/*
Name:  InsightsChannelBrokerTest.cls
Copyright © 2020  Golfbreaks
======================================================
======================================================
Purpose: Test Suite for Insights Channel Broker
------
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2020-11-02  Initial development.
1.1  J Radcliffe   2020-11-18  Webhook will no longer include Visitor JSON - Amendments to support new request content
1.2  Mark Cane&    2021-10-16  Unit test updates following broker class changes.
*/
@isTest
public with sharing class InsightsChannelBrokerTest {

    //@TestVisible public static String jsonString = '{"transactionId":"f45133f9-5945-4590-ac8d-c621241cf3d5","live":false,"visitor":{"audiences":["Enquirer","Booker","Made a UK Booking"],"badges":["Identifiable Client","Recent UK Booker","Recent UK Enquirer","Recent Booker"],"metric_sets":{"Interests: Tournaments (30 days)":{"":2},"Interests: Countries (30 days)":{"England":2,"Turkey":8,"Ireland":4}},"secondary_ids":{"5163":"lisaplummer24@gmail.com","5159":"1471996","5161":"{{!AccountId}}"},"last_visit_id":"db7e0aeca5495a2735d92c364b65a76c84a21e1fdd17f219af03232cabbdcc6c"}}';
    @TestVisible public static String jsonString = '{"tealium_id":"017584bca414002145b35b2a740203073003d06b00bd0","salesforce_id":"0013G000006yT3dQAE"}';

    // UI flow.

    @isTest static void processDataRequest(){

        User u;

        System.runAs(new User(Id=UserInfo.getUserId())){
            UserTestHelper.setupOrgSettings();
            u = UserTestHelper.createStandardUsers(1, 'Flash', 'Gordon')[0];
        }

        System.runAs(u){

            Account acc = new Account(Name='Test Account',TealiumId__c='0173bf6b01f900033ce66b7a7');
            insert acc;
            jsonString = jsonString.replace('{{!AccountId}}', acc.Id);

            String responseString;
            test.startTest();
                InsightsChannelBroker icb = new InsightsChannelBroker();
                icb.testJSONResponse = jsonString;//Set Response from simulated DET Callout
                responseString = icb.processDataRequest(acc.Id, acc.TealiumId__c, 'TestDataEvent');
            test.stopTest();

            system.assertEquals(jsonString, responseString);
        }
    }

    // Callback flow.
  
    @isTest static void handleRequestTestSuccess(){

        RestRequest req = new RestRequest();
        req.requestURI = 'https://golfbreaks.my.salesforce.com/services/apexrest/CRM/v1.0/Webhook/tealium-visitor/';
        req.requestBody = Blob.valueOf(jsonString);
        req.httpMethod = 'POST';

        RestResponse res = new RestResponse();

        Webhook__mdt wh = [Select Id, SuccessResponseStatusCode__c, ErrorResponseStatusCode__c From Webhook__mdt Where PathIdentifier__c = 'tealium-visitor'];

        test.startTest();
            InsightsChannelBroker icb = new InsightsChannelBroker();
            icb.testSuccess = true;//Simulate Success Response from package
            icb.handleRequest(req,res,wh);
        test.stopTest();

        system.assertEquals('Tealium Data Refreshed Successfully', res.responseBody.toString());
        system.assertEquals(wh.SuccessResponseStatusCode__c, res.statusCode);
    }

    @isTest static void handleRequestTestFailUnidentifiableAccountId(){

        jsonString = '{"tealium_id":"017584bca414002145b35b2a740203073003d06b00bd0"}';
        
        RestRequest req = new RestRequest();
        req.requestURI = 'https://golfbreaks.my.salesforce.com/services/apexrest/CRM/v1.0/Webhook/tealium-visitor/';
        req.requestBody = Blob.valueOf(jsonString);
        req.httpMethod = 'POST';

        RestResponse res = new RestResponse();

        Webhook__mdt wh = [Select Id, SuccessResponseStatusCode__c, ErrorResponseStatusCode__c From Webhook__mdt Where PathIdentifier__c = 'tealium-visitor'];

        test.startTest();
            InsightsChannelBroker icb = new InsightsChannelBroker();
            icb.handleRequest(req,res,wh);
        test.stopTest();

        system.assertEquals('Request Handling Failure > Could not retrieve account id from JSON Request', res.responseBody.toString());
        system.assertEquals(wh.ErrorResponseStatusCode__c, res.statusCode);
    }

    @isTest static void handleRequestTestFailUnidentifiableTealiumId(){

        jsonString = '{"salesforce_id":"0013G000006yT3dQAE"}';
        
        RestRequest req = new RestRequest();
        req.requestURI = 'https://golfbreaks.my.salesforce.com/services/apexrest/CRM/v1.0/Webhook/tealium-visitor/';
        req.requestBody = Blob.valueOf(jsonString);
        req.httpMethod = 'POST';

        RestResponse res = new RestResponse();

        Webhook__mdt wh = [Select Id, SuccessResponseStatusCode__c, ErrorResponseStatusCode__c From Webhook__mdt Where PathIdentifier__c = 'tealium-visitor'];

        test.startTest();
            InsightsChannelBroker icb = new InsightsChannelBroker();
            icb.handleRequest(req,res,wh);
        test.stopTest();

        system.assertEquals('Request Handling Failure > Could not retrieve tracking id from JSON Request', res.responseBody.toString());
        system.assertEquals(wh.ErrorResponseStatusCode__c, res.statusCode);
    }

    @isTest static void handleRequestTestFailPackageError(){
        
        RestRequest req = new RestRequest();
        req.requestURI = 'https://golfbreaks.my.salesforce.com/services/apexrest/CRM/v1.0/Webhook/tealium-visitor/';
        req.requestBody = Blob.valueOf(jsonString);
        req.httpMethod = 'POST';

        RestResponse res = new RestResponse();

        Webhook__mdt wh = [Select Id, SuccessResponseStatusCode__c, ErrorResponseStatusCode__c From Webhook__mdt Where PathIdentifier__c = 'tealium-visitor'];

        test.startTest();
            InsightsChannelBroker icb = new InsightsChannelBroker();
            icb.testSuccess = false;//Simulate Fail Response from package
            icb.handleRequest(req,res,wh);
        test.stopTest();

        system.assertEquals('Request Handling Failure > Unable to refresh Tealium Data', res.responseBody.toString());
        system.assertEquals(wh.ErrorResponseStatusCode__c, res.statusCode);

    }

    @isTest static void handleOutboundResponseTestSuccess(){//1.2+

        User u;

        System.runAs(new User(Id=UserInfo.getUserId())){
            UserTestHelper.setupOrgSettings();
            u = UserTestHelper.createStandardUsers(1, 'Flash', 'Gordon')[0];
        }

        System.runAs(u){

            Account acc = new Account(Name='Test Account',TealiumId__c='1c2010ba-acb1-4303-a716-a01c0ef79a07');
            insert acc;

            String b = '{'+
                    '"transactionId": "1c2010ba-acb1-4303-a716-a01c0ef79a07",'+
                    '"live": false,'+
                    '"visitor": {'+
                        '"metrics": {'+
                        '   "European Booking - Total": 0.0,'+
                        '   "Domestic Booking - Total": 16.0,'+
                        '   "Lifetime visit count": 1.0'+
                        '},'+
                        '"audiences": ['+
                        '    "Enquirer",'+
                        '    "Booker"'+
                        '],'+
                        '"badges": ['+
                        '    "Identifiable Client",'+
                        '    "Recent UK Booker",'+
                        '    "Recent UK Enquirer",'+
                        '    "Frequent Visitor"'+
                        '],'+
                        '"metric_sets": {'+
                        '    "Interests: Tournaments (30 days)": {'+
                        '        "": 2'+
                        '    },'+
                        '    "Lifetime devices used": {'+
                        '        "iPhone": 1'+
                        '    },'+
                        '    "Interests: Countries (30 days)": {'+
                        '        "": 1,'+
                        '        "Turkey": 3,'+
                        '        "England": 6'+
                        '    }'+
                        '},'+
                        '"secondary_ids": {'+
                        '    "5163": "lisaplummer24@gmail.com",'+
                        '    "5159": "1471996",'+
                        '    "Account Salesforce Id": "'+acc.Id+'"'+
                        '},'+
                        '"last_visit_id": "db7e0aeca5495a2735d92c364b65a76c84a21e1fdd17f219af03232cabbdcc6c"'+
                    '}'+
                '}';

            HttpResponse res = new HttpResponse();
            res.setBody(b);
            res.setStatusCode(200);

            test.startTest();
                System.assert( InsightsChannelBroker.handleOutboundResponse(res) );
            test.stopTest();
        }
    }
}