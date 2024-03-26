@isTest
public class AP44_NVMCallBackTriggerHandler_Test{
    @isTest private static void TestHandler(){
        
        List<Lead> leadList = AP23_TestDataFactory.createLead(101);
        insert leadList;
        
        
        List<NVM_Call_Back__c> nvmCallBackList = new List<NVM_Call_Back__c>();
        
        for (Integer i = 0; i < 101; i++) {
            NVM_Call_Back__c nvmCallBackLead = new NVM_Call_Back__c();
            nvmCallBackLead.Lead__c = leadList[i].Id;
            nvmCallBackLead.Call_Back_Date_and_Time__c = System.now()-1;
            nvmCallBackList.add(nvmCallBackLead);
        }
        
        Map<Id, NVM_Call_Back__c> lNVMOld = new Map<Id, NVM_Call_Back__c>();
        Map<Id, NVM_Call_Back__c> lNVM = new Map<Id, NVM_Call_Back__c>();
        for(NVM_Call_Back__c nvmItr : nvmCallBackList){
            lNVMOld.put(nvmItr.Id, nvmItr);
        }
        
        test.startTest();
        AP44_NVMCallBackTriggerHandler nvmObj = new AP44_NVMCallBackTriggerHandler();
        insert nvmCallBackList;
        nvmObj.afterInsert(nvmCallBackList);
        
        List<Lead> lLeadUpd = [SELECT Id, CallBackDateTime__c FROM Lead WHERE Id IN: leadList];
        for (Integer i = 0; i < 101; i++) {
            System.AssertEquals(Date.ValueOf(lLeadUpd[i].CallBackDateTime__c), Date.ValueOf(nvmCallBackList[i].Call_Back_Date_and_Time__c));
        }
        
        for (Integer i = 0; i < 101; i++) {
            nvmCallBackList[i].Call_Back_Date_and_Time__c = System.now()+1;   
        }     
        update nvmCallBackList;
        
        for(NVM_Call_Back__c nvmItr : nvmCallBackList){
            lNVM.put(nvmItr.Id, nvmItr);
        }
        nvmObj.afterUpdate(lNVMOld, lNVM); 
        
        lLeadUpd = [SELECT Id, CallBackDateTime__c FROM Lead WHERE Id IN: leadList];
        for (Integer i = 0; i < 101; i++) {       
            System.AssertEquals(
                Date.valueOf(lLeadUpd[i].CallBackDateTime__c) + 2,
                Date.valueOf(nvmCallBackList[i].Call_Back_Date_and_Time__c)
            );
        }
        test.stopTest();
    }
}