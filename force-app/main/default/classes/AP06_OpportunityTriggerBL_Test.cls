/*
Class:  AP06_OpportunityTriggerBL_Test.cls
Copyright © 2018  Golfbreaks
======================================================
======================================================
Purpose:
-------

Test suite for AP06_OpportunityTriggerBL Class

======================================================
======================================================
Revision History
---------------- 
Ver. Author          Date        Detail
1.1  James Radcliffe 2018-11-08  New Test Method - testSetDefaultBusinessUnit - Asserts the default business unit is set when the opportunity is inserted/updated and the BU is null
1.2  Mark Cane&      2018-11-12  Add testSetup block for WIRE calculations on test data.
1.3  James Radcliffe 2019-07-04  New Test Method - testUpdateCustomerCallBackTime
1.4  James Radcliffe 2019-07-04  Comment out redundant methods - IFramework Phase 1
1.5  James Radcliffe 2019-10-17  Comment out redundant methods - IFramework Phase 2
1.6  James Radcliffe 2021-11-02  New Test Method - testQuoteShareIdCalculation
1.7  James Radcliffe 2023-04-04  New Test Method - testFormatOpportunitySignOffParagraph
*/
@isTest
public class AP06_OpportunityTriggerBL_Test{
    @testSetUP static void dataSetUp(){
    
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//<-- 1.2 block WIRE calculations for test data.
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
        
        //Make sure we have org settings created
        //Allow the current running test user to insert Client accounts
        //OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        //insert orgSettings; 
        
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        
        List<Account> accList = AP23_TestDataFactory.createPersonAccount(1);
        insert accList;
        
        List<Opportunity> oppList = AP23_TestDataFactory.createOpportunity(20, ApplicationConstant.RECOMMENDATIONSTAGE, accList[0]);
        for(Opportunity oppty : oppList){
            oppty.RecordTypeId = ApplicationConstant.OPP_RECTYPEID_CONTACTED;
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

        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings; 
               
    }   
        
    @isTest static void testCreateCallbackDateTime(){
    
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
    
        List<Opportunity> oppList = [SELECT Id, DiaryDate__c, StageName, Owner.Id, Reminder_Event__c, Call_Back_Hour__c, Call_Back_Minute__c, RequestedCallbacktimedate__c, RecordTypeId, AccountId FROM Opportunity ORDER BY CreatedDate DESC LIMIT 20];
        System.assertEquals(20, ApplicationConstant.getCount(oppList));
        List<Opportunity> updateList = new List<Opportunity>();
        Set<Id> oppIdSet = new Set<Id>();
        
        for (integer i = 0 ; i < 10 ; i++){
            Opportunity o = oppList[i];
            system.assertEquals(null, o.RequestedCallbacktimedate__c);
            DateTime dtNow = system.now();
            o.Call_Back_Hour__c = '9';//MC 2018-11-12 - fix resticted picklist error - dtNow.addHours(2).hour().format();    
            o.Call_Back_Minute__c = '00';
            updateList.add(o);
            oppIdSet.add(o.Id);
        }
        
        AP06_OpportunityTriggerBL.updateCallbackDateTime(updateList,null);
        update updateList;
        List<Opportunity> checkList = [select Id, RequestedCallbacktimedate__c from Opportunity where Id in :oppIdSet];
        for (Opportunity o : checkList){
            system.assertNotEquals(null, o.RequestedCallbacktimedate__c);
        }
    }
    
    //1.1 - Asserts the default business unit is set when the opportunity is inserted/updated and the BU is null
    @isTest static void testSetDefaultBusinessUnit(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        //Query Opportunity record
        Opportunity updateOpp = [Select Id, RecordTypeId, Golfbreaks_Business_Unit__c, Booking_System__c, StageName, CloseDate, Name From Opportunity Where RecordTypeId =:ApplicationConstant.OPP_RECTYPEID_CONTACTED Limit 1][0];
        //Assert No Business Unit has been set
        system.assertEquals(null, updateOpp.Golfbreaks_Business_Unit__c);
        system.assertEquals(null, updateOpp.Booking_System__c);
        
        //Insert 5 Business Unit records
        List<Golfbreaks_Business_Unit__c> newBusinessUnits = new List<Golfbreaks_Business_Unit__c>();
        for(Integer i = 0;i<5;i++){
            Golfbreaks_Business_Unit__c bu = new Golfbreaks_Business_Unit__c();
            bu.Name = 'Test business unit '+i;
            bu.Default_Booking_System__c = 'Clubhouse';
            bu.IsDefault__c = false;
            bu.DeveloperName__c = 'TestBU'+i+Math.round(Math.random() * 255);
            newBusinessUnits.add(bu);
        }
        Integer randomCount = (Integer)Math.random()*4;
        newBusinessUnits[randomCount].isDefault__c = true;
        insert newBusinessUnits;
        
        //clone and insert a copy of the Opportunity
        Opportunity insertOpp = updateOpp.Clone(false,true,false,false);
        
        test.startTest();
        insert insertOpp;
        AP05_OpportunityTriggerHandler.isBeforeUpdateTriggerCalled = false;
        update updateOpp;
        test.stopTest();
        
        //Confirm the default Business Unit & Booking System has been set for both the updated and inserted Opportunity
        Opportunity[] opps = [Select Id, Golfbreaks_Business_Unit__c, Booking_System__c From Opportunity Where Id = :insertOpp.Id OR Id = :updateOpp.Id];
        system.debug('testSetDefaultBusinessUnit>oppsAfterUpdate:'+opps);
        for(Opportunity o : opps){
            system.assertEquals(newBusinessUnits[randomCount].Id, o.Golfbreaks_Business_Unit__c);
            system.assertEquals(newBusinessUnits[randomCount].Default_Booking_System__c, o.Booking_System__c);
        }
         
    }

    //1.3
    @isTest static void testUpdateCustomerCallBackTime(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
                
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        database.insert(acc,dml);
        
        List<Opportunity> newOpps = AP23_TestDataFactory.createOpportunity(2,'New',acc);
        for (Opportunity opp : newOpps){
            opp.Diarydate__c = Date.today();
        }
        
        DateTime dt1 = DateTime.newInstanceGmt(Date.today().year(), 12, 25, 16, 00, 00); //GMT
        DateTime dt2 = DateTime.newInstanceGmt(Date.today().year(), 6, 1, 10, 00, 00); //BST
        
        newOpps[0].Customer_Call_Back_Date_Time__c = dt1;
        newOpps[1].Customer_Call_Back_Date_Time__c = dt2;
        
        test.startTest();
        insert newOpps;
        test.stopTest();
        
        System.assertEquals('16:00', [select Customer_Call_Back_Time_DST__c from Opportunity where Id=:newOpps[0].Id].Customer_Call_Back_Time_DST__c);
        System.assertEquals('11:00', [select Customer_Call_Back_Time_DST__c from Opportunity where Id=:newOpps[1].Id].Customer_Call_Back_Time_DST__c);
    }  

    //1.6+
    @isTest static void testQuoteShareIdCalculation(){
        
        //Create an Account
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];

        //Create 50 Opportunities
        List<Opportunity> opps = AP23_TestDataFactory.createOpportunity(50,'New', acc);
        for(Integer i=0;i<50;i++){
            opps[i].Name = 'QUOTESHAREID'+i;//Apply a naming convention to help isolate records in subsequent queries
        }
        
        test.startTest();
            AP06_OpportunityTriggerBL.currentDTOverride = DateTime.newInstanceGmt(2021, 09, 13, 14, 42, 00);
            insert opps;

            List<Opportunity> oppsAfterInsert = [Select Id, QuoteShareId__c From Opportunity Where Name LIKE 'QUOTESHAREID%'];
            system.assertEquals(50, oppsAfterInsert.size());
            //Confirm the Ids are calculated correctly
            for(Opportunity opp : oppsAfterInsert){
                system.assertNotEquals(null, opp.QuoteShareId__c);
                String encodedId = EncodingUtil.base64Encode(Blob.valueof(opp.Id)); 
                String expectedKey = 'Q-'+encodedId.substring(0,encodedId.length()/4)+'-015-'+encodedId.substring(encodedId.length()/4,encodedId.length()/2)+'-4202021-'+encodedId.substring(encodedId.length()/2,(encodedId.length()/4)*3)+'-139-'+encodedId.substring((encodedId.length()/4)*3,encodedId.length());
                system.assertEquals(expectedKey,opp.QuoteShareId__c);
                opp.QuoteShareId__c = null;//Clear the values
            }
            //Reset the current time
            AP06_OpportunityTriggerBL.currentDTOverride = DateTime.newInstanceGmt(2021, 10, 18, 21, 49, 00);
            //Reset Trigger State
            AP05_OpportunityTriggerHandler.isBeforeUpdateTriggerCalled = false;
            //Update the Opportunities (clearing the values and forcing a recalculation)
            update oppsAfterInsert;

            List<Opportunity> oppsAfterUpdate = [Select Id, QuoteShareId__c From Opportunity Where Name LIKE 'QUOTESHAREID%'];
            system.assertEquals(50, oppsAfterUpdate.size());
            //Confirm the Ids are recalculated incorporating the NEW D/T (ensuring their uniqueness)
            for(Opportunity opp : oppsAfterUpdate){
                system.assertNotEquals(null, opp.QuoteShareId__c);
                String encodedId = EncodingUtil.base64Encode(Blob.valueof(opp.Id)); 
                String expectedKey = 'Q-'+encodedId.substring(0,encodedId.length()/4)+'-022-'+encodedId.substring(encodedId.length()/4,encodedId.length()/2)+'-4902021-'+encodedId.substring(encodedId.length()/2,(encodedId.length()/4)*3)+'-1810-'+encodedId.substring((encodedId.length()/4)*3,encodedId.length());
                system.assertEquals(expectedKey,opp.QuoteShareId__c);
            }
        test.stopTest();
    }

