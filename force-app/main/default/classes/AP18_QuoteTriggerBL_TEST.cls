/*
Name:  AP18_QuoteTriggerBL_TEST.cls
======================================================
======================================================
Purpose:
-------
Test Class for AP18_QuoteTriggerBL
======================================================
======================================================
History
------- 
Ver. Author             Date         Detail
1.0  Abram Vixen Reyes  2016-04-01   Initial development
1.1  Simon Molloy       2017-11-01   Added new test classes for updateLeadOpportunityAmount method
*/

@isTest
public class AP18_QuoteTriggerBL_TEST{
    
     @testSetup static void setupCommonData(){         
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings; 

        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        
        List<Account> accList = new List<Account>();
        accList = AP23_TestDataFactory.createPersonAccount(1);
        insert accList;

        List<Lead> leadList = AP23_TestDataFactory.createLead(100);
        insert leadList;
       
        List<Opportunity> oppList = new List<Opportunity>();
        oppList = AP23_TestDataFactory.createOpportunity(100, ApplicationConstant.RECOMMENDATIONSTAGE, accList[0]);
        insert oppList; 
         
        List<Quote__c> qteList =  AP23_TestDataFactory.createQuote(100, 'Sample Quote', oppList[0], accList[0]);
         for(Integer i=0; i<100; i++){
             qteList[i].Opportunity__c = oppList[i].Id;
             qteList[i].Source_Lead__c = leadList[i].Id;
         }
        insert qteList; 
            
    }
    
    @isTest static void tstQuoteAccepted(){       
        List<Quote__c> qteList = [SELECT Id, Name, Opportunity__r.Id, Opportunity__r.StageName, Opportunity__r.Amount, GrossProfit__c, Status__c FROM Quote__c ORDER BY CreatedDate LIMIT 100];
        System.assertEquals(100, qteList.size());
        
        for(Quote__c qte : qteList){
            qte.GrossProfit__c = 100;
            qte.Status__c = ApplicationConstant.QUOTEACCEPTEDSTATUS;
        }
        update qteList;

        test.startTest();
        AP18_QuoteTriggerBL.updateOpportunityStage(qteList);
        //AP18_QuoteTriggerBL.updateOpportunityAmount(qteList);
        AP18_QuoteTriggerBL.updateLeadOpportunityAmount(qteList);
        test.stopTest();
        
        List<Quote__c> updatedQteList = [SELECT Id, Name, Opportunity__r.Id, Opportunity__r.StageName, Opportunity__r.Amount, GrossProfit__c, Status__c FROM Quote__c ORDER BY CreatedDate LIMIT 100];
        for(Quote__c upd : updatedQteList){
            System.assertEquals(ApplicationConstant.QUOTESENTSTAGE, upd.Opportunity__r.StageName);
            System.assertEquals(upd.GrossProfit__c, upd.Opportunity__r.Amount);
        }   
    }
    
    @isTest static void tstQuoteBooking(){       
        List<Quote__c> qteList = [SELECT Id, Name, Opportunity__r.Id, Opportunity__r.StageName, Opportunity__r.Amount, GrossProfit__c, Status__c FROM Quote__c ORDER BY CreatedDate LIMIT 100];
        System.assertEquals(100, qteList.size());
        
        for(Quote__c qte : qteList){
            qte.GrossProfit__c = 100;
            qte.Status__c = ApplicationConstant.QUOTEBOOKINGSTATUS;
        }
        update qteList;
        
        test.startTest();
        AP18_QuoteTriggerBL.updateOpportunityStage(qteList);
        AP18_QuoteTriggerBL.updateLeadOpportunityAmount(qteList);
        test.stopTest();
        
        List<Quote__c> updatedQteList = [SELECT Id, Name, Opportunity__r.Id, Opportunity__r.StageName, Opportunity__r.Amount, GrossProfit__c, Status__c FROM Quote__c ORDER BY CreatedDate LIMIT 100];
        for(Quote__c upd : updatedQteList){
            System.assertEquals(ApplicationConstant.CUSTOMERACCEPTEDSTAGE, upd.Opportunity__r.StageName);
            System.assertEquals(upd.GrossProfit__c, upd.Opportunity__r.Amount);
        }   
    }   
    
    @isTest static void tstNegative(){       
        List<Quote__c> qteList = [SELECT Id, Name, Opportunity__r.Id, Opportunity__r.StageName, Opportunity__r.Amount, Opportunity__r.Name, GrossProfit__c, Status__c FROM Quote__c ORDER BY CreatedDate LIMIT 100];
        System.assertEquals(100, qteList.size());
        
        for(Quote__c qte : qteList){
            qte.Status__c = ApplicationConstant.QUOTEBOOKINGSTATUS;
        }
        update qteList;
        
        test.startTest();
        try{
            AP18_QuoteTriggerBL.updateOpportunityStage(qteList);
            AP18_QuoteTriggerBL.updateLeadOpportunityAmount(qteList);            
        }catch(Exception e){
            
        }
        test.stopTest();
        
        List<Quote__c> updatedQteList = [SELECT Id, Name, Opportunity__r.Id, Opportunity__r.StageName, Opportunity__r.Amount, GrossProfit__c, Status__c FROM Quote__c ORDER BY CreatedDate LIMIT 100];
        for(Quote__c upd : updatedQteList){
            System.assertEquals(ApplicationConstant.CUSTOMERACCEPTEDSTAGE, upd.Opportunity__r.StageName);
            System.assertEquals(upd.GrossProfit__c, upd.Opportunity__r.Amount);
        }   
    } 
       
}