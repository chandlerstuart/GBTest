/*
Class:  WorkItemWIREActionIdentifier.cls
Copyright © 2018  Golfbreaks
======================================================
======================================================
Purpose:
-------
This class will be used to determine which trigger records 
(if any) require an action and which actions are required 
following a dml action

======================================================
======================================================
Revision History
---------------- 
Ver. Author          Date        Detail
1.0  James Radcliffe 2018-10-29  Initial development.
1.1  James Radcliffe 2018-11-12  New Routing Config Setting - Building in support for (optionally) routing Leads/Cases via Active Assignment Rules
1.2  Mark Cane       2018-11-14  Bug fixes. Null dereference exceptions.
1.3  James Radcliffe 2018-12-10  Bug fix. Exclude Leads duped on insert from routing to Omni Queues
1.4  James Radcliffe 2018-12-13  isPreferredQueueCalcRequired - Calculate Preferred Queue if WI re-opened
1.5  James Radcliffe 2018-12-13  isDirectAssignmentRequired - Bug Fix. Auto Assign Lead via WIRE triggers if Sales Region newly populated (assumed via Workflow)
1.6  James Radcliffe 2018-02-26  Indirect Routing Solution - If the work item owner matches the GBWire__UnassignedWorkItemOwnerId__c, treat as though the record is assigned to a queue
1.7  Mark Cane       2019-04-08  processWorkItems - dependent actions.
1.8  James Radcliffe 2019-07-11  New method processWorkItemsQueueable
1.9  James Radcliffe 2019-11-26  Adding support for blocking data event triggers during WIRE Trigger Activity
1.10 James Radcliffe 2020-04-30  Recursion flags prevents WIRE actions running multiple times. If the preferred queue requires changing and the client is specified, it is safe to assume that a CRP recalculation is also required (to set the correct queue)
1.11 James Radcliffe 2020-01-20  Exclude test records from all WIRE activity (test records are assigned to static queue(s) via PB/Flow automation)
1.12 Mark Cane&      2024-02-16  Enhancements. Added executeWIRETriggerActionsFuture to enable future path where parent transaction is Queueable.
1.13 Mark Cane&      2024-02-28  Bug fixes 1.12 -- managed packaged class is not serializable outside of the namespace.
*/
public class WorkItemWIREActionIdentifier {
    
