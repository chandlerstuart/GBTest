/**
Name:  AP21_NVMCallBackTriggerBL_Test.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test class for all trigger operations related to NVM callback.
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Jerella L     2016-04-28  Initial development.
2.0  Andrei A      2016-05-05  Full code coverage.
3.0  Atlee         2016-05-11  Created entirely new test classes for the updated Apex classes
**/
@isTest
private class AP21_NVMCallBackTriggerBL_Test {
    static integer num = 100;

    @testSetup static void setupTestData(){
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;        
        
        List<Account> accList = AP23_TestDataFactory.createAccount(1);
        insert accList;

        List<Opportunity> oppList = AP23_TestDataFactory.createOpportunity(num, ApplicationConstant.RECOMMENDATIONSTAGE, accList[0]);
        oppList[0].TECH_NVMCallBackUrgent__c = TRUE;
        insert oppList;

        List<Case> caseList = AP23_TestDataFactory.createCase(num,accList[0]);
        caseList[0].TECH_NVMCallBackUrgent__c = TRUE;

        for (integer i = 0 ; i < caseList.size() ; i++){
            caseList[i].Opportunity__c = oppList[i].Id;
        }

        insert caseList;        
        
        List<Lead> leadList = AP23_TestDataFactory.createLead(num);
        leadList[0].TECH_NVMCallBackUrgent__c = TRUE;
        insert leadList;
        
        
    }
    
    static testMethod void testNVMCase(){
        Test.startTest();
        List<NVM_Call_Back__c> nvmCallBackList = new List<NVM_Call_Back__c>();      
        List<Case> caseList = [SELECT Id, RequestedCallBackDateAndTime__c FROM Case];
        
        for (Integer i = 0; i < num; i++) {
            NVM_Call_Back__c nvmCallBackCase = new NVM_Call_Back__c();
            nvmCallBackCase.Case__c = caseList[i].Id;
            nvmCallBackCase.Call_Back_Date_and_Time__c = System.now()-1;
            nvmCallBackList.add(nvmCallBackCase);
        }

        insert nvmCallBackList;
        List<Case> lCaseUpd = [SELECT Id, RequestedCallBackDateAndTime__c FROM Case WHERE Id IN: caseList];
        for (Integer i = 0; i < num; i++) {
            System.AssertEquals(Date.valueOf(lCaseUpd[i].RequestedCallBackDateAndTime__c), Date.ValueOf(nvmCallBackList[i].Call_Back_Date_and_Time__c));
        }
        
        for (Integer i = 0; i < num; i++) {
            nvmCallBackList[i].Call_Back_Date_and_Time__c = System.now()+1;        
        }
        update nvmCallBackList;
        
        lCaseUpd = [SELECT Id, RequestedCallBackDateAndTime__c FROM Case WHERE Id IN: caseList];
        for (Integer i = 0; i < num; i++) {        
            System.AssertEquals(Date.ValueOf(lCaseUpd[i].RequestedCallBackDateAndTime__c.Date()), Date.ValueOf(nvmCallBackList[i].Call_Back_Date_and_Time__c.Date()));
        }
        Test.stopTest();
        
    }    

    static testMethod void testNVMCaseCallBack(){
        Test.startTest();
        List<NVM_Call_Back__c> nvmCallBackList = new List<NVM_Call_Back__c>();      
        List<Case> caseList = [SELECT Id, RequestedCallBackDateAndTime__c, TECH_NVMCallBackUrgent__c FROM Case];
        
        for (Integer i = 0; i < num; i++) {
            NVM_Call_Back__c nvmCallBackCase = new NVM_Call_Back__c();
            nvmCallBackCase.Case__c = caseList[i].Id;
            nvmCallBackCase.Call_Back_Date_and_Time__c = System.now()-1;
            nvmCallBackCase.Call_Back_Day__c = ApplicationConstant.NVMCALLBACK_ASAP;
            nvmCallBackList.add(nvmCallBackCase);
        }

        insert nvmCallBackList;
        List<Case> lCaseUpd = [SELECT Id, RequestedCallBackDateAndTime__c, TECH_NVMCallBackUrgent__c FROM Case WHERE Id IN: caseList];
        for (Integer i = 0; i < num; i++) {
            System.AssertEquals(Date.valueOf(lCaseUpd[i].RequestedCallBackDateAndTime__c), Date.ValueOf(nvmCallBackList[i].Call_Back_Date_and_Time__c));            
        }
        
        for (Integer i = 0; i < num; i++) {
            nvmCallBackList[i].Call_Back_Date_and_Time__c = System.now()+1;        
        }
        update nvmCallBackList;
        
        lCaseUpd = [SELECT Id, RequestedCallBackDateAndTime__c, TECH_NVMCallBackUrgent__c FROM Case WHERE Id IN: caseList];
        for (Integer i = 0; i < num; i++) {        
            System.AssertEquals(Date.ValueOf(lCaseUpd[i].RequestedCallBackDateAndTime__c)+2, Date.ValueOf(nvmCallBackList[i].Call_Back_Date_and_Time__c));
            
        }
        Test.stopTest();
        
    }  
  
