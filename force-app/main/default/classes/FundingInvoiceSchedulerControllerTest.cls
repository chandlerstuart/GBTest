/**************************************************************
@author - Marta Paddeo (Golfbreaks)
@date - 10/12/2019
@description - Test class for FundingInvoiceSchedulerController
***************************************************************/
@isTest
private class FundingInvoiceSchedulerControllerTest {
    
    //This method builds the source data: 1 Opp Account, 1 Alternative Supplier Account, 1 Funding Order, 1 Coop Invoice and 2 Tasks.
    @testSetup
    public static void setup() {
        Map<String, RecordType> rtMap = new Map<String, RecordType>();
        for (RecordType r : [select Id, DeveloperName from RecordType where IsActive = TRUE and 
                             SObjectType = 'Account']){
                                 
                                 rtMap.put(r.DeveloperName, r);
                             }
        
        List<Account> newAccs = new List<Account>();
        
        Account acc1 = new Account();
        acc1.Name = 'Main Account';
        acc1.RecordTypeId = rtMap.get('Supplier').Id;
        newAccs.add(acc1);
        
        Account acc2 = new Account();
        acc2.Name = 'Alternative Supplier Account';
        acc2.RecordTypeId = rtMap.get('Venue').Id;
        newAccs.add(acc2);
        
        insert newAccs;
        
        Contact con = new Contact();
        con.FirstName = 'Test';
        con.LastName = 'Contact';
        con.AccountId = [select Id from Account where Name = 'Main Account'].Id;
        insert con;
        
        
        FundingOrder__c fo = new FundingOrder__c();
        fo.Name = 'Test Funding Order';
        fo.AccountId__c = [select Id from Account where Name = 'Main Account'].Id;
        fo.RecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Brochure' LIMIT 1];
        fo.OrderStage__c = 'Prospecting';
        fo.PrimaryContact__c = con.Id;
        fo.Type__c = 'Fixed';
        fo.StartDate__c = System.Today();   
        fo.EndDate__c = System.today() + 365;
        fo.OrderAmount__c = 15000;
        
        
        insert fo;
        
        Co_op_Invoice__c inv = new Co_op_Invoice__c();
        inv.FundingOrder__c = fo.Id;
        inv.Amount__c = decimal.valueOf(100);
        inv.Invoice_Date__c = system.today();
        inv.Supplier_Account__c = [select Id from Account where Name = 'Main Account'].Id;
        inv.Invoice_Type__c = 'Invoice Cash';
        inv.Stage__c = 'To Be Invoiced';
        insert inv;
        
        Task t1 = new Task();
        t1.ActivityDate = system.Today()-10;
        t1.Status = 'Completed';
        t1.WhatId = inv.Id;
        
        insert t1;
        
        Task t2 = new Task();
        t2.ActivityDate = system.Today();
        t2.Status = 'Completed';
        t2.WhatId = inv.Id;
        
        insert t2;        
        
    }
    
    //This method executes the controller and asserts that the correct number of invoices (1) are returned and the LatestActivity is stamped with the ActivityDate of the most recently completed Task.
    static testMethod void testConstructorMethod() {

        FundingOrder__c fundOrd = [select Id, OrderAmount__c, AccountId__c from FundingOrder__c LIMIT 1];  
        
                
        ApexPages.StandardController std = new ApexPages.StandardController(fundOrd);      
        
        test.startTest();
          
            FundingInvoiceSchedulerController controller = new FundingInvoiceSchedulerController(std);

        test.stopTest();

        Task latestTask = [SELECT Id, ActivityDate FROM Task WHERE Status = 'Completed' ORDER BY ActivityDate Desc LIMIT 1];

        system.assertequals(1,controller.invWrappers.size());   
        
        system.assertEquals(controller.invWrappers[0].latestActivity, latestTask.ActivityDate);
        
    }
    
