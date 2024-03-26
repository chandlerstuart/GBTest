@isTest
private class AP58_LeadConversionUtility_Test {
	
	@testSetup static void setUp() {
		// Implement test code
		OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;
        
        Account acc = AP23_TestDataFactory.createAccount(1)[0];
        insert acc;
        
        Communication_Preference__c cp = new Communication_Preference__c(Communication_Type__c = 'Newsletter', Related_To__c = acc.Id);
        insert cp;
        
        List<Lead> lLead = AP23_TestDataFactory.createLead(5);
        for(Lead l : lLead) {
        	l.OwnerId = UserInfo.getUserId();
        }
        insert lLead;

        List<Object_Field_Mapping__c> customSettings = AP23_TestDataFactory.getCustomSettingObjectFieldMapping();
        insert customSettings;  

	}

	@isTest static void convertLeadTest() {
        System.debug('convertLeadTest');
        List<Lead> updateLead = new List<Lead>();
        List<Lead> lLead = [Select Id, Rating, OwnerId, Status, Account__c FROM Lead];
        Id acctId = [SELECT Id FROM Account].Id;

        for(Lead l: lLead){
            l.GolfbreaksEnquiryId__c = '1231231231';
        	l.Account__c = acctId;
        	l.LeadtoConvert__c = true;
        	updateLead.add(l);
        	System.debug('************** ownerId : ' + l.OwnerId);
        }
        update updateLead;
        Test.startTest();

        Id batchJobId = Database.executeBatch(new AP57_ConvertLeadBatch(),100);
		System.debug('Id : ' + batchJobId);

        Test.stopTest();
        // Verify opp items got inserted 
        Integer i = [SELECT COUNT() FROM Opportunity];
        System.assertEquals(i, 5);
    }
	
}