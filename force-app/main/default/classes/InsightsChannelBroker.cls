/*
Name:  InsightsChannelBroker.cls
Copyright © 2020  Golfbreaks
======================================================
======================================================
Purpose:
-------
Broker class - Insights => SIF : DET for callouts.
             - Insights <= SIF : Webhook push of insight channel data.
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2020-10-24  Initial development.
1.1  J Radcliffe   2020-10-26  Settings values and adding error logging
1.2  Mark Cane&    2021-10-16  Added IDataEventTypeResponseHandler implementation.
1.3  Mark Cane&    2021-10-29  Bug fixes. Account Id reference correction in Visitor Data response.
1.4  Mark Cane&    2021-11-09  Bug fixes. escapeSpecialCharacters removes trailing n characters e.g. Spain become Spai.
                               Bug fixes. Runtime exceptions where secondary Ids not found in repsonse JSON.
*/
global class InsightsChannelBroker implements IDataEventTypeResponseHandler, IWebhookRequestHandler, golfbreaks.IInsightsChannelConnectable {

    @TestVisible public Boolean testSuccess;
    @TestVisible public String testJSONResponse;
    @TestVisible public static String insightsChannelDeveloperName = 'TealiumVisitorInsightsChannel';//1.2+

    // UI flow.

    public String processDataRequest(Id recordId, String trackingId, String dataEventTypeName){
        //1.2. Called by the InsightsChannelManager.getInsights() method via the golfbreaks.IInsightsChannelConnectable interface.
        //1.2. UI flow - UI initiated synchronous request of Visitor Profile.
        try{
        
            DataEventTypeAction.DataEventTypeActionRequest detar = new DataEventTypeAction.DataEventTypeActionRequest(dataEventTypeName,recordId);
            detar.queryStringParameters = 'attributeValue='+trackingId;

            List<DataEventTypeAction.DataEventTypeActionResult> detaResults = (!Test.isRunningTest())?DataEventTypeAction.invokeDataEventType( new List<DataEventTypeAction.DataEventTypeActionRequest>{ detar }):new List<DataEventTypeAction.DataEventTypeActionResult>();

            if(Test.isRunningTest()){
                detaResults.add(new DataEventTypeAction.DataEventTypeActionResult(null));
                detaResults[0].responseBody = testJSONResponse; 
                detaResults[0].isSuccess = true;
            }

            return (detaResults!=null && !detaResults.isEmpty()) ? detaResults[0].responseBody : '';
        
        }catch(Exception e){
            golfbreaks.PlatformLogManager.logExceptions(e, 'InsightsChannelBroker', 'processDataRequest');
            return '';
        }
    }

    // Callback flow.

    public void handleRequest(RestRequest req, RestResponse res, Webhook__mdt wh){
        //1.2. Called by the SIF Webhook via the IWebhookRequestHandler interface.
        //1.2. Callback flow - Webhook initiated asynchronous request of Visitor Profile.
        
        try {

            String jsonString = (req.requestBody != null)?escapeSpecialCharacters(req.requestBody.toString()):null;
            
            Map<String,Object> requestData = (Map<String,Object>)JSON.deserializeUntyped(jsonString);

            Id accountId = (requestData != null)?(Id)requestData.get('salesforce_id'):null;
            String trackingId = (requestData != null)?(String)requestData.get('tealium_id'):null;

            //Validate attributes
            if(trackingId == null){logFailResponse(res,'Could not retrieve tracking id from JSON Request',wh);return;}
            if(accountId == null){logFailResponse(res,'Could not retrieve account id from JSON Request',wh);return;}        

            //Call the refreshInsights method to trigger the retrieval (a refresh) of the Tealium data
            //1.2-Boolean isSuccess = golfbreaks.InsightsChannelManager.refreshInsights(accountId,trackingId,null);

            //1.2-if(isSuccess || (Test.isRunningTest() && testSuccess)){
            //1.2-    res.statusCode = (wh.SuccessResponseStatusCode__c != null)?Integer.valueOf(wh.SuccessResponseStatusCode__c):200;
            //1.2-    res.responseBody = Blob.valueOf('Tealium Data Refreshed Successfully');
            //1.2-    return;
            //1.2-}else{
            //1.2-    logFailResponse(res, 'Unable to refresh Tealium Data', wh);
            //1.2-    return;
            //1.2-}
        
            List<golfbreaks__InsightsChannel__mdt> insightsChannels = [select Id,MasterLabel,DeveloperName,golfbreaks__CallbackDataEventTypeName__c
                                                                                from golfbreaks__InsightsChannel__mdt
                                                                                where DeveloperName=:insightsChannelDeveloperName];

            if (Test.isRunningTest() || (insightsChannels.size()==1 && insightsChannels[0].golfbreaks__CallbackDataEventTypeName__c!=null)){

                DataEventTypeAction.DataEventTypeActionRequest detar = new DataEventTypeAction.DataEventTypeActionRequest(Test.isRunningTest()?null:insightsChannels[0].golfbreaks__CallbackDataEventTypeName__c,accountId);
                detar.queryStringParameters = 'attributeValue='+trackingId;
    
                List<DataEventTypeAction.DataEventTypeActionResult> detaResults = (!Test.isRunningTest())?DataEventTypeAction.invokeDataEventType( new List<DataEventTypeAction.DataEventTypeActionRequest>{ detar }):new List<DataEventTypeAction.DataEventTypeActionResult>{ new DataEventTypeAction.DataEventTypeActionResult(null,testSuccess) };
    
                if (detaResults==null || detaResults.isEmpty() || detaResults.size()!=1 || !detaResults[0].isSuccess){
                    logFailResponse(res, 'Unable to refresh Tealium Data', wh);

                } else {
                    res.responseBody = Blob.valueOf('Tealium Data Refreshed Successfully');
                    res.statusCode = (Integer)wh.SuccessResponseStatusCode__c;
                }

            } else logFailResponse(res, 'Unable to refresh Tealium Data', wh);
        
        } catch(Exception e){ golfbreaks.PlatformLogManager.logExceptions(e, 'InsightsChannelBroker', 'handleRequest'); }
    }

    public static Boolean handleOutboundResponse(HttpResponse res){//1.2+
        //1.2. Called by the SIF DET via the IDataEventTypeResponseHandler interface.
        //1.2. Callback flow - Webhook initiated asynchronous request of Visitor Profile.
        try {            

            system.debug('Tealium Body > '+res.getBody());

            if (res.getStatusCode()!=200){ golfbreaks.PlatformLogManager.logCustomMessage('Non-success status code '+(res.getStatusCode()!=null ? res.getStatusCode().format() : ''), null, 'InsightsChannelBroker', 'handleOutboundResponse', null); return false; }//1.4+
            
            String jsonResponse = (res.getBody()!=null) ? escapeResponseSpecialCharacters(res.getBody()) : null;//1.4~
            
            if (jsonResponse==null || String.isBlank(jsonResponse)){ golfbreaks.PlatformLogManager.logCustomMessage('No response body available', null, 'InsightsChannelBroker', 'handleOutboundResponse', null); return false; }

            Map<String,Object> dataMap = (Map<String,Object>)JSON.deserializeUntyped(jsonResponse);//1.4~
            if (!dataMap.containsKey('visitor') || !(dataMap.get('visitor') instanceof Map<String,Object>)){ golfbreaks.PlatformLogManager.logCustomMessage('Could not find a valid Account Id in Response (visitor)', null, 'InsightsChannelBroker', 'handleOutboundResponse', null); return false; }//1.4~

            //1.4- Map<String,Object> visitorData = (Map<String,Object>)((Map<String,Object>)JSON.deserializeUntyped(jsonResponse)).get('visitor');//retrieve account Id from the webhook request
            Map<String,Object> visitorMap = (Map<String,Object>)dataMap.get('visitor');//1.4~ retrieve account Id from the webhook request

            if (!visitorMap.containsKey('secondary_ids') || !(visitorMap.get('secondary_ids') instanceof Map<String,Object>)){ golfbreaks.PlatformLogManager.logCustomMessage('Could not find a valid Account Id in Response (secondary_ids)', null, 'InsightsChannelBroker', 'handleOutboundResponse', null); return false; }//1.4~

            Map<String,Object> secondaryIdMap = (Map<String,Object>)visitorMap.get('secondary_ids');
            if (!secondaryIdMap.containsKey('Account Salesforce Id')){ golfbreaks.PlatformLogManager.logCustomMessage('Could not find a valid Account Id in Response (Account Salesforce Id)', null, 'InsightsChannelBroker', 'handleOutboundResponse', null); return false; }//1.4~

            //1.4- String accountId = (String)((Map<String,Object>)((Map<String,Object>)visitorData).get('secondary_ids')).get('Account Salesforce Id');//1.2~
            String accountId = (String)secondaryIdMap.get('Account Salesforce Id');//1.4~
            if (accountId==null || !accountId.startsWith('001')){ golfbreaks.PlatformLogManager.logCustomMessage('Could not find a valid Account Id in Response', null, 'InsightsChannelBroker', 'handleOutboundResponse', null); return false; }

            //String trackingId;//retrieve from the webhook request <<--- No Tracking Id provided in Request
            List<Account> accountsToCheck = [select Id, Name, TealiumId__c from Account where Id=:accountId and TealiumId__c<>null];
            
            if (accountsToCheck==null || accountsToCheck.isEmpty()){ golfbreaks.PlatformLogManager.logCustomMessage('Could not find a valid Account Id in Response', null, 'InsightsChannelBroker', 'handleOutboundResponse', null); return false; }
            
            String trackingId = accountsToCheck[0].TealiumId__c;
            
            Map<String,String> insightsChannelToData = new Map<String,String>{ insightsChannelDeveloperName=>jsonResponse};
            
            return Test.isRunningTest() ? true : golfbreaks.InsightsChannelManager.refreshInsights(Id.valueOf(accountId), trackingId, insightsChannelToData);

        } catch(Exception e){ golfbreaks.PlatformLogManager.logExceptions(e, 'InsightsChannelBroker', 'handleOutboundResponse'); }
        return false;
    }    

    private static String escapeSpecialCharacters(String jsonString){
        jsonString = jsonString.replace('\n','\\n');
        jsonString = jsonString.replace('\r','\\r');
        jsonString = jsonString.replace('\\',' ');
        jsonString = jsonString.replace(' n ','');
        jsonString = jsonString.replace('\"','"');
        jsonString = jsonString.replace('n"','"');
        jsonString = jsonString.replace('n}','}');
        return jsonString;
    }

    private static String escapeResponseSpecialCharacters(String jsonString){//1.4+
        jsonString = jsonString.replace('\n','\\n');
        jsonString = jsonString.replace('\r','\\r');
        jsonString = jsonString.replace('\\',' ');

        return jsonString;
    }    

    private static void logFailResponse(RestResponse res, String failMessage, Webhook__mdt wh){
        res.responseBody = Blob.valueOf('Request Handling Failure > '+failMessage);
        res.statusCode = wh.ErrorResponseStatusCode__c!=null?Integer.valueOf(wh.ErrorResponseStatusCode__c):400;
    }
}