global class AP57_ConvertLeadBatch implements Database.Batchable<sObject> { 

    global AP57_ConvertLeadBatch() {        
    }
    
    global Iterable<SObject> start(Database.BatchableContext BC) {        
        String query = 'SELECT GolfbreaksEnquiryId__c, Id, Name, Status,';
               query += ' HomePhone__c, City,Country, Latitude,';
               query += ' Longitude, PostalCode, State, Street,';
               query += ' DoNotCall, Email, MobilePhone,';
               query += ' Phone, BestTimetoCall__c, PGA__c,';
               query += ' Bondholder__c, Rating, NewsletterSignUp__c,'; 
               query += ' Account__c, CreatedDate, Account__r.Lastname, SalesRegion__c ';
               query += 'FROM Lead ';
               query += 'WHERE GolfbreaksEnquiryId__c <> null ';                 
               query += 'AND LeadtoConvert__c = TRUE ';
               query += 'AND IsConverted = FALSE';
        System.debug('>>>>>>>>>>>>>>>>> query :' + query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        System.debug('>>>>>>>>>>>>>>>>> scope size:' + scope.size());
        AP58_LeadConversionUtility.convertLead((List<Lead>)scope);
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }
    
}