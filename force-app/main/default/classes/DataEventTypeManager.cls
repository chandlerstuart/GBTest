/*
Name:  DataEventTypeManager.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Manager class for Data Event Types.
------------------
Http Status Codes:
------------------
200 - Success (200 range is deemed success).
400 - Validation error (400 range is deemed permanent error - except 423).
423 - Temporary error - record locked.
500 - Technical error (500 range is deemed temporary error).

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-08-16  Initial development.
1.1  Mark Cane&    2019-09-06  Asynchronous behaviour added.
1.2  Mark Cane&    2019-09-11  Additional asynchronous data event type changes.
1.3  Mark Cane&    2019-09-11  Transaction Type changes.
1.4  Mark Cane&    2019-09-12  Bulk flag handling (Payload request type only).
1.5  Mark Cane&    2019-10-09  Status codes moved to Framework Settings + BlockedBy handling.
1.6  Mark Cane&    2019-10-14  Max/Min BatchSize + Delegate Data Event Type handling.
1.7  Mark Cane&    2019-10-16  ContentType__c optionality with default to application/json. Renamed processCalloutsAsync to processAsyncImmediateCallouts.
1.8  Mark Cane&    2019-10-16  Asynchronous Immediate callouts switch to Asynchronous Queue for retries.
1.9  Mark Cane&    2019-10-17  Merge url composition with Dynamic Placeholders. Example=[api/1.00/webhook/salesforce/client-merge/[masterrecordid]?losingClientIDs=[sourcerecordids].
1.10 J Radcliffe   2019-10-17  Bug Fixes 
1.11 J Radcliffe   2019-10-21  Bug Fix - Handle no Request Body HTTP Failures
1.12 J Radcliffe   2019-10-23  Log Async Immediate Successes & 'No Retry' failures to OutboundCallout Object (Queue)
1.13 J Radcliffe   2019-10-24  Bug Fix - Merge enpoint construction - ReplaceAll >>> Replace
1.14 J Radcliffe   2019-10-30  The DataEventType is already overwritten and then the an attempt is made to add the DelegatedDET. Once the DET is overwritten (and becomes the Delegated DET) the DeveloperName should be added to the map
1.15 Mark Cane&    2019-11-04  Bug fixes. Delegate Data Event url composition #W-000803. sObjectTypeToFormatStringFields reverted from List to Set.
1.16 Mark Cane&    2019-11-07  Enhancements. Framework settings CalloutTimeout__c handling.
1.17 Mark Cane&    2019-11-12  Enhancements. Continue where Runtime exceptions on send + Abort records where no runtime errors occur.
1.18 Mark Cane&    2019-11-13  Bug fixes. exceptionsToLog (deferred logging) added to prevent uncommitted work exception when error logged (dml) before a (the next) callout.
1.19 Mark Cane&    2019-11-25  Bug fixes. 1.17 rollback for AsyncImmediate path.
1.20 Mark Cane&    2019-11-27  Enhancements. DET level CalloutTimeout__c support (plus OC field).
1.21 Mark Cane&    2019-11-27  Bug Fixes. AsyncQueue individual send exception handling.
1.22 Mark Cane&    2019-11-29  Bug Fixes. AsyncQueue Abort status set if not Retry and not Success.
1.23 Mark Cane&    2020-01-08  Enhancements. processDataEventTypes overload to return error detail.
1.24 J Radcliffe   2020-02-24  Endpoint Formatting - Support for replacing SingleQuote symbol (*SQ*) with a single quote at runtime
1.25 J Radcliffe   2020-02-25  New Method - getResponseFromOutboundCallouts.
1.26 Mark Cane&    2020-02-26  Enhancements. Reshaped Payload functionality added.
1.27 Mark Cane&    2020-03-02  Enhancements. FlowResult class added.
1.28 Mark Cane&    2020-02-03  Enhancements. processDataEventTypes>Request Body parameter - required for Async Callback Result DET. 
1.29 Mark Cane&    2020-02-05  Enhancements. FormatStringHelper replaces local class SuccessResponseFormat composition.
1.30 Mark Cane&    2020-04-20  Enhancements. Added lastRequestBody static to improve unit testing of composed requests.
1.31 Mark Cane&    2020-05-13  Enhancements. Added lastRequestEndpoint static to improve unit testing of composed requests.
1.32 Mark Cane&    2020-05-14  Enhancements. Added support for DET field IsDeferredFormats__c.
1.33 Mark Cane&    2020-05-20  Bug Fixes. Missing endpoint protocol with IsDeferredFormats__c=true.
1.34 Mark Cane&    2020-07-22  Enhancements. Inactive DET handling.
1.35 Mark Cane&    2020-08-12  Bug Fix. Added escapeSpecialCharacters to cleanse json pre deserialisation.
1.36 Mark Cane&    2020-10-07  Enhancements. processDataEventTypesDetailed now returns recId=>IsSuccess=>responseBody+DELIM_TOKEN+errorMessage.
1.37 Mark Cane&    2020-11-07  Enhancements. DataEventType IsCustomAuthenticationProtocol__c support.
1.38 Mark Cane&    2020-11-09  Bug fixes. Null dereference where exception in Http send. recordIdToQueryStringParameters property handling.
1.39 J Radcliffe   2020-11-16  Enhancements. Added more logic for Request Headers
1.40 J Radcliffe   2020-02-09  Enhancements. Added support for Custom Headers (initially to support callouts to Content Stack)
1.41 J Radcliffe   2020-02-09  Bug Fixes. Truncate callout response if String is greater than 5000 characters
1.42 J Radcliffe   2020-02-11  Enhancements. Added support for 'finalActivityHandler'.
1.43 Mark Cane&    2021-02-21  Bug fixes. recordIdsToOutboundCallout map refactoring to enable multiple callouts for a single record Id.
1.44 Mark Cane&    2021-06-30  Enhancements. Reshaped payloads; list and ApexClass response handler support.
1.45 Mark Cane&    2021-10-16  Enhancements. Enable retry when simultaneous callout exception encountered for Async Queue processing.
1.46 Mark Cane&    2021-10-29  Bug fixes. Missing authenticated callout fields in async callout DET query.
1.47 J Radcliffe   2022-02-04  Enhancements. New interface IDataEventTypeResponseHandler3 (includes Record Ids)
1.48 J Radcliffe   2022-05-27  Enhancements. New field AuthenticationNamedCredentials__c.
1.49 Mark Cane&    2022-06-10  Enhancements. Enable retry when read callout exception encountered and DET is [Is Retry On Timeout?].
1.50 Mark Cane&    2022-06-22  Enhancements. Is Deferred?.
1.51 Mark Cane&    2022-07-17  Enhancements. IsIgnoreTimeouts__c.
1.52 Mark Cane&    2022-10-19  Enhancements. Enable retry when "You have uncommitted work pending" callout exception encountered.
1.53 Mark Cane&    2022-12-14  Bug fixes. 1.49.
1.54 J Radcliffe   2023-02-20  Enhancements. Added support for passing Apex Defined Types directly to flow response handlers.
1.55 Mark Cane&    2022-08-20  Bug fixes.
*/
public with sharing class DataEventTypeManager {

    public final static String DELIM_TOKEN = '>~~~<';//1.36+

    private Set<Integer> successStatusCodes { get; set; }//1.5+
    private Set<Integer> retryStatusCodes { get; set; }//1.5+

    private FrameworkSettings__c frameworkSettings { get; set; }//1.16+
    private Integer calloutTimeout { get; set; }//1.16+

    private Map<Id,Set<Id>> masterRecordIdToSourceRecordIds;

    private Map<Id,List<ReshapedPayloadMapping__mdt>> reshapedPayloadTypeIdToMappings;//1.26+
    private Map<Id,ReshapedPayloadType__mdt> idToReshapedPayloadTypeId;//1.44+
    
    private Boolean isIgnoreIsDeferred { get; set; }//1.50+
    @testVisible private static Boolean isDeferredOverride { get; set; }//1.50+

    @testVisible private static String lastRequestBody { get; set; }//1.30+
    @testVisible private static String lastRequestEndpoint { get; set; }//1.31+

    public Map<Id,String> recordIdToQueryStringParameters { get; set; }//1.38+

    @TestVisible public static Object flowADTData;//1.54+
    
    public DataEventTypeManager(){
        successStatusCodes = new Set<Integer>();//1.5+
        retryStatusCodes = new Set<Integer>();//1.5+
        isIgnoreIsDeferred = false;//1.50+        

        frameworkSettings = FrameworkSettings__c.getOrgDefaults();//1.16+
        calloutTimeout = (frameworkSettings!=null && frameworkSettings.CalloutTimeout__c!=null && frameworkSettings.CalloutTimeout__c>0) ? (Integer)frameworkSettings.CalloutTimeout__c : 30000;//1.16+
    }

    public DataEventTypeManager(Map<Id,Set<Id>> masterRecordIdToSourceRecordIds){//1.9+
        this();

        this.masterRecordIdToSourceRecordIds = masterRecordIdToSourceRecordIds;
    }

    public DataEventTypeManager(Boolean isIgnoreIsDeferred){//1.50+
        this();

        this.isIgnoreIsDeferred = isIgnoreIsDeferred;
    }

    public Map<Id,Boolean> processDataEventTypes(Map<String,Map<Id,String>> dataEventTypeToRecordIds){//1.6+
        return processDataEventTypes(dataEventTypeToRecordIds,false);
    }

    public Map<Id,Boolean> processDataEventTypes(Map<String,Map<Id,String>> dataEventTypeToRecordIds, Boolean includeDelegateEvents){//1.6~ 1.23~
        //1.23+ -- maintain backward compatibility.
        Map<Id,Boolean> recordIdToResult = new Map<Id,Boolean>();

        Map<Id,Map<Boolean,String>> recordIdToDetailedResult = processDataEventTypesDetailed(dataEventTypeToRecordIds,includeDelegateEvents);

        for (Id recId : recordIdToDetailedResult.keySet()){
            recordIdToResult.put(recId, new List<Boolean>(recordIdToDetailedResult.get(recId).keySet())[0]);
        }
        return recordIdToResult;
    }

    public Map<Id,Map<Boolean,String>> processDataEventTypesDetailed(Map<String,Map<Id,String>> dataEventTypeToRecordIds, Boolean includeDelegateEvents){//1.6~ 1.23~
        
        Map<Id,Map<Boolean,String>> recordIdToResult = new Map<Id,Map<Boolean,String>>();

        try {
            
            Map<Id,SObject> idToSObject = new Map<Id,SObject>();
            Map<String,Set<String>> sObjectTypeToFormatStringFields = new Map<String,Set<String>>();//1.15~
            Map<String,Set<Id>> sObjectTypeToRecordIds = new Map<String,Set<Id>>();

            Set<String> dataEventTypeNames = new Set<String>();//1.6+

            for (DataEventType__mdt det : [select Id, DeveloperName, DelegateDataEventTypeName__c
                                            from DataEventType__mdt
                                            where IsActive__c=true and IsTest__c=:Test.isRunningTest()
                                                and DeveloperName in:dataEventTypeToRecordIds.keySet()                                                            
                                            order by DeveloperName asc]){//1.6+
         
                dataEventTypeNames.add(det.DeveloperName);
                if (String.isNotBlank(det.DelegateDataEventTypeName__c) && includeDelegateEvents){ dataEventTypeNames.add(det.DelegateDataEventTypeName__c); }
            }

            Map<String,DataEventType__mdt> nameToDataEventType = new Map<String,DataEventType__mdt>();

            for (DataEventType__mdt det : [select Id,DeveloperName,ObjectType__c,RequestType__c,TransactionType__c,ExternalSystem__c,
                                                DataOperationType__c,IsBulk__c,MaxRecordsPerBulkPayload__c,
                                                EndpointPathFormatString__c,EndpointPathFormatStringFields__c,
                                                RequestFormat__c,RequestFormatFields__c,
                                                HTTPMethod__c,ContentType__c,NamedCredentials__c,                                                                                               
                                                RequestHandler__c,ResponseHandler__c,CalloutTimeout__c,
                                                MinBatchSize__c,MaxBatchSize__c,DelegateDataEventTypeName__c,
                                                FlowResponseHandler__c, ReshapedPayloadType__c,IsDeferredFormats__c,
                                                IsCustomAuthenticationProtocol__c,AuthenticationBodyFormatString__c,
                                                AuthenticationCredential1__c,AuthenticationCredential2__c,
                                                AuthenticationEndpointPathFormatString__c,AuthenticationExpiredStatusCode__c,
                                                AuthenticationHeaderFormatString__c,AuthenticationRequestContentType__c,
                                                AuthenticationRequestHttpMethod__c,AuthenticationResponseTokenPath__c,
                                                AuthenticationTokenCacheTTLSeconds__c,AuthenticationRequestEncoding__c,
                                                AuthenticationContentTypeAccept__c,ContentTypeAccept__c,//1.39+
                                                AuthenticationNamedCredentials__c,//1.48+
                                                FlowResponseHandlerADT__c,//1.54+
                                                IsDeferred__c,DeferredTimeOffset__c,DeferredParentFieldName__c,//1.50+
                                                (Select Id, Key__c, Value__c From CustomHeaders__r)//1.40+
                                            from DataEventType__mdt
                                            where IsActive__c=true and IsTest__c=:Test.isRunningTest()
                                                and DeveloperName in:dataEventTypeNames                                                            
                                            order by DeveloperName asc]){//1.1~ 1.6~ 1.9~ 1.20~ 1.32~ 1.37~
                nameToDataEventType.put(det.DeveloperName,det);
            }

            DataEventType__mdt dataEventType;

            // -- Check batch sizes and delegation.
            for (String dataEventTypeName : dataEventTypeToRecordIds.keySet().clone()){//1.6+
                if (!nameToDataEventType.containsKey(dataEventTypeName)) continue;//1.15+

                dataEventType = nameToDataEventType.get(dataEventTypeName);

                // -- Check batch size against DET configuration.
                if ((dataEventType!=null && dataEventType.MinBatchSize__c!=null 
                        && dataEventTypeToRecordIds.get(dataEventType.DeveloperName)!=null //1.9~ null check
                        && dataEventType.MinBatchSize__c>0
                        && dataEventTypeToRecordIds.get(dataEventType.DeveloperName).size()<dataEventType.MinBatchSize__c)
                    ||
                    (dataEventType!=null && dataEventType.MaxBatchSize__c!=null 
                        && dataEventTypeToRecordIds.get(dataEventType.DeveloperName)!=null//1.9~ null check
                        && dataEventType.MaxBatchSize__c>0
                        && dataEventTypeToRecordIds.get(dataEventType.DeveloperName).size()>dataEventType.MaxBatchSize__c)){

                    // -- Is delegation possible?
                    if (includeDelegateEvents
                        && String.isNotBlank(dataEventType.DelegateDataEventTypeName__c)
                        && nameToDataEventType.containsKey(dataEventType.DelegateDataEventTypeName__c)){

                        dataEventType = nameToDataEventType.get(dataEventType.DelegateDataEventTypeName__c);

                        // -- Overwrite the original dataeventtype with the delegate.

                        //1.15- if (dataEventTypeToRecordIds.containsKey(dataEventType.DelegateDataEventTypeName__c))// -- if delegate in the map already - add recordIds.
                        if (dataEventTypeToRecordIds.containsKey(dataEventType.DeveloperName))// -- if delegate in the map already - add recordIds.
                            dataEventTypeToRecordIds.get(dataEventType.DeveloperName).putAll(dataEventTypeToRecordIds.get(dataEventTypeName));//1.15+ 1.28~
                        //else dataEventTypeToRecordIds.put(dataEventType.DelegateDataEventTypeName__c,dataEventTypeToRecordIds.get(dataEventTypeName));//1.14-
                        else dataEventTypeToRecordIds.put(dataEventType.DeveloperName,dataEventTypeToRecordIds.get(dataEventTypeName));//1.14+    
                        
                        // -- Check batch size against Delegate DET configuration.
                        if ((dataEventType.MinBatchSize__c!=null 
                                && dataEventType.MinBatchSize__c>0
                                && dataEventTypeToRecordIds.get(dataEventType.DeveloperName)!=null
                                && dataEventTypeToRecordIds.get(dataEventType.DeveloperName).size()<dataEventType.MinBatchSize__c)
                            ||
                            (dataEventType.MaxBatchSize__c!=null 
                                && dataEventType.MaxBatchSize__c>0
                                && dataEventTypeToRecordIds.get(dataEventType.DeveloperName)!=null
                                && dataEventTypeToRecordIds.get(dataEventType.DeveloperName).size()>dataEventType.MaxBatchSize__c)){
                                
                            dataEventTypeToRecordIds.remove(dataEventType.DeveloperName);// -- remove the delegate data event type - batch size too big or small for the delegate.
                            dataEventTypeToRecordIds.remove(dataEventTypeName);//1.15+ -- remove the original data event type - batch size too big or small for the delegate.

                        } else { dataEventTypeToRecordIds.remove(dataEventTypeName); }//1.15+ -- remove the original data event type - delegate is ok to use.

                    } else dataEventTypeToRecordIds.remove(dataEventTypeName); // -- remove the original data event type - batch size too big or small and no delegate.
                }
            }

            // Loop 1 - gather format string fields per sObjectType.

            Map<String, Map<Id,List<String>>> detToRecordIdToDynamicStrings = new Map<String, Map<Id,List<String>>>();//1.29+

            for (String dataEventTypeName : dataEventTypeToRecordIds.keySet()){
                if (!nameToDataEventType.containsKey(dataEventTypeName)) continue;//1.15+                

                dataEventType = nameToDataEventType.get(dataEventTypeName);                         

                if (dataEventType==null) continue;
                if (dataEventType.IsDeferredFormats__c && (dataEventType.TransactionType__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Transaction_Type_Asynchronous_Queue) || dataEventType.TransactionType__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Transaction_Type_Asynchronous_Immediate))) continue;//1.32+
                if (String.isBlank(dataEventType.EndpointPathFormatString__c) && String.isBlank(dataEventType.RequestFormat__c)) continue;//1.9~ null check 1.29~ 
                
                detToRecordIdToDynamicStrings.put( dataEventType.DeveloperName, FormatStringHelper.buildDynamicStringsForDataEventType(dataEventType, dataEventTypeToRecordIds.get(dataEventType.DeveloperName).keySet()) );
            }

            IDataEventTypeRequestHandler requestHandler;
            IDataEventTypeResponseHandler responseHandler;
            IDataEventTypeResponseHandler2 responseHandler2;///1.44+
            IDataEventTypeResponseHandler3 responseHandler3;//1.47+
            Type t;

            Http outboundHttp = new Http();
            HttpRequest outboundHttpRequest;
            HttpResponse outboundHttpResponse;

            String endpointPath,requestBody;//1.29~

            //1.43- Map<Set<Id>,OutboundCallout__c> recordIdsToOutboundCallout = new Map<Set<Id>,OutboundCallout__c>();//1.3+,1.4~
            Map<String,Map<OutboundCallout__c,Set<Id>>> detToOutboundCalloutToRecIds = new Map<String,Map<OutboundCallout__c,Set<Id>>>();//1.43+
            //1.43- Map<Set<Id>,OutboundCalloutEvent__e> recordIdsToOutboundCalloutEvent = new Map<Set<Id>,OutboundCalloutEvent__e>();//1.1+,1.2~,1.4~
            Map<String,Map<OutboundCalloutEvent__e,Set<Id>>> detToOutboundCalloutEventToRecIds = new Map<String,Map<OutboundCalloutEvent__e,Set<Id>>>();//1.43+

            Boolean isSuccess;
            List<System.Exception> exceptionsToLog = new List<System.Exception>();//1.18+
            String responseBody,reshapedPayloadBody;//1.26+ 1.27~

            Integer dataEventTypeTimeout = calloutTimeout;

            // Loop 2 - Process Data Event Types by Transaction Type.

            for (String dataEventTypeName : dataEventTypeToRecordIds.keySet()){    
                if (!nameToDataEventType.containsKey(dataEventTypeName)) continue;//1.34+ 

                dataEventType = nameToDataEventType.get(dataEventTypeName);

                if (((Test.isRunningTest() && isDeferredOverride!=null && isDeferredOverride) || dataEventType.IsDeferred__c) && !isIgnoreIsDeferred && dataEventType.TransactionType__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Transaction_Type_Asynchronous_Queue)){//1.50+

                    Boolean isDeferredRequestsCreated = DeferredDataEventTypeHelper.createDeferredRequests(dataEventType,dataEventTypeToRecordIds.get(dataEventTypeName).keySet());
                    
                    for (Id recordIdToReturn : dataEventTypeToRecordIds.get(dataEventTypeName).keySet()){ recordIdToResult.put(recordIdToReturn, new Map<Boolean,String>{ isDeferredRequestsCreated=>'' }); }

                    continue;
                }

                dataEventTypeTimeout = (dataEventType.CalloutTimeout__c!=null && dataEventType.CalloutTimeout__c>0) ? (Integer)dataEventType.CalloutTimeout__c : calloutTimeout;//1.20+ -- override timeout if set at DET level.

                requestHandler=null;
                responseHandler=null;
                responseHandler2=null;//1.44+
                responseHandler3=null;//1.47+

                if (dataEventType != null && String.isNotBlank(dataEventType.RequestHandler__c) || String.isNotBlank(dataEventType.ResponseHandler__c)){

                    try {

                        if (String.isNotBlank(dataEventType.RequestHandler__c)){
                            t=Type.forName(null,dataEventType.RequestHandler__c);
                            requestHandler = (IDataEventTypeRequestHandler)t.newInstance();
                        }

                        if (String.isNotBlank(dataEventType.ResponseHandler__c)){//1.44~
                            t=Type.forName(null,dataEventType.ResponseHandler__c);
                            
                            if (IDataEventTypeResponseHandler.class.isAssignableFrom(t)){
                                responseHandler = (IDataEventTypeResponseHandler)t.newInstance();
                            } else if (IDataEventTypeResponseHandler2.class.isAssignableFrom(t)){
                                responseHandler2 = (IDataEventTypeResponseHandler2)t.newInstance();
                            }else if (IDataEventTypeResponseHandler3.class.isAssignableFrom(t)){//1.47+
                                responseHandler3 = (IDataEventTypeResponseHandler3)t.newInstance();
                            }
                        }

                    } catch(Exception ex){ exceptionsToLog.add(ex); }//1.18~
                }                

                if (dataEventType.IsBulk__c && dataEventType.RequestType__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Request_Type_Payload)){//1.4+
                    
                    Integer maxRecordsPerBulkPayload = (dataEventType.MaxRecordsPerBulkPayload__c==null || dataEventType.MaxRecordsPerBulkPayload__c==0) ? 200 : Integer.valueOf(dataEventType.MaxRecordsPerBulkPayload__c);

                    Integer currentBatchNumber=1;
                    Map<Integer, Set<Id>> batchToRecordIds = new Map<Integer, Set<Id>>();                

                    for (Id recordId : dataEventTypeToRecordIds.get(dataEventType.DeveloperName).keySet()){//1.28~
                        if (!batchToRecordIds.containsKey(currentBatchNumber)) batchToRecordIds.put(currentBatchNumber,new Set<Id>());

                        batchToRecordIds.get(currentBatchNumber).add(recordId);
                        if (batchToRecordIds.get(currentBatchNumber).size()==maxRecordsPerBulkPayload) currentBatchNumber++;
                    }

                    endpointPath = String.isNotBlank(dataEventType.EndpointPathFormatString__c) ? dataEventType.EndpointPathFormatString__c : '';                    

                    for (Integer bn : batchToRecordIds.keySet()){

                        outboundHttpRequest = new HttpRequest();
                        outboundHttpRequest.setTimeout(dataEventTypeTimeout);//1.16+ 1.20~
                        outboundHttpRequest.setEndpoint('callout:'+dataEventType.NamedCredentials__c+endpointPath);
                        outboundHttpRequest.setMethod(dataEventType.HttpMethod__c);
                        outboundHttpRequest.setHeader('Content-Type', String.isBlank(dataEventType.ContentType__c) ? 'application/json' : dataEventType.ContentType__c);//1.7~
                        //outboundHttpRequest.setHeader('Accept', String.isBlank(dataEventType.ContentType__c) ? 'application/json' : dataEventType.ContentType__c);//1.7~//1.39-
                        outboundHttpRequest.setHeader('Accept', String.isBlank(dataEventType.ContentTypeAccept__c) ? '*/*' : dataEventType.ContentTypeAccept__c);//1.39+

                        //1.40+
                        if(dataEventType?.CustomHeaders__r.size()>0){
                            for(CustomHeader__mdt ch : dataEventType.CustomHeaders__r){
                                if(ch.Key__c == null || ch.Value__c == null) continue;
                                outboundHttpRequest.setHeader(ch.Key__c,ch.Value__c);
                            }
                        }

                        if (requestHandler!=null) outboundHttpRequest = requestHandler.buildOutboundRequest(dataEventType.ObjectType__c, batchToRecordIds.get(bn), outboundHttpRequest);
                        
                        if (dataEventType.TransactionType__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Transaction_Type_Synchronous)){

                            isSuccess = true;

                            try {//1.17+

                                if (dataEventType.IsCustomAuthenticationProtocol__c)//1.37+
                                    outboundHttpResponse = CustomAuthenticationHelper.authenticatedSend(dataEventType, outboundHttpRequest);
                                else outboundHttpResponse = outboundHttp.send(outboundHttpRequest);

                            } catch(Exception ex){ 
                                isSuccess = false;
                                exceptionsToLog.add(ex);//1.18+
                            }

                            responseBody = outboundHttpResponse.getBody();//1.27+
                            
                            if (isSuccess){
                                if (responseHandler!=null) responseHandler.handleOutboundResponse(outboundHttpResponse);
                                isSuccess = isSuccessHttpResponse(outboundHttpResponse);                                
                                
                                //1.27. The [Is Bulk?] flag cannot be true where a FlowResponseHandler has been added to the DET. Code below is redundant but retained.
                                if (isSuccess && responseHandler==null 
                                        && responseHandler2==null 
                                        && responseHandler3==null //1.47+
                                        && String.isNotBlank(dataEventType.FlowResponseHandler__c)
                                        && String.isNotBlank(outboundHttpResponse.getBody())){//1.44~ 1.26+ -- Create Flow Interview if no Apex Handler and FlowResponseHandler set.
                                    
                                    FlowResult fr = invokeFlowResponseHandler(dataEventType.FlowResponseHandler__c, dataEventType.ReshapedPayloadType__c, outboundHttpResponse, dataEventType.FlowResponseHandlerADT__c);//1.27~ 1.54~

                                    isSuccess = fr.isSuccess;//1.27+
                                    
                                    if (responseBody==null) responseBody='';//1.36+
                                    if (String.isNotBlank(fr.errorMessage)) responseBody = responseBody+DELIM_TOKEN+fr.errorMessage;//1.27+ 1.36~
                                }
                            }
                            for (Id recordId : batchToRecordIds.get(bn)){ recordIdToResult.put(recordId,new Map<Boolean,String>{ isSuccess=>responseBody }); }//1.23~ 1.27~

                        } else if (dataEventType.TransactionType__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Transaction_Type_Asynchronous_Immediate)){
                            
                            if (!detToOutboundCalloutToRecIds.containsKey(dataEventType.DeveloperName)) detToOutboundCalloutToRecIds.put(dataEventType.DeveloperName, new Map<OutboundCallout__c,Set<Id>>());//1.43+
                            
                            detToOutboundCalloutToRecIds.get(dataEventType.DeveloperName).put(new OutboundCallout__c(Endpoint__c=outboundHttpRequest.getEndpoint(),
                                                                                                                        Method__c=outboundHttpRequest.getMethod(),
                                                                                                                        ContentTypeHeader__c=outboundHttpRequest.getHeader('Content-Type'),
                                                                                                                        AcceptHeader__c=outboundHttpRequest.getHeader('Accept'),
                                                                                                                        Body__c=outboundHttpRequest.getBody(),
                                                                                                                        DataEventType__c=dataEventType.DeveloperName,
                                                                                                                        ResponseHandler__c=dataEventType.ResponseHandler__c,
                                                                                                                        FlowResponseHandler__c=dataEventType.FlowResponseHandler__c,
                                                                                                                        ReshapedPayloadType__c=dataEventType.ReshapedPayloadType__c), batchToRecordIds.get(bn));//1.43+                        

                        } else if (dataEventType.TransactionType__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Transaction_Type_Asynchronous_Queue)){
                            
                            if (!detToOutboundCalloutEventToRecIds.containsKey(dataEventType.DeveloperName)) detToOutboundCalloutEventToRecIds.put(dataEventType.DeveloperName, new Map<OutboundCalloutEvent__e,Set<Id>>());//1.43+

                            detToOutboundCalloutEventToRecIds.get(dataEventType.DeveloperName).put(new OutboundCalloutEvent__e(Endpoint__c=outboundHttpRequest.getEndpoint(),
                                                                                                                                Method__c=outboundHttpRequest.getMethod(),
                                                                                                                                ContentTypeHeader__c=outboundHttpRequest.getHeader('Content-Type'),
                                                                                                                                AcceptHeader__c=outboundHttpRequest.getHeader('Accept'),
                                                                                                                                Body__c=outboundHttpRequest.getBody(),
                                                                                                                                DataEventType__c=dataEventType.DeveloperName,
                                                                                                                                ResponseHandler__c=dataEventType.ResponseHandler__c,
                                                                                                                                FlowResponseHandler__c=dataEventType.FlowResponseHandler__c,
                                                                                                                                ReshapedPayloadType__c=dataEventType.ReshapedPayloadType__c), batchToRecordIds.get(bn));//1.43~
                        }                        
                    }//batchNumber

                } else {// -- Not Bulk and Payload.
                
                    for (Id recordId : dataEventTypeToRecordIds.get(dataEventType.DeveloperName).keySet()){//1.28~

                        endpointPath = String.isNotBlank(dataEventType.EndpointPathFormatString__c) ? dataEventType.EndpointPathFormatString__c : '';    
                        requestBody=null;//1.29+
                        
                        if (detToRecordIdToDynamicStrings.containsKey(dataEventType.DeveloperName)
                            && detToRecordIdToDynamicStrings.get(dataEventType.DeveloperName).containsKey(recordId)
                            && !detToRecordIdToDynamicStrings.get(dataEventType.DeveloperName).get(recordId).isEmpty()){//1.29~
                                
                            if (String.isNotBlank(detToRecordIdToDynamicStrings.get(dataEventType.DeveloperName).get(recordId)[0])){
                                endpointPath = detToRecordIdToDynamicStrings.get(dataEventType.DeveloperName).get(recordId)[0];
                                lastRequestEndpoint = endpointPath;//1.31+
                            }

                            if (detToRecordIdToDynamicStrings.get(dataEventType.DeveloperName).get(recordId).size()>1 && String.isNotBlank(detToRecordIdToDynamicStrings.get(dataEventType.DeveloperName).get(recordId)[1])){

                                requestBody = detToRecordIdToDynamicStrings.get(dataEventType.DeveloperName).get(recordId)[1];
                                lastRequestBody = requestBody;//1.30+
                            }
                        }
                        
                        // 1.9+ -- if the record is a master record in the class level map.
                        //      -- and the endPointPath contains Dynamic Placeholders, then apply Dynamic PlaceHolder formatting.
                        if (masterRecordIdToSourceRecordIds!=null 
                            && masterRecordIdToSourceRecordIds.containsKey(recordId)
                            && (endpointPath.containsIgnoreCase('[masterrecordid]') || endpointPath.containsIgnoreCase('[sourcerecordids]'))){
                            
                            endpointPath=getDynamicPlaceHolderFormattedEndPointPath(recordId,endpointPath);
                        }

                        if (recordIdToQueryStringParameters!=null 
                            && recordIdToQueryStringParameters.containsKey(recordId)
                            && String.isNotBlank(recordIdToQueryStringParameters.get(recordId))){//1.38+

                            String qsp='';//1.55~

                            for (String p : recordIdToQueryStringParameters.get(recordId).split('&')){
                                
                                if (p.split('=').size()!=2) continue;

                                qsp = EncodingUtil.urlEncode(p.split('=')[0],'UTF-8')+'='+EncodingUtil.urlEncode(p.split('=')[1],'UTF-8');
                            }                            

                            if (!qsp.startsWith('&')) qsp='&'+qsp;
                            endPointPath+=qsp;
                            lastRequestEndpoint = endPointPath;
                        }

                        outboundHttpRequest = new HttpRequest();
                        if (String.isNotBlank(requestBody)) outboundHttpRequest.setBody(requestBody);//1.29+
                        outboundHttpRequest.setTimeout(dataEventTypeTimeout);//1.16+ 1.20~        
                        outboundHttpRequest.setEndpoint('callout:'+dataEventType.NamedCredentials__c+endpointPath);
                        outboundHttpRequest.setMethod(dataEventType.HttpMethod__c);
                        outboundHttpRequest.setHeader('Content-Type', String.isBlank(dataEventType.ContentType__c) ? 'application/json' : dataEventType.ContentType__c);//1.7~
                        //outboundHttpRequest.setHeader('Accept', String.isBlank(dataEventType.ContentType__c) ? 'application/json' : dataEventType.ContentType__c);//1.7~  //1.39-   
                        outboundHttpRequest.setHeader('Accept', String.isBlank(dataEventType.ContentTypeAccept__c) ? '*/*' : dataEventType.ContentTypeAccept__c);//1.39+   
                        outboundHttpRequest.setHeader('Content-Length', (requestBody == null || String.isBlank(requestBody))?'0':String.valueOf(requestBody.length())); //1.11+ - must specify Content-Length if no body is specified (zero) //1.39~
                        if (requestHandler!=null) outboundHttpRequest = requestHandler.buildOutboundRequest(dataEventType.ObjectType__c, new Set<Id>{ recordId }, outboundHttpRequest);

                        //1.40+
                        if(dataEventType?.CustomHeaders__r.size()>0){
                            for(CustomHeader__mdt ch : dataEventType.CustomHeaders__r){
                                if(ch.Key__c == null || ch.Value__c == null) continue;
                                outboundHttpRequest.setHeader(ch.Key__c,ch.Value__c);
                            }
                        }

                        //1.28+ -- a request body is available and not yet set on outboundHttpRequest instance.
                        if (String.isNotBlank(dataEventTypeToRecordIds.get(dataEventType.DeveloperName).get(recordId)) && String.isBlank(outboundHttpRequest.getBody())){
                            outboundHttpRequest.setBody(dataEventTypeToRecordIds.get(dataEventType.DeveloperName).get(recordId));
                        }
                        
                        if (dataEventType.TransactionType__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Transaction_Type_Synchronous)){

                            isSuccess = true;

                            try {//1.17+

                                if (dataEventType.IsCustomAuthenticationProtocol__c)//1.37+
                                    outboundHttpResponse = CustomAuthenticationHelper.authenticatedSend(dataEventType, outboundHttpRequest);
                                else outboundHttpResponse = outboundHttp.send(outboundHttpRequest);

                            } catch(Exception ex){ 
                                isSuccess = false;                                
                                exceptionsToLog.add(ex);//1.18+
                            }

                            responseBody = outboundHttpResponse?.getBody();//1.27+ 1.38~ safe operator added to avoid null dereference.
                            
                            if (isSuccess){
                                if (responseHandler!=null) responseHandler.handleOutboundResponse(outboundHttpResponse);
                                isSuccess = isSuccessHttpResponse(outboundHttpResponse);

                                if (isSuccess && responseHandler==null && responseHandler2!=null){//1.44+

                                    String reshapedResponseBody='';
                                    if (dataEventType.ReshapedPayloadType__c!=null && String.isNotBlank(responseBody)){
                                        reshapedResponseBody = reshapedPayloadBody(dataEventType.ReshapedPayloadType__c,responseBody);
                                    }                                        
                                    isSuccess = responseHandler2.handleOutboundResponse(outboundHttpResponse,reshapedResponseBody,null);
                                    responseBody = reshapedResponseBody;
                                
                                } else if (isSuccess && responseHandler==null && responseHandler2 == null && responseHandler3!=null){//1.47+

                                    String reshapedResponseBody='';
                                    if (dataEventType.ReshapedPayloadType__c!=null && String.isNotBlank(responseBody)){
                                        reshapedResponseBody = reshapedPayloadBody(dataEventType.ReshapedPayloadType__c,responseBody);
                                    }                                      
                                    isSuccess = responseHandler3.handleOutboundResponse(outboundHttpResponse,reshapedResponseBody,null,new Set<Id>{recordId});
                                    responseBody = (reshapedResponseBody != null && !String.isBlank(reshapedResponseBody))?reshapedResponseBody:outboundHttpResponse?.getBody();//If no reshaped body return body
                                
                                }   else if (responseHandler==null 
                                        && String.isNotBlank(dataEventType.FlowResponseHandler__c)
                                        && String.isNotBlank(outboundHttpResponse.getBody())){//1.26+ -- Create Flow Interview if no Apex Handler and FlowResponseHandler set.
                                    
                                    FlowResult fr = invokeFlowResponseHandler(dataEventType.FlowResponseHandler__c, dataEventType.ReshapedPayloadType__c, outboundHttpResponse, dataEventType.FlowResponseHandlerADT__c);//1.27~ 1.54~

                                    isSuccess = fr.isSuccess;//1.27+
                                    if (responseBody==null) responseBody='';//1.36+
                                    if (String.isNotBlank(fr.errorMessage)) responseBody = responseBody+DELIM_TOKEN+fr.errorMessage;//1.27+ 1.36~
                                }
                            }
                            recordIdToResult.put(recordId, new Map<Boolean,String>{ isSuccess=>responseBody } );//1.23~ 1.27~

                        } else if (dataEventType.TransactionType__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Transaction_Type_Asynchronous_Immediate)){//1.3+

                            if (!detToOutboundCalloutToRecIds.containsKey(dataEventType.DeveloperName)) detToOutboundCalloutToRecIds.put(dataEventType.DeveloperName, new Map<OutboundCallout__c,Set<Id>>());//1.43+                            

                            detToOutboundCalloutToRecIds.get(dataEventType.DeveloperName).put(new OutboundCallout__c(Endpoint__c=outboundHttpRequest.getEndpoint(),
                                                                                                                        Method__c=outboundHttpRequest.getMethod(),
                                                                                                                        ContentTypeHeader__c=outboundHttpRequest.getHeader('Content-Type'),
                                                                                                                        AcceptHeader__c=outboundHttpRequest.getHeader('Accept'),
                                                                                                                        CalloutTimeout__c=dataEventTypeTimeout,
                                                                                                                        Body__c=outboundHttpRequest.getBody(),
                                                                                                                        DataEventType__c=dataEventType.DeveloperName,
                                                                                                                        ResponseHandler__c=dataEventType.ResponseHandler__c,
                                                                                                                        RecordId__c=recordId,
                                                                                                                        FlowResponseHandler__c=dataEventType.FlowResponseHandler__c,
                                                                                                                        ReshapedPayloadType__c=dataEventType.ReshapedPayloadType__c), new Set<Id>{ recordId });//1.5~ 1.20~ 1.26~ 1.43~

                        } else if (dataEventType.TransactionType__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Transaction_Type_Asynchronous_Queue)){

                            if (!detToOutboundCalloutEventToRecIds.containsKey(dataEventType.DeveloperName)) detToOutboundCalloutEventToRecIds.put(dataEventType.DeveloperName, new Map<OutboundCalloutEvent__e,Set<Id>>());//1.43+

                            detToOutboundCalloutEventToRecIds.get(dataEventType.DeveloperName).put(new OutboundCalloutEvent__e(Endpoint__c=outboundHttpRequest.getEndpoint(),
                                                                                                                                Method__c=outboundHttpRequest.getMethod(),
                                                                                                                                ContentTypeHeader__c=outboundHttpRequest.getHeader('Content-Type'),
                                                                                                                                AcceptHeader__c=outboundHttpRequest.getHeader('Accept'),
                                                                                                                                CalloutTimeout__c=dataEventTypeTimeout,
                                                                                                                                Body__c=outboundHttpRequest.getBody(),
                                                                                                                                DataEventType__c=dataEventType.DeveloperName,
                                                                                                                                ResponseHandler__c=dataEventType.ResponseHandler__c,
                                                                                                                                RecordId__c=recordId,
                                                                                                                                FlowResponseHandler__c=dataEventType.FlowResponseHandler__c,
                                                                                                                                ReshapedPayloadType__c=dataEventType.ReshapedPayloadType__c), new Set<Id>{ recordId });//1.5~ 1.20~ 1.26~ 1.43~                                                        
                        }
                    }
                }//IsBulk__c?

            }//dataEventType

            if (!detToOutboundCalloutToRecIds.isEmpty()){//1.3+ 1.43~
                
                List<String> eventsAsJSON = new List<String>();

                for (String detDeveloperName : detToOutboundCalloutToRecIds.keySet()){
                    
                    for (OutboundCallout__c ocToSerialise : detToOutboundCalloutToRecIds.get(detDeveloperName).keySet()){

                        eventsAsJSON.add( JSON.serialize(ocToSerialise) );
                    
                        for (Id recordIdToReturn : detToOutboundCalloutToRecIds.get(detDeveloperName).get(ocToSerialise)){ recordIdToResult.put(recordIdToReturn, new Map<Boolean,String>{ true=>'' }); }
                    }
                }
                if (!eventsAsJSON.isEmpty()) processAsyncImmediateCallouts( eventsAsJSON );
            }

            if (!detToOutboundCalloutEventToRecIds.isEmpty()){//1.1+ 1.43~
                
                List<OutboundCalloutEvent__e> eventsAsList = new List<OutboundCalloutEvent__e>();
                List<Database.SaveResult> saveResults;

                for (String detDeveloperName : detToOutboundCalloutEventToRecIds.keySet()){

                    eventsAsList = new List<OutboundCalloutEvent__e>( detToOutboundCalloutEventToRecIds.get(detDeveloperName).keySet() );

                    saveResults = EventBus.publish(eventsAsList.deepClone());//publish a cloned list to retain map key validity.
                    LogHelper.logExceptions(saveResults, 'DataEventTypeManager', 'processDataEventTypes', eventsAsList);

                    for (Integer i=0; i<eventsAsList.size(); i++){
                        for (Id recordIdToReturn : detToOutboundCalloutEventToRecIds.get(detDeveloperName).get(eventsAsList[i])){
                            recordIdToResult.put(recordIdToReturn, new Map<Boolean,String>{ saveResults[i].isSuccess()=>(saveResults[i].isSuccess() ? '' : ''+DELIM_TOKEN+saveResults[i].errors[0].message) });//1.23~
                        }
                    }
                }                        
            }

            if (!exceptionsToLog.isEmpty()){//1.18+
                for (System.Exception ex : exceptionsToLog) LogHelper.logExceptions(ex, 'DataEventTypeManager', 'processDataEventTypes');
            }

        } catch(Exception ex){ LogHelper.logExceptions(ex, 'DataEventTypeManager', 'processDataEventTypes'); }
        return recordIdToResult;
    }

    public Map<OutboundCallout__c,Boolean> processDataEventTypes(Map<String,List<OutboundCallout__c>> dataEventTypeToOutboundRecords){//1.8+
        return processDataEventTypes(dataEventTypeToOutboundRecords,false);
    }
    
    public Map<OutboundCallout__c,Boolean> processDataEventTypes(Map<String,List<OutboundCallout__c>> dataEventTypeToOutboundRecords, Boolean isAsyncImmediate){        
        
        Map<OutboundCallout__c,Boolean> outboundCalloutToIsRetry = new Map<OutboundCallout__c,Boolean>();//1.2~
        Map<OutboundCallout__c,Boolean> outboundCalloutToIsSuccess = new Map<OutboundCallout__c,Boolean>();//1.12+

        try {

            //1.42+ Query Active Blocked Records and store Blocking OC Ids.
            Set<Id> ocIds = new Set<Id>();
            Set<Id> ocsWithChildCalloutsIds = new Set<Id>();//Note - This will only store related child OC's with a matching DET
            if(!isAsyncImmediate){
                for(List<OutboundCallout__c> ocList : dataEventTypeToOutboundRecords.values()){
                    for(OutboundCallout__c oc : ocList){
                        ocIds.add(oc.Id);
                    } 
                }
                for(OutboundCallout__c blockedOC : [Select Id, BlockedBy__c, DataEventType__c, BlockedBy__r.DataEventType__c From OutboundCallout__c Where BlockedBy__c In:ocIds]){
                    if(!ocsWithChildCalloutsIds.contains(blockedOC.BlockedBy__c) && blockedOC.DataEventType__c == blockedOC.BlockedBy__r.DataEventType__c) ocsWithChildCalloutsIds.add(blockedOC.BlockedBy__c);
                }
            }

            Map<String,DataEventType__mdt> nameToDataEventType = new Map<String,DataEventType__mdt>();//1.37+
            Map<String,DataEventType__mdt> nameToDeferredDataEventType = new Map<String,DataEventType__mdt>();//1.32+
            Map<String,List<CustomHeader__mdt>> nameToCustomHeaders = new Map<String,List<CustomHeader__mdt>>();//1.40+

            for (DataEventType__mdt det : [select Id,DeveloperName,ObjectType__c,RequestType__c,TransactionType__c,ExternalSystem__c,
                                                DataOperationType__c,IsBulk__c,MaxRecordsPerBulkPayload__c,
                                                EndpointPathFormatString__c,EndpointPathFormatStringFields__c,
                                                RequestFormat__c,RequestFormatFields__c,
                                                HTTPMethod__c,ContentType__c,NamedCredentials__c,                                                                                               
                                                RequestHandler__c,ResponseHandler__c,CalloutTimeout__c,
                                                MinBatchSize__c,MaxBatchSize__c,DelegateDataEventTypeName__c,
                                                FlowResponseHandler__c, ReshapedPayloadType__c,IsDeferredFormats__c,
                                                IsCustomAuthenticationProtocol__c,AuthenticationBodyFormatString__c,
                                                AuthenticationCredential1__c,AuthenticationCredential2__c,
                                                AuthenticationEndpointPathFormatString__c,AuthenticationExpiredStatusCode__c,
                                                AuthenticationHeaderFormatString__c,AuthenticationRequestContentType__c,
                                                AuthenticationRequestHttpMethod__c,AuthenticationResponseTokenPath__c,
                                                AuthenticationTokenCacheTTLSeconds__c,AuthenticationRequestEncoding__c,FinalActivityHandler__c,//1.42+
                                                AuthenticationContentTypeAccept__c,ContentTypeAccept__c,//1.46+
                                                AuthenticationNamedCredentials__c,//1.48+
                                                FlowResponseHandlerADT__c,//1.54+
                                                IsRetryOnTimeout__c,//1.49+
                                                IsIgnoreTimeouts__c,//1.51+
                                                (Select Id, Key__c, Value__c From CustomHeaders__r)//1.40+                                                
                                            from DataEventType__mdt
                                            where IsTest__c=:Test.isRunningTest()
                                                and (TransactionType__c=:Label.Picklist_Value_Data_Event_Transaction_Type_Asynchronous_Queue
                                                    or TransactionType__c=:Label.Picklist_Value_Data_Event_Transaction_Type_Asynchronous_Immediate)
                                                and DeveloperName in:dataEventTypeToOutboundRecords.keySet()                                                            
                                            order by DeveloperName asc]){//1.32+ -- include inactive DET. 1.37~

                nameToDataEventType.put(det.DeveloperName,det);//1.37+
                if (det.IsDeferredFormats__c && (String.isNotBlank(det.EndpointPathFormatString__c) || String.isNotBlank(det.RequestFormat__c))) nameToDeferredDataEventType.put(det.DeveloperName,det);//1.37~
                if (det.CustomHeaders__r.size()>0){//1.40+
                    if(!nameToCustomHeaders.containsKey(det.DeveloperName)) nameToCustomHeaders.put(det.DeveloperName,new List<CustomHeader__mdt>());
                    nameToCustomHeaders.get(det.DeveloperName).addAll(det.CustomHeaders__r);
                }
            }

            IDataEventTypeResponseHandler responseHandler;
            IDataEventTypeResponseHandler2 responseHandler2;//1.44+
            IDataEventTypeResponseHandler3 responseHandler3;//1.47+
            IDataEventTypeFinalActivityHandler finalActivityHandler;//1.42+
            Type t;
            Type t2;//1.42+

            Http outboundHttp = new Http();
            HttpRequest outboundHttpRequest;
            HttpResponse outboundHttpResponse;

            List<System.Exception> exceptionsToLog = new List<System.Exception>();//1.18+
            String responseBody;//1.27+

            DataEventType__mdt dataEventType;//1.37+
            DataEventType__mdt deferredDataEventType;//1.32+
            Map<String, Map<Id,List<String>>> detToRecordIdToDynamicStrings = new Map<String, Map<Id,List<String>>>();//1.32+
            Set<Id> recordIds = new Set<Id>();//1.32+
            
            for (String dataEventTypeDeveloperName : dataEventTypeToOutboundRecords.keySet()){       
                if (!nameToDataEventType.containsKey(dataEventTypeDeveloperName)) continue;//1.37+

                dataEventType = nameToDataEventType.get(dataEventTypeDeveloperName);//1.37+
                
                deferredDataEventType = nameToDeferredDataEventType.containsKey(dataEventTypeDeveloperName) ? nameToDeferredDataEventType.get(dataEventTypeDeveloperName) : null;
                
                if (deferredDataEventType!=null){
                    
                    recordIds = new Set<Id>();

                    for (OutboundCallout__c oc : dataEventTypeToOutboundRecords.get(dataEventTypeDeveloperName)){ recordIds.add(oc.RecordId__c); }

                    detToRecordIdToDynamicStrings.put( deferredDataEventType.DeveloperName, FormatStringHelper.buildDynamicStringsForDataEventType(deferredDataEventType, recordIds) );
                }
                    
                responseHandler=null;
                responseHandler2=null;//1.44+
                responseHandler3=null;//1.47+
            
                if (String.isNotBlank(dataEventTypeToOutboundRecords.get(dataEventTypeDeveloperName)[0].ResponseHandler__c)){//Use the first Outbound callout for the DET.

                    try {

                        if (String.isNotBlank(dataEventTypeToOutboundRecords.get(dataEventTypeDeveloperName)[0].ResponseHandler__c)){
                            t=Type.forName(null,dataEventTypeToOutboundRecords.get(dataEventTypeDeveloperName)[0].ResponseHandler__c);
                            
                            if (IDataEventTypeResponseHandler.class.isAssignableFrom(t)){
                                responseHandler = (IDataEventTypeResponseHandler)t.newInstance();
                            } else if (IDataEventTypeResponseHandler2.class.isAssignableFrom(t)){
                                responseHandler2 = (IDataEventTypeResponseHandler2)t.newInstance();
                            } else if (IDataEventTypeResponseHandler3.class.isAssignableFrom(t)){//1.47+
                                responseHandler3 = (IDataEventTypeResponseHandler3)t.newInstance();
                            }
                        }

                    } catch(Exception ex){ exceptionsToLog.add(ex); }//1.18~
                }
                
                for (OutboundCallout__c oc : dataEventTypeToOutboundRecords.get(dataEventTypeDeveloperName)){

                    if (deferredDataEventType!=null && String.isNotBlank(oc.RecordId__c)){//1.32 -- overwrite Endpoint and Body for DET with deferred formats.
                    
                        if (detToRecordIdToDynamicStrings.containsKey(deferredDataEventType.DeveloperName)
                            && detToRecordIdToDynamicStrings.get(deferredDataEventType.DeveloperName).containsKey(oc.RecordId__c)
                            && !detToRecordIdToDynamicStrings.get(deferredDataEventType.DeveloperName).get(oc.RecordId__c).isEmpty()){
                                
                            if (String.isNotBlank(detToRecordIdToDynamicStrings.get(deferredDataEventType.DeveloperName).get(oc.RecordId__c)[0])){
                                oc.Endpoint__c = 'callout:'+deferredDataEventType.NamedCredentials__c;//1.33+
                                oc.Endpoint__c+=detToRecordIdToDynamicStrings.get(deferredDataEventType.DeveloperName).get(oc.RecordId__c)[0];
                            }

                            if (detToRecordIdToDynamicStrings.get(deferredDataEventType.DeveloperName).get(oc.RecordId__c).size()>1 && String.isNotBlank(detToRecordIdToDynamicStrings.get(deferredDataEventType.DeveloperName).get(oc.RecordId__c)[1])){
                                oc.Body__c = detToRecordIdToDynamicStrings.get(deferredDataEventType.DeveloperName).get(oc.RecordId__c)[1];
                            }
                        }
                    }

                    outboundHttpRequest = new HttpRequest();
                    outboundHttpRequest.setTimeout( (oc.CalloutTimeout__c==null || oc.CalloutTimeout__c==0) ? calloutTimeout : (Integer)oc.CalloutTimeout__c );//1.16+ 1.20~
                    outboundHttpRequest.setEndpoint(oc.Endpoint__c);
                    outboundHttpRequest.setMethod(oc.Method__c);
                    outboundHttpRequest.setHeader('Content-Type', oc.ContentTypeHeader__c);
                    outboundHttpRequest.setHeader('Accept', oc.AcceptHeader__c);
                    if(oc.Body__c != null) outboundHttpRequest.setBody(oc.Body__c);  //1.11~  - cannot set body if null (i.e. Webhook)
                    outboundHttpRequest.setHeader('Content-Length', (oc.Body__c == null)?'0':String.valueOf(oc.Body__c.length())); //1.11+ - must specify Content-Length if no body is specified (zero) //1.39+

                    if(oc.DataEventType__c != null && nameToCustomHeaders.containsKey(oc.DataEventType__c)){
                        for(CustomHeader__mdt ch : nameToCustomHeaders.get(oc.DataEventType__c)){
                            if(ch.Key__c == null || ch.Value__c == null) continue;
                            outboundHttpRequest.setHeader(ch.Key__c,ch.Value__c);
                        }
                    }


                    try {//1.17+
                        
                        if (dataEventType.IsCustomAuthenticationProtocol__c)//1.37+
                            outboundHttpResponse = CustomAuthenticationHelper.authenticatedSend(dataEventType, outboundHttpRequest);
                        else outboundHttpResponse = outboundHttp.send(outboundHttpRequest);
                        
                    } catch(Exception ex){
                        
                        if (!isAsyncImmediate && dataEventType.IsIgnoreTimeouts__c && ex.getMessage().containsIgnoreCase('Read timed out')){//1.51+ 1.53~ -- added isAsyncImmediate condition.
                            outboundCalloutToIsRetry.put(oc,false);
                            continue;
                        } else if (!isAsyncImmediate && dataEventType.IsRetryOnTimeout__c && ex.getMessage().containsIgnoreCase('Read timed out')){//1.53+
                            outboundCalloutToIsRetry.put(oc,true);
                            continue;
                        }

                        exceptionsToLog.add(ex);//1.18+

                        if (!isAsyncImmediate 
                            && ex.getTypeName().equalsIgnoreCase('CalloutException')
                            && (ex.getMessage().containsIgnoreCase('More than 20 connections opened to server') 
                                || ex.getMessage().containsIgnoreCase('You have uncommitted work pending'))){//1.45+ 1.49~ 1.53- retry timeouts moved above.
                            
                            outboundCalloutToIsRetry.put(oc,true);

                        } else {

                            oc.Status__c = Label.Picklist_Value_OutboundCallout_Status_Aborted;//1.21+
                            oc.AbortReason__c = Label.Picklist_Value_OutboundCallout_Abort_Reason_Runtime_Error;
                            oc.ResponseBody__c = ex.getMessage();

                            outboundCalloutToIsRetry.put(oc,false);
                        }
                        if (isAsyncImmediate) outboundCalloutToIsSuccess.put(oc,false);//1.21~
                                                
                        continue;// next oc.
                    } 
                    
                    if (responseHandler!=null) responseHandler.handleOutboundResponse(outboundHttpResponse);

                    oc.ResponseStatusCode__c = outboundHttpResponse.getStatusCode();
                    String resBody = outboundHttpResponse.getBody();//1.41+
                    oc.ResponseBody__c = (resBody != null && !String.isBlank(resBody) && resBody.length()>5000)?resBody.left(5000)+'...':resBody;//1.41+
                    oc.LastCalloutDate__c = Datetime.now();

                    responseBody = outboundHttpResponse.getBody();//1.27+

                    if (isRetryHttpResponse(outboundHttpResponse)){//1.22~
                        outboundCalloutToIsRetry.put(oc,true);// -- remember the Sobject key is a hash so subsequent changes will affect keySet access.
                    } else {
                        if (isSuccessHttpResponse(outboundHttpResponse)){                            
                            
                            //1.26+ -- Convert ResponseBody to ReshapedPayloadBody (Async+AsyncImmediate)
                            oc.ReshapedPayloadBody__c = reshapedPayloadBody(oc.ReshapedPayloadType__c,oc.ResponseBody__c);

                            if (responseHandler3!=null){//1.47+
                                responseHandler3.handleOutboundResponse(outboundHttpResponse,oc.ReshapedPayloadBody__c,oc.Id,(oc.RecordId__c!=null)?new Set<Id>{oc.RecordId__c}:null);

                            } else if (responseHandler2!=null){
                                responseHandler2.handleOutboundResponse(outboundHttpResponse,oc.ReshapedPayloadBody__c,oc.Id);

                            } else if (responseHandler==null
                                && String.isNotBlank(oc.FlowResponseHandler__c)
                                && ((String.isNotBlank(oc.ReshapedPayloadType__c) && String.isNotBlank(oc.ReshapedPayloadBody__c)) 
                                    || (String.isNotBlank(dataEventType.FlowResponseHandlerADT__c) ))){//1.26+ -- Create Flow Interview if no Apex Handler and FlowResponseHandler set. 1.54~                                  
                                
                                FlowResult fr = invokeFlowResponseHandler(oc.FlowResponseHandler__c, oc.ReshapedPayloadType__c, outboundHttpResponse, oc, dataEventType.FlowResponseHandlerADT__c);//1.27~ 1.54~
                            
                                if (isAsyncImmediate) outboundCalloutToIsSuccess.put(oc,fr.isSuccess);//1.27+
                                if (String.isNotBlank(fr.errorMessage)) oc.ResponseBody__c = fr.errorMessage;//1.27+
                            
                            } else { if (isAsyncImmediate) outboundCalloutToIsSuccess.put(oc,true); }//<-- be careful using objects as map keys, the key becomes a hash of the original state.

                        } else {
                            if (isAsyncImmediate) outboundCalloutToIsSuccess.put(oc,false);
                            if (!isAsyncImmediate) oc.Status__c = Label.Picklist_Value_OutboundCallout_Status_Aborted;//<--- OutboundCalloutProcessor will not overwrite this status.
                        }
                        outboundCalloutToIsRetry.put(oc,false);
                        //1.42 - Invoke the handler responsible for final activity following the callout. To be executed for the final callout in a sequence (only). 
                        if(dataEventType.FinalActivityHandler__c != null && !ocsWithChildCalloutsIds?.contains(oc.Id)){
                            try {
                                t2=Type.forName(null,dataEventType.FinalActivityHandler__c);
                                finalActivityHandler = (IDataEventTypeFinalActivityHandler)t2.newInstance();   
                                if(finalActivityHandler != null) finalActivityHandler.execute(dataEventType, oc);     
                            } catch(Exception ex){ exceptionsToLog.add(ex); }//1.18~
                        }

                    }                
                }//oc
            }//dataEventTypeDeveloperName

            if (isAsyncImmediate){//1.18~

                List<OutboundCalloutEvent__e> outboundCalloutEvents = new List<OutboundCalloutEvent__e>();//1.8+

                for (OutboundCallout__c oc : outboundCalloutToIsRetry.keySet()){//1.8+
                    if (outboundCalloutToIsRetry.get(oc)){// -- retry=true
                        outboundCalloutEvents.add(new OutboundCalloutEvent__e(Endpoint__c=oc.Endpoint__c,
                                                                                Method__c=oc.Method__c,
                                                                                ContentTypeHeader__c=oc.ContentTypeHeader__c,
                                                                                AcceptHeader__c=oc.AcceptHeader__c,
                                                                                CalloutTimeout__c=oc.CalloutTimeout__c,
                                                                                Body__c=oc.Body__c,
                                                                                DataEventType__c=oc.DataEventType__c,
                                                                                ResponseHandler__c=oc.ResponseHandler__c,
                                                                                ResponseBody__c=oc.ResponseBody__c,
                                                                                FlowResponseHandler__c=oc.FlowResponseHandler__c,
                                                                                ReshapedPayloadType__c=oc.ReshapedPayloadType__c,
                                                                                ReshapedPayloadBody__c=oc.ReshapedPayloadBody__c,
                                                                                Status__c=Label.Picklist_Value_OutboundCallout_Status_New,
                                                                                ResponseStatusCode__c=String.valueOf(oc.ResponseStatusCode__c),
                                                                                RecordId__c=oc.RecordId__c) );//1.20~ 1.26~
                    } else if(outboundCalloutToIsSuccess.get(oc)){//1.12+ - Log Successes to Outbound Callout Queue (better visibility means more confidence there are no silent failures)
                        outboundCalloutEvents.add(new OutboundCalloutEvent__e(Endpoint__c=oc.Endpoint__c,
                                                                                Method__c=oc.Method__c,
                                                                                ContentTypeHeader__c=oc.ContentTypeHeader__c,
                                                                                AcceptHeader__c=oc.AcceptHeader__c,
                                                                                CalloutTimeout__c=oc.CalloutTimeout__c,
                                                                                Body__c=oc.Body__c,
                                                                                DataEventType__c=oc.DataEventType__c,
                                                                                ResponseHandler__c=oc.ResponseHandler__c,
                                                                                RecordId__c=oc.RecordId__c,
                                                                                ResponseBody__c=oc.ResponseBody__c,
                                                                                FlowResponseHandler__c=oc.FlowResponseHandler__c,
                                                                                ReshapedPayloadType__c=oc.ReshapedPayloadType__c,
                                                                                ReshapedPayloadBody__c=oc.ReshapedPayloadBody__c,
                                                                                Status__c=Label.Picklist_Value_OutboundCallout_Status_Complete,
                                                                                ResponseStatusCode__c=String.valueOf(oc.ResponseStatusCode__c)
                                                                                ));//1.20~ 1.26~
                    } else {//1.12+ - Status code is not recognised as success or retry - Log Aborted OutboundCallouts
                        outboundCalloutEvents.add(new OutboundCalloutEvent__e(Endpoint__c=oc.Endpoint__c,
                                                                                Method__c=oc.Method__c,
                                                                                ContentTypeHeader__c=oc.ContentTypeHeader__c,
                                                                                AcceptHeader__c=oc.AcceptHeader__c,
                                                                                CalloutTimeout__c=oc.CalloutTimeout__c,
                                                                                Body__c=oc.Body__c,
                                                                                DataEventType__c=oc.DataEventType__c,
                                                                                ResponseHandler__c=oc.ResponseHandler__c,
                                                                                RecordId__c=oc.RecordId__c,
                                                                                ResponseBody__c=oc.ResponseBody__c,
                                                                                FlowResponseHandler__c=oc.FlowResponseHandler__c,
                                                                                ReshapedPayloadType__c=oc.ReshapedPayloadType__c,
                                                                                ReshapedPayloadBody__c=oc.ReshapedPayloadBody__c,
                                                                                Status__c=Label.Picklist_Value_OutboundCallout_Status_Aborted,
                                                                                AbortReason__c=String.isNotBlank(oc.AbortReason__c) ? oc.AbortReason__c : Label.Picklist_Value_OutboundCallout_Abort_Reason_No_Retries,
                                                                                ResponseStatusCode__c=String.valueOf(oc.ResponseStatusCode__c)
                                                                                ));//1.19~ 1.20~ 1.26~
                    }
                }
                if (!outboundCalloutEvents.isEmpty()){//1.8+

                    List<Database.SaveResult> saveResults = EventBus.publish(outboundCalloutEvents);
                    LogHelper.logExceptions(saveResults, 'DataEventTypeManager', 'processDataEventTypes', outboundCalloutEvents);
                }
            }
            if (!exceptionsToLog.isEmpty()){//1.18+
                for (System.Exception ex : exceptionsToLog) LogHelper.logExceptions(ex, 'DataEventTypeManager', 'processDataEventTypes');
            }
            
        } catch(Exception ex){ LogHelper.logExceptions(ex, 'DataEventTypeManager', 'processDataEventTypes'); }
        return outboundCalloutToIsRetry;
    }

    private Boolean isSuccessHttpResponse(HttpResponse r){//1.5~
        if (successStatusCodes.isEmpty()){
            FrameworkSettings__c  settings = FrameworkSettings__c.getOrgDefaults();

            if (settings==null || String.isBlank(settings.OutboundCalloutSuccessStatusCodes__c)){
                successStatusCodes.add(200);
            } else {
                for (String c : settings.OutboundCalloutSuccessStatusCodes__c.split(',')){ if (c.isNumeric()) successStatusCodes.add(Integer.valueOf(c)); }
            }
        }
        return (successStatusCodes.contains(r.getStatusCode()));
    }

    private Boolean isRetryHttpResponse(HttpResponse r){//1.5~ 
        if (retryStatusCodes.isEmpty()){
            FrameworkSettings__c  settings = FrameworkSettings__c.getOrgDefaults();

            if (settings==null || String.isBlank(settings.OutboundCalloutRetryStatusCodes__c)){
                retryStatusCodes.add(423);
            } else {
                for (String c : settings.OutboundCalloutRetryStatusCodes__c.split(',')){ if (c.isNumeric()) retryStatusCodes.add(Integer.valueOf(c)); }
            }
        }
        return (retryStatusCodes.contains(r.getStatusCode()));
    }

    private String getDynamicPlaceHolderFormattedEndPointPath(Id masterRecordId, String endPointPath){//1.9+
        try {

            if (endpointPath.containsIgnoreCase('[masterrecordid]')){
                endpointPath = endpointPath.replace('[masterrecordid]', (String)masterRecordId);//1.13~
            }

            if (masterRecordIdToSourceRecordIds.containsKey(masterRecordId) && endpointPath.containsIgnoreCase('[sourcerecordids]')){
                endpointPath = endpointPath.replace('[sourcerecordids]', String.join(new List<Id>( masterRecordIdToSourceRecordIds.get(masterRecordId) ),'-'));//1.13~
            }
            
        } catch(Exception ex){ LogHelper.logExceptions(ex, 'DataEventTypeManager', 'getMergeFormattedEndPointPath'); }
        
        return endPointPath;
    }

    @future(callout=true)
    public static void processAsyncImmediateCallouts(List<String> eventsAsJSON){
        try {

            Map<String, List<OutboundCallout__c>> dataEventTypeToOutboundCallouts = new Map<String, List<OutboundCallout__c>>();
            
            OutboundCallout__c oc;

            for (String sj : eventsAsJSON){
            
                oc = (OutboundCallout__c)JSON.deserialize(sj,OutboundCallout__c.class);

                if (!dataEventTypeToOutboundCallouts.containsKey(oc.DataEventType__c)) dataEventTypeToOutboundCallouts.put(oc.DataEventType__c,new List<OutboundCallout__c>());                
                dataEventTypeToOutboundCallouts.get(oc.DataEventType__c).add(oc);
            }
            if (dataEventTypeToOutboundCallouts.isEmpty()) return;

            DataEventTypeManager detm = new DataEventTypeManager();
            Map<OutboundCallout__c,Boolean> outboundCalloutToResult = detm.processDataEventTypes(dataEventTypeToOutboundCallouts,true);//1.8~

            //1.19- Code below assumed a persisted OC state.
            // Set<Id> processedIds = new Set<Id>();//1.17+

            // for (OutboundCallout__c ocToCheck : outboundCalloutToResult.keySet()){ processedIds.add(ocToCheck.Id); }

            // List<OutboundCallout__c> ocToAbort = new List<OutboundCallout__c>();//1.17+ -- abort any OC where no processed return.

            // for (String dataEventType : dataEventTypeToOutboundCallouts.keySet()){
            //     for (OutboundCallout__c ocToCheck : dataEventTypeToOutboundCallouts.get(dataEventType)){

            //         if (!processedIds.contains(ocToCheck.Id)){
            //             ocToCheck.Status__c = Label.Picklist_Value_OutboundCallout_Status_Aborted;
            //             ocToCheck.AbortReason__c = Label.Picklist_Value_OutboundCallout_Abort_Reason_Runtime_Error;
            //             ocToCheck.NextRetryDate__c = null;

            //             ocToAbort.add(ocToCheck);
            //         }
            //     }
            // }
            // if (!ocToAbort.isEmpty()){//1.17+ 
            //     List<Database.SaveResult> saveResults = Database.update( ocToAbort );
            //     LogHelper.logExceptions(saveResults, 'DataEventTypeManager', 'processAsyncImmediateCallouts', ocToAbort);
            // } 1.19-

        } catch(Exception ex){ LogHelper.logExceptions(ex, 'DataEventTypeManager', 'processAsyncImmediateCallouts'); }
    }

    private FlowResult invokeFlowResponseHandler(String flowResponseHandler, String reshapedPayloadType, HttpResponse outboundHttpResponse, String flowResponseHandlerADT){//1.26+ 1.27~ 1.54~
        return invokeFlowResponseHandler(flowResponseHandler, reshapedPayloadType, outboundHttpResponse, null, flowResponseHandlerADT);
    } 

    private FlowResult invokeFlowResponseHandler(String flowResponseHandler, String reshapedPayloadType, HttpResponse outboundHttpResponse, OutboundCallout__c oc, String flowResponseHandlerADT ){//1.26+ 1.27~ 1.54~
        //1.26+ -- Sync=No OC, so reshape getBody(), Async+AsyncImmediate=OC, so use ReshapedPayloadBody__c if set.
        
        FlowResult fr = new FlowResult();//1.27+
        
        if (String.isBlank(flowResponseHandler) || (String.isBlank(flowResponseHandlerADT) && (String.isBlank(reshapedPayloadType) && String.isBlank(oc.ReshapedPayloadBody__c)))) return fr; //1.54~
        String reshapedPayloadBody;
        Object responseData;

        Map<String, Object> params = new Map<String, Object>();//1.54+

        if(String.isBlank(flowResponseHandlerADT)){//1.54+
            //Reshaped payload path
            reshapedPayloadBody = oc!=null && String.isNotBlank(oc.ReshapedPayloadBody__c) ? oc.ReshapedPayloadBody__c : reshapedPayloadBody(reshapedPayloadType,outboundHttpResponse.getBody());
            if (String.isBlank(reshapedPayloadBody)) return fr;
            if (oc!=null && String.isNotBlank(oc.Id)) params.put('outboundCalloutId',oc.Id);
            params.put('reshapedPayloadBody', reshapedPayloadBody);
        }else{//1.54+
            //Apex defined type path
            responseData = JSON.deserialize(outboundHttpResponse.getBody(), Test.isRunningTest()?DataEventTypeManagerTest.ADTTest.class:Type.forName(flowResponseHandlerADT));
            params.put('responseData',responseData);//Flow must have 'responseData' input variable of specified apex defined data type
            if(Test.isRunningTest() && responseData != null) flowADTData = responseData;
        }
        //if (String.isBlank(reshapedPayloadBody)) return fr; //1.54- moved above

        try {
            //1.54- Relocated above (Reshaped payload path)
            //Map<String, Object> params = new Map<String, Object>();                                            
            //if (oc!=null && String.isNotBlank(oc.Id)) params.put('outboundCalloutId',oc.Id);
            //params.put('reshapedPayloadBody', reshapedPayloadBody);

            if (Test.isRunningTest()){//1.27~
                fr.isSuccess = true;
            } else {
                Flow.Interview flowHandler = Flow.Interview.createInterview(flowResponseHandler,params);
                flowHandler.start();

                fr.isSuccess = (Boolean)flowHandler.getVariableValue('isSuccess');                    
                fr.errorMessage = (String)flowHandler.getVariableValue('errorMessage');    
            }        
        
        } catch (Exception ex){ LogHelper.logExceptions(ex, 'DataEventTypeManager', 'invokeFlowResponseHandler'); }
        return fr;
    }

    private String reshapedPayloadBody(String reshapedPayloadTypeId, String jsonResponseBody){

        if (String.isBlank(reshapedPayloadTypeId) || String.isBlank(jsonResponseBody)) return '';

        try {

            if (idToReshapedPayloadTypeId==null) idToReshapedPayloadTypeId = new Map<Id,ReshapedPayloadType__mdt>([select Id, DeveloperName, ResponseObjectPath__c from ReshapedPayloadType__mdt]);//1.44+
            if (!idToReshapedPayloadTypeId.containsKey(reshapedPayloadTypeId)) return '';//1.44+

            if (reshapedPayloadTypeIdToMappings==null) reshapedPayloadTypeIdToMappings = new Map<Id,List<ReshapedPayloadMapping__mdt>>();

            if (!reshapedPayloadTypeIdToMappings.containsKey(reshapedPayloadTypeId)){
                
                reshapedPayloadTypeIdToMappings.put(reshapedPayloadTypeId,new List<ReshapedPayloadMapping__mdt>());

                for (ReshapedPayloadMapping__mdt rpm : [select Id, ADTPropertyName__c, ResponseValuePath__c from ReshapedPayloadMapping__mdt where ReshapedPayloadType__c=:reshapedPayloadTypeId]){
                    reshapedPayloadTypeIdToMappings.get(reshapedPayloadTypeId).add(rpm);
                }
            }

            // --> ResponseObjectPath__c points to a list within the JSON - each object in the list will be reshaped using the rules and added to a list which is serialised.
            // [get>data>Map],[get>all_locations>Map],[get>items>end]
            //{
            //    "data": {
            //        "all_location": {
            //            "items": [

            //[get>records>list],[index>0>Map],[get>RecordType>Map],[get>DeveloperName>end]
            //{"totalSize":1,"done":true,"records":[
                // {"attributes":
                //   {"type":"Account","url":"/services/data/v47.0/sobjects/Account/0013z00002NxvQ9AAJ"},
                //   "Id":"0013z00002NxvQ9AAJ","FirstName":"Nathan","LastName":"Burgess",
                //    "RecordType":{"attributes":{"type":"RecordType","url":"/services/data/v47.0/sobjects/RecordType/012b00000009VrWAAU"},"DeveloperName":"Job_Applicant"}
                //}
                //]
            //}

            Map<String,Object> propertyNameToObject = new Map<String,Object>();
            List<String> tokens = new List<String>();

            jsonResponseBody = escapeSpecialCharacters(jsonResponseBody);//1.35+

            Object currentObject, originalObject = (Map<String,Object>)JSON.deserializeUntyped(jsonResponseBody);//1.27~
            
            Map<String,Object> currentMap;
            List<Object> currentList;
            String actionToken,nameOrIndexToken,typeToken;

            if (idToReshapedPayloadTypeId.get(reshapedPayloadTypeId).ResponseObjectPath__c!=null){//1.44+

                currentObject = originalObject;

                for (String objectPathElem : idToReshapedPayloadTypeId.get(reshapedPayloadTypeId).ResponseObjectPath__c.split(',')){
                        
                    tokens = objectPathElem.split('>');// .. [0]=get|index [1]=[index]|[name] [2]=list|map|end
                    if (tokens.size()<>3) break;

                    actionToken = tokens[0].removeStart('[');
                    nameOrIndexToken = tokens[1];
                    typeToken = tokens[2].removeEnd(']');
                    
                    if ((actionToken.equalsIgnoreCase('get') &&
                        currentObject instanceof Map<String,Object>) ||
                        (actionToken.equalsIgnoreCase('index') &&
                        currentObject instanceof List<Object>)){

                        currentMap = (actionToken.equalsIgnoreCase('get')) ? (Map<String,Object>)currentObject : null;
                        currentList = (actionToken.equalsIgnoreCase('index')) ? (List<Object>)currentObject : null;
                        
                        switch on typeToken {
                            when 'list','LIST','List' {
                                if (currentMap!=null) currentObject = (List<Object>)currentMap.get(nameOrIndexToken);
                                else if (currentList!=null) currentObject = (List<Object>)currentList.get(Integer.valueOf(nameOrIndexToken));
                            }
                            when 'map','MAP','Map' {
                                if (currentMap!=null) currentObject = (Map<String,Object>)currentMap.get(nameOrIndexToken);
                                else if (currentList!=null) currentObject = (Map<String,Object>)currentList.get(Integer.valueOf(nameOrIndexToken));
                            }
                            when 'end','END','End' {
                                
                                if (currentObject!=null && currentMap.get(nameOrIndexToken) instanceof List<Object>){

                                    currentList = (List<Object>)currentMap.get(nameOrIndexToken);

                                    List<Map<String,Object>> propertyNameToObjectList = new List<Map<String,Object>>();
                                    
                                    for (Object currentObjectInList : currentList){

                                        propertyNameToObject = new Map<String,Object>();

                                        originalObject = currentObjectInList;

                                        for (ReshapedPayloadMapping__mdt rpm : reshapedPayloadTypeIdToMappings.get(reshapedPayloadTypeId)){

                                            currentObjectInList = originalObject;
                        
                                            for (String valuePathElem : rpm.ResponseValuePath__c.split(',')){// .. [get>records>list]
                                                
                                                tokens = valuePathElem.split('>');// .. [0]=get|index [1]=[index]|[name] [2]=list|map|end
                                                if (tokens.size()<>3) break;
                        
                                                actionToken = tokens[0].removeStart('[');
                                                nameOrIndexToken = tokens[1];
                                                typeToken = tokens[2].removeEnd(']');
                                                
                                                if ((actionToken.equalsIgnoreCase('get') &&
                                                    currentObjectInList instanceof Map<String,Object>) ||
                                                    (actionToken.equalsIgnoreCase('index') &&
                                                    currentObjectInList instanceof List<Object>)){
                        
                                                    currentMap = (actionToken.equalsIgnoreCase('get')) ? (Map<String,Object>)currentObjectInList : null;
                                                    currentList = (actionToken.equalsIgnoreCase('index')) ? (List<Object>)currentObjectInList : null;
                                                    
                                                    switch on typeToken {
                                                        when 'list','LIST','List' {
                                                            if (currentMap!=null) currentObjectInList = (List<Object>)currentMap.get(nameOrIndexToken);
                                                            else if (currentList!=null) currentObjectInList = (List<Object>)currentList.get(Integer.valueOf(nameOrIndexToken));
                                                        }
                                                        when 'map','MAP','Map' {
                                                            if (currentMap!=null) currentObjectInList = (Map<String,Object>)currentMap.get(nameOrIndexToken);
                                                            else if (currentList!=null) currentObjectInList = (Map<String,Object>)currentList.get(Integer.valueOf(nameOrIndexToken));
                                                        }
                                                        when 'end','END','End' {
                                                            if (currentMap!=null) currentObjectInList = (Object)currentMap.get(nameOrIndexToken);
                                                            else if (currentList!=null) currentObjectInList = (Object)currentList.get(Integer.valueOf(nameOrIndexToken));
                        
                                                            propertyNameToObject.put(rpm.ADTPropertyName__c,currentObjectInList);
                                                            break;
                                                        }
                                                    }
                                                }
                                            }
                                        }//reshapedPayloadMapping

                                        //[Removed for release] System.debug(LoggingLevel.ERROR, 'FINDME>propertyNameToObject='+propertyNameToObject);
                                        
                                        if (!propertyNameToObject.isEmpty()) propertyNameToObjectList.add(propertyNameToObject);
                                        
                                    }//object in list

                                    //[Removed for release] System.debug(LoggingLevel.ERROR, 'FINDME>propertyNameToObjectList='+propertyNameToObjectList);
                                    return JSON.serialize(propertyNameToObjectList); 
                                }                         
                                break;//to next object in list.
                            }
                        }
                    }
                }//element in ResponseObjectPath__c           

            } else {

                for (ReshapedPayloadMapping__mdt rpm : reshapedPayloadTypeIdToMappings.get(reshapedPayloadTypeId)){

                    currentObject = originalObject;

                    for (String valuePathElem : rpm.ResponseValuePath__c.split(',')){// .. [get>records>list]
                        
                        tokens = valuePathElem.split('>');// .. [0]=get|index [1]=[index]|[name] [2]=list|map|end
                        if (tokens.size()<>3) break;

                        actionToken = tokens[0].removeStart('[');
                        nameOrIndexToken = tokens[1];
                        typeToken = tokens[2].removeEnd(']');
                        
                        if ((actionToken.equalsIgnoreCase('get') &&
                            currentObject instanceof Map<String,Object>) ||
                            (actionToken.equalsIgnoreCase('index') &&
                            currentObject instanceof List<Object>)){

                            currentMap = (actionToken.equalsIgnoreCase('get')) ? (Map<String,Object>)currentObject : null;
                            currentList = (actionToken.equalsIgnoreCase('index')) ? (List<Object>)currentObject : null;
                            
                            switch on typeToken {
                                when 'list','LIST','List' {
                                    if (currentMap!=null) currentObject = (List<Object>)currentMap.get(nameOrIndexToken);
                                    else if (currentList!=null) currentObject = (List<Object>)currentList.get(Integer.valueOf(nameOrIndexToken));
                                }
                                when 'map','MAP','Map' {
                                    if (currentMap!=null) currentObject = (Map<String,Object>)currentMap.get(nameOrIndexToken);
                                    else if (currentList!=null) currentObject = (Map<String,Object>)currentList.get(Integer.valueOf(nameOrIndexToken));
                                }
                                when 'end','END','End' {
                                    if (currentMap!=null) currentObject = (Object)currentMap.get(nameOrIndexToken);
                                    else if (currentList!=null) currentObject = (Object)currentList.get(Integer.valueOf(nameOrIndexToken));

                                    propertyNameToObject.put(rpm.ADTPropertyName__c,currentObject);
                                    break;
                                }
                            }
                        }
                    }
                }
                //[Removed for release] System.debug(LoggingLevel.ERROR, 'FINDME>propertyNameToObject='+propertyNameToObject);
                if (!propertyNameToObject.isEmpty()) return JSON.serialize(propertyNameToObject);
            }

        } catch (Exception ex){ LogHelper.logExceptions(ex, 'DataEventTypeManager', 'reshapedPayloadBody'); }
        return '';
    }

    private String escapeSpecialCharacters(String jsonString){//1.35+
        jsonString = jsonString.replace('\n','\\n');
        jsonString = jsonString.replace('\r','\\r');
        jsonString = jsonString.replace('\\',' ');

        return jsonString;
    }

     //1.25+
     public static List<String> getReshapedPayloads(Set<Id> outboundCalloutIds){
        try{
            List<OutboundCallout__c> ocs = [Select Id, ReshapedPayloadBody__c From OutboundCallout__c Where Id In:outboundCalloutIds];
            
            List<String> responses = new List<String>();
            for(OutboundCallout__c oc : ocs){
                responses.add(oc.ReshapedPayloadBody__c);
            }
            return responses;
        } catch(Exception ex){ LogHelper.logExceptions(ex, 'DataEventTypeManager', 'getReshapedPayloads'); }
        return null;
    }

    public class FlowResult {//1.27+
        public Boolean isSuccess { get; set; }
        public String errorMessage { get; set; }

        public FlowResult(){ isSuccess=false; }
    }
}