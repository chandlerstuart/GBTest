/*
Name:  LeadConversionManager.cls
Copyright © 2016  Golf Breaks Offshore Team
======================================================
======================================================
Purpose:
-------
Ligtning Component Controller of LeadInformation
======================================================
======================================================
History
------- 
Ver. Author         Date        Detail
1.0  Kevin I.       2016-04-01  Initial development.
2.0  Nicole DG      2016-04-01  Updated LeadConversionManager.convertLead() to check if EnquiryId is NULL. If true, send outbound message then convert Lead. Otherwise, convert Lead only.
3.0  Bryanne P.     2016-04-08  Change the name of the class to VFC01_LeadConvertProcessor
4.0  Mark C.        2016-04-09  Added a method to query for Campaign Member from Lead to show the Campaign name.
5.0  Merari C.      2016-04-15  Added logic to proceed lead conversion only when webservice response is successful
5.1  Merari C.      2016-04-19  Added method updateRelatedAccount
5.2  Tristan Z.     2016-05-15  Added logic to opt-out lead's related account communication preference (newsletter) based on lead's newsletter sign up field
5.2  Merari C.      2016-05-16  Updated logic to opt-out lead's related account communication preference (newsletter) based on lead's newsletter sign up field
6.0  Simon M.       2016-11-03  New method for conversion that does NOT call out to Clubhouse
6.1  Simon M.       2016-12-08  Reverting to original version until Phase II - above change being kept inline for future use
6.2  Simon M.       2017-01-30  Changing call to getDMLLog as this is now private, use getSaveResultLog instead
6.3  Simon M.       2017-10-06  Removing update to Newsletter field in updateRelatedAccount call to (CR000474)
6.4  J Radcliffe	2018-08-08  Removing updateRelatedAccount. Agents are setting Client's Markting Preferences, which are then cleared/replaced when a lead is converted
6.5  J Radcliffe    2018-08-08  Removing setLeadId method. This is no longer required as the LeadId__c field on the Client account has been retired with the intro of the new Call Plan (Client Routing Profile)
6.6  J Radcliffe    2019-05-02  Wrapping legacy integrations with additional Phased Code Removal Settings
*/
public class LC04_LeadConvertProcessor  {
    public class CustomException extends Exception {}
    public static final String CLASS_NAME = 'LC04_LeadConvertProcessor';  
    public static final String LEAD_CONVERT_REASON_AGENT_ACTION = 'Agent action';
    
    @AuraEnabled
    public static Lead getLeadRecord(String leadId) {
        List<Lead> leadRecords = [SELECT 
            Id, Account__c, AccountName__c, Nights__c, FirstName, LastName,
            Email, PreferredTravelDate__c, TravelGroupSize__c,
            Venue__c, NewsletterSignUp__c, AdditionalInformation__c, 
            SalesRegion__c,GolfBreaks_Campaign_ID__c,MobilePhone,IsConverted, ConvertedOpportunityId, ConvertedAccountId, Account__r.Name
            FROM Lead 
            WHERE Id = :leadId LIMIT 1];
        Lead retLead;
                            //system.assertnotequals(4,4);
        if(leadRecords.isEmpty()) {
            throw new CustomException('Lead not found');
        } else {
            retLead = leadRecords[0];
            System.debug('>>>> retLead '+retLead);
        }
        return retLead;
    }
    
    @AuraEnabled
    public static String getCreatedDate(String leadId) {
        List<Lead> leadRecords = [SELECT 
            CreatedDate
            FROM Lead 
            WHERE Id = :leadId LIMIT 1];
        String createdDate;
        if(leadRecords.isEmpty()) {
            throw new CustomException('Lead not found');
        } else {
            createdDate = String.valueOf(leadRecords[0].createdDate).substring(8,10) + '/' + String.valueOf(leadRecords[0].createdDate).substring(5,7) + '/' + String.valueOf(leadRecords[0].createdDate).substring(0,4);
            
        }
        return createdDate;
    }