    public static Boolean requiresCapacityCalcForPreviousOwner = false;
    public static Boolean requiresCRPCalcForPreviousClient = false;
    @TestVisible static Boolean isTestInsert = false;
    @TestVisible static Boolean isTestUpdate = false;
    public static Map<String,Set<String>> objectTypeWithPrefQueueCalcFieldsMap;
    public static Boolean isWIRECodeBlocked = false; //<--Referenced in trigger handlers to prevent recursion
    public static GBWire__RoutingEngineSettings__c res; //1.6
    
    
    
    
    //This method will evaluate the accepted trigger records (referencing the trigger context, changes to the records and the routing configuration) to determine which WIRE actions (if any) are required. 
    //We can apply any necessary logic to determine which actions should be performed and set the action variables accordingly. 
    //Logic is trigger context dependent and so this method should only be invoked from object triggers (After Context).
    //This method returns a Map of the trigger record Id and a corresponding WorkItemWithActionsWrapper (check list of required actions)
    public static Map<Id,GBWire.WorkItemWithActionsWrapper> processWorkItems(Map<Id,sObject> oldMap, Map<Id,sObject> newMap, String workItemType){

        system.debug('workItemType: '+workItemType);
        system.debug('Trigger.isUpdate: '+Trigger.isUpdate);
        system.debug('Trigger.isInsert: '+Trigger.isInsert);
        system.debug('oldMap: '+oldMap);
        system.debug('newMap: '+newMap);

        //Exit if WIRE trigger actions have been disabled
        GBWire__WorkItemRoutingSettings__c wirs = GBWire__WorkItemRoutingSettings__c.getOrgDefaults();
        if(wirs.GBWire__DisableWireTriggerActions__c) return null;
        //Store settings in static variable
        if(res == null) res = GBWire__RoutingEngineSettings__c.getOrgDefaults();
        
        //Verify parameters have been provided        
        if (String.isBlank(workItemType)) return null;
        
        if(!isTestInsert && (isTestUpdate || Trigger.isUpdate) && (oldMap == null || newMap == null)) return null;
        if(!isTestUpdate && (isTestInsert || Trigger.isInsert) && newMap == null) return null;
        
        system.debug('WorkItemWIREActionIdentifier>processWorkItems>Start');
        GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>Start');
        
        system.debug('WorkItemWIREActionIdentifier>processWorkItems>NewMap>'+newMap);
        GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>NewMap>'+newMap);
        
        system.debug('WorkItemWIREActionIdentifier>processWorkItems>OldMap>'+oldMap);
        GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>OldMap>'+oldMap);
        
        system.debug('WorkItemWIREActionIdentifier>processWorkItems>WorkItemType>'+workItemType);
        GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>WorkItemType>'+workItemType);
        
        if(!isTestUpdate && (isTestInsert || trigger.isInsert)){
            system.debug('WorkItemWIREActionIdentifier>processWorkItems>TriggerContext>IsInsertTrigger');
            GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>TriggerContext>IsInsertTrigger');
        }
        if(!isTestInsert && (isTestUpdate || trigger.isUpdate)){
            system.debug('WorkItemWIREActionIdentifier>processWorkItems>TriggerContext>IsUpdateTrigger');
            GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>TriggerContext>IsUpdateTrigger');
        }
        
        //Creating Map
        Map<Id,GBWire.WorkItemWithActionsWrapper> recordIdsWithRequiredActions = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
        
        system.debug('WorkItemWIREActionIdentifier>processWorkItems>RetrievingRoutingConfiguration');
        GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>RetrievingRoutingConfiguration');
        
        //Retrieve routing configuration using the workItemType
        GBWire__RoutingConfiguration__mdt config;
        if(GBWire.RoutingConfigurationHelper.nameToRoutingConfig != null){
            if(GBWire.RoutingConfigurationHelper.nameToRoutingConfig.keySet().contains(workItemType)
               && GBWire.RoutingConfigurationHelper.nameToRoutingConfig.get(workItemType) != null){
                   config = GBWire.RoutingConfigurationHelper.nameToRoutingConfig.get(workItemType);
               }else{
                   config = GBWire.RoutingConfigurationHelper.getValidRoutingConfigurations(workItemType).Values()[0];
               }
        }else{
            try{
                config = GBWIRE.RoutingConfigurationHelper.getValidRoutingConfigurations(workItemType).Values()[0];
            }catch(exception e){
                system.debug('WorkItemWIREActionIdentifier>processWorkItems>RetrievingRoutingConfiguration>ERROR>'+workItemType+'>'+e);
                GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>RetrievingRoutingConfiguration>ERROR>'+workItemType+'>'+e);
                
            }
        }
        
        system.debug('WorkItemWIREActionIdentifier>processWorkItems>RetrievingRoutingConfiguration>'+config);
        GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>RetrievingRoutingConfiguration>'+config);
        
        system.debug('WorkItemWIREActionIdentifier>processWorkItems>RetrievingWIREPreferredQueueCalcFields__mdt');
        GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>RetrievingWIREPreferredQueueCalcFields__mdt');
        
        Set<String> preferredQueueFieldChangeNames = new Set<String>();
        
        if(objectTypeWithPrefQueueCalcFieldsMap == null){
            objectTypeWithPrefQueueCalcFieldsMap = new Map<String,Set<String>>();
        }
        
        if(objectTypeWithPrefQueueCalcFieldsMap != null && !objectTypeWithPrefQueueCalcFieldsMap.containsKey(config.GBWire__SObjectType__c)){
            WIREPreferredQueueCalcFields__mdt[] fieldSettings = [Select Id, ObjectAPIName__c, ObjectType__c, ObjectField__c From WIREPreferredQueueCalcFields__mdt Where ObjectAPIName__c = :config.GBWire__SObjectType__c ];
            
            if(fieldSettings != null && fieldSettings.size()>0){
                //Collate durable Ids from metadata settings
                List<String> durableIds = new List<String>();
                for(WIREPreferredQueueCalcFields__mdt fs : fieldSettings){
                    if(!durableIds.contains(fs.ObjectField__c)){
                        durableIds.add(fs.ObjectField__c);
                    }                              
                }
                //Query and collate object field api names from Entity Particle
                EntityParticle[] eps = [Select DurableId, QualifiedApiName From EntityParticle Where DurableId In:DurableIds];
                for(EntityParticle ep : eps){
                    if(preferredQueueFieldChangeNames != null && !preferredQueueFieldChangeNames.contains(ep.QualifiedApiName)){
                        preferredQueueFieldChangeNames.add(ep.QualifiedApiName);
                    }           
                }
            }
            objectTypeWithPrefQueueCalcFieldsMap.put(config.GBWire__SObjectType__c,preferredQueueFieldChangeNames);
        }else{
            preferredQueueFieldChangeNames = objectTypeWithPrefQueueCalcFieldsMap.get(config.GBWire__SObjectType__c);
        }
        
        system.debug('WorkItemWIREActionIdentifier>processWorkItems>RetrievingWIREPreferredQueueCalcFields__mdt>'+preferredQueueFieldChangeNames);
        GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>RetrievingWIREPreferredQueueCalcFields__mdt>'+preferredQueueFieldChangeNames);
        
        system.debug('WorkItemWIREActionIdentifier>processWorkItems>EvaluatingTriggerRecords');
        GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>EvaluatingTriggerRecords');
        
        //Counters
        Integer crpCount = 0;
        Integer capCount = 0;
        Integer paCount = 0;
        Integer pqCount = 0;
        Integer assignCount = 0;
        
        Set<Id> recordsToRouteWithActiveRules = new Set<Id>();//<--1.1
        
        //Loop through trigger records
        for(sObject newRecord : newMap.values()){
            //Continue to next record if the record has invalid record type
            if(config != null && config.GBWire__ExcludedRecordTypes__c != null && (String)newRecord.get('RecordTypeId') != null && config.GBWire__ExcludedRecordTypes__c.contains((String)newRecord.get('RecordTypeId'))){
                if(!isTestUpdate && (isTestInsert || Trigger.isInsert) && config != null && config.GBWire__RTsToAssignWithActiveAssignmentRules2__c != null && (String)newRecord.get('RecordTypeId') != null && config.GBWire__RTsToAssignWithActiveAssignmentRules2__c.contains((String)newRecord.get('RecordTypeId'))){//<--1.1
                    recordsToRouteWithActiveRules.add(newRecord.Id);//<--1.1
                }
                continue;
            }

            //1.11+ Exclude test records from all WIRE activity (test records are assigned to static queue(s) via PB/Flow automation)
            if(config != null && (config.GBWire__SObjectType__c == ApplicationConstant.LEAD_SOBJECTTYPE || config.GBWire__SObjectType__c == ApplicationConstant.CASE_SOBJECTTYPE || config.GBWire__SObjectType__c == ApplicationConstant.OBJECT_TYPE_OPPORTUNITY) && (Boolean)newRecord.get('IsTest__c')) continue;

            //Retrieve old record
            sObject oldRecord = (oldMap != null)? oldMap.get(newRecord.Id):null;//1.9 (uncomment)
            
            //Create Wrapper
            GBWire.WorkItemWithActionsWrapper wrapper = new GBWire.WorkItemWithActionsWrapper();
            
            //Evaluate suitability for each action and assign to Wrapper variables
            wrapper.doAssign = isDirectAssignmentRequired(oldRecord,newRecord,config);
            if (wrapper.doAssign){//1.7+
                wrapper.doPreferredAgentCalc = true;
                wrapper.doAgentCapacityCalc = true;
            } else {
                wrapper.doPreferredAgentCalc = isPreferredAgentCalcRequired(oldRecord,newRecord,config);
                wrapper.doAgentCapacityCalc = isOwnerCapacityCalcRequired(oldRecord,newRecord,config);
            }
            //wrapper.doCRPCalc = isClientRoutingProfileCalcRequired(oldRecord,newRecord,config);//1.10-
            wrapper.doPreferredQueueCalc = isPreferredQueueCalcRequired(oldRecord,newRecord,config,preferredQueueFieldChangeNames);
            wrapper.doCRPCalc = isClientRoutingProfileCalcRequired(oldRecord,newRecord,config,wrapper.doPreferredQueueCalc);//1.10+

            //Increment count for debugging
            if(wrapper.doPreferredAgentCalc)paCount++;
            if(wrapper.doAgentCapacityCalc)capCount++;
            if(wrapper.doAssign)assignCount++;
            if(wrapper.doCRPCalc)crpCount++;
            if(wrapper.doPreferredQueueCalc)pqCount++;
            
            //If capacity recalc for the previous owner is required, assign the 'PreviousOwnerId' wrapper variable
            if(requiresCapacityCalcForPreviousOwner){
                wrapper.previousOwnerId = (Id)oldRecord.get(config.GBWire__OwnerFieldName__c);
            }
            
            //Reset the static flag
            requiresCapacityCalcForPreviousOwner = false;
            
            //If CRP recalculation for the previous client is required, assign the 'PreviousClientId' wrapper variable
            if(requiresCRPCalcForPreviousClient){
                wrapper.previousClientId = (Id)oldRecord.get(config.GBWire__ClientFieldName__c);
            }
            
            //Reset the static flag
            requiresCRPCalcForPreviousClient = false;
            
            //Continue if no actions are required
            if(!wrapper.doAssign && !wrapper.doPreferredQueueCalc && !wrapper.doCRPCalc && !wrapper.doAgentCapacityCalc && !wrapper.doPreferredAgentCalc) continue;
            
            //If actions are required, add record to map
            recordIdsWithRequiredActions.put(newRecord.Id,wrapper);
            
        }
        
        system.debug('WorkItemWIREActionIdentifier>processWorkItems>RecordsRequiringWIREActions>'+recordIdsWithRequiredActions.values().size());
        GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>RecordsRequiringWIREActions>'+recordIdsWithRequiredActions.values().size());
        
        if(recordIdsWithRequiredActions.values().size()>0){
            system.debug('WorkItemWIREActionIdentifier>processWorkItems>RecordsRequiringPreferredAgentCalculation>'+paCount);
            GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>RecordsRequiringPreferredAgentCalculation>'+paCount);
            system.debug('WorkItemWIREActionIdentifier>processWorkItems>RecordsRequiringCapacityCalculation>'+capCount);
            GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>RecordsRequiringCapacityCalculation>'+capCount);
            system.debug('WorkItemWIREActionIdentifier>processWorkItems>RecordsRequiringClientRoutingProfileCalculation>'+crpCount);
            GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>RecordsRequiringClientRoutingProfileCalculation>'+crpCount);
            system.debug('WorkItemWIREActionIdentifier>processWorkItems>RecordsRequiringPreferredQueueCalculation>'+pqCount);
            GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>RecordsRequiringPreferredQueueCalculation>'+pqCount);
            system.debug('WorkItemWIREActionIdentifier>processWorkItems>RecordsRequiringAssignment>'+assignCount);
            GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>RecordsRequiringAssignment>'+assignCount);
        }
        
        if(recordsToRouteWithActiveRules.size()>0){//<--1.1
            system.debug('WorkItemWIREActionIdentifier>processWorkItems>RecordsRequiringAssignmentViaActiveAssignmentRules>'+recordsToRouteWithActiveRules.size());
            GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>RecordsRequiringAssignmentViaActiveAssignmentRules>'+recordsToRouteWithActiveRules.size());
            routeWorkItemsWithActiveRules(recordsToRouteWithActiveRules,config);
        }
        
        //Return Map
        system.debug('WorkItemWIREActionIdentifier>processWorkItems>ReturningMap');
        GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>ReturningMap');
        system.debug('WorkItemWIREActionIdentifier>processWorkItems>Stop');
        GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>Stop');
        GBWire.RoutingLogHelper.commitLog();
        return recordIdsWithRequiredActions;
        
    }
    
