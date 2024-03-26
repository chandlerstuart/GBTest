/*
Name: ManageMarketingPreferencesController
======================================================
======================================================
Purpose: Controller class for ManageMarketingPreference component (and nested components)
======================================================
======================================================
History

Version		Author			Date		Detail
1.0			J Radcliffe		19-03-18	Initial Development
1.1         J Radcliffe     19-09-19    Add mismatch mobile warning development - Retrieve the mobile number stored on the work item and return to the component
1.2         J Radcliffe     19-09-19    Allow Save - Bypass Duplicate Check on Update
1.3         J Radcliffe     03-12-19    Bug Fix - Multiple Individuals following a merge result in the incorrect Individual being retrieved
1.4         J Radcliffe     07-04-21    Enhancements - Alert agents to Undeliverable Emails and enable Email Undeliverable Overrides.
1.5         J Radcliffe     17-03-23    Changes to support the new Email channel setting and addition subscriptions (events and tournaments).
*/
public class ManageMarketingPreferencesController {
    
    public class mmpcWrapper{
        
        @AuraEnabled public Individual ind; 
        @AuraEnabled public Account acc;
        @AuraEnabled public String workItemPhoneNumber;//1.1
        
        public mmpcWrapper(Individual individual, Account account, String workItemPhoneNumber){
            this.ind = individual;
            this.acc = account;
            this.workItemPhoneNumber = workItemPhoneNumber;
        }        
    }
    
    //Query the Individual (preferences) and Account for the corresponding client
    @AuraEnabled
    public static mmpcWrapper getData(Id recordId, String fieldName, String sObjectType, /*1.1*/String workItemPhoneFieldName){
        
        
        system.debug('recordId: '+recordId);
        system.debug('fieldName: '+fieldName);

        try{

            // 1.3+
            String accQuery = 'Select Id, PersonIndividualId, PersonEmail, PersonMailingStreet, PersonMailingCity, PersonMailingCountry, Mailing_State_County__pc, PersonMailingPostalCode, Phone, PersonMobilePhone, PersonHomePhone, PersonOtherPhone,';
            accQuery += 'EmailUndeliverable__c,EmailUndeliverableOverride__c,';//1.4+
            accQuery += 'BillingStreet, BillingCity, BillingCountry, BillingPostalCode, Billing_State_County__c From Account';
            accQuery += (sObjectType == 'Account')?' Where Id =:recordId':' Where Id IN(Select '+fieldName+' From '+sObjectType+' Where Id =:recordId) LIMIT 1';

            Account acc = database.query(accQuery);
            system.debug('Account: '+acc);
            Individual ind = [Select Id, Account__c, Phone__c, SMS__c, Brochure__c, Email__c, Weekly_Newsletter__c, Quarterly_Newsletter__c, TournamentsNewsletter__c, EventsNewsletter__c, Data_Audit_Last_Completed__c From Individual Where Id =:acc.PersonIndividualId];//1.5~ 
            system.debug('Individual: '+ind);
            String workItemPhoneNumber;
            if(workItemPhoneFieldName != null){
                String wIQuery = 'Select Id,'+workItemPhoneFieldName+' From '+sObjectType+' Where Id = :recordId Limit 1';
                sObject workItem = database.query(wIQuery);
                workItemPhoneNumber = (String)workItem.get(workItemPhoneFieldName);
            }

            return new mmpcWrapper(ind,acc,workItemPhoneNumber);

            /*1.3-
            String query;
                query = 'Select Id, PersonEmail, PersonMailingStreet, PersonMailingCity, PersonMailingCountry, Mailing_State_County__pc, PersonMailingPostalCode, Phone, PersonMobilePhone, PersonHomePhone, PersonOtherPhone,';
                query += 'BillingStreet, BillingCity, BillingCountry, BillingPostalCode, Billing_State_County__c,';
                query += '(Select Id, Account__c, Phone__c, SMS__c, Brochure__c, Weekly_Newsletter__c, Quarterly_Newsletter__c, Data_Audit_Last_Completed__c From Individuals__r) ';
            
            if(sObjectType == 'Account'){
                query += 'From Account Where Id =:recordId';
            }else{
                query += 'From Account Where Id IN(Select '+fieldName+' From '+sObjectType+' Where Id =:recordId) LIMIT 1';
            }
        
            Account[] accWithInd = database.query(query);
            String error;
            if(accWithInd != null && accWithInd.size()>0 && accWithInd[0].Individuals__r.size()>0){
                Account acc = accWithInd[0];
                Individual ind = acc.Individuals__r[0];

                 //1.1
                String workItemPhoneNumber;
                if(workItemPhoneFieldName != null){
                    String wIQuery = 'Select Id,'+workItemPhoneFieldName+' From '+sObjectType+' Where Id = :recordId Limit 1';
                    sObject workItem = database.query(wIQuery);
                    workItemPhoneNumber = (String)workItem.get(workItemPhoneFieldName);
                }

                mmpcWrapper wrapper = new mmpcWrapper(ind,acc,workItemPhoneNumber);
                return wrapper;
            }else{
                //Throw and error if no client is found
                throw new AuraHandledException('No Client or Preferences Found. Record Id: '+recordId+'; fieldName: '+fieldName);  
            } */             
        }catch(exception e){
            //PlatformLogManager.logExceptions(e, 'ManageMarketingPreferencesController', 'getData');            
            throw new AuraHandledException(e.getMessage());  
        }
    }
    
