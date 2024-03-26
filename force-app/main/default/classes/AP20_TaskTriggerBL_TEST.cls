/**
Name:   AP20_TaskTriggerBL_TEST.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test Class for  AP20_TaskTriggerBL
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail 
1.0  Gaylan, C.  2016-04-26    Created
2.0  Atlee       2016-06-03    Updated test class
2.1  Smolloy     2016-11-25    Ensure all Cases have Opportunity__c field populated as per business rules
2.2  J Radcliffe 2023-08-08    New test method testCallActivityLogging
**/

@isTest(seeAllData=false)
private class AP20_TaskTriggerBL_TEST {     
    @testSetup public static void setupCommonData(){ 

        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;

        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
      
        //improve to consider bulk
        List<Account> accList = new List<Account>();
        Account acc = new Account();
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId(); 
        acc.FirstName = 'Test';
        acc.LastName = ' LastNamex';
        acc.Phone = '+441231234567';
        accList.add(acc);
        insert accList;   
        
        
        List<Opportunity> oppList = AP23_TestDataFactory.createOpportunity(20, ApplicationConstant.CUSTOMERACCEPTEDSTAGE, accList[0]);
        insert oppList;

        List<Case> caseList = AP23_TestDataFactory.createCaseWithOpp(20, accList[0].Id, oppList[0].Id);
        Id serviceRTId = ApplicationConstant.CASERECTYPEID_SERVICECASE;
        for(Case cse : caseList){cse.RecordTypeId = serviceRTId;}
        insert caseList;
        
        List<Lead> leadList = AP23_TestDataFactory.createLead(20);
        leadList[0].Email = 'testchtestchr@leadtst.com';
        leadlist[0].Account__c = accList[0].Id;
        insert leadList;

        OrgSettings__c orgSetting = new OrgSettings__c();
        orgSetting.TriggersActive__c = true;
        insert orgSetting;
    }
    
/* Uncomment this once the issue with AP20's deprecated field is resolved.
    static testMethod void testNVMLookup(){
        Case cas = [SELECT Id, RequestedCallBackDateAndTime__c FROM Case LIMIT 1];  
        NVMContactWorld__InteractionEvent__c nvmc = new NVMContactWorld__InteractionEvent__c( 
                                                                                              NVMContactWorld__IndexedCallObjectIdentifier__c = 'CallObjectId,
                                                                                             NVMContactWorld__Type__c = 'Deliver', NVMContactWorld__TimeStamp__c = System.Today());
        insert nvmc;
        
        NVMContactWorld__InteractionEventNote__c nvmie = new NVMContactWorld__InteractionEventNote__c(NVMContactWorld__Event__c = nvmc.Id, NVMContactWorld__Detail__c = 'NVM Detail');
        insert nvmie;
        
        Test.startTest();
        Task tsk = new Task(CallObject = 'CallObjectId', WhatId = cas.Id, Subject = 'Call Back Request', Call_Back_Date_and_Time_Activity__c = System.today(), ActivityDate = System.today());            
        insert tsk;
        
        //tsk = [SELECT Id, Description, Call_Notes__c FROM Task LIMIT 1];
        //System.AssertEquals(tsk.Description.contains(nvmie.NVMContactWorld__Detail__c), TRUE);
        //System.AssertEquals(tsk.Call_Notes__c, nvmie.NVMContactWorld__Detail__c);
        Test.stopTest();
    }
 */ 
    //Checks the task description   
    static testMethod void testDescription(){
        Case cas = [SELECT Id, RequestedCallBackDateAndTime__c FROM Case LIMIT 1]; 
        Test.startTest();
            List<Task> lTask = new List<Task>();
            for(Integer i = 0; i < 20; i++){
                Task tsk = new Task(CallObject = 'CallObjectId', WhatId = cas.Id, Subject = 'Call Back Request', Call_Back_Date_and_Time_Activity__c = System.today(), 
                                ActivityDate = System.today(), Description = 'Test: --------Save your notes above this line--------Test 2');            
                lTask.add(tsk);
            }
            insert lTask;
            
            List<Task> lTaskUpd = [SELECT Id, Description, Call_Notes__c FROM Task];
            for(Task tsk: lTaskUpd){
                System.AssertEquals(tsk.Description, 'Test: ' +'\r\n' + '--------Save your notes above this line--------' + '\r\n' +null);
            }
        Test.stopTest();                
    }
    
