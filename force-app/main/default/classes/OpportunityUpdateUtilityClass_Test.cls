/**************************************************************
@author - Simon Molloy (Golfbreaks)
@date - 30/06/2017
@description - Test class for OpportunityUpdateUtilityClass
***************************************************************/
@isTest
private class OpportunityUpdateUtilityClass_Test {
    @testSetup
    public static void setup() {
      List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
      
      Account client = AP23_TestDataFactory.createPersonAccount(1)[0];
      insert client;

      List<Opportunity> oppList = AP23_TestDataFactory.createOpportunity(3,ApplicationConstant.PAIDFULLBALANCESTAGE,client);
      oppList[0].Name = 'Pre-Today Return';
      oppList[1].Name = 'Today Return';
      oppList[2].Name = 'Post-Today Return';

      insert oppList;

      List<Booking__c> bookingList = new List<Booking__c>();

      for (Opportunity o : oppList){
        Booking__c book = AP23_TestDataFactory.createBooking(1, client, o.Id)[0];
        if ('Pre-Today Return'.equalsIgnoreCase(o.Name)){
          book.Travel_Date__c = Date.today().addDays(-14);
          book.Nights__c = 7;
        }else if ('Today Return'.equalsIgnoreCase(o.Name)){
          book.Travel_Date__c = Date.today().addDays(-7);
          book.Nights__c = 7;
        }else if ('Post-Today Return'.equalsIgnoreCase(o.Name)){
          book.Travel_Date__c = Date.today().addDays(7);
          book.Nights__c = 7;
        }
        bookingList.add(book);
      }

      insert bookingList;

    }

    static testMethod void testUpdateToTripComplete() {
      List<Opportunity> oppList = [select Id, StageName, Name from Opportunity];
      
      test.startTest();
        oppList = OpportunityUpdateUtilityClass.updateToTripComplete(oppList);
        update oppList;
      test.stopTest();

      oppList = [select Id, Name, StageName from Opportunity];

      for (Opportunity o : oppList){
        if ('Pre-Today Return'.equalsIgnoreCase(o.Name)){
          system.assertEquals(ApplicationConstant.OPP_STAGE_TRIPCOMPLETED, o.StageName);
        }else if ('Today Return'.equalsIgnoreCase(o.Name)){
          system.assertEquals(ApplicationConstant.OPP_STAGE_TRIPCOMPLETED, o.StageName);
        }else if ('Post-Today Return'.equalsIgnoreCase(o.Name)){
          system.assertEquals(ApplicationConstant.PAIDFULLBALANCESTAGE, o.StageName);
        }
      }
    }
}