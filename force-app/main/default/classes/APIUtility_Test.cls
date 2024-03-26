/**
Name:  APIUtility_Test.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test Class for APIUtility
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.0  Atlee     2016-05-06   Initial test class development
**/
@isTest
public class APIUtility_Test{

    static testMethod void testEndpoint(){
        //Create data
        String baseURL = 'https://www.test.com';
        Map<String, String> mapURLParameters = new Map<String, String>();
        mapURLParameters.put('Account', 'TestAccount');
        mapURLParameters.put('Contact', 'TestContact');
        String endURL = 'https://www.test.com?Account=TestAccount&Contact=TestContact';
        Test.startTest();
        System.AssertEquals(APIUtility.buildEndPointURL(baseURL, mapURLParameters), endURL);
        Test.stopTest();
    } 

    static testMethod void testCallOutGet(){
        String url = 'www.test.com';
        Map<String, String> mapHeader = new Map<String, String>();
        mapHeader.put('Content-Type', 'application/json'); 
        Map<String, String> mapURLParameters = new Map<String, String>();
        String pathParams = 'path';
        List<String> lPath = new List<String>();
        lPath.add(pathParams);
        mapURLParameters.put('Account', 'TestAccount');
        mapURLParameters.put('Contact', 'TestContact');
           
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
        HttpResponse res = APIUtility.callOutGet(url, mapHeader);
        System.AssertEquals(res.getBody(), '{"foo":"bar"}');
        System.AssertEquals(res.getHeader('Content-Type'), 'application/json');
        
        res = APIUtility.callOutGet(url, mapURLParameters, mapHeader);
        System.AssertEquals(res.getBody(), '{"foo":"bar"}');
        System.AssertEquals(res.getHeader('Content-Type'), 'application/json');

        res = APIUtility.callOutGet(url, pathParams, mapURLParameters, mapHeader);
        System.AssertEquals(res.getBody(), '{"foo":"bar"}');
        System.AssertEquals(res.getHeader('Content-Type'), 'application/json');

        res = APIUtility.callOutGet(url, lPath, mapURLParameters, mapHeader);
        System.AssertEquals(res.getBody(), '{"foo":"bar"}');
        System.AssertEquals(res.getHeader('Content-Type'), 'application/json');


        Test.stopTest();
    }
    
    static testMethod void testCallOutPost(){
        //public static HttpResponse callOutPost(String url, List<String> parameters, String bodyTemplate, BodyType bType, Map<String, String> mapHTTPHeaders) 
        String url = 'www.test.com';
        
        Map<String, String> mapHeader = new Map<String, String>();
        mapHeader.put('Content-Type', 'application/json'); 
        
        
        String pathParams = 'meow';
        List<String> lPath = new List<String>();
        lPath.add(pathParams);
        
        String bodyTemp = '<xml Meow="{0}"/>';
        String bodyTempJSON = '{"Meow"="{0}"}';
        Dom.Document bodydoc = new Dom.Document();
        bodydoc.load(bodyTemp);
        
        Map<String, String> mapURLParameters = new Map<String, String>();
        mapURLParameters.put('Account', 'TestAccount');
        mapURLParameters.put('Contact', 'TestContact');
    
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
        
        HttpResponse res = APIUtility.callOutPost(url, lPath, bodyTemp, APIUtility.BodyType.XML, mapHeader); 
        System.AssertEquals(res.getBody(), '{"foo":"bar"}');
        System.AssertEquals(res.getHeader('Content-Type'), 'application/json');
                
        res = APIUtility.callOutPost(url, bodyTemp, APIUtility.BodyType.XML, mapHeader); 
        System.AssertEquals(res.getBody(), '{"foo":"bar"}');
        System.AssertEquals(res.getHeader('Content-Type'), 'application/json');        
        
        res = APIUtility.callOutPost(url, bodyTemp, lPath, APIUtility.BodyType.XML, mapHeader);
        System.AssertEquals(res.getBody(), '{"foo":"bar"}');
        System.AssertEquals(res.getHeader('Content-Type'), 'application/json');  

        res = APIUtility.callOutPost(url, bodyTempJSON, lPath, APIUtility.BodyType.JSON, mapHeader);
        System.AssertEquals(res.getBody(), '{"foo":"bar"}');
        System.AssertEquals(res.getHeader('Content-Type'), 'application/json');  
        
        res = APIUtility.callOutPost(url, bodyTemp, mapHeader);
        System.AssertEquals(res.getBody(), '{"foo":"bar"}');
        System.AssertEquals(res.getHeader('Content-Type'), 'application/json');  
        
        res = APIUtility.callOutPost(url, bodydoc, APIUtility.BodyType.XML, mapHeader);
        System.AssertEquals(res.getBody(), '{"foo":"bar"}');
        System.AssertEquals(res.getHeader('Content-Type'), 'application/json');  
        
        res = APIUtility.callOutPost(url, mapURLParameters, mapHeader);
        System.AssertEquals(res.getBody(), '{"foo":"bar"}');
        System.AssertEquals(res.getHeader('Content-Type'), 'application/json');  
        
        res = APIUtility.callOutDelete(url, mapHeader);
        System.AssertEquals(res.getBody(), '{"foo":"bar"}');
        System.AssertEquals(res.getHeader('Content-Type'), 'application/json');  
        
        Test.stopTest();
    }
}