    //1.7+ Test the Quote Paragraph's are correctly formatted on insert and update
    @isTest static void testFormatOpportunityQuoteParagraphs(){

        //Create 50 Opps
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        List<Opportunity> opps = AP23_TestDataFactory.createOpportunity(50,'New', acc);

        String inputParagraph = 'Hello there,\r\rThis is a paragraph with multiple sentences.\rEach sentence is separated by a line break.\rWhich appears correctly in Salesforce, but is not rendered correctly in an email without suitable HTML tagging.\rPlease help';
        String outputParagraph = '<p>Hello there,</p><p></p><p>This is a paragraph with multiple sentences.</p><p>Each sentence is separated by a line break.</p><p>Which appears correctly in Salesforce, but is not rendered correctly in an email without suitable HTML tagging.</p><p>Please help</p>';

        //Apply sign of paragraph
        for(Opportunity opp : opps){ 
            opp.Signoff_Paragraph__c = inputParagraph;
            opp.EmailIntroductoryText__c = inputParagraph;
        }
        test.startTest();
            GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;

            //Create Opportunities (test insert triggers)
            AP05_OpportunityTriggerHandler.isBeforeInsertTriggerCalled = false;
            insert opps;
             
            //Query and confirm the formatting has been corrected on insert.
            List<Opportunity> oppsAfterInsert = [Select Id, Signoff_Paragraph__c, EmailIntroductoryText__c From Opportunity Where AccountId =:acc.Id];
            system.assertEquals(50, oppsAfterInsert.size());
            for(Opportunity opp : oppsAfterInsert){  
                system.assertEquals(outputParagraph, opp.Signoff_Paragraph__c);
                system.assertEquals(outputParagraph, opp.EmailIntroductoryText__c);

                //Reset the value for update
                opp.Signoff_Paragraph__c = inputParagraph;
                opp.EmailIntroductoryText__c = inputParagraph;
            }

            //Update Opportunities (test update triggers)
            AP05_OpportunityTriggerHandler.isBeforeUpdateTriggerCalled = false;
            system.debug('starting the update!');
            update oppsAfterInsert;
        test.stopTest(); 

        //Query and confirm the formatted has been corrected on update.
        List<Opportunity> oppsAfterUpdate = [Select Id, Signoff_Paragraph__c, EmailIntroductoryText__c From Opportunity Where AccountId =:acc.Id];
        for(Opportunity opp : oppsAfterUpdate){
            system.assertEquals(outputParagraph, opp.Signoff_Paragraph__c);
            system.assertEquals(outputParagraph, opp.EmailIntroductoryText__c);
        }
        
    }

