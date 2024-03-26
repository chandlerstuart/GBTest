/**
Name:  WithoutSharingUtility.cls
Copyright © 2017  GolfBreaks
======================================================
======================================================
Purpose:
-------
Offers methods that run 'without sharing' for the few exceptions where records need to be updated by those other than the owner
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.0  S.Molloy     2017-01-03   Initial class development
1.1  M.Cane       2018-06-08   Added deleteSObjects method.
1.2  M.Cane       2018-06-13   Added queryShadowOpportunties,queryConvertedOpportunities methods.
**/
public without sharing class WithoutSharingUtility {
    // Used for logging
    public static final String CLASS_NAME = 'WithoutSharingUtility';


    /**
       *  This method is used to get the latest Lead according to its Rating, namely: Hot, Warm, Cold
       *  @name: setLeadIdRating
       *  @developer: Jerella Ledesma
       *  @param: leadToUpdateList - Map of the list of Lead in the afterUpdate transaction 
       *  ORIGINAL SOURCE METHOD - AP04_LeadTriggerBL.setLeadIdRating
       * -------------------------------------------------
       * S.Molloy               09-March-2017   Initial development
    */
    public static void setLeadIdRating(Map<Id, Lead> leadToUpdateList){
        System.debug('WithoutSharingUtility.setLeadIdRating --- Start');
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        //instantiate variables needed.
        Set<Id> leadIdsFromAccount = new Set<Id>();
        Set<Id> accountIdsFromLead = new Set<Id>();
        Map<Id,Account> accountMap = new Map<Id,Account>();
        Map<Id,Account> accountMapToUpdate = new Map<Id,Account>();
        Map<Id,List<Lead>> accountIdToLeads = new Map<Id,List<Lead>>();
        Map<Id,Lead> currentLeadMaponAccount = new Map<Id,Lead>();      
        Account accRec;
        List<Lead> leadRecList;
        Map<Id, DateTime> latestHotLead = new Map<Id, Date>();
        Map<Id, DateTime> latestWarmLead;
        Map<Id, DateTime> latestColdLead;
        Map<Id, DateTime> latestNoRating;
        Id latestId;
        DateTime latestDate;
        
        try{
            //collect all the Account Id of the Leads
            for(Lead leadRecord : leadToUpdateList.values()){
                if(leadRecord.Account__c!=null){
                    accountIdsFromLead.add(leadRecord.Account__c);  
                }
            }   
            System.debug('>>>>>> accountIdsFromLead '+accountIdsFromLead);
            //collect all the Leads of the Account 
            if(accountIdsFromLead.size()>0){
                for(Account acc : [SELECT LeadId__c FROM Account WHERE ID IN :accountIdsFromLead]){
                    accountMap.put(acc.Id, acc);
                    if(acc.LeadId__c!=null){
                        leadIdsFromAccount.add(acc.LeadId__c);
                    }
                }            
            }
            System.debug('>>>>>> leadIdsFromAccount '+leadIdsFromAccount);
            //map of all the Leads
            // if(leadIdsFromAccount.size()>0){
                currentLeadMaponAccount = new Map<Id,Lead>([SELECT Name, Account__c, Rating, CreatedDate, Status FROM Lead WHERE Status <>: ApplicationConstant.LEAD_CLOSED_CONVERTED AND Status <>: ApplicationConstant.LEAD_NO_SALE AND Status <>: ApplicationConstant.LEAD_STATUS_DUPLICATE AND Account__c IN :accountIdsFromLead]);
            // }
            System.debug('>>>>>> currentLeadMaponAccount '+currentLeadMaponAccount);
            //mapping of Account to the Lead records related to it
            for(Lead leadRecord : currentLeadMaponAccount.values()){
                if(accountIdToLeads.containsKey(leadRecord.Account__c)){
                    accountIdToLeads.get(leadRecord.Account__c).add(leadRecord);
                }
                else{
                    accountIdToLeads.put(leadRecord.Account__c, new List<Lead>{leadRecord});
                }
            }
            System.debug('>>>>>> accountIdToLeads '+accountIdToLeads);
            //comparison of the Leads according to its Rating and created date 
            for(Lead leadRecord : leadToUpdateList.values()){
                accRec = new Account();
                leadRecList = new List<Lead>();
                latestHotLead = new Map<Id, DateTime>();
                latestWarmLead = new Map<Id, DateTime>();
                latestColdLead = new Map<Id, DateTime>();
                latestNoRating = new Map<Id, DateTime>();
                    //May 10, 2016 Merari Cebrian Added another condition 
                    if(accountIdToLeads.containsKey(leadRecord.Account__c)) {
                        
                        leadRecList = accountIdToLeads.get(leadRecord.Account__c);
                        system.debug('*** -- leadRecList = ' + leadRecList + ' -- ***');
                        //Leads are separated according to its Rating 
                        for(Lead leadRec : leadRecList){
                            if(leadRec.Rating == ApplicationConstant.LEAD_RATING_HOT){
                                latestHotLead.put(leadRec.Id, leadRec.CreatedDate);
                            }
                            else if(leadRec.Rating == ApplicationConstant.LEAD_RATING_WARM){
                                latestWarmLead.put(leadRec.Id, leadRec.CreatedDate);
                            }
                            else if(leadRec.Rating == ApplicationConstant.LEAD_RATING_COLD){
                                latestColdLead.put(leadRec.Id, leadRec.CreatedDate);
                            }
                            else if(leadRec.Rating == null || leadRec.Rating == ''){
                                latestNoRating.put(leadRec.Id, leadRec.CreatedDate);
                            }
                        }
                        
                        system.debug('*** -- HOT size = ' + latestHotLead.size() + ' -- ***');
                        system.debug('*** -- WARM size = ' + latestWarmLead.size() + ' -- ***');
                        system.debug('*** -- COLD size = ' + latestColdLead.size() + ' -- ***');
                        
                        //If it has a Lead with a 'Hot' rating - it is sorted here
                        if(latestHotLead.size() > 0){
                            for(Id leadId : latestHotLead.keySet()){
                                if(latestId == null && latestDate == null){
                                    latestId = leadId;
                                    latestDate = latestHotLead.get(leadId);
                                }
                                else{
                                    if(latestDate < latestHotLead.get(leadId)){
                                        latestDate = latestHotLead.get(leadId);
                                        latestId = leadId;
                                    }
                                }
                            }
                            accRec = accountMap.get(leadRecord.Account__c);
                            accRec.LeadId__c = latestId;
                            accountMapToUpdate.put(accRec.Id, accRec);
                            
                        }
                        //If there is no Lead with a 'Hot' rating - it proceeds here and it is sorted as well here
                        else if(latestWarmLead.size() > 0){
                            for(Id leadId : latestWarmLead.keySet()){
                                if(latestId == null && latestDate == null){
                                    latestId = leadId;
                                    latestDate = latestWarmLead.get(leadId);
                                }
                                else{
                                    if(latestDate < latestWarmLead.get(leadId)){
                                        latestDate = latestWarmLead.get(leadId);
                                        latestId = leadId;
                                    }
                                }
                            }
                            accRec = accountMap.get(leadRecord.Account__c);
                            accRec.LeadId__c = latestId;
                            accountMapToUpdate.put(accRec.Id, accRec);
                            
                        }
                        //If there is no Lead with a 'Hot' rating or 'Warm' - it proceeds here and it is sorted as well here
                        else if(latestColdLead.size() > 0){
                            for(Id leadId : latestColdLead.keySet()){
                                if(latestId == null && latestDate == null){
                                    latestId = leadId;
                                    latestDate = latestColdLead.get(leadId);
                                }
                                else{
                                    if(latestDate < latestColdLead.get(leadId)){
                                        latestDate = latestColdLead.get(leadId);
                                        latestId = leadId;
                                    }
                                }
                            }
                            accRec = accountMap.get(leadRecord.Account__c);
                            accRec.LeadId__c = latestId;
                            accountMapToUpdate.put(accRec.Id, accRec);
                            
                        }
                        //If it has a Lead with a no rating - it is sorted here
                        else if(latestNoRating.size() > 0){
                            for(Id leadId : latestNoRating.keySet()){
                                if(latestId == null && latestDate == null){
                                    latestId = leadId;
                                    latestDate = latestNoRating.get(leadId);
                                }
                                else{
                                    if(latestDate < latestNoRating.get(leadId)){
                                        latestDate = latestNoRating.get(leadId);
                                        latestId = leadId;
                                    }
                                }
                            }
                            accRec = accountMap.get(leadRecord.Account__c);
                            accRec.LeadId__c = latestId;
                            accountMapToUpdate.put(accRec.Id, accRec);
                            
                        }
                        
                    } else {
                        accRec = accountMap.get(leadRecord.Account__c);
                        if(accRec <> null) {
                            accRec.LeadId__c = '';
                            accountMapToUpdate.put(accRec.Id, accRec);
                        }
                    }
                System.debug('>>>>>> accRec '+accRec);
            } 
            System.debug('>>>>>> accountMapToUpdate '+accountMapToUpdate);
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'setLeadIdRating()', CLASS_NAME, null));
        }finally{
            if(logs.isEmpty() && accountMapToUpdate.size() > 0){
                Database.SaveResult[] updateLeadList = Database.update(accountMapToUpdate.values(), false);
                logs.addAll(ApplicationConstant.getSaveResultLog(updateLeadList, 'setLeadIdRating()', CLASS_NAME, ApplicationConstant.OBJECT_TYPE_ACCOUNT, 'Update'));
            }
        
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
        System.debug('WithoutSharingUtility.setLeadIdRating --- End');
    }

    /**
       *  This method is used to update the CaseId field on Account once a case has been created.
       *  @name: updateCaseIdOnAccount
       *  @developer: Simon Molloy 22/02/2017
       *  @param: caseList - get Trigger.new from CaseTrigger; of List<Case> data type
       *  ORIGINAL SOURCE METHOD - AP02_CaseTriggerBL.cls
       */
    public static void updateCaseIdOnAccount(List<Case> caseList){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Set<Id> accountIdSet = new Set<Id>();  
        List<Account> accountsToUpdate = new List<Account>();
        Set<Id> caseRecordTypeIdFilter = new Set<Id> { ApplicationConstant.CASERECTYPEID_AMENDMENT, ApplicationConstant.CASERECTYPEID_COMPLAINT, ApplicationConstant.CASERECTYPEID_SERVICECASE};
        
        try{  
            for(Case caseRec : caseList){
                if(caseRecordTypeIdFilter.contains(caseRec.RecordTypeId) && caseRec.AccountId != null) {                   
                    accountIdSet.add(caseRec.AccountId);        
                }
            }
    
            for(Account acct : [SELECT Id, CaseId__c,(SELECT Id, CreatedDate FROM Cases WHERE Status !=:ApplicationConstant.CASE_STATUS_CLOSED AND RecordTypeId IN:caseRecordTypeIdFilter ORDER BY CreatedDate desc) FROM Account WHERE Id IN: accountIdSet]){
                acct.CaseId__c = '';
                if(!acct.Cases.isEmpty()){
                    acct.CaseId__c = acct.Cases[0].Id;
                }            
                accountsToUpdate.add(acct);
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'updateCaseIdOnAccount', CLASS_NAME, null));
        }finally{
            if(logs.isEmpty() && accountsToUpdate.size() > 0){
                Database.SaveResult[] updateAccountMap = Database.update(accountsToUpdate, false);
                logs.addAll(ApplicationConstant.getSaveResultLog(updateAccountMap, 'updateCaseIdOnAccount', CLASS_NAME, ApplicationConstant.OBJECT_TYPE_ACCOUNT, 'Update'));
            }
        
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }       
    }


    /** 
    *  This method is used to update Roll up on Monthly Sales targets
    *  ORIGINAL SOURCE - AP06_OpportunityTriggerBL.cls
    *  @name: updateMonthlySalesTargetRollup
    *  @developer: Simon Molloy
    *  @param: List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap
    */  
    public static void updateMonthlySalesTargetRollup(List<Opportunity> newOppList , Map<Id, Opportunity> oldOppMap){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        Set<String> closedWonStageNames = new Set<String> { ApplicationConstant.OPPORTUNITY_STAGENAME_FULL_DEPOSIT, ApplicationConstant.OPPORTUNITY_STAGENAME_FULL_BALANCE, ApplicationConstant.OPPORTUNITY_STAGENAME_TRIP_COMPLETED };
        Map<Id, List<Opportunity>> monthlySalesTargetOpportunityMap = new Map<Id, List<Opportunity>>();      
        Set<Id> monthlySalesTargetIds = new Set<Id>();
        
        try{
            for(Opportunity newOpp : newOppList){
                if (closedWonStageNames.contains(newOpp.Stagename)){
                    if(oldOppMap <> null) {
                        if(!String.isEmpty(newOpp.TECH_Monthly_Sales_Target__c)){
                            monthlySalesTargetIds.add(newOpp.TECH_Monthly_Sales_Target__c);
                        }
                        if(!String.isEmpty(oldOppMap.get(newOpp.Id).TECH_Monthly_Sales_Target__c)){
                            monthlySalesTargetIds.add(oldOppMap.get(newOpp.Id).TECH_Monthly_Sales_Target__c);
                        }
                    }else{
                        if(!String.isEmpty(newOpp.TECH_Monthly_Sales_Target__c)){
                            monthlySalesTargetIds.add(newOpp.TECH_Monthly_Sales_Target__c);
                        }
                    }
                }
            }
            if(!monthlySalesTargetIds.isEmpty()){
                List<Monthly_Sales_Target__c> monthlySalesTargetToUpdate = [SELECT Id, Name FROM Monthly_Sales_Target__c WHERE Id IN: monthlySalesTargetIds];
                update monthlySalesTargetToUpdate;
            }

        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'updateMonthlySalesTargetRollup', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }
    
    /** 
    *  Utility method to enable record deletion outside of Sharing Model constraints.
    *
    *  @name: deleteSObjects
    *  @developer: Mark Cane
    *  @param: List<SObject> recsToDelete: records to be deleted.
    */  
    public static void deleteSObjects(List<SObject> recsToDelete){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        try{            
            
            delete recsToDelete;

        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'deleteSObjects', CLASS_NAME, null));
        }finally{
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }

    /** 
    *  Post convert related.
    *
    *  @name: queryShadowOpportunities
    *  @developer: Mark Cane
    *  @param: Set<Id> leadIds: converted lead Ids.
    */      
    public static Map<Id,Opportunity> queryShadowOpportunities(Set<Id> leadIds, Id rtId){//1.2
        Map<Id,Opportunity> shadowOpps = new Map<Id,Opportunity>();
        
        for (Opportunity o : [select Id, Source_Lead__c, StageName, Amount, 
                                (select Id, Opportunity__c, GrossProfit__c, Status__c from Quotes__r),
                                (select Id, TECH_Opportunity__c from Bookings__r) 
                                from Opportunity where Source_Lead__c in :leadIds AND RecordTypeId = :rtId]){
            if (null != o.Source_Lead__c) shadowOpps.put(o.Source_Lead__c, o);
        }
        return shadowOpps;
    }  
    
    /** 
    *  Post convert related.
    *
    *  @name: queryConvertedOpportunities
    *  @developer: Mark Cane
    *  @param: Set<Id> opIds: converted opportunity Ids.
    */          
    public static Map<Id,Opportunity> queryConvertedOpportunities(Set<Id> oppIds){//1.2
        return new Map<Id, Opportunity>([select Id, StageName, Amount, Source_Lead__c from Opportunity where Id in :oppIds]);
    }         
}