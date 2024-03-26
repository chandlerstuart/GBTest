/*
Name:  EmailMessageTriggerTestSuite.cls
Copyright © 2014  CloudMethods
======================================================
======================================================
Purpose:
-------

Test suite for Trigger Handler class EmailMessageTriggerHandler.cls

Coverage for classes below (target 85%):
EmailMessageTriggerHandler.cls : 85%

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2014-05-21  Initial development. 
1.1  Mark Cane&    2015-07-30  Moved bulk tests to EmailMessageTriggerBulkTestSuite.cls.
*/
@isTest(SeeAllData=false)
private class EmailMessageTriggerTestSuite {
    /*
    Test cases:
        singleTestCase1 - processInboundReplyEmailMessages. Case reply received update Last_Inbound_Email_Reply_Date__c field.         
        ..
        negativeTestCase1 - processInboundReplyEmailMessages. First inbound email check Last_Inbound_Email_Reply_Date__c field not populated.        
        ..
    */
    
    /* **/
    static testMethod void singleTestCase1() {
        // Test case 1: Case reply received update Last_Inbound_Email_Reply_Date__c field.
        
        Case c = CaseTestHelper.createSimpleCase();     
        
        EmailMessage em = new EmailMessage();
        em.FromAddress = 'from@unittesting.test';
        em.ToAddress = 'to@unittesting.test';
        em.Incoming = true;
        em.Subject = 'subject text';
        em.TextBody = 'body text';
        em.ParentId = c.Id;
        em.MessageDate = Datetime.now();
        insert em;

        c = [select Id, Last_Inbound_Email_Reply_Date__c from Case where Id=:c.Id];
        System.assert(c.Last_Inbound_Email_Reply_Date__c==null, 'Last Inbound Email Reply Date should not be set');
        
        em = new EmailMessage();
        em.FromAddress = 'from@unittesting.test';
        em.ToAddress = 'to@unittesting.test';
        em.Incoming = true;
        em.Subject = 'reply text';
        em.TextBody = 'reply text';
        em.ParentId = c.Id;
        em.MessageDate = Datetime.now();
        
        Test.startTest();
        insert em;
        Test.stopTest();
        
        c = [select Id, Last_Inbound_Email_Reply_Date__c from Case where Id=:c.Id];
        em = [select Id, MessageDate from EmailMessage where Id=:em.Id];
        System.debug(LoggingLevel.ERROR, 'em :'+em);       
                
        System.assertEquals(em.MessageDate, c.Last_Inbound_Email_Reply_Date__c, 'Last Inbound Email Reply Date should equal the Email Message Date');
    }
    /* */
   
    /* **/
    static testMethod void negativeTestCase1() {
        // Negative test case 1: First inbound email check Last_Inbound_Email_Reply_Date__c field not populated.
        
        Case c = CaseTestHelper.createSimpleCase();     
        
        EmailMessage em = new EmailMessage();
        em.FromAddress = 'from@unittesting.test';
        em.ToAddress = 'to@unittesting.test';
        em.Incoming = true;
        em.Subject = 'subject text';
        em.TextBody = 'body text';
        em.ParentId = c.Id;
        em.MessageDate = Datetime.now();
        
        Test.startTest();
        insert em;
        Test.stopTest();
        
        c = [select Id, Last_Inbound_Email_Reply_Date__c from Case where Id=:c.Id];
        System.assert(c.Last_Inbound_Email_Reply_Date__c==null, 'Last Inbound Email Reply Date should no tbe set');       
    }
    /* */ 
    
	@testSetup static void setup(){  	
        OrgSettings__c orgSettings = OrgSettings__c.getInstance( UserInfo.getOrganizationId() );
        if (!orgSettings.TriggersActive__c){        
        	orgSettings.TriggersActive__c = true;  
        	insert orgSettings;
        }
    }
}