    /* 1.5  @isTest static void tstcheckOppOwnerUpdate(){
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
    
        List<Opportunity> oppList = [SELECT Id, StageName, RequestedCallbacktimedate__c, RecordTypeId, AccountId, OwnerId FROM Opportunity ORDER BY CreatedDate DESC LIMIT 20];
        System.assertEquals(20, ApplicationConstant.getCount(oppList));
               
        Map<Id,Opportunity> oldOppMap = new Map<Id, Opportunity>([SELECT Id, StageName, RequestedCallbacktimedate__c, RecordTypeId, AccountId, OwnerId FROM Opportunity ORDER BY CreatedDate DESC LIMIT 20]);

        Integer usCount = [SELECT COUNT() FROM USER WHERE isActive = true AND UserRole.DeveloperName = :ApplicationConstant.UK_TRANSIENT_SALES_AGENT LIMIT 1];
        if(usCount > 0 ){
            User agnt = [SELECT Id FROM USER WHERE isActive = true AND UserRole.DeveloperName = :ApplicationConstant.UK_TRANSIENT_SALES_AGENT LIMIT 1];   
            for(Opportunity op : oppList)
            {
                 op.OwnerId = agnt.Id;
            }
        }
        test.startTest();
        AP06_OpportunityTriggerBL.checkOppOwnerUpdate(oppList, oldOppMap);
        test.stopTest();
    }*/

