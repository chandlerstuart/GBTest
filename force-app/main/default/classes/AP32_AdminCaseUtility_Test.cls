@isTest(seeAllData=false)
private class AP32_AdminCaseUtility_Test {
    
    @testSetUp static void setupData(){
        List<Account> accList = AP23_TestDataFactory.createAccount(2);
        insert accList;
        
        List<Contact> con = AP23_TestDataFactory.createContactList(1, accList[0]);
        insert con;
        
        List<Opportunity> oppList = AP23_TestDataFactory.createOpportunity(1, ApplicationConstant.CUSTOMERACCEPTEDSTAGE, accList[0]);
        oppList[0].Owner = [SELECT Id From User LIMIT 1];
        insert oppList;

        List<Booking__c> bookList = AP23_TestDataFactory.createBooking(101, accList[0], oppList[0].Id);
        for(Booking__c bkItr : bookList){
            bkItr.TransferDetailsRequired__c = true;
            bkItr.RoomingListRequired__c = true;
        }
        insert bookList;
        
        List<String> epayTypes = new List<String>(ApplicationConstant.EPTYPESET);
        List<Expected_Payment__c> epaymentList = AP23_TestDataFactory.createExpectedPayment(101, bookList[0], epayTypes[0], 1) ;
        Integer epyIndx = 0;
        for(Integer i = 0;  i < 101; i++){
            epaymentList[i].Booking__c = bookList[i].Id;
            epaymentList[i].ExpectedPaymentType__c = epayTypes[epyIndx];
            if(epyIndx > 2){
                epyIndx++;
            }
            else{
                epyIndx=0;
            }
        }
        insert epaymentList;
    }
    
    static TestMethod void TestAdminCaseUtil(){
        test.startTest();
        Database.DMLOptions dmlx = new Database.DMLOptions();
        dmlx.allowFieldTruncation = true;
        
        List<Booking__c> bk = [SELECT Id FROM Booking__c ORDER BY CreatedDate DESC LIMIT 101];
        List<Account> acc = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 2];
        Contact con = [SELECT Id FROM Contact ORDER BY CreatedDate DESC LIMIT 1];
        Opportunity oppty = [SELECT OwnerId FROM Opportunity ORDER BY CreatedDate DESC LIMIT 1];
        
        List<Expected_Payment__c> expList = [SELECT Id, Expected_Payment_Date__c FROM Expected_Payment__c ORDER BY CreatedDate DESC LIMIT 99];
        List<Expected_Payment__c> expList2 = [SELECT Id, Expected_Payment_Date__c FROM Expected_Payment__c ORDER BY CreatedDate DESC LIMIT 100];
        List<Expected_Payment__c> expList3= [SELECT Id, Expected_Payment_Date__c FROM Expected_Payment__c ORDER BY CreatedDate DESC LIMIT 101];
        Map<Id, Expected_Payment__c> expMap = new Map<Id, Expected_Payment__c>(expList); 
        Map<Id, Expected_Payment__c> expMap2 = new Map<Id, Expected_Payment__c>(expList2); 
        Map<Id, Expected_Payment__c> expMap3 = new Map<Id, Expected_Payment__c>(expList3); 
        
        Case newCase = AP32_AdminCaseUtility.createAdminCase(ApplicationConstant.ADMINCASESUBJ, bk[0].Id, acc[0].Id, con.Id, ApplicationConstant.RECOMMENDATIONSTAGE, oppty.OwnerId, ApplicationConstant.ADMINTASKSET, dmlx);
        insert newCase;
        Integer adminCaseCount = [SELECT COUNT() FROM CASE WHERE RecordType.Name =:ApplicationConstant.CASETYPE_ADMIN];
        System.assertEquals(1, adminCaseCount);
        
        //invalid Stage
        Case anotherCase = AP32_AdminCaseUtility.createAdminCase(ApplicationConstant.ADMINCASESUBJ, bk[99].Id, acc[0].Id, con.Id, ApplicationConstant.CALENDAR_LIGHTYELLOWFORSIT, oppty.OwnerId, ApplicationConstant.ADMINTASKSET, dmlx);
        insert anotherCase;
        Integer adminCaseCount2 = [SELECT COUNT() FROM CASE WHERE RecordType.Name =:ApplicationConstant.CASETYPE_ADMIN];
        System.assertEquals(2, adminCaseCount2);
        
        Case yetAnotherCase = AP32_AdminCaseUtility.createAdminCase(ApplicationConstant.ADMINCASESUBJ, bk[43].Id, acc[0].Id, con.Id, ApplicationConstant.CUSTOMERACCEPTEDSTAGE, oppty.OwnerId, ApplicationConstant.ADMINTASKSET, dmlx);
        insert yetAnotherCase;
     
        Task newTask = AP32_AdminCaseUtility.createTask(ApplicationConstant.ADMINTASKSUBJ_CHECKCH, System.today()+2, newCase.OwnerId, acc[0].Id, oppty.OwnerId, ApplicationConstant.USP_QUEUE);
        
        //Integer adminCaseTaskCount = [SELECT COUNT() FROM Task];
       // System.assertEquals(2, adminCaseTaskCount);
        
        Task newTask2 = AP32_AdminCaseUtility.createTask(ApplicationConstant.ADMINTASKSUBJ_CHECKCH, System.today()+2, anotherCase.OwnerId, acc[0].Id, oppty.OwnerId, ApplicationConstant.USP_SALES_AGENT); 
        //Integer adminCaseTaskCount2 = [SELECT COUNT() FROM Task];
        //System.assertEquals(1, adminCaseTaskCount2);    
        
        //AP32_AdminCaseUtility.createTask(ApplicationConstant.GETFINALBALANCE, expList2[0].Expected_Payment_Date__c, newCase.Id, con.Id, newCase.OwnerId, ApplicationConstant.USP_SALES_MANAGER);
        
        /*
        AP32_AdminCaseUtility.checkCreateTask(newCase, expMap, expMap2, expMap3, true, true, true, true, true);  
        AP32_AdminCaseUtility.checkCreateTask(anotherCase, expMap, expMap2, expMap3, false, false, true, false, false);
        AP32_AdminCaseUtility.checkCreateTask(yetAnotherCase, expMap, expMap2, expMap3, true,  true, true,  true,  true);
        */
        
        //AP32_AdminCaseUtility.checkCreateTask(newCase, expMap, expMap2, expMap2, true, true, true, true, true);
        //AP32_AdminCaseUtility.createTask(ApplicationConstant.GETFINALBALANCE, expList2[0].Expected_Payment_Date__c, newCase.Id, con.Id, newCase.OwnerId, ApplicationConstant.USP_SALES_MANAGER);
        test.stopTest();
    }
}