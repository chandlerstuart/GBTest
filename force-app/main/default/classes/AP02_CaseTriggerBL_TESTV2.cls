/**
* Class Name: AP01_CaseTriggerHandlerTest
* @author: Emman Flores/Tristan Zantua/Ronald Martinez
* @date: 02.04.2016
* @description: Test Class for AP02_CaseTriggerBL

History
***********************************************************
Version     Author          Date         Detail
2.1         J.Radcliffe     13-06-2019   Removal of redundant test methods   
*/

@isTest(seeAllData=true)
public class AP02_CaseTriggerBL_TESTV2 {
    /* 2.1
    static testMethod void testAP02_CaseTriggerBL_MilestoneTest() {

        //List<Account> accList = [Select Id from Account LIMIT 1];
        //List<Opportunity> oppList = [Select id from Opportunity LIMIT 1];
        List<Booking__c> bookingList = [select Id, Account__c from Booking__c ORDER BY CreatedDate DESC LIMIT 1];
        if (bookingList.isEmpty()){
            List<Account> accList = AP23_TestDataFactory.createPersonAccount(1);
            insert accList;

            List<Opportunity> oppList = AP23_TestDataFactory.createOpportunity(1, ApplicationConstant.QUOTESENTSTAGE, accList[0]);
            insert oppList;

            List<Booking__c> createBookings = AP23_TestDataFactory.createBooking(1, accList[0], oppList[0].Id);
            insert createBookings;
            bookingList.add(createBookings[0]);

        }
        //create case
        List<Case> cases = AP23_TestDataFactory.createCase(1, bookingList[0].Account__c, bookingList[0].Id);
        for(Case c: cases){
            c.RecordTypeId = ApplicationConstant.CASERECTYPEID_COMPLAINT;
            c.Booking__c = bookingList[0].Id;
            c.Reminder_Event__c = false;
            //c.RequestedCallBackDateAndTime__c = date.today().addDays(1);
            c.RequestedCallBackDateAndTime__c = system.now().addDays(1);
            c.OwnerId = UserInfo.getUserId();
            c.Subject = 'Test Case';
        }

        database.insert(cases);
        
        Map<Id, Case> newCaseMap = new Map<Id, Case>();
            
        for(Case c: cases){
            c.Status = ApplicationConstant.CASE_STATUS_CLOSED;
            c.Reason = 'CS Error';
            newCaseMap.put(c.Id, c);
        }

        List<CaseMileStone> csList = [SELECT  CaseId, MilestoneTypeId, CompletionDate  FROM CaseMileStone WHERE CaseId IN: newCaseMap.keySet()];
        system.assertNotEquals(true, csList.isEmpty());
        
        test.startTest();
        
            AP02_CaseTriggerBL.updateCaseMileStone(newCaseMap);

        test.stopTest();  
    }*/

    

}