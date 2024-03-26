/**
Name:  AP38_BookingLeadCreationBatch.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Batch class for auto lead creation
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  M.Cebrian  2016-04-25  Initial development.
**/
global class AP38_BookingLeadCreationBatch implements Database.Batchable<sObject> {
	
	String query;
	global final String LEADSOURCE= 'Auto generate- returning traveller';
	global AP38_BookingLeadCreationBatch() {
		this.query = '';
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
	    Date datetocompare = System.today().addDays(-14);
      Date today = System.today();
      
		query = 'SELECT Id, TECH_Opportunity__c, Account__c, TECH_Opportunity__r.TravelGroupSize__c, TECH_Opportunity__r.SalesRegion__c,  Account__r.FirstName, Account__r.LastName, Account__r.Salutation, Account__r.Id, Account__r.Name, Account__r.PersonEmail FROM Booking__c WHERE Is_Cancelled__c = false AND TravelReturnDate__c =: datetocompare';
    System.debug('******* ' + query);
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<Booking__c> scope) {
   		System.debug('>>> scope' +scope);
   		List<Lead> leadsToCreate = new List<Lead>();
   		Set<Id> checkLeadsofAccount = new Set<Id>();
     		Set<Id> accountsWithValidLeads = new Set<Id>();
     		Set<String> validAccountLeadStatus = new Set<String>{'New', 'No Sale', 'Closed- Converted'};

        Map<Id, Set<Id>> accountIdsAndBookingIdsToExclude = new Map<Id, Set<Id>>();
   		//get all account ids related to booking
   		for(Booking__c bookingRec: scope){
   			checkLeadsofAccount.add(bookingRec.Account__r.Id);
        if(accountIdsAndBookingIdsToExclude.containsKey(bookingRec.Account__r.Id)){
          accountIdsAndBookingIdsToExclude.get(bookingRec.Account__r.Id).add(bookingRec.Id);
        }else{
          accountIdsAndBookingIdsToExclude.put(bookingRec.Account__r.Id, new Set<Id>{bookingRec.Id});
        }
        }
        List<Account> accountFromBookings = [SELECT Id, (SELECT Status, Id FROM Leads__r) 
                          									 FROM Account 
                          									 WHERE ID In:checkLeadsofAccount];
        System.debug('>>> accountFromBookings' +accountFromBookings);

        //Check that there ALL Leads on this Account where Status == New, No Sale, Closed-Converted
        Boolean isValid;
        for(Account acc: accountFromBookings){
        	isValid = true;
        	for(Lead ld: acc.Leads__r){
        		if(!validAccountLeadStatus.contains(ld.Status)){
        			isValid = false;
        		}
        	}
        	if(isValid){
        		accountsWithValidLeads.add(acc.Id);            
        	}else{
            accountIdsAndBookingIdsToExclude.remove(acc.Id);
          }
        }

        System.debug('>>> accountsWithValidLeads: ' +accountsWithValidLeads);

        // Exclude accounts who have an Open Opportunity or a Booking with travel date <= Today on their account
        // get accounts with isClosed = true
        Set<Id> invalidAccountIdsBasedOnOpportunity = new Set<Id>();
        for(AggregateResult ar : [SELECT Count(Id), AccountId
                                  FROM Opportunity
                                  WHERE IsClosed = false
                                  AND AccountId IN:accountsWithValidLeads
                                  GROUP BY AccountId]){   
            invalidAccountIdsBasedOnOpportunity.add(String.valueOf(ar.get('AccountId')));
        }

        for(Id acctId : invalidAccountIdsBasedOnOpportunity){
          if(accountsWithValidLeads.contains(acctId)){
            accountsWithValidLeads.remove(acctId);
          }
        }
        System.debug('>>>  invalidAccountIdsBasedOnOpportunity accountsWithValidLeads: ' +accountsWithValidLeads);
        // Exclude clients who have a Case type of Complaints with a created date within the last 14 days on their account
        Set<Id> invalidAccountIdsBasedOnCaseComplaints = new Set<Id>();
        for(AggregateResult ar : [SELECT Count(Id), AccountId
                                  FROM Case
                                  WHERE RecordTypeId =: ApplicationConstant.CASERECTYPEID_COMPLAINT
                                  AND AccountId IN:accountsWithValidLeads
                                  AND CreatedDate >= LAST_N_DAYS:14                                                                
                                  GROUP BY AccountId]){   
          invalidAccountIdsBasedOnCaseComplaints.add(String.valueOf(ar.get('AccountId')));
        }

        for(Id acctId : invalidAccountIdsBasedOnCaseComplaints){
          if(accountsWithValidLeads.contains(acctId)){
            accountsWithValidLeads.remove(acctId);
          }
        }
        System.debug('>>> invalidAccountIdsBasedOnCaseComplaints accountsWithValidLeads: ' +accountsWithValidLeads);
        //get bookings with valid accounts


        //Set<Id> invalidAccountIdsBasedOnPendingBooking = new Set<Id>();
        //Date dToday = System.today();
        //for(AggregateResult ar : [SELECT Count(Id), Account__c
        //                          FROM Booking__c
        //                          WHERE Is_Cancelled__c = false
        //                          AND Account__c IN:accountsWithValidLeads
        //                          AND Travel_Date__c >= :dToday
        //                          AND Id NOT IN:accountIdsAndBookingIdsToExclude.get(Account__c)                                                                 
        //                          GROUP BY Account__c]){   
        //  invalidAccountIdsBasedOnPendingBooking.add(String.valueOf(ar.get('AccountId')));
        //}

        //for(Id acctId : invalidAccountIdsBasedOnPendingBooking){
        //  if(accountsWithValidLeads.contains(acctId)){
        //    accountsWithValidLeads.remove(acctId);
        //  }
        //}

        Set<Id> invalidAccountIdsBasedOnPendingBooking = new Set<Id>();
        Date dToday = System.today();
        for(Booking__c bookingRec : [SELECT Id, Account__c
                                  FROM Booking__c
                                  WHERE Is_Cancelled__c = false
                                  AND Account__c IN:accountsWithValidLeads
                                  AND Travel_Date__c >= :dToday]){   
          if(!accountIdsAndBookingIdsToExclude.get(bookingRec.Account__c).contains(bookingRec.Id)){
            invalidAccountIdsBasedOnPendingBooking.add(bookingRec.Account__c);
          }
        }

        for(Id acctId : invalidAccountIdsBasedOnPendingBooking){
          if(accountsWithValidLeads.contains(acctId)){
            accountsWithValidLeads.remove(acctId);
          }
        }

        System.debug('>>> invalidAccountIdsBasedOnPendingBooking accountsWithValidLeads: ' +accountsWithValidLeads);


        for(Booking__c bookingRec: scope){
   			if(accountsWithValidLeads.contains(bookingRec.Account__r.Id)){
   				leadsToCreate.add(new Lead(LastName = bookingRec.Account__r.Name,
   				                            Account__c = bookingRec.Account__r.Id,
   											TravelGroupSize__c = bookingRec.TECH_Opportunity__r.TravelGroupSize__c, 
   											LeadSource =LEADSOURCE,
   											SalesRegion__c = bookingRec.TECH_Opportunity__r.SalesRegion__c,
   											Status = 'New',
   											//Email = 'test@test.com',
                        Email = bookingRec.Account__r.PersonEmail,
                        Diarydate__c = System.today()));
   			}
        }

        //insert leads
        System.debug('>>> leadsToCreate' +leadsToCreate);
        if(leadsToCreate.size()>0) insert leadsToCreate;
        
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}