    //New convertLead method that does NOT call out to Clubhouse
    //THIS method is not being used until Phase II, but code is being kept inline for future use
    /*
    @AuraEnabled
    public static LeadConvertResult convertLead(String leadId, String oppName) {
        system.debug('*** -- into LC04_LeadConvertProcessor.convertLead with ' + leadId +'  -- ***');
        String accId = '';
        String oppId = '';
        String accName = '';
        String errors = '';
        oppName = '';
        
        Boolean isUpdate = true;
        List<String> tmpString = new List<String>();
        Communication_Preference__c newsletterCommPref;
        
        List<Lead> leadToConvertList = [SELECT GolfbreaksEnquiryId__c, Id, Name, Status,
                                HomePhone__c,
                                City,Country,Latitude,Longitude,PostalCode,State,Street,
                                DoNotCall, 
                                Conversion_Reason__c,
                                Email, 
                                MobilePhone, 
                                Phone, 
                                BestTimetoCall__c,
                                PGA__c,
                                Bondholder__c,
                                Rating,
                                NewsletterSignUp__c, Account__c, Account__r.Name, 
                                createdDate, FirstName, LastName FROM Lead WHERE Id =: leadId LIMIT 1];                                
  
        Lead leadToConvert;      
        if (!leadToConvertList.isEmpty()){
            leadToConvert = leadToConvertList[0];
            leadToConvert.Conversion_Reason__c = LEAD_CONVERT_REASON_AGENT_ACTION;
        }else {
            system.debug('*** -- LC04_LeadConvertProcessor - unable to find Lead with ID ' + leadId + ' -- ***');
            return null;
        }
        
        if(leadToConvert.FirstName != null) oppName = leadToConvert.FirstName + ' ' + leadToConvert.LastName + ' - ' + String.valueOf(leadToConvert.createdDate).substring(8,10) + '/' + String.valueOf(leadToConvert.createdDate).substring(5,7) + '/' + String.valueOf(leadToConvert.createdDate).substring(0,4);
        else oppName = leadToConvert.LastName + ' - ' + String.valueOf(leadToConvert.createdDate).substring(8,10) + '/' + String.valueOf(leadToConvert.createdDate).substring(5,7) + '/' + String.valueOf(leadToConvert.createdDate).substring(0,4);
                             
        try {
            
            if (leadToConvert.Status != ApplicationConstant.LEAD_STATUS_CLOSED_CONVERTED) {
                //accId = [SELECT Account__c FROM Lead WHERE Id =: leadId LIMIT 1].Account__c;
                //accName = [SELECT Account__r.Name FROM Lead WHERE Id =: leadId LIMIT 1].Account__r.Name;
                accId = leadToConvert.Account__c;
                accName = leadToConvert.Account__r.Name;
                try{
                    Database.LeadConvert lc = new Database.LeadConvert();
                    lc.setLeadId(leadId);
                    lc.setOpportunityName(oppName);
                    lc.setAccountId(accId);
                    lc.setConvertedStatus(ApplicationConstant.LEAD_STATUS_CLOSED_CONVERTED);
                    Lead convertedLead = leadToConvert;
                    Database.LeadConvertResult lcr = Database.convertLead(lc);
                    System.debug('LCR: ' + lcr);
                    oppId = lcr.getOpportunityId();
                    
                    if(lcr.isSuccess()){
                        updateRelatedAccount(convertedLead, lcr.getAccountId(), isUpdate);
                        accId = lcr.getAccountId();
                        accName = [SELECT Name FROM Account WHERE Id =: accId LIMIT 1].Name;
                    }
                }
                catch(Exception ex){
                    System.debug('Convert Lead Error: ' + ex.getMessage());
                }
            }
            
        
        } catch(DmlException e){ 
            String error = e.getMessage();
            System.debug('The following exception has occurred: ' + e.getMessage());
       }
       
        return new LeadConvertResult(oppId,accId,oppName,accName, errors);
        
    }
    */
    
