/*
Name:  ExternalFileUploadManager.cls
======================================================
======================================================
Purpose:
-------
Handler for invoking the Integration Framework package to 
upload files externally. This is called from the ExternalFileUploader lwc
and GetATOLCertificateResponseHandler.cls.

Code Coverage:
ExternalFileUploaderControllerTest.cls - 90%

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2023-07-20  Initial development.
*/
public with sharing class ExternalFileUploadManager {

    public class CustomException extends Exception {} 

    @TestVisible public static String errorMessage;
    @TestVisible public static Boolean isSuccess;
    @TestVisible public static String responseBody;

    public static final String fileUploadDET = 'External_File_Upload';
    public static final String fileUpdateDET = 'External_File_Update';

    public Class FileUploadRequest{
        public String fileExtension;
        public String base64FileToUpload;
        public FileUploadRequest(String fileExtension, String base64FileToUpload){
            this.fileExtension = fileExtension;
            this.base64FileToUpload = base64FileToUpload;
        }
    }

    public Class FileUploadResponse{

    }
    
    //Upload or update a document 
    public static String uploadExtFile(String recordId, String fileExtension, Blob fileData){

        try{

            //Construct apex-defined request
            FileUploadRequest fur = new FileUploadRequest(fileExtension,EncodingUtil.base64Encode(fileData));

            //Prepare api request (via integration framework package)
            DataEventTypeAction.DataEventTypeActionRequest req = new DataEventTypeAction.DataEventTypeActionRequest();
            req.dataEventType = fileUploadDET;
            req.recordId = recordId;
            req.requestBody = JSON.serialize(fur);

            //Upload file
            DataEventTypeAction.DataEventTypeActionResult res = !Test.isRunningTest()?DataEventTypeAction.invokeDataEventType(new List<DataEventTypeAction.DataEventTypeActionRequest>{req})[0]:new DataEventTypeAction.DataEventTypeActionResult(recordId);
            if(Test.isRunningTest()){
                res.isSuccess = isSuccess;
                res.errorMessage = errorMessage;
                res.responseBody = responseBody;
            }

            //Handle api response
            if(!res.isSuccess || String.isBlank(res.responseBody)){
                throw new CustomException(res.errorMessage+' - '+res.responseBody);
            }else{
                return res.responseBody.replace('"','');//Expected file location (uId) - Remove double quotes
            }
        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'BookingDocumentManager','uploadExtFile');
            throw new CustomException('Failed to upload the new file. Please contact your System Administrator for assistance. '+e.getMessage()+'-'+e.getStackTraceString());
        }
        
    }

    public static String updateExtFile(String recordId, String fileExtension, Blob fileData, String externalFileReferenceId){
        try{
            if(externalFileReferenceId == null) throw new CustomException('No external file reference id could be identified.');
            
            //Construct apex-defined request
            FileUploadRequest fur = new FileUploadRequest(fileExtension,EncodingUtil.base64Encode(fileData));

            //Prepare api request (via integration framework package)
            DataEventTypeAction.DataEventTypeActionRequest req = new DataEventTypeAction.DataEventTypeActionRequest();
            req.dataEventType = fileUpdateDET;
            req.recordId = recordId;
            req.requestBody = JSON.serialize(fur);

            //Upload file
            DataEventTypeAction.DataEventTypeActionResult res = !Test.isRunningTest()?DataEventTypeAction.invokeDataEventType(new List<DataEventTypeAction.DataEventTypeActionRequest>{req})[0]:new DataEventTypeAction.DataEventTypeActionResult(recordId);
            if(Test.isRunningTest()){
                res.isSuccess = isSuccess;
                res.errorMessage = errorMessage;
                res.responseBody = responseBody;
            }            

            //Handle api response
            if(!res.isSuccess || String.isBlank(res.responseBody)){
                throw new CustomException(res.errorMessage+' - '+res.responseBody);
            }else{
                return res.responseBody.replace('"','');//Expected file location (uId) - Remove double quotes
            }
        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'BookingDocumentManager','updateExtFile');
            throw new CustomException('Failed to update the external file. Please contact your System Administrator for assistance. '+e.getMessage()+'-'+e.getStackTraceString());
        }
    }

}