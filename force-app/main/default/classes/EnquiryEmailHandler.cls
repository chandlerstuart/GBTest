/*
Name:  EnquiryEmailHandler.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Email Handler class for Enquiry creation.

Todo:
        
    DONE ----> (1) Unit tests

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-09-16  Initial development.
1.1  Mark Cane&    2019-09-18  Added clientId parameter.
1.2  J Radcliffe   2019-11-14  Null check for email attachments
*/
global class EnquiryEmailHandler implements Messaging.InboundEmailHandler {
 
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, Messaging.InboundEnvelope env){
 
        Messaging.InboundEmailResult emailResult = new Messaging.InboundEmailResult();          
        emailResult.success = false;

        DateTime startDateTime = system.now();        

        try {
            
            String bodyText='';

            if (String.isNotBlank(email.plainTextBody) && !email.plainTextBodyIsTruncated){            
                bodyText = email.plainTextBody;
            } else if (String.isNotBlank(email.htmlBody) && !email.htmlBodyIsTruncated){        
                bodyText = email.htmlBody;
            }

            String transactionId,clientId,actionTypeName,toAddress='',keyPrefix='';

            if (!String.isBlank(bodyText)){

                String regex='(transactionId:[a-zA-Z0-9]{18},clientId:[a-zA-Z0-9]{18},actionType:[a-zA-Z]*)';//use action type DeveloperName for portability across orgs.

                Matcher matcher=Pattern.compile(regex).matcher(bodyText);
                Boolean result= matcher.find();

                if (result && matcher.groupCount()>0){
                
                    String matchedText = matcher.group(0);

                    if (matchedText.contains(',') && matchedText.split(',').size()==3){
                        transactionId = matchedText.split(',')[0].contains(':') ? matchedText.split(',')[0].split(':')[1] : null;
                        clientId = matchedText.split(',')[1].contains(':') ? matchedText.split(',')[1].split(':')[1] : null;
                        actionTypeName = matchedText.split(',')[2].contains(':') ? matchedText.split(',')[2].split(':')[1] : null;
                    }
                }
            }
            
            if (String.isBlank(actionTypeName) && email.toAddresses!=null && email.toAddresses.size()>0){

                keyPrefix = String.isNotBlank(transactionId) ? transactionId.left(3) : null;

                ActionType__mdt actionType = ActionTypeHelper.getActionTypeForToAddressesAndKeyPrefix(email.toAddresses,keyPrefix);

                if (actionType!=null) actionTypeName = actionType.DeveloperName;
            }

            List<String> errorMessages = new List<String>();

            if (String.isBlank(actionTypeName)){
                LogHelper.logEmailRequest(email.fromName+' ['+email.fromAddress+']\n'+'To Addresses:'+email.toAddresses+'\n'+bodyText,Label.Enquiry_Validation_Error_Missing_Action_Type_For_Email,0,0,1,errorMessages);
                return emailResult;
            }                    
            
            EnquiryManager.Enquiry emailEnquiry = new EnquiryManager.Enquiry();
            //email.fromEmail -> clientDetails.email
            //email.fromName -> clientDetail.firstName + clientDetail.lastName
            //email.toAddresses -> taskDetails.detail
            //email.ccAddresses -> taskDetails.detail
            //email.subject -> taskDetails.subject
            //email.htmlBody -> taskDetails.detail
            //email.plainTextBody -> taskDetails.detail
            //email.textAttachments -> Attachments
            //email.binaryAttachments -> Attachments

            emailEnquiry.actionTypeName = actionTypeName;
            if (String.isNotBlank(transactionId)) emailEnquiry.relatedToId = transactionId; //set the transactionId such that the new Record can be linked to the parent record via Action Type Field Mapping.
            if (String.isNotBlank(clientId)) emailEnquiry.clientDetails.accountId = clientId;

            emailEnquiry.clientDetails.email = email.fromAddress;

            String fn='',ln='';            
            if (email.fromName.contains(' ')){
                
                for (Integer i=0;i<email.fromName.split(' ').size();i++){
                    if (i==0) fn=email.fromName.split(' ')[i];
                    else ln+=' '+email.fromName.split(' ')[i];
                }                
            } else {
                fn='';
                ln=email.fromName;
            }
            emailEnquiry.clientDetails.firstName = fn;
            emailEnquiry.clientDetails.lastName = ln;
        
            emailEnquiry.taskDetails.subject = email.subject;            
            
            emailEnquiry.taskDetails.detail='To Addresses:'+email.toAddresses+'\n';
            emailEnquiry.taskDetails.detail+='CC Addresses:'+email.ccAddresses+'\n';  
            emailEnquiry.taskDetails.detail+=bodyText;

            emailEnquiry.propertyCache.putAll(emailEnquiry.clientDetails.propertyCache);//Critical to allow field mappings to process.
            emailEnquiry.propertyCache.putAll(emailEnquiry.taskDetails.propertyCache);//Critical to allow field mappings to process.

            EnquiryManager em = new EnquiryManager();
            
            EnquiryManager.Enquiry e  = em.processEnquiries( new List<EnquiryManager.Enquiry>{ emailEnquiry })[0];

            String emailOutcome='';

            if(e.isSuccess){
                emailOutcome='RecordId: '+e.sfRecordId+':ClientId: '+e.clientDetails.accountId;

                if (String.isNotBlank(e.sfRecordId) && sObjectTypeSupportsAttachments(e.sfRecordId)){

                    List<Attachment> fileAttachments = new List<Attachment>();
                    if(email.textAttachments != null){//1.2+
                        for (Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments) {
                            fileAttachments.add( new Attachment(Name=tAttachment.fileName,Body=Blob.valueOf(tAttachment.body),ParentId=e.sfRecordId) );
                        }       
                    }  
                    if(email.binaryAttachments != null){//1.2+       
                        for (Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {
                            fileAttachments.add( new Attachment(Name=bAttachment.fileName,Body=bAttachment.body,ParentId=e.sfRecordId) );
                        }
                    }
                    if (!fileAttachments.isEmpty()) insert fileAttachments;
                }

            } else {
                if (!e.errorMessages.isEmpty()){
                    for(String error : e.errorMessages.values()){
                        if(!errorMessages.contains(error) && error!=null) errorMessages.add(error);
                    }
                }
            }
            emailResult.success = e.isSuccess;
            
            Integer speedInSeconds = (Integer)(system.now().getTime()-startDateTime.getTime())/1000;
            LogHelper.logEmailRequest(bodyText+':'+actionTypeName+':'+transactionId+':'+keyPrefix+':'+toAddress,emailOutcome,speedInSeconds,(emailResult.success ? 1:0),(emailResult.success ? 0:1),errorMessages);

        } catch(Exception ex){
            LogHelper.logExceptions(ex, 'EnquiryEmailHandler', 'handleInboundEmail');
            emailResult.success = false;
        }
        return emailResult;
    }

    private Boolean sObjectTypeSupportsAttachments(String recordId){
        try {
            Id recordIdAsId = Id.valueOf(recordId);

            Schema.DescribeFieldResult dfr = Schema.sObjectType.Attachment.fields.ParentId;

            for (Schema.SObjectType sobjectType : dfr.getReferenceTo()){
                if (sobjectType==recordIdAsId.getSobjectType()) return true;
            }
        } catch (Exception ex){}
        return false;
    }
}