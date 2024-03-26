/*
Name:  ApplicationConstant_Test.cls
======================================================
======================================================
Purpose:
-------
Test class for ApplicationConstant.cls

======================================================
======================================================
History
------- 
Ver. Author          Date        Detail
1.0  Abrar Haq       2016-03-03  Initial development.
1.1  Simon Molloy    2017-09-06  New test method for getOrgWideEmailAddressByName
1.2  Simon Molloy    2017-10-20  New test method for getDeleteLogs method
*/
@isTest
private class ApplicationConstant_Test {

    static final Map<String, Id> campaignRecordTypes;
    
    static{
        campaignRecordTypes = new Map<String, Id>();
        for(RecordType recType : [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Campaign']){
            campaignRecordTypes.put(recType.DeveloperName, recType.Id);
        }
    }

    @testSetup
    static void dataSetup() {

        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;

        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert acc;
        
        //Contact con = AP23_TestDataFactory.createContactList(1, acc)[0];
        //insert con;
        
        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, '1. Recommendations', acc)[0];
        insert opp;
        
        Booking__c book = AP23_TestDataFactory.createBooking(1, acc.Id, opp.Id)[0];
        book.AmountPaid__c = 5000;
        book.TransferDetailsRequired__c = true;
        book.RoomingListRequired__c = true;
        insert book;

        List<Lead> lead = AP23_TestDataFactory.createLead(1);
        insert lead;

        //Create Marketing  Strategy
        List<MarketingStrategy__c> lMS = AP23_TestDataFactory.createMarketingStrategy(200);
        insert lMS;

        Object_Field_Mapping__c ofm = new Object_Field_Mapping__c(Name = '001', Field_API_Name__c = 'Name', Object_API_Name__c = 'Booking__c');
        insert ofm;

        //Create campaign
        List<Campaign> lChildCamp = AP23_TestDataFactory.createCampaign(1, lMS[0].Id);
        for(Campaign campaign : lChildCamp){
            campaign.RecordTypeId = campaignRecordTypes.get(ApplicationConstant.CAMPAIGN_MARKETING_CAMPAIGN_EVENT);
            campaign.Type = 'Email';
            campaign.MarketingStrategy__c = null;
            campaign.Forecasted_Cost__c = 20000;
            campaign.Actual_Cost__c = 10000;
        }
        insert lChildCamp;

        //Insert Error Log Settings custom setting
        List<Error_Log_Setting__c> elsList = new List<Error_Log_Setting__c>();
        for (integer i = 0 ; i < 5 ; i++){
            Error_Log_Setting__c els = new Error_Log_Setting__c();
            els.Enabled__c = true;
            elsList.add(els);
        }
        elsList[0].Name = 'DML Error';
        elsList[1].Name = 'Error';
        elsList[2].Name = 'Exception';
        elsList[3].Name = 'Information';
        elsList[4].Name = 'Warning';

        insert elsList;
        
        Error_Log__c err = new Error_Log__c();
        insert err;
    }

    @isTest
    static void testFormatPhone(){
      String correctPhone = '+447966111111';
      String incorrectPhone = '44 07966222222';
      String incorrectPhoneFixed = '+447966222222';
      String errorPhone = 'ex.123456';

      system.assertEquals(correctPhone, ApplicationConstant.formatPhone(correctPhone));
      system.assertEquals(incorrectPhoneFixed, ApplicationConstant.formatPhone(incorrectPhone));
      system.assertEquals(errorPhone, ApplicationConstant.formatPhone(errorPhone));

    }

    @isTest
    static void testDeleteLogs(){
      List<Account> delAccounts = AP23_TestDataFactory.createPersonAccount(1,true); 
      insert delAccounts;

      List<Database.DeleteResult> delList = Database.delete(delAccounts);
      List<Error_Log__c> logs = ApplicationConstant.getDeleteResultLog(delList,'deleteAccount', 'ApplicationConstant','Account', 'delete');

    }

    @isTest 
    static void tstMthod(){
      Date tstDate;
      Date d;
      System.assertEquals('Request_Queue__c', ApplicationConstant.OBJECT_TYPE_REQUEST_QUEUE);
      System.assertEquals('Account', ApplicationConstant.OBJECT_TYPE_ACCOUNT);

      // Request Queue objects
      String x = ApplicationConstant.REQUEST_QUEUE_STATUS_WAITING;
      System.assertEquals('Retrying', ApplicationConstant.REQUEST_QUEUE_STATUS_RETRYING);
      System.assertEquals('Failed', ApplicationConstant.REQUEST_QUEUE_STATUS_FAILED);
      System.assertEquals('Success', ApplicationConstant.REQUEST_QUEUE_STATUS_SUCCESS);

      Test.startTest();

      d = Date.today();
      String yr = d.year().format().replace(',','');
      String mt = d.month().format();
      String dy = d.day().format();

      tstDate = ApplicationConstant.setStringToDateFormat(yr + '-' + mt + '-' + dy);

      List<Lead> lead = [SELECT Id from Lead LIMIT 1];

      ApplicationConstant.getLead(lead[0].id);
      ApplicationConstant.getRecordTypeId('Account', 'Client');
      ApplicationConstant.getRequestQueueObjectPriority();
      ApplicationConstant.getObjectFields('Booking__c'); 
      List<MarketingStrategy__c> mkt = [SELECT ID, Name from MarketingStrategy__c]; 
      Integer gtCount = ApplicationConstant.getCount(mkt);
      List<Database.SaveResult> sv = Database.update(mkt);
      ApplicationConstant.getSaveCount(sv);
      List<Database.Error> errList = sv[0].getErrors();
      ApplicationConstant.getErrorCount(errList);  
      ApplicationConstant.deleteOldLogs();
      //2017-01-30 : SM : getDMLLog is no longer public, accessed via getSaveResultLog instead
      //ApplicationConstant.getDMLLog(sv[0], 'OnBeforeUpdate', 'AP04_LeadTriggerBL', 'Lead', 'update');        
      ApplicationConstant.getSaveResultLog(sv, 'OnBeforeUpdate', 'AP04_LeadTriggerBL', 'Lead', 'update');    
      //Test call to getDMLLog
      List<Lead> leadList = new List<Lead>();
      leadList.add(new Lead(FirstName = 'FAIL'));
      leadList.add(new Lead(LastName = 'SUCCESS'));
      List<Database.SaveResult> srList = Database.insert(leadList,false);
      ApplicationConstant.getSaveResultLog(srList, 'OnBeforeInsert', 'AP04_LeadTriggerBL', 'Lead', 'insert');

        try{
            List<Lead> ldlist = [SELECT ID FROM LEAD LIMIT 1];
            //this is an error since we did not query column: Rating
            String theRating = ldlist[0].Rating;
        }catch(Exception e){
            ApplicationConstant.getExceptionLog(e, 'OnBeforeUpdate', 'AP04_LeadTriggerBL', 'Lead');    
            ApplicationConstant.getErrorCount(errList);
        }

      List<OrgWideEmailAddress> orgWideEmailAddresses = ApplicationConstant.getOrgWideEmailAddressByName('Salesforce Support');
      system.assertNotEquals(true, orgWideEmailAddresses.isEmpty());

      Test.stopTest();
      System.assertEquals(200, gtCount);
      System.assertEquals(tstDate, d);
    }
}