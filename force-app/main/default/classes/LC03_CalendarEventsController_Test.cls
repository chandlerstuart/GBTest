/**
Name:  LC03_CalendarEventsController_Test.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test Class for LC03_CalendarEventsController
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  M.Cebrian  2016-05-03  Initial test class development
**/
@isTest
private class LC03_CalendarEventsController_Test {

/*	@testSetup static void setupTestData() {
    }
	
	@isTest static void validateGetMethods() {
	    
	    Test.startTest();
	        LC03_CalendarEventsController.Filters fi = new LC03_CalendarEventsController.Filters();
	        fi = LC03_CalendarEventsController.getCalendarFilters();
	        system.debug('>>>>> fi '+fi);
	    Test.stopTest();
	    
	     List<String> rtNames = new List<String>();
        rtNames.add(ApplicationConstant.CALENDAR_TYPE_NONE);
        for(RecordType rt : [SELECT Id,Name FROM RecordType WHERE SobjectType = :ApplicationConstant.CALENDAR_CAMPAIGN]){
            rtNames.add(rt.Name);
        }
	    
	    List<String> typeList = new List<String>();
        
        Schema.DescribeFieldResult fieldResult = Campaign.Type.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        typeList.add(ApplicationConstant.CALENDAR_TYPE_NONE);
            
        for( Schema.PicklistEntry f : ple)
        {
            typeList.add(f.getValue());
        }
        List<String> territories = new List<String>();
        Schema.DescribeFieldResult territoryFieldResult = Campaign.Territory__c.getDescribe();
        List<Schema.PicklistEntry> territoryPLE = territoryFieldResult.getPicklistValues();
        territories.add(ApplicationConstant.CALENDAR_TYPE_NONE);
            
        for(Schema.PicklistEntry f : territoryPLE)
        {
            territories.add(f.getValue());
        }
        
        System.assertEquals(rtNames, fi.recordTypes);
        System.assertEquals(typeList, fi.eventTypes);
        System.assertEquals(territories, fi.territories);
	}*/
	
    static final Map<String, RecordType> campaignRecordTypes;
    static{
        campaignRecordTypes = new Map<String, RecordType>();
        for(RecordType recType : [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Campaign']){
            campaignRecordTypes.put(recType.DeveloperName, recType);
        }
    }

    static final Map<Id, RecordType> campaignRecordTypeIdMap;
    static{
        campaignRecordTypeIdMap = new Map<Id, RecordType>([SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Campaign']);
    }

    @testSetup static void setupDate(){
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;    
        
        //Create Marketing  Strategy
        List<MarketingStrategy__c> lMS = AP23_TestDataFactory.createMarketingStrategy(1);
        insert lMS;
        
        //Create campaign
        List<Campaign> lCamp = AP23_TestDataFactory.createCampaign(1, lMS[0].Id);
        for(Campaign campaignRec : lCamp){
            campaignRec.RecordTypeId = campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_CAMPAIGN_EVENT).Id;
            campaignRec.Type = 'Advertisement';
            campaignRec.Territory__c  = 'UK/Ireland';
            campaignRec.StartDate = Date.today();
            campaignRec.EndDate = Date.today().addDays(2);
        }
        insert lCamp;
    }

    static testMethod void testLC03_CalendarEventsController(){
        Campaign campaignRec = [SELECT Type, RecordTypeId, Territory__c FROM Campaign LIMIT 1];
        test.startTest();
        	//LC03_CalendarEventsController cont = new LC03_CalendarEventsController();
        	LC03_CalendarEventsController.Filters calendarFilter = LC03_CalendarEventsController.getCalendarFilters();
        	String calendarEventString = LC03_CalendarEventsController.getCalEvents('', campaignRec.Type, campaignRecordTypeIdMap.get(campaignRec.RecordTypeId).Name, campaignRec.Territory__c);

            Set<String> recordTypeNames = new Set<String>();
            for(RecordType rec : campaignRecordTypes.values()){
                recordTypeNames.add(rec.Name);
            }
            recordTypeNames.add(ApplicationConstant.CALENDAR_TYPE_NONE);

            for(String recTypeName : (List<String>)calendarFilter.recordTypes){
                System.assert(recordTypeNames.contains(recTypeName));
            }
            System.assertEquals(true , !String.isEmpty(calendarEventString));

        test.stopTest();    
    }
}