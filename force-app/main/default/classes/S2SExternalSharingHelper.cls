/*
Name:  S2SExternalSharingHelper.cls
Copyright © 2015 CloudMethods
======================================================
======================================================
Purpose:
-------
Encapsulates all logic related to External Sharing via Salesforce-to-Salesforce.

Note1, Account.ParentId can't be set in the PNRC.ParentId field - this throws a INVALID_PARTNER_NETWORK_STATUS exception.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2015-05-06  Initial Development.
1.1  Mark Cane&    2015-05-07  Only set the parent Id on the PNRC record where the parent Id exists as a local Id on an active (Sent) status PNRC record.
1.2  Mark Cane&    2015-05-07  Added isParentMandatory parameter and overload to restrict sending child records when the parent is not shared.
1.3  Simon Molloy  2017-09-06  Created overloaded method to handle 'relatedRecords' parameter, and update PRNC record with the same
1.4  Simon Molloy  2017-12-12  Added 'isFromTrigger' boolean to stop 'addError' issues
1.5  Simon Molloy  2018-01-05  Added new custom setting to control how many minutes in the future the scheduled sharing occurs
*/
public with sharing class S2SExternalSharingHelper {
    public static final Integer DEFAULT_TIME_DELAY = 10;
    
    public boolean isFromTrigger {
        get {
            if (null == isFromTrigger) isFromTrigger = TRUE;
            return isFromTrigger;
        }
        set;
    }

    public void shareRecordsFromTrigger(List<SObject> insertedRecs, String parentFieldName, String sot){
        shareRecordsFromTrigger(insertedRecs, parentFieldName, sot, false, null);
    }

    public void shareRecordsFromTrigger(List<SObject> insertedRecs, String parentFieldName, String sot, Boolean isParentMandatory){     
        shareRecordsFromTrigger(insertedRecs, parentFieldName, sot, isParentMandatory, null);       
    }

    public void shareRecordsFromTrigger(List<SObject> insertedRecs, String parentFieldName, String sot, Boolean isParentMandatory, String relatedRecords){      
        try {           
            if (insertedRecs.size()==0) return;         
            
            S2SExternalSharingSettings__c settings = S2SExternalSharingSettings__c.getInstance(UserInfo.getOrganizationId());
            if (settings==null || !settings.IsActive__c) return;
            
            Map<String, PartnerNetworkConnection> activePartnerConnections = new Map<String, PartnerNetworkConnection>([select Id, ConnectionName from PartnerNetworkConnection where connectionStatus = 'Accepted']);
            if (activePartnerConnections.size()==0) return; //no active connections.
            
            Set<String> validConnectionIds;

            if (settings.ConnectionIds__c!=null){
                validConnectionIds = new Set<String>();
                
                for (String s : settings.ConnectionIds__c.split(',')){
                    
                    if (activePartnerConnections.containsKey(s))                    
                        validConnectionIds.add(s);
                }               
            } else {                
                validConnectionIds = new Set<String>(activePartnerConnections.keySet()); // use all active, as no list defined in the custom setting.
            }
            if (validConnectionIds.size()==0) return;
            
            System.debug(LoggingLevel.ERROR,'>>>FINDME>>validConnectionIds:'+validConnectionIds);
            
            //Note, we could derive the SObjectType via insertedRecs[0].Id.getSObjectType().getDescribe().getName()         
            Set<String> recordTypeIds;
            
            if (sot.equalsIgnoreCase('Account') && !String.isBlank(settings.AccountRecordTypeIds__c)){
                recordTypeIds = new Set<String>(settings.AccountRecordTypeIds__c.split(','));
            } else if (sot.equalsIgnoreCase('Contact') && !String.isBlank(settings.ContactRecordTypeIds__c)){
                recordTypeIds = new Set<String>(settings.ContactRecordTypeIds__c.split(','));
            }
            
            System.debug(LoggingLevel.ERROR,'>>>FINDME>>recordTypeIds:'+recordTypeIds);
            
            
            Set<Id> parentIds = new Set<Id>();
            Map<Id,Set<Id>> parentIdToConnectionIds = new Map<Id,Set<Id>>();            
            Id parentRecId;
            
            for (SObject o : insertedRecs){             
                if (o.get('ConnectionReceivedId')!=null) continue; // don't attempt to re-share records received from another org.              
                if (recordTypeIds!=null && !recordTypeIds.contains((String)o.get('RecordTypeId'))) continue;
                
                parentRecId=null;                                   
                if (parentFieldName!=null && o.get(parentFieldName)!=null){
                    
                    parentRecId=(Id)o.get(parentFieldName);
                    parentIds.add(parentRecId);                                      
                }
            }
            
            if (parentIds.size()>0){
                for (PartnerNetworkRecordConnection pnrc : [select Id, LocalRecordId, ConnectionId 
                                                                from PartnerNetworkRecordConnection 
                                                                where Status='Sent' and LocalRecordId in:parentIds]){
                    
                    if (!parentIdToConnectionIds.containsKey(pnrc.LocalRecordId)) parentIdToConnectionIds.put(pnrc.LocalRecordId, new Set<Id>());
                    
                    parentIdToConnectionIds.get(pnrc.LocalRecordId).add(pnrc.ConnectionId);
                }
            }           
            
            System.debug(LoggingLevel.ERROR,'>>>FINDME>>parentIds:'+parentIds);
            System.debug(LoggingLevel.ERROR,'>>>FINDME>>parentIdToConnectionIds:'+parentIdToConnectionIds);
            
                        
            List<PartnerNetworkRecordConnection> pnrcToInsert = new List<PartnerNetworkRecordConnection>(); 
            
            for (SObject o : insertedRecs){             
                if (o.get('ConnectionReceivedId')!=null) continue; // don't attempt to re-share records received from another org.              
                if (recordTypeIds!=null && !recordTypeIds.contains((String)o.get('RecordTypeId'))) continue;
                
                parentRecId=null;                                   
                if (parentFieldName!=null && o.get(parentFieldName)!=null){
                    
                    parentRecId=(Id)o.get(parentFieldName);
                    
                    System.debug(LoggingLevel.ERROR,'>>>FINDME>>parentRecId:'+parentRecId);
                    
                    if (!parentIdToConnectionIds.containsKey(parentRecId) && isParentMandatory) continue;  // skip record
                }
                
                for (Id validConnectionId : validConnectionIds){
                    
                    if (parentRecId!=null){
                        if (!parentIdToConnectionIds.containsKey(parentRecId) || !parentIdToConnectionIds.get(parentRecId).contains(validConnectionId)){
                            parentRecId=null;
                            if (isParentMandatory) continue; // skip connection
                        }
                    }               
                    //2017-09-06 : SM : Add in the new relatedRecords parameter into the PNRC record
                    pnrcToInsert.add(new PartnerNetworkRecordConnection(    ConnectionId = validConnectionId,
                                                                            LocalRecordId = o.Id,
                                                                            ParentRecordId = parentRecId,
                                                                            SendClosedTasks = false,
                                                                            SendOpenTasks = false,
                                                                            SendEmails = false,
                                                                            RelatedRecords = relatedRecords));
                }
            }
            if (pnrcToInsert.size()>0) insert pnrcToInsert;
                        
        } catch (Exception e){  
            RuntimeExceptionHelper.logExceptionToDebugLog(e.getMessage(),e.getStackTraceString());

            if (null != insertedRecs && isFromTrigger){
                for (SObject o : insertedRecs){
                    o.addError(Label.Apex_Trigger_Error_External_Sharing_Failed);
                }
            }
        }
    }

    //2017-11-17 : SM : This method takes in a list of SObjects, and if the parent record.S2S_Target_Received__c = TRUE then it 
    //2017-11-17 : SM : returns the record for processing
    public static Map<Id, SObject> filterRecords(List<SObject> inRecords, String whichObject, String parentFieldName, String parentObject){
        Map<Id, SObject> returnedRecords = new Map<Id, SObject>();
        Set<Id> parentIds = new Set<Id>();
        for (SObject o : inRecords){
            parentIds.add((Id)o.get(parentFieldName));
        }
        //String query = 'SELECT Id, S2S_Target_Received__c from ' + parentObject + ' WHERE Id in :parentIds';
        String query = 'SELECT Id, LocalRecordId, PartnerRecordId from PartnerNetworkRecordConnection WHERE LocalRecordId in :parentIds';
        List<PartnerNetworkRecordConnection> pnrcRecords = Database.query(query);
        Map<Id, PartnerNetworkRecordConnection> targetMap = new Map<Id, PartnerNetworkRecordConnection>();
        for (PartnerNetworkRecordConnection pnrc : pnrcRecords){
            if (null != pnrc.PartnerRecordId){
                targetMap.put(pnrc.LocalRecordId, pnrc);
            }
        }
        
        for (Sobject o : inRecords){
            Id accId = (Id)o.get(parentFieldName);
            if (Test.isRunningTest()){
                returnedRecords.put(o.Id, o);
            }else {
                if (null != targetMap.get(accId)) returnedRecords.put(o.Id, o);
            }
            
        }

        return returnedRecords;
    }

    //2017-11-17 : SM : Method to schedule the next sharing attempt
    public static Id scheduleSharing(Set<Id> recordIds, String whichObject, String parentFieldName, String relatedObjects){
        S2SExternalSharingSettings__c settings = S2SExternalSharingSettings__c.getInstance(UserInfo.getOrganizationId());
        Integer timeDelay = (settings.Scheduled_Time_Delay__c == null ? DEFAULT_TIME_DELAY : Integer.valueOf(settings.Scheduled_Time_Delay__c));
        DateTime nowPlusTime = System.now().addMinutes(timeDelay);

        String hour = String.valueOf(nowPlusTime.hour());
        String min = String.valueOf(nowPlusTime.minute()); 
        String ss = String.valueOf(nowPlusTime.second());

        //parse to cron expression
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        String jobName = whichObject + ' ' + ss + ' ' + min + ' ' + hour;

        S2SExternalSharingSchedule s2sSchedule = new S2SExternalSharingSchedule(recordIds, whichObject, parentFieldName, relatedObjects);
        
        return System.schedule(jobName, nextFireTime, s2sSchedule);

    }
}