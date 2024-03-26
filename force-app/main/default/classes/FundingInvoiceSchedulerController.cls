/*
Name:  FundingInvoiceSchedulerController.cls
======================================================
======================================================
Purpose:
-------
Controller for FundingInvoiceScheduler Visualforce Page

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  M Paddeo      2019-11-20  Initial development
1.1  J Radcliffe   2021-12-14  Bug Fix - Default orderAmount
*/
public with sharing class FundingInvoiceSchedulerController {
    
    public Id OrderId {get; set;}
    public double orderAmount {get; set;}
    public boolean amountProvided {get; set;}
    public boolean stageIsDefinite {get; set;}
    public boolean orderIsNotCombi {get; set;}
    public integer listSize {get; set;}
    public boolean showPageBlock {get; set;}
    public boolean mainEditMode {get; set;}
    public boolean mainNewMode {get; set;}
    public FundingOrder__c parentOrder {get; set;}
    public List<InvWrapper> invWrappers {
        get {
            if (null == invWrappers) invWrappers = new List<InvWrapper>();
            return invWrappers;
        }
        set;
    }    
    //This method is called by the constructor. It builds a list of Invoice Wrappers (one for every Co-op Invoice record) and sets 'editMode' to false.
    public void initMethod(Id OppId){
        
        parentOrder = [select Id, OrderStage__c, CurrencyIsoCode, Name, OrderAmount__c, Supplier__c, ParentOrder__c,
                     (SELECT Id, Supplier_Sage_Code__c, Invoice_Number__c,  Name, CurrencyIsoCode, FundingOrder__c, FundingOrder__r.AccountId__r.Supplier__c, Amount__c, Invoice_Date__c, 
                      Invoice_Type__c, In_Sage__c, Click_To_View__c, Stage__c, Supplier_Account__c, Supplier_Account__r.Name, Deduct_From__c, 
                      Deduct_From__r.Name, Invoice_Details__c, PO_Number__c FROM Co_op_Invoices__r) 
                     from FundingOrder__c where Id = :OrderId];
        
        //Users are not allowed to insert Co-op Invoice records if the Order is child of a Combi Order.
        if(parentOrder.ParentOrder__c == null){ 
            orderIsNotCombi = true;
        }else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'This is part of a Combi Order. Invoices can only be created on the Parent Order.'));
        } 
        
        //Users are not allowed to insert Co-op Invoice records until the Order amount has been defined (reflected in the Amount picklist field). If none is selected the error should be presented
        if(parentOrder.OrderAmount__c != null){
            amountProvided = true;
        }else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'The Order Amount must be specified before invoice details can be provided.'));
        }
        
        orderAmount = 0;//1.1+            
        //Retrieve the correct Order Amount and assign to the 'orderAmount' variable
        if(parentOrder.OrderAmount__c != null && parentOrder.OrderAmount__c != 0){
            orderAmount = parentOrder.OrderAmount__c;
        }
              
        Map<Id,Co_op_Invoice__c> coopInvs = new Map<Id,Co_op_Invoice__c>(parentOrder.Co_op_Invoices__r);
        Map<Id,date> invoicesWithLatestActivityDate = new Map<Id,date>();
        Set<Id> invIds = new Set<Id>();
        
        //Query all the completed Tasks and loop through to identify the latest completed Task per invoice
        Task[] invoiceTasks = [SELECT Id, WhatId, ActivityDate, Status FROM Task WHERE Status = 'Completed' AND WhatId In:coopInvs.keyset() ORDER BY ActivityDate DESC ];
        for(Task t : invoiceTasks){
            if(!invIds.contains(t.WhatId)){
                invoicesWithLatestActivityDate.put(t.WhatId,t.ActivityDate);
                invIds.add(t.WhatId);
            }
        }
        
        
        //Loop through the retrieved list of invoices for the Order and build a wrapper for each Co-op Invoice record. Set to 'read only'
        for(Co_op_Invoice__c i : coopInvs.Values()){
            InvWrapper wrap = new InvWrapper();
            wrap.inv = i;
            wrap.editMode = false;
            wrap.isNew = false;
            wrap.isSelected = false;
            wrap.latestActivity = invoicesWithLatestActivityDate.get(i.Id);
            invWrappers.add(wrap);
        }
        
        //Set the size of the wrapper list to determine whether the 'edit'/'remove all' buttons are displayed on the page
        listSize = invWrappers.size();
        
        mainEditMode = false;
        mainNewMode = false;
        
    }
    
    //This method is the page constructor
    public FundingInvoiceSchedulerController(ApexPages.StandardController controller) {
        
        OrderId = controller.getRecord().Id;
        system.debug('*** -- OrderId = ' + OrderId + ' -- ***');
        
        initMethod(OrderId);
        
    }
    

    
    //New Class 'InvWrapper'. Each InvWrapper is a Co-op Invoice record with additional variables indicating it's state (edit/new/selected)
    @TestVisible public Class InvWrapper{
        
        public Co_op_Invoice__c inv {get;set;}
        public boolean editMode {get; set;}
        public boolean isNew {get; set;}
        public boolean isSelected {get; set;}
        public date latestActivity {get; set;}
        
    }
    
    //This method loops through each wrapper and sets all existing wrappers to edit mode
    public PageReference setToEditMode(){
        
        mainEditMode = true;
        
        for(invWrapper inv : invWrappers){
            inv.editMode = true;
        }
        return null;
    }
    
    //This method adds a new wrapper entry into the InvWrappers List and sets the page and wrappers to edit mode
    public PageReference createNewWrapper(){        
        
        mainEditMode = true;
        mainNewMode = true;
        
        for(invWrapper i : invWrappers){
            i.editMode = true;
        }
        
        try {
            InvWrapper wrap = new InvWrapper();
            wrap.inv = new Co_op_Invoice__c(FundingOrder__c = OrderId);
            wrap.inv.Stage__c = 'To Be Invoiced';
            wrap.inv.CurrencyIsoCode = parentOrder.CurrencyIsoCode;
            wrap.editMode = true;
            wrap.isNew = true;
            invWrappers.add(wrap);  
            
            system.debug('**Count of Wrapper:'+invWrappers.size());
        }catch (Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,e.getMessage()));
        }
        
        //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'THIS WORKED'));
            
        return null;
    } 
    
    //This method clears the wrapper list and calls the constructor method to rebuild the wrapper list based on existing records
    public PageReference cancel(){
              
        invWrappers = null; 
        initMethod(OrderId);
        
        return null;
    }
    
    //This method checks to ensure the total amount matches the orderAmount variable, upserts all invoice records entered by the user and renders the list read only. If the totals do not match an error is presented
    public PageReference saveInvoices(){
        List<Co_op_Invoice__c> coInvs = new List<Co_op_Invoice__c >();
        double invoiceTotal = 0;
        for(invWrapper inv : invWrappers){
            coInvs.add(inv.inv);
            if (inv.inv.Supplier_Account__c == null){ 
                inv.inv.Supplier_Account__c = parentOrder.Supplier__c;
            }
            if(inv.inv.Amount__c != null){
            invoiceTotal += inv.inv.Amount__c;
            }
        } 
        system.debug('Invoice Total ='+invoiceTotal);
        system.debug('Order Amount ='+orderAmount);
        
        if(invoiceTotal != orderAmount){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'The Total Invoice Amount ('+invoiceTotal+') does not match the Order Amount ('+orderAmount+')'));
            return null;
        }
        
        for(invWrapper inv : invWrappers){
            inv.editMode = false;
            inv.isNew = false;
        }
        
        mainEditMode = false;
        mainNewMode = false;
        listSize = invWrappers.size();
        
        try{
            upsert coInvs;
        }
        catch(Exception ex){
        mainEditMode = true;
        for(invWrapper inv : invWrappers){
            inv.editMode = true;
        }            
            ApexPages.addMessages(ex);
            system.debug(ex);
        }        
        return null;
    }
    
    //This method deletes all Co-op Invoice records and clears the wrapper list
    public PageReference removeAll(){
        if(ParentOrder.OrderStage__c =='Definite'){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Records cannot be removed whilst the Order is at Stage "Definite". If you wish to remove all invoice records, please update the Order Stage'));
            return null;
        }
        List<Co_op_Invoice__c> allInvs = new List<Co_op_Invoice__c >();
        for(invWrapper inv : invWrappers){
            allInvs.add(inv.inv);
        }
        delete allInvs;
        invWrappers = null;
        listSize = 0;
        return null;
    }
}