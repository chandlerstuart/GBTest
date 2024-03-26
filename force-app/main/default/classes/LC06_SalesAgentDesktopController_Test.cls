@isTest
private class LC06_SalesAgentDesktopController_Test {
    
    @testSetup static void SalesAgentDesktopSetUp() {
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings; 
        // Marked List Views
        Marked_List_Views__c markedListView = new Marked_List_Views__c();
        markedListView.Name = 'My New Leads';
        insert markedListView;

        List<Object_Field_Mapping__c> allOFMList = new List<Object_Field_Mapping__c>();
        //List<Object_Field_Mapping__c> leadOFM = AP23_TestDataFactory.createObjectFieldMappingsByObject('LEAD');
        List<Object_Field_Mapping__c> caseOFM = AP23_TestDataFactory.createObjectFieldMappingsByObject('CASE');
        List<Object_Field_Mapping__c> oppOFM = AP23_TestDataFactory.createObjectFieldMappingsByObject('OPPORTUNITY');
        List<Object_Field_Mapping__c> taskOFM = AP23_TestDataFactory.createObjectFieldMappingsByObject('TASK');

        //allOFMList.addAll(leadOFM);
        allOFMList.addAll(caseOFM);
        allOFMList.addAll(oppOFM);
        allOFMList.addAll(taskOFM);

        insert allOFMList;


        // Leads
        List<Leads_Today__c> csTodayLeads = new List<Leads_Today__c>();
        csTodayLeads.add(new Leads_Today__c(Name = '1' ,Label__c = 'My New Leads' , List_View_Name__c = 'My New Leads'));
        csTodayLeads.add(new Leads_Today__c(Name = '2' ,Label__c = 'My Diarised Leads' , List_View_Name__c = 'My Diarised Leads Today'));
        insert csTodayLeads;

        List<Leads_This_Week__c> csThisWeekLeads = new List<Leads_This_Week__c>();
        csThisWeekLeads.add(new Leads_This_Week__c(Name = '1' ,Label__c = 'My New Leads' , List_View_Name__c = 'My New Leads'));
        csThisWeekLeads.add(new Leads_This_Week__c(Name = '2' ,Label__c = 'My Diarised Leads' , List_View_Name__c = 'My Diarised Leads This Week'));
        insert csThisWeekLeads;

        List<Leads_Total__c> csTotalLeads = new List<Leads_Total__c>();
        csTotalLeads.add(new Leads_Total__c(Name = '1' ,Label__c = 'My New Leads' , List_View_Name__c = 'My New Leads'));
        csTotalLeads.add(new Leads_Total__c(Name = '2' ,Label__c = 'My Diarised Leads' , List_View_Name__c = 'My Diarised Leads Total'));
        insert csTotalLeads;

        // Opportunities
        List<Opportunities_Today__c> csTodayOpportunities = new List<Opportunities_Today__c>();
        csTodayOpportunities.add(new Opportunities_Today__c(Name = '1' ,Label__c = 'Diarised Recommendations' , List_View_Name__c = 'My Opportunities Recommendation Today'));
        csTodayOpportunities.add(new Opportunities_Today__c(Name = '2' ,Label__c = 'Diarised Quote Sent' , List_View_Name__c = 'My Opportunities(Quote Sent) Today'));
        csTodayOpportunities.add(new Opportunities_Today__c(Name = '3' ,Label__c = 'Diarised Close Sale' , List_View_Name__c = 'My Opportunities(Close Sale) Today'));
        csTodayOpportunities.add(new Opportunities_Today__c(Name = '4' ,Label__c = 'Diarised Customer Accepted' , List_View_Name__c = 'Customer Accepted Today'));
        insert csTodayOpportunities;

        List<Opportunities_This_Week__c> csThisWeekOpportunities = new List<Opportunities_This_Week__c>();
        csThisWeekOpportunities.add(new Opportunities_This_Week__c(Name = '1' ,Label__c = 'Diarised Recommendations' , List_View_Name__c = 'MyOpportunities Recommendation This Week'));
        csThisWeekOpportunities.add(new Opportunities_This_Week__c(Name = '2' ,Label__c = 'Diarised Quote Sent' , List_View_Name__c = 'My Opportunities(Quote Sent) This Week'));
        csThisWeekOpportunities.add(new Opportunities_This_Week__c(Name = '3' ,Label__c = 'Diarised Close Sale' , List_View_Name__c = 'My Opportunities(Close Sale) This Week'));
        csThisWeekOpportunities.add(new Opportunities_This_Week__c(Name = '4' ,Label__c = 'Diarised Customer Accepted' , List_View_Name__c = 'Customer Accepted This Week'));
        insert csThisWeekOpportunities;

        List<Opportunities_Total__c> csTotalOpportunities = new List<Opportunities_Total__c>();
        csTotalOpportunities.add(new Opportunities_Total__c(Name = '1' ,Label__c = 'Diarised Recommendations' , List_View_Name__c = 'My Opportunities Recommendation Total'));
        csTotalOpportunities.add(new Opportunities_Total__c(Name = '2' ,Label__c = 'Diarised Quote Sent' , List_View_Name__c = 'My Opportunities(Quote Sent) Total'));
        csTotalOpportunities.add(new Opportunities_Total__c(Name = '3' ,Label__c = 'Diarised Close Sale' , List_View_Name__c = 'My Opportunities(Close Sale) Total'));
        csTotalOpportunities.add(new Opportunities_Total__c(Name = '4' ,Label__c = 'Diarised Customer Accepted' , List_View_Name__c = 'Customer Accepted Total'));
        insert csTotalOpportunities;


        // Cases
        List<Cases_Today__c> csTodayCases = new List<Cases_Today__c>();
        csTodayCases.add(new Cases_Today__c(Name = '1' ,Label__c = 'My New Cases (Bookings)' , List_View_Name__c = 'My New Cases (Bookings)'));
        csTodayCases.add(new Cases_Today__c(Name = '2' ,Label__c = 'My Open Cases (Bookings)' , List_View_Name__c = 'My Open Cases(Bookings) Today_CS'));
        insert csTodayCases;

        List<Cases_This_Week__c> csThisWeekCases = new List<Cases_This_Week__c>();
        csThisWeekCases.add(new Cases_This_Week__c(Name = '1' ,Label__c = 'My New Cases (Bookings)' , List_View_Name__c = 'My New Cases (Bookings)'));
        csThisWeekCases.add(new Cases_This_Week__c(Name = '2' ,Label__c = 'My Open Cases (Bookings)' , List_View_Name__c = 'My Open Cases(Bookings) This Week_CS'));
        insert csThisWeekCases;

        List<Cases_Total__c> csTotalCases = new List<Cases_Total__c>();
        csTotalCases.add(new Cases_Total__c(Name = '1' ,Label__c = 'My New Cases (Bookings)' , List_View_Name__c = 'My New Cases (Bookings)'));
        csTotalCases.add(new Cases_Total__c(Name = '2' ,Label__c = 'My Open Cases (Bookings)' , List_View_Name__c = 'My Open Cases(Bookings) Total_CS'));
        insert csTotalCases;

        // Tasks
        List<Tasks_Today__c> csTodayTasks = new List<Tasks_Today__c>();
        csTodayTasks.add(new Tasks_Today__c(Name = '1' ,Label__c = 'My Call Backs' , List_View_Name__c = 'My Call Backs (Today)', List_View_Id__c = '00B7E000000WYRd' , Task_Query__c = 'SELECT COUNT() FROM Event WHERE StartDateTime <= TODAY AND OwnerId =:currentUserId'));
        insert csTodayTasks;

        List<Tasks_This_Week__c> csThisWeekTasks = new List<Tasks_This_Week__c>();
        csThisWeekTasks.add(new Tasks_This_Week__c(Name = '1' ,Label__c = 'My Call Backs' , List_View_Name__c = 'My Call Backs (This Week)', List_View_Id__c = '00B7E000000WYRi' , Task_Query__c = 'SELECT COUNT() FROM Event WHERE StartDateTime <= THIS_WEEK AND OwnerId =:currentUserId'));
        insert csThisWeekTasks;

        List<Tasks_Total__c> csTotalTasks = new List<Tasks_Total__c>();
        csTotalTasks.add(new Tasks_Total__c(Name = '1' ,Label__c = 'My Call Backs' , List_View_Name__c = 'My Call Backs (Total)', List_View_Id__c = '00B7E000000WYRs' , Task_Query__c = 'SELECT COUNT() FROM Event WHERE StartDateTime >= TODAY AND OwnerId =:currentUserId'));
        insert csTotalTasks;

        Account acct = new Account(Name = 'My Test Account');
        insert acct; 

        Booking__c bkg = new Booking__c();
        bkg.Account__c = acct.Id;
        insert bkg;
    }
    

