/*
Name:  RebarHTTPCallout.cls
Copyright © 2014  Golf Breaks Offshore Team
======================================================
======================================================
Purpose:
-------
This class sends an outbound message to Goldbreaks API when Lead.EnquiryId__c == NULL
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Kim B.        2016-03-07  Initial development.
2.0  Bryanne P.    2016-04-01  Implemented the HTTP Request
3.0  Nicole DG     2016-04-01  Implemented the Lead Outbound Messaging logic. Updated Lead. Account__c and Lead. EnquiryId__c from HTTP Response Body
4.0  Bryanne P.    2016-04-08  Change the name of the class to WS01_RebarHTTPCallout
4.1  Bryanne P.    2016-04-08  Added error handling and called constants
5.0  Merari C.     2016-04-14  Refactored outboundMessageCreator to implement wrapper classes and to return response status
5.1  Merari C.     2016-04-15  Added Request Queue log of webservice
5.2  Simon M.      2016-10-24  Added callout to Custom Setting to store Request Timeout value
6.0  Simon M.      2016-12-01  We need to create a Client, not an Enquiry. As this functionality may be needed
                               in the future, we will update the 'outboundMessageCreator' method to accept an
                               argument of CLIENT or ENQUIRY and run the appropriate code                              
6.1  Simon M.      2016-12-08  Refactored method call to outputboundMessageCreator, so duplicate code is in one method
6.2  Simon M.      2016-07-07  New method outboundMessageCallerOpportunity - to callout to Clubhouse API using Opportunity instead of Lead
6.3  Simon M.      2017-07-13  New @future method to call to emailBreakpointsInvite, to be called from Account Trigger
6.4  Simon M.      2017-07-27  New outboundMessageCaller method to return UNSAVED Lead, to be called from a batch class for bulk CH Enquiry creation
6.5  Simon M.      2017-08-09  new method updateAccountManager that updates Account Manager (owner) of Enquiry in Clubhouse upon Lead Owner update
6.6  J Radcliffe   2018-08-23  Disable WIRE Triggers when updating the lead in response from the enquiry create call
6.7  J Radcliffe   2018-08-23  Disable WIRE Triggers when updating the lead in response to the Account Manager Update API call
6.8  J Radcliffe   2019-05-02  Wrapping legacy integrations with additional Phased Code Removal Settings
*/
global with sharing class WS01_RebarHTTPCallout
{
    public static String returnString;
    Webservice Static String outboundMessageCreator(String LeadId, String objectType){
        //2016-12-08 : SM : Call the re-factored method from a NON-Future context
        String callerString = outboundMessageCaller(leadId, objectType, false);
        system.debug('*** -- returnString from outboundMessageCaller = ' + returnString + ' -- ***');
        return returnString;
    }

    //@Future method to enable callouts from a trigger
    @future(callout=true)
    Webservice Static void outboundMessageCreatorFuture(String LeadId, String objectType){
        //2016-12-08 : SM : Call the re-factored method from a Future context
        String callerString = outboundMessageCaller(leadId, objectType, true);
        system.debug('*** -- returnString from outboundMessageCallerFuture = ' + returnString + ' -- ***');
        //NO RETURN TYPE FROM FUTURE METHOD
    }

    //2017-08-09 : SM : New method to updated AccountManager (owner) in Clubhouse - @future method due to be called from a trigger
    @future(callout=true)
    Webservice static void updateAccountManager(String leadId){
        HttpResponse response;
        Request_Queue__c requestQueueLog = new Request_Queue__c();
        boolean isError = false;
        Lead theLead;
        try {
            theLead = [SELECT Id, OwnerId, GolfbreaksEnquiryId__c, Integration_Error_Log__c FROM Lead WHERE Id =: LeadId LIMIT 1];
            
            Http http = new Http();    
            EnquiryClientResponseWrapper lstEnqClientResponseWrapper = new EnquiryClientResponseWrapper();
            requestQueueLog.Related_ID__c = theLead.id;
            requestQueueLog.SObject_Name__c = String.valueOf(theLead.id.getSobjectType());
            
            //Get timeout value from custom setting
            Http_Timeout__c httpTimeout = Http_Timeout__c.getInstance('Account Manager Change');

            //HTTP Request
            HttpRequest request = new HttpRequest();
            if (null != httpTimeout){
                //We have a value, so set the timeout
                system.debug('*** -- Setting Lead Convert timeout to ' + integer.valueOf((httpTimeout.Timeout_In_Seconds__c * 1000)) + ' -- ***');
                request.setTimeout(integer.valueOf((httpTimeout.Timeout_In_Seconds__c * 1000)));
            }//Else it will keep the default of ten seconds

            request.setMethod('POST');
            request.setEndpoint('callout:ClubhouseCredentials/api/AccountManager');
            request.setHeader('Content-Type', 'application/json');
            
            AccountManagerRequestWrapper accManagerRequestWrapper = LC05_OutboundMessageCreator.buildAccountManagerRequestWrapper(theLead.id, 'Lead',1);
            request.setBody(JSON.serialize(accManagerRequestWrapper));
            System.debug('JSON REQUEST: ' + JSON.serialize(accManagerRequestWrapper));
            
            requestQueueLog.Request_Payload__c = JSON.serialize(accManagerRequestWrapper);
            requestQueueLog.Processed_on_date__c = System.today();
            
            try{
                response = http.send(request);
                System.debug('JSON RESPONSE: ' + response.getBody());
                
                if(String.isNotBlank(response.getBody()) && APIUtility.setPositiveStatuses.contains( response.getStatusCode() )){
                    
                    // Set Status to "Success"
                    requestQueueLog.Request_Status__c = ApplicationConstant.REQUEST_QUEUE_STATUS_SUCCESS;
                    // Change the Record Type of Request Queue object to "Log"
                    requestQueueLog.RecordTypeId = ApplicationConstant.getRecordTypeId( ApplicationConstant.OBJECT_TYPE_REQUEST_QUEUE, ApplicationConstant.RECORD_TYPE_REQUEST_QUEUE_LOG );
                    
                    lstEnqClientResponseWrapper = (EnquiryClientResponseWrapper) JSON.deserialize( response.getBody(), EnquiryClientResponseWrapper.class );
                    returnString = response.getStatusCode() + ';' + lstEnqClientResponseWrapper.ClientStatus;
                }
                else{
                    lstEnqClientResponseWrapper = (EnquiryClientResponseWrapper) JSON.deserialize( response.getBody(), EnquiryClientResponseWrapper.class );
                    requestQueueLog.Retry__c = 0;
                    requestQueueLog.Request_Status__c = ApplicationConstant.REQUEST_QUEUE_STATUS_FAILED;
                    requestQueueLog.RecordTypeId = ApplicationConstant.getRecordTypeId( ApplicationConstant.OBJECT_TYPE_REQUEST_QUEUE, ApplicationConstant.RECORD_TYPE_REQUEST_QUEUE_LOG );
                    returnString = response.getStatusCode() + ';' + 'ERROR' + ';' + lstEnqClientResponseWrapper.Message;
                    isError = true;
                }
                
                requestQueueLog.Response_Message__c = response.toString();
                requestQueueLog.Response_Payload__c = response.getBody();
                requestQueueLog.Response_Status_code__c = String.ValueOf( response.getStatusCode() );
                
            }
            catch(Exception ex){
                String errormsg = ex.getMessage();
                System.debug('Callout error: ' + ex.getMessage());
            }
        }
        catch(DmlException e){ 
            String error = e.getMessage();
            System.debug('The following exception has occurred: ' + e.getMessage());
        }   
        
        insert requestQueueLog;
        if (isError){
            system.debug('*** -- isError -- ***');
            theLead.Integration_Error_Log__c = requestQueueLog.Id;
            //6.7 - Disable WIRE triggers when setting the Integration_Error_Log__c on the Lead
            system.debug('Disabling WIRE triggers for Update Account Manager response (lead update)');
            GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
            update theLead;
            system.debug('Re-enabling WIRE triggers following the Update Account Manager response (lead update)');
            GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
        }
        System.debug('>>>> returnString' + returnString);
    }

    //2017-07-13 : SM : New @future method, calling out to the emailBreakpointsInvite method, called from Account trigger
    //2017-07-14 : SM : COMMENTED OUT FOR PHASE 1
    /*
    @future(callout=true)
    Webservice static void emailBreakpointsInviteFuture(String accId){
        emailBreakpointsInvite(accId);
    }
    */
    
    //2016-12-01 : SM : emailBreakpointsInvite
    //Calls a Clubhouse API Method 'Client/Invite' to send email to Client via Clunhouse to invite them
    //to the Breakpoints scheme (currently called from button on Account layout
    Webservice Static boolean emailBreakpointsInvite(String accId){
        boolean returnVal = false;
        HttpResponse response;
        Request_Queue__c requestQueueLog = new Request_Queue__c();
        try{
            Account acc = [select Id, Golfbreaks_Person_Id__c, Breakpoints_Invite_Sent__c, Send_Breakpoints_Invite__c from Account where Id = :accId LIMIT 1];
            
            Http http = new Http();    
            requestQueueLog.Related_ID__c = acc.id;
            requestQueueLog.SObject_Name__c = String.valueOf(acc.id.getSobjectType());
            
            //Get timeout value from custom setting
            Http_Timeout__c httpTimeout = Http_Timeout__c.getInstance('Breakpoints Invite');

            //HTTP Request
            HttpRequest request = new HttpRequest();
            EnquiryClientResponseWrapper lstEnqClientResponseWrapper = new EnquiryClientResponseWrapper();
            if (null != httpTimeout){
                //We have a value, so set the timeout
                system.debug('*** -- Setting Lead Convert timeout to ' + integer.valueOf((httpTimeout.Timeout_In_Seconds__c * 1000)) + ' -- ***');
                request.setTimeout(integer.valueOf((httpTimeout.Timeout_In_Seconds__c * 1000)));
            }//Else it will keep the default of ten seconds

            request.setMethod('GET');
            String endPoint = 'callout:ClubhouseCredentials/api/Client/Invite?';
            endPoint += 'golfbreaksClientID='+acc.Golfbreaks_Person_Id__c;
            endPoint += '&salesforceClientID='+acc.Id;
            //request.setEndpoint('callout:ClubhouseCredentials/api/Client/Invite?golfbreaksClientID='+acc.MemberNumber__c);
            request.setEndpoint(endPoint);
            
            //request.setHeader('Content-Type', 'application/json');
            
            requestQueueLog.Request_Payload__c = endPoint;
            requestQueueLog.Processed_on_date__c = System.today();
            
            try{
                response = http.send(request);
                System.debug('JSON RESPONSE: ' + response.getBody());
                
                if(String.isNotBlank(response.getBody()) && APIUtility.setPositiveStatuses.contains( response.getStatusCode() )){
                    //THIS SHOULD BE SET TO THE VALUE FROM THE RESPONSE
                    returnVal = true;
                    // Set Status to "Success"
                    requestQueueLog.Request_Status__c = ApplicationConstant.REQUEST_QUEUE_STATUS_SUCCESS;
                    // Change the Record Type of Request Queue object to "Log"
                    requestQueueLog.RecordTypeId = ApplicationConstant.getRecordTypeId( ApplicationConstant.OBJECT_TYPE_REQUEST_QUEUE, ApplicationConstant.RECORD_TYPE_REQUEST_QUEUE_LOG );
                    
                    acc.Breakpoints_Invite_Sent__c = returnVal;
                    acc.Send_Breakpoints_Invite__c = FALSE;
                    
                    update acc;
                }
                else{
                    lstEnqClientResponseWrapper = (EnquiryClientResponseWrapper) JSON.deserialize( response.getBody(), EnquiryClientResponseWrapper.class );
                    requestQueueLog.Retry__c = 0;
                    requestQueueLog.Request_Status__c = ApplicationConstant.REQUEST_QUEUE_STATUS_FAILED;
                    requestQueueLog.RecordTypeId = ApplicationConstant.getRecordTypeId( ApplicationConstant.OBJECT_TYPE_REQUEST_QUEUE, ApplicationConstant.RECORD_TYPE_REQUEST_QUEUE_LOG );
                    returnString = response.getStatusCode() + ';' + 'ERROR' + ';' + lstEnqClientResponseWrapper.Message;
                }
                
                requestQueueLog.Response_Message__c = response.toString();
                requestQueueLog.Response_Payload__c = response.getBody();
                requestQueueLog.Response_Status_code__c = String.ValueOf( response.getStatusCode() );
                
            }
            catch(Exception ex){
                String errormsg = ex.getMessage();
                System.debug('Callout error: ' + ex.getMessage());
            }            
        }
        catch(DmlException e){ 
            String error = e.getMessage();
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        insert requestQueueLog;
        
        System.debug('>>>> returnVal ' + returnVal);
        return returnVal;
    }
    
    //Helper method to create the outbound message - called from either in-transaction or @future
    private static String outboundMessageCaller(String LeadId, String objectType, boolean isFuture){
        HttpResponse response;
        Request_Queue__c requestQueueLog = new Request_Queue__c();
        boolean isError = false;
        Lead theLead;
        try {
            theLead = [SELECT Id, Account__c, GolfbreaksEnquiryId__c, Integration_Error_Log__c FROM Lead WHERE Id =: LeadId LIMIT 1];
            
            Http http = new Http();    
            EnquiryClientResponseWrapper lstEnqClientResponseWrapper = new EnquiryClientResponseWrapper();
            requestQueueLog.Related_ID__c = theLead.id;
            requestQueueLog.SObject_Name__c = String.valueOf(theLead.id.getSobjectType());
            
            //Get timeout value from custom setting
            Http_Timeout__c httpTimeout = Http_Timeout__c.getInstance('Lead Convert');

            //HTTP Request
            HttpRequest request = new HttpRequest();
            if (null != httpTimeout){
                //We have a value, so set the timeout
                system.debug('*** -- Setting Lead Convert timeout to ' + integer.valueOf((httpTimeout.Timeout_In_Seconds__c * 1000)) + ' -- ***');
                request.setTimeout(integer.valueOf((httpTimeout.Timeout_In_Seconds__c * 1000)));
            }//Else it will keep the default of ten seconds

            request.setMethod('POST');
            //2016-12-01 : SM : Determine the API URL to use based on objectType in the method signature
            if ('CLIENT'.equalsIgnoreCase(objectType)){
                request.setEndpoint('callout:ClubhouseCredentials/api/Client');
            }else if ('ENQUIRY'.equalsIgnoreCase(objectType)){
                request.setEndpoint('callout:ClubhouseCredentials/api/Enquiry/CreateEnquiry');
            }
            request.setHeader('Content-Type', 'application/json');
            
            EnquiryClientRequestWrapper enqClientRequestWrapper = LC05_OutboundMessageCreator.buildEnquiryClientRequestWrapper(theLead.id, objectType);
            request.setBody(JSON.serialize(enqClientRequestWrapper));
            System.debug('JSON REQUEST: ' + JSON.serialize(enqClientRequestWrapper));
            
            requestQueueLog.Request_Payload__c = JSON.serialize(enqClientRequestWrapper);
            requestQueueLog.Processed_on_date__c = System.today();
            
            try{
                response = http.send(request);
                System.debug('JSON RESPONSE: ' + response.getBody());
                
                if(String.isNotBlank(response.getBody()) && APIUtility.setPositiveStatuses.contains( response.getStatusCode() )){
                    
                    // Set Status to "Success"
                    requestQueueLog.Request_Status__c = ApplicationConstant.REQUEST_QUEUE_STATUS_SUCCESS;
                    // Change the Record Type of Request Queue object to "Log"
                    requestQueueLog.RecordTypeId = ApplicationConstant.getRecordTypeId( ApplicationConstant.OBJECT_TYPE_REQUEST_QUEUE, ApplicationConstant.RECORD_TYPE_REQUEST_QUEUE_LOG );
                
                    
                    lstEnqClientResponseWrapper = (EnquiryClientResponseWrapper) JSON.deserialize( response.getBody(), EnquiryClientResponseWrapper.class );
                    theLead.Account__c = lstEnqClientResponseWrapper.SalesforceClientID;    
                     //2016-12-01 : SM : Only update the EnquiryID if we are creating an Enquiry at this point.
                    if ('ENQUIRY'.equalsIgnoreCase(objectType)){
                        theLead.GolfbreaksEnquiryId__c = lstEnqClientResponseWrapper.GolfbreaksEnquiryID;  
                        theLead.Golfbreaks_Opportunity_Portal_Key__c = lstEnqClientResponseWrapper.GolfbreaksEnquiryKey;  
                    }
                    System.debug('Account ID: '+lstEnqClientResponseWrapper.SalesforceClientID);
                    
                    returnString = response.getStatusCode() + ';' + lstEnqClientResponseWrapper.ClientStatus;
                    
                    //6.6 - Disable WIRE triggers when setting the Enquiry Id on the Lead
                    if ('ENQUIRY'.equalsIgnoreCase(objectType)){
                    	system.debug('Disabling WIRE triggers for Enquiry create response (lead update)');
                    	GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
                    	system.debug('Disabling local triggers for Enquiry create response (lead update)');
                    	GBWire.WorkItemTriggerHandler.disableLocalTriggers = true;
                    }
                    update theLead; 
                    //6.6 - Re-enable the WIRE triggers following the lead update
                    if ('ENQUIRY'.equalsIgnoreCase(objectType)){
                    	system.debug('Re-enabling WIRE triggers following Enquiry create response (Lead update)');
                    	GBWire.WorkItemTriggerHandler.disableWIRETriggers = false;
                    	system.debug('Re-enabling local triggers following Enquiry create response (Lead update)');
                    	GBWire.WorkItemTriggerHandler.disableLocalTriggers = false;
                    }

                    //6.8 - Retrieve lowest level 'Phased Code Removal' settings
                    Phased_Code_Removal__c pcr = Phased_Code_Removal__c.getInstance();
                    //6.8 - Check the 'Disable_Shadow_Opportunities__c' before executing
                    if(pcr != null && !pcr.Disable_Shadow_Opportunities__c){
                        //WE now need to create a new Shadow Opportunity as the Lead has been successfully sent to Clubhouse
                        Set<Id> leadIds = new Set<Id>();
                        leadIds.add(theLead.Id);
                        AP04_LeadTriggerBL.createShadowOpportunity(leadIds);
                    }
                }
                else{
                    lstEnqClientResponseWrapper = (EnquiryClientResponseWrapper) JSON.deserialize( response.getBody(), EnquiryClientResponseWrapper.class );
                    requestQueueLog.Retry__c = 0;
                    requestQueueLog.Request_Status__c = ApplicationConstant.REQUEST_QUEUE_STATUS_FAILED;
                    requestQueueLog.RecordTypeId = ApplicationConstant.getRecordTypeId( ApplicationConstant.OBJECT_TYPE_REQUEST_QUEUE, ApplicationConstant.RECORD_TYPE_REQUEST_QUEUE_LOG );
                    returnString = response.getStatusCode() + ';' + 'ERROR' + ';' + lstEnqClientResponseWrapper.Message;
                    isError = true;
                }
                
                requestQueueLog.Response_Message__c = response.toString();
                requestQueueLog.Response_Payload__c = response.getBody();
                requestQueueLog.Response_Status_code__c = String.ValueOf( response.getStatusCode() );
                
            }
            catch(Exception ex){
                String errormsg = ex.getMessage();
                System.debug('Callout error: ' + ex.getMessage());
            }
        }
        catch(DmlException e){ 
            String error = e.getMessage();
            System.debug('The following exception has occurred: ' + e.getMessage());
        }   
        
        insert requestQueueLog;
        if (isFuture){
            if (isError){
                system.debug('*** -- isError -- ***');
                theLead.Integration_Error_Log__c = requestQueueLog.Id;
                update theLead;
            }
        }
        System.debug('>>>> returnString' + returnString);
        
        return returnString;
    }

    //Public method to create the outbound message - called from the new Opportunity Creation Wizard process
    public static String outboundMessageCallerOpportunity(Opportunity theOpp, EnquiryClientRequestWrapper enqClientRequestWrapper){
        HttpResponse response;
        Request_Queue__c requestQueueLog = new Request_Queue__c();
        boolean isError = false;
        //Opportunity theOpp;
        try {
            //theOpp = [SELECT Id, AccountId, GolfbreaksEnquiryId__c, Integration_Error_Log__c FROM Opportunity WHERE Id =: oppId LIMIT 1];
            
            Http http = new Http();    
            EnquiryClientResponseWrapper lstEnqClientResponseWrapper = new EnquiryClientResponseWrapper();
            //requestQueueLog.Related_ID__c = theOpp.id;
            requestQueueLog.SObject_Name__c = 'Opportunity';
            
            //Get timeout value from custom setting
            Http_Timeout__c httpTimeout = Http_Timeout__c.getInstance('Opportunity Convert');

            //HTTP Request
            HttpRequest request = new HttpRequest();
            if (null != httpTimeout){
                //We have a value, so set the timeout
                system.debug('*** -- Setting Opportunity Convert timeout to ' + integer.valueOf((httpTimeout.Timeout_In_Seconds__c * 1000)) + ' -- ***');
                request.setTimeout(integer.valueOf((httpTimeout.Timeout_In_Seconds__c * 1000)));
            }//Else it will keep the default of ten seconds

            request.setMethod('POST');
            request.setEndpoint('callout:ClubhouseCredentials/api/Enquiry/CreateEnquiry');
            request.setHeader('Content-Type', 'application/json');
            
            //2017-06-30 : SM : We do not call out to LC05_OutboundMessageCreator in this instance, we pass in the request wrapper fully formed
            //EnquiryClientRequestWrapper enqClientRequestWrapper = LC05_OutboundMessageCreator.buildEnquiryClientRequestWrapper(theOpp.id);
            request.setBody(JSON.serialize(enqClientRequestWrapper));
            System.debug('JSON REQUEST: ' + JSON.serialize(enqClientRequestWrapper));
            
            requestQueueLog.Request_Payload__c = JSON.serialize(enqClientRequestWrapper);
            requestQueueLog.Processed_on_date__c = System.today();
            
            try{
            	
            	System.debug(LoggingLevel.ERROR, 'Limits.getDmlRows():outboundMessageCallerOpportunity:beforesend='+Limits.getDmlRows());
            	
                response = http.send(request);
                System.debug('JSON RESPONSE: ' + response.getBody());
                
                if(String.isNotBlank(response.getBody()) && APIUtility.setPositiveStatuses.contains( response.getStatusCode() )){
                    
                    // Set Status to "Success"
                    requestQueueLog.Request_Status__c = ApplicationConstant.REQUEST_QUEUE_STATUS_SUCCESS;
                    // Change the Record Type of Request Queue object to "Log"
                    requestQueueLog.RecordTypeId = ApplicationConstant.getRecordTypeId( ApplicationConstant.OBJECT_TYPE_REQUEST_QUEUE, ApplicationConstant.RECORD_TYPE_REQUEST_QUEUE_LOG );
                    
                    lstEnqClientResponseWrapper = (EnquiryClientResponseWrapper) JSON.deserialize( response.getBody(), EnquiryClientResponseWrapper.class );
                    theOpp.AccountId = lstEnqClientResponseWrapper.SalesforceClientID;    
                    theOpp.GolfbreaksEnquiryId__c = lstEnqClientResponseWrapper.GolfbreaksEnquiryID;  
                    theOpp.Golfbreaks_Portal_Key__c = lstEnqClientResponseWrapper.GolfbreaksEnquiryKey;  
                    
                    System.debug('Account ID: '+lstEnqClientResponseWrapper.SalesforceClientID);
                    
                    returnString = response.getStatusCode() + ';' + lstEnqClientResponseWrapper.ClientStatus;

                    upsert theOpp; 

                }
                else{
                    lstEnqClientResponseWrapper = (EnquiryClientResponseWrapper) JSON.deserialize( response.getBody(), EnquiryClientResponseWrapper.class );
                    requestQueueLog.Retry__c = 0;
                    requestQueueLog.Request_Status__c = ApplicationConstant.REQUEST_QUEUE_STATUS_FAILED;
                    requestQueueLog.RecordTypeId = ApplicationConstant.getRecordTypeId( ApplicationConstant.OBJECT_TYPE_REQUEST_QUEUE, ApplicationConstant.RECORD_TYPE_REQUEST_QUEUE_LOG );
                    returnString = response.getStatusCode() + ';' + 'ERROR' + ';' + lstEnqClientResponseWrapper.Message;
                    isError = true;
                }
                
                requestQueueLog.Response_Message__c = response.toString();
                requestQueueLog.Response_Payload__c = response.getBody();
                requestQueueLog.Response_Status_code__c = String.ValueOf( response.getStatusCode() );
                
            }
            catch(Exception ex){
                String errormsg = ex.getMessage();
                System.debug('Callout error: ' + ex.getMessage());
            }
        }
        catch(DmlException e){ 
            String error = e.getMessage();
            System.debug('The following exception has occurred: ' + e.getMessage());
        }   
        
        insert requestQueueLog;

        System.debug('>>>> returnString' + returnString);
        
        return returnString;
    }

    //2017-07-27 : SM : New method to create Enquiry in Clubhouse, from Lead, used in Batch class
    //2017-07-27 : SM : Does not insert a Request Queue Log record, nor return an error string
    //2017-07-27 : SM : Instead it writes an errors back to the field Lead.Clubhouse_Integration_Error__c
    webservice static Lead outboundMessageCallerLead(String LeadId){
        HttpResponse response;
        Request_Queue__c requestQueueLog = new Request_Queue__c();
        boolean isError = false;
        Lead theLead;
        try {
            theLead = [SELECT Id, Account__c, GolfbreaksEnquiryId__c, Integration_Error_Log__c, Clubhouse_Integration_Error__c FROM Lead WHERE Id =: LeadId LIMIT 1];
            
            Http http = new Http();    
            EnquiryClientResponseWrapper lstEnqClientResponseWrapper = new EnquiryClientResponseWrapper();
            requestQueueLog.Related_ID__c = theLead.id;
            requestQueueLog.SObject_Name__c = String.valueOf(theLead.id.getSobjectType());
            
            //Get timeout value from custom setting
            Http_Timeout__c httpTimeout = Http_Timeout__c.getInstance('Lead Convert');

            //HTTP Request
            HttpRequest request = new HttpRequest();
            if (null != httpTimeout){
                //We have a value, so set the timeout
                system.debug('*** -- Setting Lead Convert timeout to ' + integer.valueOf((httpTimeout.Timeout_In_Seconds__c * 1000)) + ' -- ***');
                request.setTimeout(integer.valueOf((httpTimeout.Timeout_In_Seconds__c * 1000)));
            }//Else it will keep the default of ten seconds

            request.setMethod('POST');
            request.setEndpoint('callout:ClubhouseCredentials/api/Enquiry/CreateEnquiry');
            request.setHeader('Content-Type', 'application/json');
            
            EnquiryClientRequestWrapper enqClientRequestWrapper = LC05_OutboundMessageCreator.buildEnquiryClientRequestWrapper(theLead.id, 'ENQUIRY');
            request.setBody(JSON.serialize(enqClientRequestWrapper));
            System.debug('JSON REQUEST: ' + JSON.serialize(enqClientRequestWrapper));
            
            requestQueueLog.Request_Payload__c = JSON.serialize(enqClientRequestWrapper);
            requestQueueLog.Processed_on_date__c = System.today();
            
            try{
                response = http.send(request);
                System.debug('JSON RESPONSE: ' + response.getBody());
                
                if(String.isNotBlank(response.getBody()) && APIUtility.setPositiveStatuses.contains( response.getStatusCode() )){
                    
                    // Set Status to "Success"
                    requestQueueLog.Request_Status__c = ApplicationConstant.REQUEST_QUEUE_STATUS_SUCCESS;
                    // Change the Record Type of Request Queue object to "Log"
                    requestQueueLog.RecordTypeId = ApplicationConstant.getRecordTypeId( ApplicationConstant.OBJECT_TYPE_REQUEST_QUEUE, ApplicationConstant.RECORD_TYPE_REQUEST_QUEUE_LOG );
                
                    
                    lstEnqClientResponseWrapper = (EnquiryClientResponseWrapper) JSON.deserialize( response.getBody(), EnquiryClientResponseWrapper.class );
                    theLead.Account__c = lstEnqClientResponseWrapper.SalesforceClientID;    
                    theLead.GolfbreaksEnquiryId__c = lstEnqClientResponseWrapper.GolfbreaksEnquiryID;  
                    theLead.Golfbreaks_Opportunity_Portal_Key__c = lstEnqClientResponseWrapper.GolfbreaksEnquiryKey;  

                    System.debug('Account ID: '+lstEnqClientResponseWrapper.SalesforceClientID);
                    
                    returnString = response.getStatusCode() + ';' + lstEnqClientResponseWrapper.ClientStatus;
                    
                    //2017-07-27 : SM : At this point, we were UPDATING the Lead, but now we just return it
                    return theLead; 
                }
                else{
                    lstEnqClientResponseWrapper = (EnquiryClientResponseWrapper) JSON.deserialize( response.getBody(), EnquiryClientResponseWrapper.class );
                    requestQueueLog.Retry__c = 0;
                    requestQueueLog.Request_Status__c = ApplicationConstant.REQUEST_QUEUE_STATUS_FAILED;
                    requestQueueLog.RecordTypeId = ApplicationConstant.getRecordTypeId( ApplicationConstant.OBJECT_TYPE_REQUEST_QUEUE, ApplicationConstant.RECORD_TYPE_REQUEST_QUEUE_LOG );
                    returnString = response.getStatusCode() + ';' + 'ERROR' + ';' + lstEnqClientResponseWrapper.Message;
                    isError = true;
                }
                
                requestQueueLog.Response_Message__c = response.toString();
                requestQueueLog.Response_Payload__c = response.getBody();
                requestQueueLog.Response_Status_code__c = String.ValueOf( response.getStatusCode() );
                
            }
            catch(Exception ex){
                String errormsg = ex.getMessage();
                System.debug('Callout error: ' + ex.getMessage());
            }
        }
        catch(DmlException e){ 
            String error = e.getMessage();
            System.debug('The following exception has occurred: ' + e.getMessage());
        }   
        
        System.debug('>>>> returnString' + returnString);
        
        theLead.Clubhouse_Integration_Error__c = returnString;

        return theLead;
    }
    
}