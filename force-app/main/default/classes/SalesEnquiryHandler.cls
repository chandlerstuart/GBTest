/*
Name: SalesEnquiryHandler.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Local class to process Inbound API Enquiries/Flow Sales Enquiries
and perform activities which require access to the local schema
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-05-20  Initial development.
1.1  J Radcliffe   2019-06-03  Exclude Enquiries with errors
1.2  J Radcliffe   2019-06-10  Extended Error Logging
1.3  J Radcliffe   2019-07-01  Custom Exception for Unit Testing Exception Coverage
1.4  J Radcliffe   2020-03-26  Apply Local Date Formatting to Record Name
1.5  Mark Cane&    2023-08-21  Bug fixes. Sporadic null dereference error in dedupeSalesEnquiries method.
*/
public with sharing class SalesEnquiryHandler implements IEnquiryRecordHandler{

    @TestVisible static Boolean isTest = false;
    @TestVisible static Boolean throwError = false;
    
    public Boolean processEnquiries(List<EnquiryManager.Enquiry> enquiries) {
        try{
            if(enquiries == null) return true;
            //Calculate the Enquiry.TripDetails.territoryId for de-duplication purposes
            calculateSalesEnquiryTerritories(enquiries);
            //Handle potential duplicate enquiries
            dedupeSalesEnquiries(enquiries);
            //Set Defaults (i.e. construct the Opportunity Name from the Account details and current date)
            setDefaults(enquiries);
        }catch(exception e){
            PlatformLogManager.logExceptions(e, 'SalesEnquiryHandler', 'processEnquiries');
            return false;
        }
        return true;
    }

    //Derives the relevant enquiry Territory based on the Business Unit and Countries provided
    public static void calculateSalesEnquiryTerritories(List<EnquiryManager.Enquiry> enquiries){
        
        if(throwError) throw new TestCodeException('Test Code Exception');//1.3

        ActionType__mdt actionType;
        for(EnquiryManager.Enquiry e : enquiries){
            if(e.isAborted) continue;//1.1
            if(e.actionType != null){
                actionType = e.actionType; 
                break;
            }
        }
        if(actionType==null) return;//1.5+ -- it's not clear how enquiry records make it to this point without an assigned actionType.

        //Get Territory Data for the corresponding Business Unit
        List<Territory__c> territories = [Select Id, IsDefault__c, Countries__c, BusinessUnit__c From Territory__c Where BusinessUnit__c = :actionType.BusinessUnit__c Order By IsDefault__c DESC,CreatedDate ASC Limit 500];

        if(territories.size()==0){
            for(EnquiryManager.Enquiry enq : enquiries){
                enq.errorMessages.put('3020',Label.Enquiry_Logic_Error_No_Territories_Found);//1.2
                return;
            }
        }

        //Restructure the data into an accessible format
        Map<Id,List<String>> territoryIdsWithCountries = new Map<Id,List<String>>();
        Id defaultTerritoryId;

        for(Territory__c t : territories){
            List<String> countries = new List<String>();
            if(t.Countries__c != null) countries = t.Countries__c.split(';');
            territoryIdsWithCountries.put(t.Id,countries);
            if(t.IsDefault__c && defaultTerritoryId == null) defaultTerritoryId = t.Id;
        }
    
        system.debug('FIND ME>>> territoryIdsWithCountries: '+territoryIdsWithCountries);
        system.debug('FIND ME>>> enquiries[0].tripDetails.countries: '+enquiries[0].tripDetails.countries);

        //Loop through and apply relevant Territory to each enquiry
        for(EnquiryManager.Enquiry enq : enquiries){

            //Do not process enquiries with failures
            if(enq.isAborted) continue;//1.1
            
            //Exit if the Territory has been explicitly set in the call
            if(enq.TripDetails.territoryId != null) continue;

            //Apply the default territory if no countries have been specified in the request (valid territory cannot be identified)
            if(enq.TripDetails.countries == null && defaultTerritoryId != null) enq.TripDetails.territoryId = defaultTerritoryId;

            if(enq.TripDetails.countries != null){
                List<Id> applicableTerritories = new List<Id>();
                for(Territory__c t : territories){
                    if(t.Countries__c == null) continue;
                    List<String> tCountries = t.Countries__c.split(';');
                    for(String country : tCountries){
                        if(enq.TripDetails.countries.contains(country)){
                            applicableTerritories.add(t.Id);
                            break;
                        } 
                    }
                }
                //If ONE suitable Territory has been identified, apply to the Enquiry
                if(applicableTerritories.size()==1){
                    enq.TripDetails.territoryId = applicableTerritories[0];
                    enq.propertyCache.put('TripDetails.territoryId',applicableTerritories[0]);
                } 

                //If none or multiple territories are applicable, apply the default
                if(applicableTerritories.size() != 1 && defaultTerritoryId != null){
                    enq.TripDetails.territoryId = defaultTerritoryId;
                    enq.propertyCache.put('TripDetails.territoryId',defaultTerritoryId);
                } 
                //One final check to verify that a territory has been successfully applied to each enquiry
                if(enq.TripDetails.territoryId == null){
                    enq.errorMessages.put('3030',Label.Enquiry_Logic_Error_No_Territories_Found);
                }
            }
        }
    }

    //Checks for existing records within the org and captures the duplicate record Id on the Enquiry
    public static void dedupeSalesEnquiries(List<EnquiryManager.Enquiry> enquiries){
        
        if(throwError) throw new TestCodeException('Test Code Exception');//1.3

        ActionType__mdt actionType;
        for(EnquiryManager.Enquiry e : enquiries){
            if(e.actionType != null){
                if(e.isAborted) continue;//1.1
                actionType = e.actionType; 
                break;
            }
        }
        if (actionType==null) return;//1.5~

        //Parameters for limiting the query search
        Set<Id> accountIds = new Set<Id>();
        Set<Id> territoryIds = new Set<Id>();
        
        for(EnquiryManager.Enquiry enq : enquiries){
            if(enq.ClientDetails.accountId != null && !accountIds.contains(enq.ClientDetails.accountId)) accountIds.add(enq.ClientDetails.accountId);
            if(enq.TripDetails.territoryId != null && !territoryIds.contains(enq.TripDetails.territoryId)) territoryIds.add(enq.TripDetails.territoryId);
        }  
        //Query potential duplicatesaction
        List<Opportunity> possibleDupes = new List<Opportunity>();
        possibleDupes = [Select Id, AccountId, Territory__c From Opportunity Where AccountId In :accountIds and Territory__c In :territoryIds and IsOpen__c = true and RecordTypeId = :actionType.RecordTypeId__c];
        
        Map<String,Id> keyToOpportunityIDMap = new Map<String,Id>();
        for(Opportunity opp : possibleDupes){
            keyToOpportunityIdMap.put(opp.Territory__c+''+opp.AccountId, opp.Id);
        }

        //Loop through 'enquiry' records
        for(EnquiryManager.Enquiry enq : enquiries){
            if(enq.isAborted) continue;//1.1 
            //If a dupe exists, set the Id against the Enquiry
            String dupeCheckKey = enq.tripDetails.territoryId+''+enq.clientDetails.accountId;
            if(keyToOpportunityIdMap.containsKey(dupeCheckKey)){
                enq.duplicateEnquiryId = keyToOpportunityIdMap.get(dupeCheckKey);
                enq.recordStatus = ApplicationConstant.OPP_STAGE_DUPLICATE;
            }
        }
    }

    //Sets default attributes on the enquiry
    public static void setDefaults(List<EnquiryManager.Enquiry> enquiries){
        
        Map<Id,Golfbreaks_Business_Unit__c> busUnitMap = new Map<Id,Golfbreaks_Business_Unit__c>([Select Id, LocaleSettings__c From Golfbreaks_Business_Unit__c]);//1.4+

        if(throwError) throw new TestCodeException('Test Code Exception');//1.3

        //Set recordName attribute - constructed from client details and current date
        Datetime dt = system.today();
        String formattedDate; 
        for(EnquiryManager.Enquiry enq : enquiries){
            if(enq.isAborted) continue;//1.1
            if(busUnitMap.keySet().size() == 0 || enq.getValue('ActionType.businessUnitId') == null  
                || !busUnitMap.containsKey((String)enq.getValue('ActionType.businessUnitId')) || busUnitMap.get((String)enq.getValue('ActionType.businessUnitId')).LocaleSettings__c == null){//1.4+
                formattedDate = dt.format('dd/MM/YYYY');//Default to en-gb
            }else{//1.4+
                formattedDate = LocaleSettingsHelper.getLocalDateFormatString(busUnitMap.get((String)enq.getValue('ActionType.businessUnitId')).LocaleSettings__c,dt);
            }
            enq.recordName = enq.clientDetails.firstName+' '+enq.clientDetails.lastName+' - '+formattedDate;
        }

    } 

    

    

}