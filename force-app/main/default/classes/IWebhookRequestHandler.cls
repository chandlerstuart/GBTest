/*
Name:  IWebhookRequestHandler.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Interface class - provides abstracted pluggable interface for request handling logic. 

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-12-23  Initial development.
1.1  J Radcliffe   2020-03-19  Pass webhook into handleRequest method
*/
global interface IWebhookRequestHandler {
    void handleRequest(RestRequest req, RestResponse res, Webhook__mdt wh);
}