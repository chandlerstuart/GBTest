@isTest
private class AP07_CaseScoringLogic_Test {

    @testSetup
    static void dataSetup() {
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings; 

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
        
        Expected_Payment__c ep = AP23_TestDataFactory.createExpectedPayment(1, book, 'Full Deposit', 5000)[0];
        ep.Expected_Amount__c  = 10000;
        insert ep;

        insert AP23_TestDataFactory.getLeadScoringRuleForCase();
        insert AP23_TestDataFactory.getCasePriorityList();
    }
    
    //test method
    static testMethod void test() {
        List<Case> caseList = new List<Case>();
        Account acc = [SELECT Id FROM Account][0];
        Opportunity opp = [select Id from Opportunity][0];
        for(integer i=0;i<200;i++){
            Case cse = AP23_TestDataFactory.createCase(1, acc)[0];
            cse.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Case').getRecordTypeId();
            cse.Origin  = 'Email';
            cse.First_Contact_Resolved__c = true;
            cse.NoOfUpdates__c = 5;
            cse.Opportunity__c = opp.Id;
            caseList.add(cse);
        }
        insert caseList;
        System.assertEquals(200, [SELECT Count() FROM Case]);
        
        for(integer i=0;i<200;i++){
            Test.setCreatedDate(caseList[i].Id, Datetime.newInstance(Date.today().year(), Date.today().month(), (Date.today().day() - 1), 3, 17, 43));
        }
        
        Test.startTest();
            caseList = new List<Case>();
            for(Case cse : [SELECT Status, ClosedSubStatus__c FROM Case]){
                cse.Status = 'Closed';
                cse.ClosedSubStatus__c = 'Accepted';
                caseList.add(cse);
            }
            update caseList;
            System.assertEquals([SELECT Status FROM Case][199].Status, 'Closed');

            Case cse = [SELECT Time_taken_to_resolve__c, Points__c,Priority,CaseScoreAppliedDate__c FROM Case][199];
            System.assertEquals(cse.CaseScoreAppliedDate__c, Date.today());
            System.debug('======= Time_taken_to_resolve__c ' + cse.Time_taken_to_resolve__c);
        Test.stopTest();        
    }
}