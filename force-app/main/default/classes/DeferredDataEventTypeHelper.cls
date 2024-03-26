/*
Name:  DeferredDataEventTypeHelper.cls
Copyright © 2022  Golfbreaks
======================================================
======================================================
Purpose:
-------

Helper methods for Deferred Data Events.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2022-06-27  Initial development.
1.1  Mark Cane&    2022-11-30  Bug fixes. Based on configured schedule, the given trigger 'SCHEDULED_APEX_JOB_TYPE.000000000000000' will never fire.
*/
public with sharing class DeferredDataEventTypeHelper {

    @testVisible private static String parentFieldNameOverride { get; set; }

    public static Boolean createDeferredRequests(DataEventType__mdt dataEventType, Set<Id> recordIds){
        try {

            Map<Id,Id> idToParentId = new Map<Id,Id>();

            String parentFieldName;
            if (parentFieldNameOverride!=null) parentFieldName = parentFieldNameOverride;
            else if (dataEventType.DeferredParentFieldName__c!=null) parentFieldName = dataEventType.DeferredParentFieldName__c;

            if (String.isNotBlank(parentFieldName)        
                && DescribeHelper.globalDescribe.containsKey(dataEventType.ObjectType__c)
                && DescribeHelper.getObjectFieldMap(dataEventType.ObjectType__c).containsKey(parentFieldName)
                && DescribeHelper.getObjectFieldMap(dataEventType.ObjectType__c).get(parentFieldName).getDescribe().getType()==Schema.Displaytype.Reference){
                
                Set<Id> ids = recordIds;

                String q = 'select Id';
                q+=','+String.escapeSingleQuotes(parentFieldName);
                q+=' from '+String.escapeSingleQuotes(dataEventType.ObjectType__c);
                q+=' where Id in:ids';
                q+=' and '+String.escapeSingleQuotes(parentFieldName)+'<>null';

                for (Sobject o : Database.query(q)){
                    idToParentId.put((Id)o.get('Id'),(Id)o.get(parentFieldName));
                }
            }

            Set<Id> deferredRecordIds = new Set<Id>();
            Datetime deferredToTime = Datetime.now().addSeconds( dataEventType.DeferredTimeOffset__c==null || dataEventType.DeferredTimeOffset__c==0 ? 60 : (Integer)dataEventType.DeferredTimeOffset__c );

            for (Id recordId : recordIds){ deferredRecordIds.add( idToParentId.containsKey(recordId) ? idToParentId.get(recordId) : recordId ); }

            Set<Id> recordIdsToSkip = new Set<Id>();
            List<DataEventRequest__c> derToInsert = new List<DataEventRequest__c>();
            List<DataEventRequest__c> derToUpdate = new List<DataEventRequest__c>();

            for (DataEventRequest__c der : [select Id, RecordId__c from DataEventRequest__c where RecordId__c in:deferredRecordIds and Status__c='New' and DataEventType__c=:dataEventType.DeveloperName]){
                der.CalloutDate__c = deferredToTime;
                derToUpdate.add(der);

                recordIdsToSkip.add(der.RecordId__c);
            }

            for (Id recordId : deferredRecordIds){
                if (recordIdsToSkip.contains(recordId)) continue;
                derToInsert.add( new DataEventRequest__c(RecordId__c=recordId,Status__c='New',CalloutDate__c=deferredToTime,DataEventType__c=dataEventType.DeveloperName) );
            }

            if (!derToUpdate.isEmpty()) Database.update(derToUpdate,false);            
            if (!derToInsert.isEmpty()) Database.insert(derToInsert,false);

            return true;

        } catch(Exception ex){ LogHelper.logExceptions(ex, 'DeferredDataEventTypeHelper', 'createRequests'); }
        return false;
    }

    public static Id rescheduleCron(String dataEventTypeName, Datetime nextCalloutDt){
        Id cronId;
        
        try {
            Boolean isReschedule=false;

            String q = 'select count() from CronTrigger where State not in (\'COMPLETE\',\'ERROR\',\'DELETED\') and CronJobDetail.Name like \''+dataEventTypeName+' Deferred%\'';
            Integer activeCronCount = Database.countQuery(q);

            q = 'select Id, NextFireTime from CronTrigger where State not in (\'COMPLETE\',\'ERROR\',\'DELETED\') and CronJobDetail.Name like \''+dataEventTypeName+' Deferred%\'';
            for (CronTrigger ct : Database.query(q)){
                if (ct.NextFireTime>nextCalloutDt || activeCronCount>1){
                    System.abortJob(ct.Id);
                    isReschedule = true;
                }
            }
            if (activeCronCount==0 || isReschedule){//1.1~

                if (nextCalloutDt<=Datetime.now().addSeconds(10)) nextCalloutDt = Datetime.now().addSeconds(10);

                cronId = System.schedule(dataEventTypeName+' Deferred ['+nextCalloutDt.format('ddMMyyyy-HHmmss')+']', nextCalloutDt.format('ss mm HH dd M ? yyyy'), new DataEventRequestSchedulable(dataEventTypeName));
            }
        
        } catch(exception e){ LogHelper.logExceptions(e, 'DataEventRequestTriggerHandler', 'rescheduleCron'); }
        return cronId;
    }
}