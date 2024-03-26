/**
Name:  DataScrambler_Test.cls
======================================================
======================================================
Purpose:
-------
Test Class for DataScrambler
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  S.Molloy	   2017-10-26  Initial development
**/
@isTest
public class DataScrambler_Test {

	@testSetup
    private static void setUpData(){
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings; 

		GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
        
        WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//<-- 2.2 block WIRE calculations for test data.

		insert new Phased_Code_Removal__c(Disable_Accenture_Lead_Routing__c=true,
											Disable_Lead_Scoring__c=true,
											Disable_Legacy_Acct_Manager_Integrations__c=true,
											Disable_Legacy_Client_Enq_Integrations__c=true,
											Disable_Miscellaneous_Redundant_Triggers__c=true,
											Disable_SAA_Capacity_Calculation__c = true,
											Disable_Monthly_Sales_Target_Automation__c = true,
											Disable_Shadow_Opportunities__c = true,
											Disable_Total_Previous_Bookings_Calc__c = true
											);

        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;

        List<Lead> leadList = AP23_TestDataFactory.createLead(200);
        insert leadList;

        List<Account> accList = AP23_TestDataFactory.createPersonAccount(200);
        for (integer i = 0 ; i < accList.size() ; i ++){
        	Account a = accList[i];
        	a.LastName = a.LastName + i;
        	a.PersonEmail = a.FirstName.toLowerCase() + '.' + a.LastName.toLowerCase() + '@myemail.com';
        }
        insert accList;

        /*List<Contact> contactList = new List<Contact>();
        for (Account a : accList){
        	Contact c = AP23_TestDataFactory.createContactList(1,a)[0];
        	c.HomePhone = c.Phone;
        	c.Email = a.PersonEmail;
        	c.HomePhone = a.PersonMobilePhone;
        	c.OtherPhone = a.PersonMobilePhone;

        	contactList.add(c);
        }

        insert contactList;
        */
    }
    
     @isTest static void testRun(){
     	
     	DataScrambler dsLead = new DataScrambler('LEAD');
     	DataScrambler dsAcc = new DataScrambler('ACCOUNT');

     	test.startTest();
			GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
			GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
			
			WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//<-- 2.2 block WIRE calculations for test data.
			Database.executeBatch(dsLead, 200);
			Database.executeBatch(dsAcc, 200);

     	test.stopTest();

     	List<Account> checkAccList = [select Id, Name, PersonEmail, PersonMobilePhone from Account];
     	List<Lead> checkLeadList = [select Id, Name, Email, Phone from Lead];

     	for (Account a : checkAccList){
     		system.assertEquals(TRUE, a.PersonEmail.contains(DataScrambler.EMAIL_MODIFIER));
     		system.assertEquals(TRUE, a.PersonMobilePhone.contains(DataScrambler.PHONE_MODIFIER));
     	}

     	for (Lead l : checkLeadList){
     		system.assertEquals(TRUE, l.Email.contains(DataScrambler.EMAIL_MODIFIER));
     		system.assertEquals(TRUE, l.Phone.contains(DataScrambler.PHONE_MODIFIER));
     	}
     }
}