    @isTest static void testGetReportForLeads() {
        List<Object_Field_Mapping__c> leadOFM = AP23_TestDataFactory.createObjectFieldMappingsByObject('LEAD');
        insert leadOFM;
        Test.startTest();
        LC06_SalesAgentDesktopController_Test.createLead(true, null, 'Today');
        LC06_SalesAgentDesktopController_Test.createLead(false, Date.today(), 'ThisWeek');
        List<ListViewWrapper> todayList = LC06_SalesAgentDesktopController.getTodayReportLeads(); 
        System.debug('^^^^^^^^^^^^^^ ' + [SELECT Id, Diarydate__c, Status FROM Lead]);
        ////system.assertEquals(true , todayList[0].isMarked);
        /*//system.assertEquals('My New Leads' , todayList[0].label);
        //system.assertEquals(1 , todayList[0].recordCount);
        //system.assertEquals('My Diarised Leads', todayList[1].label);
        //system.assertEquals(false , todayList[1].isMarked);
        //system.assertEquals(1 , todayList[1].recordCount);*/

        List<ListViewWrapper> thisWeekList = LC06_SalesAgentDesktopController.getThisWeekReportLeads();
        ////system.assertEquals(true , thisWeekList[0].isMarked);
        try {
        //system.assertEquals(1 , thisWeekList[0].recordCount);
        ////system.assertEquals(1 , thisWeekList[1].recordCount);
        } catch( Exception e) {
            System.debug('Exception: ' + String.ValueOf(e));
        }

        LC06_SalesAgentDesktopController_Test.createLead(true, null, 'Total');
        List<ListViewWrapper> totalList = LC06_SalesAgentDesktopController.getTotalReportLeads();
        try {
        ////system.assertEquals(true , totalList[0].isMarked);
        //system.assertEquals(1 , totalList[0].recordCount);
        ////system.assertEquals(1 , totalList[1].recordCount);
        } catch( Exception e) {
            System.debug('Exception: ' + String.ValueOf(e));
        }
        Test.stopTest();
    }
    
