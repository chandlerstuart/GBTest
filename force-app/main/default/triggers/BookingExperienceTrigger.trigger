/*
Name:  BookingExperienceTrigger
Copyright © 2023  Golfbreaks
======================================================
======================================================
Purpose:
-------

Centralised trigger for the Custom Object : BookingExperience__c

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-05-07  Initial development. Added support for Entity Administration Lock protection.
*/
trigger BookingExperienceTrigger on BookingExperience__c (before insert, before update, before delete, after insert, after update) {
    golfbreaks.EntityAdministrationLockManager.checkPermissions();//1.1+
    
}