    //This method returns true if the record requires a recalulation of it's related Preferred Agent records
    public static boolean isPreferredAgentCalcRequired(sObject oldRecord, sObject newRecord,GBWire__RoutingConfiguration__mdt config){
        
        //If config is incomplete return false
        if(config == null || config.GBWire__IsOpenFieldName__c == null || config.GBWire__ClientFieldName__c == null 
           || config.GBWire__OwnerFieldName__c == null || config.GBWire__PreferredAgentWorkItemLookupField__c == null) return false;
        
        /**Insert Trigger Context***/
        
        if(!isTestUpdate && (isTestInsert || trigger.isInsert)){
            if(newRecord != null && newRecord.get(config.GBWire__ClientFieldName__c) != null){
                //If record is inserted, open, has an associated client and the current owner is a user, return true
                String currentOwnerId = (String)newRecord.get(config.GBWire__OwnerFieldName__c);
                if((Boolean)newRecord.get(config.GBWire__IsOpenFieldName__c) && currentOwnerId.startsWithIgnoreCase('005') /*1.6*/ && (res.GBWire__UnassignedWorkItemOwnerId__c == null || currentOwnerId !=  res.GBWire__UnassignedWorkItemOwnerId__c) /*1.6*/) return true;
            }
        }
        
        /**Update Trigger Context***/
        
        if(!isTestInsert && (isTestUpdate || trigger.isUpdate)){
            if(newRecord != null && oldRecord != null){
                //If record is updated, open and has changed from user to user, queue to user or user to queue, return true
                String currentOwnerId = (String)newRecord.get(config.GBWire__OwnerFieldName__c);
                String previousOwnerId = (String)oldRecord.get(config.GBWire__OwnerFieldName__c);           
                if((Boolean)newRecord.get(config.GBWire__IsOpenFieldName__c) && currentOwnerId != previousOwnerId 
                   && ((currentOwnerId.startsWithIgnoreCase('005') /*1.6*/ && (res.GBWire__UnassignedWorkItemOwnerId__c == null || currentOwnerId != res.GBWire__UnassignedWorkItemOwnerId__c)) /*1.6*/ 
                       || (previousOwnerId.startsWithIgnoreCase('005') /*1.6*/ && ( res.GBWire__UnassignedWorkItemOwnerId__c == null || previousOwnerId != res.GBWire__UnassignedWorkItemOwnerId__c)/*1.6*/)) 
                   && newRecord.get(config.GBWire__ClientFieldName__c) != null
                  ) return true; 
                
                //If record is updated and open status has changed (closed or re-opened), return true
                if((Boolean)newRecord.get(config.GBWire__IsOpenFieldName__c) != (Boolean)oldRecord.get(config.GBWire__IsOpenFieldName__c) && newRecord.get(config.GBWire__ClientFieldName__c) != null) return true;
                
                //If record is updated and the Client has changed, return true
                if((Id)newRecord.get(config.GBWire__ClientFieldName__c) != (Id)oldRecord.get(config.GBWire__ClientFieldName__c))return true;
                
            }
        }
        
        //TO DO - Evaluate on Delete/Undelete
        
        return false;     
        
    }
    
