public with sharing class AP58_LeadConversionUtility {

	/*************************************************************************************** 
    Developer -    Jerome To (Accenture)
    Date -         2016-06-28
    Version -      1.0 
    #############Change Log#############
    Modified by     Version     Change Date 
    ****************************************************************************************/
	public static void convertLead(List<Lead> leadRecords) {        
        List<Database.LeadConvertResult> results = new List<Database.LeadConvertResult>();
        List<Database.LeadConvert> leadConversions = new List<Database.LeadConvert>();
        try{
            for(Lead leadRec : leadRecords) {
	            Database.LeadConvert lc = new database.LeadConvert();
	            lc.setLeadId(leadRec.Id);
	            lc.setOpportunityName(leadRec.Account__r.Lastname + ' - ' + leadRec.SalesRegion__c);
	            lc.setAccountId(leadRec.Account__c);
	            lc.setConvertedStatus(ApplicationConstant.LEAD_STATUS_CLOSED_CONVERTED);
	            leadConversions.add(lc);
	        }
	    	if(!leadConversions.isEmpty()) {
	    		results = Database.convertLead(leadConversions);
                for(Database.LeadConvertResult result : results) {
                    System.debug('>>>>>>>>>>>>>>>> [' + result.leadId + '] Status : ' + (result.isSuccess() ? 'Success' : 'Failed'));
                    System.debug('>>>>>>>>>>>>>>> ' + (result.isSuccess() ? 'N/A' : ('Errors :' + result.getErrors())));
                }
	    	}
        } catch(Exception ex){
            System.debug('>>>>>>>>>>>>>>>> Convert Lead Error: ' + ex.getMessage() );
        }
    }    
}