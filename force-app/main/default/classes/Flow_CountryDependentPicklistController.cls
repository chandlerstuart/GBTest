/*
Name: Flow_CountryDependentPicklistController.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Controller for Flow_CountryDependentPicklist Component
======================================================
======================================================

Tests:

History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-06-17  Initial development.
*/
public with sharing class Flow_CountryDependentPicklistController {
    
    @AuraEnabled
    public static List<Golfbreaks_Business_Unit__c> getPicklistData(){
        //Return the Defaults to the top of the list so they are presented first (unless explicitly set by the cmp input)
        return [Select Id, Name, IsDefault__c, (Select Id, Name, BusinessUnit__c, Countries__c, IsDefault__c From Territories__r Order By IsDefault__c DESC) From Golfbreaks_Business_Unit__c Order By IsDefault__c DESC];
    }
}