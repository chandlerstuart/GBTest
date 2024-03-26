/**
Name:  AP52_CaseTakeOwnershipBL_Test.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test Class for AP52_CaseTakeOwnershipBL
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  M.Cebrian  2016-05-04  Initial test class development
1.1  S.Molloy   2016-11-25  Ensure all Case records are assigned an Opportunity__c as per business rules
**/
@isTest
public class AP52_CaseTakeOwnershipBL_Test{
    @isTest private static void testTakeOwnerShip(){
        //as of the moment cannot be saved to ApplicationConstant class
        String ROLE_CSA = ApplicationConstant.CS_UK_AGENT;
        
        //Previous Owner
        //CHECK IF THERE IS Active CSA IN ORG:
        Id tskOwnId = UserInfo.getUserId();
        Integer csaCount = [SELECT COUNT() FROM USER WHERE UserRole.Name =: ROLE_CSA AND IsActive = true];
        If(csaCount > 0 ){
       User prevOwn = [SELECT ID FROM USER WHERE UserRole.Name =: ROLE_CSA AND IsActive = true LIMIT 1];
             tskOwnId = prevOwn.Id;
        }
        
        //create Account
        List<Account> accList = AP23_TestDataFactory.createAccount(1);    
        insert accList;

         //Create Opportunity for Cases
        List<Opportunity> oppList = AP23_TestDataFactory.createOpportunity(1,ApplicationConstant.CLOSESALESTAGE, accList[0]);
        insert oppList;
        
        //create Case
        List<Case> caseList = AP23_TestDataFactory.createCase(2, accList[0]);
        for(Case cs : caseList){
            cs.RequestedCallBackDateAndTime__c = System.today();
            cs.Opportunity__c = oppList[0].Id;
        }
        insert caseList;
        
        //create Task
        List<Task> taskList = AP23_TestDataFactory.createTask(2, caseList[0]);
        for(Task tsk : taskList){
            tsk.OwnerId =   tskOwnId;     
        }
        insert taskList;
        
        //create Event
        List<Event> eveList = AP23_TestDataFactory.createEvent(3, caseList[0]);
        for(Event eve : eveList){
            eve.OwnerId =   tskOwnId;    
            eve.ActivityDateTime = System.today() + 2;
        }     
        insert eveList;
        
        test.startTest();
        AP52_CaseTakeOwnershipBL.updateTaskEventOwnerId(caseList[0].Id, tskOwnId, ApplicationConstant.CASERECTYPEID_AMENDMENT);
        test.stopTest();
        
        for(Task t : taskList){
            //System.assertEquals(t.OwnerId, UserInfo.getUserId());
        }   
        
        for(Event et : eveList){
            //System.assertEquals(et.OwnerId, UserInfo.getUserId());
        }  

    }
}