    @AuraEnabled
    public static void noChangesRequired(Id indId){
        system.debug('indId: '+indId);
        if(indId == null) return;
        
        Individual ind = [Select Id, Data_Audit_Last_Completed__c From Individual Where Id=:indId Limit 1][0];
        
        //Setting audit completion date
        ind.Data_Audit_Last_Completed__c = system.today();
        
        try{
            update ind;
        }catch(exception e){
            PlatformLogManager.logExceptions(e, 'ManageMarketingPreferencesController', 'noChangesRequired');            
            throw new AuraHandledException(e.getMessage());   
        }
    }
    
    @AuraEnabled
    public static Boolean submitChanges(Individual ind, Account acc, String changeHistoryText, String phoneNumber){
        
        if(changeHistoryText == null || changeHistoryText == '') changeHistoryText = ApplicationConstant.AGENT_CONSOLE_EDIT;
        
        //Setting audit completion date
        ind.Data_Audit_Last_Completed__c = system.today();     
        
        //Setting the Change_Reason__c values for all Communication Preferences. 
        //If no changes are made to the channel, these values will be cleared on update by the Ind Trigger
        
        /*1.5 -
        ind.SMS_Change_Reason__c = 'Individual | '+ind.Id+' | '+changeHistoryText;
        ind.Brochure_Change_Reason__c = 'Individual | '+ind.Id+' | '+changeHistoryText;
        ind.Phone_Change_Reason__c = 'Individual | '+ind.Id+' | '+changeHistoryText;
        ind.Weekly_Newsletter_Change_Reason__c = 'Individual | '+ind.Id+' | '+changeHistoryText;
        ind.Quarterly_Newsletter_Change_Reason__c = 'Individual | '+ind.Id+' | '+changeHistoryText;
        */
        
        ind.MarketingSubscriptionChangeReason__c = 'Individual | '+ind.Id+' | '+changeHistoryText;//1.5+
        
        //Copying Mailing Address to Billing Address fields
        acc.BillingStreet = acc.PersonMailingStreet;
        acc.BillingCity = acc.PersonMailingCity;
        acc.BillingCountry = acc.PersonMailingCountry;
        acc.BillingPostalCode = acc.PersonMailingPostalCode;
        acc.Billing_State_County__c = acc.Mailing_State_County__pc;

        //1.1 - Mobile Exists on Client Account
        Boolean phoneAuditRequired = true;
        if(acc.PersonMobilePhone == phoneNumber) phoneAuditRequired = false;
        if(acc.PersonHomePhone == phoneNumber) phoneAuditRequired = false;
        if(acc.PersonOtherPhone == phoneNumber) phoneAuditRequired = false;
        if(acc.Phone == phoneNumber) phoneAuditRequired = false;

        try{
            //1.2
            Database.DMLOptions dml = new Database.DMLOptions(); 
            dml.DuplicateRuleHeader.AllowSave = true;
            database.update(ind,dml);            
            database.update(acc,dml);
        }catch(exception e){
            system.debug('Whoops! There was an error > '+e.getMessage()+'-'+e.getStackTraceString());
            PlatformLogManager.logExceptions(e, 'ManageMarketingPreferencesController', 'submitChanges');
            throw new AuraHandledException(e.getMessage());           
        }
        return phoneAuditRequired;//1.1+
    }
    
}