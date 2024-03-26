/*
Name:  IndividualTriggerHandlerTestV2.cls
======================================================
======================================================
Purpose:
-------
Test class for all trigger operations related to the 
'Individual' standard object.

======================================================
======================================================
History
------- 
Ver. Author           Date        Detail
1.0  James Radcliffe  16/04/2018  Initial Development. 
1.1  James Radcliffe  16/05/2018  New Test Method: testRequestQueueCreation
1.2  James Radcliffe  22/10/2019  Remove Redundant Tests
1.3  James Radcliffe  22/10/2019  Bug Fix - Create Unique Accounts (Avoid Dupe Trigger Error)
1.4  James Radcliffe  06/10/2020  Removing Individual Lookup Tests (No Longer Required)
1.5  James Radcliffe  08/03/2023  Amendments to support recent trigger changes. See changes 2.2 on IndividualTriggerHandlerV2. And removed redundant commented code before 1.5
1.6  James Radcliffe  03/04/2023  New Test Method: testUpdateDuplicateIndividualEntities
*/
@isTest
public class IndividualTriggerHandlerTestV2 { 
    
    //Create Test Data
    @testSetup static void createTestData(){
        
        //Make sure we have org settings created
        //Allow the current running test user to insert Client accounts
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings; 
        
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        
        //Create Individual
        Individual ind = new Individual();
        ind.FirstName = 'Test';
        ind.LastName = 'Person';
        insert ind;

        //create test Account using the Test Utility classes
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        acc.PersonIndividualId = ind.Id;
        insert acc;
        
    }
    
    //Test the clearing of Change Reason fields on the Individual records
    @isTest static void clearSubscriptionChangeReasonFields(){
        
        String clientRT = ApplicationConstant.RECORD_TYPE_ACCOUNT_CLIENT;   
        Account acc = [Select Id, LastName From Account Where RecordType.DeveloperName = :clientRT LIMIT 1][0];
        
        String changeReason = 'Change Reason Test';
        //Create Individual
        Individual i = new Individual();
        i.Account__c = acc.Id;
        i.LastName = acc.LastName;
        
        /* 1.5-
        i.Brochure_Change_Reason__c = changeReason;
        i.Phone_Change_Reason__c = changeReason;
        i.SMS_Change_Reason__c = changeReason;
        i.Weekly_Newsletter_Change_Reason__c = changeReason;
        i.Quarterly_Newsletter_Change_Reason__c = changeReason;
        i.PGA_Tour_Change_Reason__c = changeReason;*/

        //1.5+
        i.MarketingSubscriptionChangeReason__c = changeReason;
        
        insert i;
        
        //Requery Individual
        //Individual i2 = [Select Id, Brochure_Change_Reason__c, Phone_Change_Reason__c, SMS_Change_Reason__c, Weekly_Newsletter_Change_Reason__c, Quarterly_Newsletter_Change_Reason__c, PGA_Tour_Change_Reason__c From Individual Where Id = :i.Id][0];//1.5-   
        Individual i2 = [Select Id, MarketingSubscriptionChangeReason__c From Individual Where Id = :i.Id][0];//1.5+    

        //Confirm the Reasons are still set after insert
        /* 1.5-
        system.assertEquals(i2.Brochure_Change_Reason__c, changeReason);
        system.assertEquals(i2.Phone_Change_Reason__c, changeReason);        
        system.assertEquals(i2.SMS_Change_Reason__c, changeReason);
        system.assertEquals(i2.Weekly_Newsletter_Change_Reason__c, changeReason);
        system.assertEquals(i2.Quarterly_Newsletter_Change_Reason__c, changeReason);    
        system.assertEquals(i2.PGA_Tour_Change_Reason__c, changeReason); */  
        //1.5+
        system.assertEquals(i2.MarketingSubscriptionChangeReason__c, changeReason);  

        Set<Id> indsToProcess = new Set<Id>{i2.Id};
            
        test.startTest();
            system.enqueueJob(new IndividualTriggerHandlerV2.PostPreferenceCentreUpdateProcessorClass(null, indsToProcess/*, null, null*/));//1.2~
        test.stopTest();
         
        //Final Query to retrieve Individual record after update
        //Individual i3 = [Select Id, Brochure_Change_Reason__c, Phone_Change_Reason__c, SMS_Change_Reason__c, Weekly_Newsletter_Change_Reason__c, Quarterly_Newsletter_Change_Reason__c, PGA_Tour_Change_Reason__c From Individual Where Id = :i.Id][0];//1.5-
        Individual i3 = [Select Id, MarketingSubscriptionChangeReason__c From Individual Where Id = :i.Id][0];//1.5+

        //Confirm the Reasons have been cleared from the Individual
        /*1.5-
        system.assertEquals(null, i3.Brochure_Change_Reason__c);
        system.assertEquals(null, i3.Phone_Change_Reason__c);        
        system.assertEquals(null, i3.SMS_Change_Reason__c);
        system.assertEquals(null, i3.Weekly_Newsletter_Change_Reason__c);
        system.assertEquals(null, i3.Quarterly_Newsletter_Change_Reason__c);    
        system.assertEquals(null, i3.PGA_Tour_Change_Reason__c);    
        */
        //1.5+
        system.assertEquals(null, i3.MarketingSubscriptionChangeReason__c);    
        
    }    
    