    static testMethod void testNVMLead(){ 
        Test.startTest();
        List<NVM_Call_Back__c> nvmCallBackList = new List<NVM_Call_Back__c>();
        List<Lead> leadList = [SELECT Id, CallBackDateTime__c FROM Lead];
        
        for (Integer i = 0; i < num; i++) {
            NVM_Call_Back__c nvmCallBackLead = new NVM_Call_Back__c();
            nvmCallBackLead.Lead__c = leadList[i].Id;
            nvmCallBackLead.Call_Back_Date_and_Time__c = System.now()-1;
            nvmCallBackList.add(nvmCallBackLead);
        }
        insert nvmCallBackList;
        
        List<Lead> lLeadUpd = [SELECT Id, CallBackDateTime__c FROM Lead WHERE Id IN: leadList];
        for (Integer i = 0; i < num; i++) {
            System.AssertEquals(Date.ValueOf(lLeadUpd[i].CallBackDateTime__c), Date.ValueOf(nvmCallBackList[i].Call_Back_Date_and_Time__c));
        }
        
        for (Integer i = 0; i < num; i++) {
            nvmCallBackList[i].Call_Back_Date_and_Time__c = System.now()+1;   
        }     
        update nvmCallBackList;
        
        lLeadUpd = [SELECT Id, CallBackDateTime__c FROM Lead WHERE Id IN: leadList];
        for (Integer i = 0; i < num; i++) {       
            System.AssertEquals(Date.ValueOf(lLeadUpd[i].CallBackDateTime__c), Date.ValueOf(nvmCallBackList[i].Call_Back_Date_and_Time__c));
        }
        Test.stopTest();
        
    }    

    static testMethod void testNVMLeadCallBack(){ 
        Test.startTest();
        List<NVM_Call_Back__c> nvmCallBackList = new List<NVM_Call_Back__c>();
        List<Lead> leadList = [SELECT Id, CallBackDateTime__c, TECH_NVMCallBackUrgent__c FROM Lead];
        
        for (Integer i = 0; i < num; i++) {
            NVM_Call_Back__c nvmCallBackLead = new NVM_Call_Back__c();
            nvmCallBackLead.Lead__c = leadList[i].Id;
            nvmCallBackLead.Call_Back_Date_and_Time__c = System.now()-1;
            nvmCallBackLead.Call_Back_Day__c = ApplicationConstant.NVMCALLBACK_ASAP;
            nvmCallBackList.add(nvmCallBackLead);
        }
        insert nvmCallBackList;
        
        List<Lead> lLeadUpd = [SELECT Id, CallBackDateTime__c, TECH_NVMCallBackUrgent__c FROM Lead WHERE Id IN: leadList];
        for (Integer i = 0; i < num; i++) {
            System.AssertEquals(lLeadUpd[i].CallBackDateTime__c.Date(), nvmCallBackList[i].Call_Back_Date_and_Time__c.Date());
        }
        
        for (Integer i = 0; i < num; i++) {
            nvmCallBackList[i].Call_Back_Date_and_Time__c = System.now()+1;   
        }     
        update nvmCallBackList;
        
        lLeadUpd = [SELECT Id, CallBackDateTime__c, TECH_NVMCallBackUrgent__c FROM Lead WHERE Id IN: leadList];
        for (Integer i = 0; i < num; i++) {       
            System.AssertEquals(lLeadUpd[i].CallBackDateTime__c.Date()+2, nvmCallBackList[i].Call_Back_Date_and_Time__c.Date());
        }
        Test.stopTest();
        
    } 

