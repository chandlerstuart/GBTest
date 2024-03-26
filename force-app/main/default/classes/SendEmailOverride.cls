/*
Name: SendEmailOverride.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Class to override the default setting behaviour of the 
'Send Email' action

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-05-16  Initial development.
*/
global with sharing class SendEmailOverride implements QuickAction.QuickActionDefaultsHandler{
    // Empty constructor
    global SendEmailOverride() {
    }

    // The main interface method
    global void onInitDefaults(QuickAction.QuickActionDefaults[] defaults) {
        
        //TO DO - Time permitting it would be preferable to create a metadata setting that would enable admins to configure default overrides for each action
        //i.e. FROM Address, TO Address, TEMPLATE DEV NAME, replace subject etc
        //Ticket logged for follow up development; W-000515 
    
        QuickAction.SendEmailQuickActionDefaults sendEmailDefaults = null;


        // Check if the quick action is the standard case feed Send Email action
        for (Integer i = 0; i < defaults.size(); i++) {
            system.debug('QuickActionInfo: '+defaults.size());
            system.debug('QuickActionInfo: '+defaults.get(i));
            if (defaults.get(i) instanceof QuickAction.SendEmailQuickActionDefaults && 
                defaults.get(i).getTargetSObject().getSObjectType() == 
                    EmailMessage.sObjectType && 
                defaults.get(i).getActionName().equals('Case.Send_Email') && 
                defaults.get(i).getActionType().equals('SendEmail')) {
                    sendEmailDefaults = 
                        (QuickAction.SendEmailQuickActionDefaults)defaults.get(i);
                    break;
            }
        }
        
        if (sendEmailDefaults != null) {
            Case c = [SELECT Status, ContactEmail FROM Case 
                        WHERE Id=:sendEmailDefaults.getContextId()];
        
            EmailMessage emailMessage = (EmailMessage)sendEmailDefaults.getTargetSObject();    
            system.debug('getInReplyToId: '+sendEmailDefaults.getInReplyToId());
            emailMessage = setBlankServiceTemplate(emailMessage, c);
            sendEmailDefaults.setTemplateId(
                        getTemplateIdHelper('Customer_Service_Signature_Lightning'));
            sendEmailDefaults.setInsertTemplateBody(false);
            sendEmailDefaults.setIgnoreTemplateSubject(false);
        }
    }

    private Id getTemplateIdHelper(String templateApiName) {
        Id templateId = null;
        try {
            templateId = [select id, name from EmailTemplate 
                            where developername = : templateApiName].id;   
        } catch (Exception e) {
            system.debug('Unble to locate EmailTemplate using name: ' + 
                templateApiName + ' refer to Setup | Communications Templates ' 
                    + templateApiName);
        }
        return templateId;
    }

    public EmailMessage setBlankServiceTemplate(EmailMessage emailMessage, Case c){
        emailMessage.BccAddress = '';
            emailMessage.ToAddress = c.ContactEmail;
            emailMessage.FromAddress = '';
            emailMessage.ValidatedFromAddress = 'customerservice@golfbreaks.com';
            emailMessage.FromName = 'GB Customer Service';
            emailMessage.ParentId = c.Id;
            return emailMessage;
    }

}