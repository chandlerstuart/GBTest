/*
Name:  GetATOLCertificateResponseHandler.cls
======================================================
======================================================
Purpose:
-------
Response Handler for GetATOLCerificate Data Event Type
(Integration Framework)

Coverage: 
GetATOLCertificateResponseHandlerTest - 98%

====================================================== 
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2022-07-05  Initial development
2.1  J Radcliffe   2023-07-20  The ATOL certificate will now be stored externally (and accessible to customers via the portal)
*/
public with sharing class GetATOLCertificateResponseHandler implements IDataEventTypeResponseHandler3{
    
    public class CustomException extends Exception {}
    @TestVisible public static final String singleBookingOnlyError = 'api.salesforce only accepts single bookings. Therefore, only one Booking record is expected/can be processed per request.';
    public static final String emailTemplateDeveloperName = 'ATOL_Certificate';
    public static final String orgWideEmailAddress = 'noreply@golfbreaks.com';
    
    public static Boolean handleOutboundResponse(HttpResponse r, String reshapedResponseBody, Id outboundCalloutId, Set<Id> recordIds){

        //Verify one (and only one) record id is passed
        if(recordIds == null){Golfbreaks.PlatformLogManager.logCustomMessage('No records were passed to the Custom Apex Response Handler.','No Record Ids','GetATOLCertificateResponseHandler','handleOutboundResponse',null);return false;}
        if(recordIds.size()>1){Golfbreaks.PlatformLogManager.logCustomMessage('More than one record was passed to the Custom Apex Response Handler. Calls to the Token Work API return one Id, so only single callouts (per record) are supported.','Multiple Records Detected (Expected 1)','GetATOLCertificateResponseHandler','handleOutboundResponse',null);return false;}
        
        //Get booking Id
        Id recordId = new List<Id>(recordIds)[0];

        try{

            if(r == null || r.getBody() == null || String.isBlank(r.getBody())) throw new CustomException('Cannot send email. No file returned by API');

            //Retrieve the Booking 
            Booking__c booking = [Select Id, Account__r.PersonContactId, Account__r.PersonEmail, Name, ATOLCertificateEmailStatus__c, (Select Id From Attachments Where Name LIKE 'ATOL Certificate - %' and ContentType = 'application/pdf'), (Select Id, FileLocation__c From Booking_Documents__r Where Name LIKE 'ATOL Certificate - %' and FileExtension__c = 'pdf') From Booking__c Where Id =:recordId];//2.1~
            String fileName = 'ATOL Certificate - '+booking.Name+'.pdf';
 
            //2.1+ - Store file to external source (must happen first to avoid 'uncommitted work pending' error)
            String externalFileReferenceId;
            Boolean externalUploadIsSuccess = true;
            try{
                if(booking.Booking_Documents__r.size()>0){//Update existing file
                    externalFileReferenceId = ExternalFileUploadManager.updateExtFile(booking.Booking_Documents__r[0].Id,'pdf', r.getBodyAsBlob(), booking.Booking_Documents__r[0].FileLocation__c);
                }else{//Upload new file
                    externalFileReferenceId = ExternalFileUploadManager.uploadExtFile(recordId,'pdf', r.getBodyAsBlob());
                }
            }catch(Exception e){}
            if(externalFileReferenceId == null) externalUploadIsSuccess = false;//Flag failures. Failures to upload the file externally should NOT prevent the file being emailed to the customer.

            //Retrieve template (implicitly throw exception if deleted or unrecognised)
            EmailTemplate emailTemplate = [Select Id From EmailTemplate Where DeveloperName =:emailTemplateDeveloperName Limit 1][0];

            //Construct email message for Lead Booker
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setToAddresses(new List<String>{booking.Account__r.PersonEmail});
            //message.setOrgWideEmailAddressId(orgWideAddress.Id);
            message.setTemplateId(emailTemplate.Id);
            message.setTargetObjectId(booking.Account__r.PersonContactId);
            message.setWhatId(booking.Id);
            
            //Extract pdf file from response and attach to email message
            attachATOLCertificate(fileName, message, r);//2.1-

            //Send email message
            Messaging.SendEmailResult result = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{message},false)[0]; 
            
            //Update Booking Email Status and log failures
            booking.ATOLCertificateEmailStatus__c = (result.isSuccess())?(externalUploadIsSuccess)?'Sent':'Upload Failure':'Failed';//2.1~
            if(!result.isSuccess()) Golfbreaks.PlatformLogManager.logCustomMessage(result.getErrors()[0].message,'Send ATOL Email Failure','GetATOLCertificateResponseHandler','handleOutboundResponse',null);
            update booking;

            //2.1+ Upsert BookingDocument__c entry with file details using the ext id (FileLocation__c)
            if(externalUploadIsSuccess){
                upsert(new BookingDocument__c(FileLocation__c=externalFileReferenceId,
                                            Booking__c=recordId,
                                            Name=fileName,
                                            FileExtension__c='pdf',
                                            Description__c='ATOL Certificate')) FileLocation__c;  
            }else{
                //Log failures to upload the file for the attention of the SF Team.
                Golfbreaks.PlatformLogManager.logCustomMessage('Cannot log Booking Document. There was a filure to externally upload the ATOL certificate for booking no. '+booking.Name+'.','Failed to upload externally','GetATOLCertificateResponseHandler','handleOutboundResponse',null);
            } 

            //Attach a copy of the refreshed file to booking for auditing/troubleshooting purposes
            Attachment att=new Attachment();
            if(booking.Attachments.size()>0) att.Id = booking.Attachments[0].Id;//Apply Id (for update)
            if(booking.Attachments.size()==0) att.parentId=recordId;//Field not updatable (only apply on insert only)
            att.Body=r.getBodyAsBlob();
            att.ContentType = 'application/pdf';
            att.Name=fileName;
            upsert att;
             
            return result.isSuccess();//Return success to the framework if we were able to successfully email the customer.

        }catch(Exception e){
            system.debug('error > '+e.getMessage());
            Golfbreaks.PlatformLogManager.logExceptions(e,'GetATOLCertificateResponseHandler','handleOutboundResponse');
            update new Booking__c(Id=recordId,ATOLCertificateEmailStatus__c='Failed');
            return false;
        }

    }

    public static void attachATOLCertificate(String fileName, Messaging.SingleEmailMessage message, HttpResponse r){
        
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName(fileName);
        efa.setBody(r.getBodyAsBlob());
        efa.setContentType('application/pdf');
        attachments.add(efa);
        message.setFileAttachments(attachments);

    }

}