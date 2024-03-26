/*
Name:  TerritoryTriggerBL
Copyright © 2018  Golfbreaks
======================================================
======================================================
Purpose:
-------

Territory__c Trigger BL class encapsulating the 
business logic for Territory Trigger records

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-05-07  Initial development.
*/
public without sharing class TerritoryTriggerBL {

    //This method unticks the previous default territory for the matching business unit when a new default territory is selected or created
    public static void untickPreviousDefaultTerritories(Map<Id,Territory__c> newMap , Map<Id,Territory__c> oldMap){

        Set<Id> businessUnitIds = new Set<Id>();
        Set<Id> newDefaultIds = new Set<Id>();

        if(trigger.isUpdate){
            for(Territory__c newT : newMap.values()){
                Territory__c oldT = oldMap.get(newT.Id);
                if(newT.IsDefault__c && !oldT.IsDefault__c && !businessUnitIds.contains(newT.BusinessUnit__c)){
                    businessUnitIds.add(newT.BusinessUnit__c);
                    newDefaultIds.add(newT.Id);
                }
            }
        }else if(trigger.isInsert){
            for(Territory__c newT : newMap.values()){
                if(newT.IsDefault__c && !businessUnitIds.contains(newT.BusinessUnit__c)){
                    businessUnitIds.add(newT.BusinessUnit__c);
                    newDefaultIds.add(newT.Id);
                }
            }
        }

        if(businessUnitIds.size()>0){

            List<Territory__c> territoriesToUpdate = new List<Territory__c>();
            for(Territory__c t : [Select Id From Territory__c Where BusinessUnit__c in:businessUnitIds and IsDefault__c = true and (NOT Id in:newDefaultIds)]){
                t.IsDefault__c = false;
                territoriesToUpdate.add(t);
            }

            if(territoriesToUpdate.size()>0){
                Database.SaveResult[] results = database.update(territoriesToUpdate,false);
                PlatformLogManager.logExceptions(results, 'TerritoryTriggerBL', 'untickPreviousDefaultTerritories', territoriesToUpdate);
            }

        }
    }

    //This method forces the user to choose a new default territory before deleting the current default
    public static void blockTheDeletionOfDefaultTerritories(List<Territory__c> deletedRecords){
        
        for(Territory__c t : deletedRecords){
            if(t.IsDefault__c){
                t.addError(ApplicationConstant.TERRITORY_DEFAULT_DELETION_ERROR);
            }
        }

    }

//Every Business Unit must have a default territory
//This method ensures a single default territory always exists for every business unit. If a business unit has no default it will;
//a) Update the first (oldest) territory to be the default OR b) Create a new default Territory
    public static void checkAndSetDefaultTerritories(){
    
        //Query all Business Units without a default (and child territories)
        Golfbreaks_Business_Unit__c[] gbus = [Select Id, Name, (Select Id, IsDefault__c From Territories__r Order By CreatedDate ASC) From Golfbreaks_Business_Unit__c Where Id NOT In(Select BusinessUnit__c From Territory__c Where IsDefault__c = true)];

        //Only proceed if bu's without a default territory exist
        if(gbus.size()>0){

            List<Territory__c> territoryUpsertList = new List<Territory__c>();

            //Loop through each Business Unit
            for(Golfbreaks_Business_Unit__c bu: gbus){
                if(bu.Territories__r.size()>0){
                    //Set the oldest existing territory as the default
                    bu.Territories__r[0].IsDefault__c = true;
                    territoryUpsertList.add(bu.Territories__r[0]);
                }else{
                    //Insert a new default territory
                    Territory__c t = new Territory__c();
                    t.Name = bu.Name+' Default';
                    t.IsDefault__c = true;
                    t.BusinessUnit__c = bu.Id;
                    territoryUpsertList.add(t);
                }
            }
            //Upsert Territories
            if(territoryUpsertList.size()>0){
                Database.UpsertResult[] results = database.upsert(territoryUpsertList, false);
                PlatformLogManager.logExceptions(results, 'TerritoryTriggerBL', 'checkAndSetDefaultTerritories', territoryUpsertList);
            }
        }
    }

    //This method forces the user to remove the country from the existing Territory before it can be applied to a new Territory.
    //It ensures that a country can belong to only one territory (per Business Unit)
    public static void territoryCountryValidation(List<Territory__c> newList, Map<Id,Territory__c> oldMap){
        
        List<Territory__c> processList = new List<Territory__c>();
        Set<Id> businessUnitIds = new Set<Id>();

        //Isolate select records for processing
        for(Territory__c newT : newList){
            if(oldMap == null){
                //New Territories;
                if(newT.Countries__c != null){
                    processList.add(newT);
                    if(!businessUnitIds.contains(newT.BusinessUnit__c)) businessUnitIds.add(newT.BusinessUnit__c);
                    continue;
                }
            }else{
                //Updated Territories;
                Territory__c oldT = oldMap.get(newT.Id);
                if(oldT.Countries__c != newT.Countries__c && newT.Countries__c != null){
                    processList.add(newT);
                    if(!businessUnitIds.contains(newT.BusinessUnit__c)) businessUnitIds.add(newT.BusinessUnit__c);
                    continue;
                }
            }
        }

        //Only proceed if a new territory is inserted (with)
        if(processList.size()>0){

            //Get Data
            Territory__c[] territories = [Select Id, Countries__c, BusinessUnit__c From Territory__c Where BusinessUnit__c In:businessUnitIds and Countries__c != null];
            
            Map<Id,Map<String,Id>> businessUnitWithCountryTerritoryMap = new Map<Id,Map<String,Id>>();

            for(Territory__c t : territories){
                List<String> countries = t.Countries__c.split(';');
                if(businessUnitWithCountryTerritoryMap == null) businessUnitWithCountryTerritoryMap = new Map<Id,Map<String,Id>>();
                if(!businessUnitWithCountryTerritoryMap.containsKey(t.BusinessUnit__c)){
                    Map<String,Id> countryTerritoryMap = new Map<String,Id>();
                    businessUnitWithCountryTerritoryMap.put(t.BusinessUnit__c,countryTerritoryMap);
                }
                for(String country : countries){
                    Map<String,Id> countryTerritoryMap = businessUnitWithCountryTerritoryMap.get(t.BusinessUnit__c);
                    if(!countryTerritoryMap.containsKey(country)) countryTerritoryMap.put(country,t.Id);
                    businessUnitWithCountryTerritoryMap.put(t.BusinessUnit__c,countryTerritoryMap);
                }
            }

            //Loop through and evaluate process records
            for(Territory__c t : processList){
                Map<String,Id> countryTerritoryMap = businessUnitWithCountryTerritoryMap.get(t.BusinessUnit__c);
                if(countryTerritoryMap == null) continue;
                List<String> newCountries = t.Countries__c.split(';');
                for(String country : newCountries){
                    //If there is an existing territory with the country applied, throw an error
                    if(countryTerritoryMap.containsKey(country) && t.Id != countryTerritoryMap.get(country)){
                        t.addError(ApplicationConstant.TERRITORY_COUNTRY_VALIDATION_ERROR+': Country: '+country+', Territory: '+countryTerritoryMap.get(country));
                    }
                }
            }
        }

    }

}