/*
Name:  OpportunityToEnquiryAction.cls
======================================================
======================================================
Purpose:
-------
Handles the processing of 'Direct to Opp' Opportunities 
(e.g. Booking Requests) to create an enquiry in Clubhouse

Note- this is a stop-gap solution until a robust global
booking integration solution is introduced.

======================================================
======================================================
History
------- 
Ver. Author           Date        Detail
1.0  James Radcliffe  24/05/2018  Initial Development.
1.1  James Radcliffe  11/07/2019  Retiring Sales Region Group: Sending static Sales Region (UK)
*/
public class OpportunityToEnquiryAction {
    
    @InvocableMethod(label='Send to Clubhouse' description='Creates an enquiry in Clubhouse based on Opportunity attributes')
    public static void SendOppstoClubhouse(List<Opportunity> opportunities) {
        
        system.debug('Opps to Send to Clubhouse: '+opportunities.size());
        
        System.debug(LoggingLevel.ERROR, 'Limits.getDmlRows():sendOppstoClubhouse:start='+Limits.getDmlRows());
        
        if(opportunities != null && opportunities.size()>0){
            
            //Set of Opp Ids
            Set<Id> oppIds = new Set<Id>();
            
            //Build oppIdsWithOpps Map
            for(Opportunity opp : opportunities){
                oppIds.add(opp.Id);
            }
                        
            //A Map of inOpps and their Ids
            Map<Id,Opportunity> oppIdsWithOpps = new Map<Id,Opportunity>([Select Id, SalesRegion__c, AdditionalInformation__c, Owner.Golfbreaks_Employee_Id__c, owner.Email, owner.FirstName, owner.LastName, AffiliateCampaignId__c, Nights__c, AccountId, PreferredTravelDate__c, PromoCode__c, TravelGroupSize__c, Venue__c, CountriesInterested__c, Weekly_Newsletter__c From Opportunity Where Id IN :oppIds ]);//1.1~
            
            system.debug('Opportunity Map: '+oppIdsWithOpps);
            //Queue job to send & create enquiries to Clubhouse
            system.enqueueJob(new sendOppsToClubhouse(oppIdsWithOpps));
        }
        
    }
    
    //A Queueable class for processing the Opportunity and invoking the call to Clubhouse
    public class sendOppsToClubhouse implements Queueable, Database.AllowsCallouts{
        
        public Map<Id,Opportunity> oppMap;
        public List<Error_Log__c> logs = new List<Error_Log__c>();
        public String CLASS_NAME = 'OpportunityToEnquiryProcessor';
        
        public sendOppsToClubhouse(Map<Id,Opportunity> inOppMap){
            this.oppMap = inOppMap;
        }
        
        public void execute(QueueableContext ctxt){
            processOpportunities();
        }
        