    //Checks the task description - no initial value  
    static testMethod void testDescription2(){
        Case cas = [SELECT Id, RequestedCallBackDateAndTime__c FROM Case LIMIT 1]; 
        Test.startTest();
            List<Task> lTask = new List<Task>();
            for(Integer i = 0; i < 20; i++){
                Task tsk = new Task(CallObject = 'CallObjectId', WhatId = cas.Id, Subject = 'Call Back Request', Call_Back_Date_and_Time_Activity__c = System.today(), 
                                ActivityDate = System.today());            
                lTask.add(tsk);
            }
            insert lTask;
            
            List<Task> lTaskUpd = [SELECT Id, Description, Call_Notes__c FROM Task];
            for(Task tsk: lTaskUpd){
                System.AssertEquals(tsk.Description, '--------Save your notes above this line--------' + '\r\n' +null);
            }
        Test.stopTest();                
    }
    

    //Update task description and call notes
    static testMethod void testNVM(){
        Case cas = [SELECT Id, RequestedCallBackDateAndTime__c FROM Case LIMIT 1];  
        NVMContactWorld__InteractionEvent__c nvmc = new NVMContactWorld__InteractionEvent__c(NVMContactWorld__IndexedCallObjectIdentifier__c = 'CallObjectId', 
                                                                                             NVMContactWorld__Type__c = 'Deliver', NVMContactWorld__TimeStamp__c = System.Today());
        insert nvmc;
        
        NVMContactWorld__InteractionEventNote__c nvmie = new NVMContactWorld__InteractionEventNote__c(NVMContactWorld__Event__c = nvmc.Id, NVMContactWorld__Detail__c = 'NVM Detail');
        insert nvmie;
        
        Test.startTest();
        
            List<Task> lTask = new List<Task>();
            for(Integer i = 0; i < 20; i++){
                Task tsk = new Task(CallObject = 'CallObjectId', WhatId = cas.Id, Subject = 'Call Back Request', Call_Back_Date_and_Time_Activity__c = System.today(), ActivityDate = System.today());            
                lTask.add(tsk);
            }
            insert lTask;
            
            List<Task> lTaskUpd = [SELECT Id, Description, Call_Notes__c FROM Task];
            for(Task tsk: lTaskUpd){
                System.AssertEquals(tsk.Description.contains(nvmie.NVMContactWorld__Detail__c), TRUE);
                System.AssertEquals(tsk.Call_Notes__c, nvmie.NVMContactWorld__Detail__c);
            }
        Test.stopTest();
    }
    
    //Update case callback time
    static testMethod void testTaskCase(){
        List<Case> lCase = [SELECT Id, RequestedCallBackDateAndTime__c FROM Case]; 
              
        Test.startTest();        
            List<Task> lTask = new List<Task>();
            Map<Id, Task> mTask = new Map<Id, Task>();
            for(Integer i = 0; i < 20; i++){
                Task tsk = new Task(WhatId = lCase[i].Id, Subject = 'Call Back Request', Call_Back_Date_and_Time_Activity__c = System.today(), ActivityDate = System.today());
                mTask.put(tsk.WhatId, tsk);
                lTask.add(tsk);
            }
            insert lTask;
            
            lCase = [SELECT Id, RequestedCallBackDateAndTime__c FROM Case]; 
            for(Case cs: lCase){
                System.AssertEquals(cs.RequestedCallBackDateAndTime__c, mTask.get(cs.Id).Call_Back_Date_and_Time_Activity__c);
            }
            
            mTask.clear();
            for(Task tsk: lTask){
                tsk.Call_Back_Date_and_Time_Activity__c = System.Today()+1;
                mTask.put(tsk.WhatId, tsk);
            }
            update lTask;
            
            lCase = [SELECT Id, RequestedCallBackDateAndTime__c FROM Case];
            for(Case cs: lCase){
                if(mTask.get(cs.Id).Call_Back_Date_and_Time_Activity__c != null){
                    System.AssertEquals(cs.RequestedCallBackDateAndTime__c, mTask.get(cs.Id).Call_Back_Date_and_Time_Activity__c);
                }
            }
        Test.stopTest();
    }
    
