/*
Class:  WorkItemWIREActionIdentifierTest.cls
Copyright © 2018  Golfbreaks
======================================================
======================================================
Purpose:
-------
Test class for WorkItemWIREActionIdentifier

Code Coverage (85% target):
---------------------------
WorkItemWIREActionIdentifier.cls = 97%

======================================================
======================================================
Revision History
---------------- 
Ver. Author          Date        Detail
1.0  James Radcliffe 2018-10-30  Initial development.
1.1  Mark Cane&      2018-10-31  Minor updates to testRouteWorkItem and routeWorkItemOnInsertSettingTest to prevent routing on test Lead insert.
1.2  James Radcliffe 2018-11-12  New Test Method: testRouteWorkItemWithActiveAssignmentRules.
1.3  Mark Cane&      2024-02-29  New Test Method: testExecuteWIRETriggerActionsFutureMethod.
*/
@isTest
public class WorkItemWIREActionIdentifierTest {
    
    @testSetup static void testSetup(){
        
        //Disable legacy (Accenture) Routing Engine
        Phased_Code_Removal__c pcm = new Phased_Code_Removal__c();
        pcm.Disable_Accenture_Case_Routing__c = true;
        pcm.Disable_Accenture_Lead_Routing__c = true;
        pcm.Disable_Account_NVM_Id_Setting__c = true;
        pcm.Disable_Monthly_Sales_Target_Automation__c = true;
        insert pcm;
        
        //Default GBWire__WorkItemRoutingSettings__c
        GBWire__WorkItemRoutingSettings__c wirs = new GBWire__WorkItemRoutingSettings__c();
        wirs.GBWire__RouteCaseonInsert__c = false;
        wirs.GBWire__RouteLeadonInsert__c = false;
        insert wirs;
        
        //Allow the current running test user to insert Client accounts        
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        
        //Insert a person Account
        insert AP23_TestDataFactory.createPersonAccount(2);
                        
    }
    
    //This method confirms the work item is routed if the work item is inserted and the route work item checkbox is ticked (plus negative assertion)
    @isTest static void testRouteWorkItemOnInsert(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        GBWire.WorkItemTriggerHandler.disableLocalTriggers = true;//<--- 1.1 prevent routing.
        GBWire.WorkItemTriggerHandler.disableWireTriggers = true;
        
        //New Lead Inserted by Sales Agent
        User agent = [Select Id, ProfileId From User Where Profile.Name =:ApplicationConstant.PROFILE_SALES_AGENT and IsActive = true Limit 1][0];
        system.runAs(agent){
            
            //Insert new Lead
            Lead lead1 = new Lead();
            lead1.FirstName = 'Test';
            lead1.LastName = 'Lead1';
            lead1.Company = 'Test';
            lead1.GBWire__RouteWorkItem__c = true;
            insert lead1;
            
            //Insert new Lead
            Lead lead2 = new Lead();
            lead2.FirstName = 'Test';
            lead2.LastName = 'Lead2';
            lead2.Company = 'Test';
            lead2.GBWire__RouteWorkItem__c = false;
            insert lead2;
            
            Id doAssignLeadId = Lead1.Id;
            Id dontAssignLeadId = Lead2.Id;
            
            //Retrieve the lead for passing to the Action Identifier
            Map<Id,Lead> newLeads = new Map<Id,Lead>([Select Id, Account__c, Territory__c, RecordTypeId, IsOpen__c, IsNew__c, IsActive__c, GBWire__RouteWorkItem__c, 
                                                               GBWire__PreferredQueue__c, OwnerId, Golfbreaks_Business_Unit__c, SalesRegion__c, TravelGroupSize__c, IsTest__c From Lead Limit 2]);
            
            //Simulate Insert Trigger Context
            WorkItemWIREActionIdentifier.isTestInsert = true;
            
            //Create Map to store results
            Map<Id,GBWire.WorkItemWithActionsWrapper> recordIdsWithRequiredActions = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            
            System.debug(LoggingLevel.ERROR, 'newLeads='+newLeads);
            
            //Run method
            test.startTest();
                String workItemType = 'Lead';
                recordIdsWithRequiredActions = WorkItemWIREActionIdentifier.processWorkItems(null,newLeads,workItemType);
            test.stopTest();
            
            //Confirm the map is not null
            system.assertNotEquals(null, recordIdsWithRequiredActions);
            
            System.debug(LoggingLevel.ERROR, 'doAssignLeadId='+doAssignLeadId);
            System.debug(LoggingLevel.ERROR, 'dontAssignLeadId='+dontAssignLeadId);
            System.debug(LoggingLevel.ERROR, 'recordIdsWithRequiredActions='+recordIdsWithRequiredActions);
            
            //Confirm the doAssign Lead would be routed (as the 'Route Work Item' was ticked)
            system.assertEquals(true, recordIdsWithRequiredActions.get(doAssignLeadId).doAssign);
            //Confirm the dontAssign Lead wouldn't be routed (as the default is to remain with the owner and the 'Route Work Item' was not selected)
            system.assertEquals(false, recordIdsWithRequiredActions.get(dontAssignLeadId).doAssign);           
            
        }   
        
    }
    
    //This method confirms the work item is routed if the work item is updated and the Route Work Item checkbox has been newly selected 
    @isTest static void testRouteWorkItemOnUpdate(){    

        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        GBWire.WorkItemTriggerHandler.disableLocalTriggers = true;//<--- 1.1 prevent routing.
        GBWire.WorkItemTriggerHandler.disableWireTriggers = true;
        
        //New Lead Inserted by Sales Agent
        User agent = [Select Id, ProfileId From User Where Profile.Name =:ApplicationConstant.PROFILE_SALES_AGENT and IsActive = true Limit 1][0];
        system.runAs(agent){
            
            //Insert new Lead
            Lead lead1 = new Lead();
            lead1.FirstName = 'Test';
            lead1.LastName = 'Lead1';
            lead1.Company = 'Test';
            lead1.GBWire__RouteWorkItem__c = false;
            insert lead1;                       
            
            //Retrieve the lead for passing to the Action Identifier
            Map<Id,Lead> leadWithRouteWorkItemUnchecked = new Map<Id,Lead>([Select Id, Territory__c, Account__c, RecordTypeId, IsOpen__c, IsNew__c, IsActive__c, GBWire__RouteWorkItem__c, 
                                                               GBWire__PreferredQueue__c, OwnerId, Golfbreaks_Business_Unit__c, SalesRegion__c, TravelGroupSize__c, IsTest__c From Lead Limit 1]);
            
            //Simulate Update Trigger Context
            WorkItemWIREActionIdentifier.isTestUpdate = true;
            WorkItemWIREActionIdentifier.isTestInsert = false;
                        
            //Assign workItemType
            String workItemType = 'Lead';
                             
            //Lead with Route Work Item selected
            Map<Id,Lead> leadWithRouteWorkItemSelected = leadWithRouteWorkItemUnchecked.deepClone();
            leadWithRouteWorkItemSelected.values()[0].GBWire__RouteWorkItem__c = true;

            test.startTest();            
            
            //New Maps to store results
            Map<Id,GBWire.WorkItemWithActionsWrapper> noChange = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            Map<Id,GBWire.WorkItemWithActionsWrapper> routeWorkItemSelected = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            Map<Id,GBWire.WorkItemWithActionsWrapper> routeWorkItemDeselected = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            
            noChange = WorkItemWIREActionIdentifier.processWorkItems(leadWithRouteWorkItemUnchecked,leadWithRouteWorkItemUnchecked,workItemType);   
            routeWorkItemSelected = WorkItemWIREActionIdentifier.processWorkItems(leadWithRouteWorkItemUnchecked,leadWithRouteWorkItemSelected,workItemType);  
            routeWorkItemDeselected = WorkItemWIREActionIdentifier.processWorkItems(leadWithRouteWorkItemSelected,leadWithRouteWorkItemUnchecked,workItemType);  
            system.assertNotEquals(null, noChange);
            system.assertNotEquals(null, routeWorkItemSelected); 
            system.assertNotEquals(null, routeWorkItemDeselected);
            //Confirm nothing is returned for the noChange Lead
            system.assertEquals(false, noChange.values().size()>0);
            //Confirm the RWI Selected lead is returned (as an action is required)
            system.assertEquals(true, routeWorkItemSelected.values().size()>0);
            //Confirm RWI Selected lead wrapper indicates it requires routing
            system.assertEquals(true,routeWorkItemSelected.values()[0].doAssign); 
            //Confirm the Deselected lead is NOT returned
            system.assertEquals(false, routeWorkItemDeselected.values().size()>0);                             
                
            test.stopTest();       
        }           
        
    }
    
