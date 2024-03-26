@isTest
public class AP26_EmailMessageTriggerBL_Test{
    @testSetup static void setupTestData() {
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings; 

        //List<MileStoneType> mTypeList =  new List<MileStoneType>();

        //MilestoneType mType = new MilestoneType();
        //mType.Name = 'ABTA Resolution';
        //mType.RecurrenceType = 'none';
        //mTypeList.add(mType);

        //mType = new MilestoneType();
        //mType.Name = 'First Response';
        //mType.RecurrenceType = 'none';
        //mTypeList.add(mType);

        //mType = new MilestoneType();
        //mType.Name = 'Initial Response - ABTA';
        //mType.RecurrenceType = 'none';
        //mTypeList.add(mType);

        //mType = new MilestoneType();
        //mType.Name = 'Resolution Time';
        //mType.RecurrenceType = 'none';
        //mTypeList.add(mType);

        //mType = new MilestoneType();
        //mType.Name = 'Response Time';
        //mType.RecurrenceType = 'none';
        //mTypeList.add(mType);

        //mType = new MilestoneType();
        //mType.Name = 'Promotion Pricing Complete';
        //mType.RecurrenceType = 'none';
        //mTypeList.add(mType);

        //mType = new MilestoneType();
        //mType.Name = 'Promotion Pricing Complete';
        //mType.RecurrenceType = 'none';
        //mTypeList.add(mType);

        //insert mTypeList;
    }

    @isTest
    static void bulikfyTest(){
        Account acc = AP23_TestDataFactory.createAccount(1)[0];
        database.insert(acc);
        Integer cntAcc = [SELECT COUNT() FROM Account];
        System.assertEquals(1, cntAcc);
        
        //create Opportunity
        List<Opportunity> oppList = AP23_TestDataFactory.createOpportunity(1, ApplicationConstant.RECOMMENDATIONSTAGE, acc);
        insert oppList;
        
        //Create Booking
        List<Booking__c> bkList = AP23_TestDataFactory.createBooking(1, acc.Id, oppList[0].Id);
        insert bkList;
        
        //Create Case
        Case cas = AP23_TestDataFactory.createCase(1,acc)[0];
        cas.Booking__c = bkList[0].Id;
        cas.Type = ApplicationConstant.COMPLAINT;
        cas.Origin = ApplicationConstant.CASE_ORIGIN;
        cas.Category__c = ApplicationConstant.COMPLAINT_CATEGORY_ONSITE;
        cas.SubCategory__c =   ApplicationConstant.COMPLAINT_SUBCATEGORY_ONSITE;    
        //cas.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(ApplicationConstant.COMPLAINT).getRecordTypeId();    
        insert cas;
        Integer compCnt = [SELECT COUNT() FROM CASE where recordtype.id =: Schema.SObjectType.Case.getRecordTypeInfosByName().get(ApplicationConstant.COMPLAINT).getRecordTypeId()];
        System.assertEquals(1, compCnt);
        
        //Create Task
        List<Task> tskList = AP23_TestDataFactory.createTask(1, cas);
        database.insert(tskList, false);

        List<EmailMessage> emailMsgList = new List<EmailMessage>();
        //emailMsg.ActivityId = tskList[0].Id;
        for(Integer ctr = 1; ctr<= 2 ; ctr++){
            EmailMessage emailMsg = new EmailMessage();
            emailMsg.FromAddress = ctr + 'testFrom@test.com';
            emailMsg.CcAddress = ctr + 'testCC@test.com';
            emailMsg.FromName = acc.Name;
            emailMsg.ToAddress = acc.PersonEmail;
            emailMsg.Incoming = true;
            emailMsg.ParentId = cas.Id;
            emailMsg.Subject = ApplicationConstant.COMPLAINT;
            emailMsgList.add(emailMsg);
        }

        insert emailMsgList;
        System.assertEquals([SELECT COUNT() FROM EmailMessage], 2);
    }

