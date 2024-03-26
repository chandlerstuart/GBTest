/**
* Class Name: RequestQueueBatch_Test
* @author: Emman Flores
* @date: 28.05.2016
* @description: Test class for RequestQueueBatch
*/
@isTest
public class RequestQueueBatch_Test{

    @testSetup static void testSetup(){
        
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;             	
    	
        //Create accounts    
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        
        List<Account> lAcc = new List<Account>();
        Account acc1 = AP23_TestDataFactory.createPersonAccount(1)[0];
        lAcc.add(acc1);
        insert lAcc;
        
                
        //Create Account       
        //List<Account> accList = new List<Account>();
        //Account acc = AP23_TestDataFactory.createAccount(1)[0];
        //accList.add(acc);
        //database.insert(accList);
        
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
    
    static testMethod void batchTest1(){
        
        List<Account> accList = [SELECT Id, Name, Golfbreaks_Person_Id__c FROM Account];            
        RequestQueueUtility.populateRequestQueueRecords(accList);

        String query = RequestQueueUtility.buildRequestQueueQuery();
        String recTypeId = ApplicationConstant.getRecordTypeId( ApplicationConstant.OBJECT_TYPE_REQUEST_QUEUE, ApplicationConstant.RECORD_TYPE_REQUEST_QUEUE_REQUEST );

        List<Request_Queue__c> lRQ = Database.query(query);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
        Database.executeBatch(new RequestQueueBatch());  
        Test.stopTest();
    }
    
    static testMethod void batchTest2(){
        List<Account> accList = [SELECT Id, Name, Golfbreaks_Person_Id__c FROM Account]; 
        
        RequestQueueUtility.populateRequestQueueRecords(accList);

        String query = RequestQueueUtility.buildRequestQueueQuery();
        List<Request_Queue__c> lRQ = Database.query(query);

        Test.startTest();
        Database.executeBatch(new RequestQueueBatch());
        Test.stopTest();
    }
    
    static testMethod void batchTest3(){
    
        List<Account> accList = [SELECT Id, Name, Golfbreaks_Person_Id__c FROM Account];            
        RequestQueueUtility.populateRequestQueueRecords(accList);

        String query = RequestQueueUtility.buildRequestQueueQuery();
        String recTypeId = ApplicationConstant.getRecordTypeId( ApplicationConstant.OBJECT_TYPE_REQUEST_QUEUE, ApplicationConstant.RECORD_TYPE_REQUEST_QUEUE_REQUEST );
        
        List<Request_Queue__c> lRQ = Database.query(query);
        lrQ[0].Retry__c = null;
        database.update(lRQ);
        
        Test.startTest();
        Database.executeBatch(new RequestQueueBatch());
        Test.stopTest();
    }
    
}