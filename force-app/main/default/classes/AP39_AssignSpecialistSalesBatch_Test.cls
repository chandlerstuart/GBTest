@isTest
private class AP39_AssignSpecialistSalesBatch_Test{
    @isTest static void tstMthod(){
        //for Lead Owner
        List<Group> spcGroup = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = :ApplicationConstant.LEAD_SPC_SALESTEAM]; 
        
        //Create Person Account
        List<Account> accList = AP23_TestDataFactory.createAccount(1);
        //accList[0].RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId(); 
        accList[0].Is_PGA__pc = true;
        //insert accList;  
        
        //create Lead
        List<Lead> leadList = AP23_TestDataFactory.createLead(101);
        leadList[0].Account__c = accList[0].id;
        leadList[0].OwnerId = spcGroup[0].id;
        insert leadList;
        
        test.startTest();
        AP39_AssignSpecialistSalesBatch assgn = new AP39_AssignSpecialistSalesBatch();
        assgn.start(null);
        assgn.execute(null, leadList);
        assgn.finish(null);  
        test.stopTest();
        
        Integer count = [SELECT COUNT() FROM LEAD WHERE Owner.Name =:ApplicationConstant.LEAD_SPC_SALESTEAM];
        System.assertEquals(0, count);
    }
}