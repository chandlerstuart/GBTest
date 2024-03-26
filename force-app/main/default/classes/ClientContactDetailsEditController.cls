/**
Name:  ClientContactDetailsEditController.cls
======================================================
======================================================
Purpose:
-------
Controller for ClientContactDetailsEdit VF Page
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail 
1.0  JRadcliffe   2018-04-27    Initial Development
1.1  JRadcliffe   2018-05-22    Ensure changes to the Mailing Address are replicated to the Billing Address
1.2  JRadcliffe   2018-06-12    Validation to force the agent to provide an address when the Brochure is changed from false to true

**/
public class ClientContactDetailsEditController {
    
    public Id accountId {get;set;}
    public Account acc {get;set;}
    public Individual ind {get;set;}
    public boolean hidePage {get;set;}
    //1.1  New Strings to store the original mailing address (on page load)
    public String initialPostCode {get;set;}
    public String initialMailingStreet {get;set;}   
    public String initialMailingCity {get;set;}
    //1.2 Brochure on page load
    public boolean initialBrochure {get;set;}
    public boolean showError {get;set;}
    
    public ClientContactDetailsEditController(){
        
        //Query client account (and related Individual record) using AccountId passed into Url
        accountId = System.currentPagereference().getParameters().get('AccountId');     
        Account[] accs = [Select Id, IsPersonAccount, Phone, PersonMobilePhone, PersonHomePhone, PersonOtherPhone, PersonMailingPostalCode, PersonMailingStreet, PersonMailingAddress,
                          PersonMailingCity,Mailing_State_County__pc, PersonMailingCountry,
                          (Select Id, Data_Audit_Last_Completed__c, Brochure__c, Brochure_Change_Reason__c, Phone__c, Phone_Change_Reason__c, SMS__c, SMS_Change_Reason__c, Weekly_Newsletter__c, 
                           Weekly_Newsletter_Change_Reason__c, Quarterly_Newsletter__c, Quarterly_Newsletter_Change_Reason__c From Individuals__r) 
                          From Account Where Id = :accountId LIMIT 1];
        if(accs.size()>0){
            acc = accs[0];
            //1.1 Set initialMailingAddress
            initialPostCode = acc.PersonMailingPostalCode;
            initialMailingStreet = acc.PersonMailingStreet;
            initialMailingCity = acc.PersonMailingCity;
            if(acc.Individuals__r.size()>0){
                ind = acc.Individuals__r[0];
                initialBrochure = ind.Brochure__c;
                showError = false;
            }else{
                //Hide page contents and display error
                hidePage = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'No Individual record was found for this Client ('+accountId+'). Please contact your system administrator for assistance'));
                showError = true;
            }
        }else{
            //Add a blank Account so the PCA component does not throw an error
            acc = new Account();
            //Hide page contents and display error
            hidePage = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Cannot find the Person Account. Please contact your system administrator for assistance'));
            showError = true;
        }
        
    }
    
    //Save changes to the record
    public PageReference submitChanges(){
        
        //Hide any errors
        showError = false;
        
        //Set the Change_Reason__c values for all Communication Preferences. 
        //If no changes are made to the channel, these values will be cleared on update by the Ind Trigger
        ind.SMS_Change_Reason__c = 'Individual | '+ind.Id+' | '+ApplicationConstant.AGENT_CONSOLE_EDIT;
        ind.Brochure_Change_Reason__c = 'Individual | '+ind.Id+' | '+ApplicationConstant.AGENT_CONSOLE_EDIT;
        ind.Phone_Change_Reason__c = 'Individual | '+ind.Id+' | '+ApplicationConstant.AGENT_CONSOLE_EDIT;
        ind.Weekly_Newsletter_Change_Reason__c = 'Individual | '+ind.Id+' | '+ApplicationConstant.AGENT_CONSOLE_EDIT;
        ind.Quarterly_Newsletter_Change_Reason__c = 'Individual | '+ind.Id+' | '+ApplicationConstant.AGENT_CONSOLE_EDIT;
        
        //Set Audit Date to today
        ind.Data_Audit_Last_Completed__c = system.today();
        
        //1.1 If the initial mailing address is changed, replicate changes to the Billing Address 
        if(acc.PersonMailingPostalCode != initialPostCode || acc.PersonMailingStreet != initialMailingStreet || acc.PersonMailingCity != initialMailingCity ){
            //Set Billing Address
            acc.BillingStreet = acc.PersonMailingStreet;
            acc.BillingCity = acc.PersonMailingCity;
            acc.BillingCountry = acc.PersonMailingCountry;
            acc.BillingPostalCode = acc.PersonMailingPostalCode;
            acc.Billing_State_County__c = acc.Mailing_State_County__pc;
            
        }
        
        //1.2 If Brochure has been selected and the address is blank, display error
        if(initialBrochure == false && ind.Brochure__c == true && (acc.PersonMailingPostalCode == null || acc.PersonMailingStreet == null)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You must provide a valid mailing address when signing the Client up to the Brochure. If you do not have a valid mailing address for the Client, please untick the Brochure subscription and proceed to save'));
            showError = true;
            return null;
        }
        
        //update Account
        try{
            update acc;
        }catch(exception e){
            String error = e.getMessage();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,error));
            showError = true;
            return null;
        }
        //update Individual
        try{
            update ind;
        }catch(exception e){
            String error = e.getMessage();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,error));
            showError = true;
            return null;
        }        
        
        system.debug('Show Error: '+showError);
        return null;
        
    }
    
    
    //Save changes to the record
    public PageReference setAuditCompletionDate(){
        
        //Requery the record to ensure no values are committed
        Individual IndToUpdate = [Select Id, Data_Audit_Last_Completed__c From Individual Where Id =:ind.Id LIMIT 1][0];
        
        //Set Audit Date to today
        IndToUpdate.Data_Audit_Last_Completed__c = system.today();
        
        //update Individual
        try{
            update IndToUpdate;
        }catch(exception e){
            String error = e.getMessage();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,error));
        }
        
        return null;
        
    }    
    
}