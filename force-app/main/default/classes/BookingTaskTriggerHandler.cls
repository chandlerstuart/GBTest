/*
Name:  BookingTaskTriggerHandler.cls
======================================================
======================================================
Purpose: Handler for all Booking Task Trigger Activity
-------

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2022-05-16  Initial development.
1.1  Mark Cane&    2022-05-18  Logic changes after M:D=>BookingTaskType__c schema update (BookingTaskTypeCommunicationProfile__c).
1.2  J Radcliffe   2022-05-25  New methods - onAfterInsert, onAfterUpdate & onAfterDelete.
*/
public with sharing class BookingTaskTriggerHandler {
    
    private Boolean isExecuting=false;
    private Integer batchSize;

    public static Boolean isFirstAfterUpdate = true;
    public static Boolean isFirstAfterInsert = true;
    public static Boolean isFirstAfterDelete = true;

    public BookingTaskTriggerHandler(boolean isExecuting, integer size){
        this.isExecuting = isExecuting;
        this.batchSize = size;
    }
    
    //1.2+
    public void onAfterInsert(List<BookingTask__c> newList, Map<Id,BookingTask__c> newMap){
        try{
            if(isFirstAfterInsert){
                isFirstAfterInsert = false;
                calculateParentRecordSummaryTotals(null, newMap);
            }
        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'BookingTaskTriggerHandler','onAfterInsert');
        }
    }
    
    //1.2+
    public void onAfterDelete(List<BookingTask__c> oldList, Map<Id,BookingTask__c> oldMap){
        try{
            if(isFirstAfterDelete){
                isFirstAfterDelete = false;
                calculateParentRecordSummaryTotals(oldMap, null);
            }
        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'BookingTaskTriggerHandler','onAfterDelete');
        }
    }

    public void onAfterUpdate(List<BookingTask__c> oldList, Map<Id,BookingTask__c> oldMap, List<BookingTask__c> newList, Map<Id,BookingTask__c> newMap){
        try{
            if(isFirstAfterUpdate){
                isFirstAfterUpdate = false;
                calculateParentRecordSummaryTotals(oldMap, newMap);
            }
        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'BookingTaskTriggerHandler','onAfterUpdate');
        }
    }

    //& trigger action methods.        
    /*public void onBeforeInsert(List<BookingTask__c> insertedRecords){    
        calculateNextReminderDate(insertedRecords,null);
    }
    
    public void onBeforeUpdate(BookingTask__c[] updatedRecords, Map<Id, BookingTask__c> newMap, Map<Id, BookingTask__c> oldMap){
        if (isFirstAfterUpdate || Test.isRunningTest()){
            isFirstAfterUpdate=false;
            calculateNextReminderDate(updatedRecords,oldMap);
        }
    }
            
    public void onAfterUndelete(List<BookingTask__c> undeletedRecords){
        calculateNextReminderDate(undeletedRecords,null);
    }*/
    //& End trigger action methods.

    //& Helper methods.
    /*
    private void calculateNextReminderDate(List<BookingTask__c> affectedRecords, Map<Id, BookingTask__c> idToUpdatedRecord){
        try {    
            
            Set<String> validTaskTypes = new Set<String>();
            for (BookingTaskType__c btt : [select Id, Name, Category__c, TaskTypeKey__c from BookingTaskType__c where Category__c in ('SupplierTask', 'ManualTask')]){
                if (String.isNotBlank(btt.TaskTypeKey__c)) validTaskTypes.add(btt.TaskTypeKey__c);
            }

            Map<String,Set<String>> cpToBookingTaskTypes = new Map<String,Set<String>>();
            List<BookingTask__c> bookingTasks = new List<BookingTask__c>();

            for (BookingTask__c bt : affectedRecords){

                if (bt.TaskType__c==null || !validTaskTypes.contains(bt.TaskType__c)) continue;

                //recalculate NRD when..
                // 1. LRD is updated.
                // 2. NRD has changed and is blank
                // 3. Set to null where the Status has changed to Complete.
    
                if (Trigger.isInsert
                    || (Trigger.isUnDelete && !bt.Status__c.equalsIgnoreCase('Complete'))
                    || (bt.LastReminderDate__c!=idToUpdatedRecord.get(bt.Id).LastReminderDate__c
                        || (bt.NextReminderDate__c!=idToUpdatedRecord.get(bt.Id).NextReminderDate__c && bt.NextReminderDate__c==null)
                        || bt.Status__c!=idToUpdatedRecord.get(bt.Id).Status__c)){

                        bookingTasks.add(bt);

                    if (String.isNotBlank(bt.CommunicationProfile__c)){
                        if (!cpToBookingTaskTypes.containsKey(bt.CommunicationProfile__c)) cpToBookingTaskTypes.put(bt.CommunicationProfile__c,new Set<String>());//Assume BT CP field is APIName__c.
                        if (String.isNotBlank(bt.TaskType__c)) cpToBookingTaskTypes.get(bt.CommunicationProfile__c).add(bt.TaskType__c);
                    }
                }                        
            }//bookingTask
            if (bookingTasks.isEmpty()) return;

            Map<String,CommunicationProfile__c> apiNameToCommunicationProfile = new Map<String,CommunicationProfile__c>();
            for (CommunicationProfile__c cp : [select Id, APIName__c, FrequencyFromVisibleDate__c, FrequencyFromDueDate__c, FrequencyFromAbsoluteDueDate__c from CommunicationProfile__c where APIName__c in:cpToBookingTaskTypes.keySet()]){
                if (String.isNotBlank(cp.APIName__c)) apiNameToCommunicationProfile.put(cp.APIName__c,cp);
            }

            String k;
            Map<String,BookingTaskTypeCommunicationProfile__c> keyToBTTCP = new Map<String,BookingTaskTypeCommunicationProfile__c>();
            for (BookingTaskTypeCommunicationProfile__c bttcp : [select Id, Name, CommunicationProfile__c, CommunicationProfile__r.APIName__c, BookingTaskType__r.TaskTypeKey__c,
                                                                        FrequencyFromVisibleDate__c,FrequencyFromDueDate__c,FrequencyFromAbsoluteDueDate__c
                                                                    from BookingTaskTypeCommunicationProfile__c 
                                                                    where CommunicationProfile__r.APIName__c in:cpToBookingTaskTypes.keySet()]){//1.1~

                if (!cpToBookingTaskTypes.get(bttcp.CommunicationProfile__r.APIName__c).contains(bttcp.BookingTaskType__r.TaskTypeKey__c)) continue;                
                
                k = bttcp.CommunicationProfile__r.APIName__c+bttcp.BookingTaskType__r.TaskTypeKey__c;
                if (!keyToBTTCP.containsKey(k)) keyToBTTCP.put(k, bttcp);
            }
            
            Integer reminderFrequencyDays;
            Date nextReminderDate;
            Map<Id, BookingTask__c> idToBookingTaskToUpdate = new Map<Id, BookingTask__c>();

            for (BookingTask__c bt : bookingTasks){
                nextReminderDate=null;
                reminderFrequencyDays=0;

                if (Trigger.isUpdate && bt.Status__c!=idToUpdatedRecord.get(bt.Id).Status__c && bt.Status__c.equalsIgnoreCase('Complete')){
                    bt.NextReminderDate__c = null;
                    continue;
                }
            
                if (bt.VisibleDate__c!=null
                    && bt.DueDate__c!=null
                    && (bt.VisibleDate__c>Date.today()
                        || (Date.today()>=bt.VisibleDate__c
                            && bt.DueDate__c>=Date.today()))){//if current date before Visible or from Visible to Due

                    if (String.isNotBlank(bt.CommunicationProfile__c) 
                        && String.isNotBlank(bt.TaskType__c)
                        && keyToBTTCP.containsKey(bt.CommunicationProfile__c+bt.TaskType__c)){ 
                            
                        reminderFrequencyDays = keyToBTTCP.get(bt.CommunicationProfile__c+bt.TaskType__c).FrequencyFromVisibleDate__c==null ? 0 : Integer.valueOf(keyToBTTCP.get(bt.CommunicationProfile__c+bt.TaskType__c).FrequencyFromVisibleDate__c);
                    
                    } else if (String.isNotBlank(bt.CommunicationProfile__c)) reminderFrequencyDays = apiNameToCommunicationProfile.get(bt.CommunicationProfile__c).FrequencyFromVisibleDate__c==null ? 0 : Integer.valueOf(apiNameToCommunicationProfile.get(bt.CommunicationProfile__c).FrequencyFromVisibleDate__c);

                    //if current date before Visible <-- set NRD==Visible Date plus frequencyDays otherwise use the current date.
                    if (reminderFrequencyDays>0) nextReminderDate = (bt.VisibleDate__c>Date.today()) ? bt.VisibleDate__c.addDays(reminderFrequencyDays) : Date.today().addDays(reminderFrequencyDays);
                }

                if (reminderFrequencyDays==0
                    && bt.DueDate__c!=null
                    && bt.AbsoluteDueDate__c!=null
                    && Date.today()>=bt.DueDate__c
                    && bt.AbsoluteDueDate__c>=Date.today()){//if current date from Due to Absolute Due

                    if (String.isNotBlank(bt.CommunicationProfile__c) && String.isNotBlank(bt.TaskType__c)){
                        if (keyToBTTCP.containsKey(bt.CommunicationProfile__c+bt.TaskType__c)){
                            reminderFrequencyDays = keyToBTTCP.get(bt.CommunicationProfile__c+bt.TaskType__c).FrequencyFromDueDate__c==null ? 0 : Integer.valueOf(keyToBTTCP.get(bt.CommunicationProfile__c+bt.TaskType__c).FrequencyFromDueDate__c);
                        } else reminderFrequencyDays = apiNameToCommunicationProfile.get(bt.CommunicationProfile__c).FrequencyFromDueDate__c==null ? 0 : Integer.valueOf(apiNameToCommunicationProfile.get(bt.CommunicationProfile__c).FrequencyFromDueDate__c);
                    }
                    if (reminderFrequencyDays>0) nextReminderDate = Date.today().addDays(reminderFrequencyDays);
                }
                
                if (reminderFrequencyDays==0                    
                    && bt.AbsoluteDueDate__c!=null
                    && Date.today()>bt.AbsoluteDueDate__c){//if current after Absolute Due

                    if (String.isNotBlank(bt.CommunicationProfile__c) && String.isNotBlank(bt.TaskType__c)){
                        if (keyToBTTCP.containsKey(bt.CommunicationProfile__c+bt.TaskType__c)){
                            reminderFrequencyDays = keyToBTTCP.get(bt.CommunicationProfile__c+bt.TaskType__c).FrequencyFromAbsoluteDueDate__c==null ? 0 : Integer.valueOf(keyToBTTCP.get(bt.CommunicationProfile__c+bt.TaskType__c).FrequencyFromAbsoluteDueDate__c);
                        } else reminderFrequencyDays = apiNameToCommunicationProfile.get(bt.CommunicationProfile__c).FrequencyFromAbsoluteDueDate__c==null ? 0 : Integer.valueOf(apiNameToCommunicationProfile.get(bt.CommunicationProfile__c).FrequencyFromAbsoluteDueDate__c);
                    }
                    if (reminderFrequencyDays>0) nextReminderDate = Date.today().addDays(reminderFrequencyDays);
                }
                if (Trigger.isUndelete){
                    if (nextReminderDate!=null) idToBookingTaskToUpdate.put(bt.Id,new BookingTask__c(Id=bt.Id,NextReminderDate__c=nextReminderDate));            
                } else if (nextReminderDate!=null){
                    bt.NextReminderDate__c=nextReminderDate;
                } else bt.NextReminderDate__c=null;//if no calculated date then set to null.                            
            }
            if (idToBookingTaskToUpdate.isEmpty()) return;      
            Database.SaveResult[] results = Database.update(idToBookingTaskToUpdate.values(),false);
            Golfbreaks.PlatformLogManager.logExceptions(results,'BookingTaskTriggerHandler','calculateNextReminderDate',idToBookingTaskToUpdate.values());
    
        } catch(Exception e){ for (BookingTask__c bp : affectedRecords) { bp.addError(e.getMessage()); } }       
    }*/
    
    //1.2+
    //Evaluates record changes and triggers a recalculation of parent record summaries when required
    public void calculateParentRecordSummaryTotals(Map<Id,BookingTask__c> oldMap, Map<Id,BookingTask__c> newMap){

        system.debug('calculateParentRecordSummaryTotals Start');

        if(newMap == null && oldMap == null) return;

        Set<Id> bookingGuestIds = new Set<Id>();
        
        Boolean isInsert = (oldMap == null && newMap != null)?true:false;
        Boolean isDelete = (oldMap != null && newMap == null)?true:false;

        if(isDelete){
            for(BookingTask__c task : oldMap.values()){
                if(task.Status__c != ApplicationConstant.BOOKING_TASK_STATUS_COMPLETE && task.Status__c != ApplicationConstant.BOOKING_TASK_STATUS_NOT_REQUIRED
                && task.AssignedTo__c != null && !bookingGuestids.contains(task.AssignedTo__c)) bookingGuestIds.add(task.AssignedTo__c);
            }
        }else{
            BookingTask__c oldTask;
            for(BookingTask__c task : newMap.values()){
                if(isInsert){
                    //New incomplete task inserted
                    if(task.Status__c != ApplicationConstant.BOOKING_TASK_STATUS_COMPLETE && task.Status__c != ApplicationConstant.BOOKING_TASK_STATUS_NOT_REQUIRED){
                        if(task.AssignedTo__c != null && !bookingGuestIds.contains(task.AssignedTo__c)) bookingGuestIds.add(task.AssignedTo__c);
                        continue;
                    }
                }else{
                    if(!oldMap.containsKey(task.Id)) continue;
                    oldTask = oldMap.get(task.Id);
                    //Booking Guest Changed
                    if(oldTask.AssignedTo__c != task.AssignedTo__c){
                        if(task.AssignedTo__c != null && !bookingGuestIds.contains(task.AssignedTo__c)) bookingGuestIds.add(task.AssignedTo__c);
                        if(oldTask.AssignedTo__c != null && !bookingGuestIds.contains(oldTask.AssignedTo__c)) bookingGuestIds.add(oldTask.AssignedTo__c);
                    }
                    if(oldTask.Status__c != task.Status__c){
                        system.debug('Old Status > '+oldTask.Status__c);
                        system.debug('New Status > '+task.Status__c);
                        if( 
                            //Newly Completed
                            ((oldTask.Status__c != ApplicationConstant.BOOKING_TASK_STATUS_COMPLETE && oldTask.Status__c != ApplicationConstant.BOOKING_TASK_STATUS_NOT_REQUIRED)
                            && (task.Status__c == ApplicationConstant.BOOKING_TASK_STATUS_COMPLETE || task.Status__c == ApplicationConstant.BOOKING_TASK_STATUS_NOT_REQUIRED))
                            ||
                            //Newly Reopened
                            ((oldTask.Status__c == ApplicationConstant.BOOKING_TASK_STATUS_COMPLETE || oldTask.Status__c == ApplicationConstant.BOOKING_TASK_STATUS_NOT_REQUIRED)
                            && (task.Status__c != ApplicationConstant.BOOKING_TASK_STATUS_COMPLETE && task.Status__c != ApplicationConstant.BOOKING_TASK_STATUS_NOT_REQUIRED))
                            
                            ){
                                if(task.AssignedTo__c != null && !bookingGuestIds.contains(task.AssignedTo__c)) bookingGuestIds.add(task.AssignedTo__c);
                            }                    
                    }
                }
            }
        } 
        if(bookingGuestIds.size()>0){
            BookingGuestTriggerBL.calculateTotalIncompleteBookingTasks(bookingGuestIds);
        }

        system.debug('calculateParentRecordSummaryTotals End');

    }
    
    //& End Helper methods.
}