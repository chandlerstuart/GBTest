/**
Name:  AP22_ExpectedPaymentAdminCaseBatch_TEST.cls
Copyright © 2016  GolfBreaks Offshore
======================================================
======================================================
Purpose:
-------
Test class for AP22_ExpectedPaymentAdminCaseBatch.cls
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Atlee      2016-05-03  Initial development.
**/
@isTest
public class AP22_ExpectedPaymentAdminCaseBatch_TEST{
    @testSetup static void setupData(){
        //Create Account
        Account acc = AP23_TestDataFactory.createAccount(1)[0];
        insert acc;
        
        //Create Opportunity
        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, '1. Recommendations', acc)[0];
        insert opp;
        
        //Create Bookings
        List<Booking__c> lBook = AP23_TestDataFactory.createBooking(1, acc, opp.Id);
        for(Booking__c bk: lBook){
            bk.TransferDetailsRequired__c = TRUE;
            bk.AmountPaid__c = 50;
            bk.TECH_Opportunity__c = opp.Id;
            bk.Status__c = 'Booking';
            bk.Travel_Date__c  = System.Today();
            bk.Nights__c = 10;
        }
        insert lBook;
        
        //Create Expected Payments
        Integer bkNum = 4;
        List<Expected_Payment__c> lEP = AP23_TestDataFactory.createExpectedPayment(bkNum, lBook[0], '', 100); 
        for(Integer i = 0; i < bkNum; i++){
            if(i == 0){
                lEP[i].ExpectedPaymentType__c = ApplicationConstant.EPAYMENTTYPEPARTIALDEPOSIT;
                lEP[i].Expected_Payment_Date__c = System.Today();
            }
            
            if(i == 1){
                lEP[i].ExpectedPaymentType__c = ApplicationConstant.EPAYMENTTYPEFULLDEPOSIT;
                lEP[i].Expected_Payment_Date__c = System.Today();
            }
            
            if(i == 2){
                lEP[i].ExpectedPaymentType__c = ApplicationConstant.EPAYMENTTYPEFULLBALANCE;
                lEP[i].Expected_Payment_Date__c = System.Today();
            }
            
            if(i == 3){
                lEP[i].ExpectedPaymentType__c = ApplicationConstant.EPAYMENTTYPEFULLBALANCE;
                lEP[i].Expected_Payment_Date__c = System.Today();
            }
        }
        insert lEP;
        

       
    }
       
    static testMethod void ExecuteMultiple(){
        //Query Acc and Opp
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Booking__c bkg = [SELECT Id FROM Booking__c LIMIT 1];
        List<Case> lCase = AP23_TestDataFactory.createCase(200, acc.Id, bkg.Id);
        for(Case cas: lCase){       
            cas.Origin = 'Email';
            cas.Status = 'New';
            cas.Type = ApplicationConstant.CASETYPE_ADMIN;
            cas.Category__c = 'Q- Portal/Personal Account';
            cas.SubCategory__c = 'Break Points';
            cas.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Case').getRecordTypeId(); 
        }
        insert lCase;
               
        Test.startTest();
        Database.executeBatch(new AP22_ExpectedPaymentAdminCaseBatch());  
        Test.stopTest();

        List<Case> lCaseUpd = [SELECT Id, TaskType__c FROM Case WHERE Id=: lCase[0].Id];
        System.AssertEquals(lCaseUpd[0].TaskType__c, 'Payment');
    }
   
    static testMethod void ExecuteError(){
        //Query Acc and Opp
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Booking__c bkg = [SELECT Id FROM Booking__c LIMIT 1];
        //Create Case
        Case cas = AP23_TestDataFactory.createCase(1, acc.Id, bkg.Id)[0];
        cas.Origin = 'Email';
        cas.Status = '1234567891123456789112345678911234567891';
        cas.Type = ApplicationConstant.CASETYPE_ADMIN;
        cas.Category__c = 'Q- Portal/Personal Account';
        cas.SubCategory__c = 'Break Points';
        cas.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Case').getRecordTypeId(); 
        cas.TaskType__c = ApplicationConstant.CASETASKTYPE_CUSTOMER;
        insert cas;
        
        //Create Tasks
        List<Task> lTask = AP23_TestDataFactory.createTask(1, cas);
        lTask[0].Subject = ApplicationConstant.GETINITIALDEPOSIT;
        insert lTask;
        
        Test.startTest();
        Database.executeBatch(new AP22_ExpectedPaymentAdminCaseBatch());  
        Test.stopTest();
        List<Task> lTaskNew = [SELECT Id FROM Task LIMIT 1];
        System.AssertEquals(1, lTaskNew.size());      
    }
    
    

    static testMethod void ExecuteBatchCaseTaskTypeNull(){
        //Query Acc and Opp
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Booking__c bkg = [SELECT Id FROM Booking__c LIMIT 1];
        //Create Case
        Case cas = AP23_TestDataFactory.createCase(1, acc.Id, bkg.Id)[0];
        cas.Origin = 'Email';
        cas.Status = 'New';
        cas.Type = ApplicationConstant.CASETYPE_ADMIN;
        cas.Category__c = 'Q- Portal/Personal Account';
        cas.SubCategory__c = 'Break Points';
        cas.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Case').getRecordTypeId(); 
        insert cas;
        
        Test.startTest();
        Database.executeBatch(new AP22_ExpectedPaymentAdminCaseBatch());  
        Test.stopTest();
        List<Case> lCase = [SELECT Id, TaskType__c FROM Case WHERE Id=: cas.Id];
        System.AssertEquals(lCase[0].TaskType__c, 'Payment');
    }


    static testMethod void ExecuteBatchCaseTask(){
        //Query Acc and Opp
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Booking__c bkg = [SELECT Id FROM Booking__c LIMIT 1];
        //Create Case
        Case cas = AP23_TestDataFactory.createCase(1, acc.Id, bkg.Id)[0];
        cas.Origin = 'Email';
        cas.Status = 'New';
        cas.Type = ApplicationConstant.CASETYPE_ADMIN;
        cas.Category__c = 'Q- Portal/Personal Account';
        cas.SubCategory__c = 'Break Points';
        cas.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Case').getRecordTypeId(); 
        cas.TaskType__c = ApplicationConstant.CASETASKTYPE_CUSTOMER;
        insert cas;
        
        //Create Tasks
        List<Task> lTask = AP23_TestDataFactory.createTask(1, cas);
        lTask[0].Subject = ApplicationConstant.GETINITIALDEPOSIT;
        insert lTask;
        
        Test.startTest();
        Database.executeBatch(new AP22_ExpectedPaymentAdminCaseBatch());  
        Test.stopTest();
        List<Task> lTaskNew = [SELECT Id FROM Task LIMIT 1];
        System.AssertEquals(1, lTaskNew.size());      
    }

    static testMethod void MultipleExistingTasks(){
        //Query Acc and Opp
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Booking__c bkg = [SELECT Id FROM Booking__c LIMIT 1];
        //Create Case
        Case cas = AP23_TestDataFactory.createCase(1, acc.Id, bkg.Id)[0];
        cas.Origin = 'Email';
        cas.Status = 'New';
        cas.Type = ApplicationConstant.CASETYPE_ADMIN;
        cas.Category__c = 'Q- Portal/Personal Account';
        cas.SubCategory__c = 'Break Points';
        cas.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Case').getRecordTypeId(); 
        cas.TaskType__c = ApplicationConstant.CASETASKTYPE_CUSTOMER;
        insert cas;
        
        //Create Tasks
        List<Task> lTask = AP23_TestDataFactory.createTask(5, cas);
        lTask[0].Subject = ApplicationConstant.GETINITIALDEPOSIT;
        lTask[1].Subject = ApplicationConstant.GETDEPOSITBALANCE;
        lTask[2].Subject = ApplicationConstant.GETFINALBALANCE;
        lTask[3].Subject = ApplicationConstant.TASKSUBJ_GETTRANSFER;
        lTask[4].Subject = ApplicationConstant.TASKSUBJ_GETROOMING;       
        insert lTask;
        
        Test.startTest();
        Database.executeBatch(new AP22_ExpectedPaymentAdminCaseBatch());  
        Test.stopTest();
        List<Task> lTaskNew = [SELECT Id FROM Task];
        System.AssertEquals(5, lTaskNew.size());      
    }
 

    static testMethod void BookingIdTest(){
        AssignmentRule AR = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
        System.debug('AR: ' +AR);

        //Query Acc and Opp
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Booking__c bkg = [SELECT Id FROM Booking__c LIMIT 1];
        //Create Case
        Case cas = AP23_TestDataFactory.createCase(1, acc.Id, bkg.Id)[0];
        cas.Origin = 'Email';
        cas.Status = 'New';
        cas.Type = 'Internal';
        cas.Category__c = 'Q- Portal/Personal Account';
        cas.SubCategory__c = 'Break Points';
        cas.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Case').getRecordTypeId(); 
        insert cas;
        
        Test.startTest();
        Database.executeBatch(new AP22_ExpectedPaymentAdminCaseBatch());  
        Test.stopTest();
        List<Case> lCase = [SELECT Id FROM Case WHERE Id=: cas.Id];
        System.AssertEquals(lCase.size(), 1);
        List<Task> lTaskNew = [SELECT Id FROM Task LIMIT 1];
        System.AssertEquals(1, lTaskNew.size());   
    }  

    static testMethod void PaymentZero(){
        //Query Acc and Opp
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Booking__c bkg = [SELECT Id FROM Booking__c LIMIT 1];
        List<Expected_Payment__c> lEP = [SELECT Id, Name, Booking__c, Booking__r.TECH_Opportunity__r.StageName, Booking__r.TECH_Opportunity__r.OwnerId, Booking__r.Account__c, Booking__r.Account__r.PersonContactId, Expected_Amount__c, Outstanding_Balance__c, Expected_Payment_Date__c, ExpectedPaymentType__c FROM Expected_Payment__c];
        for(Expected_Payment__c ep: lEP){
            if(ep.ExpectedPaymentType__c == ApplicationConstant.EPAYMENTTYPEPARTIALDEPOSIT){
                ep.Expected_Payment_Date__c = System.Today()+1;    
            }
            
            if(ep.ExpectedPaymentType__c == ApplicationConstant.EPAYMENTTYPEFULLDEPOSIT){
                ep.Expected_Payment_Date__c = System.Today()+1;    
            }
            
            if(ep.ExpectedPaymentType__c == ApplicationConstant.EPAYMENTTYPEFULLBALANCE){
                ep.Expected_Payment_Date__c = System.Today()+1;    
            }          
        }
        update lEP;
        
        Expected_Payment__c EPUpd = [SELECT Id, Expected_Amount__c, ExpectedPaymentType__c FROM Expected_Payment__c WHERE ExpectedPaymentType__c =: ApplicationConstant.EPAYMENTTYPEFULLBALANCE LIMIT 1];
        EPUpd.Expected_Amount__c = 25;
        EPUpd.Expected_Payment_Date__c = System.Today();
        update EPUpd;
        
        List<Case> lCase = AP23_TestDataFactory.createCase(1, acc.Id, bkg.Id);
        for(Case cas: lCase){       
            cas.Origin = 'Email';
            cas.Status = 'New';
            cas.Type = ApplicationConstant.CASETYPE_ADMIN;
            cas.Category__c = 'Q- Portal/Personal Account';
            cas.SubCategory__c = 'Break Points';
            cas.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Case').getRecordTypeId(); 
        }
        insert lCase;
               
        Test.startTest();
        Database.executeBatch(new AP22_ExpectedPaymentAdminCaseBatch());  
        Test.stopTest();
        List<Case> lCaseUpd = [SELECT Id, TaskType__c FROM Case WHERE Id=: lCase[0].Id];
        System.assertEquals(null, lCaseUpd[0].TaskType__c);

    } 
}