/**
Name:  ClientContactDetailsEditControllerTest.cls
======================================================
======================================================
Purpose:
-------
Test Class for ClientContactDetailsEditController
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail 
1.0  JRadcliffe   2018-04-27    Initial Development
1.1  JRadcliffe   2018-05-22	Testing the Billing Address is updated when the Mailing Address is changed
1.2  JRadcliffe   2018-06-12    Testing Brochure/Address Validation

**/
@isTest
public class ClientContactDetailsEditControllerTest {
    
    @testSetup static void createTestData(){
        
        //Make sure we have org settings created
        //Allow the current running test user to insert Client accounts
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings; 
        
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        
        //Create test Client Account
        Account newAcc = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert newAcc;
        
        //Requery account (after insert)
        Account acc = [Select Id, LastName, PersonIndividualId, PersonMobilePhone, PersonHomePhone, PersonOtherPhone, Phone,
                       (Select Id, Brochure__c, Phone__c, SMS__c, Weekly_Newsletter__c, Quarterly_Newsletter__c From Individuals__r) 
                       From Account Where Id = :newAcc.Id];
        
        //If no Individual record is implicitely created, create an individual and link to Account
        if(acc.PersonIndividualId == null && acc.Individuals__r.size()== 0){
            Individual i = new Individual();
            i.LastName = acc.LastName;
            i.Account__c = acc.Id;
            i.Brochure__c = false;
            i.SMS__c = false;
            i.Phone__c = false;
            i.Weekly_Newsletter__c = false;
            i.Quarterly_Newsletter__c = false;
            insert i;
        }else{
            //confirm the initially created individual is currently unsubscribed to all channels, otherwise unsubscribe
            Individual i2 = acc.Individuals__r[0];
            boolean updateRequired = false;
            if(i2.Brochure__c){
                i2.Brochure__c = false;
                updateRequired = true;
            }
            if(i2.SMS__c){
                i2.SMS__c = false;
                updateRequired = true;
            }
            if(i2.Phone__c){
                i2.Phone__c = false;
                updateRequired = true;
            }
            if(i2.Weekly_Newsletter__c){
                i2.Weekly_Newsletter__c = false;
                updateRequired = true;
            }
            if(i2.Quarterly_Newsletter__c){
                i2.Quarterly_Newsletter__c = false;
                updateRequired = true;
            }
            //If required, update the Individual
            if(updateRequired){
                update i2;
            }
            
        }
        
    }
    
