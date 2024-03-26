/*
Name:  NVMCallSummaryBatchClass.cls
Copyright © 2016  Golfbreaks
======================================================
======================================================
Purpose:
-------
Batch class for NVMStatsSF__NVM_Call_Summary__c custom object.
======================================================
======================================================
History
------- 
Ver. Author          Date        Detail
1.0  Simon Molloy    2016-09-13  Initial development.
1.1  Simon Molloy    2016-10-27  Add lookup to Custom Setting for NVM_Skill_Mapping_List_Setting__c
*/
global class NVMCallSummaryBatchClass implements Database.Batchable<sObject> {
    global String CLASS_NAME = 'NVMCallSummaryBatchClass';
    global String query {get; set;}
    global List<NVMStatsSF__NVM_Call_Summary__c> saveRecords {get; set;}
    global Map<String, NVM_Skill_Mapping_List_Setting__c> skillsMap {get; set;}
    global Map<String, User> userMap {get; set;}
    
    global NVMCallSummaryBatchClass() {
        
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        userMap = new Map<String, User>();
        for (User u : [select Name, Id, UserRole.Name from User where IsActive = TRUE]){
            userMap.put(u.Name, u);
        }
        system.debug('*** -- Usermap size = ' + userMap.size() + ' -- ***');
        if (null == query){
            query = 'select Id, NVMStatsSF__ChkStr__c, Skill__c, NVMStatsSF__Date__c, NVMStatsSF__Ring_List__c, NVMStatsSF__NVM_AgentID__c, ';
            query += 'NVMStatsSF__Agent_List__c, Batch_Processed__c, Demand_User__c, Demand_User_Role__c '; 
            query += 'from NVMStatsSF__NVM_Call_Summary__c ';  
            query += 'where Batch_Processed__c = FALSE ';//Order By CreatedDate DESC LIMIT 1000';
        }

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<NVMStatsSF__NVM_Call_Summary__c> scope) {
        
        if (userMap == null){
            userMap = new Map<String, User>();
            for (User u : [select Name, Id, UserRole.Name from User where IsActive = TRUE]){
                userMap.put(u.Name, u);
            }
        }
        
        saveRecords = new List<NVMStatsSF__NVM_Call_Summary__c>();
        
        skillsMap = new Map<String, NVM_Skill_Mapping_List_Setting__c>();
        
        for (NVM_Skill_Mapping_List_Setting__c nvmSkill : [select Name, Mapping_Type__c, Value__c from NVM_Skill_Mapping_List_Setting__c]){
            skillsMap.put(nvmSkill.Name, nvmSkill);
        }

        if (null != scope && !scope.isEmpty()){
            List<String> substrings;
            for (NVMStatsSF__NVM_Call_Summary__c c : scope){
                c.Batch_Processed__c = TRUE; 
                if (String.isBlank(c.NVMStatsSF__ChkStr__c)) continue;
                if (!c.NVMStatsSF__ChkStr__c.containsIgnoreCase('SkillTagger~ST')) continue;
        
                substrings = c.NVMStatsSF__ChkStr__c.split('SkillTagger~ST');
                if (substrings==null || substrings.isEmpty()) continue;
                
                String nvmSkill = substrings[substrings.size()-1].split('\\|')[0].trim();                                  
                //c.Skill__c = substrings[substrings.size()-1].split('\\|')[0].trim();
                c.Skill__c = nvmSkill;
                
                //Populate the role fields based on Skill value
                populateRoleFields(c, nvmSkill, userMap);   
            }
        }

        
        update scope;

        createCallSummaryAgentRecords(scope);
        
        
    }
    
    global void finish(Database.BatchableContext BC) {
        //EMPTY
    }

    // -------------  PRIVATE HELPER METHODS ---------------- //
    
    private void populateRoleFields(NVMStatsSF__NVM_Call_Summary__c callSummary, String nvmSkill, Map<String, User> userMap){
        NVM_Skill_Mapping_List_Setting__c skillCS = skillsMap.get(nvmSkill);
        if (null == skillCS) return;    
        
        if ('USER'.equalsIgnoreCase(skillCS.Mapping_Type__c)){
            callSummary.Demand_User__c = skillCS.Value__c;

            User u = userMap.get(skillCS.Value__c);
            if (null != u){
                callSummary.Demand_User_Role__c = u.UserRole.Name;
            }
        }else if ('USERROLE'.equalsIgnoreCase(skillCS.Mapping_Type__c)){
            callSummary.Demand_User_Role__c = skillCS.Value__c;
        }
    }

    private void createCallSummaryAgentRecords(List<NVMStatsSF__NVM_Call_Summary__c> modifiedRecords){      
        List<Error_Log__c> logs = new List<Error_Log__c>();
        try {           
            
            Map<String,List<NVM_Call_Summary_Agent__c>> agentIdToSummaries = new Map<String,List<NVM_Call_Summary_Agent__c>>(); 
            
            // for each record 
            // - parse NVMStatsSF__Ring_List__c field - e.g. //102:15, 112:4
            //   build map AgentId to List<CallSummaryAgent>  
            // - parse NVMStatsSF__Agent_List__c field - e.g. //102-0, 112-173
            //   build map AgentId to List<CallSummaryAgent>            
            String agentId,durationInSeconds;
            Map<String, Id> developerNameToRTId = AppHelper.getRecordTypesByDeveloperName('NVM_Call_Summary_Agent__c');                              
            Set<Id> callSummaryIds = new Set<Id>();
            Date summaryDate;
            
            for (NVMStatsSF__NVM_Call_Summary__c c : modifiedRecords){
                callSummaryIds.add(c.Id);
                
                if (summaryDate==null && c.NVMStatsSF__Date__c!=null) summaryDate = c.NVMStatsSF__Date__c;
                
                if (!String.isBlank(c.NVMStatsSF__Ring_List__c)){
                    
                    Id rtIdAgentQueue=developerNameToRTId.get('Agent_Queue');   
                    for (String token : c.NVMStatsSF__Ring_List__c.split(',')){
                        
                        agentId = token.split(':')[0].trim();
                        durationInSeconds = token.split(':').size()==1 ? '0' : token.split(':')[1];
                        
                        if (!agentIdToSummaries.containsKey(agentId)) agentIdToSummaries.put(agentId, new List<NVM_Call_Summary_Agent__c>());
                        
                        agentIdToSummaries.get(agentId).add(new NVM_Call_Summary_Agent__c( NVM_Call_Summary__c = c.Id,
                                                                                            NVM_Agent_Summary__c = null,
                                                                                            Duration_Seconds__c = Double.valueOf(durationInSeconds),
                                                                                            Agent__c=null,
                                                                                            Successful_Connection__c = (!String.isBlank(c.NVMStatsSF__NVM_AgentID__c) && 
                                                                                                                        c.NVMStatsSF__NVM_AgentID__c.equals(agentId) &&
                                                                                                                        Double.valueOf(durationInSeconds) > 0) ? true : false, 
                                                                                            Agent_Role__c=null,
                                                                                            RecordTypeId=rtIdAgentQueue ));
                    }
                }
                if (!String.isBlank(c.NVMStatsSF__Agent_List__c)){
                        
                    Id rtIdAgentAnswered=developerNameToRTId.get('Agent_Answered');
                    for (String token : c.NVMStatsSF__Agent_List__c.split(',')){
                        
                        agentId = token.split('-')[0].trim();                       
                        durationInSeconds = token.split('-').size()==1 ? '0' : token.split('-')[1]; 
                        
                        if (!agentIdToSummaries.containsKey(agentId)) agentIdToSummaries.put(agentId, new List<NVM_Call_Summary_Agent__c>());
                        
                        agentIdToSummaries.get(agentId).add(new NVM_Call_Summary_Agent__c( NVM_Call_Summary__c = c.Id,
                                                                                            NVM_Agent_Summary__c = null,
                                                                                            Duration_Seconds__c = Double.valueOf(durationInSeconds),
                                                                                            Agent__c=null,
                                                                                            Successful_Connection__c = !String.isBlank(c.NVMStatsSF__NVM_AgentID__c) && 
                                                                                                                        c.NVMStatsSF__NVM_AgentID__c.equals(agentId) ? true : false,
                                                                                            Agent_Role__c=null,
                                                                                            RecordTypeId=rtIdAgentAnswered ));          
                    }
                }               
            }
            // On update flush any existing records.
            if (callSummaryIds.size()>0){ delete [select Id from NVM_Call_Summary_Agent__c where NVM_Call_Summary__c in:callSummaryIds]; }
                        
            if (agentIdToSummaries.size()==0) return;
            
            
            // query user role for map key set
            // for each user update CallSummaryAgent records            
            for (User u : [select Id, Name, UserRole.Name, NVMContactWorld__NVM_Agent_Id__c from User 
                            where NVMContactWorld__NVM_Agent_Id__c in :agentIdToSummaries.keySet()]){
                
                for (NVM_Call_Summary_Agent__c c : agentIdToSummaries.get(u.NVMContactWorld__NVM_Agent_Id__c)){                 
                    c.Agent__c = u.Id;
                    c.Agent_Role__c = u.UserRole.Name;                  
                }
            }


            // query agent summary records for map keyset           
            // for each agent update CallSummaryAgent records
            for (NVMStatsSF__NVM_Agent_Summary__c a : [select Id, NVMStatsSF__AgentID__c from NVMStatsSF__NVM_Agent_Summary__c 
                                                        where NVMStatsSF__AgentID__c in :agentIdToSummaries.keySet()
                                                        and NVMStatsSF__Date__c=:summaryDate]){
                
                for (NVM_Call_Summary_Agent__c c : agentIdToSummaries.get(a.NVMStatsSF__AgentID__c)){                   
                    c.NVM_Agent_Summary__c = a.Id;          
                }
            }
            
            
            // insert CallSummaryAgent records.
            List<NVM_Call_Summary_Agent__c> recordsToInsert = new List<NVM_Call_Summary_Agent__c>();
            for (String k : agentIdToSummaries.keySet()){
                recordsToInsert.addAll(agentIdToSummaries.get(k));
            }
            if (!recordsToInsert.isEmpty()) Database.insert(recordsToInsert);           

        } catch (Exception e){
            logs.add(ApplicationConstant.getExceptionLog(e, 'createCallSummaryAgentRecords()', CLASS_NAME, 'NVMStatsSF__NVM_Call_Summary__c'));
        }finally {
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }       
    }
    
}