    //This method confirms the work item is routed if the 'Default work item routing setting' (GBWire__WorkItemRoutingSettings__c) is true for the running user
    @isTest static void testRouteDefaultSettingOnInsert(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        GBWire.WorkItemTriggerHandler.disableLocalTriggers = true;//<--- 1.1 prevent routing.
        GBWire.WorkItemTriggerHandler.disableWireTriggers = true;
        
        
        //Query Sales Agent
        User agent = [Select Id, ProfileId From User Where Profile.Name =:ApplicationConstant.PROFILE_SALES_AGENT and IsActive = true Limit 1][0];
        
        //Insert a new GBWire__WorkItemRoutingSettings__c setting for the sales agent profile
        GBWire__WorkItemRoutingSettings__c wirs = new GBWire__WorkItemRoutingSettings__c();
        wirs.GBWire__RouteLeadonInsert__c = true;
        wirs.SetupOwnerId = agent.ProfileId;
        insert wirs;
        
        system.runAs(agent){
            
            //Insert new Lead
            Lead lead1 = new Lead();
            lead1.FirstName = 'Test';
            lead1.LastName = 'Lead1';
            lead1.Company = 'Test';
            lead1.GBWire__RouteWorkItem__c = false;//<---- 1.1 both leads should be false - the routing behaviour is set from the CMT.
            insert lead1;
            
            //Insert new Lead
            Lead lead2 = new Lead();
            lead2.FirstName = 'Test';
            lead2.LastName = 'Lead2';
            lead2.Company = 'Test';
            lead2.GBWire__RouteWorkItem__c = false;
            insert lead2;
            
            Id doAssignLeadId = Lead1.Id;
            Id dontAssignLeadId = Lead2.Id;
            
            //Retrieve the lead for passing to the Action Identifier
            Map<Id,Lead> newLeads = new Map<Id,Lead>([Select Id, Account__c, Territory__c, RecordTypeId, IsOpen__c, IsNew__c, IsActive__c, GBWire__RouteWorkItem__c, 
                                                               GBWire__PreferredQueue__c, OwnerId, Golfbreaks_Business_Unit__c, SalesRegion__c, TravelGroupSize__c, IsTest__c From Lead Limit 2]);
            
            //Simulate Insert Trigger Context
            WorkItemWIREActionIdentifier.isTestInsert = true;
            
            //Create Map to store results
            Map<Id,GBWire.WorkItemWithActionsWrapper> recordIdsWithRequiredActions = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            
            //Run method
            test.startTest();
                String workItemType = 'Lead';
                recordIdsWithRequiredActions = WorkItemWIREActionIdentifier.processWorkItems(null,newLeads,workItemType);
            test.stopTest();
            
            //Confirm the map is not null
            system.assertNotEquals(null, recordIdsWithRequiredActions);
            //Confirm the doAssign Lead would be routed (as the 'Route Work Item' was ticked)
            system.assertEquals(true, recordIdsWithRequiredActions.get(doAssignLeadId).doAssign);
            //Confirm the dontAssign Lead is still routed, despite the 'Route Work Item' is unticked, thereby respecting the default setting (GBWire__WorkItemRoutingSettings__c)
            system.assertEquals(true, recordIdsWithRequiredActions.get(dontAssignLeadId).doAssign);     
        }            
        
    }
    
    //This method confirms the Preferred Agent will be created for new work items if the resulting owner is a User (and not if the owner is a queue)
    @isTest static void testPreferredAgentOnInsert(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        GBWire.WorkItemTriggerHandler.disableLocalTriggers = true;//<--- 1.1 prevent routing.
        GBWire.WorkItemTriggerHandler.disableWireTriggers = true;
        
        //Query person Account
        Id accId = [Select Id, RecordType.Name, isPersonAccount, Name from Account Limit 1].Id;
        
        Id runningUserId = UserInfo.getUserId();
            
            //Insert new Lead
            Lead lead1 = new Lead();
            lead1.FirstName = 'Test';
            lead1.LastName = 'Lead1';
            lead1.Company = 'Test';
            lead1.Account__c = accId;
            lead1.GBWire__RouteWorkItem__c = false;
            insert lead1;   
            
            //Retrieve the lead for passing to the Action Identifier
            Map<Id,Lead> leadWithUserOwner = new Map<Id,Lead>([Select Id, Account__c, Territory__c, RecordTypeId, IsOpen__c, IsNew__c, IsActive__c, GBWire__RouteWorkItem__c, 
                                                               GBWire__PreferredQueue__c, OwnerId, Golfbreaks_Business_Unit__c, SalesRegion__c, TravelGroupSize__c, IsTest__c From Lead Limit 1]);
            system.assertEquals(1,leadWithUserOwner.values().size());
            //Confirm the lead is owned by running user
            leadWithUserOwner.values()[0].ownerId = runningUserId;
                        
            //Assign workItemType
            String workItemType = 'Lead';
                             
            //Clone original lead
            Map<Id,Lead> leadWithQueueOwner = leadWithUserOwner.deepClone();    
            
            //Assign lead to Queue
            leadWithQueueOwner.values()[0].ownerId = [SELECT QueueId, Id, SobjectType FROM QueueSobject Where sObjectType = 'Lead' LIMIT 1].QueueId;

            test.startTest();            
            
            //New Maps to store results
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadInsertedUserOwner = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadInsertedQueueOwner = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
              
            //Simulate Insert Trigger Context
            WorkItemWIREActionIdentifier.isTestUpdate = false;
            WorkItemWIREActionIdentifier.isTestInsert = true;
        
            leadInsertedUserOwner = WorkItemWIREActionIdentifier.processWorkItems(null,leadWithUserOwner,workItemType);  
            leadInsertedQueueOwner = WorkItemWIREActionIdentifier.processWorkItems(null,leadWithQueueOwner,workItemType);  
                
            system.assertNotEquals(null, leadInsertedUserOwner);
            system.assertNotEquals(null, leadInsertedQueueOwner); 

        
            //Confirm the PA action is required when record is inserted with user owner
            system.assertEquals(true, leadInsertedUserOwner.values().size()>0);
            system.assertEquals(true, leadInsertedUserOwner.values()[0].doPreferredAgentCalc);
            //Confirm the PA action is NOT required when record is inserted with queue owner
            system.assertEquals(true, leadInsertedQueueOwner.values().size()==0||(leadInsertedQueueOwner.values().size()>0 && leadInsertedQueueOwner.values()[0].doPreferredAgentCalc == false));         
        
            test.stopTest();              
        
    }
    
