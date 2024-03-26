/*
Name:  ExternalFileUploaderControllerTest.cls
======================================================
======================================================
Purpose:
Test Suite for External File Upload activity for enables users
to upload files (related to a Booking/Guest) to an external source. External 
files are accessible to customer via the portal. 
-------

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2023-07-13  Initial development.
*/
@isTest
public with sharing class ExternalFileUploaderControllerTest {

    public static final string extRefId = 'ExternalFileRef123';
    public static final string testFileName = 'Test_File.txt';
    public static final string testFileDescription = 'Test File Description';

    @testSetup static void testSetup(){
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert acc;
        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, 'New', acc)[0];
        insert opp;
        Booking__c booking = AP23_TestDataFactory.createBooking(1, acc, opp.Id)[0]; 
        insert booking;

        ContentVersion testContentVersion = new ContentVersion(
            VersionData = Blob.valueOf('Test file content'),
            Title='TestDoc',
            PathOnClient='TestDoc.pdf'
        );
        insert testContentVersion;

        //Assign permission to running user
        PermissionSet ps = [Select Id From PermissionSet Where Name = 'Upload_External_Files'];
        User runningUser = [Select Id, (Select Id From PermissionSetAssignments Where PermissionSet.Id =:ps.Id) From User Where Id = :UserInfo.getUserId()][0];   
        if(runningUser.PermissionSetAssignments.size()==0){
            System.runAs(runningUser){
                insert new PermissionSetAssignment(AssigneeId=UserInfo.getUserId(),PermissionSetId=ps.Id);
            }
        }
    }

    //Test uploading a new file - success response from api
    @isTest
    static void testUploadFile_Success() {

        Booking__c booking = [Select Id From Booking__c]; 

        ContentVersion testContentVersion = [Select Id, ContentDocumentId From ContentVersion];

        Test.startTest();
            
            //Custom Mock Callout solution (HttpCalloutMock Interface not supported for packaged callouts)
            ExternalFileUploadManager.isSuccess = true;
            ExternalFileUploadManager.responseBody = '"'+extRefId+'"';

            String error = ExternalFileUploaderController.uploadFile(
                testContentVersion.ContentDocumentId,
                testContentVersion.Id,
                booking.Id,
                testFileName,
                testFileDescription
        );
        Test.stopTest();

        //Assertions

        //No error returned to lwc
        system.assertEquals(null, error);
        
        //Booking ref logged with correct details
        BookingDocument__c bookingDoc = [Select Id, FileLocation__c, FileExtension__c, Booking__c, Name, Description__c From BookingDocument__c];
        system.assertEquals(testFileName, bookingDoc.Name);
        system.assertEquals(testFileDescription, bookingDoc.Description__c);
        system.assertEquals(extRefId, bookingDoc.FileLocation__c);
        system.assertEquals(booking.Id, bookingDoc.Booking__c);
        system.assertEquals('pdf', bookingDoc.FileExtension__c);

        //Original file was removed from Salesforce
        system.assertEquals(0, [Select Count() From ContentVersion]);

    }

    //Test updating an existing file - success response from api
    @isTest
    static void testUpdateFile_Success() {

        Booking__c booking = [Select Id From Booking__c]; 

        ContentVersion testContentVersion = [Select Id, FileExtension, ContentDocumentId From ContentVersion];
        
        BookingDocument__c bDoc = new BookingDocument__c(
            FileLocation__c=extRefId,
            Booking__c=booking.Id,
            Name=testFileName,
            Description__c=testFileDescription,
            FileExtension__c=testContentVersion.FileExtension
        );
        insert bDoc;

        Test.startTest();
            
            //Custom Mock Callout solution (HttpCalloutMock Interface not supported for packaged callouts)
            ExternalFileUploadManager.isSuccess = true;
            ExternalFileUploadManager.responseBody = '"'+extRefId+'"';

            String error = ExternalFileUploaderController.uploadFile(
                testContentVersion.ContentDocumentId,
                testContentVersion.Id,
                bDoc.Id,//Pass bDoc Id for update
                'New Name',
                null//Ignore desc
        );
        Test.stopTest();

        //Assertions

        //No error returned to lwc
        system.assertEquals(null, error);
        
        //Booking ref logged with correct details (incl new name and desc)
        BookingDocument__c bookingDoc = [Select Id, FileLocation__c, FileExtension__c, Booking__c, Name, Description__c From BookingDocument__c];
        system.assertEquals(testFileName, bookingDoc.Name);//Confirm the name hasn't changed. Once a booking doc is created the name can be changed directly on the record.
        system.assertEquals(testFileDescription, bookingDoc.Description__c);//Confirm the desc hasn't changed. Once a booking doc is created the desc can be changed directly on the record.
        system.assertEquals(extRefId, bookingDoc.FileLocation__c);
        system.assertEquals(booking.Id, bookingDoc.Booking__c);
        system.assertEquals('pdf', bookingDoc.FileExtension__c);

        //Original file was removed from Salesforce
        system.assertEquals(0, [Select Count() From ContentVersion]);

    }

    //Test uploading a new file - success response from api
    @isTest
    static void testUploadFile_Failure() {

        Booking__c booking = [Select Id From Booking__c]; 

        ContentVersion testContentVersion = [Select Id, ContentDocumentId From ContentVersion];

        Test.startTest();
            
            //Custom Mock Callout solution (HttpCalloutMock Interface not supported for packaged callouts)
            ExternalFileUploadManager.isSuccess = false;
            ExternalFileUploadManager.errorMessage = 'Oops! the file upload failed!';

            String error = ExternalFileUploaderController.uploadFile(
                testContentVersion.ContentDocumentId,
                testContentVersion.Id,
                booking.Id,
                testFileName,
                testFileDescription
        );
        Test.stopTest();

        //Assertions

        //Error is returned to lwc for attention of the user
        system.assertNotEquals(null, error);
        system.assertEquals(true, error.contains('Oops! the file upload failed!'));//Confirm the api response error is returned

        //Error is logged to platform logs
        system.assertEquals(1, [Select Count() From Golfbreaks__PlatformLog__c]);
        
        //Booking ref was not logged
        system.assertEquals(0, [Select Count() From BookingDocument__c]);

        //Original file was still removed from Salesforce
        system.assertEquals(0, [Select Count() From ContentVersion]);

    }
}