        @testVisible private void processOpportunities(){
            
            if(oppMap != null && oppMap.keySet().size()>0){
                
                //Retrieve Opp for processing
                Opportunity opp = oppMap.values()[0];
                
                try{
                    //Map Opportunity details to Clubhouse Request Wrapper
                    EnquiryClientRequestWrapper wrapper = new EnquiryClientRequestWrapper();
                    wrapper.AdditionalInformation = opp.AdditionalInformation__c;
                    wrapper.AffiliateCampaignID = opp.AffiliateCampaignId__c;
                    wrapper.AccountManager = new EnquiryClientRequestWrapper.EmployeeModel((Integer)opp.Owner.Golfbreaks_Employee_Id__c, opp.Owner.Email, opp.Owner.FirstName,opp.Owner.LastName);
                    
                    //Cannot send null to Clubhouse for 'Nights'
                    if(opp.Nights__c == null){
                        wrapper.Nights = 0;
                    }else{
                        wrapper.Nights = opp.Nights__c;
                    }
                    wrapper.ClientAccountID = opp.AccountId;
                    wrapper.PreferredTravelDate = opp.PreferredTravelDate__c;
                    wrapper.PromotionCode = opp.PromoCode__c;
                    //Cannot send null to Clubhouse for 'Travel Group Size'
                    if(opp.TravelGroupSize__c == null){
                        wrapper.TravelGroupSize = 0;
                    }else{
                        wrapper.TravelGroupSize = opp.TravelGroupSize__c;
                    }
                    wrapper.Venue = opp.Venue__c;
                    //Either a Trip Region or Sales Region/s (preferred) must be provided for a successful api call
                    if(opp.CountriesInterested__c != null){
                        wrapper.SalesRegions = opp.CountriesInterested__c.split(';');
                    }else{
                        //Calculate Trip Region based on Sales Region Group
                        //wrapper.TripRegion = getSalesRegionMap().get(opp.SalesRegion__c);//1.1-
                        wrapper.TripRegion = 'UK';//1.1+
                        
                    }
                    wrapper.NewsletterSignUp = opp.Weekly_Newsletter__c;
                    system.debug('Built Enquiry Request Wrapper');
                    //Send Enquiry to Clubhouse
                    system.debug('Calling WS01_RebarHTTPCallout.outboundMessageCallerOpportunity');
                    
                    System.debug(LoggingLevel.ERROR, 'Limits.getDmlRows():sendOppstoClubhouse:execute:beforecallout='+Limits.getDmlRows());
                    
                    String responseString = WS01_RebarHTTPCallout.outboundMessageCallerOpportunity(opp,wrapper);
                    system.debug('Response String '+responseString); 
                    
                    System.debug(LoggingLevel.ERROR, 'Limits.getDmlRows():sendOppstoClubhouse:execute:aftercallout='+Limits.getDmlRows());
                    
                    String statusCode = responseString.substringBefore(';');
                    
                    //If successful then remove the opp from map and reschedule job
                    if(statusCode == '200'){
                        //Remove the successfully processed Opp
                        oppMap.remove(opp.Id);
                        //Queue the next job (if more Opps exist)
                        if(oppMap.values().size()>0){
                            try{
                                system.enqueueJob(new sendOppsToClubhouse(oppMap));
                            }catch(exception e){
                                //Create logs for any errors
                                logs.add(ApplicationConstant.getExceptionLog(e,'outboundMessageCallerOpportunity',CLASS_NAME,null));  
                            }finally{
                                if(!logs.isEmpty()){
                                    database.insert(logs,false);
                                }                            
                            }
                        }                    
                    }else{
                        //Log error from Clubhouse
                        Error_Log__c e = new Error_Log__c();
                        e.Name = 'Booking Request Sync Error';
                        e.Error_Type__c = ApplicationConstant.GENERAL_ERROR_LOG;
                        e.Method_Name__c = 'sendOppsToClubhouse';
                        e.Class_Name__c = 'OpportunityToEnquiryProcessor';
                        e.Trace__c = responseString.substringAfter(';');
                        e.Error_Message__c = 'See "Trace"';
                        insert e;
                    }
                }catch(exception e){
                    //Create logs for any errors
                    logs.add(ApplicationConstant.getExceptionLog(e,'outboundMessageCallerOpportunity',CLASS_NAME,null));                  
                }finally{
                    if(logs != null && !logs.isEmpty()){
                        database.insert(logs,false);
                    }
                }
            }
        }
        
    }
    
    //This method retrieves a map of Sales Region Groups to Trip Region
    @testVisible
    private static Map<String, String> getSalesRegionMap() {
        
        Map<String, String> salesRegionMap = new Map<String, String>();
        salesRegionMap.put('', '0');
        salesRegionMap.put(ApplicationConstant.SALESREGIONGROUP_UK_IRELAND, 'UK');
        salesRegionMap.put(ApplicationConstant.SALESREGIONGROUP_EUROPE, 'EU');
        salesRegionMap.put(ApplicationConstant.SALESREGIONGROUP_USA, 'USA');
        salesRegionMap.put(ApplicationConstant.SALESREGIONGROUP_FDP, 'RestOfWorld');
        salesRegionMap.put(ApplicationConstant.SALESREGIONGROUP_LONGHAUL, 'RestOfWorld');
        salesRegionMap.put(ApplicationConstant.SALESREGIONGROUP_MIDHAUL, 'RestOfWorld');
        return salesRegionMap;
    }
    
}