    //This method returns true if the record owner's capacity requires a recalulation (Agent Profile)
    public static boolean isOwnerCapacityCalcRequired(sObject oldRecord, sObject newRecord,GBWire__RoutingConfiguration__mdt config){
        
        //If config is incomplete return false
        if(config == null || config.GBWire__IsOpenFieldName__c == null || config.GBWire__OwnerFieldName__c == null
           || config.GBWire__IsActiveFieldName__c == null || config.GBWire__IsNewFieldName__c == null) return false;
        
        
        /**Insert Trigger Context***/
        
        if(!isTestUpdate && (isTestInsert || trigger.isInsert)){
            if(newRecord != null){
                //If record is inserted, open and the current owner is a user, return true
                String currentOwnerId = (String)newRecord.get(config.GBWire__OwnerFieldName__c);
                if(newRecord != null && 
                   String.isNotBlank(config.GBWire__IsOpenFieldName__c) &&
                   newRecord.get(config.GBWire__IsOpenFieldName__c) != null &&
                   (Boolean)newRecord.get(config.GBWire__IsOpenFieldName__c) && 
                   currentOwnerId != null && 
                   currentOwnerId.startsWithIgnoreCase('005')
                  	/*1.6*/ && (res.GBWire__UnassignedWorkItemOwnerId__c == null || currentOwnerId != res.GBWire__UnassignedWorkItemOwnerId__c)
                  ) return true;//1.2
            }
        }
        
        /**Update Trigger Context***/
        
        if(!isTestInsert && (isTestUpdate || trigger.isUpdate)){
            if(newRecord != null && oldRecord != null){
                //If record is updated, open and has changed from user to user, queue to user or user to queue, return true
                String currentOwnerId = (String)newRecord.get(config.GBWire__OwnerFieldName__c);
                String previousOwnerId = (String)oldRecord.get(config.GBWire__OwnerFieldName__c);
                if((Boolean)newRecord.get(config.GBWire__IsOpenFieldName__c) && currentOwnerId != previousOwnerId){
                    //Reassigned to user - Return true
                    if(currentOwnerId != null && previousOwnerId != null && currentOwnerId.startsWithIgnoreCase('005') 
                       /*1.6*/ && (res.GBWire__UnassignedWorkItemOwnerId__c == null || currentOwnerId != res.GBWire__UnassignedWorkItemOwnerId__c) /*1.6*/ 
                       && (!previousOwnerId.startsWithIgnoreCase('005') /*1.6*/ || (res.GBWire__UnassignedWorkItemOwnerId__c != null && previousOwnerId == res.GBWire__UnassignedWorkItemOwnerId__c)) /*1.6*/){
                        return true;
                    }
                    //If previous owner was a user, set the 'requiresCapacityCalcForPreviousOwner' flag and return true
                    if(previousOwnerId != null && previousOwnerId.startsWithIgnoreCase('005') && (res.GBWire__UnassignedWorkItemOwnerId__c == null || previousOwnerId != res.GBWire__UnassignedWorkItemOwnerId__c)){
                        requiresCapacityCalcForPreviousOwner = true;
                        return true;
                    }
                } 
                
                //If record is updated and open, new, active status has changed, return true
                if(newRecord != null && (Boolean)newRecord.get(config.GBWire__IsOpenFieldName__c) != (Boolean)oldRecord.get(config.GBWire__IsOpenFieldName__c)
                   ||(Boolean)newRecord.get(config.GBWire__IsActiveFieldName__c) != (Boolean)oldRecord.get(config.GBWire__IsActiveFieldName__c)
                   ||(Boolean)newRecord.get(config.GBWire__IsNewFieldName__c) != (Boolean)oldRecord.get(config.GBWire__IsNewFieldName__c)) return true;
                
            } 
        }
        
        //TO DO - Evaluate on Delete/Undelete
        
        return false;     
        
    }
    
