/**************************************************************
@author - Simon Molloy (Golfbreaks)
@date - 10/08/2016
@description - Test class for BatchPhoneNumberUpdate
***************************************************************/
@isTest
private class BatchPhoneNumberUpdateTest {
    @testSetup
    public static void setup() {
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        
      List<Account> accList = new List<Account>();
      RecordType clientRT = [select Id from RecordType where SObjectType = 'Account' and DeveloperName = 'Client' LIMIT 1];
      RecordType venueRT = [select Id from RecordType where SObjectType = 'Account' and DeveloperName = 'Venue' LIMIT 1];
        Account client = new Account(FirstName = 'Test', LastName = 'Client');
        client.RecordTypeId = clientRT.Id;
        client.PersonHomePhone = '+441234 567 890';
        client.PersonMobilePhone = '+447777 111 111';

        accList.add(client);

        Account venue = new Account(Name = 'Test Venue');
        venue.RecordTypeId = venueRT.Id;
        venue.Phone = '+441234 567 890';

        accList.add(venue);

        insert accList;

    }

    static testMethod void testBatchRun() {

      Account checkClient = [select Id, PersonHomePhone, PersonMobilePhone, Name from Account where Name = 'Test Client'];
      Account checkVenue = [select Id, Phone, Name from Account where Name = 'Test Venue'];

      system.assertEquals(checkClient.PersonHomePhone, '+441234 567 890');
      system.assertEquals(checkClient.PersonMobilePhone, '+447777 111 111');
      system.assertEquals(checkVenue.Phone, '+441234 567 890');

      test.startTest();
      BatchPhoneNumberUpdate bpnu = new BatchPhoneNumberUpdate();
      bpnu.query = 'select Id, Phone, PersonHomePhone, PersonMobilePhone from Account where (Phone != null OR PersonMobilePhone != null OR PersonHomePhone != null)';
      Id testBatchId = Database.executeBatch(bpnu, 200);

      test.stopTest();

    checkClient = [select Id, PersonHomePhone, PersonMobilePhone, Name from Account where Name = 'Test Client'];
      checkVenue = [select Id, Phone, Name from Account where Name = 'Test Venue'];

      system.assertEquals(checkClient.PersonHomePhone, '+441234567890');
      system.assertEquals(checkClient.PersonMobilePhone, '+447777111111');
      system.assertEquals(checkVenue.Phone, '+441234567890');      

    }

}