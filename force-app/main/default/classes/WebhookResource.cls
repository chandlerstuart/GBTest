/*
Name:  WebhookResource.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

ApexRest Resource for Webhook callback execution.

https://<INSTANCE>.salesforce.com/services/apexrest/CRM/v1.0/Webhook/

Sequence:
(i) Booking System calls Webhook to notify of data event (Customer Update, Enquiry Update & Customer Merge).
(iia) If Webhook Type = [Id Format] then parse url:

/[webhook path value]/[Id]

Map [webhook path value] to Webhook metadata record.
Invoke Data Event Type Action for [Callback Data Event Type].
Return response.

(iib) If Webhook Type = [Request Handler] then:

Instantiate Request Handler class and pass in request.
Return response.

Exemplar Webhooks:
(a) /CRM/v1.0/Webhook/customer-update/0017E000016LfUtQAK
Callback = /services/data/vXX.0/sobjects/Account/[Id]?fields=Name,Industry,...

(b) /CRM/v1.0/Webhook/enquiry-update/0067E000022LhUtUat
Callback = /services/data/vXX.0/sobjects/Opportunity/[Id]?fields=Name,Industry,...

(c) /CRM/v1.0/Webhook/customer-merge/[masterrecordid]?losingRecordIds=[sourcerecordids]
Callback = /services/data/vXX.0/sobjects/Account/[Id]?fields=Name,Industry,...

TODO :
[x] Unit tests (basic)
[x] Error messages

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-12-23  Initial development.
1.1  Mark Cane&    2019-12-27  Conversion to DET approach.
1.2  Mark Cane&    2020-01-08  Response codes and return state enhancements.
1.3  J Radcliffe   2020-04-27  Enhancement - Query Webhooks based on any path element
*/
@RestResource(urlMapping='/CRM/v1.0/Webhook/*')
global with sharing class WebhookResource {

    @HttpPost
    global static void doPost(){

        RestRequest req = RestContext.request;
        
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        //1. get the Webhook [Path Value] from the path.
        // -- Note the Webhook CMT Name field does not support hyphen characters, hence a Custom Field is used.

        List<String> pathElements = req.requestURI.split('/');
        //String pathValue = pathElements[pathElements.size()-2];//1.3-

        //2. if not exists or inactive return [UNKNOWN WEBHOOK] message.
        //if (String.isBlank(pathValue) || ([select count() from Webhook__mdt where PathIdentifier__c=:pathValue and IsActive__c=true and IsTest__c=:Test.isRunningTest()]==0)){//1.3-
        if (pathElements == null || pathElements.size() ==0 || ([select count() from Webhook__mdt where PathIdentifier__c In:pathElements and IsActive__c=true and IsTest__c=:Test.isRunningTest()]==0)){//1.3+
            res.statusCode = 400;//tbc.
            res.responseBody = Blob.valueOf('{ errorMessage : '+Label.Webhook_Validation_Error_Invalid_Webhook+'}');//1.2~.
        } else {
            
            //3. call manager class.
            //WebhookManager.processWebhook(pathValue, req, res);//1.3-
            WebhookManager.processWebhook(pathElements, req, res);//1.3+
        }
    }
}