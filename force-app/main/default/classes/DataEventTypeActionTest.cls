/*
Name: DataEventTypeActionTest.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Test suite for Data Event Type Action methods.

Coverage for classes below (target 85%):
DataEventTypeManager.cls : 42%	
DataEventTypeAction.cls : 90%	

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-08-19  Initial development.
1.1  Mark Cane&    2020-04-20  Added singleTestCase2.
1.2  Mark Cane&    2020-05-13  Added singleTestCase3.
1.3  Mark Cane&    2020-10-07  Added negativeTestCase2. Modified singleTestCase1 to test responseBody population for isSuccess=TRUE.
1.4  Mark Cane&    2020-11-07  Added singleTestCase4.
1.5  Mark Cane&    2020-11-09  Added singleTestCase5.
1.6  Mark Cane&    2021-07-02  Added singleTestCase6
1.7  J Radcliffe   2022-02-04  Added singleTestCase7
1.8  Mark Cane&    2022-11-09  Added singleTestCase8
*/
@isTest(SeeAllData=false)
public with sharing class DataEventTypeActionTest {
	/*
    Test cases:
        singleTestCase1 - ApexAction. Synchronous Request Type. All Conditions pass.
        singleTestCase2 - ApexAction. Opportunity Synchronous Request Type. Type formatting.
        singleTestCase3 - ApexAction. Case Synchronous Request Type. Polymorphic relationships.
        singleTestCase4 - ApexAction. Case Synchronous Request Type. Custom Authentication. No cached auth token.
        singleTestCase5 - ApexAction. Querystring parameters.
        singleTestCase6 - ApexAction. Synchronous Request Type. List response and IDataEventTypeResponseHandler2 response handler.
        singleTestCase7 - ApexAction. Synchronous Request Type. List response and IDataEventTypeResponseHandler3 response handler.
        singleTestCase8 - ApexAction. Request Body Format test (requestBodyFormat+Values).
        ..
        negativeTestCase1 - ApexAction. Synchronous Request Type. No active date event types.
        negativeTestCase2 - ApexAction. API Callout error.
	*/
	
    @testSetup static void setup(){}
    
    /* **/
    static testMethod void singleTestCase1() {    
        // Test case 1 : ApexAction. Synchronous Request Type. All Conditions pass.

        Account a = new Account(Name='Unit test');
        a.BillingCountry = 'Finland';
        insert a;

        DataEventTypeAction.DataEventTypeActionRequest detar = new DataEventTypeAction.DataEventTypeActionRequest('Account_Update_Sync_Test',a.Id);

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('singleTestCase1'));

        Test.startTest();
        List<DataEventTypeAction.DataEventTypeActionResult> detaResults = DataEventTypeAction.invokeDataEventType( new List<DataEventTypeAction.DataEventTypeActionRequest>{ detar });
        Test.stopTest();

        System.assertEquals(1,detaResults.size());

        for (DataEventTypeAction.DataEventTypeActionResult r : detaResults){ 
            System.assert(r.isSuccess);
            System.assertEquals('{ "SalesforceClientID":"001b000000qDVy6AAZ", "GolfbreaksClientID":"ClubhouseIdValue" }',r.responseBody);
        }
    }
    /* */  
    
    /* **/
    static testMethod void singleTestCase2() {    
        // Test case 2 : ApexAction. Opportunity Synchronous Request Type. Type formatting.

        Account a = new Account(Name='Unit test');
        a.BillingCountry = 'Finland';
        a.NumberOfEmployees = 99;
        insert a;

        Opportunity o = new Opportunity(Name='Unit Test', CloseDate=Date.today(), StageName=Opportunity.StageName.getDescribe().getPicklistValues()[0].getValue());
        o.AccountId = a.Id;
        insert o;

        DataEventTypeAction.DataEventTypeActionRequest detar = new DataEventTypeAction.DataEventTypeActionRequest('Opportunity_Retrieve_Sync_Test',o.Id);

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('singleTestCase2'));

        Test.startTest();
        List<DataEventTypeAction.DataEventTypeActionResult> detaResults = DataEventTypeAction.invokeDataEventType( new List<DataEventTypeAction.DataEventTypeActionRequest>{ detar });        
        Test.stopTest();

        System.assertEquals(1,detaResults.size());

        for (DataEventTypeAction.DataEventTypeActionResult r : detaResults){ System.assert(r.isSuccess); }

        //[Removed for release] System.debug(LoggingLevel.ERROR,'FINDME>DataEventTypeManager.lastRequestBody='+DataEventTypeManager.lastRequestBody);

        Datetime convertedDt = Datetime.newInstance(Date.today().year(), Date.today().month(), Date.today().day());

        System.assertEquals('{ "name":"Unit Test","closeDate":"'+convertedDt.format('yyyy-MM-dd')+'","numberOfEmployees":"99" }',DataEventTypeManager.lastRequestBody);
    }
    /* */    
    
    /* **/
    static testMethod void singleTestCase3() {    
        // Test case 3 : ApexAction. Case Synchronous Request Type. Polymorphic relationships.
        
        User u = new User();

        Id userProfileId = [select Id from Profile where Name = 'Standard User'].Id;

        System.runAs(new User(Id=UserInfo.getUserId())){
            u.username = 'user@unittesting.golfbreaks.com';
            u.email = 'user@unittesting.golfbreaks.com';
            u.FirstName = 'Test';
            u.LastName = 'User';         
            u.alias = 'test';
            u.languagelocalekey='en_US';
            u.localesidkey='en_US';
            u.timezonesidkey='Europe/London';//<-- force static timezone
            u.emailencodingkey='UTF-8';
            u.isactive = true;
            u.ProfileId = userProfileId;
            insert u;
        }

        Account a;
        Case c;
        System.runAs(u){   
            a = new Account(Name='Unit test');
            a.BillingCountry = 'Finland';
            a.NumberOfEmployees = 99;
            insert a;
     
            c = new Case(Subject='Unit Test', Status=Case.Status.getDescribe().getPicklistValues()[0].getValue());
            c.AccountId = a.Id;
            insert c;
        }

        DataEventTypeAction.DataEventTypeActionRequest detar = new DataEventTypeAction.DataEventTypeActionRequest('Case_Retrieve_Sync_Test',c.Id);

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('singleTestCase3'));

        Test.startTest();
        List<DataEventTypeAction.DataEventTypeActionResult> detaResults = DataEventTypeAction.invokeDataEventType( new List<DataEventTypeAction.DataEventTypeActionRequest>{ detar });        
        Test.stopTest();

        System.assertEquals(1,detaResults.size());

        for (DataEventTypeAction.DataEventTypeActionResult r : detaResults){ System.assert(r.isSuccess); }

        System.assertEquals('{ "subject":"Unit Test","numberOfEmployees":"99","timezone":"Europe/London" }',DataEventTypeManager.lastRequestBody);
        System.assertEquals('/Unit+Test+Europe%2FLondon',DataEventTypeManager.lastRequestEndpoint);
    }
    /* */  
    
    /* **/
    static testMethod void singleTestCase4() {    
        // Test case 4 : ApexAction. Case Synchronous Request Type. Custom Authentication. No cached auth token.
        
        User u = new User();

        Id userProfileId = [select Id from Profile where Name = 'Standard User'].Id;

        System.runAs(new User(Id=UserInfo.getUserId())){
            u.username = 'user@unittesting.golfbreaks.com';
            u.email = 'user@unittesting.golfbreaks.com';
            u.FirstName = 'Test';
            u.LastName = 'User';         
            u.alias = 'test';
            u.languagelocalekey='en_US';
            u.localesidkey='en_US';
            u.timezonesidkey='Europe/London';//<-- force static timezone
            u.emailencodingkey='UTF-8';
            u.isactive = true;
            u.ProfileId = userProfileId;
            insert u;
        }

        Account a;
        Case c;
        System.runAs(u){   
            a = new Account(Name='Unit test');
            a.BillingCountry = 'Finland';
            a.NumberOfEmployees = 99;
            insert a;
     
            c = new Case(Subject='Unit Test', Status=Case.Status.getDescribe().getPicklistValues()[0].getValue());
            c.AccountId = a.Id;
            insert c;
        }

        DataEventTypeAction.DataEventTypeActionRequest detar = new DataEventTypeAction.DataEventTypeActionRequest('Case_Retrieve_Custom_Auth_Sync_Test',c.Id);

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('singleTestCase4'));

        Test.startTest();
        List<DataEventTypeAction.DataEventTypeActionResult> detaResults = DataEventTypeAction.invokeDataEventType( new List<DataEventTypeAction.DataEventTypeActionRequest>{ detar });        
        Test.stopTest();

        System.assertEquals(1,detaResults.size());

        for (DataEventTypeAction.DataEventTypeActionResult r : detaResults){ System.assert(r.isSuccess); }

        System.assertEquals('{ "subject":"Unit Test","numberOfEmployees":"99","timezone":"Europe/London" }',DataEventTypeManager.lastRequestBody);
        System.assertEquals('/Unit+Test+Europe%2FLondon',DataEventTypeManager.lastRequestEndpoint);

        Cache.OrgPartition sifCacheOrgPartition = Cache.Org.getPartition('SIFCachePartition');
        if (sifCacheOrgPartition.getNumKeys()==0) return;

        DataEventType__mdt det = [select Id,DeveloperName from DataEventType__mdt where DeveloperName='Case_Retrieve_Custom_Auth_Sync_Test'];

        System.assert(sifCacheOrgPartition.getKeys().contains(det.Id));
        
        String fromCache = (String)sifCacheOrgPartition.get(det.Id);
        System.assertEquals('eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzUxMiJ9.eyJzdWIiOiJpbnRlZ3JhdGlvbnNAZ29sZmJyZWFrcy5jb20iLCJuYmYiOjE2MDQ3NTg3MDMsImlzcyI6Imh0dHBzOi8vYXBpLnRlYWxpdW1pcS5jb20iLCJleHAiOjE2MDQ3NjA1MDMsImlhdCI6MTYwNDc1ODcwM30.ct45J_3TqSh1-yHRi90srbRzmSYrg-vDr6AxFf8g1smpyb0pH1Z0oU4T7pLpiWrwnZNkVFR2ax4nz99vavhdLDrSkXGcSgpezMhoHkcmUPGF5g4Y9cKfkQAGh1yyJ1CECuvW9AsHx9Ve9QO5M12YdyOdBdn0cLyOOGISdAO_KlZ-xIhiBLqk_DLL2fNJcxgFqrZtMrlK5rP236vFTwik1mNN101FWUqasXfX4aFld5LDpEd3F60LH1iqIghyNlvVv1tmTMBVNElGW3UmsWo8p8_ZFa9lTPPVEJ4Nak22H-N9_deYaGL9BMcGQrNoszNZ7SvZEnlYBA5uf-KwdnqnTjGhHqxD4dN6OkfQXPxD41g2vuWKb78QhJK2oeEmKkkmgYO622q4Ug-A9dKvDFrfHoJQs3k133gNxr_7ysM6Zk_jzsHVdidTEyGAuFyaHNHEN1GrnHoAtLDkS1Ot9xBi2hNg6Mq0gJL6Gyx1NfBRaVggph28jOIi0rFfuQzHmG97C5n0RLfY2hB-7hHwYn8OI8VzVzsdkOGQlicuZaR1CIhxdDluWVAWe0kIObwA5YlZsD3gQHK7IZD3SnzydHTRh5WrVJU1REk1F6Hy3vzZwkElkDKJeW7g8XXv6099v5cMO-imI8aXlxWrAa1cHLGgoQwfyIAwujQKobA5fvKR6mp',fromCache);
    }
    /* */   
    
    /* **/
    static testMethod void singleTestCase5() {    
        // Test case 5 : ApexAction. Querystring parameters.

        Account a = new Account(Name='Unit test');
        a.BillingCountry = 'Finland';
        insert a;

        DataEventTypeAction.DataEventTypeActionRequest detar = new DataEventTypeAction.DataEventTypeActionRequest('Account_Update_Sync_Test',a.Id);
        detar.queryStringParameters = 'myparameter=this value';

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('singleTestCase1'));

        Test.startTest();
        List<DataEventTypeAction.DataEventTypeActionResult> detaResults = DataEventTypeAction.invokeDataEventType( new List<DataEventTypeAction.DataEventTypeActionRequest>{ detar });
        Test.stopTest();

        System.assertEquals(1,detaResults.size());

        for (DataEventTypeAction.DataEventTypeActionResult r : detaResults){ 
            System.assert(r.isSuccess);
            System.assertEquals('{ "SalesforceClientID":"001b000000qDVy6AAZ", "GolfbreaksClientID":"ClubhouseIdValue" }',r.responseBody);
        }

        //[Removed for release]System.debug(DataEventTypeManager.lastRequestEndpoint);
        System.assert(DataEventTypeManager.lastRequestEndpoint.endsWith('&myparameter=this+value'));
    }/* */    
    
    /* **/
    static testMethod void singleTestCase6() {    
        // Test case 6 : ApexAction. Synchronous Request Type. List response and IDataEventTypeResponseHandler2 response handler.

        Account a = new Account(Name='Unit test');
        a.BillingCountry = 'Finland';
        insert a;

        DataEventTypeAction.DataEventTypeActionRequest detar = new DataEventTypeAction.DataEventTypeActionRequest('Account_Update_Sync_List_Test',a.Id);

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('singleTestCase6'));

        Test.startTest();
        List<DataEventTypeAction.DataEventTypeActionResult> detaResults = DataEventTypeAction.invokeDataEventType( new List<DataEventTypeAction.DataEventTypeActionRequest>{ detar });
        Test.stopTest();

        System.assertEquals(1,detaResults.size());

        for (DataEventTypeAction.DataEventTypeActionResult r : detaResults){ 
            System.assert(r.isSuccess);
            System.assertEquals('[{"Title":"Country - Spain"},{"Title":"Destination - UK - Wales-South - Swansea"}]',r.responseBody);            
        }
    }/* */

    /* **/
    static testMethod void singleTestCase7() {    
        // Test case 7 : ApexAction. Synchronous Request Type. List response and IDataEventTypeResponseHandler3 response handler.

        Account a = new Account(Name='Unit test');
        a.BillingCountry = 'Finland';
        insert a;

        DataEventTypeAction.DataEventTypeActionRequest detar = new DataEventTypeAction.DataEventTypeActionRequest('Account_Update_Sync_List_Test',a.Id);

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('singleTestCase7'));

        Test.startTest();
        List<DataEventTypeAction.DataEventTypeActionResult> detaResults = DataEventTypeAction.invokeDataEventType( new List<DataEventTypeAction.DataEventTypeActionRequest>{ detar });
        Test.stopTest();

        System.assertEquals(1,detaResults.size());

        for (DataEventTypeAction.DataEventTypeActionResult r : detaResults){ 
            System.assert(r.isSuccess);
            System.assertEquals('[{"Title":"Country - Spain"},{"Title":"Destination - UK - Wales-South - Swansea"}]',r.responseBody);            
        }
    }/* */

    /* **/
    static testMethod void singleTestCase8() {    
        // Test case 8 : ApexAction. Request Body Format test (requestBodyFormat+Values).

        Account a = new Account(Name='Unit test');
        a.BillingCountry = 'Finland';
        insert a;

        DataEventTypeAction.DataEventTypeActionRequest detar = new DataEventTypeAction.DataEventTypeActionRequest('Account_Update_Sync_Test',a.Id);
        detar.requestBodyFormat = '{ "phoneNumber": "{0}", "accountId": "{1}", "message": "{2}", "locale": "{3}", "senderEmail": "{4}" }';
        detar.requestBodyFormatValues = '+447944888222|0010N00004y9mpVQAQ|Hello! Let’s have a conversation|en-gb|myemail@example.com';        

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('singleTestCase8'));

        Test.startTest();
        List<DataEventTypeAction.DataEventTypeActionResult> detaResults = DataEventTypeAction.invokeDataEventType( new List<DataEventTypeAction.DataEventTypeActionRequest>{ detar });
        Test.stopTest();

        System.debug(detar.requestBody);

        System.assertEquals('{ "phoneNumber": "+447944888222", "accountId": "0010N00004y9mpVQAQ", "message": "Hello! Let’s have a conversation", "locale": "en-gb", "senderEmail": "myemail@example.com" }',detar.requestBody);
    }/* */    

    /* **/
    static testMethod void negativeTestCase1() {    
        // Test case 1 : ApexAction. Synchronous Request Type. No active date event types.

        Account a = new Account(Name='Unit test');
        a.BillingCountry = 'Finland';
        insert a;

        DataEventTypeAction.DataEventTypeActionRequest detar = new DataEventTypeAction.DataEventTypeActionRequest('Account_Update_Sync_Inactive_Test',a.Id);

        Test.startTest();
        List<DataEventTypeAction.DataEventTypeActionResult> detaResults = DataEventTypeAction.invokeDataEventType( new List<DataEventTypeAction.DataEventTypeActionRequest>{ detar });
        Test.stopTest();

        System.assertEquals(1,detaResults.size());

        for (DataEventTypeAction.DataEventTypeActionResult r : detaResults){ System.assert(!r.isSuccess); }
    }
    /* */    

    /* **/
    static testMethod void negativeTestCase2() {    
        // Test case 2 : ApexAction. Synchronous Request Type. API callout error.

        Account a = new Account(Name='Unit test');
        a.BillingCountry = 'Finland';
        insert a;

        DataEventTypeAction.DataEventTypeActionRequest detar = new DataEventTypeAction.DataEventTypeActionRequest('Account_Update_Sync_Test',a.Id);

        Test.setMock(HttpCalloutMock.class, new HttpResponseMockImpl('negativeTestCase2'));

        Test.startTest();
        List<DataEventTypeAction.DataEventTypeActionResult> detaResults = DataEventTypeAction.invokeDataEventType( new List<DataEventTypeAction.DataEventTypeActionRequest>{ detar });
        Test.stopTest();

        System.assertEquals(1,detaResults.size());

        for (DataEventTypeAction.DataEventTypeActionResult r : detaResults){ 
            System.assert(!r.isSuccess);
            System.assertEquals('Validation error',r.responseBody);
            System.assertEquals('',r.errorMessage);
        }
    }
    /* */

    public class HttpResponseMockImpl implements HttpCalloutMock {
        private String responseBody;
        private Integer responseStatusCode;

        public HttpResponseMockImpl(String testCase){
            
            switch on testCase {
                when 'singleTestCase1' {
                    responseBody='{ "SalesforceClientID":"001b000000qDVy6AAZ", "GolfbreaksClientID":"ClubhouseIdValue" }';
                    responseStatusCode=200;
                }
                when 'singleTestCase2','singleTestCase3' {
                    responseBody='{ "SalesforceClientID":"001b000000qDVy6AAZ", "GolfbreaksClientID":"ClubhouseIdValue", "SalesforceEnquiryID":"unittest" }';
                    responseStatusCode=200;
                }
                when 'singleTestCase4' {//Auth token response.
                    responseBody='{"token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzUxMiJ9.eyJzdWIiOiJpbnRlZ3JhdGlvbnNAZ29sZmJyZWFrcy5jb20iLCJuYmYiOjE2MDQ3NTg3MDMsImlzcyI6Imh0dHBzOi8vYXBpLnRlYWxpdW1pcS5jb20iLCJleHAiOjE2MDQ3NjA1MDMsImlhdCI6MTYwNDc1ODcwM30.ct45J_3TqSh1-yHRi90srbRzmSYrg-vDr6AxFf8g1smpyb0pH1Z0oU4T7pLpiWrwnZNkVFR2ax4nz99vavhdLDrSkXGcSgpezMhoHkcmUPGF5g4Y9cKfkQAGh1yyJ1CECuvW9AsHx9Ve9QO5M12YdyOdBdn0cLyOOGISdAO_KlZ-xIhiBLqk_DLL2fNJcxgFqrZtMrlK5rP236vFTwik1mNN101FWUqasXfX4aFld5LDpEd3F60LH1iqIghyNlvVv1tmTMBVNElGW3UmsWo8p8_ZFa9lTPPVEJ4Nak22H-N9_deYaGL9BMcGQrNoszNZ7SvZEnlYBA5uf-KwdnqnTjGhHqxD4dN6OkfQXPxD41g2vuWKb78QhJK2oeEmKkkmgYO622q4Ug-A9dKvDFrfHoJQs3k133gNxr_7ysM6Zk_jzsHVdidTEyGAuFyaHNHEN1GrnHoAtLDkS1Ot9xBi2hNg6Mq0gJL6Gyx1NfBRaVggph28jOIi0rFfuQzHmG97C5n0RLfY2hB-7hHwYn8OI8VzVzsdkOGQlicuZaR1CIhxdDluWVAWe0kIObwA5YlZsD3gQHK7IZD3SnzydHTRh5WrVJU1REk1F6Hy3vzZwkElkDKJeW7g8XXv6099v5cMO-imI8aXlxWrAa1cHLGgoQwfyIAwujQKobA5fvKR6mp"}';                
                    responseStatusCode=200;
                }
                when 'singleTestCase6','singleTestCase7' {
                    responseBody='{ "data": { "all_location": { "items": [ { "title": "Country - Spain" },{ "title": "Destination - UK - Wales-South - Swansea" } ] } } }';                
                    responseStatusCode=200;
                }
                when 'singleTestCase8' {
                    responseBody='{ "SalesforceClientID":"001b000000qDVy6AAZ", "GolfbreaksClientID":"ClubhouseIdValue" }';
                    responseStatusCode=200;
                }
                when 'negativeTestCase2' {
                    responseBody='Validation error';
                    responseStatusCode=400;
                }
            }
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            res.setStatusCode(responseStatusCode);
            return res;
        }
    }

    public class TestDataEventTypeResponseHandler implements IDataEventTypeResponseHandler2 {
        public Boolean handleOutboundResponse(HttpResponse r, String reshapedResponseBody, Id outboundCalloutId){
            return true;
        }
    }

    public class TestDataEventTypeResponseHandler3 implements IDataEventTypeResponseHandler3 {
        public Boolean handleOutboundResponse(HttpResponse r, String reshapedResponseBody, Id outboundCalloutId, Set<Id> recordIds){
            return true;
        }
    }
}