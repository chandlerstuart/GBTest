/*
Name:  AP16_ExpectedPaymentTriggerBL_TEST.cls
======================================================
======================================================
Purpose:Test suite for AP16_ExpectedPaymentTriggerBL.cls
-------
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
2.0  J Radcliffe   2021-07-26   Changes to support trigger optimisation 
*/
@isTest
public class AP16_ExpectedPaymentTriggerBL_TEST{

    //JR - TO DO - 
    //2.0 - Made minor changes to get this up and running so I can deploy changes that will improve the selectivity of the trigger, but this requires a full rebuild!

    
    @testSetup static void setupCommonData(){

        WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//<--  block WIRE calculations for test data.
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        List<Account> accList = new List<Account>();
        accList = AP23_TestDataFactory.createPersonAccount(1);//2.0~ - chnaged from createAccount to createPersonAccount
        insert accList;
       
        List<Opportunity> oppList = new List<Opportunity>();
        oppList = AP23_TestDataFactory.createOpportunity(100, ApplicationConstant.RECOMMENDATIONSTAGE, accList[0]);
        Id contactedRTId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(ApplicationConstant.OPPORTUNITY_CONTACTED).getRecordTypeId();
        for(Opportunity opp :oppList){
            opp.RecordTypeId =  contactedRTId;
            opp.Contact_Made_Date_Time__c = system.now();
            opp.Assigned_Date_Time__c = system.now();
        }
        insert oppList;
        
        List<Booking__c> booklist = new List<Booking__c>();
        booklist = AP23_TestDataFactory.createBooking(100, accList[0].Id, oppList[0].Id);
        for(Integer i=0; i<100; i++){
            booklist[0].TECH_Opportunity__c = oppList[i].Id;
        }
        insert booklist;      
        
        List<Expected_Payment__c> epay = AP23_TestDataFactory.createExpectedPayment(100, bookList[0], ApplicationConstant.EPAYMENTTYPEPARTIALDEPOSIT, 100.0);  
        for(Integer i=0; i<100; i++){
            epay[i].Booking__c = bookList[i].Id;
        }
        insert epay;

        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings; 
   
    }  
     
    public static testMethod void tstPartialDeposit(){
        Integer actvCount = 0;
        Integer profileCount = 0;
        List<String> profileName = new List<String>{ApplicationConstant.PROFILE_GB_SYSADMIN, ApplicationConstant.PROFILE_GB_SYSADMIN };
        profileCount = [SELECT COUNT() FROM Profile WHERE Name IN: profileName];
        if(profileCount > 0){
            Profile p = [SELECT Id FROM Profile WHERE Name IN: profileName LIMIT 1];
            actvCount = [SELECT COUNT() from USER WHERE isActive = true AND Profile.Id =: p.Id];
            if(actvCount > 0 ){
                User up = [SELECT Id from USER WHERE isActive = true AND Profile.Id =: p.Id LIMIT 1];
                System.runAs(up){
                    List<Expected_Payment__c> epayList = [SELECT Id, Booking__c, Booking__r.TECH_Opportunity__r.StageName, Booking__r.AmountPaid__c, Expected_Amount__c, Outstanding_Balance__c, ExpectedPaymentType__c FROM Expected_Payment__c ORDER BY CREATEDDATE LIMIT 50];                       
                    system.assertEquals(50, epayList.size());
                    
                    test.startTest();
                    GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
                    AP16_ExpectedPaymentTriggerBL.updateOpportunityStage(epayList); 
                    test.stopTest();
                    
                    List<Expected_Payment__c> updatedEpay = [SELECT Id, Booking__c, Booking__r.TECH_Opportunity__r.StageName, Booking__r.AmountPaid__c, Expected_Amount__c, Outstanding_Balance__c, ExpectedPaymentType__c FROM Expected_Payment__c ORDER BY CREATEDDATE LIMIT 50];
                    for(Expected_Payment__c ep : updatedEpay){
                        //Check if Opportunity Stage Name =  '5. Customer Paid: Partial Deposit'
                        System.assertEquals(ApplicationConstant.PAIDPARTIALDEPOSITSTAGE, ep.Booking__r.TECH_Opportunity__r.StageName);
                    }
                }
            }//end actvCount            
        }//end profileCount
    }
    
    public static testMethod void tstFullDeposit(){
        Integer actvCount = 0;
        Integer profileCount = 0;
        List<String> profileName = new List<String>{ApplicationConstant.PROFILE_GB_SYSADMIN, ApplicationConstant.PROFILE_GB_SYSADMIN };
        profileCount = [SELECT COUNT() FROM Profile WHERE Name IN: profileName];
        if(profileCount > 0){
            Profile p = [SELECT Id FROM Profile WHERE Name IN: profileName LIMIT 1];
            actvCount = [SELECT COUNT() from USER WHERE isActive = true AND Profile.Id =: p.Id];
            if(actvCount > 0 ){
                User up = [SELECT Id from USER WHERE isActive = true AND Profile.Id =: p.Id LIMIT 1];
                System.runAs(up){
                    List<Expected_Payment__c> epayList = [SELECT Id, Booking__c, Booking__r.TECH_Opportunity__r.StageName, Booking__r.AmountPaid__c, Expected_Amount__c, Outstanding_Balance__c, ExpectedPaymentType__c FROM Expected_Payment__c ORDER BY CREATEDDATE LIMIT 50];                       
                    for(Expected_Payment__c inEpay : epayList){
                        inEpay.ExpectedPaymentType__c = ApplicationConstant.EPAYMENTTYPEFULLDEPOSIT;
                    }
                    update epayList;
                    system.assertEquals(50, epayList.size());
                    
                    test.startTest();
                    GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
                    AP16_ExpectedPaymentTriggerBL.updateOpportunityStage(epayList); 
                    test.stopTest();
                    
                    List<Expected_Payment__c> updatedEpay = [SELECT Id, Booking__c, Booking__r.TECH_Opportunity__r.StageName, Booking__r.AmountPaid__c, Expected_Amount__c, Outstanding_Balance__c, ExpectedPaymentType__c FROM Expected_Payment__c ORDER BY CREATEDDATE LIMIT 50];
                    for(Expected_Payment__c ep : updatedEpay){
                        System.assertEquals(ApplicationConstant.PAIDFULLDEPOSITSTAGE, ep.Booking__r.TECH_Opportunity__r.StageName);
                    }
                }
            }//end actvCount            
        }//end profileCount
    }
    