    //BULK test the clearing of Change_Reason__c fields on the Individual records
    @isTest static void clearSubscriptionChangeReasonFieldsBulk(){
        
        String clientRT = ApplicationConstant.RECORD_TYPE_ACCOUNT_CLIENT;   
        Account acc = [Select Id, LastName From Account Where RecordType.DeveloperName = :clientRT LIMIT 1][0];
        system.assertNotEquals(null,acc);
        String changeReason = 'Change Reason Test';
        
        List<Individual> individualsToInsert = new List<Individual>();
        //Create 100 Individuals with Change Reasons
        for(Integer counter=0;counter<100;counter++){
            Individual i = new Individual();
            i.Account__c = acc.Id;
            i.LastName = acc.LastName;
            /*1.5-
            i.Brochure_Change_Reason__c = changeReason;
            i.Phone_Change_Reason__c = changeReason;
            i.SMS_Change_Reason__c = changeReason;
            i.Weekly_Newsletter_Change_Reason__c = changeReason;
            i.Quarterly_Newsletter_Change_Reason__c = changeReason;
            i.PGA_Tour_Change_Reason__c = changeReason;*/
            
            //1.5+
            i.MarketingSubscriptionChangeReason__c = changeReason;   

            individualsToInsert.add(i);
        }
        //Insert testindividuals
        insert individualsToInsert;
        
        //Build set of Individual Ids (after insert)
        Set<Id> indsToUpdateIds = new Set<Id>();
        for(Individual i : individualsToInsert){
            indsToUpdateIds.add(i.Id);
        }
        
        
        
        //Query individuals for update
        //Individual[] inds = [Select Id, Brochure_Change_Reason__c, Phone_Change_Reason__c,  SMS_Change_Reason__c, Weekly_Newsletter_Change_Reason__c, Quarterly_Newsletter_Change_Reason__c, PGA_Tour_Change_Reason__c From Individual Where Id In :indsToUpdateIds];//1.5-
        Individual[] inds = [Select Id, MarketingSubscriptionChangeReason__c From Individual Where Id In :indsToUpdateIds];//1.5+
        
        //Confirm 100 inds have been retrieved
        system.assertEquals(100, inds.size());
        
        for(Individual i : inds){
            //Confirm the reasons are still set after insert
            /*1.5-
            system.assertEquals(changeReason,i.Brochure_Change_Reason__c);
            system.assertEquals(changeReason,i.Phone_Change_Reason__c);        
            system.assertEquals(changeReason,i.SMS_Change_Reason__c);
            system.assertEquals(changeReason,i.Weekly_Newsletter_Change_Reason__c);
            system.assertEquals(changeReason, i.Quarterly_Newsletter_Change_Reason__c);                 
            system.assertEquals(changeReason, i.PGA_Tour_Change_Reason__c);*/                
            
            //1.5+
            system.assertEquals(changeReason, i.MarketingSubscriptionChangeReason__c);                

            //Add Id to indsToUpdateIds Set
            indsToUpdateIds.add(i.Id);
        }
        
        test.startTest();
        //Clear Reason values
        system.enqueueJob(new IndividualTriggerHandlerV2.PostPreferenceCentreUpdateProcessorClass(null, indsToUpdateIds/*, null, null*/));//1.2~
        test.stopTest();
        
        //Requery Individual Records for assertions
        //Individual[] indsAfterUpdate = [Select Id, Brochure_Change_Reason__c, Phone_Change_Reason__c, SMS_Change_Reason__c, Weekly_Newsletter_Change_Reason__c, Quarterly_Newsletter_Change_Reason__c, PGA_Tour_Change_Reason__c From Individual Where Id In:indsToUpdateIds];//1.5-
        Individual[] indsAfterUpdate = [Select Id, MarketingSubscriptionChangeReason__c From Individual Where Id In:indsToUpdateIds];//1.5+

        system.assertEquals(100, inds.size());
        
        for(Individual i : indsAfterUpdate){

            //Confirm the Reasons have been cleared
            /*1.5-
            system.assertEquals(null,i.Brochure_Change_Reason__c);
            system.assertEquals(null,i.Phone_Change_Reason__c);        
            system.assertEquals(null,i.SMS_Change_Reason__c);
            system.assertEquals(null,i.Weekly_Newsletter_Change_Reason__c);
            system.assertEquals(null, i.Quarterly_Newsletter_Change_Reason__c);      
            system.assertEquals(null, i.PGA_Tour_Change_Reason__c);*/     

            //1.5+
            system.assertEquals(null, i.MarketingSubscriptionChangeReason__c);
        }
        
        
    }      
    