    //This method confirms the related Preferred Agent will be re-evaluated if the work item is transferred from user to queue, queue to user or user to user (not necessary for queue to queue)
    @isTest static void testPreferredAgentOnRecordTransferUpdate(){
           
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        GBWire.WorkItemTriggerHandler.disableLocalTriggers = true;//<--- 1.1 prevent routing.
        GBWire.WorkItemTriggerHandler.disableWireTriggers = true;
        
        //Query person Account
        Id accId = [Select Id, RecordType.Name, isPersonAccount, Name from Account Limit 1].Id;
        
        Id runningUserId = UserInfo.getUserId();
            
            //Insert new Lead
            Lead lead1 = new Lead();
            lead1.FirstName = 'Test';
            lead1.LastName = 'Lead1';
            lead1.Company = 'Test';
            lead1.Account__c = accId;
            lead1.GBWire__RouteWorkItem__c = false;
            insert lead1;   
            
            //Retrieve the lead for passing to the Action Identifier
            Map<Id,Lead> leadWithUserOwner = new Map<Id,Lead>([Select Id, Account__c, Territory__c, RecordTypeId, IsOpen__c, IsNew__c, IsActive__c, GBWire__RouteWorkItem__c, 
                                                               GBWire__PreferredQueue__c, OwnerId, Golfbreaks_Business_Unit__c, SalesRegion__c, TravelGroupSize__c, IsTest__c From Lead Limit 1]);
            system.assertEquals(1,leadWithUserOwner.values().size());
            //Confirm the lead is owned by running user
            leadWithUserOwner.values()[0].ownerId = runningUserId;
            
            //Simulate Update Trigger Context
            WorkItemWIREActionIdentifier.isTestUpdate = true;
            WorkItemWIREActionIdentifier.isTestInsert = false;
                        
            //Assign workItemType
            String workItemType = 'Lead';
                             
            //Clone original lead
            Map<Id,Lead> leadWithQueueAOwner = leadWithUserOwner.deepClone();
            Map<Id,Lead> leadWithQueueBOwner = leadWithUserOwner.deepClone();
            Map<Id,Lead> leadWithNewOwner = leadWithUserOwner.deepClone();  
            
            //Assign new owners for cloned leads
            QueueSobject[] qsos = [SELECT QueueId, Id, SobjectType FROM QueueSobject Where sObjectType = 'Lead' LIMIT 2];
            system.assertEquals(2,qsos.size());
            leadWithQueueAOwner.values()[0].ownerId = qsos[0].QueueId;
            leadWithQueueBOwner.values()[0].ownerId = qsos[1].QueueId;
            leadWithNewOwner.values()[0].ownerId = [Select Id From User Where Profile.Name =:ApplicationConstant.PROFILE_SALES_AGENT and IsActive = true and (Not Id =:runningUserId) Limit 1].Id;

            test.startTest();            
            
            //New Maps to store results
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadTransferUserToUser = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadTransferUserToQueue = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadTransferQueueToQueue = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadTransferQueueToUser = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
              
            leadTransferUserToUser = WorkItemWIREActionIdentifier.processWorkItems(leadWithUserOwner,leadWithNewOwner,workItemType);  
            leadTransferUserToQueue = WorkItemWIREActionIdentifier.processWorkItems(leadWithUserOwner,leadWithQueueAOwner,workItemType);  
            leadTransferQueueToQueue = WorkItemWIREActionIdentifier.processWorkItems(leadWithQueueAOwner,leadWithQueueBOwner,workItemType);  
            leadTransferQueueToUser = WorkItemWIREActionIdentifier.processWorkItems(leadWithQueueAOwner,leadWithUserOwner,workItemType); 
            system.assertNotEquals(null, leadTransferUserToUser);
            system.assertNotEquals(null, leadTransferUserToQueue); 
            system.assertNotEquals(null, leadTransferQueueToQueue);
            //Confirm the PA action is required when record transfers from user to user
            system.assertEquals(true, leadTransferUserToUser.values().size()>0);
            system.assertEquals(true, leadTransferUserToUser.values()[0].doPreferredAgentCalc);
            //Confirm the PA action is required when record transfers from user to queue
            system.assertEquals(true, leadTransferUserToQueue.values().size()>0);
            system.assertEquals(true, leadTransferUserToQueue.values()[0].doPreferredAgentCalc);
            //Confirm no action is required when lead transfers from queue to queue
            system.assertEquals(true,(leadTransferQueueToQueue.values().size()==0||(leadTransferQueueToQueue.values().size()>0 && leadTransferQueueToQueue.values()[0].doPreferredAgentCalc == false)));                      
            //Confirm the PA action is required when a record transfers from a queue to a user
            system.assertEquals(true, leadTransferQueueToUser.values().size()>0);
            system.assertEquals(true, leadTransferQueueToUser.values()[0].doPreferredAgentCalc);        
        
            test.stopTest();       
    }
    
    //This method confirms the related Preferred Agent will be re-evaluated if the work item is closed or re-opened
    @isTest static void testPreferredAgentRecordCloseAndReOpen(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        GBWire.WorkItemTriggerHandler.disableLocalTriggers = true;//<--- 1.1 prevent routing.
        GBWire.WorkItemTriggerHandler.disableWireTriggers = true;
        
        //Query person Account
        Id accId = [Select Id, RecordType.Name, isPersonAccount, Name from Account Limit 1].Id;
        
        Id runningUserId = UserInfo.getUserId();
            
            //Insert new Lead
            Lead lead1 = new Lead();
            lead1.FirstName = 'Test';
            lead1.LastName = 'Lead1';
            lead1.Company = 'Test';
            lead1.Account__c = accId;
            lead1.GBWire__RouteWorkItem__c = false;
            insert lead1;   
            
            //Retrieve the lead for passing to the Action Identifier
            Map<Id,Lead> openLead = new Map<Id,Lead>([Select Id, DuplicateNotaLeadReason__c, Territory__c, Account__c, RecordTypeId, IsOpen__c, IsNew__c, IsActive__c, GBWire__RouteWorkItem__c, 
                                                               GBWire__PreferredQueue__c, OwnerId, Golfbreaks_Business_Unit__c, SalesRegion__c, TravelGroupSize__c, IsTest__c From Lead Limit 1]);
            system.assertEquals(1,openLead.values().size());
            system.assertEquals(true,openLead.values()[0].IsOpen__c);
            //Confirm the lead is owned by running user
            openLead.values()[0].ownerId = runningUserId;
                        
            //Assign workItemType
            String workItemType = 'Lead';
                                         
            //Close the lead
            openLead.values()[0].Status = ApplicationConstant.LEAD_STATUS_DUPLICATE;
            openLead.values()[0].DuplicateNotaLeadReason__c = ApplicationConstant.LEAD_DUPLICATE_REASON;
            update openLead.values();

            Map<Id,Lead> closedLead = new Map<Id,Lead>([Select Id, DuplicateNotaLeadReason__c, Territory__c, Account__c, RecordTypeId, IsOpen__c, IsNew__c, IsActive__c, GBWire__RouteWorkItem__c, 
                                                               GBWire__PreferredQueue__c, OwnerId, Golfbreaks_Business_Unit__c, SalesRegion__c, TravelGroupSize__c, IsTest__c From Lead Where Id = :lead1.Id Limit 1]);
        
            test.startTest();            
            
            //New Maps to store results
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadUpdateClosed = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadUpdateReopened = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
              
            //Simulate Update Trigger Context
            WorkItemWIREActionIdentifier.isTestUpdate = true;
            WorkItemWIREActionIdentifier.isTestInsert = false;
        
            leadUpdateClosed = WorkItemWIREActionIdentifier.processWorkItems(openLead,closedLead,workItemType);  
            leadUpdateReopened = WorkItemWIREActionIdentifier.processWorkItems(closedLead,openLead,workItemType);  
        
            system.assertNotEquals(null, leadUpdateClosed);
            system.assertNotEquals(null, leadUpdateReopened); 

            //Confirm the PA action is required when a record is closed and reopened
            system.assertEquals(true, leadUpdateClosed.values().size()>0);
            system.assertEquals(true, leadUpdateClosed.values()[0].doPreferredAgentCalc);
            system.assertEquals(true, leadUpdateReopened.values().size()>0);
            system.assertEquals(true, leadUpdateReopened.values()[0].doPreferredAgentCalc);          
        
            test.stopTest();      
                
    }
        
