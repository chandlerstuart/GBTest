/*
Name:  DataScrambler.cls
======================================================
======================================================
Purpose:
-------
Batch class to scramble data post-sandbox refresh (Accounts, Contacts, Leads)

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon Molloy  2017-06-30  Initial development.
1.1  Simon Molloy  2018-01-02  Added in check to make sure this does NOT run on Live instance 
1.2  J Radcliffe   2022-11-09  
*/
global with sharing class DataScrambler implements Database.Batchable<sObject> {
    global static String LIVE_URL = 'https://golfbreaks.my.salesforce.com';
    global static String CLASS_NAME = 'DataScrambler';
    global static String EMAIL_MODIFIER = 'example.com';
    global static String PHONE_MODIFIER = '+440000000000';
    global String query {get; set;}
    global String whichObject {get; set;}
    global List<Contact> contactList {get; set;}

    global DataScrambler(String inWhichObject){
        if (null == query){
            whichObject = inWhichObject;
            if ('LEAD'.equalsIgnoreCase(whichObject)){
                query = 'SELECT Id, Email, Phone, MobilePhone, HomePhone__c from Lead WHERE IsConverted = FALSE AND Batch_Processed__c = FALSE';
            }else if ('ACCOUNT'.equalsIgnoreCase(whichObject)){
                query = 'SELECT Id, PersonEmail, PersonHomePhone, PersonMobilePhone, PersonOtherPhone, Phone, Batch_Processed__c ';//, ';
                //query += '(SELECT Id, Email, HomePhone, MobilePhone, OtherPhone, Phone from Contacts) ';
                query += 'FROM Account WHERE Batch_Processed__c = FALSE';
            }
        }
    }

    global Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope){
        //Safety measure to ensure this does not run in LIVE
        if (!Test.isRunningTest() && LIVE_URL.equalsIgnoreCase(URL.getSalesforceBaseUrl().toExternalForm())){
            return;
        }
        List<Error_Log__c> logs = new List<Error_Log__c>();

        if ('LEAD'.equalsIgnoreCase(whichObject)){
            List<Lead> processList = (List<Lead>)scope;

            for (Lead l : processList){
                l.Batch_Processed__c = TRUE;
                if (null != l.Email) l.Email = splitEmail(l.Email);
                if (null != l.Phone) l.Phone = PHONE_MODIFIER;
                if (null != l.MobilePhone) l.MobilePhone = PHONE_MODIFIER;
                if (null != l.HomePhone__c) l.HomePhone__c = PHONE_MODIFIER;
            }

        }else if ('ACCOUNT'.equalsIgnoreCase(whichObject)){
            List<Account> processList = (List<Account>) scope;
            contactList = new List<Contact>();

            for (Account a : processList){
                a.Batch_Processed__c = TRUE;
                if (null != a.PersonEmail) a.PersonEmail = splitEmail(a.PersonEmail);
                if (null != a.PersonHomePhone) a.PersonHomePhone = PHONE_MODIFIER;
                if (null != a.PersonMobilePhone) a.PersonMobilePhone = PHONE_MODIFIER;
                if (null != a.PersonOtherPhone) a.PersonOtherPhone = PHONE_MODIFIER;
                if (null != a.Phone) a.Phone = PHONE_MODIFIER;

                /*if (!a.Contacts.isEmpty()){
                    for (Contact c : a.Contacts){
                        boolean updateContact = false;
                        if (null != c.Email){
                            c.Email = splitEmail(c.Email);
                            updateContact = true;
                        }
                        if (null != c.HomePhone){
                            c.HomePhone = PHONE_MODIFIER;
                            updateContact = true;
                        }
                        if (null != c.MobilePhone){
                            c.MobilePhone = PHONE_MODIFIER;
                            updateContact = true;
                        }
                        if (null != c.OtherPhone){
                            c.OtherPhone = PHONE_MODIFIER;
                            updateContact = true;
                        }
                        if (null != c.Phone){
                            c.Phone = PHONE_MODIFIER;
                            updateContact = true;
                        }
                    }
                }*/
            }
        }

        system.debug('*** -- Update scope -- ***');   
        logs.addAll(getResultLogs(Database.update(scope, false), whichObject, 'Update'));

        /*
        if ('ACCOUNT'.equalsIgnoreCase(whichObject)){
            if (!contactList.isEmpty()){
                List<SObject> contactSObjects = contactList;
                logs.addAll(getResultLogs(Database.update(contactSObjects, false), 'CONTACT', 'Update'));
            }
        }*/

        if (!logs.isEmpty()){
            system.debug('*** -- Logs -- *** > '+JSON.serialize(logs));   
            Database.insert(logs, false);
        }

    }

    global void finish(Database.BatchableContext bc){

    }

    private String splitEmail(String emailAddress){
        String[] emailSplit;
        if (emailAddress.indexOf('@') > 0) {
            emailSplit = emailAddress.split('@');   
        }else {
            emailSplit = new String[]{emailAddress};
        }
        
        return emailSplit[0] + '@' + EMAIL_MODIFIER;
    }

    static List<Error_Log__c> getResultLogs(List<Database.SaveResult> listSaveResults, String objName, String dmlOp)   {
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        errorLogs.addAll(ApplicationConstant.getSaveResultLog(listSaveResults, 'execute', CLASS_NAME, objName, dmlOp));
        return errorLogs;
    }
}