    //This method returns true if the record should be directly assigned
    public static boolean isDirectAssignmentRequired(sObject oldRecord, sObject newRecord,GBWire__RoutingConfiguration__mdt config){
        
        //If config is incomplete return false
        if(config == null || config.GBWire__IsOpenFieldName__c == null || config.GBWire__ClientFieldName__c == null || config.GBWire__OwnerFieldName__c == null
           || config.GBWire__RouteWorkItemFieldName__c == null || config.GBWire__GhostAssignmentRuleId__c == null 
           || (config.GBWire__GhostCaseLookupField__c == null && config.GBWire__GhostLeadLookupField__c == null)) return false;
        
        /**Insert Trigger Context***/
        
        if(!isTestUpdate && (isTestInsert || trigger.isInsert)){
            if(newRecord != null){
                //If record is inserted, open and the 'Route Work Item' checkbox is ticked, return true
                if( String.isNotBlank(config.GBWire__IsOpenFieldName__c) &&
                   newRecord.get(config.GBWire__IsOpenFieldName__c) != null &&
                   (Boolean)newRecord.get(config.GBWire__IsOpenFieldName__c) && 
                   String.isNotBlank(config.GBWire__RouteWorkItemFieldName__c) &&
                   newRecord.get(config.GBWire__RouteWorkItemFieldName__c) != null &&
                   (Boolean)newRecord.get(config.GBWire__RouteWorkItemFieldName__c)) return true;//1.2
                
                //If record is inserted, open and the custom setting config 'Route Work Item' on insert is true, return true
                if(config.GBWire__RouteWorkItemOnInsertSettingFieldName__c != null){
                    GBWire__WorkItemRoutingSettings__c wirs = GBWire__WorkItemRoutingSettings__c.getInstance(); 
                    if(wirs != null && 
                       config != null && config.GBWire__IsOpenFieldName__c != null && newRecord.get(config.GBWire__IsOpenFieldName__c) != null && (Boolean)newRecord.get(config.GBWire__IsOpenFieldName__c) && //<--- 1.3 exclude closed leads from routing on insert
                       String.isNotBlank(config.GBWire__RouteWorkItemOnInsertSettingFieldName__c) &&
                       wirs.get(config.GBWire__RouteWorkItemOnInsertSettingFieldName__c) != null &&
                       (Boolean)wirs.get(config.GBWire__RouteWorkItemOnInsertSettingFieldName__c)) return true;//1.2
                }
            }
        }
        
        /**Update Trigger Context***/
        
        if(!isTestInsert && (isTestUpdate || trigger.isUpdate)){
            if(newRecord != null && oldRecord != null){           
                //If record is updated, open and the 'Route Work Item' checkbox is changed from False to True, return true
                if((Boolean)newRecord.get(config.GBWire__IsOpenFieldName__c) && (Boolean)newRecord.get(config.GBWire__RouteWorkItemFieldName__c) 
                   && !(Boolean)oldRecord.get(config.GBWire__RouteWorkItemFieldName__c)) return true;            
                //1.5 - If record is a Lead, is open, is queue owned, is updated and Sales Region populated (assumed via WF), return true
                if(config != null && config.GBWire__SObjectType__c != null && config.GBWire__SObjectType__c == ApplicationConstant.LEAD_SOBJECTTYPE){
                    String ownerId = (newRecord != null && config != null && config.GBWire__OwnerFieldName__c != null)?(String)newRecord.get(config.GBWire__OwnerFieldName__c):null;
                    if(oldRecord != null && newRecord != null && config.GBWire__IsOpenFieldName__c != null && (Boolean)newRecord.get(config.GBWire__IsOpenFieldName__c) 
                       && oldRecord.get('SalesRegion__c') == null && newRecord.get('SalesRegion__c') != null && ownerId.startsWithIgnoreCase('00G')) return true;
                }
            }
        }
        
        //TO DO - Evaluate on Delete/Undelete
        
        return false;     
        
    }    
    