    //This method confirms the Preferred Agent and CRP actions are ommitted if the client is not specified on insert and invoked when the Client is modified on the work item
    @isTest static void testClientSetClearedOrTransferred(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        GBWire.WorkItemTriggerHandler.disableLocalTriggers = true;//<--- 1.1 prevent routing.
        GBWire.WorkItemTriggerHandler.disableWireTriggers = true;
        
        //Query person Accounts
        Account[] accs = [Select Id, RecordType.Name, isPersonAccount, Name from Account Limit 2];
        system.assertEquals(2,accs.size());
        Id acc1Id = accs[0].Id;
        Id acc2Id = accs[1].Id;
        
        Id runningUserId = UserInfo.getUserId();
            
            //Insert new Lead
            Lead lead1 = new Lead();
            lead1.FirstName = 'Test';
            lead1.LastName = 'Lead1';
            lead1.Company = 'Test';
            lead1.Account__c = acc1Id;
            lead1.GBWire__RouteWorkItem__c = false;
            insert lead1;   
            
            //Retrieve the lead for passing to the Action Identifier
            Map<Id,Lead> leadWithClient = new Map<Id,Lead>([Select Id, Account__c, Territory__c, RecordTypeId, IsOpen__c, IsNew__c, IsActive__c, GBWire__RouteWorkItem__c, 
                                                               GBWire__PreferredQueue__c, OwnerId, Golfbreaks_Business_Unit__c, SalesRegion__c, TravelGroupSize__c, IsTest__c From Lead Limit 1]);
            system.assertEquals(1,leadWithClient.values().size());
            //Confirm the lead is owned by running user
            leadWithClient.values()[0].ownerId = runningUserId;
                        
            //Assign workItemType
            String workItemType = 'Lead';
                             
            //Clone original lead
            Map<Id,Lead> leadWithoutClient = leadWithClient.deepClone();
            Map<Id,Lead> leadWithNewClient = leadWithClient.deepClone();
            
            //Update cloned leads
            leadWithoutClient.values()[0].Account__c = null;
            leadWithNewClient.values()[0].Account__c = acc2Id;
        
            test.startTest();            
            
            //New Maps to store results
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadInsertWithClient = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadInsertWithoutClient = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadUpdatedClientSet = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadUpdatedClientCleared = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadUpdatedClientTransferred = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
              
            //Simulate Insert Trigger Context
            WorkItemWIREActionIdentifier.isTestUpdate = false;
            WorkItemWIREActionIdentifier.isTestInsert = true;
        
            leadInsertWithClient = WorkItemWIREActionIdentifier.processWorkItems(null,leadWithClient,workItemType);  
            leadInsertWithoutClient = WorkItemWIREActionIdentifier.processWorkItems(null,leadWithoutClient,workItemType);  
        
            //Simulate Update Trigger Context
            WorkItemWIREActionIdentifier.isTestUpdate = true;
            WorkItemWIREActionIdentifier.isTestInsert = false;
        
            leadUpdatedClientSet = WorkItemWIREActionIdentifier.processWorkItems(leadWithoutClient,leadWithClient,workItemType);  
            leadUpdatedClientCleared = WorkItemWIREActionIdentifier.processWorkItems(leadWithClient,leadWithoutClient,workItemType);
            leadUpdatedClientTransferred = WorkItemWIREActionIdentifier.processWorkItems(leadWithClient,leadWithNewClient,workItemType);
            system.assertNotEquals(null, leadInsertWithClient);
            system.assertNotEquals(null, leadInsertWithoutClient); 
            system.assertNotEquals(null, leadUpdatedClientSet);
            system.assertNotEquals(null, leadUpdatedClientCleared);  
            system.assertNotEquals(null, leadUpdatedClientTransferred);  
        
            //Confirm the PA & CRP actions are required when record is inserted with Client
            system.assertEquals(true, leadInsertWithClient.values().size()>0);
            system.assertEquals(true, leadInsertWithClient.values()[0].doPreferredAgentCalc);
            system.assertEquals(true, leadInsertWithClient.values()[0].doCRPCalc);
            //Confirm the PA & CRP actions are NOT required when record is inserted without Client
            system.assertEquals(true, leadInsertWithoutClient.values().size()==0||(leadInsertWithoutClient.values().size()>0 && leadInsertWithoutClient.values()[0].doPreferredAgentCalc == false && leadInsertWithoutClient.values()[0].doCRPCalc == false));
            //Confirm the PA & CRP actions are required when record is updated with Client
            system.assertEquals(true, leadUpdatedClientSet.values().size()>0);
            system.assertEquals(true, leadUpdatedClientSet.values()[0].doPreferredAgentCalc);
            system.assertEquals(true, leadUpdatedClientSet.values()[0].doCRPCalc);
            //Confirm the PA & CRP actions are required when records Client is cleared
            system.assertEquals(true, leadUpdatedClientCleared.values().size()>0);
            system.assertEquals(true, leadUpdatedClientCleared.values()[0].doPreferredAgentCalc);     
            system.assertEquals(true, leadUpdatedClientCleared.values()[0].doCRPCalc);
            system.assertNotEquals(null,leadUpdatedClientCleared.values()[0].previousClientId);
            //Confirm the PA & CRP actions are required when records Client is changed
            system.assertEquals(true, leadUpdatedClientTransferred.values().size()>0);
            system.assertEquals(true, leadUpdatedClientTransferred.values()[0].doPreferredAgentCalc);     
            system.assertEquals(true, leadUpdatedClientTransferred.values()[0].doCRPCalc);
            system.assertNotEquals(null,leadUpdatedClientTransferred.values()[0].previousClientId);         
        
            test.stopTest();      
                
    }
    
    //This method confirms the new work item owner's capacity is recalcuted when the record is insert if the resulting owner is a User (and not if the owner is a queue)
    @isTest static void testAgentCapacityOnInsert(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        GBWire.WorkItemTriggerHandler.disableLocalTriggers = true;//<--- 1.1 prevent routing.
        GBWire.WorkItemTriggerHandler.disableWireTriggers = true;
        
        //Query person Account
        //Id accId = [Select Id, RecordType.Name, isPersonAccount, Name from Account Limit 1].Id;
        
        Id runningUserId = UserInfo.getUserId();
            
            //Insert new Lead
            Lead lead1 = new Lead();
            lead1.FirstName = 'Test';
            lead1.LastName = 'Lead1';
            lead1.Company = 'Test';
            //lead1.Account__c = accId;
            lead1.GBWire__RouteWorkItem__c = false;
            insert lead1;   
            
            //Retrieve the lead for passing to the Action Identifier
            Map<Id,Lead> leadWithUserOwner = new Map<Id,Lead>([Select Id, Account__c, Territory__c, RecordTypeId, IsOpen__c, IsNew__c, IsActive__c, GBWire__RouteWorkItem__c, 
                                                               GBWire__PreferredQueue__c, OwnerId, Golfbreaks_Business_Unit__c, SalesRegion__c, TravelGroupSize__c, IsTest__c From Lead Limit 1]);
            system.assertEquals(1,leadWithUserOwner.values().size());
            //Confirm the lead is owned by running user
            leadWithUserOwner.values()[0].ownerId = runningUserId;
                        
            //Assign workItemType
            String workItemType = 'Lead';
                             
            //Clone original lead
            Map<Id,Lead> leadWithQueueOwner = leadWithUserOwner.deepClone();    
            
            //Assign lead to Queue
            leadWithQueueOwner.values()[0].ownerId = [SELECT QueueId, Id, SobjectType FROM QueueSobject Where sObjectType = 'Lead' LIMIT 1].QueueId;

            test.startTest();            
            
            //New Maps to store results
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadInsertedUserOwner = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadInsertedQueueOwner = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
              
            //Simulate Insert Trigger Context
            WorkItemWIREActionIdentifier.isTestUpdate = false;
            WorkItemWIREActionIdentifier.isTestInsert = true;
        
            leadInsertedUserOwner = WorkItemWIREActionIdentifier.processWorkItems(null,leadWithUserOwner,workItemType);  
            leadInsertedQueueOwner = WorkItemWIREActionIdentifier.processWorkItems(null,leadWithQueueOwner,workItemType);  
                
            system.assertNotEquals(null, leadInsertedUserOwner);
            system.assertNotEquals(null, leadInsertedQueueOwner); 

        
            //Confirm the Capacity Calc action is required when record is inserted with user owner
            system.assertEquals(true, leadInsertedUserOwner.values().size()>0);
            system.assertEquals(true, leadInsertedUserOwner.values()[0].doAgentCapacityCalc);
            //Confirm the Capacity Calc action is NOT required when record is inserted with queue owner
            system.assertEquals(true, leadInsertedQueueOwner.values().size()==0||(leadInsertedQueueOwner.values().size()>0 && leadInsertedQueueOwner.values()[0].doAgentCapacityCalc == false));         
        
            test.stopTest();              
        
    }
    