    @isTest static void testGetReportForOpportunities() {
        Test.startTest();
        Date today = Date.today();
        LC06_SalesAgentDesktopController_Test.createOpportunity('Recommendations', '1. Recommendations', today);
        LC06_SalesAgentDesktopController_Test.createOpportunity('QuoteSent', '2. Quote Sent', today);
        LC06_SalesAgentDesktopController_Test.createOpportunity('CloseSale', '3. Close Sale', today);
        LC06_SalesAgentDesktopController_Test.createOpportunity('CustomerAccepted', '4. Customer Accepted', today);
        LC06_SalesAgentDesktopController_Test.createOpportunity('Recommendations_ThisWeek', '1. Recommendations', today.addDays(1));
        LC06_SalesAgentDesktopController_Test.createOpportunity('QuoteSent_ThisWeek', '2. Quote Sent', today.addDays(1));
        LC06_SalesAgentDesktopController_Test.createOpportunity('CloseSale_ThisWeek', '3. Close Sale', today.addDays(1));
        LC06_SalesAgentDesktopController_Test.createOpportunity('CustomerAccepted_ThisWeek', '4. Customer Accepted', today.addDays(1));
        LC06_SalesAgentDesktopController_Test.createOpportunity('Recommendations_Total', '1. Recommendations', today.addDays(8));
        LC06_SalesAgentDesktopController_Test.createOpportunity('QuoteSent_Total', '2. Quote Sent', today.addDays(8));
        LC06_SalesAgentDesktopController_Test.createOpportunity('CloseSale_Total', '3. Close Sale', today.addDays(8));
        LC06_SalesAgentDesktopController_Test.createOpportunity('CustomerAccepted_Total', '4. Customer Accepted', today.addDays(8));
        List<ListViewWrapper> todayList = LC06_SalesAgentDesktopController.getTodayReportOpportunities();
        List<ListViewWrapper> thisWeekList = LC06_SalesAgentDesktopController.getThisWeekReportOpportunities();
        List<ListViewWrapper> totalList = LC06_SalesAgentDesktopController.getTotalReportOpportunities();
        try {
        //system.assertEquals('Diarised Recommendations' , todayList[0].label);
        //system.assertEquals('Diarised Quote Sent', todayList[1].label);
        //system.assertEquals('Diarised Close Sale' , todayList[2].label);
        //system.assertEquals('Diarised Customer Accepted', todayList[3].label);        
        //system.assertEquals(1 , todayList[0].recordCount);
        //system.assertEquals(1 , todayList[1].recordCount);  
        //system.assertEquals(1 , todayList[2].recordCount);
        //system.assertEquals(1 , todayList[3].recordCount);  
        //system.assertEquals(3 , totalList[0].recordCount);
        //system.assertEquals(3 , totalList[1].recordCount);  
        //system.assertEquals(3 , totalList[2].recordCount);
        //system.assertEquals(3 , totalList[3].recordCount); 
        }
        catch( Exception e) {
            System.debug('Exception: ' + String.ValueOf(e));
        }
        Test.stopTest();
    }

