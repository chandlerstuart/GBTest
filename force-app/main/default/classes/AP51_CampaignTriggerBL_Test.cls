@isTest
private class AP51_CampaignTriggerBL_Test {
	
    static final Map<String, Id> campaignRecordTypes;
    
    static{
        campaignRecordTypes = new Map<String, Id>();
        for(RecordType recType : [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Campaign']){
            campaignRecordTypes.put(recType.DeveloperName, recType.Id);
        }
    }
    
    @testSetup static void setupData(){
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;    
    
        //Create Marketing  Strategy
        List<MarketingStrategy__c> lMS = AP23_TestDataFactory.createMarketingStrategy(1);
        insert lMS;
        
        //Create child campaign
        List<Campaign> lChildCamp = AP23_TestDataFactory.createCampaign(1, lMS[0].Id);
        for(Campaign campaign : lChildCamp){
            campaign.RecordTypeId = campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_CAMPAIGN_EVENT);
            campaign.Type = 'Email';
            campaign.MarketingStrategy__c = null;
            campaign.Forecasted_Cost__c = 20000;
            campaign.Actual_Cost__c = 10000;
        }
        insert lChildCamp;

        //Create parent campaign
        List<Campaign> lCamp = AP23_TestDataFactory.createCampaign(2, lMS[0].Id);
        for(Campaign campaign : lCamp){
            campaign.Type = 'Social';
            campaign.Forecasted_Cost__c = 0;
            campaign.Actual_Cost__c = 0;
            campaign.RecordTypeId = campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_PROGRAM);
        }
        insert lCamp;
    }

    static testMethod void bulkifytest(){
        Test.startTest();
        delete [SELECT Id FROM Campaign];

        List<Campaign> campaignList = [SELECT Id FROM Campaign];
        System.assertEquals(campaignList.size(), 0);
        //Create Marketing  Strategy
        List<MarketingStrategy__c> lMS = AP23_TestDataFactory.createMarketingStrategy(1);
        insert lMS;
        
        //Create child campaign
        List<Campaign> childCampaignList = AP23_TestDataFactory.createCampaign(100, lMS[0].Id);
        for(Campaign campaign : childCampaignList){
            campaign.RecordTypeId = campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_CAMPAIGN_EVENT);
            campaign.Type = 'Email';
            campaign.MarketingStrategy__c = null;
            campaign.Forecasted_Cost__c = 20000;
            campaign.Actual_Cost__c = 10000;
        }
        campaignList.addAll(childCampaignList);
        //Create parent campaign
        List<Campaign> parentCampaignList = AP23_TestDataFactory.createCampaign(100, lMS[0].Id);
        for(Campaign campaign : parentCampaignList){
            campaign.Type = 'Social';
            campaign.Forecasted_Cost__c = 0;
            campaign.Actual_Cost__c = 0;
            campaign.RecordTypeId = campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_PROGRAM);
        }
        campaignList.addAll(parentCampaignList);
        insert campaignList;

        Integer totalCampaigns = [SELECT Count() FROM Campaign];
        System.assertEquals(totalCampaigns, 200);

        //Create parent campaign
        List<Campaign> lCamp = AP23_TestDataFactory.createCampaign(2, lMS[0].Id);
        for(Campaign campaign : lCamp){
            campaign.Type = 'Social';
            campaign.Forecasted_Cost__c = 0;
            campaign.Actual_Cost__c = 0;
            campaign.RecordTypeId = campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_PROGRAM);
        }
        insert lCamp;

        childCampaignList = AP23_TestDataFactory.createCampaign(200, lMS[0].Id);
        for(Campaign campaign : childCampaignList){
            campaign.RecordTypeId = campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_CAMPAIGN_EVENT);
            campaign.Type = 'Email';
            campaign.MarketingStrategy__c = null;
            campaign.Forecasted_Cost__c = 20000;
            campaign.Actual_Cost__c = 10000;
        }
        insert childCampaignList;

        Set<Id> childCampaignsToUpdateSet = new Set<Id>();
        for(Campaign campaign : childCampaignList){
            childCampaignsToUpdateSet.add(campaign.Id);
        }

        childCampaignList = [SELECT Id, ParentId FROM Campaign WHERE Id IN:childCampaignsToUpdateSet];
        for(Campaign campaign : childCampaignList){
            campaign.ParentId = lCamp[0].Id;
        }
        update childCampaignList;

        Integer childCountOfParentOne = [SELECT COUNT() FROM Campaign WHERE ParentId =:lCamp[0].Id];
        Integer childCountOfParentTwo = [SELECT COUNT() FROM Campaign WHERE ParentId =:lCamp[1].Id];
        System.assertEquals(childCountOfParentOne, 200);
        System.assertEquals(childCountOfParentTwo, 0);

        childCampaignList = [SELECT Id, ParentId FROM Campaign WHERE Id IN:childCampaignsToUpdateSet];
        for(Campaign campaign : childCampaignList){
            campaign.ParentId = lCamp[1].Id;
        }
        update childCampaignList;

        childCountOfParentOne = [SELECT COUNT() FROM Campaign WHERE ParentId =:lCamp[0].Id];
        childCountOfParentTwo = [SELECT COUNT() FROM Campaign WHERE ParentId =:lCamp[1].Id];
        System.assertEquals(childCountOfParentOne, 0);
        System.assertEquals(childCountOfParentTwo, 200);

        Test.stopTest();
    }

    static testMethod void rollUpMarketingProgramForecastedCostAndActualCost(){
        Test.startTest();
        //Query parent records
        List<Campaign> lCamp = [SELECT Id, Actual_Cost__c, Forecasted_Cost__c FROM Campaign WHERE RecordTypeId =:campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_PROGRAM)];
        Campaign camp01 = lCamp[0];
        Campaign camp02 = lCamp[1];

        //Query parent records
        List<Campaign> lChildCamp = [SELECT Id, ParentId,Actual_Cost__c, Forecasted_Cost__c, Type, MarketingStrategy__c FROM Campaign WHERE RecordTypeId =:campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_CAMPAIGN_EVENT)];
        Campaign campChild01 = lChildCamp[0];
        
        System.assertEquals(campChild01.Type, 'Email' );
        System.assertEquals(campChild01.MarketingStrategy__c, null );

        System.assertEquals(camp01.Actual_Cost__c, 0 );
        System.assertEquals(camp02.Forecasted_Cost__c, 0 );

        System.assertEquals(camp02.Actual_Cost__c, 0 );
        System.assertEquals(camp01.Forecasted_Cost__c, 0 );

        campChild01.ParentId = camp01.Id;
        update campChild01;

        camp01 = [SELECT Id, Actual_Cost__c, Forecasted_Cost__c FROM Campaign WHERE Id=:camp01.Id AND RecordTypeId =:campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_PROGRAM)];
        camp02 = [SELECT Id, Actual_Cost__c, Forecasted_Cost__c FROM Campaign WHERE Id=:camp02.Id AND RecordTypeId =:campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_PROGRAM)];
        System.assertEquals(camp01.Actual_Cost__c, campChild01.Actual_Cost__c );
        System.assertEquals(camp01.Forecasted_Cost__c, campChild01.Forecasted_Cost__c);
        System.assertEquals(camp02.Actual_Cost__c, 0 );
        System.assertEquals(camp02.Forecasted_Cost__c, 0 );

        resetHandler();
        campChild01 = [SELECT Id, ParentId,Actual_Cost__c, Forecasted_Cost__c FROM Campaign WHERE Id=:campChild01.Id AND RecordTypeId =:campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_CAMPAIGN_EVENT)];
        campChild01.ParentId = null;
        update campChild01;

        camp01 = [SELECT Id, Actual_Cost__c, Forecasted_Cost__c FROM Campaign WHERE Id=:camp01.Id AND RecordTypeId =:campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_PROGRAM)];
        camp02 = [SELECT Id, Actual_Cost__c, Forecasted_Cost__c FROM Campaign WHERE Id=:camp02.Id AND RecordTypeId =:campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_PROGRAM)];
        System.assertEquals(camp01.Actual_Cost__c, 0);
        System.assertEquals(camp01.Forecasted_Cost__c, 0);
        System.assertEquals(camp02.Actual_Cost__c, 0 );
        System.assertEquals(camp02.Forecasted_Cost__c, 0 );

        resetHandler();
        campChild01 = [SELECT Id, ParentId,Actual_Cost__c, Forecasted_Cost__c FROM Campaign WHERE Id=:campChild01.Id AND RecordTypeId =:campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_CAMPAIGN_EVENT)];
        campChild01.ParentId = camp02.Id;
        update campChild01;
        
        resetHandler();
        camp01 = [SELECT Id, Actual_Cost__c, Forecasted_Cost__c FROM Campaign WHERE Id=:camp01.Id AND RecordTypeId =:campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_PROGRAM)];
        camp02 = [SELECT Id, Actual_Cost__c, Forecasted_Cost__c, Type, MarketingStrategy__c FROM Campaign WHERE Id=:camp02.Id AND RecordTypeId =:campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_PROGRAM)];
        System.assertEquals(camp01.Actual_Cost__c, 0);
        System.assertEquals(camp01.Forecasted_Cost__c, 0);
        System.assertEquals(camp02.Actual_Cost__c, campChild01.Actual_Cost__c );
        System.assertEquals(camp02.Forecasted_Cost__c, campChild01.Forecasted_Cost__c );

        campChild01 = [SELECT Id, ParentId,Actual_Cost__c, Forecasted_Cost__c, Type, MarketingStrategy__c FROM Campaign WHERE Id=:campChild01.Id AND RecordTypeId =:campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_CAMPAIGN_EVENT)];
        System.assertEquals(camp02.Type, campChild01.Type );
        System.assertEquals(camp02.MarketingStrategy__c, campChild01.MarketingStrategy__c);

        delete campChild01;

        camp01 = [SELECT Id, Actual_Cost__c, Forecasted_Cost__c FROM Campaign WHERE Id=:camp01.Id AND RecordTypeId =:campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_PROGRAM)];
        camp02 = [SELECT Id, Actual_Cost__c, Forecasted_Cost__c, Type, MarketingStrategy__c FROM Campaign WHERE Id=:camp02.Id AND RecordTypeId =:campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_PROGRAM)];
        System.assertEquals(camp01.Actual_Cost__c, 0);
        System.assertEquals(camp01.Forecasted_Cost__c, 0);
        System.assertEquals(camp02.Actual_Cost__c, 0 );
        System.assertEquals(camp02.Forecasted_Cost__c, 0 );

        Test.stopTest();
    }

    private static void resetHandler(){
        AP46_CampaignTriggerHandler.isBeforeUpdateTriggerCalled = FALSE;
        AP46_CampaignTriggerHandler.isAfterDeleteTriggerCalled = FALSE;
        AP46_CampaignTriggerHandler.isBeforeInsertTriggerCalled = FALSE;
        AP46_CampaignTriggerHandler.isAfterUpdateTriggerCalled = FALSE;
        AP46_CampaignTriggerHandler.isAfterUpdateTriggerCalled = FALSE;
    }
	
}