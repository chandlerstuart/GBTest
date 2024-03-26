/*
Name:  WebhookManager.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Business Logic Manager for Webhook callback execution.

Note - the implementation does not support return of outcome=created etc.

TODO:
[ ] Code validation and refactoring.
[x] Replace Success/Fail return state with detailed error Message.
[x] Response codes.
[ ] - Webhook__mdt - format string and field list for success response.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-12-23  Initial development.
1.1  Mark Cane&    2020-01-08  Enhancement. Initial error response.
1.2  Mark Cane&    2020-02-10  Enhancement. Dynamic response handling.
1.3  Mark Cane&    2020-03-02  Enhancement. Flow Request Handler.
1.4  Mark Cane&    2020-03-02  Enhancement. Async Callback - Id format type only.
1.5  Mark Cane&    2020-02-05  Enhancements. FormatStringHelper replaces local class SuccessResponseFormat composition.
1.6  J Radcliffe   2020-03-19  Enhancements. Pass Webhook into Request Handler (Apex). Change Access Modifiers for 2 methods, so they can be referenced in local apex request handlers.
1.7  J Radcliffe   2020-03-23  Bug Fix. Change buildSuccessResponse param from Id to String (for simplifying unit tests, which rely on false external Ids)
1.8  J Radcliffe   2020-03-24  Enhancements. Make the Dynamic Deserialization Case-Insensitive
1.9  J Radcliffe   2020-04-01  Bug Fix. Replace "" with null when reshaping JSON to avoid deserialization error
1.10 J Radcliffe   2020-04-22  Bug Fix. Build on 1.10 (change null to 'null')
1.11 J Radcliffe   2020-04-27  Enhancement. Query Webhooks based on any path element.
1.12 Mark Cane&    2020-08-12  Bug Fix. Added escapeSpecialCharacters to cleanse json pre deserialisation.
1.13 J Radcliffe   2023-02-07  Enhancement. Pass Apex Defined Data Types directly to Flow Request Handlers
*/
public with sharing class WebhookManager {

    @TestVisible public static Object flowADTData;

    public WebhookManager(){}

    //public static void processWebhook(String pathValue, RestRequest outerRequest, RestResponse outerResponse){//1.11-
        public static void processWebhook(List<String> pathElements, RestRequest outerRequest, RestResponse outerResponse){//1.11+

        //get the Webhook
        // if Id format then parse Id from Url
        // .. call DataEventTypeAction
        // .. return success or fail

        // if Request Handler then instantiate request handler class
        // .. set outerResponse

        // if Flow Request Handler then Reshape request and call flow 
        // .. set outerResponse

        try {

            Map<String,Webhook__mdt> pathIdentifierToWebhook = new Map<String,Webhook__mdt>();
                
            for (Webhook__mdt wh : [select Id,DeveloperName,PathIdentifier__c,RequestType__c,RequestHandler__c,FlowRequestHandler__c,ReshapedPayloadType__c,
                                        IsAsyncCallback__c,CallbackDataEventType__r.DeveloperName,ResultDataEventType__r.DeveloperName,
                                        ErrorResponseFormatString__c,ErrorResponseStatusCode__c,ExternalIDFieldAPIName__c,
                                        ObjectType__c,SuccessResponseFormat__c,SuccessResponseFormatFields__c,SuccessResponseStatusCode__c,
                                        FlowApexDefinedDataType__c//1.13+
                                    from Webhook__mdt
                                    where IsActive__c=true and IsTest__c=:Test.isRunningTest()
                                        //and PathIdentifier__c=:pathValue//1.11-
                                        and PathIdentifier__c In:pathElements//1.11+                                                            
                                    order by DeveloperName asc]){//1.2~ 1.3~

                pathIdentifierToWebhook.put(wh.PathIdentifier__c,wh);
            }
            
            // -- if not exists or inactive return [UNKNOWN WEBHOOK] message.
            if (pathIdentifierToWebhook.isEmpty()){
                setDefaultErrorResponse(outerResponse);
                return;
            }

            //Webhook__mdt wh = pathIdentifierToWebhook.get(pathValue);//1.11-
            Webhook__mdt wh = pathIdentifierToWebhook.values()[0];//1.11+

            if (wh.RequestType__c.equalsIgnoreCase(Label.Picklist_Value_Webhook_Request_Type_Id_Format)){

                //1.2. -- Id format = Callback and ExternalIdFieldAPIName__c are mandatory.

                String externalIdAsString = outerRequest.requestURI.substring(outerRequest.requestURI.lastIndexOf('/')+1);//1.2~
                if (String.isNotBlank(externalIdAsString)){

                    Id externalId = Id.valueOf(externalIdAsString);//1.2~

                    if (wh.IsAsyncCallback__c){//1.4+

                        //1.4. -- Queueable chain required to allow DML with DET response handling.
                        if (Limits.getLimitQueueableJobs()>Limits.getQueueableJobs()) System.enqueueJob( new DataEventTypeProcessor(externalId,wh.Id, new List<String>{ wh.CallbackDataEventType__r.DeveloperName, wh.ResultDataEventType__r.DeveloperName }) );
                        outerResponse.statusCode = wh.SuccessResponseStatusCode__c.intValue();//acknowledge via success response, no body.

                    } else {

                        for (DataEventTypeAction.DataEventTypeActionResult detaResult : DataEventTypeAction.invokeDataEventType( new List<DataEventTypeAction.DataEventTypeActionRequest>{ new DataEventTypeAction.DataEventTypeActionRequest(wh.CallbackDataEventType__r.DeveloperName,externalId) })){
                            if (detaResult.isSuccess){
                                outerResponse.statusCode = wh.SuccessResponseStatusCode__c.intValue();//1.2~
                                outerResponse.responseBody = Blob.valueOf(buildSuccessResponse(wh,externalId));//1.2~
                            } else {
                                outerResponse.statusCode = wh.ErrorResponseStatusCode__c.intValue();//1.2~
                                outerResponse.responseBody = Blob.valueOf(wh.ErrorResponseFormatString__c.replace('[error]',detaResult.errorMessage));//1.2~ -- replace the Dynamic Placeholder with the returned error detail.
                            }
                        }
                    }

                } else setDefaultErrorResponse(outerResponse);
                
            } else if (wh.RequestType__c.equalsIgnoreCase(Label.Picklist_Value_Webhook_Request_Type_Request_Handler)){

                //1.2. -- Apex Request Handler = Callback created in handler class if required.

                IWebhookRequestHandler requestHandler;
                Type t;

                if (String.isNotBlank(wh.RequestHandler__c)){
                    t=Type.forName(null,wh.RequestHandler__c);
                    requestHandler = (IWebhookRequestHandler)t.newInstance();

                    requestHandler.handleRequest(outerRequest, outerResponse,wh);//1.6~

                } else setDefaultErrorResponse(outerResponse);

            } else if (wh.RequestType__c.equalsIgnoreCase(Label.Picklist_Value_Webhook_Request_Type_Flow_Request_Handler)){

                //1.3. -- Flow Request Handler = No Callback. ObjectType__c and ExternalIdFieldAPIName__c optional.

                if (String.isNotBlank(wh.FlowRequestHandler__c) &&
                        (String.isNotBlank(wh.ReshapedPayloadType__c) || String.isNotBlank(wh.FlowApexDefinedDataType__c)) && //1.13~
                        outerRequest.requestBody!=null){

                    String externalIdAsString = outerRequest.requestURI.substring(outerRequest.requestURI.lastIndexOf('/')+1);
                    Id externalId = String.isNotBlank(externalIdAsString) ? Id.valueOf(externalIdAsString) : null;
            
                    FlowRequest fr = invokeFlowRequestHandler(wh.FlowRequestHandler__c, wh.ReshapedPayloadType__c, wh.FlowApexDefinedDataType__c, outerRequest.requestBody.toString());//1.13~

                    if (fr.isSuccess){
                        outerResponse.statusCode = wh.SuccessResponseStatusCode__c.intValue();
                        if (externalId!=null) outerResponse.responseBody = Blob.valueOf(buildSuccessResponse(wh,externalId));
                    } else {
                        outerResponse.statusCode = wh.ErrorResponseStatusCode__c.intValue();
                        outerResponse.responseBody = Blob.valueOf(wh.ErrorResponseFormatString__c.replace('[error]',fr.errorMessage));
                    }
                } else setDefaultErrorResponse(outerResponse);
            }

        } catch(Exception ex){ 
            LogHelper.logExceptions(ex, 'WebhookManager', 'processWebhook');            
            setDefaultErrorResponse(outerResponse);
        }
    }

    private static void setDefaultErrorResponse(RestResponse res){//1.2+
        res.statusCode = 400;
        res.responseBody = Blob.valueOf('{ "Message" : "'+Label.Webhook_Validation_Error_Invalid_Webhook+'" }');
    }

    public static String buildSuccessResponse(Webhook__mdt wh, String externalId){//1.6~ Access Modifier private >>> public //1.7~
        try {

            return FormatStringHelper.buildDynamicStringForRecordId(wh.ObjectType__c, wh.ExternalIdFieldAPIName__c, externalId, wh.SuccessResponseFormatFields__c, wh.SuccessResponseFormat__c);//1.5~

        } catch(Exception ex){ LogHelper.logExceptions(ex, 'WebhookManager', 'buildSuccessResponse'); }
        return '';
    }

    //Overloading method for backwards compatibility //1.13+ 
    public static FlowRequest invokeFlowRequestHandler(String flowRequestHandler, String reshapedPayloadTypeId,String jsonRequestBody){
        return invokeFlowRequestHandler(flowRequestHandler, reshapedPayloadTypeId, null, jsonRequestBody);
    }

    //1.3. -- move to helper class and genericise after ReshapedPayloadMapping__mdt rename.
    public static FlowRequest invokeFlowRequestHandler(String flowRequestHandler, String reshapedPayloadTypeId, String flowApexDefinedDataType, String jsonRequestBody){//1.3+ //1.6~ Access Modifier private >>> public //1.3~ flowApexDefinedDataType
        
        FlowRequest fr = new FlowRequest();
        
        if (String.isBlank(flowRequestHandler) || (String.isBlank(reshapedPayloadTypeId) && String.isBlank(flowApexDefinedDataType))) return fr;//1.13~
        
        String reshapedPayloadBody;
        Object requestData;
        if(String.isBlank(flowApexDefinedDataType)){//1.13+
            reshapedPayloadBody = reshapedRequestBody(reshapedPayloadTypeId,jsonRequestBody);
            if (String.isBlank(reshapedPayloadBody)) return fr;
            if(reshapedPayloadBody.contains('""')) reshapedPayloadBody = reshapedPayloadBody.replace('""', 'null');//1.9+ //1.10~
        }else{
            //Deserialize into Object
            requestData = JSON.deserialize(jsonRequestBody, Test.isRunningTest()?WebhookTest.ADTTest.class:Type.forName(flowApexDefinedDataType));
        }

        try {
            Map<String, Object> params = new Map<String, Object>();
            if(String.isBlank(flowApexDefinedDataType) && !String.isBlank(reshapedPayloadBody)) params.put('reshapedPayloadBody', reshapedPayloadBody);//1.13~
            if(!String.isBlank(flowApexDefinedDataType)) params.put('requestData',requestData);//Flow must have 'requestData' input variable of specified apex defined data type //1.13+

            if(Test.isRunningTest() && requestData != null) flowADTData = requestData;//1.13+

            if (Test.isRunningTest()){//1.27~
                fr.isSuccess = true;
            } else {
                Flow.Interview flowHandler = Flow.Interview.createInterview(flowRequestHandler,params);
                flowHandler.start();

                fr.isSuccess = (Boolean)flowHandler.getVariableValue('isSuccess');                    
                fr.errorMessage = (String)flowHandler.getVariableValue('errorMessage');    
            }        
        
        } catch (Exception ex){ LogHelper.logExceptions(ex, 'WebhookManager', 'invokeFlowRequestHandler'); }
        return fr;
    }    

    //1.3. -- move to helper class and genericise after ReshapedPayloadMapping__mdt rename.
    private static String reshapedRequestBody(String reshapedPayloadTypeId, String jsonRequestBody){//1.3+

        if (String.isBlank(reshapedPayloadTypeId) || String.isBlank(jsonRequestBody)) return '';

        try {

            List<ReshapedPayloadMapping__mdt> reshapedPayloadTypeMappings = new List<ReshapedPayloadMapping__mdt>();

            for (ReshapedPayloadMapping__mdt rrm : [select Id, ADTPropertyName__c, ResponseValuePath__c from ReshapedPayloadMapping__mdt where ReshapedPayloadType__c=:reshapedPayloadTypeId]){
                reshapedPayloadTypeMappings.add(rrm);
            }

            Map<String,Object> propertyNameToObject = new Map<String,Object>();

            jsonRequestBody = escapeSpecialCharacters(jsonRequestBody);//1.12+

            Object currentObject, originalObject = (Map<String,Object>)JSON.deserializeUntyped(jsonRequestBody);
            
            Map<String,Object> currentMap;
            List<Object> currentList;
            String actionToken,nameOrIndexToken,typeToken;

            for (ReshapedPayloadMapping__mdt rrm : reshapedPayloadTypeMappings){

                currentObject = originalObject;

                for (String valuePathElem : rrm.ResponseValuePath__c.split(',')){// .. [get>records>list]
                    
                    List<String> tokens = valuePathElem.split('>');// .. [0]=get|index [1]=[index]|[name] [2]=list|map|end
                    if (tokens.size()<>3) break;

                    actionToken = tokens[0].removeStart('[');
                    nameOrIndexToken = tokens[1];
                    typeToken = tokens[2].removeEnd(']');
                    
                    if ((actionToken.equalsIgnoreCase('get') &&
                        currentObject instanceof Map<String,Object>) ||
                        (actionToken.equalsIgnoreCase('index') &&
                        currentObject instanceof List<Object>)){

                        //currentMap = (actionToken.equalsIgnoreCase('get')) ? (Map<String,Object>)currentObject : null;//1.8-
                        currentList = (actionToken.equalsIgnoreCase('index')) ? (List<Object>)currentObject : null;
                        
                        //1.8 - Set the JSON Data (Map KeySet) to UpperCase
                        Map<String,Object> dataMap = (actionToken.equalsIgnoreCase('get')) ? (Map<String,Object>)currentObject : null;//1.8~
                        if(dataMap != null){//1.8+
                            currentMap = new Map<String,Object>();//1.8+
                            for(String stringVal : dataMap.keySet()){//1.8+
                                currentMap.put(stringVal.toUpperCase(),dataMap.get(stringVal));//1.8+
                            }
                        }else{
                            currentMap = null;//1.8+
                        }
                                            
                        switch on typeToken {
                            when 'list','LIST','List' {
                                if (currentMap!=null) currentObject = (List<Object>)currentMap.get(nameOrIndexToken.toUpperCase());//1.8~
                                else if (currentList!=null) currentObject = (List<Object>)currentList.get(Integer.valueOf(nameOrIndexToken));
                            }
                            when 'map','MAP','Map' {
                                if (currentMap!=null) currentObject = (Map<String,Object>)currentMap.get(nameOrIndexToken.toUpperCase());//1.8~
                                else if (currentList!=null) currentObject = (Map<String,Object>)currentList.get(Integer.valueOf(nameOrIndexToken));
                            }
                            when 'end','END','End' {
                                if (currentMap!=null) currentObject = (Object)currentMap.get(nameOrIndexToken.toUpperCase());//1.8~
                                else if (currentList!=null) currentObject = (Object)currentList.get(Integer.valueOf(nameOrIndexToken));

                                propertyNameToObject.put(rrm.ADTPropertyName__c,currentObject);
                                break;
                            }
                        }
                    }
                }
            }
            //[Removed for release] System.debug(LoggingLevel.ERROR, 'FINDME>propertyNameToObject='+propertyNameToObject);
            if (!propertyNameToObject.isEmpty()) return JSON.serialize(propertyNameToObject);

        } catch (Exception ex){ LogHelper.logExceptions(ex, 'WebhookManager', 'reshapedRequestBody'); }
        return '';
    }

    @TestVisible
    private static String escapeSpecialCharacters(String jsonString){//1.12+
        jsonString = jsonString.replace('\n','\\n');
        jsonString = jsonString.replace('\r','\\r');
        jsonString = jsonString.replace('\\',' ');

        return jsonString;
    }

    public class FlowRequest {//1.3+ -- move to helper class.
        public Boolean isSuccess { get; set; }
        public String errorMessage { get; set; }

        public FlowRequest(){ isSuccess=false; }
    }

    public class DataEventTypeProcessor implements System.Queueable, Database.AllowsCallouts {// -- Queueable chain required to allow DML with DET response handling.

        public Id externalId { get; set; }
        public Id webhookId { get; set; }
        public String requestBody { get; set; }
        public List<String> dataEventTypes { get; set; }
        
        public DataEventTypeProcessor(Id externalId, Id webhookId, List<String> dataEventTypes){
            this.externalId = externalId;
            this.webhookId = webhookId;
            this.requestBody = requestBody;
            this.dataEventTypes = dataEventTypes;
        }

        public DataEventTypeProcessor(Id externalId, Id webhookId, List<String> dataEventTypes, String requestBody){
            this.externalId = externalId;
            this.webhookId = webhookId;
            this.requestBody = requestBody;
            this.dataEventTypes = dataEventTypes;
            this.requestBody = requestBody;
        }

        public void execute(QueueableContext context) {
            if (dataEventTypes.isEmpty()) return;

            try {

                List<Webhook__mdt> webHooks = [select Id,DeveloperName,PathIdentifier__c,RequestType__c,RequestHandler__c,FlowRequestHandler__c,ReshapedPayloadType__c,
                                                    IsAsyncCallback__c,CallbackDataEventType__r.DeveloperName,ResultDataEventType__r.DeveloperName,
                                                    ErrorResponseFormatString__c,ErrorResponseStatusCode__c,ExternalIDFieldAPIName__c,
                                                    ObjectType__c,SuccessResponseFormat__c,SuccessResponseFormatFields__c,SuccessResponseStatusCode__c
                                                from Webhook__mdt
                                                where IsActive__c=true and Id=:webhookId];
                if (webhooks.isEmpty()) return;
                
                Webhook__mdt wh = webHooks[0];

                String dataEventType = dataEventTypes[0];
                dataEventTypes.remove(0);
                
                DataEventTypeAction.DataEventTypeActionRequest detaRequest = new DataEventTypeAction.DataEventTypeActionRequest();
                detaRequest.dataEventType = dataEventType;
                detaRequest.recordId = externalId;
                if (String.isNotBlank(requestBody)) detaRequest.requestBody = requestBody;

                for (DataEventTypeAction.DataEventTypeActionResult detaResult : DataEventTypeAction.invokeDataEventType( new List<DataEventTypeAction.DataEventTypeActionRequest>{ detaRequest })){
                    if (wh.CallbackDataEventType__r.DeveloperName.equalsIgnoreCase(dataEventType)){
                        if (detaResult.isSuccess){
                            requestBody = buildSuccessResponse(wh,externalId);
                        } else {
                            requestBody = wh.ErrorResponseFormatString__c.replace('[error]',detaResult.errorMessage);
                        }
                    } else if (!detaResult.isSuccess){
                        //todo -- log failure to return response to platform log.
                    }
                }
                // -- avoid AsyncException - Max Stack Depth in unit tests.
                if (!Test.isRunningTest() && !dataEventTypes.isEmpty() && (Limits.getLimitQueueableJobs()>Limits.getQueueableJobs())){
                    System.enqueueJob( new DataEventTypeProcessor(externalId,wh.Id,dataEventTypes,requestBody) );
                }
                                
            } catch(Exception ex){ LogHelper.logExceptions(ex, 'WebhookManager', 'processAsyncCallback'); }
        }
    }    
}