    //This method confirms the related owner's capacity (and in certain cases, previous owners capacity) will be re-evaluated if the work item is transferred from user to queue, queue to user or user to user (not necessary for queue to queue)
    @isTest static void testAgentCapacityOnRecordTransferUpdate(){
           
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        GBWire.WorkItemTriggerHandler.disableLocalTriggers = true;//<--- 1.1 prevent routing.
        GBWire.WorkItemTriggerHandler.disableWireTriggers = true;
        
        //Query person Account
        Id accId = [Select Id, RecordType.Name, isPersonAccount, Name from Account Limit 1].Id;
        
        Id runningUserId = UserInfo.getUserId();
            
            //Insert new Lead
            Lead lead1 = new Lead();
            lead1.FirstName = 'Test';
            lead1.LastName = 'Lead1';
            lead1.Company = 'Test';
            lead1.Account__c = accId;
            lead1.GBWire__RouteWorkItem__c = false;
            insert lead1;   
            
            //Retrieve the lead for passing to the Action Identifier
            Map<Id,Lead> leadWithUserOwner = new Map<Id,Lead>([Select Id, Account__c, Territory__c, RecordTypeId, IsOpen__c, IsNew__c, IsActive__c, GBWire__RouteWorkItem__c, 
                                                               GBWire__PreferredQueue__c, OwnerId, Golfbreaks_Business_Unit__c, SalesRegion__c, TravelGroupSize__c, IsTest__c From Lead Limit 1]);
            system.assertEquals(1,leadWithUserOwner.values().size());
            //Confirm the lead is owned by running user
            leadWithUserOwner.values()[0].ownerId = runningUserId;
            
            //Simulate Update Trigger Context
            WorkItemWIREActionIdentifier.isTestUpdate = true;
            WorkItemWIREActionIdentifier.isTestInsert = false;
                        
            //Assign workItemType
            String workItemType = 'Lead';
                             
            //Clone original lead
            Map<Id,Lead> leadWithQueueAOwner = leadWithUserOwner.deepClone();
            Map<Id,Lead> leadWithQueueBOwner = leadWithUserOwner.deepClone();
            Map<Id,Lead> leadWithNewOwner = leadWithUserOwner.deepClone();  
            
            //Assign new owners for cloned leads
            QueueSobject[] qsos = [SELECT QueueId, Id, SobjectType FROM QueueSobject Where sObjectType = 'Lead' LIMIT 2];
            system.assertEquals(2,qsos.size());
            leadWithQueueAOwner.values()[0].ownerId = qsos[0].QueueId;
            leadWithQueueBOwner.values()[0].ownerId = qsos[1].QueueId;
            leadWithNewOwner.values()[0].ownerId = [Select Id From User Where Profile.Name =:ApplicationConstant.PROFILE_SALES_AGENT and IsActive = true and (Not Id =:runningUserId) Limit 1].Id;

            test.startTest();            
            
            //New Maps to store results
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadTransferUserToUser = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadTransferUserToQueue = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadTransferQueueToQueue = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadTransferQueueToUser = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
              
            leadTransferUserToUser = WorkItemWIREActionIdentifier.processWorkItems(leadWithUserOwner,leadWithNewOwner,workItemType);  
            leadTransferUserToQueue = WorkItemWIREActionIdentifier.processWorkItems(leadWithUserOwner,leadWithQueueAOwner,workItemType);  
            leadTransferQueueToQueue = WorkItemWIREActionIdentifier.processWorkItems(leadWithQueueAOwner,leadWithQueueBOwner,workItemType);  
            leadTransferQueueToUser = WorkItemWIREActionIdentifier.processWorkItems(leadWithQueueAOwner,leadWithUserOwner,workItemType); 
            system.assertNotEquals(null, leadTransferUserToUser);
            system.assertNotEquals(null, leadTransferUserToQueue); 
            system.assertNotEquals(null, leadTransferQueueToQueue);
            //Confirm the Capacity action is required when record transfers from user to user and that the previous owner id is specified
            system.assertEquals(true, leadTransferUserToUser.values().size()>0);
            system.assertEquals(true, leadTransferUserToUser.values()[0].doAgentCapacityCalc);
            system.assertNotEquals(null, leadTransferUserToUser.values()[0].previousOwnerId);
            //Confirm the Capacity action is required when record transfers from user to queue and the previous owner id is specified
            system.assertEquals(true, leadTransferUserToQueue.values().size()>0);
            system.assertEquals(true, leadTransferUserToQueue.values()[0].doAgentCapacityCalc);
            system.assertNotEquals(null,leadTransferUserToQueue.values()[0].previousOwnerId);
            //Confirm no Capacity action is required when lead transfers from queue to queue
            system.assertEquals(true,(leadTransferQueueToQueue.values().size()==0||(leadTransferQueueToQueue.values().size()>0 && leadTransferQueueToQueue.values()[0].doAgentCapacityCalc == false)));                      
            //Confirm the Capacity action is required when a record transfers from a queue to a user
            system.assertEquals(true, leadTransferQueueToUser.values().size()>0);
            system.assertEquals(true, leadTransferQueueToUser.values()[0].doAgentCapacityCalc);         
        
            test.stopTest();       
    }
    
