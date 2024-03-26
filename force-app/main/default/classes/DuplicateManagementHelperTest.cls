/*
Name:  DuplicateManagementHelperTest.cls
======================================================
======================================================
Purpose: Manager for all Master Account De-duplication
-------
======================================================
======================================================

History
------- 
Ver. Author        Date         Detail
1.0  J Radcliffe   2019-08-21   Initial development
1.1  J Radcliffe   2020-10-05   Extend Tests to check for successful upsert of Individual record(s)
*/
@isTest
public with sharing class DuplicateManagementHelperTest {
    public DuplicateManagementHelperTest() {

    }
    @isTest static void testFindDuplicates(){
        //NOTE - Duplicate Rules/Matching Rules are not going to be part of the package. We have no way of verifying Dupe Matching within the package 
        //This method simply confirms there are no runtime exceptions and increases code coverage
        EnquiryManager.Enquiry e = new EnquiryManager.Enquiry();
        e.isSuccess = true;
        e.actionType = [Select Id, ClientFieldMappingGroup__c From ActionType__mdt Where DeveloperName = 'TestCaseAction' Limit 1];
        e.clientDetails.firstName = 'Sophie';
        e.clientDetails.lastName = 'Grigson';
        e.clientDetails.email = 'sg@unittest.golfbreaks.com';

        List<EnquiryManager.Enquiry> enquiries = new List<EnquiryManager.Enquiry> { e }; 

        test.startTest();
            Boolean clearFromExceptions = DuplicateManagementHelper.findDuplicates(enquiries,null);
        test.stopTest();

        system.assertEquals(true, clearFromExceptions);
        system.assertEquals(false, enquiries[0].isAborted);
        system.assertEquals(true, enquiries[0].isSuccess);
        system.assertEquals(0, enquiries[0].errorMessages.values().size());
        
    }

    @isTest static void testUpsertClients(){

        EnquiryManager.Enquiry e = new EnquiryManager.Enquiry();
        e.isSuccess = true;
        e.actionType = [Select Id, ClientFieldMappingGroup__c, IndividualFieldMappingGroup__c From ActionType__mdt Where DeveloperName = 'TestCaseAction' Limit 1];
        e.clientDetails.firstName = 'Sophie';
        e.propertyCache.put('ClientDetails.firstName','Sophie');
        e.clientDetails.lastName = 'Grigson';
        e.propertyCache.put('ClientDetails.lastName','Grigson');
        e.clientDetails.email = 'sg@unittest.golfbreaks.com';
        e.propertyCache.put('ClientDetails.email','sg@unittest.golfbreaks.com');
        e.clientDetails.homePhone = '+447944999111';
        e.propertyCache.put('ClientDetails.homePhone','+447944999111');
        e.clientDetails.mobilePhone = '+447944222222';
        e.propertyCache.put('ClientDetails.mobilePhone','+447944222222');
        //1.1+
        e.marketingPreferences.weeklyNewsletter = true;
        e.propertyCache.put('MarketingPreferences.weeklyNewsletter',true);
        e.marketingPreferences.seasonalNewsletter = false;
        e.propertyCache.put('MarketingPreferences.seasonalNewsletter',false);
        e.marketingPreferences.phone = true;
        e.propertyCache.put('MarketingPreferences.phone',false);
        List<EnquiryManager.Enquiry> enquiries = new List<EnquiryManager.Enquiry> { e }; 

        test.startTest();
            Boolean clearFromInsertExceptions = DuplicateManagementHelper.upsertIndividualAndClientAccounts(enquiries);

            system.assertEquals(true, clearFromInsertExceptions);
            system.assertEquals(false, enquiries[0].isAborted);
            system.assertEquals(true, enquiries[0].isSuccess);
            system.assertEquals(0, enquiries[0].errorMessages.values().size());

            //Note - Enq To (Business) Account Field Mapping for Unit Tests are as follows;
            //ClientDetails.homePhone >> Type
            //ClientDetails.mobilePhone >> Industry
            //ClientDetails.firstName >> Name
            //ClientDetails.email >> Fax
            //ClientDetails.lastName >> AccountSource
            
            Account newAccount = [Select Id, PersonIndividualId, Name, FirstName, LastName, PersonHomePhone, PersonEmail, PersonMobilePhone From Account];//Expected 1 Account inserted- This line will fail if there is more or less than 1 Account
            Individual newIndividual = [Select Id, HasOptedOutSolicit, FirstName, LastName, HasOptedOutTracking, HasOptedOutProcessing From Individual Where Id =:newAccount.PersonIndividualId];//1.1+

            //Confirm the data has been mapped correctly
            system.assertEquals(e.clientDetails.firstName, newAccount.FirstName);
            system.assertEquals(e.clientDetails.lastName, newAccount.LastName);
            system.assertEquals(e.clientDetails.homePhone, newAccount.PersonHomePhone);
            system.assertEquals(e.clientDetails.mobilePhone, newAccount.PersonMobilePhone);
            system.assertEquals(e.clientDetails.email, newAccount.PersonEmail);
            system.assertEquals(e.clientDetails.accountId, newAccount.Id);

            //Confirm the data has been mapped correctly 1.1+
            system.assertEquals(e.marketingPreferences.weeklyNewsletter, newIndividual.HasOptedOutSolicit);
            system.assertEquals(e.clientDetails.lastName, newIndividual.LastName);
            system.assertEquals(e.clientDetails.firstName, newIndividual.FirstName);
            system.assertEquals(e.marketingPreferences.seasonalNewsletter, newIndividual.HasOptedOutTracking);
            system.assertEquals(e.marketingPreferences.phone, newIndividual.HasOptedOutProcessing);


            //Re-run to check existing Accounts are successfully updated

            e.clientDetails.firstName = 'Susan';//Modify Name
            e.propertyCache.put('ClientDetails.firstName','Susan');

            //1.1+
            e.marketingPreferences.weeklyNewsletter = false;//Set the Weekly Newsletter to false
            e.propertyCache.put('MarketingPreferences.weeklyNewsletter',false);
            e.marketingPreferences.seasonalNewsletter = true;//Set Seasonal Newsletter to true
            e.propertyCache.put('MarketingPreferences.seasonalNewsletter',true);
            e.marketingPreferences.phone = false;//Set Phone to false
            e.propertyCache.put('MarketingPreferences.phone',false);

            e.clientDetails.accountId = newAccount.id;//Set the existing client (simulate dupe match found)

            Boolean clearFromUpdateExceptions = DuplicateManagementHelper.upsertIndividualAndClientAccounts(enquiries);

        test.stopTest();
        
        
            system.assertEquals(true, clearFromUpdateExceptions);
            system.assertEquals(false, enquiries[0].isAborted);
            system.assertEquals(true, enquiries[0].isSuccess);
            system.assertEquals(0, enquiries[0].errorMessages.values().size());

            //Confirm only the previously created Account exists
            Account existingAccount = [Select Id, FirstName From Account];//Expected 1 Account inserted- This line will fail if there is more or less than 1 Account
            Individual existingIndividual = [Select Id, HasOptedOutSolicit, FirstName, LastName, HasOptedOutTracking, HasOptedOutProcessing From Individual Where Id =:newAccount.PersonIndividualId];//1.1+

            //Confirm the name has been updated
            system.assertEquals(e.clientDetails.firstName, 'Susan');
            system.assertEquals(e.clientDetails.firstName, existingAccount.FirstName);
            
            //Confirm the First Name and SNewsletter have been updated, but the Weekly Newsletter is not unticked (Override Behaviour = 'Omit')
            system.assertEquals(e.clientDetails.firstName, existingIndividual.FirstName);
            system.assertEquals(true, existingIndividual.HasOptedOutSolicit);
            system.assertEquals(true, existingIndividual.HasOptedOutTracking);
            //Confirm the Phone MP has been unticked because the Override Behaviour = Override 
            system.assertEquals(false, existingIndividual.HasOptedOutProcessing);
    }

    @isTest static void testGetDuplicateAccountIds(){
        //NOTE - Duplicate Rules/Matching Rules are not going to be part of the package. We have no way of verifying Dupe Matching within the package 
        //This method simply confirms there are no runtime exceptions and increases code coverage
        Account acc = new Account();
        acc.Name = 'Test Account';

        test.startTest();
            List<String> dupeIds = DuplicateManagementHelper.getDuplicateAccountIds(acc, 'TestCaseAction');
        test.stopTest();

        system.assertEquals(1, dupeIds.size());
        system.assertEquals('123456789101112', dupeIds[0]);
        
    }
}