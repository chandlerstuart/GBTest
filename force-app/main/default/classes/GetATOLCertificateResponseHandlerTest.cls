/*
Name:  GetATOLCertificateResponseHandlerTest.cls
======================================================
======================================================
Purpose:
-------
Test Suite for GetATOLCertificateResponseHandler.cls
====================================================== 
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-07-07  Initial development
1.1  J Radcliffe   2023-07-21  Changes to response handling. ATOL certs will now be stored externally with a reference in Salesforce (BookingDocument__c)
*/
@isTest
public with sharing class GetATOLCertificateResponseHandlerTest {

    /*
        testNoFileException - If no file is returned in the http response confirm no email is sent, the failure is logged and booking atol status is updated.
        testSuccessMessage - If all is well, confirm the email is sent, the file is uploaded externally, a reference to the document is created and the booking atol status is updated.
        testUploadFailureMessage - If the file is retrieved, but the external file upload fails, confirm the email is still sent to the customer, but update booking atol status and log failures for the attention of the SF team.
        testDocRefreshSuccess - Confirm newer documents are sent the customer and external database, with the doc reference in SF refreshed.
    */


    public static final String pendingEmailStatus = 'Pending';
    public static final String successEmailStatus = 'Sent';
    public static final String failEmailStatus = 'Failed';
    public static final String uploadFailEmailStatus = 'Upload Failure';//1.1+

    public static final string extRefId = 'ExternalFileRef123';//1.1+

    @TestSetup static void createTestData(){
        
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert acc;

        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, 'Name', acc)[0];
        insert opp;

        Booking__c booking = AP23_TestDataFactory.createBooking(1,acc.Id, opp.Id)[0];
        booking.ATOLCertificateEmailStatus__c = pendingEmailStatus;
        insert booking;
    }

    @isTest static void testNoFileException(){
        
        Id bookingId = [Select Id From Booking__c].Id;

        system.assertEquals(0, [Select Count() From Attachment]); //1.1-

        HttpResponse r = new HttpResponse();//Response with no body

        Integer emailInvocations;
        Test.startTest();
            emailInvocations = Limits.getEmailInvocations();
            system.assertEquals(0, emailInvocations);

            Boolean isSuccessful = GetATOLCertificateResponseHandler.handleOutboundResponse(r, null, null, new Set<Id>{bookingId});

            emailInvocations = Limits.getEmailInvocations();
            system.assertEquals(0, emailInvocations);//No email sent
        Test.stopTest();

        system.assertEquals(false,isSuccessful);//Error reported back to Int Framework

        system.assertEquals(1, [Select Count() From Golfbreaks__PlatformLog__c]);//Failure is logged

        Booking__c booking = [Select Id, Name, ATOLCertificateEmailStatus__c, (Select Id From Booking_Documents__r), (Select Id, Name, ContentType From Attachments) From Booking__c ];
        system.assertEquals(failEmailStatus, booking.ATOLCertificateEmailStatus__c);//Booking Status was updated
        system.assertEquals(0, booking.attachments.size());//No file attachment was created
        system.assertEquals(0, booking.Booking_Documents__r.size());//1.1+
    }

    @isTest static void testSuccessMessage(){

        Id bookingId = [Select Id From Booking__c].Id;

        system.assertEquals(0, [Select Count() From Attachment]);//1.1-
        system.assertEquals(0, [Select Count() From BookingDocument__c]);//1.1+

        HttpResponse r = new HttpResponse();
        r.setBody('FILE DATA');

        Integer emailInvocations;
        Test.startTest();

            //1.1+
            //Custom Mock Callout solution (HttpCalloutMock Interface not supported for packaged callouts)
            ExternalFileUploadManager.isSuccess = true;
            ExternalFileUploadManager.responseBody = '"'+extRefId+'"';    

            emailInvocations = Limits.getEmailInvocations();
            system.assertEquals(0, emailInvocations);

            Boolean isSuccessful = GetATOLCertificateResponseHandler.handleOutboundResponse(r, null, null, new Set<Id>{bookingId});

            emailInvocations = Limits.getEmailInvocations();
            system.assertEquals(1, emailInvocations);//Email was sent
        Test.stopTest();

        system.assertEquals(true,isSuccessful);

        Booking__c booking = [Select Id, Name, ATOLCertificateEmailStatus__c, (Select Id, Name From Booking_Documents__r), (Select Id, Name, ContentType From Attachments) From Booking__c ];
        system.assertEquals(successEmailStatus, booking.ATOLCertificateEmailStatus__c);//Booking Status was updated
        
        system.assertEquals(1, booking.attachments.size());//File was attached to Booking 
        system.assertEquals('ATOL Certificate - '+booking.Name+'.pdf', booking.attachments[0].Name);//File name is correct 
        system.assertEquals('application/pdf', booking.attachments[0].ContentType);//File type is correct 

        //1.1+
        system.assertEquals(1, booking.Booking_Documents__r.size());//1.1+ Booking Document attached to Booking 
        system.assertEquals('ATOL Certificate - '+booking.Name+'.pdf', booking.Booking_Documents__r[0].Name);//File name is correct 
    }

    //1.1+ Test upload failure (failure to upload doc to external system. Confirm the cert is still sent to customer)
    @isTest static void testUploadFailureMessage(){

        Id bookingId = [Select Id From Booking__c].Id;

        system.assertEquals(0, [Select Count() From BookingDocument__c]);

        HttpResponse r = new HttpResponse();
        r.setBody('FILE DATA');

        Integer emailInvocations;
        Test.startTest();

            //Custom Mock Callout solution (HttpCalloutMock Interface not supported for packaged callouts)
            ExternalFileUploadManager.isSuccess = false;
            ExternalFileUploadManager.errorMessage = 'Oop! There was an upload failure';    

            emailInvocations = Limits.getEmailInvocations();
            system.assertEquals(0, emailInvocations);

            Boolean isSuccessful = GetATOLCertificateResponseHandler.handleOutboundResponse(r, null, null, new Set<Id>{bookingId});

            emailInvocations = Limits.getEmailInvocations();
            system.assertEquals(1, emailInvocations);//Confirm the email was sent, despite the upload failure
        Test.stopTest();

        system.assertEquals(true,isSuccessful);//Confirm the response is still reported as success (because the customer is emailed)

        Booking__c booking = [Select Id, Name, ATOLCertificateEmailStatus__c, (Select Id, Name From Booking_Documents__r) /*(Select Id, Name, ContentType From Attachments)*/ From Booking__c ];
        system.assertEquals(uploadFailEmailStatus, booking.ATOLCertificateEmailStatus__c);//Booking Status was updated to Upload Failure

        system.assertEquals(true, [Select Count() From Golfbreaks__PlatformLog__c]>0);//Confirm the failure is logged for attention of SF team.
        
        //1.1+
        system.assertEquals(0, booking.Booking_Documents__r.size());//1.1+ Booking Document is not created (as no external file exists)
    }

    //1.1+
    @isTest static void testDocRefreshSuccess(){

        Booking__c booking = [Select Id, Name From Booking__c];

        system.assertEquals(0, [Select Count() From Attachment]);//1.1-
        system.assertEquals(0, [Select Count() From BookingDocument__c]);//1.1+

        HttpResponse r = new HttpResponse();
        r.setBody('FILE DATA');

        //Create an existing booking doc reference
        BookingDocument__c doc = new BookingDocument__c(Booking__c=booking.Id,FileLocation__c=extRefId,Name='ATOL Certificate - '+booking.Name+'.pdf',Description__c='DescB4Update');//The description should be updated to 'ATOL Certificate' during execution, confirming it has been successfully identified and refreshed.
        insert doc;

        Integer emailInvocations;
        Test.startTest();

            //1.1+
            //Custom Mock Callout solution (HttpCalloutMock Interface not supported for packaged callouts)
            ExternalFileUploadManager.isSuccess = true;
            ExternalFileUploadManager.responseBody = '"'+extRefId+'"';    

            emailInvocations = Limits.getEmailInvocations();
            system.assertEquals(0, emailInvocations);

            Boolean isSuccessful = GetATOLCertificateResponseHandler.handleOutboundResponse(r, null, null, new Set<Id>{booking.Id});

            emailInvocations = Limits.getEmailInvocations();
            system.assertEquals(1, emailInvocations);//Email was sent
        Test.stopTest();

        system.assertEquals(true,isSuccessful);

        Booking__c bookingAfterUpdate = [Select Id, Name, ATOLCertificateEmailStatus__c, (Select Id, Name, Description__c From Booking_Documents__r), (Select Id, Name, ContentType From Attachments) From Booking__c ];
        system.assertEquals(successEmailStatus, bookingAfterUpdate.ATOLCertificateEmailStatus__c);//Booking Status was updated

        system.assertEquals(1, bookingAfterUpdate.attachments.size());//File was attached to Booking 
        system.assertEquals('ATOL Certificate - '+booking.Name+'.pdf', bookingAfterUpdate.attachments[0].Name);//File name is correct 
        system.assertEquals('application/pdf', bookingAfterUpdate.attachments[0].ContentType);//File type is correct 
        
        system.assertEquals(1, bookingAfterUpdate.Booking_Documents__r.size());//1.1+ Only one document attached to Booking (no duplicate doc created)
        system.assertEquals(doc.Id, bookingAfterUpdate.Booking_Documents__r[0].Id);//The expected doc is attached.
        system.assertEquals('ATOL Certificate - '+booking.Name+'.pdf', bookingAfterUpdate.Booking_Documents__r[0].Name);//File remains correct 
        system.assertEquals('ATOL Certificate', bookingAfterUpdate.Booking_Documents__r[0].Description__c);//The file desc has been updated (indicating a refresh has taken place) 
    }

    
    @isTest static void testAttachmentRefresh(){//Update

        system.assertEquals(0, [Select Count() From Attachment]);

        Booking__c testBooking = [Select Id, Name From Booking__c];
        String fileName = 'ATOL Certificate - '+testBooking.Name+'.pdf';

        Attachment att=new Attachment();
        att.parentId=testBooking.Id;
        att.Body=Blob.valueOf('TEST BODY');
        att.ContentType = 'application/pdf';
        att.Name=fileName;
        insert att;

        Attachment att2 = [Select Id, CreatedDate, LastModifiedDate, Body From Attachment];

        HttpResponse r = new HttpResponse();
        r.setBody('FILE DATA');

        Test.startTest();
            //1.1+
            //Custom Mock Callout solution (HttpCalloutMock Interface not supported for packaged callouts)
            ExternalFileUploadManager.isSuccess = true;
            ExternalFileUploadManager.responseBody = '"'+extRefId+'"';    

            Boolean isSuccessful = GetATOLCertificateResponseHandler.handleOutboundResponse(r, null, null, new Set<Id>{testBooking.Id});
        Test.stopTest();

        system.assertEquals(true,isSuccessful);

        Booking__c booking = [Select Id, Name, ATOLCertificateEmailStatus__c, (Select Id, Name, ContentType From Attachments) From Booking__c ];
        system.assertEquals(successEmailStatus, booking.ATOLCertificateEmailStatus__c);//Booking Status was updated
        system.assertEquals(1, booking.attachments.size());//One one file is attached to Booking
        system.assertEquals(att.Id, booking.attachments[0].Id);//Is original file
        system.assertEquals('ATOL Certificate - '+booking.Name+'.pdf', booking.attachments[0].Name);//File name is correct
        system.assertEquals('application/pdf', booking.attachments[0].ContentType);//File type is correct
        system.assertEquals(Blob.valueOf('FILE DATA'), [Select Id, Body From Attachment].body);//Content is updated
    }
    
}