/**************************************************************
@author - Simon Molloy (Golfbreaks)
@date - 23/01/2017
@description - Test class for AP63_BookingToAccountBatchUpdate
***************************************************************/
@isTest (seeAllData = FALSE)
private class AP63_BookingToAccountBatchUpdate_Test {
	//Data Setup
    @testSetup static void setupTestData() {
    	//Insert Error Log Settings custom setting
        List<Error_Log_Setting__c> elsList = new List<Error_Log_Setting__c>();
        for (integer i = 0 ; i < 5 ; i++){
            Error_Log_Setting__c els = new Error_Log_Setting__c();
            els.Enabled__c = true;
            elsList.add(els);
        }
        elsList[0].Name = 'DML Error';
        elsList[1].Name = 'Error';
        elsList[2].Name = 'Exception';
        elsList[3].Name = 'Information';
        elsList[4].Name = 'Warning';

        insert elsList;

    	List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        //creating test accounts
        List<Account> accs = new List<Account>();
        accs.addAll(AP23_TestDataFactory.createPersonAccount(5));

        Account venueAccount = AP23_TestDataFactory.createAccountWithRecType(1, 'Venue')[0];
        venueAccount.Name = 'Test Venue';

        insert venueAccount;
        insert accs;
        
        //creating bookings
        List<Booking__c> bookings = new List<Booking__c>();
        for (Account a : accs){
        	Booking__c booking = new Booking__c();
            booking.Account__c = a.Id;
            booking.Sales_Region_Group__c = 'UK & Ireland';
            booking.Sale_Price_Gross__c = 2932;
            booking.Travel_Date__c = Date.today().addDays(-7);
        	booking.Nights__c = 7;
        	booking.PrimaryVenue__c = venueAccount.Id;
            bookings.add(booking);
        }

        insert bookings;

        /*

        //creating opportunities
        //retreiving opp sales stages
        Set<String> oppStages = new Set<String>();
        Schema.DescribeFieldResult f = Opportunity.StageName.getDescribe();
        List<Schema.PicklistEntry> p = f.getPicklistValues();
        List<Opportunity> opps = new List<Opportunity>();
        for (Schema.PicklistEntry pe : p) {
            for (Account acc : accs) {
                opps.addAll(AP23_TestDataFactory.createOpportunity(1, '1. Recommendations', acc));
            }
        }
        insert opps;

		*/

        
    }

    /**
     * test method to validate the primary venue on the booking is set in the Last Destination field
     * on the Account
     * @author  Simon Molloy
     * @date    23/01/2017
     */
    
    @isTest
    static void test_BatchMethod() {
    	List<Booking__c> sizeList = [select Id from Booking__c where TravelReturnDate__c = TODAY];
        system.assertEquals(5, sizeList.size());
    	test.startTest();
    	AP63_BookingToAccountBatchUpdate batchClass = new AP63_BookingToAccountBatchUpdate();
    	
    	Id jobId = Database.executeBatch(batchClass, sizeList.size());

    	test.stopTest();

    	List<Account> venueAccountList = [select Id from Account where Name = 'Test Venue' LIMIT 1];
    	List<Account> accList = [select Id, Last_Destination__c from Account where RecordType.Name = 'Client'];

    	for (Account a : accList){
    		system.assertEquals(venueAccountList[0].Id, a.Last_Destination__c);
    	}
    }

}