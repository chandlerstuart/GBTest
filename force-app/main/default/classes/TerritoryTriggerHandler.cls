/*
Name:  TerritoryTriggerHandler
Copyright © 2018  Golfbreaks
======================================================
======================================================
Purpose:
-------

Territory__c Trigger Handler Class to facilitate the
processing of Territory Trigger records

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-05-07  Initial development.
*/
public without sharing class TerritoryTriggerHandler {

    //Static flags to control recursion
    public static Boolean isFirstAfterInsert = true;
    public static Boolean isFirstAfterUpdate = true;
    public static Boolean isFirstBeforeDelete = true;
    public static Boolean isFirstBeforeUpdate = true;
    public static Boolean isFirstBeforeInsert = true;
    

    public void onBeforeDelete(List<Territory__c> oldList){
        
        if(isFirstBeforeDelete){
            isFirstBeforeDelete = false;

            //Force the user to select a new default before deleting the current default territory
            TerritoryTriggerBL.blockTheDeletionOfDefaultTerritories(oldList);
        }

    }

    public void onBeforeInsert(List<Territory__c> newList){
        
        if(isFirstBeforeInsert){
            isFirstBeforeInsert = false;

            //Force user to remove Country from existing territory before applying to another territory
            TerritoryTriggerBL.territoryCountryValidation(newList, null);

        }

    }

    public void onBeforeUpdate(List<Territory__c> newList, Map<Id,Territory__c> oldMap){
        
        if(isFirstBeforeUpdate){
            isFirstBeforeUpdate = false;

            //Force user to remove Country from existing territory before applying to another territory
            TerritoryTriggerBL.territoryCountryValidation(newList, oldMap);
            
        }

    }

    public void onAfterInsert(List<Territory__c> newList, Map<Id,Territory__c> newMap){

        if(isFirstAfterInsert){
            isFirstAfterInsert = false;
            
            //Remove the previous default territory if a new default has been chosen
            TerritoryTriggerBL.untickPreviousDefaultTerritories(newMap, null);
            //Ensure a default territory exists for every business unit after insert
            TerritoryTriggerBL.checkAndSetDefaultTerritories();
            
            
        }
        
    }

    public void onAfterUpdate(Map<Id,Territory__c> newMap,Map<Id,Territory__c> oldMap){
        if(isFirstAfterUpdate){
            isFirstAfterUpdate = false;

            //Remove the previous default territory if a new default has been chosen
            TerritoryTriggerBL.untickPreviousDefaultTerritories(newMap, oldMap);
            //Ensure a default territory exists for every business unit after update
            TerritoryTriggerBL.checkAndSetDefaultTerritories();
            
            
        }
    }

}