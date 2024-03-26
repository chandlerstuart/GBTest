/**
* @author -         Patrick Villarica (Accenture)
* @date -           14/04/2016
* @description -    Admin Case UTILITY Class
* #############Change Log#############
* Modified by     Version     Change Date
**/

public with sharing class AP32_AdminCaseUtility{
    
    /*************************************************************************************** 
    Developer -    Patrick Villarica (Accenture)
    Date -         14/04/2016
    Version -      1.0 
    Function -     Process if we need to create Admin Task
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static List<Task> checkCreateTask(Case relatedCase, Map<Id, Expected_Payment__c> initialDMap, Map<Id, Expected_Payment__c> depositBMap, Map<Id, Expected_Payment__c> finalBMap/*, Map<Id, Expected_Payment__c> bookingTaskMap*/, Boolean isIDeposit, Boolean isDBalance, Boolean isFBalance/*, Boolean isTransferDetail, Boolean isRoomingList*/) {
        
        List<Task> retTaskToCreate = new List<Task> ();
        
        if(isIDeposit && initialDMap.containsKey(relatedCase.Booking__c)) {
            retTaskToCreate.add(createTask(ApplicationConstant.GETINITIALDEPOSIT, initialDMap.get(relatedCase.Booking__c).Expected_Payment_Date__c, relatedCase.Id, relatedCase.Account.PersonContactId, relatedCase.OwnerId, relatedCase.Owner.Type));
        }
        if(isDBalance && depositBMap.containsKey(relatedCase.Booking__c)) {
            retTaskToCreate.add(createTask(ApplicationConstant.GETDEPOSITBALANCE, depositBMap.get(relatedCase.Booking__c).Expected_Payment_Date__c, relatedCase.Id, relatedCase.Account.PersonContactId, relatedCase.OwnerId, relatedCase.Owner.Type));
        }
        if(isFBalance && finalBMap.containsKey(relatedCase.Booking__c)) {
            retTaskToCreate.add(createTask(ApplicationConstant.GETFINALBALANCE, finalBMap.get(relatedCase.Booking__c).Expected_Payment_Date__c, relatedCase.Id, relatedCase.Account.PersonContactId, relatedCase.OwnerId, relatedCase.Owner.Type));
        }
        
        /*if(bookingTaskMap.containsKey(relatedCase.Booking__c)) {
            if(isTransferDetail && bookingTaskMap.get(relatedCase.Booking__c).Booking__r.TransferDetailsRequired__c) {
                retTaskToCreate.add(createTask(ApplicationConstant.TASKSUBJ_GETTRANSFER, bookingTaskMap.get(relatedCase.Booking__c).Expected_Payment_Date__c, relatedCase.Id, relatedCase.Account.PersonContactId, relatedCase.OwnerId, relatedCase.Owner.Type));
            }
            if(isRoomingList && bookingTaskMap.get(relatedCase.Booking__c).Booking__r.RoomingListRequired__c) {
                retTaskToCreate.add(createTask(ApplicationConstant.TASKSUBJ_GETROOMING, bookingTaskMap.get(relatedCase.Booking__c).Expected_Payment_Date__c, relatedCase.Id, relatedCase.Account.PersonContactId, relatedCase.OwnerId, relatedCase.Owner.Type));
            }
        }*/
        
        return retTaskToCreate;
    }
    
    /*************************************************************************************** 
    Developer -    Patrick Villarica (Accenture)
    Date -         14/04/2016
    Version -      1.0 
    Function -     Create new Admin Task
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Task createTask(String subj, Date dueDate, Id relatedCase, Id relatedPersonAccount, Id CaseOwner, String OwnerType) {
        QueueId__c userIdSettings = QueueId__c.getInstance();

        Task newTask = new Task();
        
        newTask.Subject = subj;
        newTask.ActivityDate = dueDate;
        newTask.WhatId = relatedCase;
        if(OwnerType == ApplicationConstant.USP_QUEUE){
            if(userIdSettings.User_Id__c!='' && userIdSettings.User_Id__c!=null){
                newTask.OwnerId = userIdSettings.User_Id__c;
            }
        }else {
          newTask.OwnerId = CaseOwner;
        }
        newTask.WhoId = relatedPersonAccount;
        newTask.Status = ApplicationConstant.TASKSTATUS_NOTSTARTED;
        newTask.Priority = ApplicationConstant.TASKPRIORITY_NORMAL;
        newTask.IsReminderSet = true;
        newTask.ReminderDateTime = System.now(); //We can use .addHours() to change the time for the reminder
    
        
        return newTask;
    }
    
    /*************************************************************************************** 
    Developer -    Patrick Villarica (Accenture)
    Date -         14/04/2016
    Version -      1.0 
    Function -     Create new Admin Case
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Case createAdminCase(String subj, Id relatedBooking, Id relatedAccount, Id relatedContactId, String relatedOppStage, Id relatedOppOwner, Set<String> relatedTaskType, Database.DMLOptions dmlOpts) {
        
        String taskType = '';
        Case newCase = new Case();
        
        newCase.RecordTypeId = ApplicationConstant.CASERECTYPEID_ADMIN;
        newCase.Subject = subj;
        newCase.Origin = ApplicationConstant.CASEORIGIN_CLUBHOUSE;
        newCase.Type = ApplicationConstant.CASETYPE_ADMIN;
        newCase.Booking__c = relatedBooking;
        newCase.AccountId = relatedAccount;
        newCase.ContactId = relatedContactId;
        newCase.Status = ApplicationConstant.CASESTATUS_NEW;
        for(String type: relatedTaskType) {
           taskType += type + ';';
        }
        newCase.TaskType__c = taskType;
        if(ApplicationConstant.SALESOPPSTAGESET.contains(relatedOppStage)) {
            newCase.OwnerId = relatedOppOwner;
        } else {
            newCase.setOptions(dmlOpts);
        }
        
        return newCase;
    }
}