    //submitChanges Test
    @isTest static void submitChangesTest(){
        
        //Query client Account
        Account[] accs = [Select Id, LastName, PersonIndividualId, PersonMobilePhone, PersonHomePhone, PersonOtherPhone, Phone,
                          (Select Id, Brochure__c, Phone__c, SMS__c, Weekly_Newsletter__c, Quarterly_Newsletter__c From Individuals__r) 
                          From Account];
        system.assertEquals(1,accs.size());
        Account acc = accs[0];
        
        //Instanstiate ClientContactDetailsEditController and set parameters
        
        Test.setCurrentPage(Page.ClientContactDetailsEdit);				        
        ApexPages.currentPage().getParameters().put('AccountId', accs[0].Id);                
        
        //Instantiate Controller
        ClientContactDetailsEditController controller = new ClientContactDetailsEditController();
        
        //Subscribe client to all channels
        controller.ind.Phone__c = true;
        controller.ind.Brochure__c = true;
        controller.ind.Weekly_Newsletter__c = true;
        controller.ind.Quarterly_Newsletter__c = true;
        controller.ind.SMS__c = true;        
        
        //Set the Phone numbers
        String mobilePhone = '+441111111111';
        String homePhone = '+442222222222';
        String otherPhone = '+443333333333';
        String phone = '+444444444444';
        controller.acc.PersonMobilePhone = mobilePhone;
        controller.acc.PersonHomePhone = homePhone;
        controller.acc.PersonOtherPhone = otherPhone;   
        controller.acc.Phone = phone;
        
        //1.1 Set the Mailing Address
        String mailingStreet = '24 Test Street';
        String mailingPostCode = 'RG12 2PY';
        String mailingCity = 'Test City';
        String mailingCountry = 'United Kingdom';
        String mailingState = 'Test State';
        controller.acc.PersonMailingStreet = mailingStreet;
        controller.acc.PersonMailingPostalCode = mailingPostCode;
        controller.acc.PersonMailingCountry = mailingCountry;
        controller.acc.PersonMailingCity = mailingCity;
        controller.acc.Mailing_State_County__pc = mailingState;
        
        //Submit Changes
        test.startTest();
        controller.submitChanges();
        test.stopTest();
        
        //Query back records
        //Query client Account
        Account[] accsAfterUpdate = [Select Id, PersonMailingStreet,PersonMailingCity, PersonMailingPostalCode,Mailing_State_County__pc, PersonMailingCountry, 
                                     BillingStreet,BillingCity,BillingCountry,BillingPostalCode,Billing_State_County__c, LastName, PersonIndividualId, PersonMobilePhone, PersonHomePhone, PersonOtherPhone, Phone,
                                     (Select Id, Brochure__c, Phone__c, SMS__c, Weekly_Newsletter__c, Quarterly_Newsletter__c From Individuals__r) 
                                     From Account];
        system.assertEquals(1,accsAfterUpdate.size());
        Account accAfterUpdate = accsAfterUpdate[0];	
        system.assertEquals(1, accAfterUpdate.Individuals__r.size());
        Individual indAfterUpdate = accAfterUpdate.Individuals__r[0];
        
        //Confirm the values were saved
        system.assertEquals(true,indAfterUpdate.Phone__c);        
        system.assertEquals(true,indAfterUpdate.SMS__c);   
        system.assertEquals(true,indAfterUpdate.Brochure__c);   
        system.assertEquals(true,indAfterUpdate.Weekly_Newsletter__c);   
        system.assertEquals(true,indAfterUpdate.Quarterly_Newsletter__c);   
        
        system.assertEquals(mobilePhone, accAfterUpdate.PersonMobilePhone);   
        system.assertEquals(homePhone, accAfterUpdate.PersonHomePhone);   
        system.assertEquals(otherPhone, accAfterUpdate.PersonOtherPhone);           
        system.assertEquals(Phone, accAfterUpdate.Phone); 
 
        //1.1 Confirm the Mailing Address has been set
        system.assertEquals(mailingStreet, accAfterUpdate.PersonMailingStreet);   
        system.assertEquals(mailingPostCode, accAfterUpdate.PersonMailingPostalCode);   
        system.assertEquals(mailingCity, accAfterUpdate.PersonMailingCity);           
        system.assertEquals(mailingCountry, accAfterUpdate.PersonMailingCountry); 
        system.assertEquals(mailingState, accAfterUpdate.Mailing_State_County__pc);  
        
        //1.1 Confirm the changes have been replicated to the Billing Address
        system.assertEquals(accAfterUpdate.BillingStreet, accAfterUpdate.PersonMailingStreet);            
        system.assertEquals(accAfterUpdate.BillingPostalCode, accAfterUpdate.PersonMailingPostalCode);   
        system.assertEquals(accAfterUpdate.BillingCity, accAfterUpdate.PersonMailingCity);   
        system.assertEquals(accAfterUpdate.BillingCountry, accAfterUpdate.PersonMailingCountry);   
        system.assertEquals(accAfterUpdate.Billing_State_County__c, accAfterUpdate.Mailing_State_County__pc);           
    }
    
    @isTest static void testSetAuditCompletionDate(){
        
        //Query client Account
        Account[] accs = [Select Id, LastName, PersonIndividualId, PersonMobilePhone, PersonHomePhone, PersonOtherPhone,
                          (Select Id, Data_Audit_Last_Completed__c, Brochure__c, Phone__c, SMS__c, Weekly_Newsletter__c, Quarterly_Newsletter__c From Individuals__r) 
                          From Account];
        system.assertEquals(1,accs.size());
        Account acc = accs[0];
        Id indId = acc.Individuals__r[0].Id;
        
        //Instanstiate ClientContactDetailsEditController and set parameters       
        Test.setCurrentPage(Page.ClientContactDetailsEdit);				        
        ApexPages.currentPage().getParameters().put('AccountId', accs[0].Id);                
        
        //Instantiate the Controller
        ClientContactDetailsEditController controller = new ClientContactDetailsEditController();
                
        //Confirm the Date is blank
        system.assertEquals(null, controller.ind.Data_Audit_Last_Completed__c);
        
        //Set Audit Completion Date
        test.startTest();
        controller.setAuditCompletionDate();
        test.stopTest();
        
        //Requery Individual to check update
        Individual iAfterUpdate = [Select Id, Data_Audit_Last_Completed__c From Individual Where Id = :indId LIMIT 1];
        
        //Confirm the Date has been set to today
        system.assertEquals(system.today(),iAfterUpdate.Data_Audit_Last_Completed__c);
        
    }
    