    //This method returns true if the record's parent Account's Client Routing profile requires calculating/re-calculating
    public static boolean isClientRoutingProfileCalcRequired(sObject oldRecord, sObject newRecord,GBWire__RoutingConfiguration__mdt config, Boolean preferredQueueCalcIsRequired){//1.10~ 

        //system.debug('oldRecord: '+JSON.serialize(oldRecord));
        //system.debug('newRecord: '+JSON.serialize(newRecord));
        //system.debug('config: '+JSON.serialize(config));


        //If config is incomplete return false
        if(config == null || config.GBWire__IsOpenFieldName__c == null || config.GBWire__ClientFieldName__c == null 
           || config.GBWire__PreferredQueueFieldName__c == null) return false;    
        
        /**Insert Trigger Context***/
        
        if(!isTestUpdate && (isTestInsert || trigger.isInsert)){
            if(newRecord != null && newRecord.get(config.GBWire__ClientFieldName__c) != null){ 
                //If the inserted record is open, return true
                if((Boolean)newRecord.get(config.GBWire__IsOpenFieldName__c))return true;
            }       
        }
        
        /**Update Trigger Context***/
        
        if(!isTestInsert && (isTestUpdate || trigger.isUpdate)){
            if(newRecord != null && oldRecord != null){   
                
                //If record is updated and the Client has changed, return true
                if((Id)newRecord.get(config.GBWire__ClientFieldName__c) != (Id)oldRecord.get(config.GBWire__ClientFieldName__c)){
                    requiresCRPCalcForPreviousClient = true;
                    return true;
                }
                
                //If record is updated and open status has changed (closed or re-opened), return true
                if((Boolean)newRecord.get(config.GBWire__IsOpenFieldName__c) != (Boolean)oldRecord.get(config.GBWire__IsOpenFieldName__c) && newRecord.get(config.GBWire__ClientFieldName__c) != null) return true;
                
                //If record is updated and the Preferred Queue has changed, return true //1.10~ OR the Preferred Queue is set to be recalculated
                if((newRecord.get(config.GBWire__PreferredQueueFieldName__c) != oldRecord.get(config.GBWire__PreferredQueueFieldName__c) || preferredQueueCalcIsRequired) && newRecord.get(config.GBWire__ClientFieldName__c) != null)return true;//1.10~
            }             
        }            
        
        //TO DO - Evaluate on Delete/Undelete
        
        return false;
    }
    