    public static testMethod void tstFullBalance(){
        Integer actvCount = 0;
        Integer profileCount = 0;
        List<String> profileName = new List<String>{ApplicationConstant.PROFILE_GB_SYSADMIN, ApplicationConstant.PROFILE_GB_SYSADMIN };
        profileCount = [SELECT COUNT() FROM Profile WHERE Name IN: profileName];
        if(profileCount > 0){
            Profile p = [SELECT Id FROM Profile WHERE Name IN: profileName LIMIT 1];
            actvCount = [SELECT COUNT() from USER WHERE isActive = true AND Profile.Id =: p.Id];
            if(actvCount > 0 ){
                User up = [SELECT Id from USER WHERE isActive = true AND Profile.Id =: p.Id LIMIT 1];
                System.runAs(up){
                    List<Expected_Payment__c> epayList = [SELECT Id, Booking__c, Booking__r.TECH_Opportunity__r.StageName, Booking__r.AmountPaid__c, Expected_Amount__c, Outstanding_Balance__c, ExpectedPaymentType__c FROM Expected_Payment__c ORDER BY CREATEDDATE LIMIT 50];                       
                    for(Expected_Payment__c inEpay : epayList){
                        inEpay.ExpectedPaymentType__c = ApplicationConstant.EPAYMENTTYPEFULLBALANCE;
                    }
                    update epayList;
                    system.assertEquals(50, epayList.size());
                    
                    test.startTest();
                    GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
                    AP16_ExpectedPaymentTriggerBL.updateOpportunityStage(epayList); 
                    test.stopTest();
                    
                    List<Expected_Payment__c> updatedEpay = [SELECT Id, Booking__c, Booking__r.TECH_Opportunity__r.StageName, Booking__r.AmountPaid__c, Expected_Amount__c, Outstanding_Balance__c, ExpectedPaymentType__c FROM Expected_Payment__c ORDER BY CREATEDDATE LIMIT 50];
                    for(Expected_Payment__c ep : updatedEpay){
                        System.assertEquals(ApplicationConstant.PAIDFULLBALANCESTAGE, ep.Booking__r.TECH_Opportunity__r.StageName);
                    }
                }
            }//end actvCount            
        }//end profileCount
    }
    
    public static testMethod void tstNegativo(){
        Integer actvCount = 0;
        Integer profileCount = 0;
        List<String> profileName = new List<String>{ApplicationConstant.PROFILE_GB_SYSADMIN, ApplicationConstant.PROFILE_GB_SYSADMIN };
        profileCount = [SELECT COUNT() FROM Profile WHERE Name IN: profileName];
        if(profileCount > 0){
            Profile p = [SELECT Id FROM Profile WHERE Name IN: profileName LIMIT 1];
            actvCount = [SELECT COUNT() from USER WHERE isActive = true AND Profile.Id =: p.Id];
            if(actvCount > 0 ){
                User up = [SELECT Id from USER WHERE isActive = true AND Profile.Id =: p.Id LIMIT 1];
                System.runAs(up){
                    List<Opportunity> opptyList = [SELECT Id, StageName, DiaryDate__c, DiaryDateNote__c FROM Opportunity ORDER BY CREATEDDATE LIMIT 50]; 
                    for(Opportunity opp : opptyList){
                        System.assertEquals(Date.today(), opp.DiaryDate__c);
                        opp.DiaryDate__c = Date.today().addDays(30); //OVR_004: The Diary Date has been changed. Please enter a note for Diary Date Note.
                        System.assert(String.isBlank(opp.DiaryDateNote__c));
                    }
                    
                    List<Expected_Payment__c> epayList = [SELECT Id, Booking__c, Booking__r.TECH_Opportunity__r.StageName, Booking__r.AmountPaid__c, Expected_Amount__c, Outstanding_Balance__c, ExpectedPaymentType__c FROM Expected_Payment__c ORDER BY CREATEDDATE LIMIT 50];                       
                    system.assertEquals(50, epayList.size());
                    
                    test.startTest();
                    try{
                        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
                        AP16_ExpectedPaymentTriggerBL.updateOpportunityStage(epayList); 
                    }catch(Exception e){
                        System.assertEquals('The Diary Date has been changed. Please enter a note for Diary Date Note.', e.getMessage());
                    }                   
                    test.stopTest();

                }
            }//end actvCount            
        }//end profileCount
    }
}