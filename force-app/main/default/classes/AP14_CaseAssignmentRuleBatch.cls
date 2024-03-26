/**
* @Class Name: AP14_CaseAssignmentRuleBatch 
* @developer:  Aldric Seril 
* @date:       04/05/2016
* @description: reassigning of Queue in Case Object
* @Modification: 2017-01-30 : Simon M : Changed call to getDMLLog as this is now private, use getSaveResultLog instead
*/


global class AP14_CaseAssignmentRuleBatch implements Database.Batchable<sObject>
{
    public static final String CLASS_NAME = 'AP14_CaseAssignmentRuleBatch';  
    
    /**
    * @description 
    * @param BatchableContext which is a predefined parameter
    * @return Database.QueryLocator
    */ 
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        String query = 'SELECT Id,Owner.type,Owner.Name, Status, TECH_IsUrgent__c FROM Case WHERE Owner.type = \'Queue\' AND Status = \'New\' ';
        system.debug('*** -- query in Start method -- ***');
        return Database.getQueryLocator(query);
    }
    
    /* @description Executes the business logic and reassign the owner if there is no available Sales Attribute Agent.
    * 
    * @param BC a BatchableContext which is a predefined parameter
    * @param caseList is a list of sObjects from the initial database query
    * @return void
    */ 
    global void execute(Database.BatchableContext BC, List<Case> caseList)
    {
        Set<String> ownerStringSet = new Set<String>();
        Set<ID> caseID = new Set<ID>();
        Set<Case> Urgentcase = new Set<Case>();
        Set<String> saaSet = new Set<String>();
        Set<String> CaseQueueSet = new Set<String>();
        List<Case> caseUpdate = new List<Case>();
        Map<String, String> caseRouteMap = new Map<String,String>();
        Map<String, Group> queueMap = new Map<String, Group>();
        Map<Id, Case> updateCaseMap = new Map<Id, Case>();
        Map<String, String> mapCaseAndErrors = new Map<String, String>();
        String errorLogDescription = '';
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Error_Log__c log = new Error_Log__c();
                
        List<CaseRoutes__c> csr = CaseRoutes__c.getall().values();

        for(CaseRoutes__c caseRoutes : csr){
            caseRouteMap.put(caseRoutes.Name, caseRoutes.RouteName__c);
            CaseQueueSet.add(caseRoutes.Name); 
        }
        
        for(Case cs : caseList ){
            if(CaseQueueSet.contains(cs.Owner.Name)){ 
            	ownerStringSet.add(cs.Owner.Name); 
            }        
        }

        for(Sales_Agent_Attributes__c SAA : [Select id,Online__c,Queue__c, Available__c from Sales_Agent_Attributes__c where Queue__c IN: ownerStringSet AND Available__c = TRUE]){
        
            saaSet.add(SAA.Queue__c);
        
        }
        
        for(Group grp: [Select Id, Name from group]){ 
        	queueMap.put(grp.Name, grp);
        }
           
        for(Case Cases: caseList ){     
            if((!saaSet.contains(Cases.owner.Name)) && caseRouteMap.containskey(Cases.Owner.Name) && queueMap.containskey(caseRouteMap.get(Cases.Owner.Name))){
                
                Cases.ownerid = Cases.TECH_IsUrgent__c ? queueMap.get(AP35_AppConstantForScheduledClass.QUEUE_CS_URGENT).Id : queueMap.get(caseRouteMap.get(Cases.Owner.Name)).Id;
                                
                //if(Cases.TECH_IsUrgent__c){
                //    Cases.ownerid = queueMap.get(AP35_AppConstantForScheduledClass.QUEUE_CS_URGENT).Id;
                //}
                //else{
                //    Cases.ownerid = queueMap.get(caseRouteMap.get(Cases.Owner.Name)).Id;
                //}
            
                caseUpdate.add(cases);
                updateCaseMap.put(Cases.Id, Cases);
            }
        }

        
        Database.SaveResult[] caseUpdateList = database.update(caseUpdate, false);
        //2017-01-30 : SM : getDMLLog is now private so call getSaveResultLog instead
        logs.addAll(ApplicationConstant.getSaveResultLog(caseUpdateList, 'execute', CLASS_NAME, 'Case','Update'));

        for(Integer i=0; i<caseUpdateList.size(); i++){
            Database.SaveResult result = caseUpdateList[i];

            if(!caseUpdateList.get(i).isSuccess()){
            	// ERROR
                List<Database.Error> lstErrors = result.getErrors();
                for(Integer j=0; j< lstErrors.size(); j++){     
                    //String errorDescription = '';
                    String errorDescription = ApplicationConstant.GENERAL_EXCEPTION_GET_STATUS_CODE +' '+ lstErrors.get(j).getStatusCode() + '\n' + ApplicationConstant.GENERAL_EXCEPTION_GET_FIELDS +' '+ lstErrors.get(j).getFields() + '\n' + ApplicationConstant.GENERAL_EXCEPTION_GET_ERROR_MESSAGE +' '+ lstErrors.get(j).getMessage() + '\n';
                    //errorDescription += ApplicationConstant.GENERAL_EXCEPTION_GET_STATUS_CODE +' '+ lstErrors.get(j).getStatusCode() + '\n';
                    //errorDescription += ApplicationConstant.GENERAL_EXCEPTION_GET_FIELDS +' '+ lstErrors.get(j).getFields() + '\n';
                    //errorDescription += ApplicationConstant.GENERAL_EXCEPTION_GET_ERROR_MESSAGE +' '+ lstErrors.get(j).getMessage() + '\n';
                    mapCaseAndErrors.put( caseUpdateList.get(i).Id, errorDescription);
                    System.Debug('>>ERROR : caseUpdateList.get(i).Id<<'+caseUpdateList.get(i).Id);
                }
                /*
                log = ApplicationConstant.getDMLLog(caseUpdateList[i], 'execute', CLASS_NAME, 'Case', 'Update');
                log.trace__c += ' \n Record Name: ' + caseUpdate.get(i).CaseNumber;
                logs.add(log);
                */
            }
        }
        
        if( mapCaseAndErrors.size() > 0 && updateCaseMap.size() > 0 ){   
            for(Case cas : updateCaseMap.values()){ if( mapCaseAndErrors.containsKey(cas.Id) ){ cas.addError( mapCaseAndErrors.get(cas.Id) ); } }
        }
        
        if(!logs.isEmpty()){
            Database.insert(logs, false);
        }
    }
    
    
    /*
    * @description A method which executes the final actions of the class.
    * @return void
    */ 
    global void finish(Database.BatchableContext BC)
    {

    }
}