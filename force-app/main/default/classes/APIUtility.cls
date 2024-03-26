/**
* @author -         Abrar Haq (Accenture)
* @date -           31/03/2016
* @description -    A utility class for HTTP callouts
* #############Change Log#############
* Modified by     Version     Change Date
**/
public with sharing class APIUtility {
    //Properties
    public static HttpResponse responseForAssertions {get;set;}
    
    public static Set<Integer> setPositiveStatuses = new Set<Integer>{200, 201, 202, 203, 204, 205, 206};

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         31/03/2016
    Version -      1.0 
    Function -     Get full Endpoint URL (including parameters)
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String buildEndPointURL(String baseURL, Map<String, String> mapURLParameters){
        String endPointURL = '';        
        for(String parameterKey : mapURLParameters.keySet()){
            if(endPointURL == ''){
                endPointURL += '?' + parameterKey + '=' + mapURLParameters.get(parameterKey);
            }
            else{
                endPointURL += '&' + parameterKey + '=' + mapURLParameters.get(parameterKey);
            }            
        }
        baseURL += endPointURL;
        return baseURL;
    }

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         31/03/2016
    Version -      1.0 
    Function -     GET Method with full endpoint (including parameters) and no body
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static HttpResponse callOutGet(string url, Map<String, String> mapHTTPHeaders) {
        return callOut(url, 'GET', null, null, null, mapHTTPHeaders);
    }

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         31/03/2016
    Version -      1.0 
    Function -     GET Method with parameters to build and no body
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/    
    public static HttpResponse callOutGet(String url, Map<String,String> parameters, Map<String, String> mapHTTPHeaders) {
        String parameterString = '';
        for (String key : parameters.keySet()) {
            if (parameterString == '')
                parameterString += '?' + key + '=' + parameters.get(key);
            else
                parameterString += '&' + key + '=' + parameters.get(key);
        }
        url += parameterString;
        return callOut(url, 'GET', null, null, null, mapHTTPHeaders);
    }

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         31/03/2016
    Version -      1.0 
    Function -     GET Method with parameters to build and no body
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/    
    public static HttpResponse callOutGet(String url, String pathParams, Map<String,String> parameters, Map<String, String> mapHTTPHeaders) {
        String parameterString = '';
        for (String key : parameters.keySet()) {
            if (parameterString == '')
                parameterString += '?' + key + '=' + parameters.get(key);
            else
                parameterString += '&' + key + '=' + parameters.get(key);
        }
        url += pathParams + parameterString;
        return callOut(url, 'GET', null, null, null, mapHTTPHeaders);
    }

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         31/03/2016
    Version - 1.0 
    Function - GET Method with parameters and list of path params to build and no body
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static HttpResponse callOutGet(String url, List<String> pathParams, Map<String,String> parameters, Map<String, String> mapHTTPHeaders) {
        String parameterString = '';
        if(parameters != null){
            for (String key : parameters.keySet()) {
                if (parameterString == '')
                    parameterString += '?' + key + '=' + parameters.get(key);
                else
                    parameterString += '&' + key + '=' + parameters.get(key);
            }
        }
        String sPathParams = '';
        for(String s : pathParams){
            sPathParams += s+'/';
        }
        url += sPathParams + parameterString;
        return callOut(url, 'GET', null, null, null, mapHTTPHeaders);
    } 

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         31/03/2016
    Version -      1.0 
    Function -     POST Method for XML or TEXT Request with template
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/    
    public static HttpResponse callOutPost(String url, List<String> parameters, String bodyTemplate, BodyType bType, Map<String, String> mapHTTPHeaders) {
        String body = String.format(bodyTemplate, parameters);
        Dom.Document doc = new Dom.Document();
        if (bType == BodyType.XML) {
            doc.load(body);
        }
        return callOut(url, 'POST', body, doc, bType, mapHTTPHeaders);
    }

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         31/03/2016
    Version -      1.0 
    Function -     POST Method for XML or TEXT with full body, getting a string body (XML or TEXT)
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/    
    public static HttpResponse callOutPost(String url, String bodyString, BodyType bType, Map<String, String> mapHTTPHeaders) {
        Dom.Document doc = new Dom.Document();
        if (bType == BodyType.XML) {
            doc.load(bodyString);
        }
        return callOut(url, 'POST', bodyString, doc, bType, mapHTTPHeaders);
    }
    
    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         31/03/2016
    Version - 1.0 
    Function - POST Method with parameters and list of path params to build
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static HttpResponse callOutPost(String url, String bodyString, List<String> pathParams, BodyType bType, Map<String, String> mapHTTPHeaders){
        Dom.Document doc = new Dom.Document();
        if (bType == BodyType.XML) {
            doc.load(bodyString);
        }

        if( pathParams <> null && pathParams.size() > 0){
            String sPathParams = '';
            for(String s : pathParams){
                sPathParams += s+'/';
            }
            url += sPathParams;
        }

        return callOut(url, 'POST', bodyString, doc, bType, mapHTTPHeaders);
    }

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         31/03/2016
    Version -      1.0 
    Function -     POST Method for TEXT with full String body
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static HttpResponse callOutPost(String url, String bodyString, Map<String, String> mapHTTPHeaders) {
        return callOut(url, 'POST', bodyString, null, BodyType.TEXT, mapHTTPHeaders);
    }

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         31/03/2016
    Version -      1.0 
    Function -     POST Method for XML with full XML body. BodyType included to support ETXML (ExactTarget)
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/    
    public static HttpResponse callOutPost(string url, Dom.Document body, BodyType bType, Map<String, String> mapHTTPHeaders) {
        return callOut(url, 'POST', null, body, bType, mapHTTPHeaders);
    }

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         31/03/2016
    Version -      1.0 
    Function -     POST Method for Text body Request in a form style
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/    
    public static HttpResponse callOutPost(String url, Map<String, String> parameters, Map<String, String> mapHTTPHeaders) {
        String body = '';
        for (String key : parameters.keySet()) {
            if (body == '')
                body += key + '=' + parameters.get(key);
            else
                body += '&' + key + '=' + parameters.get(key);
        }
        return callOut(url, 'POST', body, null, BodyType.FORM, mapHTTPHeaders);
    }

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         31/03/2016
    Version -      1.0 
    Function -     DELETE Method with full endpoint (including parameters) and no body
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static HttpResponse callOutDelete(string url, Map<String, String> mapHTTPHeaders) {
        return callOut(url, 'DELETE', null, null, null, mapHTTPHeaders);
    }

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         31/03/2016
    Version -      1.0 
    Function -     Do generic callout
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/    
    public static HttpResponse callOut(String url, String method, String StringBody, Dom.Document docBody, BodyType bType, Map<String, String> mapHTTPHeaders){
        //HTTP objects
        HttpRequest request;
        HttpResponse response;
        Http h = new Http();
        
        //Set request
        request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod(method);
        request.setTimeout(60000);

        /*
        // Get Authorization parameters (Username & Password) from a custom setting "Integration Authorization Settings (PMS_Integration_Authorization_Settings__c)"
        //PMS_Integration_Authorization_Settings__c integrationAuthorizationSetting = PMS_Integration_Authorization_Settings__c.getInstance();        
        // Specify the required user name and password to access the endpoint
        // As well as the header and header information    
        Blob headerValue = Blob.valueOf( integrationAuthorizationSetting.PMS_Username__c + ':' +  integrationAuthorizationSetting.PMS_Password__c );
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        request.setHeader('Authorization', authorizationHeader);
        */
        //request.setHeader('Accept', 'application/xml');

        if( mapHTTPHeaders <> null ){
            for(String key : mapHTTPHeaders.keySet()){
                request.setHeader(key, mapHTTPHeaders.get(key) );
            }
        }

        //Set xml body
        if (bType == BodyType.XML) {
            request.setBodyDocument(docBody);
            //request.setHeader('Content-Type', 'text/xml');
            request.setHeader('Content-Type', 'application/xml');
        }
        if (bType == BodyType.TEXT) {
           request.setBody(stringBody);
        }
        if(bType == BodyType.JSON){
            request.setBody(stringBody);
            request.setHeader('Content-Type', 'application/json');
        }
        if (bType == BodyType.FORM) {
            request.setBody(stringBody);
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        }
        
        //Send request and return response or error
        response = h.send(request);

        responseForAssertions = response;

        if(!setPositiveStatuses.contains(response.getStatusCode())){
            //throw new PMS_APIUtilityException( 'HTTP Response Status: '+response.getStatus() +', '+ 'HTTP Response Status Code: '+ string.valueOf(response.getStatusCode()) );
        }
        
        return response;
    }
    
    //Body types available
    public enum BodyType {XML,TEXT, JSON, FORM}

    //Custom Exception
    public class PMS_APIUtilityException extends Exception{}
    
}