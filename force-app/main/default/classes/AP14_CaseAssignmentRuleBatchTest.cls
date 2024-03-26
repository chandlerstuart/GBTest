/**
Name:  AP14_CaseAssignmentRuleBatchTest.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test Class for AP14_CaseAssignmentRuleBatch
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.0  A. Seril 2016-04-26   Initial test class development
2.0  C. Gaylan 2016-05-10   
3.0  Atlee 2016-05-11   Updated the test class
3.1  SMolloy 2016-11-25  Ensure Cases have Opportunity__c field populated as per business rules

**/

@isTest(seeAllData=false)
public class AP14_CaseAssignmentRuleBatchTest {
    @testSetup static void setupData(){
        List<Group> lGroup = new List<Group>();
        Group testGroup = new Group(Name='CS-UK-Level1', type=ApplicationConstant.USP_QUEUE);
        Group testGroup2 = new Group(Name='CS-UK-Level2', type=ApplicationConstant.USP_QUEUE);
        Group testGroup3 = new Group(Name='CS-EU-Level1', type=ApplicationConstant.USP_QUEUE);
        Group urgentGroup = new Group(Name=ApplicationConstant.QUEUE_CS_URGENT , type=ApplicationConstant.USP_QUEUE);
        lGroup.add(testGroup);
        lGroup.add(testGroup2);
        lGroup.add(testGroup3);
        lGroup.add(urgentGroup);
        insert lGroup;
        
        List<CaseRoutes__c> lCaseRoutes = new List<CaseRoutes__c>();
        CaseRoutes__c caseRoute1 = new CaseRoutes__c (Name='CS-EU-Level1', RouteName__c=ApplicationConstant.QUEUE_CS_EU);
        CaseRoutes__c caseRoute2 = new CaseRoutes__c (Name='CS-ROW-LongHaul-Level1', RouteName__c='CS-ROW');
        lCaseRoutes.add(caseRoute1);  
        lCaseRoutes.add(caseRoute2);
        insert lCaseRoutes;
          
        System.runAs(new User(Id=UserInfo.getUserId())){
            List<QueuesObject> lQueue = new List<QueueSObject>();
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SobjectType = 'Case');
            QueuesObject testQueue2 = new QueueSObject(QueueID = testGroup2.id, SobjectType = 'Case');
            QueuesObject testQueue3 = new QueueSObject(QueueID = testGroup3.id, SobjectType = 'Case');
            QueuesObject urgentQueue = new QueueSObject(QueueID = urgentGroup.id, SobjectType = 'Case');
            lQueue.add(testQueue);
            lQueue.add(testQueue2);
            lQueue.add(testQueue3);
            lQueue.add(urgentQueue);
            insert lQueue;
        }
        
        List<Account> accList = AP23_TestDataFactory.createAccount(1);
        insert accList;

        List<Opportunity> oppList = AP23_TestDataFactory.createOpportunity(1,ApplicationConstant.CLOSESALESTAGE,accList[0]);
        insert oppList;
        
        Sales_Agent_Attributes__c saa = new Sales_Agent_Attributes__c(Online__c = TRUE, NumberOfOnlineUser__c = 2, Queue__c = testGroup3.Name); 
        insert saa;
 
        List<Case> caseList = new List<Case>();
        Case cas = new Case(Status = 'New', Type = 'Question', AccountId = accList[0].Id, OwnerId = testGroup.Id, RequestedCallBackDateAndTime__c = DateTime.Now().addMinutes(1), Opportunity__c = oppList[0].Id); //Urgent
        Case cas2 = new Case(Status = 'New', Type = 'Complaint', AccountId = accList[0].Id, OwnerId = testGroup2.Id, RequestedCallBackDateAndTime__c = DateTime.Now(), Opportunity__c = oppList[0].Id);
        Case cas3 = new Case(Status = 'New', Type = 'Feedback', AccountId = accList[0].Id, OwnerId = testGroup3.Id, RequestedCallBackDateAndTime__c = DateTime.Now(), Opportunity__c = oppList[0].Id);
        caseList.add(cas);
        caseList.add(cas2);
        caseList.add(cas3);
        insert caseList;
        
    }

    static testMethod void testBatch(){
        Test.startTest();
        AP14_CaseAssignmentRuleBatch casebatch = new AP14_CaseAssignmentRuleBatch();        
        Database.executeBatch(casebatch);
        
        List<Group> lGroup = [SELECT Id, Name FROM Group];
        Group testGrp = new Group();
        Group testGrp2 = new Group();
        Group urgentGrp = new Group();  
        for(Group grp: lGroup){
            if(grp.Name == 'CS-UK-Level1'){
                testGrp = grp;    
            }
            
            if(grp.Name == 'CS-UK-Level2'){
                testGrp2 = grp;    
            }
            
            if(grp.Name == AP35_AppConstantForScheduledClass.QUEUE_CS_URGENT){
                urgentGrp = grp;    
            }            
        }
        
        
        List<Case> lCase = [SELECT Id, Type, OwnerId, Owner.Name, TECH_IsUrgent__c FROM Case];
        Case testCase = new Case();
        Case testCase2 = new Case();
        
        for(Case cs: lCase){
            if(cs.Type == 'Question'){
                testCase = cs;
            }
            
            if(cs.Type == 'Complaint'){
                testCase2 = cs;
            }
       
        }
        System.AssertEquals(testCase.TECH_IsUrgent__c, TRUE);
        system.debug(testCase.TECH_IsUrgent__c);
        //System.AssertEquals(testCase2.Owner.Name, testGrp2.Name);

        Test.stopTest();
    }

}