    @isTest static void testPageLoadFailuresNoAccount(){
        
        //Set AccountId to null
        Test.setCurrentPage(Page.ClientContactDetailsEdit);				        
        ApexPages.currentPage().getParameters().put('AccountId', null);          
        
        //Instantiate the Controller
        ClientContactDetailsEditController controller = new ClientContactDetailsEditController();
        
        //Confirm the page has been hidden
        system.assertEquals(true,controller.hidePage);
        
        //Confirm the error has been displayed
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        boolean b = false;
        for(Apexpages.Message msg : msgs){
            if (msg.getDetail().contains('Cannot find the Person Account. Please contact your system administrator for assistance')) b = true;
        }
        system.assertEquals(true,b);      
        
    }
    
    @isTest static void testPageLoadFailuresNoindividual(){
        
        //Query Person Account
        Account acc = [Select Id, PersonIndividualId, (Select Id From Individuals__r) From Account Where isPersonAccount = true Limit 1];
        system.assertNotEquals(null,acc);
        
        //Disconnect the PersonIndividual
        acc.PersonIndividualId = null;
        update acc;
        
        //Delete the Individual Record
        delete acc.Individuals__r;
        
        //Set AccountId to orphan account
        Test.setCurrentPage(Page.ClientContactDetailsEdit);				        
        ApexPages.currentPage().getParameters().put('AccountId', acc.Id);          
        
        //Instantiate the Controller
        ClientContactDetailsEditController controller = new ClientContactDetailsEditController();
        
        //Confirm the page has been hidden
        system.assertEquals(true,controller.hidePage);
        
        //Confirm the correct error has been displayed
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        boolean b = false;
        for(Apexpages.Message msg : msgs){
            if (msg.getDetail().contains('No Individual record was found for this Client')) b = true;
        }
        system.assertEquals(true,b);      
        
    }    
    
    //1.2 Test Validation - An address must be provided when 'Brochure' is selected
    @isTest static void testMailingAddressMandatoryValidation(){
        
        //Retrieve Account with Individual record
        Account acc = [Select Id, PersonMailingStreet,PersonMailingPostalCode, (Select Id, Brochure__c From Individuals__r) From Account Where isPersonAccount = true LIMIT 1][0];
        system.assertNotEquals(null,acc);
        system.assertEquals(1,acc.Individuals__r.size());
        
        //Clear the Address Details and unsubscribe to brochure
        acc.PersonMailingPostalCode = null;
        acc.PersonMailingPostalCode = null;
        acc.Individuals__r[0].Brochure__c = false;
        update acc;
        update acc.Individuals__r;
        
        //Instanstiate ClientContactDetailsEditController and set parameters      
        Test.setCurrentPage(Page.ClientContactDetailsEdit);				        
        ApexPages.currentPage().getParameters().put('AccountId', acc.Id);     

		//Instantiate the Controller
        ClientContactDetailsEditController controller = new ClientContactDetailsEditController();
        
        //Confirm the Address details are blank
        system.assertEquals(null,controller.initialPostCode);
        system.assertEquals(null,controller.initialMailingStreet);
        
        //Confirm the 'initialBrochure' value is set correctly
        system.assertEquals(false,controller.initialBrochure);
          
        //Attempt to sign the client up to the brochure
		controller.Ind.Brochure__c = true;
        
        //Submit changes
        test.startTest();
        controller.submitChanges();
        test.stopTest();
        
        //Confirm the correct error has been displayed
        system.assertEquals(true,ApexPages.hasMessages());
        system.assertEquals(true,ApexPages.getMessages()[0].getDetail().contains('You must provide a valid mailing address when signing the Client up to the Brochure. If you do not have a valid mailing address for the Client, please untick the Brochure subscription and proceed to save'));
        
        
    }
}