    //This method returns true if the record's 'Preferred Queue' requires calculating/re-calculating
    public static boolean isPreferredQueueCalcRequired(sObject oldRecord, sObject newRecord,GBWire__RoutingConfiguration__mdt config, Set<String> preferredQueueFieldChangeNames){
        
        //If config is incomplete return false
        if(config == null || config.GBWire__IsOpenFieldName__c == null || config.GBWire__ClientFieldName__c == null 
           || config.GBWire__PreferredQueueFieldName__c == null) return false;    
        
        //If the Client is not populated or the record is closed return false
        //if(newRecord == null || /*!(Boolean)newRecord.get(config.GBWire__IsOpenFieldName__c) || newRecord.get(config.GBWire__ClientFieldName__c) == null*/) return false;
        
        //If record is inserted (has no Preferred Queue), return true
        if(!isTestUpdate && (isTestInsert || trigger.isInsert)) return true;
        
        //If a field referenced in the WIREPreferredQueueCalcFields__mdt metadata setting is changed, return true
        for(String field : preferredQueueFieldChangeNames){
            if(oldRecord.get(field) != newRecord.get(field)) return true;           
        }
        
        //1.4
        if(oldRecord != null && newRecord != null && config != null && config.GBWire__IsOpenFieldName__c != null){
            Boolean oldOpenStatus = (Boolean)oldRecord.get(config.GBWire__IsOpenFieldName__c);
            Boolean newOpenStatus = (Boolean)newRecord.get(config.GBWire__IsOpenFieldName__c);
            if(oldOpenStatus == false && newOpenStatus) return true;
        }
        //TO DO - Evaluate on Delete/Undelete
        
        return false;
    }    
    
    //1.1 - New Method to Assign accepted records via Active Assignment Rules (of the corresponding sObject Type)
    public static void routeWorkItemsWithActiveRules(Set<Id> workItemIds, GBWire__RoutingConfiguration__mdt config){
        
        //Exit if parameters are not specified or Work Item is of an unsupported object type
        if(workItemIds == null || config == null) return;
        if(config.GBWire__sObjectType__c != null && config.GBWire__sObjectType__c != ApplicationConstant.LEAD_SOBJECTTYPE && config.GBWire__sObjectType__c != ApplicationConstant.CASE_SOBJECTTYPE) return;
        
        system.debug('WorkItemWIREActionIdentifier>processWorkItems>setAssignmentRulesOnWorkItem>Start');
        GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>setAssignmentRulesOnWorkItem>Start');
        
        
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.useDefaultRule = true;     
        
        system.debug('WorkItemWIREActionIdentifier>processWorkItems>setAssignmentRulesOnWorkItem>QueryingRecords');
        GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>setAssignmentRulesOnWorkItem>QueryingRecords');
        
        //Dynamically query records
        String query;
        query = 'Select Id From '+config.GBWire__sObjectType__c+' Where Id In:workItemIds';
        List<sObject> records = database.query(query);        
        
        if(records != null && records.size()>0){
            //Apply the AR
            for(sObject s : records){
                s.setOptions(dmlOpts);
            }
            try{
                //Update records
                system.debug('WorkItemWIREActionIdentifier>processWorkItems>setAssignmentRulesOnWorkItem>AssigningRecords>');
                GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>setAssignmentRulesOnWorkItem>AssigningRecords');
                database.update(records);
            }catch(exception e){
                system.debug('WorkItemWIREActionIdentifier>processWorkItems>setAssignmentRulesOnWorkItem>FAIL>'+e);
                GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>setAssignmentRulesOnWorkItem>FAIL>'+e);
            }
        }
        
        
        system.debug('WorkItemWIREActionIdentifier>processWorkItems>setAssignmentRulesOnWorkItem>Stop');
        GBWire.RoutingLogHelper.debug('WorkItemWIREActionIdentifier>processWorkItems>setAssignmentRulesOnWorkItem>Stop');
        
    }

