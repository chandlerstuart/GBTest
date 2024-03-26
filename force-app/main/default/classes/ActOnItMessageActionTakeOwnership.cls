/*
Name:  ActOnItMessageActionTakeOwnership.cls
======================================================
======================================================
Purpose:
-------
ActOnIt plugin action (to be launched from an AOI alert message). 
This action takes ownership of a message's related record(s). 
This action will support any Object with an Owner field (supports record ownership).
======================================================
======================================================
History
------- 
Ver.  Author            Date        Detail
1.0   J Radcliffe       2021-03-23  Class creation.
*/
global with sharing class ActOnItMessageActionTakeOwnership implements ActOnIt.ActOnItMessageAction { 

    global ActOnIt.ActOnItMessageActionResult execute( String userId, String messageLogId, String messageTypeId, String  messageActionId, List<Id> relatedRecordIds){
        
        try{
            //Validate Input
            if(relatedRecordIds== null || relatedRecordIds.size()==0) return new ActOnIt.ActOnItMessageActionResult(false,'Message has no related record(s)',null);
            //Identify SObjectType
            String sObjectType = String.valueOf(relatedRecordIds[0].getsobjecttype());
            //Validate the SObjectType has an OwnerId field (supports record ownership)
            Boolean hasOwnerField = Schema.getGlobalDescribe().get(sObjectType).getDescribe().fields.getMap().containsKey('ownerId');
            if(hasOwnerField){
                //Dynamically Query Record
                String query = 'Select Id, OwnerId From '+String.escapeSingleQuotes(sObjectType)+' Where Id IN :relatedRecordIds';
                List<sObject> recordsToUpdate = Database.query(query);
                if(recordsToUpdate.size()==0) return new ActOnIt.ActOnItMessageActionResult(false,'Could not find related record(s)',null);
                //Update Owner
                for(sObject record : recordsToUpdate){
                     record.put('OwnerId',userId);
                }
                update recordsToUpdate;
                //Create Result
                ActOnIt.ActOnItMessageActionResult result = new ActOnIt.ActOnItMessageActionResult(true,null,null);
                //If there is only one record, assign the record Id (to open the record for the user)
                if(recordsToUpdate.size()==1) result.navigateToRecordId = relatedRecordIds[0];
                //Return Success Response
                return result;
            }else{
                //Return Fail Response
                return new ActOnIt.ActOnItMessageActionResult(false,'Cannot take ownership of '+sObjectType+' records',null);
            }
        }catch(Exception e){
            //Return Fail Response
            return new ActOnIt.ActOnItMessageActionResult(false,'Oops there was an error: '+e.getMessage(),null);
        }
    }
}