    //This method confirms the agent capacity will be re-evaluated for the owner if the work item is closed or re-opened
    @isTest static void testAgentCapacityRecordCloseAndReOpen(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        GBWire.WorkItemTriggerHandler.disableLocalTriggers = true;//<--- 1.1 prevent routing.
        GBWire.WorkItemTriggerHandler.disableWireTriggers = true;
        
        //Query person Account
        Id accId = [Select Id, RecordType.Name, isPersonAccount, Name from Account Limit 1].Id;
        
        Id runningUserId = UserInfo.getUserId();
            
            //Insert new Lead
            Lead lead1 = new Lead();
            lead1.FirstName = 'Test';
            lead1.LastName = 'Lead1';
            lead1.Company = 'Test';
            lead1.Account__c = accId;
            lead1.GBWire__RouteWorkItem__c = false;
            insert lead1;   
            
            //Retrieve the lead for passing to the Action Identifier
            Map<Id,Lead> openLead = new Map<Id,Lead>([Select Id, DuplicateNotaLeadReason__c, Territory__c, Account__c, RecordTypeId, IsOpen__c, IsNew__c, IsActive__c, GBWire__RouteWorkItem__c, 
                                                               GBWire__PreferredQueue__c, OwnerId, Golfbreaks_Business_Unit__c, SalesRegion__c, TravelGroupSize__c, IsTest__c From Lead Limit 1]);
            system.assertEquals(1,openLead.values().size());
            system.assertEquals(true,openLead.values()[0].IsOpen__c);
            //Confirm the lead is owned by running user
            openLead.values()[0].ownerId = runningUserId;
                        
            //Assign workItemType
            String workItemType = 'Lead';
                                         
            //Close the lead
            openLead.values()[0].Status = ApplicationConstant.LEAD_STATUS_DUPLICATE;
            openLead.values()[0].DuplicateNotaLeadReason__c = ApplicationConstant.LEAD_DUPLICATE_REASON;
            update openLead.values();

            Map<Id,Lead> closedLead = new Map<Id,Lead>([Select Id, DuplicateNotaLeadReason__c, Territory__c, Account__c, RecordTypeId, IsOpen__c, IsNew__c, IsActive__c, GBWire__RouteWorkItem__c, 
                                                               GBWire__PreferredQueue__c, OwnerId, Golfbreaks_Business_Unit__c, SalesRegion__c, TravelGroupSize__c, IsTest__c From Lead Where Id = :lead1.Id Limit 1]);
        
            test.startTest();            
            
            //New Maps to store results
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadUpdateClosed = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadUpdateReopened = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
              
            //Simulate Update Trigger Context
            WorkItemWIREActionIdentifier.isTestUpdate = true;
            WorkItemWIREActionIdentifier.isTestInsert = false;
        
            leadUpdateClosed = WorkItemWIREActionIdentifier.processWorkItems(openLead,closedLead,workItemType);  
            leadUpdateReopened = WorkItemWIREActionIdentifier.processWorkItems(closedLead,openLead,workItemType);  
        
            system.assertNotEquals(null, leadUpdateClosed);
            system.assertNotEquals(null, leadUpdateReopened); 

            //Confirm the Capacity action is required when a record is closed and reopened
            system.assertEquals(true, leadUpdateClosed.values().size()>0);
            system.assertEquals(true, leadUpdateClosed.values()[0].doAgentCapacityCalc);
            system.assertEquals(true, leadUpdateReopened.values().size()>0);
            system.assertEquals(true, leadUpdateReopened.values()[0].doAgentCapacityCalc);          
        
            test.stopTest();      
                
    }
    
    //This method confirms the client routing profile will be re-evaluated for the owner if the work item is closed or re-opened
    @isTest static void testCRPRecordCloseAndReOpen(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        GBWire.WorkItemTriggerHandler.disableLocalTriggers = true;//<--- 1.1 prevent routing.
        GBWire.WorkItemTriggerHandler.disableWireTriggers = true;
        
        //Query person Account
        Id accId = [Select Id, RecordType.Name, isPersonAccount, Name from Account Limit 1].Id;
        
        Id runningUserId = UserInfo.getUserId();
            
            //Insert new Lead
            Lead lead1 = new Lead();
            lead1.FirstName = 'Test';
            lead1.LastName = 'Lead1';
            lead1.Company = 'Test';
            lead1.Account__c = accId;
            lead1.GBWire__RouteWorkItem__c = false;
            insert lead1;   
            
            //Retrieve the lead for passing to the Action Identifier
            Map<Id,Lead> openLead = new Map<Id,Lead>([Select Id, DuplicateNotaLeadReason__c, Territory__c, Account__c, RecordTypeId, IsOpen__c, IsNew__c, IsActive__c, GBWire__RouteWorkItem__c, 
                                                               GBWire__PreferredQueue__c, OwnerId, Golfbreaks_Business_Unit__c, SalesRegion__c, TravelGroupSize__c, IsTest__c From Lead Limit 1]);
            system.assertEquals(1,openLead.values().size());
            system.assertEquals(true,openLead.values()[0].IsOpen__c);
            //Confirm the lead is owned by running user
            openLead.values()[0].ownerId = runningUserId;
                        
            //Assign workItemType
            String workItemType = 'Lead';
                                         
            //Close the lead
            openLead.values()[0].Status = ApplicationConstant.LEAD_STATUS_DUPLICATE;
            openLead.values()[0].DuplicateNotaLeadReason__c = ApplicationConstant.LEAD_DUPLICATE_REASON;
            update openLead.values();

            Map<Id,Lead> closedLead = new Map<Id,Lead>([Select Id, DuplicateNotaLeadReason__c, Territory__c, Account__c, RecordTypeId, IsOpen__c, IsNew__c, IsActive__c, GBWire__RouteWorkItem__c, 
                                                               GBWire__PreferredQueue__c, OwnerId, Golfbreaks_Business_Unit__c, SalesRegion__c, TravelGroupSize__c, IsTest__c From Lead Where Id = :lead1.Id Limit 1]);
        
            test.startTest();            
            
            //New Maps to store results
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadUpdateClosed = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadUpdateReopened = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
              
            //Simulate Update Trigger Context
            WorkItemWIREActionIdentifier.isTestUpdate = true;
            WorkItemWIREActionIdentifier.isTestInsert = false;
        
            leadUpdateClosed = WorkItemWIREActionIdentifier.processWorkItems(openLead,closedLead,workItemType);  
            leadUpdateReopened = WorkItemWIREActionIdentifier.processWorkItems(closedLead,openLead,workItemType);  
        
            system.assertNotEquals(null, leadUpdateClosed);
            system.assertNotEquals(null, leadUpdateReopened); 

            //Confirm the CRP action is required when a record is closed and reopened
            system.assertEquals(true, leadUpdateClosed.values().size()>0);
            system.assertEquals(true, leadUpdateClosed.values()[0].doCRPcalc);
            system.assertEquals(true, leadUpdateReopened.values().size()>0);
            system.assertEquals(true, leadUpdateReopened.values()[0].doCRPcalc);          
        
            test.stopTest();      
                
    }
    
    //This method confirms the client routing profile is re-evaluated if the work item is updated and the preferred queue is changed
    @isTest static void testCRPOnPrefQueueChange(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        GBWire.WorkItemTriggerHandler.disableLocalTriggers = true;//<--- 1.1 prevent routing.
        GBWire.WorkItemTriggerHandler.disableWireTriggers = true;
        
        //Query person Account
        Id accId = [Select Id, RecordType.Name, isPersonAccount, Name from Account Limit 1].Id;
        
        Id runningUserId = UserInfo.getUserId();
            
            //Insert new Lead
            Lead lead1 = new Lead();
            lead1.FirstName = 'Test';
            lead1.LastName = 'Lead1';
            lead1.Company = 'Test';
            lead1.Account__c = accId;
            lead1.GBWire__RouteWorkItem__c = false;
            insert lead1;   
            
            //Retrieve the lead for passing to the Action Identifier
            Map<Id,Lead> newLead = new Map<Id,Lead>([Select Id, DuplicateNotaLeadReason__c, Territory__c, Account__c, RecordTypeId, IsOpen__c, IsNew__c, IsActive__c, GBWire__RouteWorkItem__c, 
                                                               GBWire__PreferredQueue__c, OwnerId, Golfbreaks_Business_Unit__c, SalesRegion__c, TravelGroupSize__c, IsTest__c From Lead Limit 1]);
            system.assertEquals(1,newLead.values().size());
            system.assertEquals(true,newLead.values()[0].IsOpen__c);
            //Confirm the lead is owned by running user
            newLead.values()[0].ownerId = runningUserId;
                        
            //Assign workItemType
            String workItemType = 'Lead';
                                         
            //Clone the lead and change the Preferred Queue
            Map<Id,Lead> changeLead = newLead.deepClone();
            changeLead.values()[0].GBWire__PreferredQueue__c = 'Test Queue';
        
            test.startTest();            
            
            //New Maps to store results
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadPreferredQueueNoChange = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            Map<Id,GBWire.WorkItemWithActionsWrapper> leadPreferredQueueChange = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
              
            //Simulate Update Trigger Context
            WorkItemWIREActionIdentifier.isTestUpdate = true;
            WorkItemWIREActionIdentifier.isTestInsert = false;
        
            leadPreferredQueueNoChange = WorkItemWIREActionIdentifier.processWorkItems(newLead,newLead,workItemType);  
            leadPreferredQueueChange = WorkItemWIREActionIdentifier.processWorkItems(newLead,changeLead,workItemType);  
        
            system.assertNotEquals(null, leadPreferredQueueNoChange);
            system.assertNotEquals(null, leadPreferredQueueChange); 

            //Confirm the CRP action is NOT required when no change is made to the record
            system.assertEquals(true, leadPreferredQueueNoChange.values().size() == 0 || (leadPreferredQueueNoChange.values().size()>=0 && leadPreferredQueueNoChange.values()[0].doCRPcalc == false));
            //Confirm the CRP action is required when the Preferred Queue is changed    
            system.assertEquals(true, leadPreferredQueueChange.values().size()>0);
            system.assertEquals(true, leadPreferredQueueChange.values()[0].doCRPcalc);          
        
            test.stopTest();      
                
    }  
    
