/*
Name:  GolfbreaksBusinessUnitTriggerHandler
Copyright © 2018  Golfbreaks
======================================================
======================================================
Purpose:
-------

Golfbreaks_Business_Unit__c Trigger Handler Class 
to facilitate the processing of GBU Trigger records

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-05-08  Initial development.
*/
public without sharing class GolfbreaksBusinessUnitTriggerHandler {

    //Static flags to control recursion
    public static Boolean isFirstAfterInsert = true;
    public static Boolean isFirstAfterUpdate = true;
    public static Boolean isFirstBeforeDelete = true;    

    public void onBeforeDelete(List<Golfbreaks_Business_Unit__c> oldList){
        
        if(isFirstBeforeDelete){
            isFirstBeforeDelete = false;

            //Force the user to select a new default before deleting the current default Business Unit
            GolfbreaksBusinessUnitTriggerBL.blockTheDeletionOfDefaultBusinessUnit(oldList);
        }

    }

    public void onAfterInsert(List<Golfbreaks_Business_Unit__c> newList, Map<Id,Golfbreaks_Business_Unit__c> newMap){

        if(isFirstAfterInsert){
            isFirstAfterInsert = false;
            
            //Remove the previous default Business Unit if a new default has been chosen
            GolfbreaksBusinessUnitTriggerBL.untickPreviousDefaultBusinessUnit(newMap, null);
            //Ensure a default Business Unit exists for every business unit after insert
            GolfbreaksBusinessUnitTriggerBL.checkAndSetDefaultBusinessUnit();
            
            
        }
        
    }

    public void onAfterUpdate(Map<Id,Golfbreaks_Business_Unit__c> newMap,Map<Id,Golfbreaks_Business_Unit__c> oldMap){
        if(isFirstAfterUpdate){
            isFirstAfterUpdate = false;

            //Remove the previous default Business Unit if a new default has been chosen
            GolfbreaksBusinessUnitTriggerBL.untickPreviousDefaultBusinessUnit(newMap, oldMap);
            //Ensure a default Business Unit exists for every business unit after update
            GolfbreaksBusinessUnitTriggerBL.checkAndSetDefaultBusinessUnit();
            
            
        }
    }

}