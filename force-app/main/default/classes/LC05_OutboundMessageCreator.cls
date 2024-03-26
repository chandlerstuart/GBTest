/*
Name:  OutboundMessageCreator.cls
Copyright © 2016  Golf Breaks Offshore Team
======================================================
======================================================
Purpose:
-------
This class constructs a dynamic query string based on OutboundFieldMapping__c custom setting and an Object that will be serialized as JSON string for HTTP Request Body
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Rom R.        2016-03-30  Initial development.
2.0  Nicole DG     2016-04-01  Code clean-up
3.0  Bryanne P.    2016-04-08  Change the name of the class to VFC01_OutboundMessageCreator
4.0  Merari C.     2016-04-14  Created buildEnquiryClientRequestWrapper Method
2.0  Merari C.     2016-04-14  Updated buildEnquiryClientRequestWrapper Method to include AccountManager
3.0  Simon M.      2016-12-01  Fork in code between CLIENT or ENQUIRY wrapper type
3.1  Simon M.      2017-04-21  Added in new functionality for 'Is PGA' processing
3.2  Simon M.      2017-08-09  New method to build request wrapper for update of Enquiry Account Manager (owner) in Clubbouse
3.3  James Radcliffe 2018-05-04 Retiring the Newsletter Sign Up field (to be replaced by GDPR Preference Centre) - Hard Set to False (CH does not accept null values)
*/
public with sharing class LC05_OutboundMessageCreator
{
    
    /*************************************************************************************** 
    Developer -    Merari Cebrian (Accenture)
    Date -         14/04/2016
    Version -      4.0 
    Function -     Build EnquiryClientRequestWrapper class using an Lead Record
    #############Change Log#############
    Modified by     Version     Change Date 
    ****************************************************************************************/
    public static EnquiryClientRequestWrapper buildEnquiryClientRequestWrapper(String objectRecordId, String wrapperType){
        String soql = '';
        String objectFields = '';
        List<SObject> sobjectRecord;
        Set<String> setObjectFields = new Set<String>();
        //wrapper class for client request
        EnquiryClientRequestWrapper enqClientRequestWrapper = new EnquiryClientRequestWrapper(); 
        //Map for sales region and numeric values
        Map<String, String> salesRegionMap = getSalesRegionMap();
        if( String.isNotBlank(objectRecordId) ){
            Id recordId = (Id)objectRecordId;

            // Get the Object Type
            Schema.SObjectType objectType = recordId.getSobjectType();
            // Process custom setting records
            List<Object_Field_Mapping__c> checkOFMList = ApplicationConstant.CUSTOM_SETTING_OBJECT_FIELD_MAPPING_SETTING.values();
            
            for(Object_Field_Mapping__c objectFieldMapping : ApplicationConstant.CUSTOM_SETTING_OBJECT_FIELD_MAPPING_SETTING.values()){
                if( objectFieldMapping.Object_API_Name__c == String.ValueOf(objectType) ){
                    if( objectFields == '' ){
                        objectFields += objectFieldMapping.Field_API_Name__c;
                    }
                    else{
                        objectFields += ',' + objectFieldMapping.Field_API_Name__c;
                    }
                    setObjectFields.add(objectFieldMapping.Field_API_Name__c);
                }            
            }

            // Query Object and get record        
            soql = 'SELECT ' + objectFields + ' FROM ' + String.ValueOf(objectType) + ' WHERE Id =: objectRecordId ';
            system.debug('Query: ' + soql);

            try{
                sobjectRecord = Database.query(soql);  
            } catch(QueryException e) {
                throw e;
            }

            // Convert general SObject to an Lead
            if(!sobjectRecord.isEmpty()){
                Lead leadRecord = (Lead)sobjectRecord[0];
                if( leadRecord <> null && leadRecord.Id <> null ){
                    if ('ENQUIRY'.equalsIgnoreCase(wrapperType)){
                        //2017-04-21 : SM : Get the PGA Pro Record Type so we can get the Developer Name to pass into the request if the Lead is a PGA lead
                        /*
                        List<RecordType> pgaProList = [select Id, DeveloperName from RecordType where DeveloperName = 'PGA_Pro' AND SObjectType = 'Account' LIMIT 1];
                        //2017-04-21 : SM : If the Lead is a PGA Lead, then grab the Record Type Developer Name and pass that into the request
                        system.debug('*** -- Lead is PGA = ' + leadRecord.PGA__c + ' -- ***');
                        if (leadRecord.PGA__c){
                            system.debug('*** -- setting RT Developer Name ' + pgaProList[0].DeveloperName + ' -- ***');
                            enqClientRequestWrapper.RecordTypeDeveloperName = pgaProList[0].DeveloperName;
                        }
                        */
                        // Populate Account Client Request Wrapper
                        enqClientRequestWrapper.AdditionalInformation = leadRecord.AdditionalInformation__c;
                        enqClientRequestWrapper.AffiliateCampaignID = leadRecord.GolfBreaks_Campaign_ID__c;
                        enqClientRequestWrapper.ClientAccountID = leadRecord.Account__c;
                        enqClientRequestWrapper.Email = leadRecord.Email;
                        // enqClientRequestWrapper.FirstName = leadRecord.Account__c <> null ? leadRecord.FirstName : 'Not_Provided';
                        enqClientRequestWrapper.FirstName = leadRecord.FirstName;
                        enqClientRequestWrapper.LastName = leadRecord.LastName;
                        enqClientRequestWrapper.Title = leadRecord.Salutation;
                        //Retiring the Newsletter Sign Up field (to be replaced by GDPR Preference Centre) 04/05/18 - Hard Setting to False (CH does not accept null values)
                        //enqClientRequestWrapper.NewsletterSignUp = leadRecord.NewsletterSignUp__c;
                        enqClientRequestWrapper.NewsletterSignUp = false;
                        enqClientRequestWrapper.Nights = leadRecord.Nights__c;
                        //enqClientRequestWrapper.Phone = leadRecord.MobilePhone;
                        enqClientRequestWrapper.Phone = getPhone(leadRecord);
                        enqClientRequestWrapper.PreferredTravelDate = leadRecord.PreferredTravelDate__c;
                        enqClientRequestWrapper.PromotionCode = leadRecord.PromoCode__c;
                        enqClientRequestWrapper.Salutation = leadRecord.Salutation;
                        enqClientRequestWrapper.TravelGroupSize = leadRecord.TravelGroupSize__c;
                        enqClientRequestWrapper.TripRegion = salesRegionMap.get(leadRecord.SalesRegion__c);
                        enqClientRequestWrapper.Venue = leadRecord.Venue__c;
                        enqClientRequestWrapper.VenueAccountIDs = new List<String>(); 
                        List<User> leadownerList = [Select Email, Id, Golfbreaks_Employee_Id__c FROM User WHERE Id =: leadRecord.OwnerId Limit 1];
                        if (!leadownerList.isEmpty()){
                            enqClientRequestWrapper.AccountManager = new EnquiryClientRequestWrapper.EmployeeModel(Integer.valueOf(leadownerList[0].Golfbreaks_Employee_Id__c), leadownerList[0].Email, '','');
                        }
                        //TODO : SalesforceAddressModel code goes here (see OpportunityCreationWizard.buildRequestWrapper)
                    }else if ('CLIENT'.equalsIgnoreCase(wrapperType)){
                        // Populate Account Client Request Wrapper
                        //2017-04-21 : SM : Get the PGA Pro Record Type so we can get the Developer Name to pass into the request if the Lead is a PGA lead
                        
                        List<RecordType> pgaProList = [select Id, DeveloperName from RecordType where DeveloperName = 'PGA_Pro' AND SObjectType = 'Account' LIMIT 1];
                        //2017-04-21 : SM : If the Lead is a PGA Lead, then grab the Record Type Developer Name and pass that into the request
                        system.debug('*** -- Lead is PGA = ' + leadRecord.PGA__c + ' -- ***');
                        if (leadRecord.PGA__c){
                            system.debug('*** -- setting RT Developer Name ' + pgaProList[0].DeveloperName + ' -- ***');
                            enqClientRequestWrapper.RecordTypeDeveloperName = pgaProList[0].DeveloperName;
                            enqClientRequestWrapper.IsPGA = TRUE;
                        }
                        
                        enqClientRequestWrapper.ClientAccountID = leadRecord.Account__c;
                        enqClientRequestWrapper.SalesChannel = 'GBDC';
                        enqClientRequestWrapper.Title = leadRecord.Salutation;
                        enqClientRequestWrapper.FirstName = leadRecord.FirstName;
                        enqClientRequestWrapper.LastName = leadRecord.LastName;
                        enqClientRequestWrapper.Email = leadRecord.Email;
                        enqClientRequestWrapper.PersonEmail = leadRecord.Email;
                        enqClientRequestWrapper.PersonHomePhone = leadRecord.HomePhone__c;
                        enqClientRequestWrapper.PersonMobilePhone = leadRecord.MobilePhone;
                        enqClientRequestWrapper.PersonOtherPhone = leadRecord.Phone;
                        //2017-10-17 : SM : Added in Newsletter Signup as part of the first Client Creation process
                        //2018-05-04 : JR : Retiring the Newsletter Sign Up field (to be replaced by GDPR Preference Centre) - Hard Setting to False (CH does not accept null values)
                        if (leadRecord.NewsletterSignup__c){
                          //  enqClientRequestWrapper.NewsletterSignUp = leadRecord.NewsletterSignUp__c;
                              enqClientRequestWrapper.NewsletterSignUp = false;
                        }
                        List<User> leadownerList = [Select Email, Id, Golfbreaks_Employee_Id__c FROM User WHERE Id =: leadRecord.OwnerId Limit 1];
                        if (!leadownerList.isEmpty()){
                            enqClientRequestWrapper.AccountManager = new EnquiryClientRequestWrapper.EmployeeModel(Integer.valueOf(leadownerList[0].Golfbreaks_Employee_Id__c), leadownerList[0].Email, '','');
                        }
                        //TODO : SalesforceAddressModel code goes here (see OpportunityCreationWizard.buildRequestWrapper)
                    }
                }
            }
        }

        return enqClientRequestWrapper;
    }

    /*************************************************************************************** 
    Developer -    Simon Molloy
    Date -         09/08/2017
    Version -      1.0 
    Function -     Build AccountManagerRequestWrapper object
    #############Change Log#############
    Modified by     Version     Change Date 
    ****************************************************************************************/
    public static AccountManagerRequestWrapper buildAccountManagerRequestWrapper(String objectRecordId, String sObjectType, integer entityType){
        AccountManagerRequestWrapper wrapper;
        if ('LEAD'.equalsIgnoreCase(sObjectType)){
            Lead leadRecord = [select Id, OwnerId, GolfbreaksEnquiryId__c from Lead where Id = :objectRecordId LIMIT 1];
            if (null != leadRecord){
                wrapper = new AccountManagerRequestWrapper(entityType, leadRecord.GolfbreaksEnquiryId__c);
                List<User> leadownerList = [Select Email, Id, Golfbreaks_Employee_Id__c FROM User WHERE Id =: leadRecord.OwnerId Limit 1];
                if (!leadownerList.isEmpty()){
                    wrapper.NewAccountManager = new EnquiryClientRequestWrapper.EmployeeModel(Integer.valueOf(leadownerList[0].Golfbreaks_Employee_Id__c), leadownerList[0].Email, '','');
                }
            }
        }

        return wrapper;
    }
    
    /*************************************************************************************** 
    Developer -    Merari Cebrian (Accenture)
    Date -         14/04/2016
    Version -      4.0 
    Function -     Build TripRegionMap
    #############Change Log#############
    Modified by     Version     Change Date 
    ****************************************************************************************/
    Private static Map<String, String> getSalesRegionMap() {
        
        Map<String, String> salesRegionMap = new Map<String, String>();
        salesRegionMap.put('', '0');
        salesRegionMap.put(ApplicationConstant.SALESREGIONGROUP_UK_IRELAND, '1');
        salesRegionMap.put(ApplicationConstant.SALESREGIONGROUP_EUROPE, '2');
        salesRegionMap.put(ApplicationConstant.SALESREGIONGROUP_USA, '3');
        salesRegionMap.put(ApplicationConstant.SALESREGIONGROUP_FDP, '3');
        salesRegionMap.put(ApplicationConstant.SALESREGIONGROUP_LONGHAUL, '4');
        salesRegionMap.put(ApplicationConstant.SALESREGIONGROUP_MIDHAUL, '4');
        return salesRegionMap;
    }

    /*************************************************************************************** 
    Developer -    Jerome To (Accenture)
    Date -         06/07/2016
    Version -      1.0 
    Function -     Get Phone
    #############Change Log#############
    Modified by     Version     Change Date 
    ****************************************************************************************/
    static String getPhone(Lead leadRecord){
        if(!String.isBlank(leadRecord.MobilePhone)) {
            return leadRecord.MobilePhone;
        } else if (!String.isBlank(leadRecord.Phone)) {
            return leadRecord.Phone;
        } else {
            return leadRecord.HomePhone__c;
        }
    }
}