    @AuraEnabled
    public static LeadConvertResult convertLead(String leadId, String oppName) {

        //6.6 Retrieve lowest level 'Phased Code Removal' settings
        Phased_Code_Removal__c pcr = Phased_Code_Removal__c.getInstance();


        system.debug('*** -- into LC04_LeadConvertProcessor.convertLead with ' + leadId +'  -- ***');
        String accId = '';
        String oppId = '';
        String accName = '';
        String errors = '';
        oppName = '';
        
        String webServiceResponse = '';
        Integer responseStatus = 0;
        Boolean isUpdate = true;
        List<String> tmpString = new List<String>();
        Communication_Preference__c newsletterCommPref;
        
        List<Lead> leadToConvertList = [SELECT GolfbreaksEnquiryId__c, Id, Name, Status,
                                HomePhone__c,
                                City,Country,Latitude,Longitude,PostalCode,State,Street,
                                DoNotCall, 
                                Email, 
                                MobilePhone, 
                                Phone, 
                                BestTimetoCall__c,
                                PGA__c,
                                Bondholder__c,
                                Rating,
                                NewsletterSignUp__c, Account__c,createdDate, FirstName, LastName FROM Lead WHERE Id =: leadId LIMIT 1];                                
  
        Lead leadToConvert;      
        if (!leadToConvertList.isEmpty()){
            leadToConvert = leadToConvertList[0];
        }else {
            system.debug('*** -- LC04_LeadConvertProcessor - unable to find Lead with ID ' + leadId + ' -- ***');
            return null;
        }
        
        if(leadToConvert.FirstName != null) oppName = leadToConvert.FirstName + ' ' + leadToConvert.LastName + ' - ' + String.valueOf(leadToConvert.createdDate).substring(8,10) + '/' + String.valueOf(leadToConvert.createdDate).substring(5,7) + '/' + String.valueOf(leadToConvert.createdDate).substring(0,4);
        else oppName = leadToConvert.LastName + ' - ' + String.valueOf(leadToConvert.createdDate).substring(8,10) + '/' + String.valueOf(leadToConvert.createdDate).substring(5,7) + '/' + String.valueOf(leadToConvert.createdDate).substring(0,4);
                             
        try {
            //6.6 - Check the 'Disable_Legacy_Client_Enq_Integrations__c' before executing
            if(pcr != null && !pcr.Disable_Legacy_Client_Enq_Integrations__c){
                if((leadToConvert.GolfbreaksEnquiryId__c == null || String.isBlank(String.valueOf(leadToConvert.GolfbreaksEnquiryId__c))) && leadToConvert.Status != ApplicationConstant.LEAD_STATUS_CLOSED_CONVERTED){
                    System.debug('>>>> rebar is called');
                    webServiceResponse = WS01_RebarHTTPCallout.outboundMessageCreator(leadId, 'ENQUIRY');
                    System.debug('>>>> webServiceResponse ' +webServiceResponse);
                    
                    //parse return string to get response
                    if(String.isNotBlank(webServiceResponse)){
                        tmpString = webServiceResponse.split(';');
                        responseStatus = Integer.valueOf(tmpString[0]);
                        if(tmpString[1] == 'CREATED'){
                            isUpdate = false;
                        } else if(tmpString[1] == 'UPDATED'){
                            isUpdate = true;
                        } else if(tmpString[1] == 'ERROR'){
                            errors = tmpString[2];
                        }
                    }
                }
            }
            if ((String.isNotBlank(String.valueOf(leadToConvert.GolfbreaksEnquiryId__c)) || APIUtility.setPositiveStatuses.contains( responseStatus )) && leadToConvert.Status != ApplicationConstant.LEAD_STATUS_CLOSED_CONVERTED ) {
                Lead accLead = [SELECT Account__c, Account__r.Name FROM Lead WHERE Id =: leadId LIMIT 1];
                accId = accLead.Account__c;//[SELECT Account__c FROM Lead WHERE Id =: leadId LIMIT 1].Account__c;
                accName = accLead.Account__r.Name;//[SELECT Account__r.Name FROM Lead WHERE Id =: leadId LIMIT 1].Account__r.Name;
                try{
                    Database.LeadConvert lc = new Database.LeadConvert();
                    lc.setLeadId(leadId);
                    lc.setOpportunityName(oppName);
                    lc.setAccountId(accId);
                    lc.setConvertedStatus(ApplicationConstant.LEAD_STATUS_CLOSED_CONVERTED);
                    Lead convertedLead = leadToConvert;
                    Database.LeadConvertResult lcr = Database.convertLead(lc);
                    System.debug('LCR: ' + lcr);
                    oppId = lcr.getOpportunityId();
                    
                    if(lcr.isSuccess()){
                        //6.4 - updateRelatedAccount(convertedLead, lcr.getAccountId(), isUpdate);
                        accId = lcr.getAccountId();
                        accName = [SELECT Name FROM Account WHERE Id =: accId LIMIT 1].Name;

                        //We need to call the 'postConvertProcessor' in AP04_LeadTriggerBL to
                        //Copy values from the Shadow Opp. to the Converted Opp.
                        Set<Id> leadIds = new Set<Id>();
                        leadIds.add(accLead.Id);
                        system.debug('*** -- LC04_LeadConvertProcessor.convertLead - Calling doPostConvert with ' + leadIds + ' -- ***');
                        //6.6 - Check the 'Disable_Shadow_Opportunities__c' before executing
                        if(pcr != null && !pcr.Disable_Shadow_Opportunities__c){
                            AP04_LeadTriggerBL.doPostConvert(leadIds);
                        }
                    }
                }
                catch(Exception ex){
                    System.debug('Convert Lead Error: ' + ex.getMessage());
                }
            }
            
        
        } catch(DmlException e){ 
            String error = e.getMessage();
            System.debug('The following exception has occurred: ' + e.getMessage());
       }
       
        return new LeadConvertResult(oppId,accId,oppName,accName, errors);
        
    }
    
    
    /*************************************************************************************** 
    Developer -    Merari Cebrian (Accenture)
    Date -         2016-04-19
    Version -      5.1
    Function -     update fields of related account of lead
    #############Change Log#############
    Modified by     Version     Change Date 
    ****************************************************************************************/
    /*6.4 public static void updateRelatedAccount(Lead convertedLead, String relatedAcnt, Boolean isUpdate){
        List<Communication_Preference__c> commPrefListToUpdate = new List<Communication_Preference__c>();
        Map<Id, Communication_Preference__c> commPrefMapToUpdate = new Map<Id, Communication_Preference__c>();
        Map<String, String> mapComPrefAndErrors = new Map<String, String>();
        String errorLogDescription = '';
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Error_Log__c log = new Error_Log__c();
        
        Account accnt = [SELECT Id,
                        PersonHomePhone,
                        PersonMailingCity,PersonMailingCountry,PersonMailingLatitude,PersonMailingLongitude,PersonMailingPostalCode,PersonMailingState,PersonMailingStreet,
                        BillingCity,BillingCountry,BillingPostalCode,BillingState,BillingStreet,
                        PersonDoNotCall,
                        PersonEmail,
                        PersonMobilePhone,
                        Phone,
                        BestTimeToCall__c,
                        //Is_PGA__pc,
                        //Bond_Holder__pc,
                        NewsletterSignUp__c,
                        //Customer_Since__pc,
                        LeadId__c,
                        (SELECT Id, Opt_In__c, Activated_Date__c, Opted_Out_Date__c FROM Customer_Preferences__r Where Communication_Type__c = 'Newsletter')
                        FROM Account WHERE Id =: relatedAcnt];
                        
        //map lead fields to account fields                
        accnt.PersonHomePhone = convertedLead.HomePhone__c;
        accnt.BillingCity = convertedLead.City;
        accnt.BillingCountry = convertedLead.Country;
        accnt.BillingPostalCode = convertedLead.PostalCode;
        accnt.BillingState = convertedLead.State;
        accnt.BillingStreet = convertedLead.Street;
        accnt.PersonMailingCity = convertedLead.City;
        accnt.PersonMailingCountry = convertedLead.Country;
        accnt.PersonMailingLatitude = convertedLead.Latitude;
        accnt.PersonMailingLongitude = convertedLead.Longitude;
        accnt.PersonMailingPostalCode = convertedLead.PostalCode;
        accnt.PersonMailingState = convertedLead.State;
        accnt.PersonMailingStreet = convertedLead.Street;
        accnt.PersonDoNotCall = convertedLead.DoNotCall;
        accnt.PersonEmail = convertedLead.Email;
        accnt.PersonMobilePhone = convertedLead.MobilePhone;
        accnt.Phone = convertedLead.Phone;
        //accnt.Is_PGA__pc = convertedLead.PGA__c;
        //accnt.Bond_Holder__pc = convertedLead.Bondholder__c;
        //2017-10-09 : SM : Removing update to Newsletter field as per CR-000474
        //accnt.NewsletterSignUp__c = convertedLead.NewsletterSignUp__c;
        accnt.LeadId__c = setLeadIdRating(convertedLead);
        Datetime convertdate = convertedLead.createdDate;
        Date dates = date.newinstance(convertdate.year(), convertdate.month(), convertdate.day());
        //accnt.Customer_Since__pc = dates;
        system.debug('date created'+dates);
        if(!isUpdate) {accnt.BestTimeToCall__c = convertedLead.BestTimetoCall__c;}
        
        for(Communication_Preference__c cp: accnt.Customer_Preferences__r){
            cp.Opt_In__c = convertedLead.NewsletterSignUp__c;
            cp.Activated_Date__c = convertedLead.NewsletterSignUp__c ? system.today() : null;
            cp.Opted_Out_Date__c = convertedLead.NewsletterSignUp__c ? null : system.today();
            commPrefListToUpdate.add(cp);
            commPrefMapToUpdate.put(cp.Id, cp);
        }
        
        try{
            update accnt;
        }catch(DmlException e){
            System.debug('Account not updated. The following exception has occurred: ' + e.getMessage());
        }
        
        //Database.SaveResult[] commPreferenceListToUpdate = database.update(commPrefListToUpdate, false);
        
        //for(Integer i=0; i<commPreferenceListToUpdate.size(); i++){
        //    Database.SaveResult result = commPreferenceListToUpdate[i];
        //    // SUCCESS
        //    if(commPreferenceListToUpdate.get(i).isSuccess()){
        //        System.Debug('>>SUCCESS : commPreferenceListToUpdate.get(i).getId()<<'+commPreferenceListToUpdate.get(i).getId());
        //    }
        //    // ERROR
        //    else{
        //        List<Database.Error> lstErrors = result.getErrors();
        //        for(Integer j=0; j< lstErrors.size(); j++){     
        //            String errorDescription = '';
        //            errorDescription += ApplicationConstant.GENERAL_EXCEPTION_GET_STATUS_CODE +' '+ lstErrors.get(j).getStatusCode() + '\n';
        //            errorDescription += ApplicationConstant.GENERAL_EXCEPTION_GET_FIELDS +' '+ lstErrors.get(j).getFields() + '\n';
        //            errorDescription += ApplicationConstant.GENERAL_EXCEPTION_GET_ERROR_MESSAGE +' '+ lstErrors.get(j).getMessage() + '\n';
        //            mapComPrefAndErrors.put( commPreferenceListToUpdate.get(i).Id, errorDescription);
        //            System.Debug('>>ERROR : commPreferenceListToUpdate.get(i).Id<<'+commPreferenceListToUpdate.get(i).Id);
        //        }
                
        //        log = ApplicationConstant.getDMLLog(commPreferenceListToUpdate[i], 'execute', CLASS_NAME, 'Communication_Preference__c', 'Update');
        //        log.trace__c += ' \n Record Name: ' + commPrefListToUpdate.get(i).Name;
        //        logs.add(log);
        //    }
        //}
        
        //if( mapComPrefAndErrors.size() > 0 && commPrefMapToUpdate.size() > 0 ){   
        //    for(Communication_Preference__c cf : commPrefMapToUpdate.values()){
        //        if( mapComPrefAndErrors.containsKey(cf.Id) ){
        //            cf.addError( mapComPrefAndErrors.get(cf.Id) );                    
        //        }
        //    }
        //} 
        
        if(!commPrefListToUpdate.isEmpty()){
            logs.addAll(getResultLogs(database.update(commPrefListToUpdate, false)));
        }

        if(!logs.isEmpty()){
            Database.insert(logs, false);
        }
    }*/
    
