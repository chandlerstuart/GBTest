/*
Name:  EmailHelper.cls
Copyright © 2014  Kaptio ehf.
======================================================
======================================================
Purpose:
-------
Facilitates sending of emails from within apex code
======================================================
======================================================
History
------- 
Ver.  Author             Date        Detail
1.0  Örn Ingvar   2014-10-15  Class creation.

*/
public with sharing class EmailHelper {
    
    public static void sendAnEmail(String subject, String body, String emailAddress) {
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {emailAddress};
            mail.setToAddresses(toAddresses);
            mail.setReplyTo(emailAddress);
            mail.setSenderDisplayName(UserInfo.getOrganizationName()+' Admin');
            mail.setSubject(subject);
            mail.setPlainTextBody(body);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } catch (Exception ex) {
            RuntimeExceptionHelper.logException(ex);
        }
    }
    
}