/**
Name:  AP37_SalesAgentAttributesHandler_Test.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test class for all trigger operations related to the Sales Agent Attributes custom object.
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Nicole DG     2016-04-23  Initial development.
2.0  C. Gaylan     2016-05-17  Improve coverage.
**/
@isTest(seeAllData=false)
public class AP37_SalesAgentAttributesHandler_Test {
    private static testMethod void testNewSalesAgentAttribute(){
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;  
        
        final string SalesAgentProfile = 'Golfbreaks Sales User';
        final string salesManagerProfile = 'Golfbreaks Sales Manager';
        Integer count = [SELECT COUNT() FROM User WHERE (Profile.Name =: SalesAgentProfile OR Profile.Name =:salesManagerProfile) AND IsActive = true];
        List<User> usrId = new List<User>();
        if(count > 0){
             usrId = [SELECT Id FROM User WHERE (Profile.Name =: SalesAgentProfile OR Profile.Name =:salesManagerProfile) AND IsActive = true LIMIT 1];
        }

        List<Sales_Agent_Attributes__c> saaList = new List<Sales_Agent_Attributes__c>();
        for(integer i=0; i<usrId.size(); i++){
            Sales_Agent_Attributes__c saa = new Sales_Agent_Attributes__c(Sales_Rep__c = usrId[i].Id, Team__c = ApplicationConstant.UK_AND_IRELAND_9_TEAM,  Product_Knowledge__c=ApplicationConstant.COUNTRY_ENGLAND_WALES);
            saaList.add(saa);
        }
        Map<Id, Sales_Agent_Attributes__c> newMap = new Map<Id, Sales_Agent_Attributes__c>([SELECT Id FROM Sales_Agent_Attributes__c]);
        
        test.startTest();
        AP37_SalesAgentAttributesHandler x = new AP37_SalesAgentAttributesHandler();
        insert saaList;
        x.onAfterInsert(newMap);
        test.stopTest();
        
        delete saaList;
        Integer newCount = [SELECT COUNT() FROM Sales_Agent_Attributes__c WHERE Team__c =: ApplicationConstant.UK_AND_IRELAND_9_TEAM];      
        System.assertEquals(0, newCount);
    }
    private static testMethod void testUpdateSalesAgentAttribute(){
        Sales_Agent_Attributes__c saa = new Sales_Agent_Attributes__c(Sales_Rep__c = UserInfo.getUserId(), Team__c = ApplicationConstant.UK_AND_IRELAND_0_8_TEAM,   Product_Knowledge__c=ApplicationConstant.COUNTRY_ENGLAND_WALES);
        insert saa;
        Map<Id, Sales_Agent_Attributes__c> oldMap = new Map<Id, Sales_Agent_Attributes__c>();
        oldMap.put(saa.Id, saa);
        Map<Id, Sales_Agent_Attributes__c> newMap = new Map<Id, Sales_Agent_Attributes__c>();
        
        test.startTest();
        AP37_SalesAgentAttributesHandler x = new AP37_SalesAgentAttributesHandler();
        saa.Team__c = ApplicationConstant.UK_AND_IRELAND_9_TEAM; 
        update saa;
        newMap.put(saa.Id, saa);
        x.onAfterUpdate(newMap, oldMap);
        test.stopTest();
        
        Integer oldCount = [SELECT COUNT() FROM Sales_Agent_Attributes__c WHERE Team__c=:ApplicationConstant.UK_AND_IRELAND_0_8_TEAM];
        System.assertEquals(0, oldCount);
        
        Integer newCount = [SELECT COUNT() FROM Sales_Agent_Attributes__c WHERE Team__c=:ApplicationConstant.UK_AND_IRELAND_9_TEAM];
        System.assertEquals(1, newCount);
    }
}