    /*1.4
    @isTest static void tstOppIdOnAccount(){
    
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        
        List<Account> accList = [SELECT Id, OppId__c FROM Account ORDER BY CREATEDDATE LIMIT 1];
        System.assertEquals(1, ApplicationConstant.getCount(accList));
        
        List<Opportunity> oppList = [SELECT Id, StageName, RequestedCallbacktimedate__c, RecordTypeId, AccountId FROM Opportunity ORDER BY CreatedDate DESC LIMIT 20];
        System.assertEquals(20, ApplicationConstant.getCount(oppList));
        
        test.startTest();
        AP06_OpportunityTriggerBL.updateOppIdOnAccount(oppList);
        
        List<Account> accListUpdated = [SELECT Id, OppId__c FROM Account ORDER BY CREATEDDATE LIMIT 1];   
        System.assertEquals(oppList[0].Id, accListUpdated[0].OppId__c); //Most Recent Sales Oppty = OppId on Account
        
        //Negative testing
        List<Opportunity> oppList2 = [SELECT Id, StageName, RequestedCallbacktimedate__c, RecordTypeId, AccountId, DiaryDate__c, DiaryDateNote__c FROM Opportunity ORDER BY CreatedDate DESC LIMIT 20];
        System.assertEquals(20, ApplicationConstant.getCount(oppList2));
        for(Opportunity opp: oppList2){
            opp.DiaryDate__c = Date.today().addDays(15);
        }
        try{
            accList[0].Phone = '';
            AP06_OpportunityTriggerBL.updateOppIdOnAccount(oppList2);
        }catch(Exception e){
            //System.assertEquals(expected, e.getMessage());
        }
        test.stopTest();
    }*/
    
    /*1.4
    @isTest static void tstupdateTotalPreviousOpportunitiesOnLead(){   
        
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
    
        List<Account> accList = [SELECT Id, OppId__c FROM Account ORDER BY CREATEDDATE LIMIT 1];
        System.assertEquals(1, ApplicationConstant.getCount(accList));
        
         //create Lead:
        List<Lead> ldList = AP23_TestDataFactory.createLead(20, accList[0].Id);
        insert ldList;
        
        List<Opportunity> oppList = [SELECT Id, StageName, RequestedCallbacktimedate__c, RecordTypeId, AccountId FROM Opportunity ORDER BY CreatedDate DESC LIMIT 20];
        System.assertEquals(20, ApplicationConstant.getCount(oppList));
        
        test.startTest();
        AP06_OpportunityTriggerBL.updateTotalPreviousOpportunitiesOnLead(oppList);
        test.stopTest();
        
        List<Lead> ldProcessUpdated = [SELECT id, Account__c, TotalPreviousOpportunities__c FROM Lead ORDER BY CreatedDate LIMIT 20];
        System.assertEquals(20, ApplicationConstant.getCount(ldProcessUpdated));      
        
        for(Lead ld : ldProcessUpdated){
            System.assertEquals(20, ld.TotalPreviousOpportunities__c);
        }
        
    }*/
    
