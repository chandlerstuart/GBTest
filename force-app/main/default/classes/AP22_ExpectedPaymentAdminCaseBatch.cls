/**
* @author -         Patrick Villarica (Accenture)
* @date -           12/04/2016
* @description -    A batch class to process the Creation of Admin Case for 
* #############Change Log#############
* Modified by     Version     Change Date        Change Log
* cgaylan          2.0        05/14/2016         Implement Code Review Findings
* Simon M          2.1        30/01/2017         Added new call to getSaveResultLog as getDMLLog is now private
**/

global class AP22_ExpectedPaymentAdminCaseBatch implements Database.Batchable<sObject>, Database.Stateful {
    global AssignmentRule AR;
    global Database.DMLOptions dmlOpts;
    public static final String CLASS_NAME = 'AP22_ExpectedPaymentAdminCaseBatch';  
    
    global AP22_ExpectedPaymentAdminCaseBatch(){
        //Instantiate variables   
        AR = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
        dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        Set<String> epType = ApplicationConstant.EPTYPESET;
        String cancelled = 'Cancellation';
        Date todayMin1 = System.Today().addDays(-1);
        String query = 'SELECT Id, Name, Booking__c, Booking__r.TECH_Opportunity__r.StageName, Booking__r.TECH_Opportunity__r.OwnerId, Booking__r.Account__c, Booking__r.Account__r.PersonContactId, Expected_Amount__c, Outstanding_Balance__c, Expected_Payment_Date__c, ExpectedPaymentType__c FROM Expected_Payment__c'+
                        ' WHERE ExpectedPaymentType__c IN: epType'+
                        ' AND Outstanding_Balance__c <> 0'+
                        ' AND Expected_Payment_Date__c <= Today AND Booking__r.Status__c != :cancelled AND Booking__r.TravelReturnDate__c >=: todayMin1';     
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Expected_Payment__c> scope){
        //Map Variables to store the ExpectedPayment details
        Map<Id, Expected_Payment__c> epIDepositMap = new Map<Id, Expected_Payment__c>();
        Map<Id, Expected_Payment__c> epDBalanceMap = new Map<Id, Expected_Payment__c>();
        Map<Id, Expected_Payment__c> epFBalanceMap = new Map<Id, Expected_Payment__c>();
        //Map<Id, Expected_Payment__c> bookingTaskMap = new Map<Id, Expected_Payment__c>();
        Map<Id, Expected_Payment__c> bookingEpMap = new Map<Id, Expected_Payment__c>();     
        //Set Variables
        Set<Id> bookingIdSet = new Set<Id>();
        Set<Id> bookingIdSetCheck = new Set<Id>();
        Set<Id> epbookingIDSet = new Set<Id>();
        Set<String> taskType = new Set<String>();
        //Boolean Variables
        Boolean isCreateIDeposit = false;
        Boolean isCreateDBalance = false;
        Boolean isCreateFBalance = false;
        //Boolean isCreateTransferDetail = false;
        //Boolean isCreateRoomingList = false;
        Boolean isForCaseUpdate = false;
        //List Variables
        List<Task> createTaskList = new List<Task>();
        List<Case> createCaseList = new List<Case>();
        List<Case> updateCaseList = new List<Case>();
        
        //for AdminCase error handling
        Map<String, String> mapCreateCaseAndErrors = new Map<String, String>();
        Map<String, String> mapUpdateCaseAndErrors = new Map<String, String>();
        Map<String, String> mapCreateTaskAndErrors = new Map<String, String>();
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Error_Log__c log = new Error_Log__c();
        
        for(Expected_Payment__c epRec: scope)
        {
            
            if(!bookingEpMap.containsKey(epRec.Booking__c)) {
                bookingEpMap.put(epRec.Booking__c, epRec);
            }
            
            if(epRec.Outstanding_Balance__c <> 0) {
            
                if(epRec.ExpectedPaymentType__c == ApplicationConstant.EPAYMENTTYPEPARTIALDEPOSIT) {
                    epIDepositMap.put(epRec.Booking__c, epRec);
                    
                    epbookingIDSet.add(epRec.Booking__c);
                    bookingIdSetCheck.add(epRec.Booking__c);
                }
                if(epRec.ExpectedPaymentType__c == ApplicationConstant.EPAYMENTTYPEFULLDEPOSIT) {
                    epDBalanceMap.put(epRec.Booking__c, epRec);
                    
                    epbookingIDSet.add(epRec.Booking__c);
                    bookingIdSetCheck.add(epRec.Booking__c);
                }
                if(epRec.ExpectedPaymentType__c == ApplicationConstant.EPAYMENTTYPEFULLBALANCE) {
                    epFBalanceMap.put(epRec.Booking__c, epRec);
                    //bookingTaskMap.put(epRec.Booking__c, epRec);
                    
                    epbookingIDSet.add(epRec.Booking__c);
                    bookingIdSetCheck.add(epRec.Booking__c);
                }
            }/* else {
                if(epRec.ExpectedPaymentType__c == ApplicationConstant.EPAYMENTTYPEFULLBALANCE) {
                    bookingTaskMap.put(epRec.Booking__c, epRec);
                
                    epbookingIDSet.add(epRec.Booking__c);
                    bookingIdSetCheck.add(epRec.Booking__c);
                }
            }*/
        }
        
        //Get all Open Admin Case and its related Task
        for(Case caseRec : [SELECT Id, OwnerId, Owner.Type, AccountId, Type, TaskType__c, Status, Booking__c, Account.PersonContactId, (Select ID, Subject FROM Tasks WHERE Subject IN: ApplicationConstant.ADMINTASKSET AND IsClosed = false ) FROM Case WHERE Status <>: ApplicationConstant.CASE_STATUS_CLOSED AND Type =: ApplicationConstant.CASETYPE_ADMIN AND Booking__c IN: epbookingIDSet]) 
        {
            bookingIdSetCheck.remove(caseRec.Booking__c); //Removing the booking in the set since it already have an existing Admin Case
            isForCaseUpdate = false;
            
            //Check if we need to update Case TaskType__c to include Payment
            if(epIDepositMap.containsKey(caseRec.Booking__c) || epDBalanceMap.containsKey(caseRec.Booking__c) || epFBalanceMap.containsKey(caseRec.Booking__c)) {
                //Check if there is already a TaskType for the Case record
                if(caseRec.TaskType__c <> null) {
                    
                    if(!caseRec.TaskType__c.contains(ApplicationConstant.CASETASKTYPE_PAYMENT)) {
                        
                        caseRec.TaskType__c = caseRec.TaskType__c + ';'+ApplicationConstant.CASETASKTYPE_PAYMENT;
                        isForCaseUpdate = true;
                    }
                } else {
                    
                    caseRec.TaskType__c = ApplicationConstant.CASETASKTYPE_PAYMENT;
                    isForCaseUpdate = true;
                }
            }
            
            //Check if we need to update Case TaskType__c to include Customer
            /*if(bookingTaskMap.containsKey(caseRec.Booking__c)) {
                
                if(bookingTaskMap.get(caseRec.Booking__c).Booking__r.TransferDetailsRequired__c || bookingTaskMap.get(caseRec.Booking__c).Booking__r.RoomingListRequired__c) {
                    //Check if there is already a TaskType for the Case record
                    if(caseRec.TaskType__c <> null) {
                       
                       if(!caseRec.TaskType__c.contains(ApplicationConstant.CASETASKTYPE_CUSTOMER)) {
                            
                            caseRec.TaskType__c = caseRec.TaskType__c + ';'+ApplicationConstant.CASETASKTYPE_CUSTOMER;
                            isForCaseUpdate = true;
                        }
                    } else {
                        
                        caseRec.TaskType__c = ApplicationConstant.CASETASKTYPE_CUSTOMER;
                        isForCaseUpdate = true;
                    }
                }
            }*/
            
            if(isForCaseUpdate) {
                updateCaseList.add(caseRec);
            }
            
            if(ApplicationConstant.getCount(caseRec.Tasks) > 0 ) { 
                
                isCreateIDeposit = true;
                isCreateDBalance = true;
                isCreateFBalance = true;
                //isCreateTransferDetail = true;
                //isCreateRoomingList = true;
                
                for (Task t: caseRec.Tasks) {
                    if(t.Subject == ApplicationConstant.GETINITIALDEPOSIT) {
                        isCreateIDeposit = false;
                    }
                    if(t.Subject == ApplicationConstant.GETDEPOSITBALANCE) {
                        isCreateDBalance = false;
                    }
                    if(t.Subject == ApplicationConstant.GETFINALBALANCE) {
                        isCreateFBalance = false;
                    }
                    /*if(t.Subject == ApplicationConstant.TASKSUBJ_GETTRANSFER) {
                        isCreateTransferDetail = false;
                    }
                    if(t.Subject == ApplicationConstant.TASKSUBJ_GETROOMING) {
                        isCreateRoomingList = false;
                    }*/
                }
                
                createTaskList.addAll(AP32_AdminCaseUtility.checkCreateTask(caseRec, epIDepositMap, epDBalanceMap, epFBalanceMap/*, bookingTaskMap*/, isCreateIDeposit, isCreateDBalance, isCreateFBalance/*, isCreateTransferDetail, isCreateRoomingList*/));
                
            } else {
                
                createTaskList.addAll(AP32_AdminCaseUtility.checkCreateTask(caseRec, epIDepositMap, epDBalanceMap, epFBalanceMap/*, bookingTaskMap*/, true, true, true/*, true, true*/));
            }
        }
        
        if(!bookingIdSetCheck.IsEmpty()) 
        {
            for(Id bId: bookingIdSetCheck){
                if(bookingEpMap.containsKey(bId)) {
                    taskType.clear();
                    if(epIDepositMap.containsKey(bId) || epDBalanceMap.containsKey(bId) || epFBalanceMap.containsKey(bId)) {
                        taskType.add(ApplicationConstant.CASETASKTYPE_PAYMENT);
                    }
                    /*if(bookingTaskMap.containsKey(bId)) {
                        if(bookingTaskMap.get(bId).Booking__r.TransferDetailsRequired__c || bookingTaskMap.get(bId).Booking__r.RoomingListRequired__c) {
                            taskType.add(ApplicationConstant.CASETASKTYPE_CUSTOMER);
                        }
                    }*/
                    
                    createCaseList.add(AP32_AdminCaseUtility.createAdminCase(ApplicationConstant.ADMINCASESUBJ, bId, bookingEpMap.get(bId).Booking__r.Account__c, bookingEpMap.get(bid).Booking__r.Account__r.PersonContactId, bookingEpMap.get(bid).Booking__r.TECH_Opportunity__r.StageName, bookingEpMap.get(bid).Booking__r.TECH_Opportunity__r.OwnerId, taskType, dmlOpts));
                }
            }
        }
        
        if(!createCaseList.IsEmpty())
        {
            logs.addAll(getResultLogs(Database.insert(createCaseList, false), 'Case', 'Insert'));
            
            for(Case caseRec : [SELECT Id, OwnerId, Owner.Type, AccountId, Type, Status, Booking__c, Account.PersonContactId FROM Case WHERE Status <>: ApplicationConstant.CASE_STATUS_CLOSED AND Type =: ApplicationConstant.CASETYPE_ADMIN AND Booking__c IN: bookingIdSetCheck])
            {   
                
                createTaskList.addAll(AP32_AdminCaseUtility.checkCreateTask(caseRec, epIDepositMap, epDBalanceMap, epFBalanceMap/*, bookingTaskMap*/, true, true, true/*, true, true*/));
            }
        }
        
        if(!createTaskList.IsEmpty()) { 
            
            logs.addAll(getResultLogs(Database.insert(createTaskList, false), 'Task', 'Insert'));            
        }
        
        if(!updateCaseList.IsEmpty()) { 
            logs.addAll(getResultLogs(Database.update(updateCaseList, false), 'Case', 'Update'));
        }

        if(!logs.isEmpty()) {
            Database.insert(logs, false);
        }
    }
    
    global void finish(Database.BatchableContext BC){
        //Execute finish method
    }

    static List<Error_Log__c> getResultLogs(List<Database.SaveResult> listSaveResults, String objName, String dmlOp)   {
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        //2017-01-30 : SM : getDMLLog is now private so call getSaveResultLog instead
        errorLogs.addAll(ApplicationConstant.getSaveResultLog(listSaveResults, 'execute', CLASS_NAME, objName, dmlOp));
        /*
        Error_Log__c log = new Error_Log__c();              
        for(Database.SaveResult saveResult : listSaveResults){
            log = ApplicationConstant.getDMLLog(saveResult, 'execute()', CLASS_NAME, objName, dmlOp);                    
            errorLogs.add(log);                
        }
        */
        return errorLogs;
    }
}