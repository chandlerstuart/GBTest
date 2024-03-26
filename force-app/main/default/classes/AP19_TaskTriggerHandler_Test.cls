/**
* Class Name: AP19_TaskTriggerHandler_Test
* @author: Emman Flores
* @date: 07.05.2016
* @description: Test Class AP19_TaskTriggerHandler
*/

@isTest(seeAllData=false)

public class AP19_TaskTriggerHandler_Test{
       
    static testMethod void testEvents() {
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;  
        
        //Create List of Task
        List<Task> taskList = new List<Task>();
        
        //Create Account
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        database.insert(acc);

        //Create Opportunity for Cases
        List<Opportunity> oppList = AP23_TestDataFactory.createOpportunity(1,ApplicationConstant.CLOSESALESTAGE, acc);
        insert oppList;
        
        //Create Cases
        Case cas = AP23_TestDataFactory.createCase(1,acc)[0];
        cas.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Case').getRecordTypeId();    
        cas.Opportunity__c = oppList[0].Id;
        //cas.ContactId= con.Id;
        database.insert(cas);
        
        for(integer i=0; i<200; i++){
            Task inTask = new Task();            
        //inTask.WhoId = cas.ContactId;
            inTask.WhatId = cas.Id;
            inTask.Subject = 'Call Back Request';  
            inTask.Call_Back_Date_and_Time_Activity__c = System.today();
            inTask.ActivityDate = System.today();
            taskList.add(inTask);
        }
        
        
        List<Task> newTaskList = new List<Task>(taskList);
        List<Task> oldTaskList = new List<Task>(taskList);
        Map<Id,Task> newTaskMap = new Map<Id,Task>([SELECT Id FROM Task]);
        Map<Id,Task> oldTaskMap = new Map<Id,Task>([SELECT Id FROM Task]);
        
        test.startTest();
            AP19_TaskTriggerHandler tasktriggerhandler = new AP19_TaskTriggerHandler();
            database.insert(taskList);
            System.assertEquals(200, [SELECT Count() FROM Task]);
            
            database.update(taskList);
            
            database.delete(taskList);
            System.assertEquals(0, [SELECT Count() FROM Task]);
            // tasktriggerhandler.OnBeforeInsert(newTaskList);
            // tasktriggerhandler.OnBeforeUpdate(newTaskList,newTaskMap,oldTaskList,oldTaskMap);
            // tasktriggerhandler.OnAfterInsert(newTaskList,newTaskMap,oldTaskList,oldTaskMap);
            // tasktriggerhandler.OnAfterUpdate(newTaskList,newTaskMap,oldTaskList,oldTaskMap);
            // tasktriggerhandler.OnBeforeDelete(newTaskList,newTaskMap,oldTaskList,oldTaskMap);
            // tasktriggerhandler.OnAfterDelete(newTaskList,newTaskMap,oldTaskList,oldTaskMap);
            tasktriggerhandler.OnAfterUnDelete(newTaskList,newTaskMap,oldTaskList,oldTaskMap);
            tasktriggerhandler.OnUndelete(newTaskList,newTaskMap,oldTaskList,oldTaskMap);
        test.stopTest();  
    }
}