    /*1.4
    @isTest static void tstcheckStatusUpdates(){
    
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
    
        //Create Sales Agent Attributes
        Sales_Agent_Attributes__c salesRep = new Sales_Agent_Attributes__c();
        RecordType agntRC = [SELECT Id from RecordType where DeveloperName =: ApplicationConstant.USP_SALES_AGENT_DEVNAME];
        salesRep.RecordTypeId =  agntRC.Id;
        Integer usCount = [SELECT COUNT() FROM USER WHERE isActive = true AND UserRole.DeveloperName = :ApplicationConstant.UK_TRANSIENT_SALES_AGENT LIMIT 1];
        if( usCount > 0 ){
            User agnt = [SELECT Id FROM USER WHERE isActive = true AND UserRole.DeveloperName = :ApplicationConstant.UK_TRANSIENT_SALES_AGENT LIMIT 1];
            salesRep.Sales_Rep__c = UserInfo.getUserId();        
            test.startTest();
            insert salesRep;
            
            List<Sales_Agent_Attributes__c> salesRepList = [SELECT Id, Sales_Rep__c, Current_Number_of_Open_Leads_Opps__c, RecordType.Id, RecordType.DeveloperName FROM Sales_Agent_Attributes__c LIMIT 1];
            System.assertEquals(1, salesRepList.size());
            System.assertEquals(ApplicationConstant.USP_SALES_AGENT_DEVNAME, salesRepList[0].RecordType.DeveloperName );
            
            List<Opportunity> oppList = [SELECT Id, IsClosed, StageName, RequestedCallbacktimedate__c, RecordTypeId, AccountId, OwnerId FROM Opportunity ORDER BY CreatedDate DESC LIMIT 20];
            System.assertEquals(20, ApplicationConstant.getCount(oppList));
            for(Integer i=0; i<20; i++){
                oppList[i].StageName = ApplicationConstant.OPP_STAGE_TRIPCOMPLETED;
                oppList[i].OwnerId = UserInfo.getUserId();
            }
            update oppList;
            
            Map<Id,Opportunity> oldOppMap = new Map<Id, Opportunity>([SELECT Id, IsClosed, StageName, RequestedCallbacktimedate__c, RecordTypeId, AccountId, OwnerId FROM Opportunity ORDER BY CreatedDate DESC LIMIT 20]);    
    
            AP06_OpportunityTriggerBL.checkStatusUpdates(oppList, oldOppMap);
            
            test.stopTest();
            
            List<Opportunity> oppListUpdated = [SELECT Id, IsClosed, StageName, RequestedCallbacktimedate__c, RecordTypeId, AccountId, OwnerId FROM Opportunity WHERE StageName =: ApplicationConstant.OPP_STAGE_TRIPCOMPLETED];
            System.assertEquals(20, ApplicationConstant.getCount(oppListUpdated));
            
            for(Opportunity opp : oppListUpdated){
                System.assertEquals(true, opp.IsClosed);
                System.assertEquals(oldOppMap.get(opp.Id).OwnerId, opp.OwnerId);
            }
        }  
    }*/ 
    
   /* @isTest static void tstPopOppDetails(){
        List<Opportunity> oppList = [SELECT Id, IsClosed, StageName, RequestedCallbacktimedate__c, TECH_NVMCallBackUrgent__c, Reminder_Event__c, RecordTypeId, AccountId, OwnerId FROM Opportunity ORDER BY CreatedDate DESC LIMIT 10];
        System.assertEquals(10, ApplicationConstant.getCount(oppList));     
            
        Map<Id,Opportunity> oldOppMap = new Map<Id, Opportunity>([SELECT Id, IsClosed, StageName, RequestedCallbacktimedate__c, TECH_NVMCallBackUrgent__c, Reminder_Event__c, RecordTypeId, AccountId, OwnerId FROM Opportunity ORDER BY CreatedDate DESC LIMIT 11]);        
        for(Opportunity opp : oppList){
            opp.TECH_NVMCallBackUrgent__c = true;
        }   
        update oppList;

        for(Opportunity opp : oppList){
            System.assertEquals(!oldOppMap.get(opp.Id).TECH_NVMCallBackUrgent__c, opp.TECH_NVMCallBackUrgent__c);                                               
        }                                       
        test.startTest();
        AP06_OpportunityTriggerBL.populateOppDetails(oppList, oldOppMap);                                       
                                     
        List<Opportunity> oppListUpdated = [SELECT Id, IsClosed, StageName, RequestedCallbacktimedate__c, TECH_NVMCallBackUrgent__c, Reminder_Event__c, RecordTypeId, AccountId, OwnerId FROM Opportunity ORDER BY CreatedDate DESC LIMIT 10];
        System.assertEquals(10, ApplicationConstant.getCount(oppList));
        for(Opportunity opp : oppListUpdated){
            System.assertEquals(true, opp.Reminder_Event__c);                                          
        }                                    
        
        for(Opportunity opp : oppList){
            opp.TECH_NVMCallBackUrgent__c = false;
            opp.RequestedCallbacktimedate__c = System.today().addDays(9);
        }   
        update oppList;
        
        AP06_OpportunityTriggerBL.populateOppDetails(oppList, oldOppMap);                                     
        test.stopTest(); 
    }*/
    