    //Test Inserting Change History Records
    @isTest static void InsertChangeHistoryRecordsClassTest(){
        
        //Query Individual Record (implicitly created during test setup)
        //Individual[] allInds = [Select Id, Brochure_Change_Reason__c, Phone_Change_Reason__c, Quarterly_Newsletter_Change_Reason__c, Weekly_Newsletter_Change_Reason__c, SMS_Change_Reason__c, PGA_Tour_Change_Reason__c, Account__c From Individual];//1.5-
        Individual[] allInds = [Select Id, MarketingSubscriptionChangeReason__c, Account__c From Individual];//1.5+

        system.assertEquals(true,allInds.size()>0);
        String reason = 'Change Reason';
        
        //Create Set of Individual Ids & List of Preference Centre Changes to pass into method
        Set<Id> individualIds = new Set<Id>();
        List<Preference_Centre_Change__b> pccs = new List<Preference_Centre_Change__b>();
        
        for(Individual i : allInds){
            /*1.5-
            i.Brochure_Change_Reason__c = reason;
            i.Phone_Change_Reason__c = reason;
            i.Quarterly_Newsletter_Change_Reason__c = reason;
            i.Weekly_Newsletter_Change_Reason__c = reason;
            i.SMS_Change_Reason__c = reason;
            i.PGA_Tour_Change_Reason__c = reason;*/
            i.MarketingSubscriptionChangeReason__c = reason;//1.5+

            individualIds.add(i.Id);       
            //Create Preference Centre Change record (in memory)
            Preference_Centre_Change__b pcc = new Preference_Centre_Change__b();
            pcc.Individual__c = i.Id;
            pcc.Date__c = system.now();
            pcc.Detail__c = 'Test Log Entry';
            pcc.Account__c = i.Account__c;
            pcc.Old_Value__c = null;
            pcc.New_Value__c = 'New Value';
            pcc.Preference__c = 'All';
            pccs.add(pcc);
        }
        
        //Update Individual records (submit change reasons)
        update allInds;
        
        test.startTest();
        System.enqueueJob(new IndividualTriggerHandlerV2.PostPreferenceCentreUpdateProcessorClass(pccs,individualIds/*,null, null*/));//1.2~
        test.stopTest();
        
        //Query back the Individual record/s
        //Individual[] indsAfterUpdate = [Select Id, Brochure_Change_Reason__c, Phone_Change_Reason__c, Quarterly_Newsletter_Change_Reason__c, Weekly_Newsletter_Change_Reason__c, SMS_Change_Reason__c, PGA_Tour_Change_Reason__c, Account__c From Individual Where Id In:individualIds];
        Individual[] indsAfterUpdate = [Select Id, MarketingSubscriptionChangeReason__c, Account__c From Individual Where Id In:individualIds];

        //Assert the Change Reasons have been cleared
        for(Individual i : indsAfterUpdate){
            /*1.5-
            system.assertEquals(null, i.Brochure_Change_Reason__c);
            system.assertEquals(null, i.Phone_Change_Reason__c);
            system.assertEquals(null, i.Quarterly_Newsletter_Change_Reason__c);
            system.assertEquals(null, i.Weekly_Newsletter_Change_Reason__c);
            system.assertEquals(null, i.SMS_Change_Reason__c);            
            system.assertEquals(null, i.PGA_Tour_Change_Reason__c);*/   

            system.assertEquals(null, i.MarketingSubscriptionChangeReason__c);//1.5+
        }
    }   
 

