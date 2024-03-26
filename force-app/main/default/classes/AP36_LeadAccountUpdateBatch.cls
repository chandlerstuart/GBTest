/**
 * @Author: Jerome To
 * @name: AP36_LeadAccountUpdateBatch 
 * @CreateDate: 19.04.2016
 * @Description: Scheduled batch for Lead Account Update
 * @Version <1.0>
 */

global with sharing class AP36_LeadAccountUpdateBatch implements Database.Batchable<sObject>, Database.Stateful{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        //Id closedConverted = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Id closedConverted').getRecordTypeId();
        Id closedConverted = [Select Id From RecordType Where SObjectType='Lead' AND DeveloperName='closedConverted' LIMIT 1].Id;
        
        String query = 'SELECT Id,';
        query += ' Name,';
        query += ' City,'; 
        query += ' PostalCode,';
        query += ' Country,';
        query += ' State,';
        query += ' Street,';
        query += ' Salutation,';
        query += ' FirstName,';
        query += ' LastName,';
        query += ' Account__c,';
        query += ' DonotsendviaEmail__c,';
        query += ' DonotsendviaPost__c,';
        query += ' DonotsendviaSMS__c,';
        query += ' PGA__c,';
        query += ' VIP__c,';
        query += ' Phone,';
        query += ' MobilePhone,';
        query += ' HomePhone__c,';
        query += ' BestTimetoCall__c,';
        query += ' Email';
        query += ' FROM Lead WHERE Account__c = null AND Email <> \'\' AND RecordTypeId != '+ '\'' + closedConverted + '\'';
        System.debug(LoggingLevel.INFO ,'********* AP36_LeadAccountUpdateBatch Query - ' + query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Lead> scope){
        
        System.debug(LoggingLevel.INFO ,'********* AP36_LeadAccountUpdateBatch scope size - ' + scope.size());

        List<Lead> leadsToUpdate = new List<Lead>();
        List<String> emailList = new List<String>();
        Map<String, Account> emailAccountMap = new Map<String, Account>();
        
        if(!scope.isEmpty()){
            for(Lead leadRec : scope){
                emailList.add(leadRec.Email);
            }

            for(Account acct : [SELECT Id, PersonEmail, BillingCity, BillingPostalCode, BillingCountry, BillingState, BillingStreet, PersonMobilePhone, Salutation, FirstName, LastName, PersonHomePhone, Phone, BestTimeToCall__c, DoNotsendviaEmail__c, DoNotsendviaPost__c,
                                   DoNotsendviaSMS__c, Is_PGA__pc, Is_VIP__pc, Bond_Holder__pc FROM Account WHERE PersonEmail IN: emailList AND IsPersonAccount = true]){
                emailAccountMap.put(acct.PersonEmail, acct);
                 
            }

            for(Lead leadRecord : scope){
                if(emailAccountMap.containsKey(leadRecord.Email)){
                    Account acct = emailAccountMap.get(leadRecord.Email);
                    if(acct != null){
                        leadRecord.City = acct.BillingCity;
                        leadRecord.PostalCode = acct.BillingPostalCode;
                        leadRecord.Country = acct.BillingCountry;
                        leadRecord.State = acct.BillingState;
                        leadRecord.Street = acct.BillingStreet;
                        leadRecord.Salutation = acct.Salutation;
                        leadRecord.FirstName = acct.FirstName;
                        leadRecord.LastName =  acct.LastName;
                        leadRecord.Account__c =  acct.Id;
                        leadRecord.DonotsendviaEmail__c =  acct.DoNotsendviaEmail__c;
                        leadRecord.DoNotsendviaPost__c =  acct.DoNotsendviaPost__c;
                        leadRecord.DoNotsendviaSMS__c =  acct.DoNotsendviaSMS__c;
                        leadRecord.PGA__c =  acct.Is_PGA__pc;
                        //leadRecord.VIP__c =  acct.Is_VIP__pc;
                        leadRecord.Phone = acct.Phone;
                        leadRecord.MobilePhone = acct.PersonMobilePhone;
                        leadRecord.HomePhone__c =  acct.PersonHomePhone;
                        leadRecord.BestTimetoCall__c = acct.BestTimeToCall__c;
                    }
                    leadsToUpdate.add(leadRecord);
                }
            }

            Database.SaveResult[] updateLeadList = Database.update(leadsToUpdate, false);
            String errorLogDescription;
            for(Integer i=0; i< updateLeadList.size(); i++){
                Database.SaveResult result = updateLeadList[i];
                // SUCCESS
                if(updateLeadList.get(i).isSuccess()){
                    System.Debug(LoggingLevel.INFO, '>>SUCCESS : updateLeadList.get(i).getId()<<'+updateLeadList.get(i).getId());
                }
                // ERROR
                else{
                    List<Database.Error> lstErrors = result.getErrors();
                    for(Integer j=0; j< lstErrors.size(); j++){        
                        System.Debug(LoggingLevel.INFO,'>>ERROR : updateLeadList.get(i).Id<<'+updateLeadList.get(i).Id);
                    }
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}