/*
Name:  DataEventTypeTriggerHandler.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Trigger Handler class for the Data Operation Type
based invocation of Data Event Types.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-08-16  Initial development.
1.1  Mark Cane&    2019-08-19  Literal=>Picklist label references added.
1.2  Mark Cane&    2019-08-20  Added changed field tracking.
1.3  Mark Cane&    2019-08-23  Global access modifier changes.
1.4  Mark Cane&    2019-09-11  Transaction Type changes. Only Async Immediate and Async Queue types from ApexTrigger.
1.5  Mark Cane&    2019-10-16  Exclude blank DataOperationType__c (now optional).
1.6  Mark Cane&    2019-10-16  Suppress Update events when update is occuring as the final step of a merge operation.
1.7  Mark Cane&    2019-10-17  Enhancements - Merge events now pass the master record Id and pass source records Ids map to manager. 
1.8  J Radcliffe   2019-10-17  Bug Fixes
1.9  J Radcliffe   2019-10-29  Enabled Delegated Data Events for processing invoked by Trigger Handler
1.10 J Radcliffe   2019-11-04  Bug Fix - 'Includes' operator being treated as 'contains'. Adding support for multiple values. 
1.11 J Radcliffe   2019-11-01  Bug Fix - Null check on Condition Value
1.12 J Radcliffe   2019-11-05  Change to Trigger Handler Logic - OR condition must exclude all 'Required' conditions before checking if at least one of the others are met.
1.13 J Radcliffe   2019-11-26  Bug Fix - Slight change to Condition Logic
1.14 J Radcliffe   2019-11-26  Support for disabling Data Event Triggers from Local Triggers
1.15 Mark Cane&    2020-02-03  Enhancements. Request Body parameter - required for Async Callback Result DET. 
1.16 Mark Cane&    2020-03-23  Enhancements. Merge Data Events now fire on Master Record After Update.
1.17 J Radcliffe   2020-04-27  Bug Fix. Setting recId variable. Previously recId variable is never set for (direct) record deletion before it was added to the map
1.18 J Radcliffe   2020-04-27  Bug Fix. Logic change to allow for Insert/Update Data Events to execute even if they have no conditions 
1.19 J Radcliffe   2020-05-13  Bug Fix. Remove Start and End white space on condition values
1.20 J Radcliffe   2020-05-13  Support 'Excludes' operator for String and Id Data Types
1.21 J Radcliffe   2020-08-18  Add support for 'Delete' Data Event Conditions
1.22 J Radcliffe   2020-09-14  Add support for 'Merge' Data Event Conditions
1.23 Mark Cane&    2020-10-07  Optimisation. Replaced expensive (for trigger context) getPopulatedFieldsAsMap() method call with null check.
1.24 J Radcliffe   2020-03-08  Bug Fixes. Logic alteration to cater for scenario where !allConditions required and yet there are no non-required related conditions
1.25 J Radcliffe   2022-03-14  Enhancement - New condition operators Is Blank and Is Not Blank
*/
global with sharing class DataEventTypeTriggerHandler {

    global static Boolean blockDataEventTriggers = false;//1.14
    
    private String sObjectType;
    private Map<String,String> fieldNameToType;

    @TestVisible private Boolean isExecuting { get; set; }
    @TestVisible private System.TriggerOperation triggerOp { get; set; }
    @TestVisible private Map<Id,SObject> newMap { get; set; }
    @TestVisible private Map<Id,SObject> oldMap { get; set; }

    @TestVisible private Id overrideMasterRecId { get; set; }//1.16+
    
    global Map<String,Map<Id,String>> dataEventTypeToRecordIds;//1.3~ 1.15~
    global Map<Id,Set<String>> recordIdToChangedFields;//1.2+,//1.3~
    global Map<Id,Boolean> recordIdToResult;//1.3+

    // -- static as this collection must span the transaction.
    public static Map<Id,Set<Id>> masterRecordIdToSourceRecordIds { get; set; }//1.6+ 1.7~ -- stash the masterRecordId from the after delete trigger and use to suppress the subsequent update.

    global DataEventTypeTriggerHandler(String sObjectType){
        this.sObjectType = sObjectType;
        this.fieldNameToType = new Map<String,String>();
    }

    global void handleTriggerOperationType(){
        
        if(blockDataEventTriggers) return;//1.14+

        if (Trigger.isExecuting){
            isExecuting = Trigger.isExecuting;
            triggerOp = Trigger.operationType;// System Enum:BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, and AFTER_UNDELETE.§
            newMap = Trigger.newMap;
            oldMap = Trigger.oldMap;
        }
        
        if (!isExecuting || String.isBlank(sObjectType) || !DescribeHelper.globalDescribe.containsKey(sObjectType)) return;       

        try {

            // enumerate active data event types for the sObjectType
            // for each data event type
            //   for each record
            //     evaluate each condition -> if all conditions pass - add data event type and record to map
            // pass populated map to the DataEventTypeManager class.

            dataEventTypeToRecordIds = new Map<String,Map<Id,String>>();//1.15~
            recordIdToChangedFields = new Map<Id,Set<String>>();//1.2+    
            recordIdToResult = new Map<Id,Boolean>();//1.3+

            Boolean hasMasterRecordIdField = DescribeHelper.getObjectFieldMap(sObjectType).containsKey('MasterRecordId');

            Boolean isValidCondition=false, hasInvalidRequiredCondition=false;
            Integer validConditionCount=0;   
            Integer validNotRequiredCount=0;//1.12+
            Id recId,masterRecId;//1.9~
            for (DataEventType__mdt dataEventType : [select Id, AllConditionsRequired__c, DeveloperName, ObjectType__c, DataOperationType__c,
                                                        (select Id, FieldName__c, ConditionValue__c, Operator__c, IsRequired__c 
                                                            from DataEventConditions__r)
                                                    from DataEventType__mdt
                                                    where IsActive__c=true and IsTest__c=:Test.isRunningTest()
                                                        and ObjectType__c=:sObjectType
                                                        and DataOperationType__c!=null
                                                        and (TransactionType__c=:Label.Picklist_Value_Data_Event_Transaction_Type_Asynchronous_Immediate or TransactionType__c=:Label.Picklist_Value_Data_Event_Transaction_Type_Asynchronous_Queue)
                                                    order by DeveloperName asc]){//1.4~ 1.5~ 1.8~ (IsRequired__c)


                if ( (dataEventType.DataOperationType__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Data_Operation_Type_Insert) && triggerOp==System.TriggerOperation.AFTER_INSERT) 
                    || (dataEventType.DataOperationType__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Data_Operation_Type_Update) && (triggerOp==System.TriggerOperation.BEFORE_UPDATE || triggerOp==System.TriggerOperation.AFTER_UPDATE)) ){                    
                
                    for (SObject o : newMap.values()){

                        recId = (Id)o.get('Id');

                        if (dataEventType.DataOperationType__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Data_Operation_Type_Update) && DataEventTypeTriggerHandler.masterRecordIdToSourceRecordIds!=null && DataEventTypeTriggerHandler.masterRecordIdToSourceRecordIds.containsKey(recId)) continue;//1.6+ 1.7~ -- suppress update operations for merge related master record updates.

                        validConditionCount=0;
                        validNotRequiredCount=0;//1.12+
                        hasInvalidRequiredCondition=false;

                        for (DataEventTypeCondition__mdt c : dataEventType.DataEventConditions__r){
                            isValidCondition = evaluateDataEventTypeCondition(c, sObjectType, o, (triggerOp==System.TriggerOperation.AFTER_INSERT) ? null : oldMap.get(recId));
                            if (isValidCondition) validConditionCount++;
                            if (isValidCondition && !c.IsRequired__c) validNotRequiredCount++;//1.12+
                            if (!isValidCondition && dataEventType.AllConditionsRequired__c) break;//All conditions must be valid.

                            if (isValidCondition && c.Operator__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Type_Condition_Operator_IsChanged)){//1.2+

                                if (!recordIdToChangedFields.containsKey(recId)) recordIdToChangedFields.put(recId, new Set<String>()); 
                                recordIdToChangedFields.get(recId).add(c.FieldName__c);
                            }

                            if (!isValidCondition 
                                && !dataEventType.AllConditionsRequired__c
                                && c.IsRequired__c){
                                        
                                hasInvalidRequiredCondition=true;
                                break;//Invalid required condition.
                            }
                        }//condition.

                        if ( (dataEventType.AllConditionsRequired__c && validConditionCount==dataEventType.DataEventConditions__r.size())
                                || (dataEventType.DataEventConditions__r.size()==0)//1.18+
                                //|| (!dataEventType.AllConditionsRequired__c && validNotRequiredCount>=1 && !hasInvalidRequiredCondition)){ //1.12~ (replaced validConditionCount with validNotRequiredCount)//1.24-
                                || (!dataEventType.AllConditionsRequired__c && dataEventType.DataEventConditions__r.size()>0 && (validNotRequiredCount>=1 || validConditionCount==dataEventType.DataEventConditions__r.size()) && !hasInvalidRequiredCondition)){//1.24+
                                if (!dataEventTypeToRecordIds.containsKey(dataEventType.DeveloperName)) dataEventTypeToRecordIds.put(dataEventType.DeveloperName, new Map<Id,String>());//1.15~
                            dataEventTypeToRecordIds.get(dataEventType.DeveloperName).put(recId,null);//1.15~
                        }
                    }//record.

                } else if (dataEventType.DataOperationType__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Data_Operation_Type_Merge) && triggerOp==System.TriggerOperation.AFTER_UPDATE && hasMasterRecordIdField){//1.16+

                    for (SObject o : newMap.values()){//1.16+

                        masterRecId = (Id)o.get('Id');

                        //1.22+
                        validConditionCount=0;
                        validNotRequiredCount=0;
                        hasInvalidRequiredCondition=false;

                        //1.22+
                        for (DataEventTypeCondition__mdt c : dataEventType.DataEventConditions__r){
                            isValidCondition = evaluateDataEventTypeCondition(c, sObjectType, o, null);
                            if (isValidCondition) validConditionCount++;
                            if (isValidCondition && !c.IsRequired__c) validNotRequiredCount++;
                            if (!isValidCondition && dataEventType.AllConditionsRequired__c) break;//All conditions must be valid.
                            if (!isValidCondition 
                                && !dataEventType.AllConditionsRequired__c
                                && c.IsRequired__c){
                                        
                                hasInvalidRequiredCondition=true;
                                break;//Invalid required condition.
                            }
                        }//condition.

                        if ( (dataEventType.AllConditionsRequired__c && validConditionCount==dataEventType.DataEventConditions__r.size())//1.22+
                            || (dataEventType.DataEventConditions__r.size()==0)
                            //|| (!dataEventType.AllConditionsRequired__c && validNotRequiredCount>=1 && !hasInvalidRequiredCondition)){ 1.24-
                            || (!dataEventType.AllConditionsRequired__c && dataEventType.DataEventConditions__r.size()>0 && (validNotRequiredCount>=1 || validConditionCount==dataEventType.DataEventConditions__r.size()) && !hasInvalidRequiredCondition)){//1.24+
                        
                            if (DataEventTypeTriggerHandler.masterRecordIdToSourceRecordIds!=null
                                && DataEventTypeTriggerHandler.masterRecordIdToSourceRecordIds.containsKey(masterRecId)){//1.16+ -- updated record is a master record being updated post-merge.
                                
                                if (!dataEventTypeToRecordIds.containsKey(dataEventType.DeveloperName)) dataEventTypeToRecordIds.put(dataEventType.DeveloperName, new Map<Id,String>());
                                if (!dataEventTypeToRecordIds.get(dataEventType.DeveloperName).containsKey(masterRecId)) dataEventTypeToRecordIds.get(dataEventType.DeveloperName).put(masterRecId,null);
                            }

                        }
                    }

                } else if (dataEventType.DataOperationType__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Data_Operation_Type_Merge) && triggerOp==System.TriggerOperation.AFTER_DELETE && hasMasterRecordIdField){//check for merge.

                    //The following is the order of events when a merge occurs:
                    //  The before delete trigger fires.
                    //  The system deletes the necessary records due to the merge, assigns new parent records to the child records, and sets the MasterRecordId field on the deleted records.
                    //  The after delete trigger fires. <--- the MasterRecordId is only set in the after delete operation - stash to suppress update.
                    //  The system does the specific updates required for the master record. Normal update triggers apply.

                    for (SObject o : oldMap.values()){

                        //Assumption: merge events fire for the master record not the losing records.
                        //Assumption: master record updates within a merge transaction will fire events if no active merge DET exists.
                    
                        //1.23- if ((Test.isRunningTest() && overrideMasterRecId!=null) || o.getPopulatedFieldsAsMap().containsKey('MasterRecordId')){//1.16+
                        if ((Test.isRunningTest() && overrideMasterRecId!=null) || o.get('MasterRecordId')!=null){//1.23+

                            recId = (Id)o.get('Id');
                            masterRecId =  (Test.isRunningTest() && overrideMasterRecId!=null) ? overrideMasterRecId : (Id)o.get('MasterRecordId');//1.7+

                            //1.22+
                            validConditionCount=0;
                            validNotRequiredCount=0;
                            hasInvalidRequiredCondition=false;

                            //1.22+
                            for (DataEventTypeCondition__mdt c : dataEventType.DataEventConditions__r){
                                isValidCondition = evaluateDataEventTypeCondition(c, sObjectType, o, null);
                                //system.debug('condition: '+JSON.serialize(c));
                                //system.debug('isValid:'+isValidCondition);
                                if (isValidCondition) validConditionCount++;
                                if (isValidCondition && !c.IsRequired__c) validNotRequiredCount++;
                                if (!isValidCondition && dataEventType.AllConditionsRequired__c) break;//All conditions must be valid.
                                if (!isValidCondition 
                                    && !dataEventType.AllConditionsRequired__c
                                    && c.IsRequired__c){
                                            
                                    hasInvalidRequiredCondition=true;
                                    break;//Invalid required condition.
                                }
                            }//condition.

                            if ( (dataEventType.AllConditionsRequired__c && validConditionCount==dataEventType.DataEventConditions__r.size())//1.22+
                            || (dataEventType.DataEventConditions__r.size()==0)
                            //|| (!dataEventType.AllConditionsRequired__c && validNotRequiredCount>=1 && !hasInvalidRequiredCondition)){ //1.24-
                            || (!dataEventType.AllConditionsRequired__c && dataEventType.DataEventConditions__r.size()>0 && (validNotRequiredCount>=1 || validConditionCount==dataEventType.DataEventConditions__r.size()) && !hasInvalidRequiredCondition)){//1.24+

                        
                                if (DataEventTypeTriggerHandler.masterRecordIdToSourceRecordIds==null) DataEventTypeTriggerHandler.masterRecordIdToSourceRecordIds = new Map<Id,Set<Id>>();//1.7~
                                if (!DataEventTypeTriggerHandler.masterRecordIdToSourceRecordIds.containsKey(masterRecId)) DataEventTypeTriggerHandler.masterRecordIdToSourceRecordIds.put(masterRecId,new Set<Id>());//1.7~

                                DataEventTypeTriggerHandler.masterRecordIdToSourceRecordIds.get(masterRecId).add(recId);//1.7~

                            }

                            // -- master record is added to the det map
                            //1.16- if (!dataEventTypeToRecordIds.containsKey(dataEventType.DeveloperName)) dataEventTypeToRecordIds.put(dataEventType.DeveloperName, new Map<Id,String>());//1.7~ 1.15~
                            //1.16- if (!dataEventTypeToRecordIds.get(dataEventType.DeveloperName).containsKey(masterRecId)) dataEventTypeToRecordIds.get(dataEventType.DeveloperName).put(masterRecId,null);//1.7~ 1.15~
                        }
                    }
                }
                
                if ((dataEventType.DataOperationType__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Data_Operation_Type_Delete) && triggerOp==System.TriggerOperation.AFTER_DELETE)
                        /*|| (dataEventType.DataOperationType__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Data_Operation_Type_Undelete) && triggerOp==System.TriggerOperation.AFTER_UNDELETE)*/){//1.21~ Removing Undelete - No current use-case and subsequent code does not yet support Undelete (references oldMap not newMap)

                    //Assumption: delete events fire for deletion operations within a merge transaction.

                    for (SObject o : oldMap.values()){

                        recId = (recId == null)?(Id)o.get('Id'):recId;//1.17+

                        //1.21+
                        validConditionCount=0;
                        validNotRequiredCount=0;
                        hasInvalidRequiredCondition=false;

                        //1.21+
                        for (DataEventTypeCondition__mdt c : dataEventType.DataEventConditions__r){
                            isValidCondition = evaluateDataEventTypeCondition(c, sObjectType, o, null);
                            if (isValidCondition) validConditionCount++;
                            if (isValidCondition && !c.IsRequired__c) validNotRequiredCount++;
                            if (!isValidCondition && dataEventType.AllConditionsRequired__c) break;//All conditions must be valid.
                            if (!isValidCondition 
                                && !dataEventType.AllConditionsRequired__c
                                && c.IsRequired__c){
                                        
                                hasInvalidRequiredCondition=true;
                                break;//Invalid required condition.
                            }
                        }//condition.

                        if ( (dataEventType.AllConditionsRequired__c && validConditionCount==dataEventType.DataEventConditions__r.size())//1.21+
                                || (dataEventType.DataEventConditions__r.size()==0)
                                //|| (!dataEventType.AllConditionsRequired__c && validNotRequiredCount>=1 && !hasInvalidRequiredCondition)){ //1.24-
                                || (!dataEventType.AllConditionsRequired__c && dataEventType.DataEventConditions__r.size()>0 && (validNotRequiredCount>=1 || validConditionCount==dataEventType.DataEventConditions__r.size()) && !hasInvalidRequiredCondition)){//1.24+

                        
                            if (!dataEventTypeToRecordIds.containsKey(dataEventType.DeveloperName)) dataEventTypeToRecordIds.put(dataEventType.DeveloperName, new Map<Id,String>());//1.15~
                            dataEventTypeToRecordIds.get(dataEventType.DeveloperName).put(recId,null);//1.15~
                        }
                    }
                }                

            }//dataEventType.

            if (dataEventTypeToRecordIds.isEmpty()) return;

            DataEventTypeManager detm = (DataEventTypeTriggerHandler.masterRecordIdToSourceRecordIds!=null) ? new DataEventTypeManager(DataEventTypeTriggerHandler.masterRecordIdToSourceRecordIds) : new DataEventTypeManager();//1.7~

            recordIdToResult = detm.processDataEventTypes(dataEventTypeToRecordIds,true);//1.3~//1.9~

        } catch(Exception ex){ LogHelper.logExceptions(ex, 'DataEventTypeTriggerHandler', 'handleTriggerOperationType'); }
        return;
    }

    private Boolean evaluateDataEventTypeCondition(DataEventTypeCondition__mdt dataEventTypeCondition, String sObjectType, Sobject n, Sobject o){
        try {

            //system.debug('sObject: '+JSON.serialize(n));

            if (dataEventTypeCondition.Operator__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Type_Condition_Operator_IsChanged)){

                //Assumption: IsChanged events do not fire on insert.

                if (n==null || o==null) return false;

                //1.23- return ( (n.getPopulatedFieldsAsMap().containsKey(dataEventTypeCondition.FieldName__c)!=o.getPopulatedFieldsAsMap().containsKey(dataEventTypeCondition.FieldName__c))
                //1.23-         || (n.get(dataEventTypeCondition.FieldName__c)!=o.get(dataEventTypeCondition.FieldName__c)));
                return ( n.get(dataEventTypeCondition.FieldName__c)!=o.get(dataEventTypeCondition.FieldName__c) );//1.23+
            
            } else {            
                        
                if (!fieldNameToType.containsKey(dataEventTypeCondition.FieldName__c)){
                
                    if (!DescribeHelper.getObjectFieldMap(sObjectType).containsKey(dataEventTypeCondition.FieldName__c)) return false;

                    Schema.DescribeFieldResult fd =  DescribeHelper.getObjectFieldMap(sObjectType).get(dataEventTypeCondition.FieldName__c).getDescribe();

                    if (fd.getType()==Schema.Displaytype.String ||
                        fd.getType()==Schema.Displaytype.PickList || 
                        fd.getType()==Schema.Displaytype.Email ||
                        fd.getType()==Schema.Displaytype.URL ||
                        fd.getType()==Schema.Displaytype.Phone ||
                        fd.getType()==Schema.Displaytype.TextArea){                        
                        
                        fieldNameToType.put(dataEventTypeCondition.FieldName__c, 'String');            
                    } else if (fd.getType()==Schema.Displaytype.Currency ||
                                fd.getType()==Schema.Displaytype.Double ||
                                fd.getType()==Schema.Displaytype.Integer ||
                                fd.getType()==Schema.Displaytype.Percent){                                            
                        
                        fieldNameToType.put(dataEventTypeCondition.FieldName__c, 'Number');
                    } else if (fd.getType()==Schema.Displaytype.Boolean){                
                        
                        fieldNameToType.put(dataEventTypeCondition.FieldName__c, 'Boolean');                
                    } else if (fd.getType()==Schema.Displaytype.Reference){
                        
                        fieldNameToType.put(dataEventTypeCondition.FieldName__c, 'Id');                                         
                    } else if (fd.getType()==Schema.Displaytype.MultiPicklist){             
                        
                        fieldNameToType.put(dataEventTypeCondition.FieldName__c, 'MultiPicklist');      
                    }
                }
            }
            if (!fieldNameToType.containsKey(dataEventTypeCondition.FieldName__c)) return false;

            //1.25+
            if(dataEventTypeCondition.Operator__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Type_Condition_Operator_Is_Blank)){
                return (n.get(dataEventTypeCondition.FieldName__c)==null)?true:false; 
            }else if(dataEventTypeCondition.Operator__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Type_Condition_Operator_Is_Not_Blank)){
                return (n.get(dataEventTypeCondition.FieldName__c)==null)?false:true; 
            }
            
            switch on fieldNameToType.get(dataEventTypeCondition.FieldName__c) {
                when 'String','Id' {

                    //1.23- String actualValue = n.getPopulatedFieldsAsMap().containsKey(dataEventTypeCondition.FieldName__c) ? String.valueOf(n.get(dataEventTypeCondition.FieldName__c)) : null;
                    String actualValue = n.get(dataEventTypeCondition.FieldName__c)!=null ? String.valueOf(n.get(dataEventTypeCondition.FieldName__c)) : null;//1.23+

                    if (dataEventTypeCondition.Operator__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Type_Condition_Operator_Equals)){

                        if (String.isNotBlank(actualValue) && actualValue.equalsIgnoreCase(dataEventTypeCondition.ConditionValue__c)) return true;

                    } else if (dataEventTypeCondition.Operator__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Type_Condition_Operator_Does_Not_Equal)){
                        if(String.isBlank(actualValue) && String.isBlank(dataEventTypeCondition.ConditionValue__c)) return false;//1.13+
                        if (String.isBlank(actualValue) || !actualValue.equalsIgnoreCase(dataEventTypeCondition.ConditionValue__c)) return true;

                    } else if (dataEventTypeCondition.Operator__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Type_Condition_Operator_Includes)){

                        //if (String.isNotBlank(actualValue) && actualValue.containsIgnoreCase(dataEventTypeCondition.ConditionValue__c)) return true;//1.10-
                        if (String.isNotBlank(actualValue)){//1.10+
                            if(dataEventTypeCondition.ConditionValue__c != null && dataEventTypeCondition.ConditionValue__c.contains(',')){
                                for(String cv : dataEventTypeCondition.ConditionValue__c.split(',')){
                                    cv = removeStartAndEndWhiteSpace(cv);//1.19+
                                    if(actualValue.containsIgnoreCase(cv)) return true;
                                }
                            }else{
                                if(actualValue.containsIgnoreCase(removeStartAndEndWhiteSpace(dataEventTypeCondition.ConditionValue__c))) return true;//1.19~
                            }
                        } 
                    } else if (dataEventTypeCondition.Operator__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Type_Condition_Operator_Excludes)){//1.20+

                        if (String.isNotBlank(actualValue)){
                            if(dataEventTypeCondition.ConditionValue__c != null && dataEventTypeCondition.ConditionValue__c.contains(',')){
                                for(String cv : dataEventTypeCondition.ConditionValue__c.split(',')){
                                    cv = removeStartAndEndWhiteSpace(cv);
                                    if(actualValue.containsIgnoreCase(cv)) return false;
                                }
                                return true;
                            }else{
                                return (actualValue.containsIgnoreCase(removeStartAndEndWhiteSpace(dataEventTypeCondition.ConditionValue__c)))?false:true;
                            }
                        } 
                    }
                }
                when 'Multi-Picklist' {

                    //1.23- List<String> actualValues = n.getPopulatedFieldsAsMap().containsKey(dataEventTypeCondition.FieldName__c) ? ((String)n.get(dataEventTypeCondition.FieldName__c)).split(';') : null;
                    List<String> actualValues = n.get(dataEventTypeCondition.FieldName__c)!=null ? ((String)n.get(dataEventTypeCondition.FieldName__c)).split(';') : null;//1.23+

                    if (dataEventTypeCondition.Operator__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Type_Condition_Operator_Includes)){ 
                        if (actualValues!=null && actualValues.contains(dataEventTypeCondition.ConditionValue__c)) return true;
                    } else if (dataEventTypeCondition.Operator__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Type_Condition_Operator_Excludes)){ 
                        if (actualValues==null || !actualValues.contains(dataEventTypeCondition.ConditionValue__c)) return true;
                    }

                }
                when 'Boolean' {

                    //1.23- Boolean actualValue = n.getPopulatedFieldsAsMap().containsKey(dataEventTypeCondition.FieldName__c) ? (Boolean)n.get(dataEventTypeCondition.FieldName__c) : false;
                    Boolean actualValue = n.get(dataEventTypeCondition.FieldName__c)!=null ? (Boolean)n.get(dataEventTypeCondition.FieldName__c) : false;//1.23+
                
                    if (dataEventTypeCondition.Operator__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Type_Condition_Operator_Equals)){

                        if (actualValue && dataEventTypeCondition.ConditionValue__c.equalsIgnoreCase('true')) return true;

                        if (!actualValue && dataEventTypeCondition.ConditionValue__c.equalsIgnoreCase('false')) return true;                    
                    }
                } 
                when 'Number' {

                    //1.23- Decimal actualValue = n.getPopulatedFieldsAsMap().containsKey(dataEventTypeCondition.FieldName__c) ? (Decimal)n.get(dataEventTypeCondition.FieldName__c) : null;
                    Decimal actualValue = n.get(dataEventTypeCondition.FieldName__c)!=null ? (Decimal)n.get(dataEventTypeCondition.FieldName__c) : null;//1.23+

                    Decimal conditionValue = (dataEventTypeCondition.ConditionValue__c != null)? Decimal.valueOf(dataEventTypeCondition.ConditionValue__c):null;//1.11~

                    if (dataEventTypeCondition.Operator__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Type_Condition_Operator_Equals)){

                        if (actualValue!=null && actualValue==conditionValue) return true;

                    } else if (dataEventTypeCondition.Operator__c.equalsIgnoreCase(Label.Picklist_Value_Data_Event_Type_Condition_Operator_Does_Not_Equal)){
                        if (actualValue == null && conditionValue == null) return false;//1.13+
                        if (actualValue==null || actualValue<>conditionValue) return true;

                    }
                }
            }
        } catch(Exception ex){ }
        return false;                        
    }    

    //1.19+
    public static String removeStartAndEndWhiteSpace(String value){

        if(value == null || String.isBlank(value)) return value;

        while (value.startsWith(' ')) {
            value = value.removeStart(' ');
        }
        while (value.endsWith(' ')) {
            value = value.removeEnd(' ');
        }
        return value;
    }
}