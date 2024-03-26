/**
* Class Name: AP05_OpportunityTriggerHandler_Test
* @author: Emman Flores
* @date: 07.05.2016
* @description: Test AP05_OpportunityTriggerHandler
History
------- 
Ver. Author        Date         Detail 
2.0  J Radcliffe   2024-02-13   New test method: testAssignPublicIdsOnInsert.
2.1  Mark Cane&    2024-02-29   New Test Method: testExecuteWIRETriggerActionsFutureMethod.
*/

@isTest(seeAllData=false)
public class AP05_OpportunityTriggerHandler_Test{

    @TestSetup
    static void testSetup(){

        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;  

        insert new Phased_Code_Removal__c(ActivatePublicIdGeneration__c = true);//2.0+        

                
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
    }
       
    static testMethod void testEvents() {
    
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//<-- block WIRE calculations for test data.
    	GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
        
        //Create Account
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        database.insert(acc);
        
        //Create Opportunity
        List<Opportunity> opportunityList = new List<Opportunity>();
        opportunityList = AP23_TestDataFactory.createOpportunity(50,'1. Recommendations',acc);
        for(Opportunity opp : opportunityList){
            opp.ServiceAgentAssigned__c = 'Test Agent';
        }
        
        
        
        List<Opportunity> newOppList = new List<Opportunity>(opportunityList);
        List<Opportunity> oldOppList = new List<Opportunity>(opportunityList);
        Map<Id,Opportunity> newOppMap = new Map<Id,Opportunity>([SELECT Id FROM Opportunity]);
        Map<Id,Opportunity> oldOppMap = new Map<Id,Opportunity>([SELECT Id FROM Opportunity]);
        
        test.startTest();
            database.insert(opportunityList);
            System.assertEquals(50, [SELECT Count() FROM Opportunity]);
            
            for(Opportunity opp : opportunityList){
                opp.StageName = '2. Quote Sent';
            }
            database.update(opportunityList);
            System.assertEquals(opportunityList[49].StageName, '2. Quote Sent');
            
            
            // opptriggerhandler.OnBeforeInsert(newOppList);
            // opptriggerhandler.OnBeforeUpdate(newOppList,newOppMap,oldOppList,oldOppMap);
            // opptriggerhandler.OnAfterInsert(newOppList,newOppMap,oldOppList,oldOppMap);
            // opptriggerhandler.OnAfterUpdate(newOppList,newOppMap,oldOppList,oldOppMap);
            // opptriggerhandler.OnBeforeDelete(newOppList,newOppMap,oldOppList,oldOppMap);
            // opptriggerhandler.OnAfterDelete(newOppList,newOppMap,oldOppList,oldOppMap);
            
            
            AP05_OpportunityTriggerHandler opptriggerhandler = new AP05_OpportunityTriggerHandler();
            opptriggerhandler.OnAfterUnDelete(newOppList,newOppMap,oldOppList,oldOppMap);
            opptriggerhandler.OnUndelete(newOppList,newOppMap,oldOppList,oldOppMap);
            database.delete(opportunityList);
            System.assertEquals(0, [SELECT Count() FROM Opportunity]);
        test.stopTest();  
    }

    //2.0+
    @isTest static void testAssignPublicIdsOnInsert(){
        
        Account acc = AP23_TestDataFactory.createPersonAccount(1,true)[0];
        insert(acc);

        List<Opportunity> oppList = AP23_TestDataFactory.createOpportunity(10,ApplicationConstant.RECOMMENDATIONSTAGE,acc);

        test.startTest();
            insert oppList;
            Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>(oppList);
            system.assertEquals(10, [Select Count() From Opportunity Where Id In:oppMap.keySet() and PublicId__c != null]);
        test.stopTest();

    }

    @isTest static void testExecuteWIRETriggerActionsFutureMethod(){//2.1+
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        GBWire.WorkItemTriggerHandler.disableLocalTriggers = false;
        GBWire.WorkItemTriggerHandler.disableWireTriggers = true;

        AP05_OpportunityTriggerHandler.isQueueableLimitReached = true;
        
        //New Lead Inserted by Sales Agent
        User agent = [Select Id, ProfileId From User Where Profile.Name =:ApplicationConstant.PROFILE_SALES_AGENT and IsActive = true Limit 1][0];
        system.runAs(agent){

            Account acc = AP23_TestDataFactory.createPersonAccount(1,true)[0];
            insert(acc);

            List<Opportunity> oppList = AP23_TestDataFactory.createOpportunity(1,ApplicationConstant.OPP_STAGE_NEW,acc);
            oppList[0].ActionType__c = 'TestImport';

            System.assertEquals(0, [select count() from AsyncApexJob where (JobType='Queueable') and ApexClass.Name='WorkItemWIREActionIdentifier' limit 1]);// -- futures are not queryable in a test context.

            test.startTest();
            insert oppList;
            test.stopTest();

            System.assertEquals(1, [select count() from AsyncApexJob where (JobType='Queueable') and ApexClass.Name='WorkItemWIREActionIdentifier' limit 1]);
        }
    }
}