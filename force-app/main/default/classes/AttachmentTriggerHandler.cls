/*
Name: AttachmentTriggerHandler.cls
Copyright © 2016  CloudMethods
======================================================
======================================================
Purpose:
-------

Trigger handler class for the object : Attachment

Permissions Model : None

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2016-02-10  Initial development.
*/
public with sharing class AttachmentTriggerHandler {
    private Boolean isExecuting = false; //& indicates whether the script is executing in a Trigger context.
    private Integer batchSize = 0;

    //& statics to prevent recursive behaviour associated with update operations.
    //& (via W/F update later in the context sequence or direct in-trigger update or in-direct via roll-up (OLI, OLIS)).
    public static Boolean firstAfterUpdateRun = true;
    public static Boolean firstBeforeUpdateRun = true;
    
    public AttachmentTriggerHandler(boolean isExecuting, integer size){
        isExecuting = isExecuting;
        batchSize = size;
    }
            
    //& trigger action methods.    
    //public void onBeforeInsert(Attachment[] insertedRecords){}
    
    public void onAfterInsert(Attachment[] insertedRecords, Map<Id, Attachment> newMap){    
        deleteDocuSignAttachments(insertedRecords);
    }
    
    //public void onBeforeUpdate(Attachment[] updatedRecords, Map<Id, Attachment> newMap, Map<Id, Attachment> oldMap){}
    
    //public void onAfterUpdate(Attachment[] updatedRecords, Map<Id, Attachment> newMap, Map<Id, Attachment> oldMap){}
    
    //public void onBeforeDelete(List<Attachment> deletedRecords, Map<Id, Attachment> oldMap){}
    
    //public void onAfterDelete(List<Attachment> deletedRecords, Map<Id, Attachment> oldMap){}
    
    //public void onAfterUndelete(List<Attachment> undeletedRecords, Map<Id, Attachment> newMap){}
    
    //& End trigger action methods.
    
    
    //& helper methods.
    
    public void deleteDocuSignAttachments(List<Attachment> modifiedRecords){        
        try {    
            // gather attachments parented by dsfs__DocuSign_Status__c records
            Map<Id,Id> dsStatusIdToAttachment = new Map<Id,Id>(); 
            for (Attachment a : modifiedRecords){   
                if ( a.parentId.getSObjectType().getDescribe().getName().equalsIgnoreCase('dsfs__DocuSign_Status__c') ){ dsStatusIdToAttachment.put(a.parentId,a.Id); }
            }
            if (dsStatusIdToAttachment.isEmpty()) return;
            
            // return parent records related to Job Application records.
            Set<Id> attachmentIdsToDelete = new Set<Id>();
            for (dsfs__DocuSign_Status__c dss : [select Id from dsfs__DocuSign_Status__c 
                                                            where Id in :dsStatusIdToAttachment.keySet()
                                                            and (Job_Application__c<>null OR Employee_Change_of_Terms__c<>null)]){
                attachmentIdsToDelete.add(dsStatusIdToAttachment.get(dss.Id));  
            }
            if (attachmentIdsToDelete.isEmpty()) return;
            
            // delete remaining attachments
            List<Attachment> attachmentsToDelete = [select Id from Attachment where Id in:attachmentIdsToDelete];
            if (!attachmentsToDelete.isEmpty()) delete attachmentsToDelete;
            if (!attachmentsToDelete.isEmpty()) Database.emptyRecyclebin(attachmentsToDelete);           

        } catch(Exception e){ for (Attachment a : modifiedRecords) { a.addError(e.getMessage()); } }        
    }
    //& End helper methods.    
}