@isTest
private class VFC04_LeadLeftPanelController_Test {
    @isTest static void testSummaryReport() {
        Test.startTest();
        VFC04_LeadLeftPanelController_Test.createLead(true, null, 'Test');
        VFC04_LeadLeftPanelController_Test.createOpportunity('Recommendations', ApplicationConstant.RECOMMENDATIONSTAGE, Date.today());
        VFC04_LeadLeftPanelController_Test.createCase(Datetime.now());
        VFC04_LeadLeftPanelController_Test.createTask(Datetime.now(), Datetime.now().addDays(1), 'Today');
        VFC04_LeadLeftPanelController ctr = new VFC04_LeadLeftPanelController();
        List<VFC04_LeadLeftPanelController.SummaryReportWrapper> wrap = new List<VFC04_LeadLeftPanelController.SummaryReportWrapper>();
        wrap = ctr.listSummaryReport;
        System.assertEquals('Leads', wrap[0].objectName);
        System.assertEquals('Opportunities', wrap[1].objectName);
        System.assertEquals('Cases', wrap[2].objectName);
        System.assertEquals('Tasks', wrap[3].objectName);
        System.assertEquals(1, wrap[0].totalOpenRecords);
        System.assertEquals(1, wrap[1].totalOpenRecords);
        System.assertEquals(1, wrap[2].totalOpenRecords);
        System.assertEquals(1, wrap[3].totalOpenRecords);
        Test.stopTest();
    }

    private static void createLead(Boolean isNew, Date diaryDate, String lastName){
        Lead newLead = new Lead();
        newLead.OwnerId = UserInfo.getUserId();
        newLead.LastName = lastName;
        newLead.LeadSource = 'Website form';
        newLead.Phone = '+631234568';
        if(isNew){
            newLead.Status = ApplicationConstant.LEAD_STATUS_NEW;
        }else{
            newLead.Status = 'Meeting Booked';
            newLead.Diarydate__c = diaryDate;
        }
        insert newLead;
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
        Account acct = new Account(Name = 'My Test Account');
        insert acct; 
        Booking__c bkg = new Booking__c();
        bkg.Account__c = acct.Id;
        insert bkg;
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault=true];
        Case cse = new Case();
        Id rectypeId = ApplicationConstant.CASERECTYPEID_COMPLAINT;
        //Date today = Date.today();
        cse.RecordTypeId = rectypeId;
        cse.Booking__c = bkg.Id;
        cse.Type = ApplicationConstant.CASE_FEEDBACK;
        cse.Category__c = ApplicationConstant.CASE_CATEG_FONSITE;
        cse.SubCategory__c = ApplicationConstant.CASE_SUBCATEG_POS;    
        cse.Origin = ApplicationConstant.CASE_ORIGIN;
        cse.Status = ApplicationConstant.CASE_STATUS_NEW;
        cse.Complaint_Source__c = ApplicationConstant.CASE_COMPSOURCE_CLIENT;
        cse.Complaint_Liability__c = ApplicationConstant.CASE_COMPLIABILITY_SUPPLIER;
        cse.BusinessHours = bh;
        cse.RequestedCallBackDateAndTime__c = requestCallBackDateTime;
        insert cse;
    }

    private static void createTask(Datetime startDate, Datetime endDate, String taskSubject){
        Task tsk = new Task(Status = ApplicationConstant.TASK_STAT_INPROGRESS, Priority = ApplicationConstant.TASKPRIORITY_NORMAL, OwnerId = UserInfo.getUserId() );
        insert tsk;
    }
}