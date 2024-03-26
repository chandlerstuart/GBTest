/**
 ** @author: Alyana Navarro 25/02/2016
 ** Class Name: AP28_ManualLeadAssignmentBatch
 ** @Description: Prototype Manual Lead Assignment batch. This executes when the button (Assign All Leads) is clicked in the Lead record.
 **
 **/

/**
 ** @Edited by: Nicole De Guzman 03/04/2016
 ** @Class Name: AP28_ManualLeadAssignmentBatch
 ** @Description: Updated AP28_ManualLeadAssignmentBatch.start to store the list of lead records to variable 'query'
 **
 **/

 /**
 ** @Edited by: Simon M 30/01/2017
 ** @Class Name: AP28_ManualLeadAssignmentBatch
 ** @Description: Changed call to getDMLLog as this method is now private.  Now calls getSaveResultLog
 **
 **/
global with sharing class AP28_ManualLeadAssignmentBatch implements Database.Batchable<sObject>, Database.Stateful{ 

    // Used for logging --- Added by Dee 5/19
    public static final String CLASS_NAME = 'AP28_ManualLeadAssignmentBatch';  
     
    public Set<Id> userTeam;
 
    global AP28_ManualLeadAssignmentBatch(Set<Id> teamIds) {    
        userTeam = teamIds;
        System.debug('---- AP28_ManualLeadAssignmentBatch ---- \n'+ userTeam);
    }
   
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT id, name, CountriesInterested__c, OwnerId, Account__c, AssignedtoSAA__c, TravelGroupSize__c, LastName, ' +
                       'FirstName, Company, Status, LeadSource, Email, Phone, Rating, SalesRegion__c, CustomerLifetimeValue__c, ' +
                       'IsLeadAssigned__c, SpecialistSales__c FROM Lead WHERE OwnerId IN: userTeam';
        System.debug('---- AP28_ManualLeadAssignmentBatch ---- \n'+ query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Lead> scope){
         List<Error_Log__c> logs = new List<Error_Log__c>();
        Error_Log__c log = new Error_Log__c();
        List<Lead> updatedLeads = new List<Lead>();
        System.debug('debivy');

        /* Defect D-0577
         * remove the dependency in the code which says that the user 
         * who presses the button must have a record in the Sales Agent Attributes 
         * object of record type "Sales Manager". 
        */
        
        updatedLeads = AP27_LeadAssignmentUtility.doSAAMatching(scope, true);


        system.debug('updatedLeads : ' + updatedLeads);
        //for Error Handling
        Map<String, String> mapLeadAndErrors = new Map<String, String>();
        Set<Id> agentIds = new Set<Id>();
        List<Lead> failedLeads = new List<Lead>();
        
        if(updatedLeads.size() > 0){
            
            logs.addAll(getResultLogs(Database.update(updatedLeads, false)));
            //Database.SaveResult[] updateLeadList = Database.update(updatedLeads, false);
            //String errorLogDescription;
            //for(Integer i=0; i< updateLeadList.size(); i++){
            //    Database.SaveResult result = updateLeadList[i];
            //    // SUCCESS
            //    if(updateLeadList.get(i).isSuccess()){
            //        System.Debug('>>SUCCESS : updateLeadList.get(i).getId()<<'+updateLeadList.get(i).getId());
            //    }
            //    // ERROR
            //    else{
            //        List<Database.Error> lstErrors = result.getErrors();
            //        for(Integer j=0; j< lstErrors.size(); j++){   
            //            String errorDescription = '';
            //            errorDescription += ApplicationConstant.GENERAL_EXCEPTION_GET_STATUS_CODE +' '+ lstErrors.get(j).getStatusCode() + '\n';
            //            errorDescription += ApplicationConstant.GENERAL_EXCEPTION_GET_FIELDS +' '+ lstErrors.get(j).getFields() + '\n';
            //            errorDescription += ApplicationConstant.GENERAL_EXCEPTION_GET_ERROR_MESSAGE +' '+ lstErrors.get(j).getMessage() + '\n';
            //            mapLeadAndErrors.put(updateLeadList.get(i).Id, errorDescription);
            //            System.Debug('>>ERROR : updateLeadList.get(i).Id<<'+updateLeadList.get(i).Id);
            //        }
                    
            //        log = ApplicationConstant.getDMLLog(updateLeadList[i], 'execute', CLASS_NAME, 'Lead', 'Update');
            //        log.trace__c += ' \n Record Name: ' + updatedLeads.get(i).Name;
            //        logs.add(log);
            //    }
            //}
            
            //if(!mapLeadAndErrors.isEmpty()){
            //    for(Lead ldErr : updatedLeads){
            //        if( mapLeadAndErrors.containsKey(ldErr.Id) ){
            //                ldErr.addError( mapLeadAndErrors.get(ldErr.Id) );
            //        }
            //    }
            //}
                        
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }
    
    global void finish(Database.BatchableContext BC){
        
    }

    private static List<Error_Log__c> getResultLogs(List<Database.SaveResult> listSaveResults)   {
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        //2017-01-30 : SM : getDMLLog is now private so call getSaveResultLog instead
        errorLogs.addAll(ApplicationConstant.getSaveResultLog(listSaveResults, 'execute', CLASS_NAME, 'Lead', 'Update'));
        /*
        Error_Log__c log = new Error_Log__c();              
        for(Database.SaveResult saveResult : listSaveResults){
            log = ApplicationConstant.getDMLLog(saveResult, 'execute()', CLASS_NAME, 'Lead', 'Update');                    
            errorLogs.add(log);                
        }
        */
        return errorLogs;
    }
}