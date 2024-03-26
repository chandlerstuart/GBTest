/**
   @Author: Nicole de Guzman/Renz Melecotones
   @name: AP19_TaskTriggerHandler
   @CreateDate: 03.04.2016
   @Description: Handler Class for TaskTrigger
   @Version <1.0>
   @History
        JEROME TO (ACN) - APR 26, 2016 - Added functionality for NVM Log a Call Notes on OnBeforeInsert
History
------- 
Ver. Author         Date         Detail
1.1  J Radcliffe    2022-03-15   Integration Framework Plugin (invoke Data Event Trigger Handler)
1.2  J Radcliffe    2023-08-08   Invoke new method before insert - assignTaskSubtype - Responsible for setting the TaskSubtype to 'Call' for call activities before insert.
*/ 
public with sharing class AP19_TaskTriggerHandler {

    //recursion flags Added By Dee June 4 -- Based on Code Review
    public static Boolean isBeforeUpdateTriggerCalled = FALSE;
    public static Boolean isBeforeInsertTriggerCalled = FALSE;
    public static Boolean isAfterUpdateTriggerCalled = FALSE;
    public static Boolean isAfterInsertTriggerCalled = FALSE;

    public AP19_TaskTriggerHandler(){
        
    }

    //public void OnBeforeInsert(List<Task> newTaskList, Map<Id,Task> newTaskMap, List<Task> oldTaskList, Map<Id,Task> oldTaskMap){        
    public void OnBeforeInsert(List<Task> newTaskList){
        if(!isBeforeInsertTriggerCalled){
            AP20_TaskTriggerBL.assignTaskSubtype(newTaskList);//1.2+
            AP20_TaskTriggerBL.populateNVMCallNotes(newTaskList);
            AP20_TaskTriggerBL.populateWhoId(newTaskList);
            AP20_TaskTriggerBL.processTasks(newTaskList);
            
            isBeforeInsertTriggerCalled = TRUE;
        }
    }   
    
    public void OnBeforeUpdate(List<Task> newTaskList, Map<Id,Task> newTaskMap, List<Task> oldTaskList, Map<Id,Task> oldTaskMap){
        if(!isBeforeUpdateTriggerCalled){
            AP20_TaskTriggerBL.processTasks(newTaskList);
            
            isBeforeUpdateTriggerCalled = TRUE;
        }
    }
     
    public void OnAfterInsert(List<Task> newTaskList, Map<Id,Task> newTaskMap, List<Task> oldTaskList, Map<Id,Task> oldTaskMap){
        if(!isAfterInsertTriggerCalled){
            AP20_TaskTriggerBL.updateCallBackDateTime(newTaskList, oldTaskMap);
            AP20_TaskTriggerBL.populateDiaryDateNotes(newTaskList);

            //1.1+
            DataEventTypeTriggerHandler dth = new DataEventTypeTriggerHandler(ApplicationConstant.OBJECT_TYPE_TASK);
            dth.handleTriggerOperationType();

            isAfterInsertTriggerCalled = TRUE;
        }
    }
    
    public void OnAfterUpdate(List<Task> newTaskList, Map<Id,Task> newTaskMap, List<Task> oldTaskList, Map<Id,Task> oldTaskMap){
        if(!isAfterUpdateTriggerCalled){
            AP20_TaskTriggerBL.updateCallBackDateTime(newTaskList, oldTaskMap);

            //1.1+
            DataEventTypeTriggerHandler dth = new DataEventTypeTriggerHandler(ApplicationConstant.OBJECT_TYPE_TASK);
            dth.handleTriggerOperationType();
            
            isAfterUpdateTriggerCalled = TRUE;
        }
    }
    
    public void OnBeforeDelete(List<Task> newTaskList, Map<Id,Task> newTaskMap, List<Task> oldTaskList, Map<Id,Task> oldTaskMap){
        
    }
    
    public void OnAfterDelete(List<Task> newTaskList, Map<Id,Task> newTaskMap, List<Task> oldTaskList, Map<Id,Task> oldTaskMap){
        
    }
     
    public void OnAfterUnDelete(List<Task> newTaskList, Map<Id,Task> newTaskMap, List<Task> oldTaskList, Map<Id,Task> oldTaskMap){
        
    }
    
    public void OnUndelete(List<Task> newTaskList, Map<Id,Task> newTaskMap, List<Task> oldTaskList, Map<Id,Task> oldTaskMap){
        
    }
    
}