    //1.8
    public class ExecuteWIREActionsQueueable implements Queueable{
        
        public Map<Id,GBWire.WorkItemWithActionsWrapper> WIREMap;
        public String workItemType;
        public Boolean blockDataEventTriggers;//1.9+

        public ExecuteWIREActionsQueueable(Map<Id,GBWire.WorkItemWithActionsWrapper> WIREMap, String workItemType){
            this.WIREMap = WIREMap;
            this.workItemType = workItemType;
            blockDataEventTriggers = false;//1.9+
        }

        public ExecuteWIREActionsQueueable(Map<Id,GBWire.WorkItemWithActionsWrapper> WIREMap, String workItemType, Boolean blockDataEventTriggers){//1.9+
            this.WIREMap = WIREMap;
            this.workItemType = workItemType;
            this.blockDataEventTriggers = blockDataEventTriggers;
        }

        public void execute(QueueableContext context){
            try{
                Boolean dataEventsBlocked = DataEventTypeTriggerHandler.blockDataEventTriggers;//1.9+
                DataEventTypeTriggerHandler.blockDataEventTriggers = blockDataEventTriggers;//1.9+
                if(WIREMap != null && WIREMap.keySet().size()>0) GBWire.WorkItemUtility.executeWIRETriggerActions(WIREMap, workItemType);
                DataEventTypeTriggerHandler.blockDataEventTriggers = dataEventsBlocked;//1.9+
            }catch(exception e){
                    system.debug('*** -- Exception: ' + e + ' at ' + e.getLineNumber() + ' -- ***');
                    PlatformLogManager.logExceptions(e, 'ExecuteWIREActionsQueueable', 'execute');
            }
        }
    }

    @future public static void executeWIRETriggerActionsFuture(String wireMapSerialised, String workItemType, Boolean blockDataEventTriggers){//1.12+ 1.13~
        try{
            
            Map<String, Object> wireMapSerialisedData = (Map<String,Object>)JSON.deserializeUntyped(wireMapSerialised);// -- JSON typed deserialisation does not support generic Object.
            
            GBWire.WorkItemWithActionsWrapper w;
            Map<Id,GBWire.WorkItemWithActionsWrapper> WIREMap = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            Map<String,Object> mapToValue;

            for(String workItemId : wireMapSerialisedData.keySet()){

                w = new GBWire.WorkItemWithActionsWrapper();

                mapToValue = (Map<String,Object>)wireMapSerialisedData.get(workItemId);

                w.doAssign = mapToValue.containsKey('doAssign') ? (Boolean)mapToValue.get('doAssign') : false;
                w.doPreferredQueueCalc = mapToValue.containsKey('doPreferredQueueCalc') ? (Boolean)mapToValue.get('doPreferredQueueCalc') : false;
                w.doCRPCalc = mapToValue.containsKey('doCRPCalc') ? (Boolean)mapToValue.get('doCRPCalc') : false;
                w.doAgentCapacityCalc = mapToValue.containsKey('doAgentCapacityCalc') ? (Boolean)mapToValue.get('doAgentCapacityCalc') : false;
                w.doPreferredAgentCalc = mapToValue.containsKey('doPreferredAgentCalc') ? (Boolean)mapToValue.get('doPreferredAgentCalc') : false;
                w.previousOwnerId = mapToValue.containsKey('previousOwnerId') ? (Id)mapToValue.get('previousOwnerId') : null;
                w.previousClientId = mapToValue.containsKey('previousClientId') ? (Id)mapToValue.get('previousClientId') : null;

                WIREMap.put((Id)workItemId,w);
            }

            if (!WIREMap.isEmpty()) System.enqueueJob(new WorkItemWIREActionIdentifier.ExecuteWIREActionsQueueable(WIREMap,workItemType,blockDataEventTriggers));//1.13~
            //1.13- ExecuteWIREActionsQueueable ewaq = new ExecuteWIREActionsQueueable(WIREMap,workItemType,blockDataEventTriggers);
            //1.13- ewaq.execute(null);
            
        }catch(exception e){
            system.debug('*** -- Exception: ' + e + ' at ' + e.getLineNumber() + ' -- ***');
            PlatformLogManager.logExceptions(e, 'WorkItemWIREActionIdentifier', 'executeWIRETriggerActionsFuture');
        }
    }    
}