    /*************************************************************************************** 
    Developer -    Merari Cebrian (Accenture)
    Date -         2016-04-15
    Version -      5.0 
    Function -     returns related account and opportunity of converted lead
    #############Change Log#############
    Modified by     Version     Change Date 
    ****************************************************************************************/
    public class LeadConvertResult {
        @AuraEnabled
        public String oppId;
        @AuraEnabled
        public String accId;
        @AuraEnabled
        public String oppName;
        @AuraEnabled
        public String accName;
        @AuraEnabled
        public String errors;
        public LeadConvertResult(String oppId,String accId, String oppName, String accName, String errors){
            this.oppId = oppId;
            this.accId = accId;
            this.oppName = oppName;
            this.accName = accName;
            this.errors= errors;
        }
    }
    /*************************************************************************************** 
    Developer -    Merari Cebrian (Accenture)
    Date -         2016-05-18
    Version -      5.0 
    Function -     returns latest valid lead on acc
    #############Change Log#############
    Modified by     Version     Change Date 
    ****************************************************************************************/
   /*6.5 private static string setLeadIdRating(Lead leadRecord){
        System.debug('setLeadIdRating --- Start');
        List<Error_Log__c> logs = new List<Error_Log__c>();
        
        //instantiate variables needed.
        Map<Id,Account> accountMap = new Map<Id,Account>();
        Map<Id,Account> accountMapToUpdate = new Map<Id,Account>();
        Map<Id,List<Lead>> accountIdToLeads = new Map<Id,List<Lead>>();
        Map<Id,Lead> currentLeadMaponAccount = new Map<Id,Lead>();      
        Account accRec = new Account();
        List<Lead> leadRecList = new List<Lead>();
        Map<Id, DateTime> latestHotLead = new Map<Id, DateTime>();
        Map<Id, DateTime> latestWarmLead = new Map<Id, DateTime>();
        Map<Id, DateTime> latestColdLead = new Map<Id, DateTime>();
        Map<Id, DateTime> latestNoRating = new Map<Id, DateTime>();
        String latestId = '';
        DateTime latestDate;
        
            currentLeadMaponAccount = new Map<Id,Lead>([SELECT Name, Account__c, Rating, CreatedDate, Status FROM Lead WHERE Status <>: ApplicationConstant.LEAD_CLOSED_CONVERTED AND Status <>: ApplicationConstant.LEAD_NO_SALE AND Status <>: ApplicationConstant.LEAD_STATUS_DUPLICATE AND Account__c =:leadRecord.Account__c]);
            System.debug('>>>>>> currentLeadMaponAccount '+currentLeadMaponAccount);
            //mapping of Account to the Lead records related to it
            for(Lead leadRec : currentLeadMaponAccount.values()){
                if(accountIdToLeads.containsKey(leadRec.Account__c)){
                    accountIdToLeads.get(leadRec.Account__c).add(leadRec);
                }
                else{
                    accountIdToLeads.put(leadRec.Account__c, new List<Lead>{leadRec});
                }
            }
            System.debug('>>>>>> accountIdToLeads '+accountIdToLeads);
            if(accountIdToLeads.containsKey(leadRecord.Account__c)) {
                        
                leadRecList = accountIdToLeads.get(leadRecord.Account__c);
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


                System.debug('>>>TEST_latestHotLead : ' + latestHotLead.size());
                System.debug('>>>TEST_latestWarmLead : ' + latestWarmLead.size());
                System.debug('>>>TEST_latestColdLead : ' + latestColdLead.size());                
                System.debug('>>>TEST_latestNoRating : ' + latestNoRating.size());

                //If it has a Lead with a 'Hot' rating - it is sorted here
                if(latestHotLead.size() > 0){
                    
                    for(Id leadId : latestHotLead.keySet()){
                        system.debug('latestHotLead:: ' + leadId);
                        if(String.isBlank(latestId) && latestDate == null){
                            latestId = leadId;
                            latestDate = latestHotLead.get(leadId);
                        }
                        else{
                            system.debug('latestHotLead:: else ' + String.valueof(latestDate) + ' :: ' + String.Valueof( latestHotLead.get(leadId)));
                        
                            if(latestDate < latestHotLead.get(leadId)){
                                latestDate = latestHotLead.get(leadId);
                                latestId = leadId;
                            }
                        }
                    }
                    System.debug('latestHotLead --- latestId' +latestId);
                }
                //If there is no Lead with a 'Hot' rating - it proceeds here and it is sorted as well here
                else if(latestWarmLead.size() > 0){
                    for(Id leadId : latestWarmLead.keySet()){
                        if(String.isBlank(latestId) && latestDate == null){
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
                }
                //If there is no Lead with a 'Hot' rating or 'Warm' - it proceeds here and it is sorted as well here
                else if(latestColdLead.size() > 0){
                    for(Id leadId : latestColdLead.keySet()){
                        if(String.isBlank(latestId) && latestDate == null){
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
                }
                //If it has a Lead with a no rating - it is sorted here
                else if(latestNoRating.size() > 0){
                    for(Id leadId : latestNoRating.keySet()){
                        if(String.isBlank(latestId) && latestDate == null){
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
                }
            } 
        System.debug('setLeadIdRating --- latestId' +latestId);
        System.debug('setLeadIdRating --- End');
        return latestId;
    }*/

    private static List<Error_Log__c> getResultLogs(List<Database.SaveResult> listSaveResults)   {
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        //2017-01-30 : SM : getDMLLog is now private so call getSaveResultLog instead
        errorLogs.addAll(ApplicationConstant.getSaveResultLog(listSaveResults, 'execute', CLASS_NAME, 'Lead', 'Update'));
        /*Error_Log__c log = new Error_Log__c();              
        for(Database.SaveResult saveResult : listSaveResults){
            log = ApplicationConstant.getDMLLog(saveResult, 'execute()', CLASS_NAME, 'Lead', 'Update');                    
            errorLogs.add(log);                
        }
        */
        return errorLogs;
    }
}