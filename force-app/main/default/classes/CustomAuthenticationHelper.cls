/*
Name: CustomAuthenticationHelper.cls
Copyright © 2020  Golfbreaks
======================================================
======================================================
Purpose:
-------
(DET) Custom Authentication Helper class.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2020-11-07  Initial development.
1.1  J Radcliffe   2020-11-16  Enhancements. New configurable 'Accept' header field.
1.2  J Radcliffe   2022-05-27  Enhancements. Support for auth-specific named credentials.
1.3  Mark Cane&    2023-08-20  Authentication callout timeout value now linked to the framework setting.
1.4  Mark Cane&    2023-11-28  Enhancements. Allow token replacement within the body. Do not set header in this case.
*/
public with sharing class CustomAuthenticationHelper {
    
    public CustomAuthenticationHelper(){}

    private static Cache.OrgPartition sifCacheOrgPartition;
    private static Http outboundHttp;
    private static Integer authCalloutTimeout;//1.3+

    static {        
        sifCacheOrgPartition = Cache.Org.getPartition('SIFCachePartition');
        outboundHttp = new Http();

        FrameworkSettings__c frameworkSettings = FrameworkSettings__c.getOrgDefaults();//1.3+
        authCalloutTimeout = (frameworkSettings!=null && frameworkSettings.CalloutTimeout__c!=null && frameworkSettings.CalloutTimeout__c>0) ? (Integer)frameworkSettings.CalloutTimeout__c : 30000;//1.3+
    }

    public static HttpResponse authenticatedSend(DataEventType__mdt det, HttpRequest outboundHttpRequest){
        HttpResponse authenticatedResponse;
        
        try {
            
            Boolean isNewAuthToken=false;
            String authenticationToken;

            if (sifCacheOrgPartition!=null){
                
                //1.0. Authentication tokens are cached by DET Id.
                Object cachedAuthToken = sifCacheOrgPartition.get(det.Id);//Note - max key length is 50 - det Id length is 18.

                if (cachedAuthToken!=null) authenticationToken = (String)cachedAuthToken;
            }

            if (String.isNotBlank(authenticationToken)){

                if (String.isNotBlank(outboundHttpRequest.getBody()) && outboundHttpRequest.getBody().contains('[TOKEN]')){//1.4+
                    outboundHttpRequest.setBody(outboundHttpRequest.getBody().replace('[TOKEN]',authenticationToken));//1.4+
                } else {
                    //1.0. if [TOKEN] add header to req and HTTP.send(req) --> rethrow exception.
                    //1.0. E.g. Bearer [TOKEN] becomes Bearer 49340395703750.
                    String authorizationHeaderValue = String.isBlank(det.AuthenticationHeaderFormatString__c) ? authenticationToken : det.AuthenticationHeaderFormatString__c.replace('[TOKEN]',authenticationToken);                                
                    outboundHttpRequest.setHeader('Authorization', authorizationHeaderValue);    
                }
                
                try {
                    authenticatedResponse = outboundHttp.send(outboundHttpRequest);

                    //1.0. if HTTP response status code is not [AuthenticationExpiredStatusCode:401] then return response.
                    if (authenticatedResponse.getStatusCode()!=det.AuthenticationExpiredStatusCode__c) return authenticatedResponse;

                    authenticationToken=null;//Token has expired.

                } catch (Exception ex){ throw ex; }
            }

            //1.0. if no [TOKEN] or response status code is [AuthenticationExpiredStatusCode:401] then
            //1.0. build new Authentication Token request -> send, parse, cache
            HttpRequest authHttpRequest = new HttpRequest();

            String credential1 = String.isBlank(det.AuthenticationCredential1__c) ? '' : det.AuthenticationCredential1__c;
            String credential2 = String.isBlank(det.AuthenticationCredential2__c) ? '' : det.AuthenticationCredential2__c;

            if (String.isNotBlank(det.AuthenticationRequestEncoding__c)){

                if (String.isNotBlank(credential1)){
                    if (det.AuthenticationRequestEncoding__c.equalsIgnoreCase('url')) credential1 = EncodingUtil.urlEncode(credential1,'UTF-8');
                    if (det.AuthenticationRequestEncoding__c.equalsIgnoreCase('base64')) credential1 = EncodingUtil.base64Encode(Blob.valueOf(credential1));
                }
                if (String.isNotBlank(credential2)){
                    if (det.AuthenticationRequestEncoding__c.equalsIgnoreCase('url')) credential2 = EncodingUtil.urlEncode(credential2,'UTF-8');
                    if (det.AuthenticationRequestEncoding__c.equalsIgnoreCase('base64')) credential2 = EncodingUtil.base64Encode(Blob.valueOf(credential2));
                }
            }

            String authEndpoint = det.AuthenticationEndpointPathFormatString__c;
            authEndpoint = authEndpoint.replace('[1]', credential1);
            authEndpoint = authEndpoint.replace('[2]', credential2);            
            if (!authEndpoint.startsWith('/')) authEndpoint='/'+authEndpoint;

            String authBody;
            if (String.isNotBlank(det.AuthenticationBodyFormatString__c)){
                authBody = det.AuthenticationBodyFormatString__c;
                authBody = authBody.replace('[1]', credential1);
                authBody = authBody.replace('[2]', credential2);                
            }

            authHttpRequest.setTimeout(authCalloutTimeout);//1.3+ -- default value is 10 seconds if not set.

            String authNamedCred = (det.AuthenticationNamedCredentials__c != null)?det.AuthenticationNamedCredentials__c:det.NamedCredentials__c;//1.2+
            authHttpRequest.setEndpoint('callout:'+authNamedCred+authEndpoint);//1.2~
            authHttpRequest.setMethod(det.AuthenticationRequestHttpMethod__c);
            authHttpRequest.setHeader('Content-Type', String.isBlank(det.AuthenticationRequestContentType__c) ? 'application/json' : det.AuthenticationRequestContentType__c);
            authHttpRequest.setHeader('Accept', String.isBlank(det.AuthenticationContentTypeAccept__c) ? '*/*' : det.AuthenticationContentTypeAccept__c);//1.1~
            
            if (String.isNotBlank(authBody)) authHttpRequest.setBody(authBody);
            
            try {
                HttpResponse authHttpResponse = outboundHttp.send(authHttpRequest);

                if (authHttpResponse.getStatusCode()==200){

                    String responseBody = authHttpResponse.getBody();
                    
                    //1.0. Code assumes that no token path means the body is the token.
                    if (String.isNotBlank(responseBody) && String.isBlank(det.AuthenticationResponseTokenPath__c)){
                        authenticationToken = responseBody;
                        isNewAuthToken = true;

                    } else if (String.isNotBlank(responseBody) && String.isNotBlank(det.AuthenticationResponseTokenPath__c)){
                        //1.0. Code assumes that token path means the body is a simple JSON object and the token can be found by Map key.
                                            
                        Map<String,Object> dataObjectMap = (Map<String,Object>)JSON.deserializeUntyped(responseBody);

                        if (dataObjectMap.containsKey(det.AuthenticationResponseTokenPath__c)){
                            authenticationToken = (String)dataObjectMap.get(det.AuthenticationResponseTokenPath__c);
                            isNewAuthToken = true;
                        }
                    
                    } else authenticationToken=null;                       
                }
              
            } catch (Exception ex){ throw ex; }
            

            if (String.isNotBlank(authenticationToken)){

                if (isNewAuthToken && sifCacheOrgPartition!=null){
                    
                    Integer ttlSecs = det.AuthenticationTokenCacheTTLSeconds__c==null || det.AuthenticationTokenCacheTTLSeconds__c==0 || det.AuthenticationTokenCacheTTLSeconds__c<300 ? 300 : (Integer)det.AuthenticationTokenCacheTTLSeconds__c;

                    sifCacheOrgPartition.put(det.Id, authenticationToken, ttlSecs, Cache.Visibility.ALL, false);
                }

                if (String.isNotBlank(outboundHttpRequest.getBody()) && outboundHttpRequest.getBody().contains('[TOKEN]')){//1.4+
                    outboundHttpRequest.setBody(outboundHttpRequest.getBody().replace('[TOKEN]',authenticationToken));//1.4+
                } else {
                    //1.0. if [TOKEN] add header to req and HTTP.send(req) --> rethrow exception.
                    //1.0. E.g. Bearer [TOKEN] becomes Bearer 49340395703750.
                    String authorizationHeaderValue = String.isBlank(det.AuthenticationHeaderFormatString__c) ? authenticationToken : det.AuthenticationHeaderFormatString__c.replace('[TOKEN]',authenticationToken);
                    
                    outboundHttpRequest.setHeader('Authorization', authorizationHeaderValue);
                }
                
                try {

                    return outboundHttp.send(outboundHttpRequest);

                } catch (Exception ex){ throw ex; }
            }

        } catch (Exception ex) { throw ex; }
        
        throw new CustomAuthenticationException('Custom Authentication Protocol Error');
    }
}