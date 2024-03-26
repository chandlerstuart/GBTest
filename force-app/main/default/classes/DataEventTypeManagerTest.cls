/*
Name:  DataEventTypeManagerTest.cls
Copyright © 2023  Golfbreaks
======================================================
======================================================
Purpose: Historically the DataEventTypeManager class has
been implicitly tested through the trigger test suite. 
This test suite is for testing DataEventTypeManager 
functionality in isolation as required.
-------
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2023-02-20  Initial development.
*/
@isTest
public with sharing class DataEventTypeManagerTest {

    /*
    Test cases:
        singleTestCase1 - DataEventType - User_Retrieve_Flow_ADT_Test - ADT Deserialization.
    */
    
    //Test Apex Defined Data Types
    @TestVisible public class ADTTest{
        @AuraEnabled @invocableVariable public string name;
        @AuraEnabled @invocableVariable public ADTInner2 innerObj;
        @AuraEnabled @invocableVariable public List<ADTInner1> innerList;
    }

    public class ADTInner1{
        @AuraEnabled @invocableVariable public string innerName;
        @AuraEnabled @invocableVariable public ADTInner2 innerObj;
    }

    public class ADTInner2{
        @AuraEnabled @invocableVariable public string innerName;
        @AuraEnabled @invocableVariable public Integer innerVal;
    }

    public class CallbackResponseMockImpl implements HttpCalloutMock {

        public String responseBody;
        public Integer responseStatusCode;

        public CallbackResponseMockImpl(){
            responseBody = '{"name":"Response JSON Structure","innerObj":{"innerName":"First Entry","innerVal":99},"innerList":[{"innerName":"firstEntry","innerObj":{"innerVal":1,"innerName":"Test1"}},{"innerName":"secondEntry","innerObj":{"innerVal":2,"innerName":"Test3"}},{"innerName":"thirdEntry","innerObj":{"innerVal":3,"innerName":"Test3"}}]}';
            responseStatusCode=200;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            res.setStatusCode(responseStatusCode);
            return res;
        }
    }    

    static testMethod void singleTestCase1(){

        // Test case 1 : DataEventType - Account_Retrieve_Flow_ADT_Test - ADT Deserialization.

        Test.setMock(HttpCalloutMock.class, new CallbackResponseMockImpl());

        Map<String,Map<Id,String>> dataEventTypeToRecordIds = new Map<String,Map<Id,String>>();
        dataEventTypeToRecordIds.put('User_Retrieve_Flow_ADT_Test',new Map<Id,String>{UserInfo.getUserId()=>null});
 
		Test.startTest();
            DataEventTypeManager detm = new DataEventTypeManager();
            detm.processDataEventTypes(dataEventTypeToRecordIds);
        Test.stopTest();
        
        system.assertNotEquals(null, DataEventTypeManager.flowADTData);

        //Confirm the request is successfully deserialized and stored as an object in the correct structure (to be successfully passed to flow)
        ADTTest testData = (ADTTest)DataEventTypeManager.flowADTData;
        system.assertEquals(3, testData.innerList.size());
        system.assertEquals('Response JSON Structure', testData.name);

    }


}