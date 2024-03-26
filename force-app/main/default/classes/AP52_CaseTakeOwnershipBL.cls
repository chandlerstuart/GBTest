/**
   @Author: Pat Villarica
   @name: AP52_CaseTakeOwnershipBL
   @CreateDate: 05.16.2016
   @Description: Business Logic Class for Case Custom Button 'Take Ownership'
   @Version <1.0>
 */ 

global class AP52_CaseTakeOwnershipBL{
    
    public static final String CLASS_NAME = 'AP52_CaseTakeOwnershipBL';
    
    /**
       *  This method is used to update the Owner field on Task/Event related to the Case upon clicking the 'Take Ownership'.
       *  @name: updateTaskEventOwnerId
       *  @developer: Pat Villarica 05/16/2016
       *  @param: caseList - get caseId of Case Id: Id datatype
       *                   - get prevOwnerId of Previous Owner: Id datatype
       *                   - get recordTypeId of Case Record Type: Id datatype
       */
    WebService static void updateTaskEventOwnerId(Id caseId, Id prevOwnerId, Id recordTypeId) {
    
        List<Error_Log__c> logs = new List<Error_Log__c>();
        List<Task> updateTaskList = new List<Task> ();
        List<Event> updateEventList = new List<Event> ();
        Set<Id> caseRecordTypeIds = new Set<Id> (); 
        
        caseRecordTypeIds.add(ApplicationConstant.CASERECTYPEID_AMENDMENT);
        caseRecordTypeIds.add(ApplicationConstant.CASERECTYPEID_COMPLAINT);
        caseRecordTypeIds.add(ApplicationConstant.CASERECTYPEID_SERVICECASE);
        caseRecordTypeIds.add(ApplicationConstant.CASERECTYPEID_ADMIN);
        
        if(caseRecordTypeIds.contains(recordTypeId)) {
        
            for(Case caseRec: [Select OwnerId, (Select OwnerId FROM Tasks Where IsClosed = false AND OwnerId =: prevOwnerId), (Select OwnerId FROM Events Where EventIsClosed__c = false AND OwnerId =: prevOwnerId) From Case Where ID =: caseId]) {
            
                if(caseRec.Tasks.size() > 0) {
                    
                    for(Task t: caseRec.Tasks) {
                    
                        t.OwnerId = UserInfo.getUserId();                    
                        updateTaskList.add(t);
                    }
                }
                
                if(caseRec.Events.size() > 0) {
                    
                    for(Event e: caseRec.Events) {
                    
                        e.OwnerId = UserInfo.getUserId();                    
                        updateEventList.add(e);
                    }
                }
            
            }
        }
        
        if(updateTaskList.size() > 0) {

            Database.SaveResult[] srTask = Database.update(updateTaskList, false);
            logs.addAll(ApplicationConstant.getSaveResultLog(srTask, 'updateTaskEventOwnerId', CLASS_NAME, 'Task', 'Update'));
        }
        
        if(updateEventList.size() > 0) {

            Database.SaveResult[] srEvent = Database.update(updateEventList, false);
            logs.addAll(ApplicationConstant.getSaveResultLog(srEvent, 'updateTaskEventOwnerId', CLASS_NAME, 'Event', 'Update'));            
        }
        
        if(!logs.isEmpty()){
        
                Database.insert(logs, false);
        }
    }
}