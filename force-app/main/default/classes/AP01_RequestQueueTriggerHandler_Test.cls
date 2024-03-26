/**
* @author -         Christian Gaylan
* @date -           02/05/2016
* @description -    Test Class for AP01_RequestQueueTriggerHandler
* #############Change Log#############
* Modified by     Version     Change Date
**/

@isTest
private class AP01_RequestQueueTriggerHandler_Test {
    
    @testSetup static void setUpData(){
        List<Request_Queue__c> ReqQ = new List<Request_Queue__c>();
        for(Integer x=0; x<=9; x++){
            Request_Queue__c reqObj = new Request_Queue__c();
            reqObj.Processed_on_date__c = System.today();
            ReqQ.add(reqObj);
        }
        insert ReqQ;
    }
    
    @isTest static void testRequestQueueBatch(){
        List<Request_Queue__c> reqQueue = [SELECT Id FROM Request_Queue__c LIMIT 200];
        test.startTest();
        AP01_RequestQueueTriggerHandler req = new AP01_RequestQueueTriggerHandler();
        req.runRequestQueueBatchProcess(reqQueue);
        req.OnAfterInsert(reqQueue);
        System.assertEquals(10, reqQueue.size());
        test.stopTest();
    }          
}