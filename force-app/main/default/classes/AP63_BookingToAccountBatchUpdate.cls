/**************************************************************
@author - Simon Molloy (Golfbreaks)
@date - 18/01/2017
@description - Batch class to update Account records from Bookings
v1.0 - use Booking.PrimaryVenue to update Account.LastDestination
***************************************************************/
global with sharing class AP63_BookingToAccountBatchUpdate implements Database.Batchable<SObject>{
	global String query {get; set;}
	global final String CLASS_NAME = 'AP63_BookingToAccountBatchUpdate';

	//First query version looking at Bookings with Return Travel Date of TODAY
	global Database.QueryLocator start(Database.BatchableContext BC){
        if (null == query){
            query = 'select Id, PrimaryVenue__c, Account__c from Booking__c where TravelReturnDate__c = TODAY';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Booking__c> scope){
    	List<Error_Log__c> logs = new List<Error_Log__c>();
    	Set<Id> accIdSet = new Set<Id>();
    	Map<Id, Account> accMap;

    	try {
	        for (Booking__c b : scope){
	        	accIdSet.add(b.Account__c);
	        }

	        accMap = new Map<Id, Account>([select Id, Last_Destination__c from Account where Id in :accIdSet]);

	        system.debug('*** -- accMap Size in ' + CLASS_NAME + ' execute = ' + accMap.size() + ' -- ***');

	        for (Booking__c b : scope){
	        	Account bookingAccount = accMap.get(b.Account__c);
	        	if (null != bookingAccount){
		        	if (accMap.get(b.Account__c).Last_Destination__c != b.PrimaryVenue__c){
		        		accMap.get(b.Account__c).Last_Destination__c = b.PrimaryVenue__c;
		        	}else {
		        		accMap.remove(b.Account__c);
		        	}
		        }
	        }
       
        }catch(Exception e){
        	system.debug('*** -- Exception generated in ' + CLASS_NAME + ' execute ' + e + ' at line ' + e.getLineNumber() + ' -- ***');
        	logs.add(ApplicationConstant.getExceptionLog(e, 'execute', CLASS_NAME, null));
        }finally{
            
            if(logs.isEmpty() && accMap.size() > 0){
                Database.SaveResult[] updateAccList = Database.update(accMap.values(), false);
                logs.addAll(ApplicationConstant.getSaveResultLog(updateAccList, 'execute', CLASS_NAME, 'Account', 'Update'));
            }

            if(!logs.isEmpty()){
                Database.insert(logs, false);
            }
        }
    }

    global void finish(Database.BatchableContext BC){
        //EMPTY
    }

}