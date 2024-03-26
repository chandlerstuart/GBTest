/*
Name:  UpdateLeadOppAmountBatch.cls
======================================================
======================================================
Purpose:
-------
Batch class to update Lead & Opportunity Amounts (as per AP18_QuoteTriggerBL.updateLeadOppAmount)
======================================================
======================================================
History
------- 
Ver. Author             Date         Detail
1.0  Simon Molloy	    2017-11-15   Initial development
*/
global class UpdateLeadOppAmountBatch implements Database.Batchable<sObject> {
	global static final String CLASS_NAME = 'UpdateLeadOppAmountBatch';
	global List<Error_Log__c> logs {get; set;}
	global String query {get; set;}
	global String whichObject {get; set;}
	
	global UpdateLeadOppAmountBatch() {
		
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		List<Id> quoteIds;
		// *** PROCESS OPPORTUNITIES
		if ('OPPORTUNITY'.equalsIgnoreCase(whichObject)){	
			List<String> oppStageList = new List<String>();
			oppStageList.add(ApplicationConstant.RECOMMENDATIONSTAGE);
			oppStageList.add(ApplicationConstant.QUOTESENTSTAGE);
			oppStageList.add(ApplicationConstant.CLOSESALESTAGE);
			oppStageList.add(ApplicationConstant.CUSTOMERACCEPTEDSTAGE);
			oppStageList.add(ApplicationConstant.PAIDPARTIALDEPOSITSTAGE);


			List<Opportunity> oppList = [select Id, (Select Id from Quotes__r)
											from Opportunity where StageName in :oppStageList];

			quoteIds = new List<Id>();
			for (Opportunity o : oppList){
				for (Quote__c q : o.Quotes__r){
					quoteIds.add(q.Id);	
				}
			}
		}

		// *** PROCESS LEADS
		if ('LEAD'.equalsIgnoreCase(whichObject)){
			List<String> leadStatusList = new List<String>();
			leadStatusList.add(ApplicationConstant.LEAD_NO_SALE);
			leadStatusList.add(ApplicationConstant.LEAD_STATUS_DUPLICATE);
			
			List<Lead> leadList = [select Id, (Select Id from Quotes__r)
									from Lead where IsConverted = FALSE AND Status NOT IN :leadStatusList];

			quoteIds = new List<Id>();
			for (Lead l : leadList){
				for (Quote__c q : l.Quotes__r){
					quoteIds.add(q.Id);	
				}
			}
		}

		if (null == query){
			query = 'SELECT Id, Source_Lead__c, GrossProfit__c, Status__c, Opportunity__c from Quote__c where Id in :quoteIds';
		}
		
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
   		logs = new List<Error_Log__c>();
		List<Quote__c> processList = (List<Quote__c>) scope;
		Set<Id> oppToUpdate = new Set<Id>();
        Set<Id> leadToUpdate = new Set<Id>();
        List<Opportunity> oppList = new List<Opportunity>();
        List<Lead> leadList = new List<Lead>();
        Map<Id, Opportunity> oppToUpdateMap = new Map<Id, Opportunity>();
        Map<Id, Lead> leadToUpdateMap = new Map<Id, Lead>();
		
		if ('LEAD'.equalsIgnoreCase(whichObject)){
			for (Quote__c quote : processList){
				if (!String.isBlank(quote.Source_Lead__c)){
	                leadToUpdate.add(quote.Source_Lead__c);
	            }
	        }

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
	                        }
	                    }
	                }
	            }
	        }catch(Exception e){
	           logs.add(ApplicationConstant.getExceptionLog(e, 'execute', CLASS_NAME, null));
	        }finally{
	            if(logs.isEmpty() && leadToUpdateMap.size() > 0){
	                //Set the trigger guard variables to avoid recursion
	                AP03_LeadTriggerHandler.IsBeforeUpdateTriggerCalled = TRUE;
	                AP03_LeadTriggerHandler.IsAfterUpdateTriggerCalled = TRUE;
	                
	                Database.SaveResult[] UpdatedLead = Database.update( leadToUpdateMap.values(), false);
	                logs.addAll(ApplicationConstant.getSaveResultLog(UpdatedLead, 'execute', CLASS_NAME, 'Lead', 'Update'));
	            }
	        
	            if(!logs.isEmpty()){
	                Database.insert(logs, false);
	            }
	        }
		}

		if ('OPPORTUNITY'.equalsIgnoreCase(whichObject)){
			for (Quote__c quote : processList){
				if(!String.isBlank(quote.Opportunity__c)){
                	oppToUpdate.add(quote.Opportunity__c);
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
	
	global void finish(Database.BatchableContext BC) {
		
	}	
}