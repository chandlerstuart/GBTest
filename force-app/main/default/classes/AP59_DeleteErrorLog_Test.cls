@isTest(seeAllData = false)
public class AP59_DeleteErrorLog_Test{
    @testSetUp static void CreateLogs(){
        List<Error_Log__c> errList = new List<Error_Log__c>();
        for(Integer i=0; i<200; i++){
      Error_Log__c errObj = new Error_Log__c();
            errObj.Name = 'err'+i;
            errObj.Error_Type__c = 'Warning';
            errObj.trace__c = 'sample trace';
            errList.add(errObj);
            
        }
    database.insert(errList, false);
        
        for(Error_Log__c er : errList){
            Test.setCreatedDate(er.Id, Datetime.newInstance(System.Today().year(), System.Today().month(), System.Today().day()-2));
        }     
    database.update(errList, false);
    }
    
    @isTest static void testDeleteBatch(){
        List<Error_Log__c> errList = [SELECT Id, Name, Error_Type__c, trace__c, CreatedDate FROM Error_Log__c WHERE CreatedDate <= N_DAYS_AGO:2 LIMIT 200];
        System.assertEquals(200, errList.size());

     Test.startTest();
        Database.executeBatch(new AP59_DeleteErrorLog());  
        Test.stopTest();
        
        Integer errCount = [SELECT COUNT() FROM Error_Log__c LIMIT 200];
        System.assertEquals(0, errCount);
    }
}