    //This method confirms the Preferred Queue is only updated when a relevant change is made to the record
    @isTest static void testPreferredQueueUpdate(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        GBWire.WorkItemTriggerHandler.disableLocalTriggers = true;//<--- 1.1 prevent routing.
        GBWire.WorkItemTriggerHandler.disableWireTriggers = true;
        
        //Query person Account
        Id accId = [Select Id, RecordType.Name, isPersonAccount, Name from Account Limit 1].Id;
        
        Id runningUserId = UserInfo.getUserId();
            
            //Insert new Lead
            Lead lead1 = new Lead();
            lead1.FirstName = 'Test';
            lead1.LastName = 'Lead1';
            lead1.Company = 'Test';
            lead1.Account__c = accId;
            lead1.TravelGroupSize__c = 2;
            lead1.GBWire__RouteWorkItem__c = false;
            insert lead1;   
            
            //Retrieve the lead for passing to the Action Identifier
            Map<Id,Lead> newLead = new Map<Id,Lead>([Select Id, DuplicateNotaLeadReason__c, Territory__c, Account__c, RecordTypeId, IsOpen__c, IsNew__c, IsActive__c, GBWire__RouteWorkItem__c, 
                                                               GBWire__PreferredQueue__c, OwnerId, Golfbreaks_Business_Unit__c, SalesRegion__c, TravelGroupSize__c, IsTest__c From Lead Limit 1]);
            system.assertEquals(1,newLead.values().size());
            system.assertEquals(true,newLead.values()[0].IsOpen__c);
            //Confirm the lead is owned by running user
            newLead.values()[0].ownerId = runningUserId;
        
            //Query 'Relevant' Lead fields
            WIREPreferredQueueCalcFields__mdt[] fieldSettings = [Select Id, ObjectAPIName__c, ObjectType__c, ObjectField__c From WIREPreferredQueueCalcFields__mdt Where ObjectAPIName__c = 'Lead' ];
            List<String> preferredQueueFieldChangeNames = new List<String>();
            
            if(fieldSettings != null && fieldSettings.size()>0){
                //Collate durable Ids from metadata settings
                List<String> durableIds = new List<String>();
                for(WIREPreferredQueueCalcFields__mdt fs : fieldSettings){
                    if(!durableIds.contains(fs.ObjectField__c)){
                        durableIds.add(fs.ObjectField__c);
                    }                              
                }
                //Query and collate object field api names from Entity Particle
                EntityParticle[] eps = [Select DurableId, QualifiedApiName From EntityParticle Where DurableId In:DurableIds];
                for(EntityParticle ep : eps){
                    if(preferredQueueFieldChangeNames != null && !preferredQueueFieldChangeNames.contains(ep.QualifiedApiName)){
                        preferredQueueFieldChangeNames.add(ep.QualifiedApiName);
                    }           
                }
            }   
            //Confirm there are fields in the setting
            system.assertEquals(true, preferredQueueFieldChangeNames.size()>0);
            //Confirm the Travel Group Size is still in the list
            system.assertEquals(true, preferredQueueFieldChangeNames.contains('TravelGroupSize__c'));
            //Confirm the Last Name is not in the list
            system.assertEquals(true, !preferredQueueFieldChangeNames.contains('LastName'));
                                 
            //Assign workItemType
            String workItemType = 'Lead';
                                         
            //Clone the lead and change the Travel Group Size
            Map<Id,Lead> lastNameChangeLead = newLead.deepClone();
            Map<Id,Lead> groupSizeChangeLead = newLead.deepClone();
        
            lastNameChangeLead.values()[0].LastName = 'TestName';
            groupSizeChangeLead.values()[0].TravelGroupSize__c = 10;
            
            test.startTest();            
            
            //New Maps to store results
            Map<Id,GBWire.WorkItemWithActionsWrapper> irrelevantChangeLead = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
            Map<Id,GBWire.WorkItemWithActionsWrapper> relevantChangeLead = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
              
            //Simulate Update Trigger Context
            WorkItemWIREActionIdentifier.isTestUpdate = true;
            WorkItemWIREActionIdentifier.isTestInsert = false;
        
            irrelevantChangeLead = WorkItemWIREActionIdentifier.processWorkItems(newLead,lastNameChangeLead,workItemType);  
            relevantChangeLead = WorkItemWIREActionIdentifier.processWorkItems(newLead,groupSizeChangeLead,workItemType);  
        
            system.assertNotEquals(null, irrelevantChangeLead);
            system.assertNotEquals(null, relevantChangeLead); 

            //Confirm the Preferred Queue calc action is NOT required when irrelevant changes are made to the record
            system.assertEquals(true, irrelevantChangeLead.values().size() == 0 || (irrelevantChangeLead.values().size()>=0 && irrelevantChangeLead.values()[0].doPreferredQueueCalc == false));
            //Confirm the Preferred Queue calc action is required when irrelevant changes are made to the record    
            system.assertEquals(true, relevantChangeLead.values().size()>0);
            system.assertEquals(true, relevantChangeLead.values()[0].doPreferredQueueCalc);          
        
            test.stopTest();      
                
    }  
    
    //This method confirms no actions fire if an update is made on a closed record (that does not lead to the record being re-opened)
    @isTest static void testUpdateOnClosedRecord(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        GBWire.WorkItemTriggerHandler.disableLocalTriggers = true;//<--- 1.1 prevent routing.
        GBWire.WorkItemTriggerHandler.disableWireTriggers = true;
        
        //Query person Account
        Id accId = [Select Id, RecordType.Name, isPersonAccount, Name from Account Limit 1].Id;
        
        Id runningUserId = UserInfo.getUserId();
            
            //Insert new Lead
            Lead lead1 = new Lead();
            lead1.FirstName = 'Test';
            lead1.LastName = 'Lead1';
            lead1.Company = 'Test';
            lead1.Account__c = accId;
            lead1.GBWire__RouteWorkItem__c = false;
            insert lead1;   
            
            //Retrieve the lead for passing to the Action Identifier
            Map<Id,Lead> openLead = new Map<Id,Lead>([Select Id, DuplicateNotaLeadReason__c, Territory__c, Account__c, RecordTypeId, IsOpen__c, IsNew__c, IsActive__c, GBWire__RouteWorkItem__c, 
                                                               GBWire__PreferredQueue__c, OwnerId, Golfbreaks_Business_Unit__c, SalesRegion__c, TravelGroupSize__c, IsTest__c From Lead Limit 1]);
            system.assertEquals(1,openLead.values().size());
            system.assertEquals(true,openLead.values()[0].IsOpen__c);
            //Confirm the lead is owned by running user
            openLead.values()[0].ownerId = runningUserId;
                        
            //Assign workItemType
            String workItemType = 'Lead';
                                         
            //Close the lead
            openLead.values()[0].Status = ApplicationConstant.LEAD_STATUS_DUPLICATE;
            openLead.values()[0].DuplicateNotaLeadReason__c = ApplicationConstant.LEAD_DUPLICATE_REASON;
            update openLead.values();

            Map<Id,Lead> closedLead = new Map<Id,Lead>([Select Id, DuplicateNotaLeadReason__c, Territory__c, Account__c, RecordTypeId, IsOpen__c, IsNew__c, IsActive__c, GBWire__RouteWorkItem__c, 
                                                               GBWire__PreferredQueue__c, OwnerId, Golfbreaks_Business_Unit__c, SalesRegion__c, TravelGroupSize__c, IsTest__c From Lead Where Id = :lead1.Id Limit 1]);
        
            system.assertEquals(false, closedLead.values()[0].IsOpen__c);
        
            test.startTest();            
            
            //New Maps to store results
            Map<Id,GBWire.WorkItemWithActionsWrapper> closedLeadUpdated = new Map<Id,GBWire.WorkItemWithActionsWrapper>();
              
            //Simulate Update Trigger Context
            WorkItemWIREActionIdentifier.isTestUpdate = true;
            WorkItemWIREActionIdentifier.isTestInsert = false;
        
            closedLeadUpdated = WorkItemWIREActionIdentifier.processWorkItems(closedLead,closedLead,workItemType);  
        
            system.assertNotEquals(null, closedLeadUpdated); 

            //Confirm zero actions are required 
            system.assertEquals(true, closedLeadUpdated.values().size()==0);     
        
            test.stopTest();      
                
    }
    
