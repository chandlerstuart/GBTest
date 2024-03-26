/*
Name:  EmailMessageTriggerHandler.cls
Copyright © 2014  CloudMethods
======================================================
======================================================
Purpose:
-------
Handler class for all trigger operations related to the EmailMessage standard object.
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2014-05-21  Initial development.
1.1  J Radcliffe   2021-06-26  Modifying logic to expect other types of parent id (to enable Enhanced Email feature)
*/
public with sharing class EmailMessageTriggerHandler {    
    private Boolean isExecuting = false; //& indicates whether the script is executing in a Trigger context.
    private Integer batchSize = 0;

    //& statics to prevent recursive behaviour associated with update operations.
    //& (via W/F update later in the context sequence or direct in-trigger update or in-direct via roll-up (OLI, OLIS)).
    //public static Boolean firstBeforeUpdateRun = true;
    //public static Boolean firstAfterUpdateRun = true;
    
    public EmailMessageTriggerHandler(boolean isExecuting, integer size){
        isExecuting = isExecuting;
        batchSize = size;
    }
            
    //& trigger action methods.
    
    //public void onBeforeInsert(EmailMessage[] insertedRecords){}
    
    public void onAfterInsert(EmailMessage[] insertedRecords, Map<Id, EmailMessage> newMap){
    	
    	Map<Id,Case> idToCaseToUpdate = processInboundReplyEmailMessages(insertedrecords, newMap);    	
    	
    	if (!idToCaseToUpdate.isEmpty()){
    		
    		try {
    			//Note - the trigger operates in allOrNothing mode - no partial updates are applied.
    			update idToCaseToUpdate.values();
    		} catch (Exception e){
				System.debug(LoggingLevel.WARN, '->->Exception thrown : ' + e.getMessage());
				for (EmailMessage em : insertedRecords){ em.addError(e.getMessage()); }
    		}
    	}    	
    }
    
    //public void onBeforeUpdate(EmailMessage[] updatedRecords, Map<Id, EmailMessage> newMap, Map<Id, EmailMessage> oldMap){}
    
    //public void onAfterUpdate(EmailMessage[] updatedRecords, Map<Id, EmailMessage> newMap, Map<Id, EmailMessage> oldMap){}
    
    //public void onBeforeDelete(List<EmailMessage> deletedRecords, Map<Id, EmailMessage> oldMap){}{}
    
    //public void onAfterDelete(List<EmailMessage> deletedRecords, Map<Id, EmailMessage> oldMap){}
    
    //public void onAfterUndelete(List<EmailMessage> undeletedRecords, Map<Id, EmailMessage> newMap){}
    
    //& End trigger action methods.
    
    //& helper methods.
	private Map<Id,Case> processInboundReplyEmailMessages(List<EmailMessage> insertedRecords, Map<Id, EmailMessage> newMap){		
		//Note, enumerate the email messages - select inbound - get parentId.
		// if the inbound is not the only inbound email for the case - then update the Last_Inbound_Email_Reply_Date__c field on Case.		
		Map<Id,Case> idToCaseToUpdate = new Map<Id,Case>();
		
		try {			
			Map<Id, EmailMessage> caseIdToEmailMessage = new Map<Id, EmailMessage>();			
			
			for (EmailMessage em : insertedRecords){
				if (em.Incoming && em.ParentId!=null && String.valueOf(em.ParentId).startsWithIgnoreCase('500')){//1.1~startsWith
					caseIdToEmailMessage.put(em.ParentId, em);					
				}
			}

			if(!caseIdToEmailMessage.isEmpty()){//1.1+
				for (Case c : [select id, (select Id from EmailMessages where Incoming=true) from Case where Id in:caseIdToEmailMessage.keySet()]){
					if (c.EmailMessages.size()>1){
						c.Last_Inbound_Email_Reply_Date__c = caseIdToEmailMessage.get(c.Id).MessageDate;
						idToCaseToUpdate.put(c.Id,c);
					}
				}
			}
			
		} catch (Exception e){
			System.debug(LoggingLevel.WARN, '->->Exception thrown : ' + e.getMessage());
			for (EmailMessage em : insertedRecords){ em.addError(e.getMessage()); }
		}
		return idToCaseToUpdate;
	}
	//& End helper methods.
}