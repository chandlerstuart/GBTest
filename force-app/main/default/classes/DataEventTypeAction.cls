/*
Name:  DataEventTypeAction.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

ApexAction for the Direct invocation of Data Event Types.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-08-16  Initial development.
1.1  Mark Cane&    2019-10-14  Added processDataEventTypes includeDelegateEvents parameter.
1.2  J Radcliffe   2019-10-22  Bug Fix - An Apex error occurred: System.TypeException: DataEventTypeAction.DataEventTypeActionRequest does not have a no-arg constructor.ApexPages
1.3  Mark Cane&    2020-01-08  Enhancements. Result errorMessage property is now populated.
1.4  Mark Cane&    2020-02-03  Enhancements. Request Body parameter - required for Async Callback Result DET. 
1.5  J Radcliffe   2020-04-30  Bug Fix - Remove blank spaces.
1.6  Mark Cane&    2020-10-07  Enhancements. Added result responseBody property - populated when isSuccess.
1.7  Mark Cane&    2020-10-07  Enhancements. Added request property queryStringParameters to allow values to be passed through.
1.8  Mark Cane&    2022-11-09  Enhancements. Added requestBodyFormat+Values request properties.
1.9  J Radcliffe   2023-01-26  Bug Fix - Reverse flow's encoding i.e. &#124; >>> |
*/
global with sharing class DataEventTypeAction {
    global DataEventTypeAction(){ }

    @InvocableMethod(label='Invoke Direct Data Event Type' description='Create Enquiry Action')
    global static List<DataEventTypeActionResult> invokeDataEventType(List<DataEventTypeActionRequest> detaRequests){
        List<DataEventTypeActionResult> detaResults = new List<DataEventTypeActionResult>();

        try {
            
            Map<String,Map<Id,String>> dataEventTypeToRecordIds = new Map<String,Map<Id,String>>();//1.4~
            Map<Id,String> recordIdToQueryStringParameters = new Map<Id,String>();//1.7+

            for (DataEventTypeActionRequest r : detaRequests){
                r.dataEventType = (r.dataEventType != null)?r.dataEventType.trim():null;//1.5+
                
                if(r.requestBodyFormatValues != null && r.requestBodyFormatValues.contains('&#124;')) r.requestBodyFormatValues.replace('&#124;','|');//1.9+

                if (String.isBlank(r.requestBody)
                    && String.isNotBlank(r.requestBodyFormat)
                    && String.isNotBlank(r.requestBodyFormatValues)){//expect pipe delimited.

                    r.requestBody = FormatStringHelper.getJSONSafeFormatString(r.requestBodyFormat, r.requestBodyFormatValues.split('\\|'));//1.8+
                }

                if (!dataEventTypeToRecordIds.containsKey(r.dataEventType)) dataEventTypeToRecordIds.put(r.dataEventType, new Map<Id,String>());
                dataEventTypeToRecordIds.get(r.dataEventType).put(r.recordId,r.requestBody);//1.4~

                if (String.isNotBlank(r.queryStringParameters)) recordIdToQueryStringParameters.put(r.recordId,r.queryStringParameters);//1.7+
            }
            if (dataEventTypeToRecordIds.isEmpty()) return detaResults;

            DataEventTypeManager detm = new DataEventTypeManager();
            
            if (!recordIdToQueryStringParameters.isEmpty()) detm.recordIdToQueryStringParameters = recordIdToQueryStringParameters;//1.7+

            Map<Id,Map<Boolean,String>> recordIdToResult = detm.processDataEventTypesDetailed(dataEventTypeToRecordIds,true);//1.1~ 1.3~
            DataEventTypeActionResult detaResult;//1.3+
            List<String> responseDetails;//1.6+

            for (DataEventTypeActionRequest r : detaRequests){//1.3~              
                
                detaResult = new DataEventTypeActionResult(r.recordId);

                if (recordIdToResult.containsKey(r.recordId)){
                    detaResult.isSuccess = new List<Boolean>(recordIdToResult.get(r.recordId).keySet())[0];
                    
                    responseDetails = recordIdToResult.get(r.recordId).get(detaResult.isSuccess)!=null ? recordIdToResult.get(r.recordId).get(detaResult.isSuccess).split(DataEventTypeManager.DELIM_TOKEN) : new List<String>();//1.6+

                    if (responseDetails.size()>0) detaResult.responseBody = responseDetails[0];//1.6+
                    if (responseDetails.size()>1) detaResult.errorMessage = responseDetails[1];//1.6+
                        
                } else detaResult.isSuccess = false;

                detaResults.add(detaResult);
            }
        } catch(Exception ex){ LogHelper.logExceptions(ex, 'DataEventTypeAction', 'invokeDataEventType'); }
        return detaResults;
    }

    global class DataEventTypeActionRequest {
        @InvocableVariable
        global String dataEventType;
        
        @InvocableVariable
        global Id recordId;

        @InvocableVariable
        global String requestBody;//1.4+

        @InvocableVariable
        global String queryStringParameters;//1.7+ -- can't use a Map so the qs append must be passed in.       
        
        @InvocableVariable(label='Request Body Format String' description='E.g. {"phoneNumber": "{0}", "accountId": "{1}" }. Note the requestBody property takes precendence.' required=false)
        global String requestBodyFormat;//1.8+
        
        @InvocableVariable(label='Request Body Format Values' description='E.g. +447944888222|0010N00004y9mpVQAQ. Note a pipe delimited string is expected.' required=false)
        global String requestBodyFormatValues;//1.8+

        global DataEventTypeActionRequest(){}//1.2

        global DataEventTypeActionRequest(String dataEventType, Id recordId){
            this.dataEventType = dataEventType;
            this.recordId = recordId;
        }
    }

    global class DataEventTypeActionResult {
        @InvocableVariable
        global Id recordId;
        
        @InvocableVariable
        global Boolean isSuccess;

        @InvocableVariable
        global String errorMessage;//1.3+

        @InvocableVariable
        global String responseBody;//1.6+

        global DataEventTypeActionResult(Id recordId){//1.3+
            this.recordId = recordId;
            this.errorMessage = '';
        }

        global DataEventTypeActionResult(Id recordId, Boolean isSuccess){
            this.recordId = recordId;
            this.isSuccess = isSuccess;
            this.errorMessage = '';
        }
    }
}