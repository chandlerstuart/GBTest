/**
   @Author: MaJoy Maliñana
   @name: VFC03_OpportunityHighlightsPanelCtrl
   @CreateDate: 02.18.2016
   @Description: Class for highlights panel for Opportunity Console layout.
   @Version <1.0>
   @Edited by: Karen Joy Sarandin 03/04/2016
   @Description: Code clean-up, code must be development In Progress.
**/
public with sharing class VFC03_OpportunityHighlightsPanelCtrl{
    
    public String name{get; set;}
    public Opportunity opportunityRec {get; set;}
    public Boolean checkAlertForCase{get;set;}
    
    public VFC03_OpportunityHighlightsPanelCtrl(ApexPages.StandardController stdController){ 
            this.opportunityRec = (Opportunity)stdController.getRecord();
            
    }
    
    public Account getAccountDetails(){
        Account accountRec = new Account();
        try{
            accountRec = [SELECT Id, Name, PersonMobilePhone, 
                                 PersonEmail, PersonHomePhone, Phone, 
                                 BreakpointsMember__c, Loyalty__c, Advocate__c, 
                                 PersonContactId, CustomerLifetimeValue__c, BreakpointsAmountAvailable__c, 
                                 BreakpointsAmountPending__c,  NewsletterSignUp__c, CustomerSatisfactionStatus__c,
                                 MemberNumber__c, Is_PGA__pc ,Is_VIP__pc 
                          FROM Account 
                          WHERE id =: opportunityRec.AccountId];
        } catch(Exception e){
            System.debug('The following exception has occurred: ' + e.getMessage());
            accountRec = null;
        }  
        return accountRec;
    }
    
    public Lead getLeadDetails(){
        Lead leadRec = new Lead();
        try{
            leadRec = [SELECT Id, name, email, MobilePhone, Phone,  HomePhone__c
                          FROM Lead
                          WHERE id =: opportunityRec.AccountId];
        } catch(Exception e){
            System.debug('The following exception has occurred: ' + e.getMessage());
            leadRec = null;
        }  
        return leadRec;
    }
    public List<Booking__c> getBooking(){
        List<Booking__c> bookingList = new List<Booking__c>();
        try{
            bookingList = [SELECT id, name, Travel_Date__c, Country__c
                           FROM Booking__c
                           WHERE Account__c =: opportunityRec.AccountId ORDER BY CreatedDate DESC LIMIT 3];
        } catch(Exception e){
            System.debug('The following exception has occurred: ' + e.getMessage());
            bookingList = null;
        } 
        return bookingList;
    } 
    
    public PageReference save() {
        update opportunityRec;
        return null;   
    }   
}