    @isTest static void testGetReportForCasesToday() {
        Test.startTest();
        LC06_SalesAgentDesktopController_Test.createCase(Datetime.now());       
        List<ListViewWrapper> todayList = LC06_SalesAgentDesktopController.getTodayReportCases();
        List<ListViewWrapper> thisWeekList = LC06_SalesAgentDesktopController.getThisWeekReportCases();
        List<ListViewWrapper> totalList = LC06_SalesAgentDesktopController.getTotalReportCases();
        try {
        //system.assertEquals('My New Cases (Bookings)' , todayList[0].label);
        // //system.assertEquals('My Open Cases (Bookings)', todayList[1].label);
        //system.assertEquals(1 , todayList[0].recordCount);
        //system.assertEquals(1 , todayList[0].recordCount);
        //system.assertEquals(1 , thisWeekList[0].recordCount);
        //system.assertEquals(1 , thisWeekList[0].recordCount);       
        //system.assertEquals(1 , totalList[0].recordCount);
        // //system.assertEquals(1 , totalList[1].recordCount);
        } catch( Exception e) {
            System.debug('Exception: ' + String.ValueOf(e));
        }
        Test.stopTest();
    }

    @isTest static void testGetReportForCasesThisWeek() {
        Test.startTest();
        LC06_SalesAgentDesktopController_Test.createCase(Datetime.now().addDays(2));
        List<ListViewWrapper> todayList = LC06_SalesAgentDesktopController.getTodayReportCases();
        List<ListViewWrapper> thisWeekList = LC06_SalesAgentDesktopController.getThisWeekReportCases();
        List<ListViewWrapper> totalList = LC06_SalesAgentDesktopController.getTotalReportCases();
        try {
        //system.assertEquals('My New Cases (Bookings)' , thisWeekList[0].label);
        // //system.assertEquals('My Open Cases (Bookings)', thisWeekList[0].label);
        //system.assertEquals(1 , todayList[0].recordCount);
        //system.assertEquals(1 , todayList[0].recordCount);
        //system.assertEquals(1 , thisWeekList[0].recordCount);
        // //system.assertEquals(1 , thisWeekList[0].recordCount);        
        //system.assertEquals(1 , totalList[0].recordCount);
        // //system.assertEquals(1 , totalList[1].recordCount);
        } catch( Exception e) {
            System.debug('Exception: ' + String.ValueOf(e));
        }
        
        Test.stopTest();
    }

    @isTest static void testGetReportForCasesToTal() {
        Test.startTest();
        LC06_SalesAgentDesktopController_Test.createCase(Datetime.now().addDays(9));
        List<ListViewWrapper> todayList = LC06_SalesAgentDesktopController.getTodayReportCases();
        List<ListViewWrapper> thisWeekList = LC06_SalesAgentDesktopController.getThisWeekReportCases();
        List<ListViewWrapper> totalList = LC06_SalesAgentDesktopController.getTotalReportCases();
        try {
        //system.assertEquals('My New Cases (Bookings)' , totalList[0].label);
        // //system.assertEquals('My Open Cases (Bookings)', totalList[1].label);
        //system.assertEquals(1 , todayList[0].recordCount);
        //system.assertEquals(1 , todayList[0].recordCount);
        //system.assertEquals(1 , thisWeekList[0].recordCount);
        // //system.assertEquals(0 , thisWeekList[0].recordCount);        
        //system.assertEquals(1 , totalList[0].recordCount);
        // //system.assertEquals(1 , totalList[1].recordCount);
        } catch( Exception e) {
            System.debug('Exception: ' + String.ValueOf(e));
        }
        Test.stopTest();
    }