    /*1.4
    @isTest static void tstupdateMonthlySalesTargetRollup(){
    
       GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
    
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
    }
    */
    
    /*1.4
    @isTest static void tstmapMonthlySalesTargetLookup(){
    
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
    
        List<Opportunity> oppList = [SELECT Id, Owner.Id, IsClosed, StageName, RequestedCallbacktimedate__c, TECH_NVMCallBackUrgent__c, TECH_Monthly_Sales_Target__c,  Reminder_Event__c, CloseDate, RecordTypeId, AccountId, OwnerId FROM Opportunity ORDER BY CreatedDate DESC LIMIT 10];
        System.assertEquals(10, ApplicationConstant.getCount(oppList));  
        
        Map<Id,Opportunity> oldOppMap = new Map<Id, Opportunity>([SELECT Id, Owner.Id, IsClosed, StageName, RequestedCallbacktimedate__c, TECH_NVMCallBackUrgent__c, TECH_Monthly_Sales_Target__c,  Reminder_Event__c, CloseDate, RecordTypeId, AccountId, OwnerId FROM Opportunity ORDER BY CreatedDate DESC LIMIT 11]);
        for(Opportunity opp: oppList)
        {
             opp.CloseDate = Date.today().addDays(-20);
             opp.StageName = ApplicationConstant.OPPORTUNITY_STAGENAME_FULL_DEPOSIT;
        }  
        
        test.startTest();
        AP06_OpportunityTriggerBL.mapMonthlySalesTargetLookup(oppList, oldOppMap);
        test.stopTest();

    }
    */

    /*1.4
    
    @isTest static void tstcreateUpdateEvent(){
    
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
    
        List<Opportunity> oppList = [SELECT Id, StageName, Owner.Id, Reminder_Event__c,  RequestedCallbacktimedate__c, RecordTypeId, AccountId FROM Opportunity ORDER BY CreatedDate DESC LIMIT 20];
        System.assertEquals(20, ApplicationConstant.getCount(oppList));
        
        //Create Event for an oppty:
        Event ev  = new Event();
        oppList[0].RequestedCallbacktimedate__c = System.today();
        ev.OwnerId = oppList[0].OwnerId;
        ev.StartDateTime = oppList[0].RequestedCallbacktimedate__c;
        ev.EndDateTime = oppList[0].RequestedCallbacktimedate__c;
        ev.ReminderDateTime = (oppList[0].RequestedCallbacktimedate__c).addMinutes(-15);
        ev.IsReminderSet = true;
        ev.ActivityDateTime = oppList[0].RequestedCallbacktimedate__c;
        ev.Subject = 'Call Back Request';
        ev.WhatId = oppList[0].id;
        insert ev;
        
        test.startTest();

        Map<Id,Opportunity> oldOppMap = new Map<Id, Opportunity>();
        for(Opportunity opp: oppList)
        {
             opp.Reminder_Event__c = true;
             oldOppMap.put(opp.Id, opp);
        } 
        
        Map<Id,Opportunity> oldOppMapCopy = new Map<Id, Opportunity>([SELECT Id, StageName, Owner.Id, Reminder_Event__c,  RequestedCallbacktimedate__c, RecordTypeId, AccountId FROM Opportunity ORDER BY CreatedDate DESC LIMIT 19]); 
        
        List<Event> evList = [SELECT Id, OwnerId, WhatId, StartDateTime FROM Event];
        System.assertEquals(oppList[0].Id, evList[0].WhatId);
        AP06_OpportunityTriggerBL.createUpdateEvent(oldOppMap, oldOppMapCopy);
        test.stopTest();
    }*/

}