/**
Name:  WithoutSharingUtility_Test.cls
Copyright © 2017  GolfBreaks
======================================================
======================================================
Purpose:
-------
Test Class for WithoutSharingUtility
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.0  S.Molloy     2017-01-03   Initial test class development
1.1  M.Cane       2018-06-08   Added testDeleteSObjects.
1.2  M.Cane       2018-06-14   Added createAccountValidationRulesByProfileId() and createPersonAccount() to testSetup to fix test execution errors on Client insert.
1.3  J.Radcliffe  2019-07-05   Removing redundant methods
**/
@isTest
private class WithoutSharingUtility_Test {
    @testSetUp static void dataSetUp(){
        
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;         
        
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());//1.2
        insert validationList;      
        
        List<Account> accList = AP23_TestDataFactory.createPersonAccount(1);//1.2
        insert accList;
        
        List<Opportunity> oppList = AP23_TestDataFactory.createOpportunity(20, ApplicationConstant.RECOMMENDATIONSTAGE, accList[0]);
        for(Opportunity oppty : oppList){
            oppty.RecordTypeId = ApplicationConstant.OPP_RECTYPEID_NSO;
        }
        insert oppList;
        
        List<Booking__c> bkList = AP23_TestDataFactory.createBooking(20, accList[0].Id, oppList[0].Id);
        for(Integer i=0; i<20; i++){
            bkList[i].TECH_Opportunity__c = oppList[i].Id;
        }
        insert bkList;
        
        Integer RoleCount = [SELECT COUNT() FROM UserRole WHERE DeveloperName = :ApplicationConstant.UK_TRANSIENT_SALES_AGENT LIMIT 1];
        Integer PrCnt = [SELECT COUNT() FROM Profile WHERE Name = 'Golfbreaks Sales User' LIMIT 1];
        if(RoleCount > 0  && PrCnt > 0){
            UserRole usrole = [SELECT Id FROM UserRole WHERE DeveloperName = :ApplicationConstant.UK_TRANSIENT_SALES_AGENT LIMIT 1];
            Profile pr = [SELECT Id FROM Profile WHERE Name = 'Golfbreaks Sales User' LIMIT 1];
             User sampleUser = new User(
                Username = 'stuser@sfdc.com.prod',
                Alias = 'stuser',
                email = 'stuser@sfdc.com',
                emailencodingkey = 'UTF-8',
                LastName = 'TstUser',
                LanguageLocaleKey= 'en_US',
                LocaleSidKey = 'en_US',
                UserRole = usrole,
                ProfileId = pr.Id,
                TimeZoneSidKey = 'America/Los_Angeles'
            );
            insert sampleUser; 
        }
               
    }

    @isTest static void testUpdateCaseIdOnAccount(){
        Account acc = [select Id from Account LIMIT 1];
        RecordType amendmentRT = [select Id from RecordType where SObjectType = 'Case' and DeveloperName = 'CAS_Amendment' LIMIT 1];
        List<Case> caseList = AP23_TestDataFactory.createCase(1, acc);
        caseList[0].AccountId = acc.Id;
        caseList[0].RecordTypeId = amendmentRT.Id;

        test.startTest();
            WithoutSharingUtility.updateCaseIdOnAccount(caseList);
        test.stopTest();
    }

    //1.3
    /*
    @isTest static void tstupdateMonthlySalesTargetRollup(){
       List<Opportunity> oppList = [SELECT Id, IsClosed, StageName, RequestedCallbacktimedate__c, TECH_NVMCallBackUrgent__c, Reminder_Event__c, RecordTypeId, AccountId, OwnerId FROM Opportunity ORDER BY CreatedDate DESC LIMIT 10];
       System.assertEquals(10, ApplicationConstant.getCount(oppList));   
       
       Integer usCount = [SELECT COUNT() FROM USER WHERE isActive = true AND UserRole.DeveloperName = :ApplicationConstant.UK_TRANSIENT_SALES_AGENT LIMIT 1];
        if(usCount > 0){
             User agnt = [SELECT Id FROM USER WHERE isActive = true AND UserRole.DeveloperName = :ApplicationConstant.UK_TRANSIENT_SALES_AGENT LIMIT 1];
           
               Monthly_Sales_Target__c mnthlyList = AP23_TestDataFactory.createMonthlySalesTargetByGrossProfit(agnt, Date.today());
               insert mnthlylist;
                
                for(Opportunity opp : oppList){
                    opp.StageName = ApplicationConstant.OPPORTUNITY_STAGENAME_FULL_DEPOSIT;
                    opp.TECH_Monthly_Sales_Target__c = mnthlyList.Id;
                }
                
                Map<Id,Opportunity> oldOppMap = new Map<Id, Opportunity>();
                for(Opportunity opp: oppList)
                {
                     oldOppMap.put(opp.Id, opp);
                }  
                
                test.startTest();
                AP06_OpportunityTriggerBL.updateMonthlySalesTargetRollup(oppList, oldOppMap);
                oldOppMap = null;
                System.assertEquals(null, oldOppMap);
                AP06_OpportunityTriggerBL.updateMonthlySalesTargetRollup(oppList, oldOppMap);
                test.stopTest();
        } 
    }*/

    @isTest static void testDeleteSObjects(){
        List<Opportunity> oppList = [select Id from Opportunity];       
        System.assert(!oppList.isEmpty());

        Test.startTest();
        WithoutSharingUtility.deleteSObjects(oppList);
        Test.stopTest();
        
        oppList = [select Id from Opportunity];     
        System.assert(oppList.isEmpty());        
    }    
    
}