/**
   @Author: MaJoy Maliñana
   @name: VFC02_LeadHighlightsPanelCtrl
   @CreateDate: 02.29.2016
   @Description: Class for highlights panel for Lead Console layout.
   @Version <1.0>
   @Edited by: Karen Joy Sarandin 03/04/2016
   @Description: Code clean-up, code must be development In Progress.
**/
public with sharing class VFC02_LeadHighlightsPanelCtrl{
    public String name{get; set;}
    public Lead leadRec{get; set;}
    public Boolean checkAlertForCase{get;set;}
    public Lead thisLead;
    
    public VFC02_LeadHighlightsPanelCtrl(ApexPages.StandardController stdController){
        //May 10, 2016 - Merari Cebrian - Added else statement and updated if condition from if(this.LeadRec != null){ to if(this.LeadRec.Id != null){
        this.leadRec= (Lead)stdController.getRecord();
        if(this.LeadRec.Id != null){
            thisLead = [Select Id, Account__c from Lead where Id = :this.leadRec.Id];
            queryLeadwithAccountAndCase();
        }
        else{
            thisLead = new Lead();
        }
    }
    
    public Account getAccount(){
        Account accountRec = new Account();
        
        try{
            accountRec = [SELECT Id, Name, TECH_ClientTypeBadge__c, 
                                PersonEmail, BreakpointsMember__c , Loyalty__c, 
                                Advocate__c, PersonContactId, CustomerLifetimeValue__c, 
                                BreakpointsAmountAvailable__c, BreakpointsAmountPending__c,  NewsletterSignUp__c, 
                                CustomerSatisfactionStatus__c, MemberNumber__c, Is_PGA__pc ,Is_VIP__pc 
                          FROM Account 
                          WHERE id =: thisLead.Account__c];
            
        } catch(Exception e){
            System.debug('The following exception has occurred in accountRec: ' + e.getMessage());
            accountRec = null;
        }
        return accountRec;
    }
    
public void queryLeadwithAccountAndCase(){
    
    List<Lead> LeadAcc = new List<Lead>([Select Id, Account__c from Lead where Id =: this.leadRec.Id]);
  
    //setLeadAcc.addAll(LeadAcc.Id);
    Set<Id> setLeadAcc = new Set<Id>();
    for(Lead lc : LeadAcc){
        setLeadAcc.add(lc.Account__c);
    }
    
    List<Case> AccountCase = new List<Case>([Select Id from Case where AccountId IN : setLeadAcc AND Status != 'Closed']);
    
    if(AccountCase.size() > 0){
        //set to true
        checkAlertForCase = true;
    }
    else{
        checkAlertForCase = false;
    }
}    
    
    public List<Booking__c> getBooking(){
        List<Booking__c> bookingList = new List<Booking__c>();
        try{
            bookingList = [SELECT id, name, Travel_Date__c, Country__c
                           FROM Booking__c
                           WHERE Account__c =: leadRec.Account__c ORDER BY CreatedDate DESC LIMIT 3];
        } catch(Exception e){
            System.debug('The following exception has occurred in bookingList: ' + e.getMessage());
            bookingList = null;
        }
        return bookingList;
    }
    
    public PageReference save() {
        update leadRec;
        queryLeadwithAccountAndCase();
        return null; 
    } 
}