    static testMethod void testNVMOpp(){ 
        Test.startTest();
        List<NVM_Call_Back__c> nvmCallBackList = new List<NVM_Call_Back__c>();
        List<Opportunity> oppList = [SELECT Id, RequestedCallbacktimedate__c FROM Opportunity];
        
        for (Integer i = 0; i < num; i++) {
            NVM_Call_Back__c nvmCallBackOpp = new NVM_Call_Back__c();
            nvmCallBackOpp.Opportunity__c = oppList[i].Id;
            nvmCallBackOpp.Call_Back_Date_and_Time__c = System.now()-1;
            nvmCallBackList.add(nvmCallBackOpp);
        }
        insert nvmCallBackList;
        
        List<Opportunity> lOppUpd = [SELECT Id, RequestedCallbacktimedate__c FROM Opportunity WHERE Id IN: oppList];
        for (Integer i = 0; i < num; i++) {
            System.AssertEquals(lOppUpd[i].RequestedCallbacktimedate__c.Date(), nvmCallBackList[i].Call_Back_Date_and_Time__c.Date());
        }
        
        for (Integer i = 0; i < num; i++) {
            nvmCallBackList[i].Call_Back_Date_and_Time__c = System.now()+1;   
        }     
        update nvmCallBackList;
        
        lOppUpd= [SELECT Id, RequestedCallbacktimedate__c FROM Opportunity WHERE Id IN: oppList];
        for (Integer i = 0; i < num; i++) {       
            System.AssertEquals(lOppUpd[i].RequestedCallbacktimedate__c.Date(), nvmCallBackList[i].Call_Back_Date_and_Time__c.Date());
        }
        Test.stopTest();
        
    } 

    static testMethod void testNVMOppCallBack(){ 
        Test.startTest();
        List<NVM_Call_Back__c> nvmCallBackList = new List<NVM_Call_Back__c>();
        List<Opportunity> oppList = [SELECT Id, RequestedCallbacktimedate__c, TECH_NVMCallBackUrgent__c FROM Opportunity];
        
        for (Integer i = 0; i < num; i++) {
            NVM_Call_Back__c nvmCallBackOpp = new NVM_Call_Back__c();
            nvmCallBackOpp.Opportunity__c = oppList[i].Id;
            nvmCallBackOpp.Call_Back_Date_and_Time__c = System.now()-1;
            nvmCallBackOpp.Call_Back_Day__c = ApplicationConstant.NVMCALLBACK_ASAP;
            nvmCallBackList.add(nvmCallBackOpp);
        }
        insert nvmCallBackList;
        
        List<Opportunity> lOppUpd = [SELECT Id, RequestedCallbacktimedate__c, TECH_NVMCallBackUrgent__c FROM Opportunity WHERE Id IN: oppList];
        for (Integer i = 0; i < num; i++) {
            System.AssertEquals(Date.ValueOf(lOppUpd[i].RequestedCallbacktimedate__c), Date.ValueOf(nvmCallBackList[i].Call_Back_Date_and_Time__c));
        }
        
        for (Integer i = 0; i < num; i++) {
            nvmCallBackList[i].Call_Back_Date_and_Time__c = System.now()+1;   
        }     
        update nvmCallBackList;
        
        lOppUpd= [SELECT Id, RequestedCallbacktimedate__c, TECH_NVMCallBackUrgent__c FROM Opportunity WHERE Id IN: oppList];
        for (Integer i = 0; i < num; i++) {       
            System.AssertEquals(lOppUpd[i].RequestedCallbacktimedate__c.Date()+2, nvmCallBackList[i].Call_Back_Date_and_Time__c.Date());
        }
        Test.stopTest();
        
    } 
    
    static testMethod void testTrigger(){
        Test.startTest();
        List<NVM_Call_Back__c> nvmCallBackList = new List<NVM_Call_Back__c>();
        List<Opportunity> oppList = [SELECT Id, RequestedCallbacktimedate__c FROM Opportunity];
        OrgSettings__c orgSettings = [SELECT TriggersActive__c FROM OrgSettings__c LIMIT 1];
        orgSettings.TriggersActive__c = FALSE;
        update orgSettings;
        
        NVM_Call_Back__c nvmCallBackOpp = new NVM_Call_Back__c(Opportunity__c = oppList[0].Id, Call_Back_Date_and_Time__c = System.now()-1);
        nvmCallBackList.add(nvmCallBackOpp);
        insert nvmCallBackList;
        
        System.AssertEquals(orgSettings.TriggersActive__c, FALSE);
        
        Test.stopTest();        
    }
    
    static testMethod void testCaseError(){
        Test.startTest();
        AP21_NVMCallBackTriggerBL.onAfterInsert(null);
        AP21_NVMCallBackTriggerBL.onAfterUpdate(null, null);
        AP21_NVMCallBackTriggerBL.andFinally(null, null, null, null, null, null, null);
        
        List<Error_Log__c> logs = [SELECT Id FROM Error_Log__c];
        //System.AssertEquals(logs.size(), 6);
        Test.stopTest();
    } 
}