/**
   @Author: Recuerdo Bregente
   @name: AP39_AssignSpecialistSalesBatch 
   @CreateDate: 25.04.2016
   @Description: Scheduled batch for Leads assigned to Specialist Sales Team
   @Version <1.0>
 */ 

global with sharing class AP39_AssignSpecialistSalesBatch implements Database.Batchable<sObject>, Database.Stateful{

    public static final String CLASS_NAME = 'AP39_AssignSpecialistSalesBatch';
   
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT id, name, CountriesInterested__c, OwnerId, Account__c, AssignedtoSAA__c, TravelGroupSize__c, LastName, ' +
                       'FirstName, Company, Status, LeadSource, Email, Phone, Rating, SalesRegion__c, CustomerLifetimeValue__c, ' +
                       'IsLeadAssigned__c, SpecialistSales__c FROM Lead WHERE AssignedtoSAA__c = false AND IsConverted = false AND SpecialistSales__c = true ' +
                        ' AND OwnerId IN (SELECT Id FROM Group WHERE Type = \'Queue\' AND DeveloperName = \'SSpecialistSalesTeam\')'; 
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Lead> scope){


        if(!scope.isEmpty()){
            AP27_LeadAssignmentUtility.assignSpecialistTeam(scope, false);
        }

        //List<Lead> updatedLead = new List<Lead>();
        //List<Error_Log__c> logs = new List<Error_Log__c>();

        //updatedLead.addAll(scope);
        
        //if(!updatedLead.isEmpty()){
        //    updatedLead = AP27_LeadAssignmentUtility.assignSpecialistTeam(updatedLead, false);
        //    system.debug('updatedLead : ' + updatedLead);
        //}
        
        //if(ApplicationConstant.getCount(updatedLead) > 0){ //updatedLead.size() > 0 may cause exception
        //    Database.SaveResult[] updateLeadList = Database.update(updatedLead, false);
        //    String errorLogDescription;
        //    for(Integer i=0; i< ApplicationConstant.getSaveCount(updateLeadList); i++){ //updateLeadList.size()
        //        Database.SaveResult result = updateLeadList[i];
        //        // SUCCESS
        //        if(updateLeadList.get(i).isSuccess()){
        //            System.Debug('>>SUCCESS : updateLeadList.get(i).getId()<<'+updateLeadList.get(i).getId());
        //        }
        //        // ERROR
        //        else{
        //            List<Database.Error> lstErrors = result.getErrors();
        //            for(Integer j=0; j< ApplicationConstant.getErrorCount(lstErrors); j++){    // lstErrors.size()   
        //                System.Debug('>>ERROR : updateLeadList.get(i).Id<<'+updateLeadList.get(i).Id);
                        
        //            //DevName: AAngeles 05-19-2016
                    
        //                if(updatedLead.size() > 0) {

        //                    Database.SaveResult[] srLead = Database.update(updatedLead, false);
        //                    logs.addAll(ApplicationConstant.getSaveResultLog(srLead, 'AP39_AssignSpecialistSalesBatch.execute', CLASS_NAME , 'Lead', 'Update'));            
        //                }
                    
        //                if(!logs.isEmpty()){
    
        //                    Database.insert(logs, false);
        //                }

        //            }
        //        }
        //    }
        //}
        ////END IF
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}