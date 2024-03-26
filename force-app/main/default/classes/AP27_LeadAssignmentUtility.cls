/**
 ** @author: Alyana Navarro 2.25.2016, Dee 4.12.2016
 ** Class Name: AP27_LeadAssignmentUtility
 ** @Description: Prototype utility class for Lead Assignment.
 **
 **/

/**
 ** @Edited by: Nicole De Guzman 03/04/2016
 ** @Class Name: AP27_LeadAssignmentUtility
 ** @Description: Code clean-up
 **
 **/
public with sharing class AP27_LeadAssignmentUtility{

    // Used for logging --- Added by Dee 5/15
    public static final String CLASS_NAME = 'AP27_LeadAssignmentUtility';
    
    //& MC - 2016-12-03
    private static final String CALLBACK_QUEUE_DEVELOPER_NAME = 'S_Callback_Leads'; // Move to ApplicationConstant.cls
    private static final String LEAD_SOURCE_WEBFORM_CALLBACK = 'Web Callback';
    
    
    //& MC - 2016-12-04 - Overload used from trigger context (AP04_LeadTriggerBL).
    public static List<Lead> leadRouter(List<Lead> leads, Boolean isFromTrigger){
        return leadRouter(leads, isFromTrigger, true);
    }    
    
     /**
       *  This method calls all methods related to lead routing according to proper sequence.
       *  @name: leadRouter
       *  @developer: Recuerdo Bregente
       *  @param: leads - all leads created from trigger or from batch class
       *  @param: isFromTrigger - true if calling method comes from trigger. Otherwise, false.
       *  @param: isCustomerCallbackRouteToQueue - true for assignment of new Customer Callback leads to the Callback queue. 
       *                                           false where Customer Callback Leads should be routed using SAA, Specialist and Cold teams.    
     */
    public static List<Lead> leadRouter(List<Lead> leads, Boolean isFromTrigger, Boolean isCustomerCallbackRouteToQueue){
        System.debug('leadRouter --- Start');
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        List<Lead> updatedLeads = new List<Lead>();
        
        
        try{
            
            List<Lead> coldLeads = new List<Lead>();
            
            //& MC - 2016-12-03 - for consistency the coding approach for Customer Callback routing has been aligned to the existing code.
            List<Lead> customerCallbackLeads = new List<Lead>();
            Map<Boolean, List<Lead>> qualifiedLeads = qualifyLeads(leads, coldLeads, customerCallbackLeads, isCustomerCallbackRouteToQueue); //& MC - 2016-12-03           
            
            if(qualifiedLeads.containsKey(false) && !qualifiedLeads.get(false).isEmpty()){
                Map<Boolean, List<Lead>> leadsWithRegion = getLeadsWithRegion(qualifiedLeads.get(false));
                if(leadsWithRegion.containsKey(true) && !leadsWithRegion.get(true).isEmpty()){
                    doSAAMatching(leadsWithRegion.get(true), isFromTrigger);
                    updatedLeads.addAll(leadsWithRegion.get(true));
                }
                
                if(leadsWithRegion.containsKey(false) && !leadsWithRegion.get(false).isEmpty()){
                    assignToUnknownSalesTeam(leadsWithRegion.get(false));
                    updatedLeads.addAll(leadsWithRegion.get(false));
                }
            }
            System.debug('leadRouter --- qualifiedLeads: ' + qualifiedLeads + ' contains: ' +qualifiedLeads.containsKey(true));
            
            if(qualifiedLeads.containsKey(true) && !qualifiedLeads.get(true).isEmpty()){
                assignSpecialistTeam(qualifiedLeads.get(true), isFromTrigger);
                updatedLeads.addAll(qualifiedLeads.get(true));
            }
            
            if(!coldLeads.isEmpty()){
                assignToColdTeam(coldLeads);
                updatedLeads.addAll(coldLeads);
            }
            
            if(!customerCallbackLeads.isEmpty()){
                assignToCustomerCallbackQueue(customerCallbackLeads);
                updatedLeads.addAll(customerCallbackLeads);
            }
            
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'leadRouter()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
        
        System.debug('leadRouter --- End');
        return updatedLeads;
    }
    
    /**
       *  This method identifies which lead records would go to Sales Attribute Mappings.
       *  @name: qualifyLeads
       *  @developer: Recuerdo Bregente
       *  @param: leads - lead records to be verified
       *
       * Revision History :
       * 1. Mark Cane - 2016-12-03: callbackLeads param and related code added.
       * 2. Mark Cane - 2017-02-06: skip assignment where the flag is set. Assignment rule logic explicitly applied.
     */
    public static Map<Boolean, List<Lead>> qualifyLeads(List<Lead> leads, List<Lead> coldLeads, List<Lead> callbackLeads, Boolean isCustomerCallbackRouteToQueue){
        System.debug('qualifyLeads --- Start');
        Map<Boolean, List<Lead>> qualifiedLeads = new Map<Boolean, List<Lead>>();
        
        for(Lead leadRecord : leads){
            System.debug('qualifyLeads --- leadRecord.LeadSource: ' + leadRecord.LeadSource);
            if(leadRecord.Status <> ApplicationConstant.LEAD_CLOSED_CONVERTED && leadRecord.Status <> ApplicationConstant.LEAD_NO_SALE &&
                leadRecord.Status <> ApplicationConstant.LEAD_STATUS_DUPLICATE){
                
                //& MC - 2017-02-04 - skip assignment where the flag is set. Assignment rule logic invoked via after insert trigger. 
                if (leadRecord.Bypass_SAA_Routing__c){
                    // do nothing.
                    
                //& MC - 2016-12-03 - param callbackLeads==null where Callback Leads should be routed via the normal assignment algorithm.  
                } else if (isCustomerCallbackRouteToQueue &&
                        leadRecord.Customer_Call_Back_Date_Time__c!=null && 
                        leadRecord.LeadSource==LEAD_SOURCE_WEBFORM_CALLBACK){
                                
                    callbackLeads.add(leadRecord);
                    
                } else if(ApplicationConstant.LEAD_ROUTING_RATING.contains(leadRecord.Rating) && !leadRecord.IsLeadAssigned__c &&
                    !ApplicationConstant.UNQUALIFIED_SOURCE.contains(leadRecord.LeadSource)){
                    if(!qualifiedLeads.containsKey(leadRecord.SpecialistSales__c)){
                        qualifiedLeads.put(leadRecord.SpecialistSales__c, new List<Lead>());
                    }
                    
                    qualifiedLeads.get(leadRecord.SpecialistSales__c).add(leadRecord);
                    
                } else if(ApplicationConstant.LEAD_RATING_COLD.equals(leadRecord.Rating)){
                    coldLeads.add(leadRecord);
                }
            }
        }
        
        System.debug('qualifyLeads --- qualifiedLeads: ' + qualifiedLeads);
        
        System.debug('qualifyLeads --- End');
        return qualifiedLeads;
    }    
    
    /**
       *  This method filters the Lead with those that has regions.
       *  @name: getLeadsWithRegion
       *  @developer: Recuerdo Bregente
       *  @param: leads - lead records to check
     */
    public static Map<Boolean, List<Lead>> getLeadsWithRegion(List<Lead> leads){
        System.debug('getLeadsWithRegion --- Start');
        Map<Boolean, List<Lead>> leadsWithOrWithoutRegion = new Map<Boolean, List<Lead>>();
        leadsWithOrWithoutRegion.put(true, new List<Lead>());
        leadsWithOrWithoutRegion.put(false, new List<Lead>());
        
        for(Lead leadRecord : leads){
            if(!String.isEmpty(leadRecord.SalesRegion__c)){
                leadsWithOrWithoutRegion.get(true).add(leadRecord);
            }
            else{
                leadsWithOrWithoutRegion.get(false).add(leadRecord);
            }
        }
      
        System.debug('getLeadsWithRegion --- End');
        return leadsWithOrWithoutRegion;
    }
    
    /**
       *  This method matches the lead record with Sales Agent Attribute Record.
       *  @name: doSAAMatching
       *  @developer: Recuerdo Bregente
       *  @param: leads - lead records to fnd matching with Sales Agent Attribute
       *  @param: isFromTrigger - true if calling method comes from trigger. Otherwise, false.
     */
    public static List<Lead> doSAAMatching(List<Lead> leads, Boolean isFromTrigger){
        System.debug('!!!!!!!!!!!!!!!! doSAAMatching --- Start:'+leads);
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        List<Lead> updatedLeads = new List<Lead>();
        
        try{
            // Filter Leads when invoking method is from a batch class
            if(!isFromTrigger){
                leads = filterQueuedLeads(leads);
            }
            
            Map<Id, Sales_Agent_Attributes__c> salesAgentMap = retrieveSalesAgentAttribute();
            Map<String, List<Id>> teamAgentsMap = retrieveTeamAgentsMap(salesAgentMap);
            Map<String, String> teamMap = mapTeamByRegionAndSize(leads);
            Map<String, List<Id>> leadAgentMatches = findMatches(leads, salesAgentMap, teamMap);
            Map<Id, Sales_Agent_Attributes__c> agentsToUpdate = new Map<Id, Sales_Agent_Attributes__c>();
            String leadIdentifier;
            Id currentSAAId;
            Boolean isRecordUpdate = false;
            List<Lead> assignToQueue = new List<Lead>();
            List<Lead> assignToUserQueue = new List<Lead>();
            List<Lead> assignOldestOppByAgent = new List<Lead>();
            Map<String, Set<Id>> undistributedAgents = new Map<String, Set<Id>>();
            Map<String, Set<Id>> distributedAgents = new Map<String, Set<Id>>();
            Set<Id> matchedIdSet =  new Set<Id>();
            Integer saaIndex;
            List<Integer> maxReached = new List<Integer>();
            
            for(Lead leadRecord : leads){
                leadIdentifier = leadRecord.LastName+leadRecord.FirstName+leadRecord.Company+leadRecord.Status+leadRecord.LeadSource+leadRecord.Email+leadRecord.Phone+leadRecord.Rating+leadRecord.SalesRegion__c+leadRecord.Id;
                saaIndex = -1;
                currentSAAId = null;
                
                if(leadAgentMatches.containsKey(leadIdentifier) && teamMap.containsKey(leadIdentifier) && 
                    teamAgentsMap.containsKey(teamMap.get(leadIdentifier))){
                    
                    if(leadAgentMatches.get(leadIdentifier).size() == 1){
                         System.debug('!!!!!!!!!!!!!!!! doSAAMatching --- Match Found, Lead: ' + leadRecord.LastName);
                         if(salesAgentMap.get(leadAgentMatches.get(leadIdentifier)[0]).Current_Number_of_Open_Leads_Opps__c < 
                             salesAgentMap.get(leadAgentMatches.get(leadIdentifier)[0]).Max_Number_of_Open_Leads_Opportunities__c && 
                             salesAgentMap.get(leadAgentMatches.get(leadIdentifier)[0]).Current_Items_Diarised_Today__c < 
                             salesAgentMap.get(leadAgentMatches.get(leadIdentifier)[0]).Max_Items_Diarised_Today__c){
                             currentSAAId = leadAgentMatches.get(leadIdentifier)[0];
                         }
                         
                    }
                    else if(leadAgentMatches.get(leadIdentifier).size() > 1){
                        System.debug('!!!!!!!!!!!!!!!! doSAAMatching --- Many Matches, Lead: ' + leadRecord.LastName + ' Account: ' + leadRecord.Account__c);
                        if(leadRecord.Account__c == null){
                            matchedIdSet =  new Set<Id>();
                            matchedIdSet.addAll(leadAgentMatches.get(leadIdentifier));
                            maxReached = new List<Integer>();
                            saaIndex = findAvailableSaa(matchedIdSet, salesAgentMap, teamAgentsMap, teamMap.get(leadIdentifier), maxReached, agentsToUpdate);
                            
                            if(saaIndex != -1){
                                currentSAAId = teamAgentsMap.get(teamMap.get(leadIdentifier)).get(saaIndex);
                            }
                            
                            if(!maxReached.isEmpty()){
                                maxReached.sort();
                                
                                for(Integer i = maxReached.size()-1; i >= 0; i--){
                                    teamAgentsMap.get(teamMap.get(leadIdentifier)).remove(maxReached[i]);
                                }
                            }
                            
                        }
                        else{
                            assignOldestOppByAgent.add(leadRecord);
                        }
                    }
                    else{
                        System.debug('doSAAMatching --- No Match, Lead: ' + leadRecord.LastName);
                        assignToQueue.add(leadRecord);
                    }
                    
                    if(!String.isEmpty(currentSAAId)){
                        leadRecord.OwnerId = salesAgentMap.get(currentSAAId).Sales_Rep__c;
                        System.debug('Matched agent to Insert: ' + salesAgentMap.get(currentSAAId).Sales_Rep__r.lastName);
                        System.debug('Matched agent to Insert: ' + salesAgentMap.get(currentSAAId).nextUp__c);
                        leadRecord.AssignedtoSAA__c = true;
                        salesAgentMap.get(currentSAAId).Current_Number_of_Open_Leads_Opps__c++;
                        updatedLeads.add(leadRecord);
                        
                        if(ApplicationConstant.LEAD_STATUS_CONTACT_ATTEMPTED.equals(leadRecord.Status) && leadRecord.Diarydate__c != null && 
                            ApplicationConstant.setStringToDateFormat(String.valueOf(leadRecord.Diarydate__c)) <= Date.today()){
                            salesAgentMap.get(currentSAAId).Current_Items_Diarised_Today__c++;
                        }
                    }
                }
            }
            
            if(!assignOldestOppByAgent.isEmpty()){
                System.debug('doSAAMatching --- Start Matching with Account Opportunities');
                Map<String, Map<Id, Sales_Agent_Attributes__c>> leadWithSalesAgentMap = simplifyMapOfLeadToSetOfAgents(leadAgentMatches, salesAgentMap);
                Map<String, Id> leadMatches = matchAgentWithOldestAccountOpp(assignOldestOppByAgent, leadAgentMatches, salesAgentMap, leadWithSalesAgentMap);
                
                for(Lead leadRecord : assignOldestOppByAgent){
                    leadIdentifier = leadRecord.LastName+leadRecord.FirstName+leadRecord.Company+leadRecord.Status+leadRecord.LeadSource+leadRecord.Email+leadRecord.Phone+leadRecord.Rating+leadRecord.SalesRegion__c+leadRecord.Id;
                    saaIndex = -1;
                    currentSAAId = null;
                    
                    if(leadMatches.containsKey(leadIdentifier) && leadMatches.get(leadIdentifier) != null){
                        currentSAAId = leadMatches.get(leadIdentifier);
                    }
                    else{
                        matchedIdSet =  new Set<Id>();
                        matchedIdSet.addAll(leadAgentMatches.get(leadIdentifier));
                        maxReached = new List<Integer>();
                        saaIndex = findAvailableSaa(matchedIdSet, salesAgentMap, teamAgentsMap, teamMap.get(leadIdentifier), maxReached, agentsToUpdate);
                        if(saaIndex != -1){
                            currentSAAId = teamAgentsMap.get(teamMap.get(leadIdentifier)).get(saaIndex);
                        }
                        
                        if(!maxReached.isEmpty()){
                            maxReached.sort();
                            
                            for(Integer i = maxReached.size()-1; i >= 0; i--){
                                teamAgentsMap.get(teamMap.get(leadIdentifier)).remove(maxReached[i]);
                            }
                        }
                    }
                    
                    if(!String.isEmpty(currentSAAId)){
                        leadRecord.OwnerId = salesAgentMap.get(currentSAAId).Sales_Rep__c;
                        leadRecord.AssignedtoSAA__c = true;
                        salesAgentMap.get(currentSAAId).Current_Number_of_Open_Leads_Opps__c++;
                        updatedLeads.add(leadRecord);
                        
                        if(ApplicationConstant.LEAD_STATUS_CONTACT_ATTEMPTED.equals(leadRecord.Status) && leadRecord.Diarydate__c != null && 
                            ApplicationConstant.setStringToDateFormat(String.valueOf(leadRecord.Diarydate__c)) <= Date.today()){
                            salesAgentMap.get(currentSAAId).Current_Items_Diarised_Today__c++;
                        }
                    }
                }
            }
            
            if(!assignToQueue.isEmpty()){
                updatedLeads.addAll(assignLeadsToQueue(assignToQueue, teamMap));
            }
            
            if(!agentsToUpdate.isEmpty()){
                Database.SaveResult[] salesAgentToUpdate = Database.update(agentsToUpdate.values(), false);
                logs.addAll(ApplicationConstant.getSaveResultLog(salesAgentToUpdate, 'doSAAMatching()', CLASS_NAME, 'Sales Agent Attribute', 'Update'));
            }
        }catch(Exception e){
            logs.add(ApplicationConstant.getExceptionLog(e, 'doSAAMatching()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
        
        System.debug('doSAAMatching --- End');
        return updatedLeads;
    }
    
    /**
       *  This method retrieves and return a Map of Sales Agent Attribute records.
       *  @name: retrieveSalesAgentAttribute
       *  @developer: Recuerdo Bregente
       *  @history: Jerome To (ACN) - May 27, 2016 - removed record type filter for Sales manager (RecordType.Name = :ApplicationConstant.USP_SALES_MANAGER)
     */
    public static Map<Id, Sales_Agent_Attributes__c> retrieveSalesAgentAttribute(){

        Map<Id, Sales_Agent_Attributes__c> salesAgentMap = 
                         new Map<Id, Sales_Agent_Attributes__c>([SELECT CLV_threshold__c, Product_Knowledge__c, Sales_Rep__c, id, name, Online__c, Team__c, nextUp__c,
                         Current_Number_of_Open_Leads_Opps__c, Max_Number_of_Open_Leads_Opportunities__c, Min_CLV_Threshold__c, Sales_Rep__r.lastName, Current_Items_Diarised_Today__c,
                         Max_Items_Diarised_Today__c FROM Sales_Agent_Attributes__c WHERE Sales_Rep__c != null AND 
                         Sales_Agent_ID__c != null AND Current_Number_of_Open_Leads_Opps__c != null AND Max_Items_Diarised_Today__c != null AND
                         RecordType.Name = :ApplicationConstant.LEAD_SALES_AGENT AND
                         Max_Number_of_Open_Leads_Opportunities__c != null Order By Name ASC]);
        
        return salesAgentMap;            
    }
    
    /**
       *  This method retrieves and return a Map of Sales Agent Attribute records.
       *  @name: retrieveSalesAgentAttribute
       *  @developer: Recuerdo Bregente
       *  @param: leads - lead records to use in matching with Sales Agent Attribute records
       *  @param: agents - Sales Agent Attribute records to use for matching with lead records
       *  @param: teamMap - Mappings between lead and queue
     */
    public static Map<String, List<Id>> findMatches(List<Lead> leads, Map<Id, Sales_Agent_Attributes__c> agents, Map<String, String> teamMap){
        System.debug('findMatches --- Start');
        Map<String, List<Id>> leadAgentMatches = new Map<String, List<Id>>();
        
        Map<Id, User> activeUsers = new Map<Id, User>([SELECT Id FROM User WHERE IsActive = true]);
        String leadIdentifier;
        
        for(Lead leadRecord : leads){
            leadIdentifier = leadRecord.LastName+leadRecord.FirstName+leadRecord.Company+leadRecord.Status+leadRecord.LeadSource+leadRecord.Email+leadRecord.Phone+leadRecord.Rating+leadRecord.SalesRegion__c+leadRecord.Id;
            
            if(!leadAgentMatches.containsKey(leadIdentifier)){
                leadAgentMatches.put(leadIdentifier, new List<Id>());
            }
            
            if(leadRecord.CustomerLifetimeValue__c == null){
                leadRecord.CustomerLifetimeValue__c = 0;
            }
            
            for(Sales_Agent_Attributes__c agentRecord : agents.values()){
                if(agentRecord.Current_Items_Diarised_Today__c == null){
                    agentRecord.Current_Items_Diarised_Today__c = 0;
                    agents.get(agentRecord.Id).Current_Items_Diarised_Today__c = 0;
                }
                
                if(teamMap.containsKey(leadIdentifier) && !String.isEmpty(agentRecord.Team__c) && teamMap.get(leadIdentifier) != null && 
                     agentRecord.Team__c.contains(teamMap.get(leadIdentifier)) && 
                     (String.isEmpty(leadRecord.CountriesInterested__c) || (!String.isEmpty(leadRecord.CountriesInterested__c) && agentRecord.Product_Knowledge__c != null && 
                     compareMultiSelect(leadRecord.CountriesInterested__c, agentRecord.Product_Knowledge__c))) && 
                     agentRecord.Current_Number_of_Open_Leads_Opps__c < agentRecord.Max_Number_of_Open_Leads_Opportunities__c && 
                     agentRecord.Min_CLV_Threshold__c <= leadRecord.CustomerLifetimeValue__c && agentRecord.Online__c && 
                     leadRecord.CustomerLifetimeValue__c <= agentRecord.CLV_threshold__c && 
                     agentRecord.Max_Items_Diarised_Today__c > agentRecord.Current_Items_Diarised_Today__c && 
                     activeUsers.containsKey(agentRecord.Sales_Rep__c)){
                     System.debug('Match Found: ' + agentRecord.Name);
                     leadAgentMatches.get(leadIdentifier).add(agentRecord.Id);
                }
            }
        }
        
        System.debug(LoggingLevel.INFO , 'findMatches --- End: ' + leadAgentMatches);
        return leadAgentMatches;            
    }
    
    /**
       *  This method maps the team base on the lead record's region and size.
       *  @name: mapTeamByRegionAndSize
       *  @developer: Recuerdo Bregente
       *  @param: leads - lead records to use for team mapping
       *  2016-11-30 : SM : Now using a custom setting to determing travel group size to group mapping
     */
    public static Map<String, String> mapTeamByRegionAndSize(List<Lead> leads){
        System.debug('mapTeamByRegionAndSize --- Start');
        Map<String, String> teamMap = new Map<String, String>();
        String team;
        String leadIdentifier;
        
        //Pull in and process TeamTravelGroupSize__c custom settings
        Map<String, List<TeamTravelGroupSize__c>> ttgsMapToList = new Map<String, List<TeamTravelGroupSize__c>>();
        Map<String, TeamTravelGroupSize__c> ttgsMap = TeamTravelGroupSize__c.getAll();
         
        for (String s : ttgsMap.keySet()){
             List<TeamTravelGroupSize__c> ttList;
             if (ttgsMapToList.containsKey(s)){
                 ttList = ttgsMapToList.get(s);
                 ttList.add(ttgsMap.get(s));
                 ttgsMapToList.put(s, ttList);
             }else {
                 ttList = new List<TeamTravelGroupSize__c>();
                 ttList.add(ttgsMap.get(s));
                 ttgsMapToList.put(s, ttList);
             }
        } 
        
        for(Lead leadRecord : leads){
             leadIdentifier = leadRecord.LastName+leadRecord.FirstName+leadRecord.Company+leadRecord.Status+leadRecord.LeadSource+leadRecord.Email+leadRecord.Phone+leadRecord.Rating+leadRecord.SalesRegion__c+leadRecord.Id;
             
             /*  THIS will be the new code for Custom Setting processing
             List<TeamTravelGroupSize__c> ttList = ttgsMapToList.get(leadRecord.SalesRegion__c);
             system.debug('*** -- ttList for ' + leadRecord.SalesRegion__c + ' = ' + ttList + ' -- ***');
             
             if (null != ttList){
                 for (TeamTravelGroupSize__c t : ttList){
                     system.debug('*** -- TGS = ' + leadRecord.TravelGroupSize__c + ' -- ***');
                     system.debug('*** -- Min = ' + t.Minimum_Size__c + ' -- ***');
                     system.debug('*** -- Max = ' + t.Maximum_Size__c + ' -- ***');
                     if (leadRecord.TravelGroupSize__c >= t.Minimum_Size__c && leadRecord.TravelGroupSize__c <= t.Maximum_Size__c){
                         team = t.Name;
                         break;
                     }
                 }
             }else {
                 if(leadRecord.SalesRegion__c == ApplicationConstant.SALESREGIONGROUP_MIDHAUL){
                     team = ApplicationConstant.ROW_MID_HAUL_TEAM;
                 } else if(leadRecord.SalesRegion__c == ApplicationConstant.SALESREGIONGROUP_LONGHAUL){
                     team = ApplicationConstant.ROW_LONG_HAUL_TEAM;
                 } else if(leadRecord.SalesRegion__c == ApplicationConstant.SALESREGIONGROUP_USA){//[IMA 0420] Changed from ROW - FDP to USA
                     team = ApplicationConstant.US_TEAM;//[IMA 0420] Changed from S- ROW - FDP Sales Team TO S- USA Sales Team
                 }
             }
             */
             
             //THIS code will eventually be replaced by the code above with custom settings
             if(leadRecord.SalesRegion__c == ApplicationConstant.SALESREGIONGROUP_EUROPE && leadRecord.TravelGroupSize__c >= 9){
                 team = ApplicationConstant.EUROPE_8_TEAM;
             } else if(leadRecord.SalesRegion__c == ApplicationConstant.SALESREGIONGROUP_EUROPE && leadRecord.TravelGroupSize__c <= 8){
                        team = ApplicationConstant.EUROPE_0_7_TEAM;
             } else if(leadRecord.SalesRegion__c == ApplicationConstant.SALESREGIONGROUP_UK_IRELAND && leadRecord.TravelGroupSize__c >= 9){
                        team = ApplicationConstant.UK_AND_IRELAND_9_TEAM;
             } else if(leadRecord.SalesRegion__c == ApplicationConstant.SALESREGIONGROUP_UK_IRELAND && leadRecord.TravelGroupSize__c <= 8){
                        team = ApplicationConstant.UK_AND_IRELAND_0_8_TEAM;
             } else if(leadRecord.SalesRegion__c == ApplicationConstant.SALESREGIONGROUP_MIDHAUL){
                        team = ApplicationConstant.ROW_MID_HAUL_TEAM;
             } else if(leadRecord.SalesRegion__c == ApplicationConstant.SALESREGIONGROUP_LONGHAUL){
                        team = ApplicationConstant.ROW_LONG_HAUL_TEAM;
             } else if(leadRecord.SalesRegion__c == ApplicationConstant.SALESREGIONGROUP_USA){//[IMA 0420] Changed from ROW - FDP to USA
                        team = ApplicationConstant.US_TEAM;//[IMA 0420] Changed from S- ROW - FDP Sales Team TO S- USA Sales Team
             }
             
             System.debug('mapTeamByRegionAndSize --- Lead: ' + leadRecord.LastName + ' team: ' +team);
             teamMap.put(leadIdentifier, team);
        }
        
        System.debug('mapTeamByRegionAndSize --- End');
        return teamMap;            
    }
    
    /**
       *  This method checks if two multiselect values are equal.
       *  @name: compareMultiSelect
       *  @developer: Recuerdo Bregente
       *  @param: String, String
     */
     public static Boolean compareMultiSelect(String multiSelect1, String multiSelect2){
         Boolean isEqual = true;
         String[] tempString;
         if(multiSelect1.contains(';')){
             tempString = multiSelect1.split(';');
         }
         else{
             tempString = new String[]{multiSelect1};
         }
         
         for(String value : tempString){
             if(!multiSelect2.contains(value)){
                 isEqual = false;
                 break;
             }
         }
         
         return isEqual;
     }
     
     /**
       *  This method retrieves the matching of Leads and Sales Agent Attribute with the oldest opportunity.
       *  @name: matchAgentWithOldestAccountOpp
       *  @developer: Recuerdo Bregente
       *  @param: Leads - Lead records with multiple matches to Sales Agent Attribute records
       *  @param: leadAgentMatches - Contains the mappings of lead with multiple Sales Agent Attribute matches
       *  @param: salesAgentMap - Sales Agent records to use in referencing the sales agent with ownerId of the Opportunity
     */
     public static Map<String, Id> matchAgentWithOldestAccountOpp(List<Lead> leads,
                                                       Map<String, List<Id>> leadAgentMatches,
                                                       Map<Id, Sales_Agent_Attributes__c> salesAgentMap,
                                                       Map<String, Map<Id, Sales_Agent_Attributes__c>> leadWithSalesAgentMap){
         System.debug('matchAgentWithOldestAccountOpp --- Start');
                                                       
         Map<String, Id> leadAgentMap = new Map<String, Id>();
         String leadIdentifier;
         
         Map<Id, List<Opportunity>> accountIdOpportunityListMap = retrieveAccountOpportunity(leads);
         Id agentId = null;
         
         for(Lead leadRecord : leads){
             leadIdentifier = leadRecord.LastName+leadRecord.FirstName+leadRecord.Company+leadRecord.Status+leadRecord.LeadSource+leadRecord.Email+leadRecord.Phone+leadRecord.Rating+leadRecord.SalesRegion__c+leadRecord.Id;
             
             if(!leadAgentMap.containsKey(leadIdentifier)){
                 leadAgentMap.put(leadIdentifier, null);
             }
             
             if(accountIdOpportunityListMap.containsKey(leadRecord.Account__c) && !accountIdOpportunityListMap.get(leadRecord.Account__c).isEmpty()){
                 for(Opportunity oppRecord : accountIdOpportunityListMap.get(leadRecord.Account__c)){
                     System.debug('OppName: ' + oppRecord.Name + ' Created Date: ' + oppRecord.CreatedDate + ' Owner: ' + oppRecord.OwnerId);
                     if(leadWithSalesAgentMap.containsKey(leadIdentifier) && leadWithSalesAgentMap.get(leadIdentifier).containsKey(oppRecord.OwnerId)){
                         agentId = leadWithSalesAgentMap.get(leadIdentifier).get(oppRecord.OwnerId).Id;
                         if(salesAgentMap.get(agentId).Current_Number_of_Open_Leads_Opps__c < salesAgentMap.get(agentId).Max_Number_of_Open_Leads_Opportunities__c &&
                             salesAgentMap.get(agentId).Current_Items_Diarised_Today__c < salesAgentMap.get(agentId).Max_Items_Diarised_Today__c){
                             
                             leadAgentMap.put(leadIdentifier, leadWithSalesAgentMap.get(leadIdentifier).get(oppRecord.OwnerId).Id);
                             System.debug('matchAgentWithOldestAccountOpp --- Opportunity Found');
                             break;
                         }
                     }
                     System.debug('matchAgentWithOldestAccountOpp --- Opportunity Not Found');
                 }
             }    
         }
         
         System.debug('matchAgentWithOldestAccountOpp --- End');
         return leadAgentMap;
     }
     
     /**
       *  This method retrieves the opportunityRecords of an account.
       *  @name: retrieveAccountOpportunity
       *  @developer: Recuerdo Bregente
       *  @param: leads - Lead records to lookup Account Opportunities
     */
     public static Map<Id, List<Opportunity>> retrieveAccountOpportunity(List<Lead> leads){
        
        Set<Id> accountIdSet = new Set<Id>();
        for(Lead leadRecord : leads){
            accountIdSet.add(leadRecord.Account__c);
        }
     
        Map<Id, List<Opportunity>> accountIdOpportunityListMap = new Map<Id, List<Opportunity>>();
         
        for(Opportunity oppo : [SELECT id, name, AccountId, OwnerId, CreatedDate FROM Opportunity WHERE AccountId IN: accountIdSet ORDER BY CreatedDate ASC]){
            if(!accountIdOpportunityListMap.containsKey(oppo.AccountId)){
                accountIdOpportunityListMap.put(oppo.AccountId, new List<Opportunity>());
            }
            
            accountIdOpportunityListMap.get(oppo.AccountId).add(oppo);
        }
        
        return accountIdOpportunityListMap;
     }
     
     /**
       *  This method simpliefies the mappings between Leads and Sales Agent Attributes.
       *  @name: simplifyMapOfLeadToSetOfAgents
       *  @developer: Recuerdo Bregente
       *  @param: leadAgentMatches - Map to be simplified
       *  @param: salesAgentMap - Map of Sales agent to be used as reference for Agent User Id
     */
     public static Map<String, Map<Id, Sales_Agent_Attributes__c>> simplifyMapOfLeadToSetOfAgents(Map<String, List<Id>> leadAgentMatches,
                                                                                                     Map<Id, Sales_Agent_Attributes__c> salesAgentMap){
        
        Map<String, Map<Id, Sales_Agent_Attributes__c>> simplifiedMap = new Map<String, Map<Id, Sales_Agent_Attributes__c>>();
        
        for(String key : leadAgentMatches.keySet()){
            if(!leadAgentMatches.get(key).isEmpty() && leadAgentMatches.get(key).size() > 1){
                for(Id idTemp : leadAgentMatches.get(key)){
                    if(!simplifiedMap.containsKey(key)){
                        simplifiedMap.put(key, new Map<Id, Sales_Agent_Attributes__c>());
                    }
                    
                    simplifiedMap.get(key).put(salesAgentMap.get(idTemp).Sales_Rep__c, salesAgentMap.get(idTemp));
                }
            }
        }
        
        return simplifiedMap;
     }
     
     /**
       *  This method assigns leads to queue.
       *  @name: assignLeadsToQueue
       *  @developer: Recuerdo Bregente
       *  @param: leads - Leads to be assign to queues
       *  @param: teamMap - Mapping of Leads to Queue Name
     */
     public static List<Lead> assignLeadsToQueue(List<Lead> leads, Map<String, String> teamMap){
        System.debug('assignLeadsToQueue --- Start');
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Map<String, Id> teamNameIdMap = new Map<String, Id>();
        List<Lead> updatedLeads = new List<Lead>();
        
        try{
            for(Group teamQueue : [SELECT Id, Name FROM Group WHERE Name IN :teamMap.values() AND Type = 'Queue']){
                teamNameIdMap.put(teamQueue.Name, teamQueue.Id);
            }
            String leadIdentifier;
            
            for(Lead leadRecord : leads){
                leadIdentifier = leadRecord.LastName+leadRecord.FirstName+leadRecord.Company+leadRecord.Status+leadRecord.LeadSource+leadRecord.Email+leadRecord.Phone+leadRecord.Rating+leadRecord.SalesRegion__c+leadRecord.Id;
                if(teamMap.containsKey(leadIdentifier) && !ApplicationConstant.US_TEAM.equals(teamMap.get(leadIdentifier)) && 
                    teamNameIdMap.containsKey(teamMap.get(leadIdentifier))){
                    leadRecord.OwnerId = teamNameIdMap.get(teamMap.get(leadIdentifier));
                    leadRecord.AssignedtoSAA__c = false;
                    updatedLeads.add(leadRecord);
                }
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'assignLeadsToQueue()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
        
        System.debug('assignLeadsToQueue --- End');
        return updatedLeads;
     }
     
     /**
       *  This method assigns Specialist Sales Team's agent to Specialist Sales Lead.
       *  @name: assignSpecialistTeam
       *  @developer: Recuerdo Bregente
       *  @param: leads - Lead records to be checked and be assigned to Specialist Sales Agent
     */
    public static List<Lead> assignSpecialistTeam(List<Lead> leads, Boolean isFromTrigger){
        System.debug('assignSpecialistTeam --- Start');
        List<Error_Log__c> logs = new List<Error_Log__c>();
        List<Lead> updatedLeads = new List<Lead>();
        Map<Id, Sales_Agent_Attributes__c> agentsToUpdate = new Map<Id, Sales_Agent_Attributes__c>();
        Set<Id> saaIds = new Set<Id>();
        Map<String, List<Id>> teamAgentsMap = new Map<String, List<Id>>();
        List<Integer> maxReached = new List<Integer>();
        Integer index;
        
        try{
            Map<Id, Sales_Agent_Attributes__c> salesAgentList = new Map<Id, Sales_Agent_Attributes__c>
                             ([SELECT Sales_Rep__c, Current_Number_of_Open_Leads_Opps__c, Max_Number_of_Open_Leads_Opportunities__c, Name, Current_Items_Diarised_Today__c, 
                             Max_Items_Diarised_Today__c, nextUp__c  
                             FROM Sales_Agent_Attributes__c WHERE Sales_Agent_ID__c != null AND Current_Number_of_Open_Leads_Opps__c != null AND 
                             Online__c = true AND (RecordType.Name = :ApplicationConstant.LEAD_SALES_AGENT OR 
                             RecordType.Name = :ApplicationConstant.USP_SALES_MANAGER) AND 
                             Team__c INCLUDES (:ApplicationConstant.LEAD_SPC_SALESTEAM) AND 
                             Max_Number_of_Open_Leads_Opportunities__c != null Order By Name ASC]);
                             
            
            List<Group> specialistGroup = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND 
                                            Name = :ApplicationConstant.LEAD_SPC_SALESTEAM];
            
            Id currentSAAId;
            Map<Id, Sales_Agent_Attributes__c> agentsToIncrement = new Map<Id, Sales_Agent_Attributes__c>();
            for(Lead leadRecord : leads){
                index = -1;
                currentSAAId = null;
                
                if(!salesAgentList.isEmpty()){
                    System.debug('assignSpecialistTeam --- salesAgentList.keySet(): ' + salesAgentList.keySet());
                    saaIds = salesAgentList.keySet();
                    teamAgentsMap.put(ApplicationConstant.LEAD_SPC_SALESTEAM, new List<Id>());
                    teamAgentsMap.get(ApplicationConstant.LEAD_SPC_SALESTEAM).addAll(saaIds);
                    maxReached = new List<Integer>();
                    index = findAvailableSaa(saaIds, salesAgentList, teamAgentsMap, ApplicationConstant.LEAD_SPC_SALESTEAM, maxReached, agentsToUpdate);
                    if(index != -1){
                        currentSAAId = teamAgentsMap.get(ApplicationConstant.LEAD_SPC_SALESTEAM).get(index);
                    }
                    
                    if(!maxReached.isEmpty()){
                        maxReached.sort();
                            
                        for(Integer i = maxReached.size()-1; i >= 0; i--){
                            teamAgentsMap.get(ApplicationConstant.LEAD_SPC_SALESTEAM).remove(maxReached[i]);
                        }
                    }
                }    
                
                if(!String.isEmpty(currentSAAId)){
                    leadRecord.OwnerId = salesAgentList.get(currentSAAId).Sales_Rep__c;
                    leadRecord.AssignedtoSAA__c = true;
                    updatedLeads.add(leadRecord);
                    
                    salesAgentList.get(currentSAAId).Current_Number_of_Open_Leads_Opps__c++;
                    
                    if(salesAgentList.get(currentSAAId).Current_Number_of_Open_Leads_Opps__c >= salesAgentList.get(currentSAAId).Max_Number_of_Open_Leads_Opportunities__c){
                        salesAgentList.remove(currentSAAId);
                    }
                    
                    currentSAAId = null;
                }
                else{
                    if(!specialistGroup.isEmpty()){
                        leadRecord.OwnerId = specialistGroup[0].Id;
                        leadRecord.AssignedtoSAA__c = false;
                        updatedLeads.add(leadRecord);
                    }
                }
            }
            
            if(!agentsToUpdate.isEmpty()){
                Database.SaveResult[] salesAgentToUpdate = Database.update(agentsToUpdate.values(), false);
                logs.addAll(ApplicationConstant.getSaveResultLog(salesAgentToUpdate, 'assignSpecialistTeam()', CLASS_NAME, 'Sales Agent Attribute', 'Update'));
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'assignSpecialistTeam()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
        
        System.debug('assignSpecialistTeam --- End');
        return updatedLeads;            
    }
    
    /**
       *  This method filters only Queued assigned Leads.
       *  @name: filterQueuedLeads
       *  @developer: Recuerdo Bregente
       *  @param: leads - Lead records to be filtered.
     */
     public static List<Lead> filterQueuedLeads(List<Lead> leads){
        System.debug('filterQueuedLeads --- Start');
        List<Lead> filteredLeads = new List<Lead>();
        Map<Id, Group> queueMap = new Map<Id, Group>([SELECT Id, Name FROM GROUP WHERE Name IN :ApplicationConstant.TEAM_SET AND Type = 'Queue']);
        for(Lead leadRecord : leads){
            if(queueMap.containsKey(leadRecord.OwnerId)){
                if(leadRecord.CustomerLifetimeValue__c == null){
                    leadRecord.CustomerLifetimeValue__c = 0;
                }
                filteredLeads.add(leadRecord);
            }
        }
        
        System.debug('filterQueuedLeads --- End');
        return filteredLeads;
     }
     
     /**
       *  This method assigns leads to unknown sales team.
       *  @name: assignToUnknownSalesTeam
       *  @developer: Recuerdo Bregente
       *  @param: leads - Lead records to be assigned to unknown sales team.
     */
     public static List<Lead> assignToUnknownSalesTeam(List<Lead> leads){
        System.debug('assignToUnknownSalesTeam --- Start');
        List<Error_Log__c> logs = new List<Error_Log__c>();
        List<Lead> unknownLeadsTeam = new List<Lead>();
        List<Group> unknownQueue = [SELECT Id, Name FROM GROUP WHERE Name = :ApplicationConstant.UNKNOWN_SALES_TEAM AND Type = 'Queue'];
        
        try{
            if(!unknownQueue.isEmpty()){
                for(Lead leadRecord : leads){
                    leadRecord.OwnerId = unknownQueue[0].Id;
                    leadRecord.AssignedtoSAA__c = false;
                    unknownLeadsTeam.add(leadRecord);
                }
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'assignToUnknownSalesTeam()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
        System.debug('assignToUnknownSalesTeam --- End');
        return unknownLeadsTeam;
     }
     
     /**
       *  This method assigns leads to returning traveller sales team.
       *  @name: assignToReturningTravellerSalesTeam
       *  @developer: Recuerdo Bregente
       *  @param: leads - Lead records to be assigned to returning traveller sales team.
     */
     public static List<Lead> assignToReturningTravellerSalesTeam(List<Lead> leads){
        System.debug('assignToReturningTravellerSalesTeam --- Start');
        List<Error_Log__c> logs = new List<Error_Log__c>();
        List<Lead> returningLeads = new List<Lead>();
        List<Group> returningQueue = [SELECT Id, Name FROM GROUP WHERE Name = :ApplicationConstant.RETURNING_TRAVELLER_TEAM AND Type = 'Queue'];
        
        try{
            if(!returningQueue.isEmpty()){
                for(Lead leadRecord : leads){
                    leadRecord.OwnerId = returningQueue[0].Id;
                    leadRecord.AssignedtoSAA__c = false;
                    returningLeads.add(leadRecord);
                }
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'assignToReturningTravellerSalesTeam()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
        System.debug('assignToReturningTravellerSalesTeam --- End');
        return returningLeads;
     }
     
     /**
       *  This method finds an available Saa with open Leads and Opportunities not greater than max.
       *  @name: findAvailableSaa
       *  @developer: Recuerdo Bregente
       *  @param: saaIds - Ids of matched Sales Agents.
       *  @param: salesAgentMap - Mapping of Ids and Sales Agent Attribute records.
     */
     public static Integer findAvailableSaa(Set<Id> saaIds, Map<Id, Sales_Agent_Attributes__c> salesAgentMap, Map<String, List<Id>> teamAgentsMap, String teamName, List<Integer> maxReached, Map<Id, Sales_Agent_Attributes__c> agentsToUpdate){
        System.debug('findAvailableSaa --- Start');
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Integer indexCounter = 0;
        Integer startIndex = -1;
        Integer saaIndex = -1;
        Boolean saaIsfound = false;
        Boolean beginAgain = false;
        
        try{
            
            if(!String.isEmpty(teamName) && !teamAgentsMap.get(teamName).isEmpty() && !saaIds.isEmpty()){
                System.debug('findAvailableSaa --- start first loop: ' + teamAgentsMap.get(teamName).size());
                for(Id teamSaaId : teamAgentsMap.get(teamName)){
                    System.debug('findAvailableSaa --- currentRec: ' + salesAgentMap.get(teamSaaId).Name + ' at index: ' + indexCounter);
                    
                    if(startIndex == -1 && salesAgentMap.get(teamSaaId).nextUp__c){
                            System.debug('findAvailableSaa --- first nextUp equal to true: ' + salesAgentMap.get(teamSaaId).Name + ' index:' + indexCounter);
                            startIndex = indexCounter;
                    }
                    
                    if(saaIds.contains(teamSaaId) && salesAgentMap.containsKey(teamSaaId)){
                        if(salesAgentMap.get(teamSaaId).Current_Number_of_Open_Leads_Opps__c < 
                            salesAgentMap.get(teamSaaId).Max_Number_of_Open_Leads_Opportunities__c){
                            if(salesAgentMap.get(teamSaaId).Current_Items_Diarised_Today__c < salesAgentMap.get(teamSaaId).Max_Items_Diarised_Today__c && 
                                salesAgentMap.get(teamSaaId).nextUp__c && !saaIsfound){
                                salesAgentMap.get(teamSaaId).nextUp__c = false;
                                agentsToUpdate.put(teamSaaId, salesAgentMap.get(teamSaaId));
                                saaIsfound = true;
                                saaIndex = indexCounter;
                                beginAgain = true;
                                System.debug('SELECTED AGENT: ' + salesAgentMap.get(teamSaaId).Name + 'at Index: ' + saaIndex);
                            }
                        }
                        else{
                            maxReached.add(indexCounter);
                        }
                    }
                    
                    if(startIndex != -1){
                        if(salesAgentMap.get(teamSaaId).nextUp__c){
                            salesAgentMap.get(teamSaaId).nextUp__c = false;
                            agentsToUpdate.put(teamSaaId, salesAgentMap.get(teamSaaId));
                        }
                        
                        if(indexCounter < teamAgentsMap.get(teamName).size() -1){
                            salesAgentMap.get(teamAgentsMap.get(teamName).get(indexCounter+1)).nextUp__c = true;
                            agentsToUpdate.put(teamAgentsMap.get(teamName).get(indexCounter+1), salesAgentMap.get(teamAgentsMap.get(teamName).get(indexCounter+1)));
                        }
                    }
                    
                    if(indexCounter+1 == teamAgentsMap.get(teamName).size()){
                        salesAgentMap.get(teamAgentsMap.get(teamName).get(0)).nextUp__c = true;
                        agentsToUpdate.put(teamAgentsMap.get(teamName).get(0), salesAgentMap.get(teamAgentsMap.get(teamName).get(0)));
                    }
                    if(saaIsfound){
                        break;
                    }
                    else if(startIndex == -1 && indexCounter+1 == teamAgentsMap.get(teamName).size()){
                        startIndex = indexCounter;
                    }
                    
                    indexCounter++;
                }
                System.debug('findAvailableSaa --- end first loop');
                
                if(!saaIsfound && startIndex > 0){
                    System.debug('findAvailableSaa --- start 2nd loop, End Index: '+ startIndex);
                    for(Integer i = 0; i < teamAgentsMap.get(teamName).size() && i < startIndex; i++){
                        System.debug('findAvailableSAA --- currentRecord: ' +salesAgentMap.get(teamAgentsMap.get(teamName)[i]).Name);
                        if(saaIds.contains(teamAgentsMap.get(teamName)[i]) && salesAgentMap.containsKey(teamAgentsMap.get(teamName)[i])){
                            if(salesAgentMap.get(teamAgentsMap.get(teamName)[i]).Current_Number_of_Open_Leads_Opps__c < 
                                salesAgentMap.get(teamAgentsMap.get(teamName)[i]).Max_Number_of_Open_Leads_Opportunities__c){
                                if(salesAgentMap.get(teamAgentsMap.get(teamName)[i]).Current_Items_Diarised_Today__c < salesAgentMap.get(teamAgentsMap.get(teamName)[i]).Max_Items_Diarised_Today__c && 
                                    salesAgentMap.get(teamAgentsMap.get(teamName)[i]).nextUp__c && !saaIsfound){
                                    salesAgentMap.get(teamAgentsMap.get(teamName)[i]).nextUp__c = false;
                                    agentsToUpdate.put(teamAgentsMap.get(teamName)[i], salesAgentMap.get(teamAgentsMap.get(teamName)[i]));
                                    saaIsfound = true;
                                    saaIndex = i;
                                    beginAgain = true;
                                    System.debug('SELECTED AGENT: ' + salesAgentMap.get(teamAgentsMap.get(teamName)[i]).Name);
                                }
                            }
                        }
                        
                        if(!saaIsfound && salesAgentMap.get(teamAgentsMap.get(teamName)[i]).nextUp__c){
                            salesAgentMap.get(teamAgentsMap.get(teamName)[i]).nextUp__c = false;
                            agentsToUpdate.put(teamAgentsMap.get(teamName)[i], salesAgentMap.get(teamAgentsMap.get(teamName)[i]));
                        }
                        
                        if(i < teamAgentsMap.get(teamName).size() -1){
                            salesAgentMap.get(teamAgentsMap.get(teamName).get(i+1)).nextUp__c = true;
                            agentsToUpdate.put(teamAgentsMap.get(teamName).get(i+1), salesAgentMap.get(teamAgentsMap.get(teamName).get(i+1)));
                        }
                        else if(teamAgentsMap.get(teamName).size() > 0){
                            salesAgentMap.get(teamAgentsMap.get(teamName).get(0)).nextUp__c = true;
                            agentsToUpdate.put(teamAgentsMap.get(teamName).get(0), salesAgentMap.get(teamAgentsMap.get(teamName).get(0)));
                             
                        }
                        
                        if(saaIsfound){
                            break;
                        }
                    }
                    System.debug('findAvailableSaa --- end 2nd loop');
                }
            }
            
            if(saaIndex != -1){
                System.debug('BEFORE find SAA, nextUp: ' + salesAgentMap.get(teamAgentsMap.get(teamName).get(saaIndex)).nextUp__c);
            }
            
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'findAvailableSaa()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
        System.debug('findAvailableSaa --- End, returned index: ' + saaIndex);
        return saaIndex;
     }
     
     /**
       *  This method retrieves a map of Team and Agents.
       *  @name: retrieveTeamAgentsMap
       *  @developer: Recuerdo Bregente
       *  @param: salesAgentMap - Map of Sales Agent Attributes and its Id
     */
     public static Map<String, List<Id>> retrieveTeamAgentsMap(Map<Id, Sales_Agent_Attributes__c> salesAgentMap){
        System.debug('retrieveTeamAgentsMap --- Start');
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Map<String, List<Id>> teamAgentsMap = new Map<String, List<Id>>();
        List<String> teamListPerAgent = new List<String>();
        
        try{
            for(Sales_Agent_Attributes__c saaRec : salesAgentMap.values()){
                teamListPerAgent = new List<String>();
                if(!String.isEmpty(saaRec.Team__c) && saaRec.Team__c.contains(';')){
                    teamListPerAgent.addAll(saaRec.Team__c.split(';'));
                }
                else if(!String.isEmpty(saaRec.Team__c) && !saaRec.Team__c.contains(';')){
                    teamListPerAgent.add(saaRec.Team__c);
                }
                
                if(!teamListPerAgent.isEmpty()){
                    for(String team : teamListPerAgent){
                        if(!String.isEmpty(team)){
                            if(!teamAgentsMap.containsKey(team)){
                                teamAgentsMap.put(team, new List<Id>());
                            }
                            System.debug('retrieveTeamAgentsMap --- team: ' + team + ' saa: ' + saaRec.Name);
                            teamAgentsMap.get(team).add(saaRec.Id);
                        }
                    }
                }    
            }
            
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'retrieveTeamAgentsMap()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
        System.debug('retrieveTeamAgentsMap --- End');
        return teamAgentsMap;
     }
     
     /**
       *  This method assigns leads to cold team.
       *  @name: assignToColdTeam
       *  @developer: Recuerdo Bregente
       *  @param: leads - Lead records to be assigned to cold lead team.
     */
     public static List<Lead> assignToColdTeam(List<Lead> leads){
        System.debug('assignToColdTeam--- Start');
        List<Error_Log__c> logs = new List<Error_Log__c>();
        List<Lead> coldLeads = new List<Lead>();
        List<Group> coldQueue = [SELECT Id, Name FROM GROUP WHERE Name = :ApplicationConstant.COLD_TEAM AND Type = 'Queue'];
        
        try{
            if(!coldQueue.isEmpty()){
                for(Lead leadRecord : leads){
                    leadRecord.OwnerId = coldQueue[0].Id;
                    leadRecord.AssignedtoSAA__c = false;
                    coldLeads.add(leadRecord);
                }
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'assignToColdTeam()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
        System.debug('assignToColdTeam--- End');
        return coldLeads;
     }
     
     /**
       *  This method assigns leads to callback queue.
       *  @name: assignToCustomerCallbackQueue
       *  @developer: Mark Cane
       *  @modification date: 2016-12-03
       *  @param: leads - Lead records to be assigned to Customer Callback Queue.
       *
       * Note : for consistency the coding approach for this method has been aligned to equivalent methods within the class.
       *
     */
     public static List<Lead> assignToCustomerCallbackQueue(List<Lead> leads){
        System.debug('assignToCustomerCallbackQueue--- Start');
        List<Error_Log__c> logs = new List<Error_Log__c>();
        List<Lead> callbackLeads = new List<Lead>();
        
        Map<Id, User> apiUser = new Map<Id, User>([SELECT Id, Name FROM User WHERE Name = :ApplicationConstant.USER_NAME_API_USER]);
        List<Group> callbackQueue = [SELECT Id, Name FROM GROUP WHERE DeveloperName=:CALLBACK_QUEUE_DEVELOPER_NAME AND Type = 'Queue'];
        
        try{
            if(!callbackQueue.isEmpty()){
                for(Lead leadRecord : leads){
                    
                    System.debug('leadRecord---'+leadRecord);
                    System.debug(apiUser.containsKey(leadRecord.OwnerId));
                    
                    if (apiUser.containsKey(leadRecord.OwnerId) &&
                            leadRecord.Customer_Call_Back_Date_Time__c!=null
                             && leadRecord.Customer_Call_Back_Date_Time__c > Datetime.now() // TBD. All API user assigned callback leads must be assigned to the queue. 
                            ){
                    
                        
                        leadRecord.OwnerId = callbackQueue[0].Id;
                        leadRecord.AssignedtoSAA__c = false;
                        callbackLeads.add(leadRecord);
                    }
                }
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'assignToCustomerCallbackQueue()', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
        System.debug('assignToCustomerCallbackQueue--- End');
        return callbackLeads;
     }     
}