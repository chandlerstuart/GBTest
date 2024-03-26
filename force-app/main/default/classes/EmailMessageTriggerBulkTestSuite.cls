/*
Name: EmailMessageTriggerBulkTestSuite.cls
Copyright © 2015  CloudMethods
======================================================
======================================================
Purpose:
-------

Bulk Test suite for Trigger Handler class EmailMessageTriggerHandler.cls

Coverage for classes below (target 85%):
EmailMessageTriggerHandler.cls :85%

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2015-07-30  Initial development.
*/
@isTest(SeeAllData=false)
public with sharing class EmailMessageTriggerBulkTestSuite {
	private static Integer REC_COUNT = 200;
	
	/*
    Test cases:	
        ..        
        bulkTestCase1 - Bulk test of processInboundReplyEmailMessages logic.
        ..
    */
    
 	/* **/
    static testMethod void bulkTestCase1() {
        // Bulk test case 1: Bulk test of processInboundReplyEmailMessages logic.
        
        List<Case> casesToInsert = new List<Case>();
        List<EmailMessage> emailMessagesToInsert = new List<EmailMessage>();
        EmailMessage em;
                
        for (Integer i=0; i<REC_COUNT; i++){
        	casesToInsert.add(CaseTestHelper.createSimpleCase(false));
        }
        insert casesToInsert;
        
        //Initial email.
        for (Case c : casesToInsert){
        	em = new EmailMessage();
	        em.FromAddress = 'from@unittesting.test';
	        em.ToAddress = 'to@unittesting.test';
	        em.Incoming = true;
	        em.Subject = 'subject text';
	        em.TextBody = 'body text';
	        em.ParentId = c.Id;
	        em.MessageDate = Datetime.now();        	
        	
        	emailMessagesToInsert.add(em);
        }
        insert emailMessagesToInsert;
        
        for (Case c : [select Id, Last_Inbound_Email_Reply_Date__c from Case where Id in:casesToInsert]){
        	System.assert(c.Last_Inbound_Email_Reply_Date__c==null, 'Last Inbound Email Reply Date should not be set');
        }        
        

        //Reply email.
        emailMessagesToInsert = new List<EmailMessage>();
        for (Case c : casesToInsert){
        	em = new EmailMessage();
	        em.FromAddress = 'from@unittesting.test';
	        em.ToAddress = 'to@unittesting.test';
	        em.Incoming = true;
	        em.Subject = 'reply text';
	        em.TextBody = 'reply body';
	        em.ParentId = c.Id;
	        em.MessageDate = Datetime.now();        	
        	
        	emailMessagesToInsert.add(em);
        }
		
        Test.startTest();
        insert emailMessagesToInsert;
        Test.stopTest();
        
        for (Case c : [select Id, Last_Inbound_Email_Reply_Date__c from Case where Id in:casesToInsert]){
        	System.assert(c.Last_Inbound_Email_Reply_Date__c!=null, 'Last Inbound Email Reply Date should be set');
        }
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