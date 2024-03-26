/**
* @author -         Patrick Villarica (Accenture)
* @date -           12/04/2016
* @description -    A batch class to process the Creation of Admin Case 
* #############Change Log#############
* Modified by     Version     Change Date
* Simon M         2.0         2017-01-30    Changed call to getDMLLog as this is now private, use getSaveResulLog instead
**/


global class AP31_BookingAdminCaseBatch implements Database.Batchable<sObject>, Database.Stateful {

    global AssignmentRule AR;
    global Database.DMLOptions dmlOpts;
    public static final String CLASS_NAME = 'AP31_BookingAdminCaseBatch';  
    
    global AP31_BookingAdminCaseBatch(){
        //Instantiate variables
        AR = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
        dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String cancelled = 'Cancellation';
        Date todayMin1 = System.Today().addDays(-1);
        String query = 'SELECT AgentTaskName__c, AgentTaskDueDate__c, AgentAttentionRequired__c, Account__c, Account__r.PersonContactId, TECH_Opportunity__r.StageName, TECH_Opportunity__r.OwnerId FROM Booking__c'+
                        ' WHERE'+
                        ' AgentTaskName__c <> \'\' AND AgentAttentionRequired__c = true AND AgentTaskDueDate__c <= Today AND Status__c !=:cancelled AND TravelReturnDate__c >=: todayMin1';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Booking__c> scope){
        //Set variables
        Set<Id> bookingIdSetCheck = new Set<Id>();
        Set<Id> bookingIDSet = new Set<Id>();
        Set<String> taskType = new Set<String>();
        //Map variables
        Map<Id, Booking__c> bookingMap = new Map<Id, Booking__c>();
        //Boolean variables
        Boolean isCreateCheckChTask = false;
        Boolean isForCaseUpdate = false;
        //List variables
        List<Task> createTaskList = new List<Task>();
        List<Case> createCaseList = new List<Case>();
        List<Case> updateCaseList = new List<Case>();
        
        //error handling
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Error_Log__c log = new Error_Log__c();
        Map<String, String> mapCaseTaskAndErrors = new Map<String, String>();
        String errorLogDescription = '';
        Map<Id, Case> updateCaseMap = new Map<Id, Case>();
         Map<Id, Task> updateTaskMap = new Map<Id, Task>();
        
        //Get all Booking Set and BookingMap
        for(Booking__c booking: scope) {
            bookingIDSet.add(booking.Id);
            bookingIdSetCheck.add(booking.Id);
            
            bookingMap.put(booking.ID, booking);
        }
        //Get all case associated with the bookings
        for(Case caseRec : [SELECT Id, OwnerId, Owner.Type, AccountId, Type, TaskType__c, Status, Booking__c, Account.PersonContactId, (Select ID, Subject FROM Tasks WHERE (Subject IN: ApplicationConstant.ADMINTASKSET OR Subject Like: ApplicationConstant.ADMINTASKSUBJ_CHECKCH) AND IsClosed = false ) FROM Case WHERE Status <>: ApplicationConstant.CASE_STATUS_CLOSED AND Type =: ApplicationConstant.CASETYPE_ADMIN AND Booking__c IN: bookingIDSet]) 
        {
            bookingIdSetCheck.remove(caseRec.Booking__c); //Removing the booking in the set since it already have an existing Admin Case
            isForCaseUpdate = false;
            isCreateCheckChTask = true;
            
            if(caseRec.TaskType__c <> null) {
            
                if(!caseRec.TaskType__c.contains(ApplicationConstant.CASETASKTYPE_SUPPLIER)) {
                
                    caseRec.TaskType__c = caseRec.TaskType__c + ';'+ApplicationConstant.CASETASKTYPE_SUPPLIER;
                    isForCaseUpdate = true;
                }
            } else {
            
                caseRec.TaskType__c = ApplicationConstant.CASETASKTYPE_SUPPLIER;
                isForCaseUpdate = true;
            }
            //Include the Case forUpdate
            if(isForCaseUpdate) {
                updateCaseList.add(caseRec);
            }
            
            if(caseRec.Tasks.size() > 0) {
                
                for (Task t: caseRec.Tasks) {
                    //Check if there is an existing task for us not to create duplicate   
                    if(t.Subject == ApplicationConstant.TASKSUBJ_CHECKCH + bookingMap.get(caseRec.Booking__c).AgentTaskName__c) {
                        isCreateCheckChTask = false;
                    }
                 }
            }
            //If no existing Check Clubhouse task for the Agent Task Name then create a task
            if(isCreateCheckChTask) {
                
                createTaskList.add(AP32_AdminCaseUtility.createTask(ApplicationConstant.TASKSUBJ_CHECKCH + bookingMap.get(caseRec.Booking__c).AgentTaskName__c, date.newinstance(bookingMap.get(caseRec.Booking__c).AgentTaskDueDate__c.year(), bookingMap.get(caseRec.Booking__c).AgentTaskDueDate__c.month(), bookingMap.get(caseRec.Booking__c).AgentTaskDueDate__c.day()), caseRec.Id, caseRec.Account.PersonContactId, caseRec.OwnerId, caseRec.Owner.Type));
            }
        }
        //If there is a booking without an existing Admin Case then create a Case
        if(bookingIdSetCheck.size() <> 0) {
            for(Id bId: bookingIdSetCheck){
                if(bookingMap.containsKey(bId)) {
                 taskType.clear();
                 taskType.add(ApplicationConstant.CASETASKTYPE_SUPPLIER);
                 
                 createCaseList.add(AP32_AdminCaseUtility.createAdminCase(ApplicationConstant.ADMINCASESUBJ, bId, bookingMap.get(bId).Account__c, bookingMap.get(bid).Account__r.PersonContactId, bookingMap.get(bid).TECH_Opportunity__r.StageName, bookingMap.get(bid).TECH_Opportunity__r.OwnerId, taskType, dmlOpts));   
                }
            }
            
        }
        
        for(Case c: createCaseList){
            updateCaseMap.put(c.Id, c);
        }
        
        if(createCaseList.size() <> 0) {
            logs.addAll(getResultLogs(Database.insert(createCaseList, false), 'Case', 'Insert'));
            
            for(Case caseRec : [SELECT Id, OwnerId, Owner.Type, AccountId, Type, TaskType__c, Status, Booking__c, Account.PersonContactId FROM Case WHERE Status <>: ApplicationConstant.CASE_STATUS_CLOSED AND Type =: ApplicationConstant.CASETYPE_ADMIN AND Booking__c IN: bookingIdSetCheck]) 
            {                
                createTaskList.add(AP32_AdminCaseUtility.createTask(ApplicationConstant.TASKSUBJ_CHECKCH + bookingMap.get(caseRec.Booking__c).AgentTaskName__c, date.newinstance(bookingMap.get(caseRec.Booking__c).AgentTaskDueDate__c.year(), bookingMap.get(caseRec.Booking__c).AgentTaskDueDate__c.month(), bookingMap.get(caseRec.Booking__c).AgentTaskDueDate__c.day()), caseRec.Id, caseRec.Account.PersonContactId, caseRec.OwnerId, caseRec.Owner.Type));
            }
        }
        
        for(Task t: createTaskList){
            updateTaskMap.put(t.Id, t);
        }
        
        mapCaseTaskAndErrors.clear();
        
        if(createTaskList.size() <> 0) {
            logs.addAll(getResultLogs(Database.insert(createTaskList, false), 'Task' , 'Insert'));
        }
        
        updateCaseMap.clear();
        mapCaseTaskAndErrors.clear();
        
        for(Case c: createCaseList){
            updateCaseMap.put(c.Id, c);
        }
        
        if(updateCaseList.size() <> 0) {
            logs.addAll(getResultLogs(Database.update(updateCaseList, false), 'Case', 'Update'));
        }

        if(!logs.isEmpty()){
            Database.insert(logs, false);
        }
    }
    
    global void finish(Database.BatchableContext BC){
        //Execute finish method
    }

    static List<Error_Log__c> getResultLogs(List<Database.SaveResult> listSaveResults, String objString, String dmlString)   {
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        //2017-01-30 : SM : getDMLLog is now private so call getSaveResultLog instead
        errorLogs.addAll(ApplicationConstant.getSaveResultLog(listSaveResults, 'execute', CLASS_NAME, objString, dmlString));
        /*
        Error_Log__c log = new Error_Log__c();              
        for(Database.SaveResult saveResult : listSaveResults){
            log = ApplicationConstant.getDMLLog(saveResult, 'execute()', CLASS_NAME, objString, dmlString);                    
            errorLogs.add(log);                
        }
        */
        return errorLogs;
    }
}