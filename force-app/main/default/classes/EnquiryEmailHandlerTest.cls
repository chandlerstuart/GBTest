/*
Name: EnquiryEmailHandlerTest.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Test suite for Enquiry Email Handler functions.

Coverage for classes below (target 85%):
EnquiryEmailHandler.cls : 85%	

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-09-16  Initial development.
1.1  Mark Cane&    2019-09-22  Added singleTestCase2+negativeTestCase1.
*/
@isTest(SeeAllData=false)
public with sharing class EnquiryEmailHandlerTest {
	/*
    Test cases:
        singleTestCase1 - ApexEmailService. Create new Enquiry. Operational Email Reply.
        singleTestCase2 - ApexEmailService. Create new Enquiry. Action Type mapping from To Address and Key Prefix.
        ..
        negativeTestCase1 - ApexEmailService. No Action Type mapping.
	*/
	
    @testSetup static void setup(){

        Account a = new Account(FirstName='Acme',LastName='Account');
        insert a;

        Case c = new Case();
        c.Subject = 'Test';
        c.Description = 'Test';
        c.Type = null;
        c.Status = 'New';
        c.AccountId = a.id;
        insert c;
    }
    
    /* **/
    static testMethod void singleTestCase1() {
        // Test case 1 : ApexEmailService. Create new Enquiry. Operational Email Reply.

        Id clientId = [select Id from Account where FirstName='Acme'].Id;

        Id relatedRecordId = [select Id from Case where Subject='Test'].Id;//<--in practice this would be Opportunity or Booking.


        Test.setMock(HttpCalloutMock.class, new ClubhouseClientResponseMockImpl());

        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
       
        email.fromAddress = 'jim.smith@email.com';
        email.fromName = 'Jim Smith';
        email.plainTextBody = 'email body\n2225256325\nTitle\n{transactionId:'+relatedRecordId+',clientId:'+clientId+',actionType:TestOppEmailAction}\nregistered office';
        email.plainTextBodyIsTruncated=false;        
        email.subject = 'Operational Email Reply';
        email.toAddresses = new List<String>{ 'hello2@unittesting.golfbreaks.com' };//<-- no mapping to ActionType on To Address.
      
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfileone.txt';
        attachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };    

        Messaging.InboundEmail.TextAttachment attachmenttext = new Messaging.InboundEmail.TextAttachment();
        attachmenttext.body = 'my attachment text';
        attachmenttext.fileName = 'textfiletwo.txt';
        attachmenttext.mimeTypeSubType = 'text/plain';
        email.textAttachments =  new Messaging.inboundEmail.TextAttachment[] { attachmenttext };

        EnquiryEmailHandler h = new EnquiryEmailHandler();

        Test.startTest();
        Messaging.InboundEmailResult emailResult = h.handleInboundEmail(email, env);
        Test.stopTest();

        System.assert(emailResult.success);
        System.assertEquals(1,[select count() from Opportunity where Name=:email.subject]);
        System.assertEquals(2,[select count() from Attachment]);
  	}
    /* */ 

    /* **/
    static testMethod void singleTestCase2() {
        // Test case 2 : ApexEmailService. Create new Enquiry. Action Type mapping from To Address and Key Prefix.

        Id clientId = [select Id from Account where FirstName='Acme'].Id;

        Id relatedRecordId = [select Id from Case where Subject='Test'].Id;//<--in practice this would be Opportunity or Booking.


        Test.setMock(HttpCalloutMock.class, new ClubhouseClientResponseMockImpl());

        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
       
        email.fromAddress = 'jim.smith@email.com';
        email.fromName = 'Jim Smith';
        email.plainTextBody = 'email body\n2225256325\nTitle\nregistered office';//<-- no embedded metadata.
        email.plainTextBodyIsTruncated=false;
        email.subject = 'Operational Email Reply';
        email.toAddresses = new List<String>{ 'hello@unittesting.golfbreaks.com' };//<-- maps to Action Type [To Address] field.
      
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfileone.txt';
        attachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };    

        Messaging.InboundEmail.TextAttachment attachmenttext = new Messaging.InboundEmail.TextAttachment();
        attachmenttext.body = 'my attachment text';
        attachmenttext.fileName = 'textfiletwo.txt';
        attachmenttext.mimeTypeSubType = 'text/plain';
        email.textAttachments =  new Messaging.inboundEmail.TextAttachment[] { attachmenttext };

        EnquiryEmailHandler h = new EnquiryEmailHandler();

        Test.startTest();
        Messaging.InboundEmailResult emailResult = h.handleInboundEmail(email, env);
        Test.stopTest();

        System.assert(emailResult.success);
        System.assertEquals(1,[select count() from Opportunity where Name=:email.subject]);
        System.assertEquals(2,[select count() from Attachment]);
  	}
    /* */ 

    /* **/
    static testMethod void negativeTestCase1() {
        // Test case 1 : ApexEmailService. No Action Type mapping.

        Id clientId = [select Id from Account where FirstName='Acme'].Id;

        Id relatedRecordId = [select Id from Case where Subject='Test'].Id;//<--in practice this would be Opportunity or Booking.


        Test.setMock(HttpCalloutMock.class, new ClubhouseClientResponseMockImpl());

        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
       
        email.fromAddress = 'jim.smith@email.com';
        email.fromName = 'Jim Smith';
        email.plainTextBody = 'email body\n2225256325\nTitle\nregistered office';//<-- no embedded metadata.
        email.plainTextBodyIsTruncated=false;        
        email.subject = 'Operational Email Reply';
        email.toAddresses = new List<String>{ 'hello2@unittesting.golfbreaks.com' };//<-- no mapping to ActionType on To Address.
      
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfileone.txt';
        attachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };    

        Messaging.InboundEmail.TextAttachment attachmenttext = new Messaging.InboundEmail.TextAttachment();
        attachmenttext.body = 'my attachment text';
        attachmenttext.fileName = 'textfiletwo.txt';
        attachmenttext.mimeTypeSubType = 'text/plain';
        email.textAttachments =  new Messaging.inboundEmail.TextAttachment[] { attachmenttext };

        EnquiryEmailHandler h = new EnquiryEmailHandler();

        Test.startTest();
        Messaging.InboundEmailResult emailResult = h.handleInboundEmail(email, env);
        Test.stopTest();

        System.assert(!emailResult.success);
        System.assertEquals(0,[select count() from Opportunity where Name=:email.subject]);
        System.assertEquals(0,[select count() from Attachment]);
  	}
    /* */

    public class ClubhouseClientResponseMockImpl implements HttpCalloutMock {

        private String responseBody;
        private Integer responseStatusCode;

        public ClubhouseClientResponseMockImpl(){
            responseBody='{ "GolfbreaksEnquiryID":"ClubhouseIdValue", "SalesforceClientID":"001b000000qDVy6AAZ", "GolfbreaksClientID":"ClubhouseIdValue" }';
            responseStatusCode=200;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            res.setStatusCode(responseStatusCode);
            return res;
        }
    }        
}