    @isTest static void testRouteWorkItemWithActiveAssignmentRules(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        //Query Case Configuration
        GBWire__RoutingConfiguration__mdt config = GBWire.RoutingConfigurationHelper.getValidRoutingConfigurations(ApplicationConstant.CASE_SOBJECTTYPE).values()[0];
        system.assertNotEquals(null,config);
        
        //Query IT Support Record Type
        String recordTypeIdString = (String)[Select Id From RecordType Where SObjectType = 'Case' and (DeveloperName = :ApplicationConstant.RECORD_TYPE_CASE_IT_SUPPORT OR DeveloperName = :ApplicationConstant.RECORD_TYPE_CASE_SALESFORCE ) Limit 1].Id;
        system.assertNotEquals(null,recordTypeIdString);
        
        //Confirm IT Support is in the excluded RTs column
        system.assertNotEquals(null,config.GBWire__ExcludedRecordTypes__c);
        system.assertEquals(true, config.GBWire__ExcludedRecordTypes__c.contains(recordTypeIdString));
        
        //Confirm IT Support is configured in the 'GBWire__RTsToAssignWithActiveAssignmentRules2__c' field
        system.assertEquals(true,config.GBWire__RTsToAssignWithActiveAssignmentRules2__c.contains(recordTypeIdString));
        
        //Insert an IT Support Case
        Case cse = new Case();
        cse.RecordTypeId = (Id)recordTypeIdString;
        cse.Subject = 'Unit Test Support Case';
        cse.Reporter__c = UserInfo.getUserId();
        insert cse;
        
        //Query Case
        Case c = [Select Id, OwnerId, RecordTypeId From Case Where Id =:cse.Id LIMIT 1][0];
        //Confirm the case has remained with the current user
        system.assertEquals(UserInfo.getUserId(), c.OwnerId);
        
        //Simulate Insert Trigger
        WorkItemWIREActionIdentifier.isTestInsert = true;
        WorkItemWIREActionIdentifier.isTestUpdate = false;
        
        Map<Id,sObject> caseMap = new Map<Id,sObject>();
        caseMap.put(c.Id,c);
        
        //Run Action Identifier
        test.startTest();
            WorkItemWIREActionIdentifier.processWorkItems(null, caseMap, 'Case');
        test.stopTest();
        
        //Confirm the Case has been routed to a queue (assumed to be via Assignment Rules)     
        Case[] cseAfterInsert = [Select Id, OwnerId From Case Where Id = :cse.Id LIMIT 1];
        system.debug('cseAfterInsert owner: '+cseAfterInsert[0].ownerId);
        String ownerIdString = (String)cseAfterInsert[0].OwnerId;
        system.assertEquals(true, ownerIdString.startsWithIgnoreCase('00G')); 
                
    }

    @isTest static void testExecuteWIRETriggerActionsFutureMethod(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        GBWire.WorkItemTriggerHandler.disableLocalTriggers = true;//<--- 1.1 prevent routing.
        GBWire.WorkItemTriggerHandler.disableWireTriggers = true;
        
        //New Lead Inserted by Sales Agent
        User agent = [Select Id, ProfileId From User Where Profile.Name =:ApplicationConstant.PROFILE_SALES_AGENT and IsActive = true Limit 1][0];
        system.runAs(agent){
            
            //Insert new Lead
            Lead lead1 = new Lead();
            lead1.FirstName = 'Test';
            lead1.LastName = 'Lead1';
            lead1.Company = 'Test';
            lead1.GBWire__RouteWorkItem__c = true;
            insert lead1;
            
            //Insert new Lead
            Lead lead2 = new Lead();
            lead2.FirstName = 'Test';
            lead2.LastName = 'Lead2';
            lead2.Company = 'Test';
            lead2.GBWire__RouteWorkItem__c = false;
            insert lead2;
            
            Id doAssignLeadId = Lead1.Id;
            Id dontAssignLeadId = Lead2.Id;
            
            //Retrieve the lead for passing to the Action Identifier
            Map<Id,Lead> newLeads = new Map<Id,Lead>([Select Id, Account__c, Territory__c, RecordTypeId, IsOpen__c, IsNew__c, IsActive__c, GBWire__RouteWorkItem__c, 
                                                               GBWire__PreferredQueue__c, OwnerId, Golfbreaks_Business_Unit__c, SalesRegion__c, TravelGroupSize__c, IsTest__c From Lead Limit 2]);
            
            //Simulate Insert Trigger Context
            WorkItemWIREActionIdentifier.isTestInsert = true;
                        
            System.debug(LoggingLevel.ERROR, 'newLeads='+newLeads);

            String workItemType = 'Lead';
            Map<Id,GBWire.WorkItemWithActionsWrapper> WIREMap = WorkItemWIREActionIdentifier.processWorkItems(null,newLeads,workItemType);
            
            Map<String,Object> mapToValue;
            Map<Id,Map<String,Object>> WIREMapSerializable = new Map<Id,Map<String,Object>>();//1.21+ -- managed package classes serializable in the namespace only.

            for(Id leadId : WIREMap.keySet()){

                mapToValue = new Map<String,Object>();

                mapToValue.put('doAssign',WIREMap.get(leadId).doAssign);
                mapToValue.put('doPreferredQueueCalc',WIREMap.get(leadId).doPreferredQueueCalc);
                mapToValue.put('doCRPCalc',WIREMap.get(leadId).doCRPCalc);
                mapToValue.put('doAgentCapacityCalc',WIREMap.get(leadId).doAgentCapacityCalc);
                mapToValue.put('doPreferredAgentCalc',WIREMap.get(leadId).doPreferredAgentCalc);
                mapToValue.put('previousOwnerId',WIREMap.get(leadId).previousOwnerId);
                mapToValue.put('previousClientId',WIREMap.get(leadId).previousClientId);

                WIREMapSerializable.put(leadId,mapToValue);
            }
            String wireMapSerialised = JSON.serialize(WIREMapSerializable);
            
            System.assertEquals(0, [select count() from AsyncApexJob where (JobType='Queueable') and ApexClass.Name='WorkItemWIREActionIdentifier' limit 1]);

            test.startTest();
            WorkItemWIREActionIdentifier.executeWIRETriggerActionsFuture(wireMapSerialised, 'Lead', true);
            test.stopTest();            
            
            System.assertEquals(1, [select count() from AsyncApexJob where (JobType='Queueable') and ApexClass.Name='WorkItemWIREActionIdentifier' limit 1]);
        }   
    }
}