    //Update Opp callback time    
    /*static testMethod void testTaskOpp(){
        List<Opportunity> lOpp = [SELECT Id, RequestedCallbacktimedate__c FROM Opportunity];
               
        Test.startTest();
            List<Task> lTask = new List<Task>();
            Map<Id, Task> mTask = new Map<Id, Task>();
            
            for(Integer i = 0; i < 20; i++){
                Task tsk = new Task(WhatId = lOpp[i].Id, Subject = 'Call Back Request', Call_Back_Date_and_Time_Activity__c = System.today(), ActivityDate = System.today());            
                mTask.put(tsk.WhatId, tsk);
                lTask.add(tsk);
            }
            insert lTask;
            
            lOpp = [SELECT Id, RequestedCallbacktimedate__c FROM Opportunity]; 
            for(Opportunity op: lOpp){
                System.AssertEquals(op.RequestedCallbacktimedate__c, mTask.get(op.Id).Call_Back_Date_and_Time_Activity__c);
            }        
            mTask.clear();
            for(Task tsk: lTask){
                tsk.Call_Back_Date_and_Time_Activity__c = System.Today()+1;
                mTask.put(tsk.WhatId, tsk);
            }
            update lTask;
            
            lOpp = [SELECT Id, RequestedCallbacktimedate__c FROM Opportunity]; 
            for(Opportunity op: lOpp){
                System.AssertEquals(op.RequestedCallbacktimedate__c, mTask.get(op.Id).Call_Back_Date_and_Time_Activity__c);
            } 
        Test.stopTest();
    }*/
    
    //Update Lead callback time
    /*static testMethod void testTaskLead(){
        List<Lead> lLead = [SELECT Id, CallBackDateTime__c FROM Lead];  
             
        Test.startTest();
            List<Task> lTask = new List<Task>();
            Map<Id, Task> mTask = new Map<Id, Task>();
            
            for(Integer i = 0; i < 20; i++){
                Task tsk = new Task(WhoId = lLead[i].Id, Subject = 'Call Back Request', Call_Back_Date_and_Time_Activity__c = System.today(), ActivityDate = System.today());            
                mTask.put(tsk.WhoId, tsk);
                lTask.add(tsk);
            }
            insert lTask;
            
            lLead = [SELECT Id, CallBackDateTime__c FROM Lead]; 
            for(Lead ld: lLead){
                System.AssertEquals(ld.CallBackDateTime__c, mTask.get(ld.Id).Call_Back_Date_and_Time_Activity__c);
            }        
            mTask.clear();
            for(Task tsk: lTask){
                tsk.Call_Back_Date_and_Time_Activity__c = System.Today()+1;
                mTask.put(tsk.WhoId, tsk);
            }
            update lTask;

            lLead = [SELECT Id, CallBackDateTime__c FROM Lead]; 
            for(Lead ld: lLead){
                System.AssertEquals(ld.CallBackDateTime__c, mTask.get(ld.Id).Call_Back_Date_and_Time_Activity__c);
            } 
        Test.stopTest();
    }*/
    
    static testMethod void testException(){
        
        AP20_TaskTriggerBL.updateCallBackDateTime(null, null);
        AP20_TaskTriggerBL.populateWhoId(null);
        AP20_TaskTriggerBL.populateNVMCallNotes(null);
        AP20_TaskTriggerBL.createUsersLookup(null);
        AP20_TaskTriggerBL.createInteractionEventNotesLookup(null);
        AP20_TaskTriggerBL.processTasks(null);
        //AP20_TaskTriggerBL.populateDiaryDateNotes(null);
        Test.startTest();
        List<Error_Log__c> logs = [SELECT Id FROM Error_Log__c];
        //System.AssertEquals(logs.size(), 10);
        Test.stopTest();
    }

    //2.2+ - Confirm the Task Subtype is set on (before) insert for call activities
    static testMethod void testCallActivityLogging(){

        system.assertEquals(0, [Select Count() From Task]);

        List<Task> taskList = new List<Task>();
        for(Integer i=0;i<100;i++){
            Task newTask = new Task(ActivityDate=System.today());//Extend
            if(i<50){   
                newTask.Subject = 'Outbound call to +447944444444';
                newTask.CallType = 'Outbound';//Assign call type (our primary indicator for call activities)
            }
            taskList.add(newTask);
        }
        system.assertEquals(100, taskList.size());//100 records prepared for insert

        Test.startTest();
            insert taskList;
        Test.stopTest();

        //Confirm the subtypes for the 50 tasks assigned a CallType were updated successfully
        system.assertEquals(50, [Select Count() From Task Where TaskSubtype = :ApplicationConstant.TASK_CALL]);

    }

}