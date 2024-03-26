/**
Name:  AP29_ManualLeadAssignBatchCaller_Test.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test Class for AP29_ManualLeadAssignBatchCaller
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Accenture   2016-04-25  Initial test class development
1.1  SMolloy     2016-11-25  Ensured all Case records are assigned a Booking record as per business rules
**/
@isTest
private class AP29_ManualLeadAssignBatchCaller_Test {
    
    @testSetup
    static void dataSetup() {
        Account acc = AP23_TestDataFactory.createAccount(1)[0];
        insert acc;
        
        Contact con = AP23_TestDataFactory.createContactList(1, acc)[0];
        insert con; 
        
        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, '1. Recommendations', acc)[0];
        insert opp;
        
        Booking__c book = AP23_TestDataFactory.createBooking(1, acc.Id, opp.Id)[0];
        book.AmountPaid__c = 5000;
        book.TransferDetailsRequired__c = true;
        book.RoomingListRequired__c = true;
        insert book;
        
        Case cse = AP23_TestDataFactory.createCase(1, acc)[0];
        cse.Booking__c = book.Id;
        insert cse;
        
        Expected_Payment__c ep = AP23_TestDataFactory.createExpectedPayment(1, book, 'Full Deposit', 5000)[0];
        ep.Expected_Amount__c  = 10000;
        insert ep;
    }
    
  private static testMethod void test() {
      Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com1234', userroleid=[SELECT Id FROM UserRole WHERE DeveloperName = :ApplicationConstant.HEADOFUKSALES].Id);
        Group g = new Group(Type = 'Queue', Name = ApplicationConstant.EUROPE_8_TEAM);
        System.runAs(u) {
            
            AP29_ManualLeadAssignmentBatchCaller.processDetails();
        }
        
        Id classID = [Select Id From ApexClass Where Name = 'AP28_ManualLeadAssignmentBatch'].id;
        List<AsyncApexJob> jobList = [Select Status, ApexClassID from AsyncApexJob where ApexClassID =: classID AND Status = 'Processing'];
        
        //check if there is a job running
        System.assertEquals(0, jobList.size());
  }

}