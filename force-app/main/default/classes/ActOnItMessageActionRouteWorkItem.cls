/*
Name:  ActOnItMessageActionRouteWorkItem.cls
======================================================
======================================================
Purpose:
-------
ActOnIt plugin action (to be launched from an AOI alert message). 
This action updates the route work item checkbox of a message's related record(s),
implicitly triggering the reassignment of the record(s) via Omni Channel. 
This action will support any Object that can be routed via the GBWIRE routing application
======================================================
======================================================
History
------- 
Ver.  Author            Date        Detail
1.0   J Radcliffe       2021-03-23  Class creation.
*/
global with sharing class ActOnItMessageActionRouteWorkItem implements ActOnIt.ActOnItMessageAction {
    
    global ActOnIt.ActOnItMessageActionResult execute( String userId, String messageLogId, String messageTypeId, String  messageActionId, List<Id> relatedRecordIds){
        
        try{
            //Validate Input
            if(relatedRecordIds== null || relatedRecordIds.size()==0) return new ActOnIt.ActOnItMessageActionResult(false,'Message has no related record(s)',null);
            //Identify SObjectType
            String sObjectType = String.valueOf(relatedRecordIds[0].getsobjecttype());
            //Validate the SObjectType has a Route Work Item field (supports GBWIRE Routing)
            String rwiFieldName;
            try{
                rwiFieldName = [Select Id, GBWire__RouteWorkItemFieldName__c From GBWire__RoutingConfiguration__mdt Where GBWire__SObjectType__c =:sObjectType and GBWire__IsActive__c = true Limit 1].GBWire__RouteWorkItemFieldName__c;
            }catch(Exception e){
                return new ActOnIt.ActOnItMessageActionResult(false,'Cannot Route Work Items of this type ('+sObjectType+')',null);
            }
            
            //Dynamically Query Record(s)
            String query = 'Select Id, '+rwiFieldName+' From '+sObjectType+' Where Id IN :relatedRecordIds';
            List<sObject> recordsToUpdate = Database.query(query);
            if(recordsToUpdate.size()==0) return new ActOnIt.ActOnItMessageActionResult(false,'Could not find related record(s)',null);
            //Update RWI (to trigger the reassignment of the records)
            for(sObject record : recordsToUpdate){
                    record.put(rwiFieldName,true);
            }
            update recordsToUpdate;
            //Create Result
            ActOnIt.ActOnItMessageActionResult result = new ActOnIt.ActOnItMessageActionResult(true,null,null);
            //If there is only one record, assign the record Id (to open the record for the user)
            if(recordsToUpdate.size()==1) result.navigateToRecordId = relatedRecordIds[0];
            //Return Success Response
            return result;

        }catch(Exception e){
            //Return Fail Response
            return new ActOnIt.ActOnItMessageActionResult(false,'Oops there was an error: '+e.getMessage(),null);
        }
    }
}