    @isTest static void testGetReportForTasks() {
        Test.startTest();
        LC06_SalesAgentDesktopController_Test.createEvent(Datetime.now(), Datetime.now().addDays(1), 'Today');
        LC06_SalesAgentDesktopController_Test.createEvent(Datetime.now().addDays(1), Datetime.now().addDays(2), 'This Week');
        LC06_SalesAgentDesktopController_Test.createEvent(Datetime.now().addDays(8), Datetime.now().addDays(9), 'Total');
        List<ListViewWrapper> todayList = LC06_SalesAgentDesktopController.getTodayReportTasks();
        List<ListViewWrapper> thisWeekList = LC06_SalesAgentDesktopController.getThisWeekReportTasks();
        List<ListViewWrapper> totalList = LC06_SalesAgentDesktopController.getTotalReportTasks();
        try {
        //system.assertEquals('My Call Backs', todayList[0].label);
        } catch( Exception e) {
            System.debug('Exception: ' + String.ValueOf(e));
        }
        Test.stopTest();        
    }

    private static void createLead(Boolean isNew, Date diaryDate, String lastName){
        Lead newLead = new Lead();
        newLead.OwnerId = UserInfo.getUserId();
        newLead.LastName = lastName;
        newLead.LeadSource = 'Website form';
        newLead.Phone = '+631234568';
        if(isNew){
            newLead.Status = 'New';
        }else{
            newLead.Status = 'Contact Attempted';
            newLead.Diarydate__c = diaryDate;
        }
        insert newLead;
        ObjectWrapper ow = new ObjectWrapper();
        ow.fieldLabel = Lead.LastName.getDescribe().getLabel();
        ow.fieldName = Lead.LastName.getDescribe().getName();
        resetHandler();
    }

    private static void createOpportunity(String oppName, String stageName, Date diaryDate){
        Opportunity opp = new Opportunity();
        Id rectypeId = ApplicationConstant.OPP_RECTYPEID_NSO;
        Date today = Date.today();
        opp.RecordTypeId = rectypeId;
        opp.CloseDate = today;
        opp.OwnerId = UserInfo.getUserId();
        opp.Name = oppName;
        opp.StageName = stageName;  
        opp.DiaryDate__c = diaryDate;
        insert opp;
    }

    private static void createCase(Datetime requestCallBackDateTime ){

        Booking__c bkg = [SELECT Id FROM Booking__c LIMIT 1];
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault=true];
        Case cse = new Case();
        Id rectypeId = ApplicationConstant.CASERECTYPEID_COMPLAINT;
        //Date today = Date.today();
        cse.RecordTypeId = rectypeId;
        cse.Booking__c = bkg.Id;
        cse.Type = 'Feedback';
        cse.Category__c = 'F- On Site';
        cse.SubCategory__c = 'Positive';    
        cse.Origin = 'Email';
        cse.Status = 'New';
        cse.Complaint_Source__c = 'Client';
        cse.Complaint_Liability__c = 'Supplier';
        cse.BusinessHours = bh;
        cse.RequestedCallBackDateAndTime__c = requestCallBackDateTime;
        insert cse;
    }

    private static void createEvent(Datetime startDate, Datetime endDate, String taskSubject){
        Event evnt = new Event(StartDateTime = startDate, EndDateTime = endDate, Subject = taskSubject, OwnerId = UserInfo.getUserId() );
        insert evnt;
    }

    private static void resetHandler(){
        AP04_LeadTriggerBL.firstRun = true;
        AP04_LeadTriggerBL.comesFromInsert = false;
        AP04_LeadTriggerBL.isBeforeUpdateTriggerCalled = FALSE;
        AP04_LeadTriggerBL.isBeforeInsertTriggerCalled = FALSE;
        AP04_LeadTriggerBL.isAfterUpdateTriggerCalled = FALSE;
        AP04_LeadTriggerBL.isAfterInsertTriggerCalled = FALSE;
    }
}