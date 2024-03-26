/**
   @Author: Christian Bolima
   @name: AP30_ScheduledLeadAssignmentBatch 
   @CreateDate: 13.04.2016
   @Description: Scheduled batch for AP27_LeadAssignmentUtility
   @Version <1.0>
 */ 
 
 /**
 ** @Edited by: R.Bregente, I.Acorda
 ** @Class Name: AP30_ScheduledLeadAssignmentBatch 
 ** @Description: Updated AP30_ScheduledLeadAssignmentBatch logic and exception handling
 **/

 /**
 ** @Edited by: Simon M - 2017-01-30
 ** @Class Name: AP30_ScheduledLeadAssignmentBatch 
 ** @Description: getDMLLog method is now private, so make call to getSaveResultLog instead
 **/

global with sharing class AP30_ScheduledLeadAssignmentBatch implements Database.Batchable<sObject>, Database.Stateful{

    // Used for logging --- Added by Ivy 6/03
    public static final String CLASS_NAME = 'AP30_ScheduledLeadAssignmentBatch';  
   
    global Database.QueryLocator start(Database.BatchableContext BC){
        Set<Id> groupIdSet = new Set<Id>();
        if (!ApplicationConstant.TEAM_SET.isEmpty()){
            String grpQuery = 'select Id from Group where Name IN (';
            for (String sName : ApplicationConstant.TEAM_SET){
                grpQuery += '\'' + sName + '\',';
            }
            grpQuery = grpQuery.substring(0, grpQuery.length()-1);
            grpQuery += ')';
            for (Group g : Database.query(grpQuery)){
                groupIdSet.add(g.Id);
            }
        }
        


        String query = 'SELECT id, name, CountriesInterested__c, OwnerId, Account__c, AssignedtoSAA__c, TravelGroupSize__c, LastName, ' +
                       'FirstName, Company, Status, LeadSource, Email, Phone, Rating, SalesRegion__c, CustomerLifetimeValue__c, ' +
                       'IsLeadAssigned__c, SpecialistSales__c FROM Lead WHERE AssignedtoSAA__c != true AND IsLeadAssigned__c = false AND IsConverted = false AND SalesRegion__c != null AND TravelGroupSize__c != null'; //Added criteria for salesregion so on for defect D-0432
        
        if (!ApplicationConstant.TEAM_SET.isEmpty()){

            query += ' AND OwnerId IN (';

            for (Id sId : groupIdSet){
                query += '\'' + sId + '\',';
            }

            query = query.substring(0, query.length()-1);
            query += ')';
        }


        /*Boolean isFirst = true;
        if(!ApplicationConstant.TEAM_SET.isEmpty()){
            for(String setName : ApplicationConstant.TEAM_SET){
                if(!isFirst){
                    query += ' OR';
                }
                else{
                    query += ' AND (';
                    isFirst = false;
                }
                
                query += ' Owner.Name = \'' + setName + '\'';
            }
            
            query += ')';
        }
        */
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Lead> scope){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Error_Log__c log = new Error_Log__c();
        List<Lead> updatedLead = new List<Lead>();
        System.debug('AP30_ScheduledLeadAssignmentBatch --- size: ' + scope.size());
        updatedLead = AP27_LeadAssignmentUtility.doSAAMatching(scope, false);
        system.debug('updatedLead : ' + updatedLead);
        
        //for Error Handling
        Map<String, String> mapLeadAndErrors = new Map<String, String>();
        
        if(updatedLead.size() > 0){
            Database.SaveResult[] updateLeadList = Database.update(updatedLead, false);
            //2017-01-30 : SM : getDMLLog is now private so call getSaveResultLog instead
            logs.addAll(ApplicationConstant.getSaveResultLog(updateLeadList, 'execute', CLASS_NAME, 'Lead','Update'));


            String errorLogDescription;
            for(Integer i=0; i< updateLeadList.size(); i++){
                Database.SaveResult result = updateLeadList[i];
                // SUCCESS
                if(updateLeadList.get(i).isSuccess()){
                    System.Debug('>>SUCCESS : Id<<'+updateLeadList.get(i).getId() + ' Name: ' + updatedLead.get(i).Name);
                }
                // ERROR
                else{
                    List<Database.Error> lstErrors = result.getErrors();
                    for(Integer j=0; j< lstErrors.size(); j++){   
                        //String errorDescription = '';
                        String errorDescription = ApplicationConstant.GENERAL_EXCEPTION_GET_STATUS_CODE +' '+ lstErrors.get(j).getStatusCode() + '\n' + ApplicationConstant.GENERAL_EXCEPTION_GET_FIELDS +' '+ lstErrors.get(j).getFields() + '\n' + ApplicationConstant.GENERAL_EXCEPTION_GET_ERROR_MESSAGE +' '+ lstErrors.get(j).getMessage() + '\n';
                        mapLeadAndErrors.put(updateLeadList.get(i).Id, errorDescription);
                        System.Debug('>>ERROR : updateLeadList.get(i).Id<<'+updateLeadList.get(i).Id);     
                    }
                    /*
                    log = ApplicationConstant.getDMLLog(updateLeadList[i], 'execute', CLASS_NAME, 'Lead', 'Update');
                    log.trace__c += ' \n Record Name: ' + updatedLead.get(i).Name;
                    logs.add(log);
                    */
                }
            }
            
             if(!mapLeadAndErrors.isEmpty()){
                for(Lead ldErr : updatedLead){
                    if( mapLeadAndErrors.containsKey(ldErr.Id) ){
                            ldErr.addError( mapLeadAndErrors.get(ldErr.Id) );
                    }
                }
            }
            
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
        
    }
    
    
    
    global void finish(Database.BatchableContext BC){
        
    }
}