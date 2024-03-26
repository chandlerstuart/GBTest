/**
   @Author: Atlee Martinez
   @name: AP44_NVMCallBackTriggerHandler
   @CreateDate: 05.10.2016
   @Description: Handler Class for NVMCallBackTrigger
   @Version <1.0>
 */ 
public class AP44_NVMCallBackTriggerHandler {

    //recursion flags Added By Dee June 4 -- Based on Code Review
    public static Boolean isAfterUpdateTriggerCalled = FALSE;
    public static Boolean isAfterInsertTriggerCalled = FALSE;
    
    public void afterInsert(List<NVM_Call_Back__c> newNVMList){
        if(!isAfterInsertTriggerCalled){
            AP21_NVMCallBackTriggerBL.onAfterInsert(newNVMList);
            
            isAfterInsertTriggerCalled = TRUE;
        }
    }
    
    public void afterUpdate(Map<Id, NVM_Call_Back__c> lNVMOld, Map<Id, NVM_Call_Back__c> lNVM){
        if(!isAfterUpdateTriggerCalled){
            AP21_NVMCallBackTriggerBL.onAfterUpdate(lNVMOld, lNVM);
            
            isAfterUpdateTriggerCalled = TRUE;
        }
    }
}