@isTest
public class RequestQueueUtility_TEST{
    @testSetup static void testSetup(){

        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
    	
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;             	
    	
        //Create accounts    
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        
        List<Account> lAcc = new List<Account>();
        Account acc1 = AP23_TestDataFactory.createPersonAccount(1)[0];
        lAcc.add(acc1);
        insert lAcc;

        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, '2. Quote Sent', lAcc[0])[0];
        insert opp;
        
        //Create custom setting
        List<Request_Queue_Status_Setting__c> lRQSS = new List<Request_Queue_Status_Setting__c>();
        Request_Queue_Status_Setting__c rqss01 = new Request_Queue_Status_Setting__c(Name = 'Retrying'); 
        Request_Queue_Status_Setting__c rqss02 = new Request_Queue_Status_Setting__c(Name = 'Waiting'); 
        lRQSS.add(rqss01);
        lRQSS.add(rqss02);
        insert lRQSS; 
        
        List<Object_Field_Mapping__c> customSettings = AP23_TestDataFactory.getCustomSettingObjectFieldMapping();
        insert customSettings;
    
    }
    
    static testMethod void requestBatchFail(){
        
        List<Account> lAcc = [SELECT Id, Name, Golfbreaks_Person_Id__c FROM Account];            
        RequestQueueUtility.populateRequestQueueRecords(lAcc);

        String query = RequestQueueUtility.buildRequestQueueQuery();
        String recTypeId = ApplicationConstant.getRecordTypeId( ApplicationConstant.OBJECT_TYPE_REQUEST_QUEUE, ApplicationConstant.RECORD_TYPE_REQUEST_QUEUE_REQUEST );
        String ExpQuery = 'SELECT id,ownerid,isdeleted,name,currencyisocode,recordtypeid,createddate,createdbyid,lastmodifieddate,lastmodifiedbyid,systemmodstamp,lastvieweddate,lastreferenceddate,connectionreceivedid,connectionsentid,request_payload__c,response_status_code__c,priority__c,sobject_name__c,related_id__c,retry__c,response_message__c,response_payload__c,external_id__c,processed_on_date__c,response_time__c,request_status__c FROM Request_Queue__c  WHERE RecordTypeId = \'' +recTypeId+ '\' AND Request_Status__c IN (\'Retrying\',\'Waiting\') Order By Priority__c ASC  LIMIT  10';
        
        List<Request_Queue__c> lRQ = Database.query(query);
        // Test createRequestQueueRecord
        System.AssertEquals(lRQ.size(), lAcc.size());
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
        Database.executeBatch(new RequestQueueBatch());  
        Test.stopTest();
        
        Request_Queue__c req01 = [SELECT Id, Request_Status__c FROM Request_Queue__c WHERE Id =: lRQ[0].Id];
        System.AssertEquals(req01.Request_Status__c, ApplicationConstant.REQUEST_QUEUE_STATUS_FAILED);    
    }
    
    static testMethod void testAccountWrapperBuild(){
        Opportunity opp = [select Id from Opportunity LIMIT 1];
        Set<Id> oppIdSet = new Set<Id>();
        oppIdSet.add(opp.Id);
        Map<Id, OpportunityAccountManagerRequestWrapper> wrapperMap = RequestQueueUtility.buildOpportunityAccountManagerRequestWrapperMap(oppIdSet);
        system.assertNotEquals(true, wrapperMap.isEmpty());
    }

    static testMethod void RequestBatchCatchFail(){
        List<Account> lAcc = [SELECT Id, Name, Golfbreaks_Person_Id__c FROM Account]; 
        
        RequestQueueUtility.populateRequestQueueRecords(lAcc);

        String query = RequestQueueUtility.buildRequestQueueQuery();
        List<Request_Queue__c> lRQ = Database.query(query);

        Test.startTest();
        Database.executeBatch(new RequestQueueBatch());
        Test.stopTest();
    
        Request_Queue__c req01 = [SELECT Id, Request_Status__c FROM Request_Queue__c WHERE Id =: lRQ[0].Id];
        System.AssertEquals(req01.Request_Status__c, ApplicationConstant.REQUEST_QUEUE_STATUS_FAILED);
    
    }
    
    static testMethod void testException(){
        List<Request_Queue__c> lRQ = new List<Request_Queue__c>();
        Request_Queue__c rq01 = new Request_Queue__c();
        lRQ.add(rq01);
        insert lRQ;
        rq01.Retry__c = 100;
        RequestQueueUtility.createRequestQueueRecord(lRQ);    
        System.AssertEquals(rq01.Retry__c, 100);
    
    }
    
    static testMethod void testJSON(){
        String jsonInput = '[{"Message":"Test Message", "SalesforceClientID":"Test Client Id", "GolfbreaksClientID": 12345}]';
        List<AccountClientResponseWrapper> lWrapper = RequestQueueUtility.populateAccountClientResponseWrapper(jsonInput);
        //System.AssertEquals(lWrapper[0].Message, 'Test Message');
        System.AssertEquals(lWrapper[0].SalesforceClientID, 'Test Client Id');
        //System.AssertEquals(lWrapper[0].GolfbreaksClientID, 12345);
    }
}