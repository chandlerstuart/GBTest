/*
Name:  LeadConversionAction.cls
======================================================
======================================================
Purpose:
-------
This apex action facilitates lead conversion via flow.
If the number of leads to convert exceeds the configured limit
leads are converted in batches (in sequence)

Summary:
It processes leads either synchronously or asynchronously in batches based on the batch size limit retrieved from the LeadConversionSettings__c Custom Setting.

The LeadConversionQueueable class is responsible for processing leads in batches using the Queueable interface.

It sets the Opportunity Name, Opportunity Owner, and other conversion fields based on the input parameters provided.

It handles errors during lead conversion and logs them for debugging.

It updates the 'GBWire__RouteWorkItem__c' field for Opportunities and optionally routes Opportunities via Omni Channel based on the routeOpportunity input.


======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2023-09-13  Initial development.
*/
public class LeadConversionAction {

    public class CustomException extends Exception{}
    @TestVisible public static boolean throwException = false;
    @TestVisible public static boolean throwError = false;

    @InvocableMethod(label='Convert Leads into Opportunities' description='Converts Leads into Opportunities')
    public static void convertLeads(List<LeadConversionInput> inputList) {
        
        // Get the batch size limit from the Custom Setting or default to 20
        Integer batchSizeLimit = LeadConversionSettings__c.getOrgDefaults().MaximumBatchSize__c != null ?
                                Integer.valueOf(LeadConversionSettings__c.getOrgDefaults().MaximumBatchSize__c) : 20;

        Integer totalLeads = inputList.size();
        Integer processedLeads = 0;

        if(inputList.size()<batchSizeLimit){
            //Process synchronously
            processBatch(inputList);
        }else{
            // Queue the initial processing job
            System.enqueueJob(new LeadConversionQueueable(inputList,batchSizeLimit));
        }
    }

    // Inner class for the Queueable job
    public class LeadConversionQueueable implements Queueable {
        List<LeadConversionInput> inputList;
        Integer batchSizeLimit;

        public LeadConversionQueueable(List<LeadConversionInput> inputList, Integer batchSizeLimit) {
            this.inputList = inputList;
            this.batchSizeLimit = batchSizeLimit;
        }

        public void execute(QueueableContext context) {
            
            // Process up to the batch size limit or the remaining leads
            List<LeadConversionInput> processNow = new List<LeadConversionInput>();
            List<LeadConversionInput> processNext = new List<LeadConversionInput>();

            // Extract a batch of LeadConversionInput objects
            Integer counter = 0;
            for (LeadConversionInput lci : inputList) {
                if(counter+1 <= batchSizeLimit){
                    processNow.add(lci);
                }else{
                    processNext.add(lci);
                }
                counter = counter+1;
            }

            // Process the batch
            processBatch(processNow);

            // If there are remaining leads, queue another processing job
            if (processNext.size()>0) {
                System.enqueueJob(new LeadConversionQueueable(processNext, batchSizeLimit));
            }
        }
    }

    public static void processBatch(List<LeadConversionInput> batchInputList) {

        try{

            // Process lead conversion for the batch
            List<Id> opportunityIdsToAutoAssign = new List<Id>();

            LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];

            List<Database.LeadConvert> lcs = new List<Database.LeadConvert>();

            for (LeadConversionInput input : batchInputList) {
                
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(input.leadId);

                // Set Lead Status
                if(input.convertedLeadStatus != null && !String.isBlank(input.convertedLeadStatus)){
                    lc.setConvertedStatus(input.convertedLeadStatus);
                }else{
                    lc.setConvertedStatus(convertStatus.MasterLabel);
                }

                // Set Account Id
                if (input.accountId != null && !String.isBlank(input.accountId)) {
                    lc.setAccountId(input.accountId);
                }

                // Set Opportunity Name if provided; otherwise, use the standard name
                if (input.opportunityName != null && !String.isBlank(input.opportunityName)) {
                    lc.setOpportunityName(input.opportunityName);
                }

                // Set Opportunity Owner if provided; otherwise, leave it blank
                if (input.ownerId != null && !String.isBlank(input.ownerId)) {
                    lc.setOwnerId(input.ownerId);
                }
                lcs.add(lc);
            }

            List<String> conversionErrors = new List<String>();

            if(lcs.size()>0){

                if(Test.isRunningTest() && throwException) throw new CustomException('Whoops! Something unexpected happened');

                // Perform the conversion
                Integer resultCounter = 0;

                if(Test.isRunningTest() && throwError) lcs[0].setConvertedStatus('FAKESTATUS!');//Force an error for the first lead

                List<Database.LeadConvertResult> lcrs = Database.convertLead(lcs, false);
                for(Database.LeadConvertResult lcr : lcrs){
                    if (lcr.isSuccess()) {
                        // Lead was successfully converted
                        if(batchInputList[resultCounter].routeOpportunity != null && batchInputList[resultCounter].routeOpportunity == true){
                            // Collect Opportunity Ids for routing via omni
                            opportunityIdsToAutoAssign.add(lcr.getOpportunityId());
                        }
                    } else {
                        // Handle conversion errors
                        System.debug('Lead conversion failed: ' + lcr.getErrors()[0].getMessage());
                        conversionErrors.add('Lead conversion failed: ' + lcr.getErrors()[0].getMessage()+'. Lead Id: '+lcr.leadid);
                    }
                    resultCounter = resultCounter+1;
                }
            } 

            if(conversionErrors.size()>0) Golfbreaks.PlatformLogManager.logCustomMessage(JSON.serialize(conversionErrors),'Lead Conversion Failures','LeadConversionAction','processBatch',null);

            // Bulk update the 'GBWire__RouteWorkItem__c' field for all Opportunities in the batch
            if (!opportunityIdsToAutoAssign.isEmpty()) {
                routeOpportunities(opportunityIdsToAutoAssign);
            }

        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'LeadConversionAction','processBatch');
        }
    }
    
    public static void routeOpportunities(List<Id> opportunityIds) {
        // Bulk update the 'GBWire__RouteWorkItem__c' field for all Opportunities - implicitly trigger routing engine
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        opportunitiesToUpdate = [SELECT Id, GBWire__RouteWorkItem__c FROM Opportunity WHERE Id IN :opportunityIds];

        for (Opportunity opp : opportunitiesToUpdate) {
            opp.GBWire__RouteWorkItem__c = true;
        }

        List<Database.SaveResult> results = Database.update(opportunitiesToUpdate,false);
        Golfbreaks.PlatformLogManager.logExceptions(results,'LeadConversionAction','routeOpportunities',opportunitiesToUpdate);
    }

    public class LeadConversionInput {
        @InvocableVariable(label='Lead Id' description='The Id of the Lead to be converted.' required=true)
        public Id leadId;

        @InvocableVariable(label='Account Id' description='The Id of the Lead\'s related Client Account.' required=true)
        public Id accountId;

        @InvocableVariable(label='Converted Lead Status' description='The status that should be applied to the lead following successful conversion (optional). If unspecified a default will be applied.')
        public String convertedLeadStatus;

        @InvocableVariable(label='Opportunity Name' description='The name to set for the Opportunity (optional). If left empty, the default name will be applied.')
        public String opportunityName;

        @InvocableVariable(label='Opportunity Owner Id' description='The Salesforce User Id to assign as the Opportunity Owner (optional). If left empty, the owner will remain unchanged.')
        public String ownerId;

        @InvocableVariable(label='Route Opportunity' description='If enabled, the Opportunity will be automatically routed via Omni Channel.')
        public Boolean routeOpportunity;
    }
}