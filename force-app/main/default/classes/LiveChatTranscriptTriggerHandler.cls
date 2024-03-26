/*
Name:  LiveChatTranscriptTriggerHandler.cls
Copyright © 2015  CloudMethods
======================================================
======================================================
Purpose:
-------
Handler class for all trigger operations related to the LiveChatTranscript standard object.
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2014-08-06  Initial development (added processRatings).
*/
public with sharing class LiveChatTranscriptTriggerHandler {    
    private Boolean isExecuting = false; //& indicates whether the script is executing in a Trigger context.
    private Integer batchSize = 0;

    //& statics to prevent recursive behaviour associated with update operations.
    //& (via W/F update later in the context sequence or direct in-trigger update or in-direct via roll-up (OLI, OLIS)).
    public static Boolean firstAfterUpdateRun = true;
    public static Boolean firstBeforeUpdateRun = true;
    
    public LiveChatTranscriptTriggerHandler(boolean isExecuting, integer size){
        isExecuting = isExecuting;
        batchSize = size;
    }
            
    //& trigger action methods.    
    //public void onBeforeInsert(LiveChatTranscript[] insertedRecords){ }    
    
    public void onAfterInsert(LiveChatTranscript[] insertedRecords, Map<Id, LiveChatTranscript> newMap){
    	processRatings(insertedRecords, newMap);
    }    
    
    //public void onBeforeUpdate(LiveChatTranscript[] updatedRecords, Map<Id, LiveChatTranscript> newMap, Map<Id, LiveChatTranscript> oldMap){ }
    
    //public void onAfterUpdate(LiveChatTranscript[] updatedRecords, Map<Id, LiveChatTranscript> newMap, Map<Id, LiveChatTranscript> oldMap){ }
    
    //public void onBeforeDelete(List<LiveChatTranscript> deletedRecords, Map<Id, LiveChatTranscript> oldMap){}{}
    
    //public void onAfterDelete(List<LiveChatTranscript> deletedRecords, Map<Id, LiveChatTranscript> oldMap){}
    
    //public void onAfterUndelete(List<LiveChatTranscript> undeletedRecords, Map<Id, LiveChatTranscript> newMap){}
    
    //& End trigger action methods.
    
    
    //& helper methods.
    private void processRatings(List<LiveChatTranscript> modifiedRecords, Map<Id, LiveChatTranscript> newMap){    
    	try {    	
			
			Map<String, LiveChatTranscript> chatKeyToTranscript = new Map<String, LiveChatTranscript>();
			
			for (LiveChatTranscript t : modifiedRecords){
				chatKeyToTranscript.put(t.ChatKey,t);
			}
			
			List<Live_Chat_Transcript_Rating__c> ratingsToUpdate = new List<Live_Chat_Transcript_Rating__c>(); 
			
			for (Live_Chat_Transcript_Rating__c r : [select Id, Chat_Key__c from Live_Chat_Transcript_Rating__c 
														where Live_Chat_Transcript__c=null and Chat_Key__c in:chatKeyToTranscript.keySet()]){
			
				r.Live_Chat_Transcript__c = chatKeyToTranscript.get(r.Chat_Key__c).Id;
				r.OwnerId = chatKeyToTranscript.get(r.Chat_Key__c).OwnerId;
				
				if (chatKeyToTranscript.get(r.Chat_Key__c).AccountId!=null) r.Account__c = chatKeyToTranscript.get(r.Chat_Key__c).AccountId;
				
				ratingsToUpdate.add(r);														
			}	
			
			if (ratingsToUpdate.size()>0) update ratingsToUpdate;
			
		} catch (Exception e){		
			System.debug(LoggingLevel.WARN, '->->Exception thrown : ' + e.getMessage());			
			//TODO - revisit approach to runtime exception handling.			
			for (LiveChatTranscript c : modifiedRecords){ c.addError(e.getMessage()); }
    	}
    }       
	//& End helper methods.
}