    @isTest static void testUpdateDuplicateIndividualEntities(){

        //Create 5 duplicate Accounts with Individuals
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.DuplicateRuleHeader.AllowSave = true;//Prevent duplicate management from blocking the creation of duplicate accounts
        List<Account> accs = AP23_TestDataFactory.createPersonAccount(5,false);
        AP01_AccountTriggerBL.allowDupes = true;//Prevent account trigger from blocking the creation of duplicate accounts
        Database.insert(accs,dmo);
        AP01_AccountTriggerBL.allowDupes = false;

        Map<Id,Account> accsForUpdateMap = new Map<Id,Account>();
        for(Account acc:accs){
            accsForUpdateMap.put(acc.Id,acc);
        }

        List<Individual> individuals = AP23_TestDataFactory.createIndividuals(accs,true);
        for(Individual ind : individuals){
            system.assertEquals(false, ind.Email__c);
            system.assertEquals(false, ind.Weekly_Newsletter__c);
            accsForUpdateMap.get(ind.Account__c).PersonIndividualId = ind.Id;
        }

        update accsForUpdateMap.values();

        system.assertEquals(0, [Select Count() From Individual Where Email__c = true and Weekly_Newsletter__c = true and Quarterly_Newsletter__c = false]);

        test.startTest();
            //Reset flags
            IndividualTriggerHandlerV2.firstAfterUpdateRun = true;
            IndividualTriggerHandlerV2.isDuplicateUpdate = false;

            //Update the first record
            individuals[0].Email__c = true;
            individuals[0].Weekly_Newsletter__c = true;
            individuals[0].MarketingSubscriptionChangeReason__c = 'Opting In';
            system.debug('starting update');
            update individuals;
            system.debug('stopping update');

            //Confirm all related records were updated as expected.
            system.assertEquals(5, [Select Count() From Individual Where Email__c = true and Weekly_Newsletter__c = true and Quarterly_Newsletter__c = false and Account__c In:accsForUpdateMap.keySet()]);

            //Reset flags
            IndividualTriggerHandlerV2.firstAfterUpdateRun = true;
            IndividualTriggerHandlerV2.isDuplicateUpdate = false;

            //Update the last record
            individuals[4].Weekly_Newsletter__c = false;
            individuals[4].Quarterly_Newsletter__c = true;
            individuals[0].MarketingSubscriptionChangeReason__c = 'Switching';
            update individuals;

            //Confirm the related records have been adjusted correctly
            system.assertEquals(5, [Select Count() From Individual Where Email__c = true and Weekly_Newsletter__c = false and Quarterly_Newsletter__c = true and Account__c In:accsForUpdateMap.keySet()]);
        test.stopTest();

    }
}