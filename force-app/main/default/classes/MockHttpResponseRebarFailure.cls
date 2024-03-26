/*
Name:  MockHttpResponseRebarFailure.cls
======================================================
======================================================
Purpose:
-------
Returns a failure status code. Used for testing 
integration failures

======================================================
======================================================
History
------- 
Ver. Author           Date        Detail
1.0  James Radcliffe  05/06/2018  Initial Development.
*/
@isTest
global class MockHttpResponseRebarFailure implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"foo":"bar"}');
        res.setStatusCode(400);
        return res;
    }
}