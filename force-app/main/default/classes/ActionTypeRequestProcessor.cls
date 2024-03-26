/*
Name:  ActionTypeRequestProcessor.cls
Copyright © 2023  Golfbreaks
======================================================
======================================================
Purpose:
-------

Processor class for the ActionTypeRequest__c object.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2023-11-22  Initial development.
1.1  Mark Cane&    2023-12-05  Added equivalence check on ATR data type and property data type.
1.2	 J Radcliffe   2024-03-06  Bug fixes. Multiple downstream processes depend data being mapped to the enquiry request structure. Adding a new constructor to EnquiryManager, which accepts an ActionTypeRequest__c and maps the core details.
							   Note - The subsequent update of the property cache remains (from field mappings) is still necessary as it augments the existing property cache with additional values for added flexibility, without having to define them in the Enquiry structure.
1.3  J Radcliffe   2024-03-06  Check to see if the cache is already populated during construction before referencing mapping data.
*/
global with sharing class ActionTypeRequestProcessor implements System.Queueable, Database.Batchable<sObject> {

	private final String actionTypeName;
	private final Id exclusiveProcessorId;

	@testVisible private static Boolean isForceSchedulable=false;

    global ActionTypeRequestProcessor(){}

	global ActionTypeRequestProcessor(Id exclusiveProcessorId){ this.exclusiveProcessorId=exclusiveProcessorId; }	

	global ActionTypeRequestProcessor(String actionTypeName){ this.actionTypeName = actionTypeName; }

	global ActionTypeRequestProcessor(String actionTypeName,Id exclusiveProcessorId){ 
		this.actionTypeName = actionTypeName;
		this.exclusiveProcessorId=exclusiveProcessorId;
	}

    // Queueable
    global void execute(QueueableContext context) {
        if (isProcessorRunning(context.getJobId())) return;

		try {	    

			Integer requestsPerCycleLimit=200;//default.	

			Set<String> transactionalATs = new Set<String>();
			
			for (ActionType__mdt at : [select Id, DeveloperName, IsIsolatedRequestProcessor__c, IsTransactionalRequestProcessor__c, MaxRequestsPerProcessor__c from ActionType__mdt]){
                if (at.IsIsolatedRequestProcessor__c) continue;
				if (at.IsTransactionalRequestProcessor__c) transactionalATs.add(at.DeveloperName);
			}
			if (transactionalATs.isEmpty()) return;			

			List<ActionTypeRequest__c> requestsToProcess = [select Id,Name, ActionType__c
																from ActionTypeRequest__c 
																where Status__c='Pending'
																	and ActionType__c in :transactionalATs
																	and ProcessorJobId__c=null
																	and IsBatch__c=false
																order by Priority__c desc nulls last, CreatedDate asc
																limit :requestsPerCycleLimit];
			
			if (!requestsToProcess.isEmpty()){
				ActionTypeRequestProcessor.processRequests(requestsToProcess);
				
				if ([select count() from ActionTypeRequest__c where Status__c='Pending' and ActionType__c in :transactionalATs and Id not in:requestsToProcess and ProcessorJobId__c=null limit 1]>0){ runQueueable(context.getJobId()); }
			}

 		} catch(Exception e){ LogHelper.logExceptions(e, 'ActionTypeRequestProcessor', 'Queueable.execute'); }
    }

    // Batchable
    public Database.QueryLocator start(Database.BatchableContext context){

        if (String.isBlank(actionTypeName) && isProcessorRunning(context.getJobId())){ return emptyState(); }

		String q='select Id,Name,ActionType__c';
		q+=' from ActionTypeRequest__c';
		q+=' where Status__c=\'New\'';

		if (exclusiveProcessorId==null) q+=' and IsBatch__c=true';
		else q+=' and ProcessorJobId__c=\''+exclusiveProcessorId+'\'';		

		if (String.isNotBlank(actionTypeName)) q+=' and ActionType__c = \''+String.escapeSingleQuotes(actionTypeName)+'\'';
		q+=' order by Priority__c desc nulls last, CreatedDate asc';

        return Database.getQueryLocator(q);
    }
    
    public void execute(Database.BatchableContext bc, List<SObject> scope){ processRequests(scope); }
    
    public void finish(Database.BatchableContext bc){ }


    //& Helper methods.
    public static void processRequests(List<ActionTypeRequest__c> recs){                
		try {

			// [ ]1. -- group records by ActionType.
			// [ ]2. -- for each ActionType - load field mappings (for field groups).
			// [ ]3. -- for each ATR(request) - enumerate the field mappings
			// .. if the field mapping has an Action Type Request Field Mapping and the field is populated
			// .. then build a propertyCache(fm.EnquiryPropertyName__c=>ATR.fieldValue[read dynamically])
			// [ ]create an EnquiryManager.Enquiry instance and set the propertyCache and actionType variables.
			// [ ]pass list of Enquiry instances to EnquiryManager.processEnquiries().
			// [ ].. unit tests (all processing paths)

			Map<String,List<ActionTypeRequest__c>> atNameToATRs = new Map<String,List<ActionTypeRequest__c>>();
			for (ActionTypeRequest__c atr : recs){
				if (atr.ActionType__c==null) continue;
				
				if (!atNameToATRs.containsKey(atr.ActionType__c)) atNameToATRs.put(atr.ActionType__c,new List<ActionTypeRequest__c>());
				atNameToATRs.get(atr.ActionType__c).add(atr);
			}

			Map<Id,List<ActionTypeFieldMapping__mdt>> fieldGroupIdToField = new Map<Id,List<ActionTypeFieldMapping__mdt>>();
			Map<String,ActionType__mdt> atNameToAT = new Map<String,ActionType__mdt>();

			for (ActionType__mdt at : [select Id,DeveloperName,ClientFieldMappingGroup__c,IndividualFieldMappingGroup__c,WorkItemFieldMappingGroup__c
										from ActionType__mdt
										where DeveloperName in:atNameToATRs.keySet()]){
				atNameToAT.put(at.DeveloperName,at);
				if (at.ClientFieldMappingGroup__c!=null && !fieldGroupIdToField.containsKey(at.ClientFieldMappingGroup__c)) fieldGroupIdToField.put(at.ClientFieldMappingGroup__c,new List<ActionTypeFieldMapping__mdt>());
				if (at.IndividualFieldMappingGroup__c!=null && !fieldGroupIdToField.containsKey(at.IndividualFieldMappingGroup__c)) fieldGroupIdToField.put(at.IndividualFieldMappingGroup__c,new List<ActionTypeFieldMapping__mdt>());
				if (at.WorkItemFieldMappingGroup__c!=null && !fieldGroupIdToField.containsKey(at.WorkItemFieldMappingGroup__c)) fieldGroupIdToField.put(at.WorkItemFieldMappingGroup__c,new List<ActionTypeFieldMapping__mdt>());
			}

			for (ActionTypeFieldMapping__mdt atfm : [select Id,DeveloperName,EnquiryPropertyName__c,EnquiryPropertyDataType__c,ActionTypeFieldMappingGroup__c,ActionTypeRequestFieldName__c
														from ActionTypeFieldMapping__mdt 
														where ActionTypeFieldMappingGroup__c in:fieldGroupIdToField.keySet()]){
				fieldGroupIdToField.get(atfm.ActionTypeFieldMappingGroup__c).add(atfm);	
			}

			Map<String,Schema.DisplayType> fieldNameToType = DescribeHelper.getObjectAccessibleFieldMap('ActionTypeRequest__c');
			//[Removed for release] System.debug(LoggingLevel.ERROR,fieldNameToType);
			
			String q='select Id';
			for (String fn : fieldNameToType.keySet()){
				q+=','+String.escapeSingleQuotes(fn);
			}
			q+=' from ActionTypeRequest__c';
			q+=' where Id in:recs';
			q+=' order by Priority__c desc nulls last, CreatedDate asc';

			EnquiryManager.Enquiry e;			
			List<EnquiryManager.Enquiry> enquiriesToProcess = new List<EnquiryManager.Enquiry>();
			
			List<ActionTypeFieldMapping__mdt> fieldMappings;
			ActionType__mdt actionType;

			List<Id> cachedRequestIds = new List<Id>();
			Map<Id,SObject> idToSObject = new Map<Id,SObject>(Database.query(q));

			for (String actionTypeName : atNameToATRs.keySet()){

				if (!atNameToAT.containsKey(actionTypeName)) continue;//next actionType.

				actionType = atNameToAT.get(actionTypeName);
				
				fieldMappings = new List<ActionTypeFieldMapping__mdt>();

				if (actionType.ClientFieldMappingGroup__c!=null && fieldGroupIdToField.containsKey(actionType.ClientFieldMappingGroup__c)){ fieldMappings.addAll(fieldGroupIdToField.get(actionType.ClientFieldMappingGroup__c)); }
				if (actionType.IndividualFieldMappingGroup__c!=null && fieldGroupIdToField.containsKey(actionType.IndividualFieldMappingGroup__c)){ fieldMappings.addAll(fieldGroupIdToField.get(actionType.IndividualFieldMappingGroup__c)); }
				if (actionType.WorkItemFieldMappingGroup__c!=null && fieldGroupIdToField.containsKey(actionType.WorkItemFieldMappingGroup__c)){ fieldMappings.addAll(fieldGroupIdToField.get(actionType.WorkItemFieldMappingGroup__c)); }					

				if (fieldMappings.isEmpty()) continue;//next actionType.

				for (ActionTypeRequest__c atr : atNameToATRs.get(actionTypeName)){

					//e = new EnquiryManager.Enquiry();//1.2-
					e = new EnquiryManager.Enquiry((ActionTypeRequest__c)idToSObject.get(atr.Id));//1.2+
					e.actionType = actionType;
					e.actionTypeName = actionTypeName;

					for (ActionTypeFieldMapping__mdt atf : fieldMappings){

						//[Removed for release] System.debug(LoggingLevel.ERROR,atf);
						//[Removed for release] System.debug(LoggingLevel.ERROR,atr);
						//[Removed for release] System.debug(LoggingLevel.ERROR,idToSObject.get(atr.Id));

						if (atf.ActionTypeRequestFieldName__c==null
							|| atf.EnquiryPropertyName__c==null
							|| !fieldNameToType.containsKey(atf.ActionTypeRequestFieldName__c)
							|| !idToSObject.containsKey(atr.Id)
							|| idToSObject.get(atr.Id).get(atf.ActionTypeRequestFieldName__c)==null
							|| e.propertyCache.containsKey(atf.EnquiryPropertyName__c))//1.3+ Already populated by constructor (skipping)
							continue;//next field mapping.

						if (atf.EnquiryPropertyDataType__c.equalsIgnoreCase('String Array')){
							e.propertyCache.put(atf.EnquiryPropertyName__c,((String)idToSObject.get(atr.Id).get(atf.ActionTypeRequestFieldName__c)).split(','));

						} else if (ActionTypeHelper.getPropertyDataType(fieldNameToType.get(atf.ActionTypeRequestFieldName__c)).equalsIgnoreCase(atf.EnquiryPropertyDataType__c)){//1.1+ -- check ATR field type to EnquiryPropertyDataType__c equivalence.
							e.propertyCache.put(atf.EnquiryPropertyName__c,idToSObject.get(atr.Id).get(atf.ActionTypeRequestFieldName__c));
						}	
					}
					enquiriesToProcess.add(e);
					cachedRequestIds.add(atr.Id);
				}//request
			}//actionType

			if (!enquiriesToProcess.isEmpty()){
				Integer successCount = 0;
				Integer failCount = 0;
				List<Id> failIds = new List<Id>();
			
				List<ActionTypeRequest__c> requestsToUpdate = new List<ActionTypeRequest__c>();
				Integer loopCounter=0;
	
				EnquiryManager em = new EnquiryManager();    
				for (EnquiryManager.Enquiry etp : em.processEnquiries(enquiriesToProcess)){
					if(cachedRequestIds.size()<=loopCounter) break;
					if(etp.isSuccess){
						requestsToUpdate.add(new ActionTypeRequest__c(Id=cachedRequestIds[loopCounter],Status__c='Complete'));
						successCount = successCount+1;
					} else {
						failIds.add(cachedRequestIds[loopCounter]);//Store the Ids of the records that failed to log to the Platform Log object
						ActionTypeRequest__c atr = new ActionTypeRequest__c();
						atr.Id = cachedRequestIds[loopCounter];
						atr.Status__c = 'Aborted';
						if(etp.errorMessages != null && etp.errorMessages.values().size()>0){
							String errorMessages = '';
							for(String error: e.errorMessages.keySet()){
								errorMessages = errorMessages+'Status Code: : Error Message: '+e.errorMessages.get(error)+'\n';
							}
							atr.ErrorMessages__c = errorMessages;
						}
						requestsToUpdate.add(atr);
						failCount = failCount+1;
					}
					loopCounter = loopCounter+1;
				}   
	
				if(requestsToUpdate.size()>0){
					Database.SaveResult[] saveResults = Database.update(requestsToUpdate,false);//Update Action Type Requests with results ('Complete'/'Fail')
					LogHelper.logExceptions(saveResults, 'ActionTypeRequestProcessor', 'processRequests', requestsToUpdate);
				}
	
				if(failCount>0){ LogHelper.logAPIRequest(null, null, null, successCount, failCount, new List<String>{ 'Enquiry Import Failure! Please see the Action Type Request records for full details. Ids:'+String.join(failIds,',') }); }//In addition to updating the Action Type Requests, log failures to the Platform Log Object for the attention of the Salesforce Team.
			}

		} catch(Exception e){ LogHelper.logExceptions(e, 'ActionTypeRequestProcessor', 'processRequests'); }
	}
    
	public static Id runQueueable(){ return runQueueable(null); }
    
    public static Id runQueueable(Id ctId){
        
        if ((ctId!=null && !isProcessorRunning(ctId)) ||        
        	(ctId==null && !isProcessorRunning())){
        
        	if (!isForceSchedulable && Limits.getQueueableJobs()<(Limits.getLimitQueueableJobs())){
        		return System.enqueueJob(new ActionTypeRequestProcessor());
        	} else {

				// Transactional :-
				// #1 - isProcessorRunning should only return false where ActionTypeRequestProcessor Queueable is running.
				// #2 - if ActionTypeRequestProcessor Queueable is not running and Queueable limit is hit, then schedule a Schedulable to process just this batch.
				//      .. processorId = CronTriggerId 
				//      .. isbatch = false (stop records being picked up by batchable)
				//      .. code change - stop ActionTypeRequestProcessor picking up records with a processorId.
				//      .. code change - ensure batchable can process records exclusively where processorId=Schedulable and isbatch=false.

				// Isolated :-
				// #1 - if Queueable limit is hit, then schedule a Schedulable to process just this batch.
				//      .. processorId = CronTriggerId 
				//      .. isbatch = false (stop records being picked up by batchable)
				//      .. code change - ensure batchable can process records exclusively where processorId=Schedulable and isbatch=false.
				return System.schedule('ActionTypeRequests '+Datetime.now().format('ddMMyyyy-HHmmss')+' DSC', Datetime.now().addSeconds(5).format('ss mm HH dd M ? yyyy'), new ActionTypeRequestSchedulable(true));
			}
        } else return null;
    }

    public static Boolean isProcessorRunning(){

        return ([select count()
                    from AsyncApexJob 
                    where JobType='Queueable' 
                        		and (Status='Queued' or Status='Holding' or Status='Preparing' or Status='Processing') 
                        		and ApexClass.Name='ActionTypeRequestProcessor' limit 1]>0);

    }
    
    public static Boolean isProcessorRunning(Id thisJobId){

        return ([select count()
					from AsyncApexJob 
					where JobType='Queueable' 
								and (Status='Queued' or Status='Holding' or Status='Preparing' or Status='Processing') 
								and ApexClass.Name='ActionTypeRequestProcessor'
                        		and Id!=:thisJobId limit 1]>0);
    }

	private Database.Querylocator emptyState(){
        //& return empty locator - prevents error in the Batch interface.
        return Database.getQueryLocator('select Id from ActionTypeRequest__c limit 0');
    }

}