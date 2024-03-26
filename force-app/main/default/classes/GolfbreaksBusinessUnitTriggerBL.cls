/*
Name:  GolfbreaksBusinessUnitTriggerBL
Copyright © 2018  Golfbreaks
======================================================
======================================================
Purpose:
-------

Golfbreaks_Business_Unit__c Trigger BL class encapsulating the 
business logic for GBU Trigger records

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-05-08  Initial development.
*/
public without sharing class GolfbreaksBusinessUnitTriggerBL {

    //This method unticks the previous default Business Unit a new default is selected or created
    public static void untickPreviousDefaultBusinessUnit(Map<Id,Golfbreaks_Business_Unit__c> newMap , Map<Id,Golfbreaks_Business_Unit__c> oldMap){

        Id newDefaultId;

        if(trigger.isUpdate){
            for(Golfbreaks_Business_Unit__c newBU : newMap.values()){
                Golfbreaks_Business_Unit__c oldBU = oldMap.get(newBU.Id);
                if(newBU.IsDefault__c && !oldBU.IsDefault__c){
                    newDefaultId = newBU.Id;
                    break;
                }
            }
        }else if(trigger.isInsert){
            for(Golfbreaks_Business_Unit__c newBU : newMap.values()){
                if(newBU.IsDefault__c){
                    newDefaultId = newBU.Id;
                    break;
                }
            }
        }

        if(newDefaultId != null){

            List<Golfbreaks_Business_Unit__c> businessUnitsToUpdate = new List<Golfbreaks_Business_Unit__c>();
            
            for(Golfbreaks_Business_Unit__c bu : [Select Id From Golfbreaks_Business_Unit__c Where IsDefault__c = true and (NOT Id =:newDefaultId)]){
                bu.IsDefault__c = false;
                businessUnitsToUpdate.add(bu);
            }

            if(businessUnitsToUpdate.size()>0){
                Database.SaveResult[] results = database.update(businessUnitsToUpdate,false);
                PlatformLogManager.logExceptions(results, 'GolfbreaksBusinessUnitTriggerBL', 'untickPreviousDefaultBusinessUnit', businessUnitsToUpdate);
            }

        }
    }

    //This method forces the user to choose a new default Business Unit before deleting the current default
    public static void blockTheDeletionOfDefaultBusinessUnit(List<Golfbreaks_Business_Unit__c> deletedRecords){
        
        for(Golfbreaks_Business_Unit__c bu : deletedRecords){
            if(bu.IsDefault__c){
                bu.addError(ApplicationConstant.BUSINESS_UNIT_DEFAULT_DELETION_ERROR);
            }
        }

    }

//The API Requires a Default Business Unit to be stamped against an enquiry in instances where a valid BU cannot be identified
//This method ensures a single default Business Unit always exists. If no default is found it will set the oldest as the default, else it will create a new default BU
    public static void checkAndSetDefaultBusinessUnit(){
    
        //Query all Business Units floating the Default to the top
        Golfbreaks_Business_Unit__c[] gbus = [Select Id, Name, IsDefault__c From Golfbreaks_Business_Unit__c Order By IsDefault__c DESC,CreatedDate ASC];

        //Only proceed if no default is retrieved
        if(gbus.size()==0 || !gbus[0].IsDefault__c){

            List<Golfbreaks_Business_Unit__c> businessUnitUpsertList = new List<Golfbreaks_Business_Unit__c>();

            if(gbus.size()>0){
                //Set the oldest existing Business Unit as the default
                gbus[0].IsDefault__c = true;
                businessUnitUpsertList.add(gbus[0]);
            }else{
                //Insert a new default Business Unit
                Golfbreaks_Business_Unit__c bu = new Golfbreaks_Business_Unit__c();
                bu.Name = 'Default Business Unit';
                bu.IsDefault__c = true;
                //Note - 'Booking System' will adopt the configured default
                businessUnitUpsertList.add(bu);
            }

            //Upsert Business Units
            if(businessUnitUpsertList.size()>0){
                Database.UpsertResult[] results = database.upsert(businessUnitUpsertList, false);
                PlatformLogManager.logExceptions(results, 'GolfbreaksBusinessUnitTriggerBL', 'checkAndSetDefaultBusinessUnit', businessUnitUpsertList);
            }
        }
    }

}