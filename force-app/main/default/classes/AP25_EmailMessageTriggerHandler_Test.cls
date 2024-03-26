/**
* Class Name: AP25_EmailMessageTriggerHandler_Test
* @author: Emman Flores
* @date: 07.05.2016
* @description: Test AP25_EmailMessageTriggerHandler
*/

@isTest(seeAllData=false)

public class AP25_EmailMessageTriggerHandler_Test{
       
    static testMethod void testEvents() {
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;  
        
        //Create List of Email message
        List<EmailMessage> emailList = new List<EmailMessage>();
        
        //Create Account
        Account acc = AP23_TestDataFactory.createAccount(1)[0];
        database.insert(acc);

        //Create Opportunity for Cases
        List<Opportunity> oppList = AP23_TestDataFactory.createOpportunity(1,ApplicationConstant.CLOSESALESTAGE, acc);
        insert oppList;
        
        //Create Cases
        Case cas = AP23_TestDataFactory.createCase(1,acc)[0];
        cas.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Case').getRecordTypeId();   
        cas.Opportunity__c = oppList[0].Id; 
        database.insert(cas);
        
        //Create Task
        Task inTask = new Task();            
        inTask.WhatId = cas.Id;
        inTask.Subject = 'Call Back Request';  
        inTask.Call_Back_Date_and_Time_Activity__c = System.today();
        inTask.ActivityDate = System.today();
        database.insert(inTask);

        //Create Email Message
        for(integer i=0; i<200; i++){
            EmailMessage emailMsg = new EmailMessage();
            emailMsg.ActivityId = inTask.Id;
            emailMsg.FromAddress = 'testFrom@test.com';
            emailMsg.CcAddress = 'testCC@test.com';
            emailMsg.FromName = 'Test Name';
            emailMsg.ToAddress = 'testTo@test.com';
            emailMsg.Incoming = false;
            emailMsg.ParentId = cas.Id;
            emailMsg.Subject = 'Test Subject';
            emailList.add(emailMsg);
        }
        
        test.startTest();
            AP25_EmailMessageTriggerHandler emailtriggerhandler = new AP25_EmailMessageTriggerHandler();
            database.insert(emailList);
            System.assertEquals(200, [SELECT Count() FROM EmailMessage]);
            
            
            database.delete(emailList);
            System.assertEquals(0, [SELECT Count() FROM EmailMessage]);
            // emailtriggerhandler.OnBeforeInsert(newEmailMsgList,newEmailMsgMap,oldEmailMsgList,oldEmailMsgMap);
            
            // emailtriggerhandler.OnAfterInsert(newEmailMsgList,newEmailMsgMap,oldEmailMsgList,oldEmailMsgMap);
            
            // emailtriggerhandler.OnBeforeDelete(newEmailMsgList,newEmailMsgMap,oldEmailMsgList,oldEmailMsgMap);
            // emailtriggerhandler.OnAfterDelete(newEmailMsgList,newEmailMsgMap,oldEmailMsgList,oldEmailMsgMap);
            List<EmailMessage> newEmailMsgList = new List<EmailMessage>(emailList);
            List<EmailMessage> oldEmailMsgList = new List<EmailMessage>(emailList);
            Map<Id,EmailMessage> newEmailMsgMap = new Map<Id,EmailMessage>([SELECT Id FROM EmailMessage]);
            Map<Id,EmailMessage> oldEmailMsgMap = new Map<Id,EmailMessage>([SELECT Id FROM EmailMessage]);
            
            emailtriggerhandler.OnBeforeUpdate(newEmailMsgList,newEmailMsgMap,oldEmailMsgList,oldEmailMsgMap);
            emailtriggerhandler.OnAfterUpdate(newEmailMsgList,newEmailMsgMap,oldEmailMsgList,oldEmailMsgMap);
            
            emailtriggerhandler.OnAfterUnDelete(newEmailMsgList,newEmailMsgMap,oldEmailMsgList,oldEmailMsgMap);
            emailtriggerhandler.OnUndelete(newEmailMsgList,newEmailMsgMap,oldEmailMsgList,oldEmailMsgMap);
        test.stopTest();  
    }
}