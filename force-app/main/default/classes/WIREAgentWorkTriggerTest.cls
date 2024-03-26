/*
Class:  WIREAgentWorkTriggerTest.cls
Copyright © 2018  Golfbreaks
======================================================
======================================================
Purpose:
-------
This class is used solely to pass code coverage for the
Agent Work Trigger. The business logic Unit Tests are 
handled within the package (AgentWorkTriggerHandlerTestSuite)

======================================================
======================================================
Revision History
---------------- 
Ver. Author          Date        Detail
*/
@isTest(SeeAllData=true)
public class WIREAgentWorkTriggerTest {
    
    @isTest private static void agentWorkTest(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
    	
        Lead l = new Lead();
        l.LastName = 'TestLead';
        l.Company = 'TestCompany';
		l.Status = 'New';    
        insert l;
        
        ServiceChannel serviceChannel = [SELECT Id, MasterLabel FROM ServiceChannel WHERE MasterLabel LIKE '%Lead%'];
        
        AgentWork aw = new AgentWork();
        aw.WorkItemId = l.Id;
        aw.ServiceChannelId = serviceChannel.id;
        aw.UserId = [Select Id, user.Name, UserId, ServicePresenceStatus.DeveloperName From UserServicePresence Where IsCurrentState = true and ServicePresenceStatus.DeveloperName = 'Available' Limit 1].UserId;
        insert aw;
        update aw;
    }
}