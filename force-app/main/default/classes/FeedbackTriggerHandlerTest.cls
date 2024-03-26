/*
Name:  FeedbackTriggerHandlerTest
======================================================
======================================================
Purpose:
-------
Test Suite for Feedback Trigger activity.

======================================================
======================================================
History
------- 
Ver. Author                Date             Detail
1.0  J Radcliffe           2021-01-21       Initial development. Enabling Object for ActOnIt Alerts
1.1  J Radcliffe           2023-11-09       Bug fix. See below



1.1 continued: There appears to be a bug in the flow framework (in a test context). Any attempt insert multiple opportunity records triggers the following flow error for the AOI Log Activity action:
FLOW_INTERVIEW_HANDLED_ERROR
'The number of results does not match the number of interviews that were executed in a single bulk execution request.'

The error suggests the packaged flow action is not returning the same number of results as requests that are passed in. However, manual testing has proven this to be false:
1) I have replicated the same process in execute annonymous (keeping the code as like-for-like as possible) and seen all records created without errors. This includes the activity within the apex action executing successfully. 
2) I have set a flag in the action called 'processAsync' to true, which I know immediately queues the action and returns an exact (accurate) number of responses (before any processing -that might cause exceptions etc- takes place).
3) The debugs reveal no processing of the apex action. It hits the error right away, which further confirms there's nothing particularly wrong with the action itself. 

Workaround: I am forced to reduce the batch size to 1 for test methods until this is resolved.

*/
@isTest
public with sharing class FeedbackTriggerHandlerTest {
    
    @TestSetup static void testSetup(){

        //Create 50 Person Accounts
        List<Account> accs = AP23_TestDataFactory.createPersonAccount(1);//1.1~
        insert(accs);
        
        //Create 50 Opportunities (1 for each Account)
        List<Opportunity> opps = new List<Opportunity>();
        for(Account acc : accs){
            opps.add(AP23_TestDataFactory.createOpportunity(1,ApplicationConstant.QUOTESENTSTAGE,acc)[0]);
        }
        insert opps;

        //Enable org triggers
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;  
         
    }

    //A simple test method to increase trigger code coverage and ensure the AOI application's handler does not trigger failures 
    @isTest static void testFeedbackInsert(){
        
        List<Feedback__c> feedbackList = new List<Feedback__c>();
        for(Opportunity opp : [Select Id, AccountId From Opportunity]){
            feedbackList.add(new Feedback__c(Account__c=opp.AccountId,Opportunity__c=opp.Id,OpportunityDeleteReason__c='Price'));
        }
        system.assertEquals(1, feedbackList.size());//1.1~
        test.startTest();
            insert feedbackList;
        test.stopTest();

        system.assertEquals(1, [Select Id From Feedback__c].size());//1.1~
    }
}