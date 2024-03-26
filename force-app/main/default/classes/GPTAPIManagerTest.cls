/*
Name:  GPTAPIManagerTest
======================================================
======================================================
Purpose:
-------
Test Suite for GPTAPIManager.cls
======================================================
======================================================

Coverage:
GPTAPIManager.cls - 100%

History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2023-10-10  Initial development.
*/
@isTest
public with sharing class GPTAPIManagerTest {
    

    @isTest static void testDeIdentifyContent() {

        // Test input string containing various personal details
        String testContent = 'Here are some personal details: ' +
            'Email: john_doe123@gmail.com or alice.smith@example.co.uk ' +
            'Phone (UK): 123-456-7890 or 123.456.7890 or 123 456 7890 ' +
            'Phone (USA): (123) 456-7890 or 123-456-7890 or 123.456-7890 or 456-7890 ' +
            'Account Number: 1234567890123 or 9876543210987654 ' +
            'US Postcode: 90210 or 12345 or 54321 ' +
            'UK Postcode: RG12 5RP or EH12 6HN ' +
            'Credit Card: 1234-1234-1234-1234 or 9876 5432 1098 7654 ';

        // Expected output with personal details replaced
        String expectedOutput = 'Here are some personal details: ' +
            'Email: ******@******.*** or ******@******.*** ' +
            'Phone (UK): ***-***-**** or ***-***-**** or ***-***-**** ' +
            'Phone (USA): ***-***-**** or ***-***-**** or ***-***-**** or***-***-**** ' +
            'Account Number:***-***-****890123 or***-***-*******-***-****54 ' +
            'US Postcode: ****** or ****** or ****** ' +
            'UK Postcode: **** *** or **** *** ' +
            'Credit Card: 1***-***-****-1***-***-**** or 9***-***-**** 1***-***-**** ';

        Test.startTest();
            // Call the de_identifyContent method
            String result = GPTAPIManager.de_identifyContent(testContent);
        Test.stopTest();

        // Assert that the result matches the expected output
        System.assertEquals(expectedOutput, result);
    }

    // Define a mock callout class to simulate the HTTP callout
    public class MockHttpResponseSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response to simulate the behavior of the external service
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"id": "123", "choices": [{"index": 0, "message": {"role": "Assistant", "content": "Why did the chicken cross the road?"}}]}');
            return res;
        }
    }

    // Define a mock callout class to simulate the HTTP callout
    public class MockHttpResponseFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response to simulate the behavior of the external service
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('Cannot process the request.');
            return res;
        }
    }

    // Test method for the askGPT method
    @isTest
    static void testAskGPTSuccess() {
        // Create test data
        List<GPTAPIManager.GPTMessage> messages = new List<GPTAPIManager.GPTMessage>();
        GPTAPIManager.GPTMessage message = new GPTAPIManager.GPTMessage();
        message.role = 'User';
        message.content = 'Tell me a joke';
        messages.add(message);

        // Set up the mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());

        Test.startTest();
        // Call the askGPT method
        List<GPTAPIManager.GPTMessage> response = GPTAPIManager.askGPT(messages,false);
        Test.stopTest();

        // Verify the response
        System.assertEquals(2, response.size());
        System.assertEquals('Assistant', response[1].role);
        System.assertEquals('Why did the chicken cross the road?', response[1].content);
    }

    @isTest
    static void testAskGPTFailure() {
        // Create test data
        List<GPTAPIManager.GPTMessage> messages = new List<GPTAPIManager.GPTMessage>();
        GPTAPIManager.GPTMessage message = new GPTAPIManager.GPTMessage();
        message.role = 'User';
        message.content = 'Tell me a joke';
        messages.add(message);

        // Set up the mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseFailure());

        // Call the askGPT method
        List<GPTAPIManager.GPTMessage> response;
        Boolean errorThrown = false;
        try{
            Test.startTest();
            response = GPTAPIManager.askGPT(messages,false);
            Test.stopTest();
        }catch(Exception e){
            errorThrown = true;
            system.assertEquals(true, e.getMessage().contains('whoops! There was a failure: [400] Cannot process the request.'));
        }
        System.assertEquals(true, errorThrown);

        // Verify the response
        System.assertEquals(null, response);
    }
}