/**
   @Author: Jerella Ledesma
   @name: AP21_NVMCallBackTriggerBL
   @CreateDate: 04.09.2016
   @Description: Handler Class for NVM Callback
   @Version <1.0>
   @Updated 05.11.2016 Atlee
 */ 
public with sharing class AP21_NVMCallBackTriggerBL   {

    // Used for logging --- Added by Dee 5/15
    public static final String CLASS_NAME = 'AP21_NVMCallBackTriggerBL';

    public static void onAfterInsert(List<NVM_Call_Back__c> lNVM){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        try{
             //Instantiation of the list, maps, records to be used.
             Map<Id, NVM_Call_Back__c> nvmCallBackList= new Map<Id, NVM_Call_Back__c>();
             Map<Id, Id> oppList = new Map<Id, Id>();
             Map<Id, Id> leadList = new Map<Id, Id>();
             Map<Id, Id> caseList = new Map<Id, Id>();
             Map<Id, Opportunity> oppListToUpdate = new Map<Id, Opportunity>();
             Map<Id, Lead> leadListToUpdate = new Map<Id, Lead>();
             Map<Id, Case> caseListToUpdate = new Map<Id, Case>();
             Set<Id> caseIds = new Set<Id>();
             Set<Id> oppIds = new Set<Id>();
             Set<Id> leadIds = new Set<Id>();
             Set<Id> nvmIds = new Set<Id>();
             //NVM_Call_Back__c nvmRec;
             User apiUser = new User();   
            
            
            for(NVM_Call_Back__c nvmRec: lNVM){
                nvmCallBackList.put(nvmRec.Id, nvmRec);
                
                if(nvmRec.Call_Back_Date_and_Time__c<>null){
                    if(nvmRec.Case__c<>null){
                        caseList.put(nvmRec.Id,nvmRec.Case__c);
                    }
                    else if(nvmRec.Opportunity__c<>null){
                        oppList.put(nvmRec.Id,nvmRec.Opportunity__c);
                    }
                    else if(nvmRec.Lead__c<>null){
                        leadList.put(nvmRec.Id,nvmRec.Lead__c);
                    }
                }
                
            }
    
            andFinally(nvmCallBackList, caseListToUpdate, caseList, oppListToUpdate, oppList, leadListToUpdate, leadList);
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'onAfterInsert()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }
    
    public static void onAfterUpdate(Map<Id, NVM_Call_Back__c> lNVMOld, Map<Id, NVM_Call_Back__c> lNVM) {
         List<Error_Log__c> logs = new List<Error_Log__c>();
        
         try{
             //Instantiation of the list, maps, records to be used.
             Map<Id, NVM_Call_Back__c> nvmCallBackList= new Map<Id, NVM_Call_Back__c>();
             Map<Id, Id> oppList = new Map<Id, Id>();
             Map<Id, Id> leadList = new Map<Id, Id>();
             Map<Id, Id> caseList = new Map<Id, Id>();
             Map<Id, Opportunity> oppListToUpdate = new Map<Id, Opportunity>();
             Map<Id, Lead> leadListToUpdate = new Map<Id, Lead>();
             Map<Id, Case> caseListToUpdate = new Map<Id, Case>();
             Set<Id> caseIds = new Set<Id>();
             Set<Id> oppIds = new Set<Id>();
             Set<Id> leadIds = new Set<Id>();
             Set<Id> nvmIds = new Set<Id>();
             User apiUser = new User();  
            
    
            
            for(NVM_Call_Back__c nvmRec: lNVM.values()){
                NVM_Call_Back__c oldnvmRec = lNVMOld.get(nvmRec.Id);
                
                if(nvmRec.Call_Back_Date_and_Time__c <> oldnvmRec.Call_Back_Date_and_Time__c){
                    nvmCallBackList.put(nvmRec.Id, nvmRec);
                    
                    if(nvmRec.Call_Back_Date_and_Time__c<>null){
                        if(nvmRec.Case__c<>null){
                            caseList.put(nvmRec.Id,nvmRec.Case__c);
                        }
                        else if(nvmRec.Opportunity__c<>null){
                            oppList.put(nvmRec.Id,nvmRec.Opportunity__c);
                        }
                        else if(nvmRec.Lead__c<>null){
                            leadList.put(nvmRec.Id,nvmRec.Lead__c);
                        }
                    }
                }
            }
            
            andFinally(nvmCallBackList, caseListToUpdate, caseList, oppListToUpdate, oppList, leadListToUpdate, leadList);
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'onAfterUpdate()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }        
    }
    
    
    public static void andFinally(Map<Id, NVM_Call_Back__c> nvmCallBackList, Map<Id, Case> caseListToUpdate, Map<Id, Id> caseList, Map<Id, Opportunity> oppListToUpdate, Map<Id, Id> oppList, Map<Id, Lead> leadListToUpdate, Map<Id, Id> leadList) {
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Event event;
        Id assignmentOfOwner;
        List<Case> NVMCase = new List<Case>();
        List<Opportunity> NVMOpp = new List<Opportunity>();
        List<Lead> NVMLead = new List<Lead>();
        try{
            if(caseList.size() > 0){
                NVMCase =  [SELECT Owner.Type, OwnerId, RequestedCallBackDateAndTime__c, TECH_NVMCallBackUrgent__c FROM Case WHERE Id IN :caseList.values()];
            }     
            
            if(oppList.size() > 0){
                NVMOpp = [SELECT OwnerId, RequestedCallbacktimedate__c, TECH_NVMCallBackUrgent__c FROM Opportunity WHERE Id IN :oppList.values()];
            }
            
            if(leadList.size() > 0){
                NVMLead = [SELECT Owner.Type, OwnerId, CallBackDateTime__c, TECH_NVMCallBackUrgent__c FROM Lead WHERE Id IN :leadList.values()];
            }               
        
            //Error checking
            Map<String, String> mapCaseAndErrors = new Map<String, String>();
            String errorLogDescription = '';
            
            
            for(Id nvm : nvmCallBackList.keySet()){ 
                if(caseList.size() > 0){
                    for(Case caseRec : NVMCase){
                        if(caseList.containsKey(nvm)){  
                            caseRec.RequestedCallBackDateAndTime__c = nvmCallBackList.get(nvm).Call_Back_Date_and_Time__c;
                            if(nvmCallBackList.get(nvm).Call_Back_Day__c == ApplicationConstant.NVMCALLBACK_ASAP) {
                                caseRec.TECH_NVMCallBackUrgent__c = (caseRec.TECH_NVMCallBackUrgent__c ? false : true);
                            }
                            caseListToUpdate.put(caseRec.Id, caseRec);
                        }
                    }
                }
                if(oppList.size() > 0){
                    for(Opportunity oppRec : NVMOpp){
                        if(oppList.containsKey(nvm)){
                            oppRec.RequestedCallbacktimedate__c = nvmCallBackList.get(nvm).Call_Back_Date_and_Time__c;
                            if(nvmCallBackList.get(nvm).Call_Back_Day__c == ApplicationConstant.NVMCALLBACK_ASAP) {
                                oppRec.TECH_NVMCallBackUrgent__c = (oppRec.TECH_NVMCallBackUrgent__c ? false : true);
                            }
                            oppListToUpdate.put(oppRec.Id, oppRec);
                        }
                    }
                }
                if(leadList.size() > 0){
                    for(Lead leadRec : NVMLead){
                        if(leadList.containsKey(nvm)){  
                            leadRec.CallBackDateTime__c = nvmCallBackList.get(nvm).Call_Back_Date_and_Time__c;
                            if(nvmCallBackList.get(nvm).Call_Back_Day__c == ApplicationConstant.NVMCALLBACK_ASAP) {
                                leadRec.TECH_NVMCallBackUrgent__c = (leadRec.TECH_NVMCallBackUrgent__c ? false : true);
                            }
                            leadListToUpdate.put(leadRec.Id, leadRec);
                        }
                    }
                }
             }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'andFinally()', CLASS_NAME, null));
        }finally{
            if(logs.isEmpty()){
                if(caseListToUpdate.size() > 0){
                    Database.SaveResult[] updateCaseList = Database.update(caseListToUpdate.values(), false);
                    logs.addAll(ApplicationConstant.getSaveResultLog(updateCaseList, 'andFinally()', CLASS_NAME, ApplicationConstant.CASE_SOBJECTTYPE, 'Update'));
                }
                
                if(oppListToUpdate.size() > 0){
                    Database.SaveResult[] updateOppList = Database.update(oppListToUpdate.values(), false);
                    logs.addAll(ApplicationConstant.getSaveResultLog(updateOppList, 'andFinally()', CLASS_NAME, 'Opportunity', 'Update'));
                }
                
                if(leadListToUpdate.size() > 0){
                    Database.SaveResult[] updateLeadList = Database.update(leadListToUpdate.values(), false);
                    logs.addAll(ApplicationConstant.getSaveResultLog(updateLeadList, 'andFinally()', CLASS_NAME, ApplicationConstant.LEAD_SOBJECTTYPE, 'Update'));
                }
            }
        
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }
    
    

}