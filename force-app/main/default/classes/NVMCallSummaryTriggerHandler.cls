/*
Name:  NVMCallSummaryTriggerHandler.cls
Copyright © 2015  CloudMethods
======================================================
======================================================
Purpose:
-------
Handler class for all trigger operations related to the NVMStatsSF__NVM_Call_Summary__c standard object.
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2016-07-18  Initial development.
*/
public with sharing class NVMCallSummaryTriggerHandler {    
    private Boolean isExecuting = false; //& indicates whether the script is executing in a Trigger context.
    private Integer batchSize = 0;

    //& statics to prevent recursive behaviour associated with update operations.
    //& (via W/F update later in the context sequence or direct in-trigger update or in-direct via roll-up (OLI, OLIS)).
    public static Boolean firstAfterUpdateRun = true;
    public static Boolean firstBeforeUpdateRun = true;
    
    public NVMCallSummaryTriggerHandler(boolean isExecuting, integer size){
        isExecuting = isExecuting;
        batchSize = size;
    }
            
    //& trigger action methods.    
    public void onBeforeInsert(NVMStatsSF__NVM_Call_Summary__c[] insertedRecords){
    	updateSkillField(insertedRecords);
    }
    
    public void onAfterInsert(NVMStatsSF__NVM_Call_Summary__c[] insertedRecords, Map<Id, NVMStatsSF__NVM_Call_Summary__c> newMap){    	
    	createCallSummaryAgentRecords(insertedRecords);
    }
    
    //public void onBeforeUpdate(NVMStatsSF__NVM_Call_Summary__c[] updatedRecords, Map<Id, NVMStatsSF__NVM_Call_Summary__c> newMap, Map<Id, NVMStatsSF__NVM_Call_Summary__c> oldMap){}
    
    public void onAfterUpdate(NVMStatsSF__NVM_Call_Summary__c[] updatedRecords, Map<Id, NVMStatsSF__NVM_Call_Summary__c> newMap, Map<Id, NVMStatsSF__NVM_Call_Summary__c> oldMap){ 
    	if (firstAfterUpdateRun){
    		firstAfterUpdateRun = false; // prevent recursive updates within applied logic. 
    		
	    	createCallSummaryAgentRecords(updatedRecords);	
    	}
    }
    
    //public void onBeforeDelete(List<NVMStatsSF__NVM_Call_Summary__c> deletedRecords, Map<Id, NVMStatsSF__NVM_Call_Summary__c> oldMap){}{}
    
    //public void onAfterDelete(List<NVMStatsSF__NVM_Call_Summary__c> deletedRecords, Map<Id, NVMStatsSF__NVM_Call_Summary__c> oldMap){}
    
    //public void onAfterUndelete(List<NVMStatsSF__NVM_Call_Summary__c> undeletedRecords, Map<Id, NVMStatsSF__NVM_Call_Summary__c> newMap){}
    
    //& End trigger action methods.
    
    
    //& helper methods.
	private void updateSkillField(List<NVMStatsSF__NVM_Call_Summary__c> modifiedRecords){		
		try {		
						
			List<String> substrings;
			
			for (NVMStatsSF__NVM_Call_Summary__c r : modifiedRecords){
				
				if (String.isBlank(r.NVMStatsSF__ChkStr__c)) continue;
	            if (!r.NVMStatsSF__ChkStr__c.containsIgnoreCase('SkillTagger~ST')) continue;
        
    	        substrings = r.NVMStatsSF__ChkStr__c.split('SkillTagger~ST');
            	if (substrings==null || substrings.isEmpty()) continue;
                                                  
            	r.Skill__c = substrings[substrings.size()-1].split('\\|')[0].trim();				
			}		

		} catch (Exception e){
			System.debug(LoggingLevel.WARN, '->->Exception thrown : ' + e.getMessage());	
			System.debug(LoggingLevel.WARN, '->->Exception thrown : ' + e.getStackTraceString());			
			//TODO - revisit approach to runtime exception handling.			
			for (NVMStatsSF__NVM_Call_Summary__c c : modifiedRecords){
				c.addError(e.getMessage());
			}
		}		
	}    

	private void createCallSummaryAgentRecords(List<NVMStatsSF__NVM_Call_Summary__c> modifiedRecords){		
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
																							Successful_Connection__c = !String.isBlank(c.NVMStatsSF__NVM_AgentID__c) && 
																														c.NVMStatsSF__NVM_AgentID__c.equals(agentId) ? true : false, 
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
			if (Trigger.isUpdate && callSummaryIds.size()>0){ delete [select Id from NVM_Call_Summary_Agent__c where NVM_Call_Summary__c in:callSummaryIds]; }
						
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
			System.debug(LoggingLevel.WARN, '->->Exception thrown : ' + e.getMessage());	
			System.debug(LoggingLevel.WARN, '->->Exception thrown : ' + e.getStackTraceString());			
			//TODO - revisit approach to runtime exception handling.			
			for (NVMStatsSF__NVM_Call_Summary__c c : modifiedRecords){
				c.addError(e.getMessage());
			}
		}		
	}

	//& End helper methods.
}