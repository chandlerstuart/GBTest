global class AP59_AdminCaseBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    public static final String CLASS_NAME = 'AP59_AdminCaseBatch';

    global AP59_AdminCaseBatch(){
        
    }
    global Database.QueryLocator start(Database.BatchableContext BC){        
        String adminType =ApplicationConstant.CASETYPE_ADMIN;
        String query = 'SELECT Id, Type, Status, Booking__c, OwnerId, Is_Case_Assigned__c, Booking__r.Has_Admin_Case_To_Close__c, Booking__r.Has_Change_in_Agent_Task_Name__c, Booking__r.AgentTaskName__c,' +
                        ' (Select ID, Subject FROM Tasks WHERE IsClosed = false )' +
                        ' FROM Case'+
                        ' WHERE IsClosed = false'+
                        ' AND Booking__c != null'+
                        ' AND Booking__r.Has_Admin_Case_To_Close__c = true'+
                        ' AND Type = :adminType ';     
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Case> scope) {
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Set<Id> bookingIds = new Set<Id>();
        Set<Id> bookingIDeposit = new Set<Id>();
        Set<Id> bookingFDeposit = new Set<Id>();
        Set<Id> bookingFBalance = new Set<Id>();
    
        //List variables
        List<Task> forUpdateTaskList = new List<Task>();
        List<Case> forUpdateCaseList = new List<Case>();
        //Map variables
        Map<Id, Task> taskMap = new Map<Id, Task>();
        Map<Id, Case> caseMap = new Map<Id, Case>();

        User apiUser = [SELECT Id FROM User WHERE Name =: ApplicationConstant.USER_NAME_API_USER LIMIT 1];

        Integer closedAdminTask = 0;

        for(Case caseRec : scope) {
            bookingIds.add(caseRec.Booking__c);
        }

        for (Expected_Payment__c ep : [SELECT Id, Booking__c, Outstanding_Balance__c, ExpectedPaymentType__c 
                                            FROM Expected_Payment__c 
                                            WHERE ExpectedPaymentType__c IN: ApplicationConstant.EPTYPESET AND Outstanding_Balance__c = 0 AND Booking__c IN: bookingIds]) {
                
            //Get all Booking to auto close related Partial Deposit Task
            if (ep.ExpectedPaymentType__c == ApplicationConstant.EPAYMENTTYPEPARTIALDEPOSIT) {    
                bookingIDeposit.add(ep.Booking__c);
            }
            //Get all Booking to auto close related Full Deposit Task
            else if (ep.ExpectedPaymentType__c == ApplicationConstant.EPAYMENTTYPEFULLDEPOSIT) {    
                bookingFDeposit.add(ep.Booking__c);
            }
            //Get all Booking to auto close related Full Balance Task
            else if (ep.ExpectedPaymentType__c == ApplicationConstant.EPAYMENTTYPEFULLBALANCE) {    
                bookingFBalance.add(ep.Booking__c);
            }
        }
        try{
            for(Case caseRec : scope) {
                closedAdminTask = 0; //Reset the counter for the Admin Task    
                for (Task t : caseRec.Tasks) {
                    //Check if there is a Open Initial Deposit Tasku
                    if (t.Subject == ApplicationConstant.GETINITIALDEPOSIT && bookingIDeposit.contains(caseRec.Booking__c)) {    
                        closedAdminTask++;
                        t.Status = ApplicationConstant.TASKSTATUS_COMPLETED;
                        taskMap.put(t.id, t);
                        forUpdateTaskList.add(t);
                    }
                    //Check if there is a Open Deposit Balance Task
                    else if (t.Subject == ApplicationConstant.GETDEPOSITBALANCE && bookingFDeposit.contains(caseRec.Booking__c)) {

                        closedAdminTask++;
                        t.Status = ApplicationConstant.TASKSTATUS_COMPLETED;
                        taskMap.put(t.id, t);
                        forUpdateTaskList.add(t);
                    }
                    //Check if there is a Open Full Balance Task
                    else if (t.Subject == ApplicationConstant.GETFINALBALANCE && bookingFBalance.contains(caseRec.Booking__c)) {
                        closedAdminTask++;
                        t.Status = ApplicationConstant.TASKSTATUS_COMPLETED;
                        taskMap.put(t.id, t);
                        forUpdateTaskList.add(t);
                    }
                    //Check if there is a Open Check Clubhouse Task
                    else if (caseRec.Booking__r.Has_Change_in_Agent_Task_Name__c) {
                        if (t.Subject == ApplicationConstant.TASKSUBJ_CHECKCH + caseRec.Booking__r.AgentTaskName__c) {
                            closedAdminTask++;
                            t.Status = ApplicationConstant.TASKSTATUS_COMPLETED;
                            taskMap.put(t.id, t);
                            forUpdateTaskList.add(t);
                        }
                    }
                }
                //Check if we can auto close the related Case
                if (caseRec.Tasks.size() == closedAdminTask) {
                    if(String.valueOf(caseRec.OwnerId).startswith('00G')) {
                        caseRec.OwnerId = apiUser.Id;
                        caseRec.Is_Case_Assigned__c = true;
                    }
                    caseRec.Status = ApplicationConstant.CASE_STATUS_CLOSED;
                    caseMap.put(caseRec.Id, caseRec);
                    forUpdateCaseList.add(caseRec);
                }
            }

            if (!forUpdateTaskList.isEmpty()) {
                Database.update(forUpdateTaskList);                  
            }
        
            if (!forUpdateCaseList.isEmpty()) {
                Database.update(forUpdateCaseList);
            }

        }catch(Exception e){
           //logs.add(ApplicationConstant.getExceptionLog(e, 'executeOnAdminCaseBatch', CLASS_NAME, null));
           System.debug('>>>>>>>>>>>>>>>>>> Exception ' + e.getMessage());
        }finally{
            
        }

    }

    global void finish(Database.BatchableContext BC){
        //Execute finish method
    }


}