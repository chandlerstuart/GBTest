/*
Name:  GetMessagingDetailsAction.cls
======================================================
======================================================
Purpose:
-------
Golfbreaks Messaging Channels (e.g. SMS / WhatsApp etc) are limited to clients who are (or have recently been) in the sales or support cycle. 

This action can be called via flow and other sources to identify:
1. Whether messaging is enabled for the client.
2. The most applicable Salesforce record (Opportunity, Booking or other).
3. The most applicable sales or service agent.

This information is utilised within flow to determine how to handle incoming messages (e.g which records should be linked, where  it be routed, whether a case should be created etc.)

If messaging is not enabled, the customer will receive a friendly automatic response advising them to contact Golfbreaks via other channels and the conversation will be closed without further action.

======================================================
======================================================
History
------- 
Ver. Author                  Date        Detail
1.0  J Radcliffe   2024-01-04  Initial development.
1.1  C Stuart      2024-02-01  Introduced the ability to simulate an exception for code coverage
*/
public with sharing class GetMessagingDetailsAction {

    @TestVisible public static Boolean throwException = false;

    public static List<String> messagingEnabledClients = new List<String>();

    @InvocableMethod
    public static List<ActionResult> getMessagingDetails(List<ActionRequest> requests) {

        List<ActionResult> results = new List<ActionResult>();

        try{
        
            //Build Id Set
            Set<String> accountIds = new Set<String>();
            for(ActionRequest request : requests){
                accountIds.add(request.accountId);
            }

            // Call a sub-method to find each account's service work item id
            Map<String, String> accountToWorkItemIdMap = findMessagingServiceWorkItemIds(accountIds);

            // Call a sub-method to get the preferred agents for the applicable agent, client and work items
            Map<String, String> preferredAgentMap;
            if(accountToWorkItemIdMap != null && accountToWorkItemIdMap.values().size()>0){
                preferredAgentMap = getPreferredAgentId(accountToWorkItemIdMap);
            }

            // Iterate through the accounts to set results
            for (String accountId : accountIds) {
                ActionResult result = new ActionResult();

                // Apply the messaging service work item id
                if(accountToWorkItemIdMap != null && accountToWorkItemIdMap.containsKey(accountId)) result.messagingServiceWorkItemId = accountToWorkItemIdMap.get(accountId);

                // If messagingServiceWorkItemId is not null the client is enabled for messaging (as a service)
                result.isMessagingEnabled = messagingEnabledClients.contains(accountId);

                // If messaging is enabled, retrieve the preferred agent from the map (if there is a preferred agent)
                if (result.isMessagingEnabled && result.messagingServiceWorkItemId != null) {
                    result.serviceWorkItemDataType = String.valueOf(((Id)result.messagingServiceWorkItemId).getSObjectType());
                    if(preferredAgentMap != null && preferredAgentMap.containsKey(accountId)) result.preferredAgentId = preferredAgentMap.get(accountId);
                }

                result.isSuccess = true;

                results.add(result);
            }
            if(throwException) throw new GetMessagingDetailsActionTest.CustomException(); // Throw Exception For Testing Purposes 1.1+
            return results;

        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'GetMessagingDetailsAction','getMessagingDetails');
            for(ActionRequest request : requests){
                ActionResult res = new ActionResult();
                res.isSuccess = false;
                res.errorMessage = e.getMessage()+'-'+e.getStackTraceString();
                results.add(res);
            }
            return results;
        }
    }

    private static Map<String, String> findMessagingServiceWorkItemIds(Set<String> accountIds) {

        if(accountIds == null) return new Map<String, String>();

        //Master map to return
        Map<String, String> messagingWorkItemIdMap = new Map<String, String>();

        // Query for GBWire__CRPWorkItemId__c field on the accounts
        // and subquery for bookings and opportunities
        List<Account> accounts = [SELECT Id, GBWire__CRPWorkItemId__c,
                                        
                                        (SELECT Id, TECH_Opportunity__c, OpportunityStage__c, TravelReturnDate__c
                                        FROM Bookings__r WHERE 
                            
                                        //Active or Recently travelled
                                         TravelReturnDate__c >= LAST_N_DAYS:14 
                                         AND Is_Postponed__c = false
                                         AND Is_Cancelled__c = false

                                         ORDER BY Travel_Date__c ASC),//Priority order by travel date
                                        
                                         (SELECT Id, IsClosed FROM Opportunities WHERE 

                                         //Active or Recent No Sale
                                         (IsClosed = false OR                                      
                                         (CloseDate >= LAST_N_DAYS:90 
                                         AND StageName = :ApplicationConstant.OPP_STAGE_NOSALE
                                         AND Owner.IsActive = true
                                         )) 

                                         ORDER BY LastModifiedDate DESC)
                                 FROM Account WHERE Id IN :accountIds];

        // Iterate through the accounts to evaluate data
        for (Account account : accounts) {

            //Data lists
            List<Opportunity> activeOpportunities = new List<Opportunity>();
            List<Opportunity> recentNoSaleOpportunities = new List<Opportunity>();
            List<Booking__c> activeBookings = new List<Booking__c>();
            List<Booking__c> recentlyTravelledBookings = new List<Booking__c>();


            String messagingWorkItemId;
            Boolean isMessagingEnabled = false;
            
            // Sort the related data into lists
            if (account.Bookings__r.size() > 0) {
                for(Booking__c booking : account.Bookings__r){
                    if(booking.TravelReturnDate__c>=System.today()){
                        activeBookings.add(booking);
                    }else{
                        recentlyTravelledBookings.add(booking);
                    }
                }
            }

            if (account.Opportunities.size() > 0) {
                for(Opportunity opportunity : account.Opportunities){
                    if(!opportunity.IsClosed){
                        activeOpportunities.add(opportunity);
                    }else{
                        recentNoSaleOpportunities.add(opportunity);
                    }
                }
            }

            //Evaluate related data to determine the most suitable messaging service item based on agreed business logic.
            
            //Active Opportunity and No Active Booking
            if(activeOpportunities.size()==1 && activeBookings.size()==0){
                system.debug('Open Opportunity and No Booking');
                messagingWorkItemId = activeOpportunities[0].Id;
                isMessagingEnabled = true;
            }
            //Active Booking and No Active Opportunity
            else if(activeBookings.size()==1 && activeOpportunities.size()==0){
                //Check if it's pre or post deposit.
                if(activeBookings[0].TECH_Opportunity__c != null
                && activeBookings[0].OpportunityStage__c != ApplicationConstant.PAIDFULLDEPOSITSTAGE 
                &&  activeBookings[0].OpportunityStage__c != ApplicationConstant.PAIDFULLBALANCESTAGE){
                    system.debug('Open Booking with Pre Deposit Opportunity');
                    messagingWorkItemId = activeBookings[0].TECH_Opportunity__c;
                }else{
                    system.debug('Open Booking and No Opp');
                    messagingWorkItemId = activeBookings[0].Id;
                }
                isMessagingEnabled = true;
            }
            //Active Booking and Active Opportunity
            else if(activeBookings.size()>0 && activeOpportunities.size()>0){
                system.debug('Active Booking and Opp');
                messagingWorkItemId = activeOpportunities[0].Id;// Start with Sales
                isMessagingEnabled = true;
            }
            //Multiple Active Bookings
            else if(activeBookings.size()>1){
                system.debug('Multiple Active Bookings');
                isMessagingEnabled = true;//They are enabled, but we cannot identify which booking, a generic case will be created FOA service teams.
            }
            //Multiple Active Opportunities
            else if(activeOpportunities.size()>1){
                system.debug('Multiple Active Opportunities');
                messagingWorkItemId = activeOpportunities[0].Id;//First (in query order) is priority
                isMessagingEnabled = true;
            }
            //Recently Travelled Booking
            else if(recentlyTravelledBookings.size()>0){
                system.debug('Recently Travelled Booking');
                messagingWorkItemId = recentlyTravelledBookings[0].Id;
                isMessagingEnabled = true;
            }
            //Recent No Sale Opportunity
            else if(recentNoSaleOpportunities.size()>0){
                system.debug('Recently No Saled Opp');
                messagingWorkItemId = recentNoSaleOpportunities[0].Id;
                isMessagingEnabled = true;
            }
            //Default (no record found. Messaging not supported)
            else{
                system.debug('Intent unknown');
                continue; // Skip without adding an entry 
            }

            if(isMessagingEnabled == true) messagingEnabledClients.add(account.Id);
            if(messagingWorkItemId != null) messagingWorkItemIdMap.put(account.Id, messagingWorkItemId);
        }

        return messagingWorkItemIdMap;
    }

    private static Map<String, String> getPreferredAgentId(Map<String, String> accountToMessagingServiceWorkItemIdMap) {

        Map<String, String> preferredAgentMap = new Map<String, String>();

        if(accountToMessagingServiceWorkItemIdMap == null) return preferredAgentMap;

        // Query for GBWire__PreferredAgent__c to find matches
        // where GBWire__Client__c is the original account Id
        // and activeWorkItemId is in either GBWire__Opportunity__c, GBWire__Case__c, or Booking__c fields
        List<GBWire__PreferredAgent__c> preferredAgents = [SELECT GBWire__Agent__c, GBWire__Client__c
                                                          FROM GBWire__PreferredAgent__c
                                                          WHERE GBWire__Client__c IN :accountToMessagingServiceWorkItemIdMap.keySet()
                                                          AND GBWire__Agent__c != null
                                                          AND (GBWire__Opportunity__c IN :accountToMessagingServiceWorkItemIdMap.values()
                                                               OR GBWire__Case__c IN :accountToMessagingServiceWorkItemIdMap.values()
                                                               //OR Booking__c IN :accountToMessagingServiceWorkItemIdMap.values()
                                                               )];

        // Iterate through the preferred agents to set the map
        for (GBWire__PreferredAgent__c preferredAgent : preferredAgents) {
            preferredAgentMap.put(preferredAgent.GBWire__Client__c, preferredAgent.GBWire__Agent__c);
        }

        return preferredAgentMap;
    }
        
    public class ActionRequest {
        
        @InvocableVariable(label='Client Account Id' required=true)
        public Id accountId;
    
    }

    public class ActionResult {
        @InvocableVariable
        public Boolean isMessagingEnabled; //This indicates whether we are offering Messaging as a service to this client i.e. are they actively or recently in our sales/service cycle?
        
        @InvocableVariable
        public String messagingServiceWorkItemId; //The booking or opportunity that justifies the service and provides context to the incoming message.
        
        @InvocableVariable
        public String preferredAgentId; //The preferred agent for handling messages raised by client.
        
        @InvocableVariable
        public String serviceWorkItemDataType; //The relevant department Sales / Service

        @InvocableVariable
        public Boolean isSuccess; //The success status (true/false)

        @InvocableVariable
        public String errorMessage; //Error details
    }

}