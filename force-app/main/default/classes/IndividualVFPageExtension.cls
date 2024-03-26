/*
Name:  IndividualTriggerHandler.cls
======================================================
======================================================
Purpose:
-------
Extension Class for the IndividualVFPage

======================================================
======================================================
History
------- 
Ver. Author           Date        Detail
1.0  James Radcliffe  18/04/2018  Initial Development.
*/
public class IndividualVFPageExtension {
    
    public List<Preference_Centre_Change__b> changeHistory {get;set;}
    
    public IndividualVFPageExtension(ApexPages.StandardController sc){
        
        Id individualId = sc.getId();
        system.debug('Individual Id: '+individualId);
        
        changeHistory = [Select Id, CreatedBy.Name, CreatedDate, SystemModstamp, Account__c, Date__c, New_Value__c, Old_Value__c, Detail__c, Preference__c From Preference_Centre_Change__b Where Individual__c = :individualId LIMIT 50];
        
        
    }

}