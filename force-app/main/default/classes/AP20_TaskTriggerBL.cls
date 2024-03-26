/*
Name:   AP20_TaskTriggerBL.cls
======================================================
======================================================
Purpose:
-------
Test Class for  AP20_TaskTriggerBL
======================================================
======================================================
History
------- 
Ver. Author             Date         Detail 
1.0  Renz Melecotones   25-04-2016   Initial development
2.0  J.Radcliffe        08-08-2023   New method - assignTaskSubtype - Responsible for setting the TaskSubtype to 'Call' for call activities before insert.
*/
public with sharing class AP20_TaskTriggerBL {

    // Used for logging --- Added by Dee 5/15
    public static final String CLASS_NAME = 'AP20_TaskTriggerBL';
    
    public static final string DIVIDER = '--------Save your notes above this line--------';
    private static Map<String, String> allNotes = new Map<String, String>();
    private static Map<String, User> allUsers = new Map<String, User>();
    
    /**
       *  This method is used to update Requested Call Back Date & Time field on related Case, Opp or Lead if the record is created.
       *  @name: updateCallBackDateTime
       *  @developer: Renz Melecotones 25/04/2016
       *  @param: taskList - get Trigger.new from TaskTrigger of List<Task> Data Type
       *  Ver   Developer   Date        Description
       *  1.0   Renz M.     25/04/2016  Initial implementation
       *  2.0   Nicole DG   07/05/2016  Code review - Updated line 64, 70 & 76 to check for set size instead of checking if it's not NULL
    **/
    public static void updateCallBackDateTime(List<Task> taskList, Map<Id, Task> oldTaskMap){       
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Set<Id> caseIdSet = new Set<Id>();
        Set<Id> oppIdSet = new Set<Id>();
        Set<Id> leadIdSet = new Set<Id>();
        
        Map<Id, Case> caseIdMap = new Map<Id,Case>();
        Map<Id, Opportunity> oppIdMap = new Map<Id, Opportunity>();
        Map<Id, Lead> leadIdMap = new Map<Id, Lead>();  
        Map<String, String> mapAccAndErrors = new Map<String, String>();
        
        String casePrefixStr = Schema.SObjectType.Case.getKeyPrefix();
        String oppPrefixStr = Schema.SObjectType.Opportunity.getKeyPrefix();
        String leadPrefixStr = Schema.SObjectType.Lead.getKeyPrefix();
            
        String whatIdStr;
        String whoIdStr;
        
        try{
            if(oldTaskMap == null){
                for(Task taskRec: taskList){
                    whatIdStr = taskRec.WhatId;
                    whoIdStr = taskRec.WhoId;
                    if(taskRec.Call_Back_Date_and_Time_Activity__c <> null){
                        if(taskRec.WhatId <> null && whatIdStr.startsWith(casePrefixStr)){
                            caseIdSet.add(taskRec.WhatId);
                        }else if(taskRec.WhatId <> null && whatIdStr.startsWith(oppPrefixStr)){ 
                            oppIdSet.add(taskRec.WhatId);
                        }else if(taskRec.WhoId <> null && whoIdStr.startsWith(leadPrefixStr)){      
                            leadIdSet.add(taskRec.WhoId);
                        }
                    }
                    
                }
            }else{
                for(Task taskRec: taskList){
                    whatIdStr = taskRec.WhatId;
                    whoIdStr = taskRec.WhoId;
                    if(taskRec.Call_Back_Date_and_Time_Activity__c <> null){
                        if(taskRec.WhatId <> null && whatIdStr.startsWith(casePrefixStr) && taskRec.Call_Back_Date_and_Time_Activity__c <> oldTaskMap.get(taskRec.Id).Call_Back_Date_and_Time_Activity__c){         
                            caseIdSet.add(taskRec.WhatId);
                        }else if(taskRec.WhatId <> null && whatIdStr.startsWith(oppPrefixStr) && taskRec.Call_Back_Date_and_Time_Activity__c <> oldTaskMap.get(taskRec.Id).Call_Back_Date_and_Time_Activity__c){    
                            oppIdSet.add(taskRec.WhatId);
                        }else if(taskRec.WhoId <> null && whoIdStr.startsWith(leadPrefixStr) && taskRec.Call_Back_Date_and_Time_Activity__c <> oldTaskMap.get(taskRec.Id).Call_Back_Date_and_Time_Activity__c){     
                            leadIdSet.add(taskRec.WhoId);
                        }
                    }
                }
            }
            
            if(caseIdSet.size() > 0){
                for(Case caseRec: [SELECT Id, RequestedCallBackDateAndTime__c FROM Case WHERE Id IN: caseIdSet]){
                    caseIdMap.put(caseRec.Id, caseRec);
                }
            }
            
            if(oppIdSet.size() > 0){
                for(Opportunity oppRec: [SELECT Id, RequestedCallbacktimedate__c FROM Opportunity WHERE Id IN: oppIdSet]){
                    oppIdMap.put(oppRec.Id, oppRec);
                }
            }
            
            if(leadIdSet.size() > 0){
                for(Lead leadRec: [SELECT Id, CallBackDateTime__c FROM Lead WHERE Id IN: leadIdSet]){
                    leadIdMap.put(leadRec.Id, leadRec);
                }
            }
            
            for(Task taskRec: taskList){            
                if(caseIdMap.containsKey(taskRec.WhatId)){
                    caseIdMap.get(taskRec.WhatId).RequestedCallBackDateAndTime__c = taskRec.Call_Back_Date_and_Time_Activity__c;
                }
                
                if(oppIdMap.containsKey(taskRec.WhatId)){
                    oppIdMap.get(taskRec.WhatId).RequestedCallbacktimedate__c = taskRec.Call_Back_Date_and_Time_Activity__c;
                }
                
                if(leadIdMap.containsKey(taskRec.WhoId)){
                    leadIdMap.get(taskRec.WhoId).CallBackDateTime__c = taskRec.Call_Back_Date_and_Time_Activity__c;
                }           
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'updateCallBackDateTime()', CLASS_NAME, null));
        }finally{
            if(logs.isEmpty()){
                if(caseIdMap.size() > 0){
                    Database.SaveResult[] updateCaseMap = Database.update(caseIdMap.values(), false);
                    logs.addAll(ApplicationConstant.getSaveResultLog(updateCaseMap, 'updateCallBackDateTime()', CLASS_NAME, ApplicationConstant.CASE_SOBJECTTYPE, 'Update'));
                }
                
                if(oppIdMap.size() > 0){
                    Database.SaveResult[] updateOppMap = Database.update(oppIdMap.values(), false);
                    logs.addAll(ApplicationConstant.getSaveResultLog(updateOppMap, 'updateCallBackDateTime()', CLASS_NAME, 'Opportunity', 'Update'));
                }
                
                if(leadIdMap.size() > 0){
                    Database.SaveResult[] updateLeadMap = Database.update(leadIdMap.values(), false);
                    logs.addAll(ApplicationConstant.getSaveResultLog(updateLeadMap, 'updateCallBackDateTime()', CLASS_NAME, ApplicationConstant.LEAD_SOBJECTTYPE, 'Update'));
                }
            }
        
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }  
    }

    //2.0+ - Assign the 'Call' task subtype to call activity tasks generated by the vonage package.
    //Vonage were unable to action this at present and the task subtype field isn't available for selection in record triggered flows (hence the trigger)
    public static void assignTaskSubtype(List<Task> newTasks){
        if(newTasks == null) return;
        for(Task newTask : newTasks){
            if(newTask.CallType != null) newTask.TaskSubtype = ApplicationConstant.TASK_CALL;
        }
    }


    // Populate “Name (WhoId)” field of Task with “Person Account” via “Related To (WhatId)” field. 
    // WhatId can be a Case “or” an Opportunity
    public static void populateWhoId(List<Task> newTasks){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Set<Id> caseIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        Map<Id, Id> caseAcctIdMap = new Map<Id, Id>();
        Map<Id, Id> opportunityAcctIdMap = new Map<Id, Id>();

        String casePrefix = Schema.SObjectType.Case.getKeyPrefix();
        String opportunityPrefix = Schema.SObjectType.Opportunity.getKeyPrefix();

        String whatId;
        
        try{
            for(Task task : newTasks){
                whatId = task.WhatId;
                if(!String.isEmpty(whatId)){
                    if(task.WhoId == null && whatId.startsWith(casePrefix)){
                        caseIds.add(task.WhatId);
                    }
                    else if(task.WhoId ==null && whatId.startsWith(opportunityPrefix)){
                        opportunityIds.add(task.WhatId);
                    }
                }
            }
    
            if(caseIds.size() > 0 ){
                for( Case c : [SELECT Id, AccountId, Account.PersonContactId FROM Case WHERE Id IN : caseIds AND Account.isPersonAccount = true]){
                    caseAcctIdMap.put(c.Id, c.Account.PersonContactId);
                }
            }

            if(opportunityIds.size() > 0){
                for( Opportunity o : [SELECT Id, AccountId, Account.PersonContactId FROM Opportunity WHERE Id IN : opportunityIds AND Account.isPersonAccount = true]){
                    opportunityAcctIdMap.put(o.Id, o.Account.PersonContactId);
                }
            }
    
            if(caseIds.size() > 0 || opportunityAcctIdMap.size() > 0){
                for(Task task : newTasks){
                    whatId = task.WhatId;
                    if(!String.isEmpty(whatId)){
                        if(task.WhoId == null && whatId.startsWith(casePrefix)){
                            task.WhoId = caseAcctIdMap.get(whatId);
                        }
                        else if(task.WhoId == null && whatId.startsWith(opportunityPrefix)){
                            task.WhoId = opportunityAcctIdMap.get(whatId);
                        }
                    }
                }
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'populateWhoId()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }  
    }

    // Populate NVM Notes into Description and Call_Notes__c field
    public static void populateNVMCallNotes(List<Task> lsTasks){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Set<String> setCallObjectIds = new Set<String>();
        Set<String> setInteractionEventIds = new Set<String>();
        Map<String, String> mapCallObjectIdANDCallNotes = new Map<String, String>();
        try{
            if( lsTasks.size() > 0 ){                
                for(Task taskRecord : lsTasks){
                    if(!String.isEmpty(taskRecord.CallObject) ){            
                        setCallObjectIds.add(taskRecord.CallObject);
                    }
                }
                if( setCallObjectIds.size() > 0 ){  
                    for(NVMContactWorld__InteractionEvent__c interactionEvent : [SELECT Id, NVMContactWorld__IndexedCallObjectIdentifier__c FROM NVMContactWorld__InteractionEvent__c WHERE NVMContactWorld__IndexedCallObjectIdentifier__c IN :setCallObjectIds]){
                        setInteractionEventIds.add(interactionEvent.Id);                    
                    }
                    if( setInteractionEventIds.size() > 0 ){
                        for(NVMContactWorld__InteractionEventNote__c interactionEventNote : [SELECT Id, NVMContactWorld__Detail__c, NVMContactWorld__Event__c, NVMContactWorld__Event__r.NVMContactWorld__IndexedCallObjectIdentifier__c FROM NVMContactWorld__InteractionEventNote__c WHERE NVMContactWorld__Event__c IN :setInteractionEventIds]){
                            if(interactionEventNote.NVMContactWorld__Detail__c <> null){
                                mapCallObjectIdANDCallNotes.put( interactionEventNote.NVMContactWorld__Event__r.NVMContactWorld__IndexedCallObjectIdentifier__c, interactionEventNote.NVMContactWorld__Detail__c );
                            }                                                   
                        }
                    }
    
                    if( mapCallObjectIdANDCallNotes <> null && mapCallObjectIdANDCallNotes.size() > 0 ){
                        for(Task taskRecord : lsTasks){
                            if(!String.isEmpty(taskRecord.CallObject) ){
                                if( mapCallObjectIdANDCallNotes.containsKey(taskRecord.CallObject) ){
                                    taskRecord.Description = mapCallObjectIdANDCallNotes.get(taskRecord.CallObject);
                                    taskRecord.Call_Notes__c = mapCallObjectIdANDCallNotes.get(taskRecord.CallObject);
                                }
                            }
                        }
                    }
                }
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'populateNVMCallNotes()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }
    
    
    //method used in processTask
    public static void createUsersLookup (List<Task> newTasks) {
        List<User> users = [Select ID, FirstName, LastName, Name, isActive from User WHERE isActive =: TRUE];      
        for (User a : users) {
            allUsers.put(a.ID, a);
        }
        System.debug('Size of allUsers is ' + allUsers.size());
    }  
    
    //method used in processTask
    public static void createInteractionEventNotesLookup (List<Task> newTasks) {
        List<Error_Log__c> logs = new List<Error_Log__c>();
    
        //Build parent and child list of all Interaction Events and Interaction Notes
        List <NVMContactWorld__InteractionEventNote__c> conList = New List<NVMContactWorld__InteractionEventNote__c>();
        String combinedNote;
        String guid;
        String newGuid;
        String oldGuid;
        List<String> taskCallGuids = new List<String> ();
        try{
            //List<Id> taskCallGuids = new List<Id> ();
            
            for (Task ss : newTasks) {
                if(!String.isEmpty(ss.CallObject)){
                    taskCallGuids.Add(ss.CallObject);
                }
            }
    
            for(NVMContactWorld__InteractionEvent__c event:
                [Select id, name, NVMContactWorld__Agent__c,
                NVMContactWorld__CallObjectIdentifier__c,
                (SELECT Name,  CreatedDate, NVMContactWorld__Detail__c
                FROM NVMContactWorld__Interaction_Event_Notes__r)
                From NVMContactWorld__InteractionEvent__c
                WHERE NVMContactWorld__CallObjectIdentifier__c IN :taskCallGuids
                ORDER BY NVMContactWorld__TimeStamp__c ASC NULLS FIRST]){
                combinedNote = Null;
                //Loop through child records
                for(NVMContactWorld__InteractionEventNote__c note:event.NVMContactWorld__Interaction_Event_Notes__r){
                    //Change ID for real name
                    User createdByName = allUsers.get(event.NVMContactWorld__Agent__c);
                    newGuid = event.NVMContactWorld__CallObjectIdentifier__c;
                    //We need to merge single records into 1
                    String noteDetail;
                    if (note.NVMContactWorld__Detail__c != Null) {
                        noteDetail = note.NVMContactWorld__Detail__c;
                    }
                    else {
                        noteDetail = 'This agent saved no notes'; 
                    }
                    conList.add(note); 
                    //Create the actual string
                    combinedNote = createdByName.Name + ' | on ' + note.CreatedDate + ' | ' + noteDetail + '\r\n'; 
                    guid = event.NVMContactWorld__CallObjectIdentifier__c;
                    if (allNotes.get(event.NVMContactWorld__CallObjectIdentifier__c) == Null) {
                        System.debug('Map not created - create it');
                        allNotes.put(guid, combinedNote); 
                    }
                    else {
                        System.debug('Map already created - update it');
                        String oldNotes = allNotes.get(event.NVMContactWorld__CallObjectIdentifier__c);
                        System.debug('oldNotes is ' + oldNotes);
                        allNotes.put(event.NVMContactWorld__CallObjectIdentifier__c, oldNotes + ' \r\n' + combinedNote);
                        System.debug('allNotes is ' + allNotes.values());
                    }
                } //end outer for
            }
        }catch(Exception e){           
           e.setMessage(e.getMessage() + ' : ' + taskCallGuids);
           logs.add(ApplicationConstant.getExceptionLog( e, 'createInteractionEventNotesLookup()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }
    
    //process task
    public static void processTasks(List<Task> newTasks) {
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        try{ 
            createUsersLookup (newTasks);
            createInteractionEventNotesLookup (newTasks);
            System.debug('Starting class');     
            //Loop through Task records and get GUIDs to query Interaction Events - checking that it is only NVM Tasks
            for (Task ss : newTasks) { 
                //Final call to the built map to populate description
                if(!String.isEmpty(ss.CallObject)){
                    String oldValue = ss.Description;
                    if(String.isEmpty(ss.Description)) {
                        ss.Description = '\r\n' + DIVIDER + '\r\n' + allNotes.get(ss.CallObject);
                    }
                    else if (oldValue.contains(DIVIDER)) {
                        Integer thingsToRemove = oldValue.indexOf(DIVIDER);
                        System.debug('Remove string after position ' + thingsToRemove); 
                        System.debug('Previous call notes found');
                        ss.Description = oldValue.left(thingsToRemove) + '\r\n' + DIVIDER + '\r\n' + allNotes.get(ss.CallObject);
                    }
                    else {
                        String newValue = oldValue + '\r\n' + DIVIDER + '\r\n' + allNotes.get(ss.CallObject);
                        ss.Description = newValue; 
                    }
                }
            } //end for 
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'processTasks()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    } //end method
    
    
    /**
   *  This method is used to populate the diary date notes on Lead or Opp on insert
   *  @name: populateDiaryDateNotes
   *  @developer: Vince Canlas (ACN) - June 17, 2016 
   *  @param: List<Task> newTasks from Trigger.New
   *        
   */
    public static void populateDiaryDateNotes(List<Task> newTasks) {
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Set<Id> oppIdSet = new Set<Id>();
        Set<Id> leadIdSet = new Set<Id>();
        
        Map<Id, Opportunity> oppIdMap = new Map<Id, Opportunity>();
        Map<Id, Lead> leadIdMap = new Map<Id, Lead>();  
        Map<String, String> mapAccAndErrors = new Map<String, String>();
        
        String oppPrefixStr = Schema.SObjectType.Opportunity.getKeyPrefix();
        String leadPrefixStr = Schema.SObjectType.Lead.getKeyPrefix();
            
        String whatIdStr;
        String whoIdStr;
        
        try{
            if(newTasks <> null){
                for(Task taskRec: newTasks){
                    whatIdStr = taskRec.WhatId;
                    whoIdStr = taskRec.WhoId;
                    if(taskRec.Call_Notes__c <> null){
                        if(taskRec.WhatId <> null && whatIdStr.startsWith(oppPrefixStr)){ 
                            oppIdSet.add(taskRec.WhatId);
                        }else if(taskRec.WhoId <> null && whoIdStr.startsWith(leadPrefixStr)){      
                            leadIdSet.add(taskRec.WhoId);
                        }
                    }
                    
                }
            }
            if(oppIdSet.size() > 0){
                for(Opportunity oppRec: [SELECT Id, DiaryDateNote__c FROM Opportunity WHERE Id IN: oppIdSet]){
                    oppIdMap.put(oppRec.Id, oppRec);
                }
            }
            
            if(leadIdSet.size() > 0){
                for(Lead leadRec: [SELECT Id, DiaryDateNote__c FROM Lead WHERE Id IN: leadIdSet]){
                    leadIdMap.put(leadRec.Id, leadRec);
                }
            }
            
            for(Task taskRec: newTasks){            
                if(oppIdMap.containsKey(taskRec.WhatId)){
                    oppIdMap.get(taskRec.WhatId).DiaryDateNote__c = taskRec.Call_Notes__c;
                }
                
                if(leadIdMap.containsKey(taskRec.WhoId)){
                    leadIdMap.get(taskRec.WhoId).DiaryDateNote__c = taskRec.Call_Notes__c;
                }           
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'populateDiaryDateNotes()', CLASS_NAME, null));
        }finally{
            if(logs.isEmpty()){
                if(oppIdMap.size() > 0){
                    Database.SaveResult[] updateOppMap = Database.update(oppIdMap.values(), false);
                    logs.addAll(ApplicationConstant.getSaveResultLog(updateOppMap, 'populateDiaryDateNotes()', CLASS_NAME, 'Opportunity', 'Insert'));
                }
                
                if(leadIdMap.size() > 0){
                    Database.SaveResult[] updateLeadMap = Database.update(leadIdMap.values(), false);
                    logs.addAll(ApplicationConstant.getSaveResultLog(updateLeadMap, 'populateDiaryDateNotes()', CLASS_NAME, ApplicationConstant.LEAD_SOBJECTTYPE, 'Insert'));
                }
            }
        
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }  
    }
    
    /**
       *  This method is used to set the lead status to Contact Attempted when Lead status is New.
       *  @name: setLeadStatusToContactAttempted
       *  @developer: Vince Canlas (ACN) - July 22, 2016 
       *  @param: List<Task> newTasks from Trigger.New
       *        
       */
    /*public static void setLeadStatusToContactAttempted(List<Task> newTasks) { 
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Set<Id> leadIdSet = new Set<Id>();
        Map<Id, Lead> leadIdMap = new Map<Id, Lead>();  
        Map<String, String> mapAccAndErrors = new Map<String, String>();
        String leadPrefixStr = Schema.SObjectType.Lead.getKeyPrefix();
        String whoIdStr;
        
        try{
            if(newTasks <> null){
                for(Task taskRec: newTasks){
                    whoIdStr = taskRec.WhoId;
                    if(taskRec.WhoId <> null && whoIdStr.startsWith(leadPrefixStr)){      
                        leadIdSet.add(taskRec.WhoId);
                    }
                }
            }
            if(leadIdSet.size() > 0){
                for(Lead leadRec: [SELECT Id, Status FROM Lead WHERE Id IN: leadIdSet AND Status =: 'New']){
                    leadIdMap.put(leadRec.Id, leadRec);
                }
            }
            
            for(Task taskRec: newTasks){            
                if(leadIdMap.containsKey(taskRec.WhoId)){
                    leadIdMap.get(taskRec.WhoId).Status = 'Contact Attempted';
                }           
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'setLeadStatusToContactAttempted()', CLASS_NAME, null));
        }finally{
            if(logs.isEmpty()){
                if(leadIdMap.size() > 0){
                    Database.SaveResult[] updateLeadMap = Database.update(leadIdMap.values(), false);
                    logs.addAll(ApplicationConstant.getSaveResultLog(updateLeadMap, 'setLeadStatusToContactAttempted()', CLASS_NAME, ApplicationConstant.LEAD_SOBJECTTYPE, 'Insert'));
                }
            }
        
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }  
    }*/
}