    @isTest public static void tstBL(){
        List<EmailMessage> newEmailMsgList = new List<EmailMessage>();
        Map<Id,EmailMessage> newEmailMsgMap = new Map<Id,EmailMessage>();

        //Create Account
        Account acc = AP23_TestDataFactory.createAccount(1)[0];
        database.insert(acc);
        Integer cntAcc = [SELECT COUNT() FROM Account];
        System.assertEquals(1, cntAcc);
        
        SlaProcess slaP = [SELECT Id, isActive,StartDateField FROM SlaProcess WHERE Name ='service case & amendment entitlement process'];

        System.debug('$$$$$$$$$$$$$$$$$$$ ' + slaP);

        Entitlement ent = new Entitlement();
        ent.Name = ApplicationConstant.SERVICE_CASE;
        ent.AccountId = acc.id;
        ent.StartDate = Date.today().addDays(-2);
        ent.SlaProcess = slaP;
        insert ent;

        //create Opportunity
        List<Opportunity> oppList = AP23_TestDataFactory.createOpportunity(1, ApplicationConstant.RECOMMENDATIONSTAGE, acc);
        insert oppList;
        
        //Create Booking
        List<Booking__c> bkList = AP23_TestDataFactory.createBooking(1, acc.Id, oppList[0].Id);
        insert bkList;
        
        
        System.debug('^^^^^^^^^^ ' + [SELECT Id, Name, Status FROM Entitlement]);

        //Create Case
        Case cas = AP23_TestDataFactory.createCase(1,acc)[0];
        cas.Booking__c = bkList[0].Id;
        cas.Type = ApplicationConstant.SERVICE_CASE;
        cas.Origin = ApplicationConstant.CASE_ORIGIN;
        cas.Category__c = ApplicationConstant.COMPLAINT_CATEGORY_ONSITE;
        cas.SubCategory__c =   ApplicationConstant.COMPLAINT_SUBCATEGORY_ONSITE;
        cas.RecordTypeId = ApplicationConstant.CASERECTYPEID_SERVICECASE;    
        //cas.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(ApplicationConstant.COMPLAINT).getRecordTypeId();    
        insert cas;

        System.debug('!!!!!!!!!!!!!!!!!!!!! Hello -- ' + [SELECT Id, CompletionDate FROM CaseMilestone]);

        Integer compCnt = [SELECT COUNT() FROM CASE where recordtype.id =: Schema.SObjectType.Case.getRecordTypeInfosByName().get(ApplicationConstant.SERVICE_CASE).getRecordTypeId()];
        System.assertEquals(1, compCnt);
        
        //Create Task
        List<Task> tskList = AP23_TestDataFactory.createTask(1, cas);
        database.insert(tskList, false);
        
        //Complete Case Milestone - Response Time.
        //Get Milestone ID Type:
        //MileStoneType mStone = [SELECT Id FROM MileStoneType WHERE Name =: ApplicationConstant.MILESTONE_RESPONSE_TIME];
        //CaseMilestone caseMilestoneRec = [SELECT Id, CompletionDate FROM CaseMilestone WHERE CaseId =: cas.Id AND MilestoneTypeId =: mStone.Id]; 
        //caseMilestoneRec.CompletionDate = System.today();
        //update caseMilestoneRec;
        
        //Create Email Message
        EmailMessage emailMsg = new EmailMessage();
        //emailMsg.ActivityId = tskList[0].Id;
        emailMsg.FromAddress = 'testFrom@test.com';
        emailMsg.CcAddress = 'testCC@test.com';
        emailMsg.FromName = acc.Name;
        emailMsg.ToAddress = acc.PersonEmail;
        emailMsg.Incoming = true;
        emailMsg.ParentId = cas.Id;
        emailMsg.Subject = ApplicationConstant.COMPLAINT;
        
        
        
        test.startTest();
        insert emailMsg;
        //newEmailMsgMap.put(emailMsg.Id, emailMsg);
        //AP26_EmailMessageTriggerBL.updateCaseMilestone(newEmailMsgMap);
        test.stopTest();
        
        //List<MileStoneType> mtype= [SELECT Id FROM MileStoneType WHERE Name =: ApplicationConstant.MILESTONE_FIRST_RESPONSE OR Name =: ApplicationConstant.MILESTONE_INITIAL_RESPONSE_ABTA];
        //Set<Id> milestoneTypeIdSet = new Set<Id>();
        //for(MileStoneType mm : mtype){
        //    milestoneTypeIdSet.add(mm.Id);
        //}
        //List<CaseMilestone> caseMilestoneRec = [SELECT IsCompleted FROM CaseMilestone WHERE CaseId =: cas.Id AND MilestoneTypeId IN: milestoneTypeIdSet];
        //for(CaseMilestone cs : caseMilestoneRec){
        //    System.assert(cs.IsCompleted);
        //}      
    }
}