/*
Name:  AP18_QuoteTriggerBL.cls
======================================================
======================================================
Purpose:
-------
Business Logic Class for AP17_QuoteTriggerHandler
======================================================
======================================================
History
------- 
Ver. Author             Date         Detail
1.0  Renz Melecotones   2016-04-04   Initial development
1.1  Simon Molloy       2017-11-01   Removed updateOpportunityAmount method
1.2  Simon Molloy       2017-11-01   Added new updateLeadOpportunityAmount method
*/
public with sharing class AP18_QuoteTriggerBL{

    // Used for logging
    public static final String CLASS_NAME = 'AP18_QuoteTriggerBL';
    
    /**
       *  This method is used to update the stages on the Opportunity based on Quote Status
       *  @name: updateOpportunityStage
       *  @developer: Abram Vixen Reyes 01.04.2016
       *  @param: quoteList - get Trigger.new from QouteTrigger; of List<Qoute__c> data type
    **/
    public static void updateOpportunityStage(List<Quote__c> quoteList){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Set<Id> oppToUpdate = new Set<Id>();
        Map<String, String> mapOppAndErrors = new Map<String, String>();
        String errorLogDescription = '';
        List<Opportunity> oppList = new List<Opportunity>();
        Map<Id, Opportunity> oppQueryMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        Set<String> oppInitialStages = new Set<String>{ApplicationConstant.RECOMMENDATIONSTAGE, ApplicationConstant.QUOTESENTSTAGE, ApplicationConstant.CLOSESALESTAGE};
        
        try{
            for(Quote__c quote: quoteList){
                if(!String.isBlank(quote.Opportunity__c)){
                    oppToUpdate.add(quote.Opportunity__c);
                }
            }
            
            if(!oppToUpdate.isEmpty()){
            
                oppQueryMap = new Map<Id, Opportunity>([SELECT Id, StageName FROM Opportunity WHERE Id IN:oppToUpdate]);
                
                if(!oppQueryMap.isEmpty()){
                    for(Quote__c quote: quoteList){
                        if(oppQueryMap.containsKey(quote.Opportunity__c)){
                            Opportunity oppforUp = oppQueryMap.get(quote.Opportunity__c);
                            if(oppforUp.StageName == ApplicationConstant.RECOMMENDATIONSTAGE ){
                               oppforUp.StageName = ApplicationConstant.QUOTESENTSTAGE;
                               oppMap.put(quote.Opportunity__c, oppforUp);
                            }else if(quote.Status__c == ApplicationConstant.QUOTEBOOKINGSTATUS && oppforUp.StageName <> ApplicationConstant.CUSTOMERACCEPTEDSTAGE && oppInitialStages.contains(oppforUp.StageName)){
                                oppforUp.StageName = ApplicationConstant.CUSTOMERACCEPTEDSTAGE;
                                oppMap.put(quote.Opportunity__c, oppforUp);  
                            }
                        }
                    }
                }
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'updateOpportunityStage', CLASS_NAME, null));
        }finally{
            if(logs.isEmpty() && oppMap.size() > 0){
                Database.SaveResult[] UpdatedOpp = Database.update(oppMap.values(), false);
                logs.addAll(ApplicationConstant.getSaveResultLog(UpdatedOpp, 'updateOpportunityStage', CLASS_NAME, 'Opportunity', 'Update'));
            }
        
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }
    
    /**
       *  This method is used to update the amount on the Opportunity AND LEAD based on Quote Sale Price Gross
       *  @name: updateLeadOpportunityAmount
       *  @developer: created by Simon Molloy
       *  @modification: 2017-11-01 : SM : If an Opportunity has no quotes in 'Booking' stage then
       *                 The total is now the AVERAGE GP across all quotes rather than the 'most recent'
    **/
    public static void updateLeadOpportunityAmount(List<Quote__c> quoteList){
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Map<String, String> mapOppAndErrors = new Map<String, String>();
        String errorLogDescription = '';
        Map<Id, Opportunity> oppToUpdateMap = new Map<Id, Opportunity>();
        Map<Id, Lead> leadToUpdateMap = new Map<Id, Lead>();
        Set<Id> oppToUpdate = new Set<Id>();
        Set<Id> leadToUpdate = new Set<Id>();
        List<Opportunity> oppList = new List<Opportunity>();
        List<Lead> leadList = new List<Lead>();
        
        //Collect IDs for Leads & Opportunities
        for(Quote__c quote: quoteList){
            if(!String.isBlank(quote.Opportunity__c)){
                oppToUpdate.add(quote.Opportunity__c);
            }
            if (!String.isBlank(quote.Source_Lead__c)){
                leadToUpdate.add(quote.Source_Lead__c);
            }
        }
        System.debug('>>>oppToUpdate '+oppToUpdate);
        System.debug('>>>leadToUpdate '+leadToUpdate);
            
        //*****  UPDATE LEADS  ***** //
        try{
            system.debug('*** -- Processing Leads -- ***');
            if(!leadToUpdate.isEmpty()){
    
                
                Map<Id, List<Quote__c>> leadQuoteMap = new Map<Id, List<Quote__c>>();
                
                leadList = [SELECT Id, Amount__c FROM Lead WHERE Id IN:leadToUpdate];
                
                Id qtId;
                for(Quote__c qt: [SELECT Id, GrossProfit__c, Status__c, Source_Lead__r.Id FROM Quote__c WHERE Source_Lead__r.Id IN: leadToUpdate Order by CreatedDate DESC]){
                    qtId = Id.valueOf(qt.Source_Lead__r.Id);
                    if(leadQuoteMap.containsKey(qtId)) {
                        leadQuoteMap.get(qtId).add(qt);
                    }
                    else {
                        leadQuoteMap.put(qtId, new List<Quote__c>{qt});
                    }
                }
                System.debug('>>>leadQuoteMap '+leadQuoteMap);
                
                Boolean hasBooking = false;
                for(Lead l: leadList){
                    hasBooking = false;
                    if(leadQuoteMap.containsKey(l.Id)) {
                        for(Quote__c qt: leadQuoteMap.get(l.Id)){
                            if(qt.Status__c == ApplicationConstant.QUOTEBOOKINGSTATUS || qt.Status__c == ApplicationConstant.QUOTECANCELLATION){
                                hasBooking = true;

                                if(null != qt.GrossProfit__c && l.Amount__c <> qt.GrossProfit__c) {
                                    l.Amount__c = qt.GrossProfit__c;
                                    leadToUpdateMap.put(l.Id, l);
                                }
                                break;
                            }
                        }
                        //if opp has quote with no status = booking
                        //2017-11-01 : SM : We now add ALL quote GrossProfit__c amounts and 
                        //2017-11-01 : SM : Divide by the number of Quotes to get the average price
                        if(!hasBooking && !leadQuoteMap.get(l.Id).isEmpty()) {
                            integer noOfQuotes = leadQuoteMap.get(l.Id).size();
                            decimal quoteTotals = 0;
                            for (Quote__c qt : leadQuoteMap.get(l.Id)){
                                quoteTotals += (null == qt.GrossProfit__c ? 0 : qt.GrossProfit__c);
                            }

                            if (l.Amount__c <> quoteTotals){
                                l.Amount__c = quoteTotals / noOfQuotes;
                                leadToUpdateMap.put(l.Id, l);
                            }

                            /* REMOVED as per Sprint Item S138
                            //set opp amount to latest related quote sale price
                            if(opp.Amount <> oppQuoteMap.get(opp.Id)[0].GrossProfit__c) {
                                opp.Amount = oppQuoteMap.get(opp.Id)[0].GrossProfit__c;
                                oppToUpdateMap.put(opp.Id, opp);
                            }
                            */
                        }
                    }
                }
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'updateLeadOpportunityAmount', CLASS_NAME, null));
        }finally{
            if(logs.isEmpty() && leadToUpdateMap.size() > 0){
                //Set the trigger guard variables to avoid recursion
                AP03_LeadTriggerHandler.IsBeforeUpdateTriggerCalled = TRUE;
                AP03_LeadTriggerHandler.IsAfterUpdateTriggerCalled = TRUE;
                
                Database.SaveResult[] UpdatedLead = Database.update( leadToUpdateMap.values(), false);
                logs.addAll(ApplicationConstant.getSaveResultLog(UpdatedLead, 'updateLeadOpportunityAmount', CLASS_NAME, 'Lead', 'Update'));
            }
        
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }


        //*****  UPDATE OPPORTUNITY  *****//
        try{
            system.debug('*** -- Processing Opportunities -- ***');
            if(!oppToUpdate.isEmpty()){
    
                
                Map<Id, List<Quote__c>> oppQuoteMap = new Map<Id, List<Quote__c>>();
                
                oppList = [SELECT Id, Amount FROM Opportunity WHERE Id IN:oppToUpdate];
                
                Id qtId;
                for(Quote__c qt: [SELECT Id, GrossProfit__c, Status__c, Opportunity__r.Id FROM Quote__c WHERE Opportunity__r.Id IN: oppToUpdate Order by CreatedDate DESC]){
                    qtId = Id.valueOf(qt.Opportunity__r.Id);
                    if(oppQuoteMap.containsKey(qtId)) {
                        oppQuoteMap.get(qtId).add(qt);
                    }
                    else {
                        oppQuoteMap.put(qtId, new List<Quote__c>{qt});
                    }
                }
                System.debug('>>>oppQuoteMap '+oppQuoteMap);
                
                Boolean hasBooking = false;
                for(Opportunity opp: oppList){
                    hasBooking = false;
                    if(oppQuoteMap.containsKey(opp.Id)) {
                        for(Quote__c qt: oppQuoteMap.get(opp.Id)){
                            if(qt.Status__c == ApplicationConstant.QUOTEBOOKINGSTATUS || qt.Status__c == ApplicationConstant.QUOTECANCELLATION){
                                hasBooking = true;
                                if(null != qt.GrossProfit__c && opp.Amount <> qt.GrossProfit__c) {
                                    opp.Amount = qt.GrossProfit__c;
                                    oppToUpdateMap.put(opp.Id, opp);
                                }
                                break;
                            }
                        }
                        //if opp has quote with no status = booking
                        //2017-11-01 : SM : We now add ALL quote GrossProfit__c amounts and 
                        //2017-11-01 : SM : Divide by the number of Quotes to get the average price
                        if(!hasBooking && !oppQuoteMap.get(opp.Id).isEmpty()) {
                            system.debug('*** -- Into Averaging Code -- ***');
                            integer noOfQuotes = oppQuoteMap.get(opp.Id).size();
                            system.debug('*** -- Number of quotes ' + noOfQuotes + ' -- ***');
                            decimal quoteTotals = 0;
                            for (Quote__c qt : oppQuoteMap.get(opp.Id)){
                                quoteTotals += (null == qt.GrossProfit__c ? 0 : qt.GrossProfit__c);
                            }
                            system.debug('*** -- quoteTotals ' + quoteTotals + ' -- ***');
                            if (opp.Amount <> quoteTotals){
                                opp.Amount = quoteTotals / noOfQuotes;
                                oppToUpdateMap.put(opp.Id, opp);
                            }

                            /* REMOVED as per Sprint Item S138
                            //set opp amount to latest related quote sale price
                            if(opp.Amount <> oppQuoteMap.get(opp.Id)[0].GrossProfit__c) {
                                opp.Amount = oppQuoteMap.get(opp.Id)[0].GrossProfit__c;
                                oppToUpdateMap.put(opp.Id, opp);
                            }
                            */
                        }
                    }
                }
            }
        }catch(Exception e){
           logs.add(ApplicationConstant.getExceptionLog(e, 'updateLeadOpportunityAmount', CLASS_NAME, null));
        }finally{
            if(logs.isEmpty() && oppToUpdateMap.size() > 0){
                //Set the trigger guard variables to avoid recursion
                AP05_OpportunityTriggerHandler.IsBeforeUpdateTriggerCalled = TRUE;
                AP05_OpportunityTriggerHandler.IsAfterUpdateTriggerCalled = TRUE;

                Database.SaveResult[] UpdatedOpp = Database.update( oppToUpdateMap.values(), false);
                logs.addAll(ApplicationConstant.getSaveResultLog(UpdatedOpp, 'updateLeadOpportunityAmount', CLASS_NAME, 'Opportunity', 'Update'));
            }
        
            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }
    
}