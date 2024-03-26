/*
Name: ActionTypeHelper.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Action Type Helper class.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-05-13  Initial development.
1.1  J Radcliffe   2019-05-15  Code integration changes.
1.2  J Radcliffe   2019-05-21  New method to set parameters on the Enquiry from settings on the Action Type (required for field mapping)
1.3  J Radcliffe   2019-08-15  Added 'ClientFieldMappingGroup__c' and 'WorkItemFieldMappingGroup__c' to Action Type Query
1.4  J Radcliffe   2019-09-03  Added 'ClientDuplicateRuleDeveloperName__c' to Action Type Query
1.5  Mark Cane&    2019-08-07  Removed Booking System references. 
1.6  J Radcliffe   2019-10-28  Added 'SendToExternalSystem__c' to Action Type Query
1.7  J Radcliffe   2020-10-05  Added 'IndividualFieldMappingGroup__c' to Action Type Query
1.8  Mark Cane&    2023-12-05  Added getPropertyDataType.
*/
public with sharing class ActionTypeHelper{
    
    public static ActionType__mdt getActionTypeByName(String actionTypeName){//1.1~

        List<ActionType__mdt> actionTypes = [select Id, DeveloperName, BusinessUnit__c, SObjectType__c, RecordStageStatus__c,
                                                DupeMatchAction__c, RecordTypeId__c, RouteOnCreate__c, RecordHandlerClassName__c, CreateEnquiry__c, IndividualFieldMappingGroup__c,//1.7~ 
                                                ClientFieldMappingGroup__c, WorkItemFieldMappingGroup__c, ClientDuplicateRuleDeveloperName__c,SendToExternalSystem__c//1.3+//1.4+//1.6~
                                                from ActionType__mdt 
                                                where DeveloperName=:actionTypeName];//1.3~ BookingSystem__c field removed from query.
        
        return actionTypes.isEmpty() ? null : actionTypes[0];
    }

    public static IEnquiryRecordHandler getHandlerClass(String recordHandlerClassName){//1.1~
        
        IEnquiryRecordHandler recordHandler;

        try {
                    
    	    Type t;
            t=Type.forName(null,recordHandlerClassName);

            recordHandler=(IEnquiryRecordHandler)t.newInstance();
		} catch (Exception e) { return null; }
        return recordHandler;
    }

    public static EnquiryManager.Enquiry addActionTypeSettingsToEnquiryPropertyCache(EnquiryManager.Enquiry enquiry, ActionType__mdt actionType){
        
        if(enquiry == null || actionType == null) return enquiry;

        if(enquiry.propertyCache == null) enquiry.propertyCache = new Map<String,Object>();
        if(actionType.BusinessUnit__c != null) enquiry.propertyCache.put('ActionType.businessUnitId', String.isNotBlank(enquiry.businessUnitId) ? enquiry.businessUnitId : actionType.BusinessUnit__c);
        //1.5- if(actionType.BookingSystem__c != null) enquiry.propertyCache.put('ActionType.bookingSystem', String.isNotBlank(enquiry.bookingSystem) ? enquiry.bookingSystem : actionType.BookingSystem__c);
        if(actionType.RecordTypeId__c != null) enquiry.propertyCache.put('ActionType.recordTypeId', String.isNotBlank(enquiry.enquiryRecordTypeId) ? enquiry.enquiryRecordTypeId : actionType.RecordTypeId__c);
        if(actionType.RecordStageStatus__c != null) enquiry.propertyCache.put('ActionType.status', String.isNotBlank(enquiry.recordStatus) ? enquiry.recordStatus : actionType.RecordStageStatus__c);
        if(actionType.RouteOnCreate__c != null) enquiry.propertyCache.put('ActionType.routeOnCreate', enquiry.routeOnCreate!=null ? enquiry.routeOnCreate : actionType.RouteOnCreate__c);
        enquiry.propertyCache.put('ActionType.developerName',actionType.DeveloperName);

        return enquiry;
    }

    public static ActionType__mdt getActionTypeForToAddressesAndKeyPrefix(List<String> toAddresses, String keyPrefix){//1.4+

        List<String> localToAddresses = new List<String>(toAddresses);

        String q='select Id,DeveloperName';
        q+=' from ActionType__mdt';
        q+=' where ToAddress__c in:localToAddresses';
        if (String.isNotBlank(keyPrefix)) q+=' and KeyPrefix__c='+String.escapeSingleQuotes(keyPrefix);
        
        List<ActionType__mdt> actionTypes = Database.query(q);
        
        return actionTypes.isEmpty() ? null : actionTypes[0];
    }

    public static String getPropertyDataType(Schema.DisplayType dt){//1.8+
        if (dt==null) return 'String';
        
        switch on dt {
            when BOOLEAN {
                return 'Boolean';
            } when INTEGER,LONG {
                return 'Integer';
            } when CURRENCY,DOUBLE,PERCENT {
                return 'Decimal';
            } when MULTIPICKLIST {
                return 'Multi Select';
            } when DATE {
                return 'Date';
            } when DATETIME {
                return 'DateTime';
            } when else {
                return 'String';
            }
        }
    }
}