    //This method adds a new wrapper entry and then saves. It asserts that a new CoopInvoice has been created and that, because the Supplier Account has been left blank, the Supplier has defaulted to 'Invoicing Supplier' or the Opportunity.
    static testMethod void testCreateAndSave() {     

        FundingOrder__c fundOrd = [select Id, OrderAmount__c, AccountId__c from FundingOrder__c LIMIT 1];
        
        ApexPages.StandardController std = new ApexPages.StandardController(fundOrd);
        
        test.startTest();
        
            FundingInvoiceSchedulerController controller = new FundingInvoiceSchedulerController(std);        
            system.assertequals(1,controller.invWrappers.size());   
            
            controller.createNewWrapper();
            controller.invWrappers[1].inv.Amount__c = 100;
            controller.invWrappers[1].inv.Invoice_Date__c = system.Today().addMonths(1);
            controller.invWrappers[1].inv.Invoice_Type__c = 'Invoice Cash';
            controller.invWrappers[1].inv.Stage__c = 'To Be Invoiced';
            
            system.assertequals(2,controller.invWrappers.size());
            
            controller.saveInvoices();
        
        test.stopTest();
        
        Co_op_Invoice__c[] coInvs = [select Id, Supplier_Account__c  from Co_op_Invoice__c];
        
        system.assertEquals(1,coInvs.size());
        
        //if the supplier is left blank, check to ensure it is updared to the 'Invoicing Supplier' on the related Opp
        for(Co_op_Invoice__c i : coInvs){
            system.assertEquals(i.Supplier_Account__c, fundOrd.AccountId__c);
        }
        
    }
    
    //This method ensures the wrapper list is set to 'edit mode',  and asserts that both the wrappers and Invoices are deleted when 'Remove All' is selected.
    static testMethod void testEditAndRemoveAll(){

        FundingOrder__c fundOrd = [select Id, OrderAmount__c, AccountId__c from FundingOrder__c LIMIT 1];
        
        ApexPages.StandardController std = new ApexPages.StandardController(fundOrd);      
        
        test.startTest();
            FundingInvoiceSchedulerController controller = new FundingInvoiceSchedulerController(std);       
            system.assertequals(1,controller.invWrappers.size());   
            
            controller.setToEditMode();
            Id supplierAccountId = [SELECT Id FROM Account WHERE Name = 'Main Account' LIMIT 1].Id;
            
            for(FundingInvoiceSchedulerController.InvWrapper i : controller.invWrappers){
                system.assertEquals(true,i.editMode);
                i.inv.Supplier_Account__c = supplierAccountId;
            }       
            controller.saveInvoices();
            
            
            List<Co_Op_Invoice__c> invoices = [SELECT Id, Supplier_Account__c FROM Co_op_Invoice__c];
            for(Co_Op_Invoice__c ci : invoices){
                system.assertEquals(supplierAccountId,ci.Supplier_Account__c);
            }
            
            controller.removeAll();
        test.stopTest();
        
        List<Co_Op_Invoice__c> allInvoices = [SELECT Id, Supplier_Account__c FROM Co_op_Invoice__c];
        system.assertEquals(0, allInvoices.size());
        system.assertEquals(0, controller.invWrappers.size());             
    }
    
    //This methods creates a wrapper entry and then cancels. Asserts that the entry has been removed and that the wrappers are no longer in edit mode
    static testMethod void testAddAndCancel(){
        
        FundingOrder__c fundOrd = [select Id, OrderAmount__c, AccountId__c from FundingOrder__c LIMIT 1];
        
        ApexPages.StandardController std = new ApexPages.StandardController(fundOrd);      
        
        test.startTest();
            FundingInvoiceSchedulerController controller = new FundingInvoiceSchedulerController(std);       
            system.assertequals(1,controller.invWrappers.size()); 
            
            controller.createNewWrapper();
            system.assertequals(2,controller.invWrappers.size());      
            
            for(FundingInvoiceSchedulerController.InvWrapper wrap : controller.invWrappers){
                system.assertEquals(true,wrap.editMode);
            }
            
            controller.cancel();
        test.stopTest();
        system.assertequals(1,controller.invWrappers.size());    
        
        for(FundingInvoiceSchedulerController.InvWrapper wrap : controller.invWrappers){
            system.assertEquals(false,wrap.editMode);
        }      
    }
    
}