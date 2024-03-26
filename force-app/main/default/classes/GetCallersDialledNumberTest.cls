/*
Name:  GetCallersDialledNumberTest.cls
======================================================
======================================================
Purpose:
-------
Test Suite for GetCallersDialledNumber.cls
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2021-11-17  Initial development
*/
@isTest
public with sharing class GetCallersDialledNumberTest {

    @isTest static void getCallersDialledNumberSuccess(){

        List<GetCallersDialledNumber.Request> requests = new List<GetCallersDialledNumber.Request>();
        GetCallersDialledNumber.Request request = new GetCallersDialledNumber.Request();
        request.userId = UserInfo.getUserId();
        requests.add(request);

        test.startTest();
            List<GetCallersDialledNumber.Result> results = GetCallersDialledNumber.execute(requests);
        test.stopTest();

        //Assertions
        system.assertEquals(1, results.size());
        system.assertEquals(GetCallersDialledNumber.testCallerId, results[0].callerId);
        system.assertEquals(GetCallersDialledNumber.testDialledNumber, results[0].dialledNumber);//Confirm the expected dialled number is deserialized and a '+' prefix added

    }
    
}