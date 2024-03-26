/*
Name:  ExternalFileUploaderController.cls
======================================================
======================================================
Purpose:
-------
Controller for ExternalFileUploader lwc. This component enables users
to upload files (related to a Booking/Guest) to an external source. External 
files are accessible to customer via the portal. 

Code Coverage:
ExternalFileUploaderControllerTest.cls - 92%

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2023-07-20  Initial development.
*/
public with sharing class ExternalFileUploaderController { 

    public class CustomException extends Exception{}
    
    //SObject Constants - For supported data types.
    public static final String bookingDocObjectAPIName = 'BookingDocument__c';
    public static final String bookingObjectAPIName = 'Booking__c';
    public static final String bookingGuestObjectAPIName = 'BookingGuest__c';

    public static final String fileUploadCustomPermission = 'Upload_External_Files';

    @AuraEnabled
    public static String uploadFile(String documentId, String contentVersionId, String recordId, String fileName, String fileDesc) {

        try{

            //Validate input
            if(fileName == null) throw new CustomException('A file name must be provided');//Files will be visible to customers and should include a recognisable name.
            if(documentId == null || contentVersionId == null) throw new CustomException('Invalid document or document version id');//These identifiers are for the newly uploaded file logged to Salesforce via standard file upload cmp.
            if(recordId == null) throw new CustomException('No related record id provided in upload');//Uploads can only take place from a record page.
            String sObjectAPIName = String.valueOf(Id.valueOf(recordId).getSObjectType());
            if(!sObjectAPIName.containsIgnoreCase(bookingDocObjectAPIName) 
            && !sObjectAPIName.containsIgnoreCase(bookingObjectAPIName)
            && !sObjectAPIName.containsIgnoreCase(bookingGuestObjectAPIName)) throw new CustomException('Invalid operation. External file uploads are not supported for this data type: '+sObjectAPIName);//For supported data types only.

            //Verify permissions
            Boolean hasPermission = FeatureManagement.checkPermission(fileUploadCustomPermission);
            if(!hasPermission) throw new CustomException('Oops! Sorry, you don\'t have permission to upload external files. Please contact your System Administrator if you require assistance.');

            //Query file data 
            ContentVersion fileVersion = [Select Id, VersionData, FileExtension, ContentDocument.FileType, ContentDocument.Title, ContentDocumentId From ContentVersion Where Id = :contentVersionId];
            
            // Make the API call to store the file externally (gb enterprise api) and retrieve the unique reference id
            String externalFileReferenceId; 
            BookingDocument__c bookingDocument;
            if(sObjectAPIName.containsIgnoreCase(bookingDocObjectAPIName)){//If uploading from a Booking Doc, assume the file is being updated.
                //Retrieve externalFileReferenceId from the Booking Document (for update)
                bookingDocument = [Select Id, Booking__c, BookingGuest__c, FileLocation__c, Name, Description__c From BookingDocument__c Where Id = :recordId];
                fileName = bookingDocument.Name;
                fileDesc = bookingDocument.Description__c;
                externalFileReferenceId = ExternalFileUploadManager.updateExtFile(recordId,fileVersion.FileExtension, fileVersion.VersionData, bookingDocument.FileLocation__c);
            }else{//Else assume this is a new file upload.
                externalFileReferenceId = ExternalFileUploadManager.uploadExtFile(recordId,fileVersion.FileExtension, fileVersion.VersionData);
            }
            //A unique ext id must be returned by both calls for upsert
            if(externalFileReferenceId == null) throw new CustomException('No External File Reference Id found');
            
            //Map data to booking & guest based on data type i.e. link guest file upload to the guest AND booking.
            Id bookingId;
            Id guestId;
            if(sObjectAPIName.equalsIgnoreCase(bookingObjectAPIName)){//Booking__c
                bookingId = recordId;
            }else if(sObjectAPIName.equalsIgnoreCase(bookingGuestObjectAPIName)){//BookingGuest__c
                guestId = recordId;
                bookingId = [Select Id, Booking__c From BookingGuest__c Where Id = :recordId].Booking__c;
            }else if(sObjectAPIName.equalsIgnoreCase(bookingDocObjectAPIName)){//BookingDocument__c
                guestId = bookingDocument.BookingGuest__c;
                bookingId = bookingDocument.Booking__c;
            }

            // Upsert BookingDocument__c entry with file details using the ext id (FileLocation__c)
            upsert(new BookingDocument__c(FileLocation__c=externalFileReferenceId,
                                            Booking__c=bookingId,
                                            BookingGuest__c=guestId,
                                            Name=fileName,
                                            Description__c=fileDesc,
                                            FileExtension__c=fileVersion.FileExtension)) FileLocation__c;      

            return null;//Returning null will tell the lwc that everything has executed successfully.
        } catch (Exception e) {
            system.debug('Failure!');
            return 'Failed to load file externally. Please contact your System Administrator for assistance. Error: '+ e.getMessage()+'-'+e.getStackTraceString();//Returning a string will tell the lwc something went wrong.
        }finally{
            delete [Select Id From ContentDocument Where Id = :documentId];//Regardless of outcome, the original file uploaded to Salesforce must be deleted.
        }
    }
}