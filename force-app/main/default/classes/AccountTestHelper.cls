/*
Name:  AccountTestHelper.cls
Copyright © 2014  CloudMethods
======================================================
======================================================
Purpose:
-------
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2014-01-27  Initial development.
1.1  Mark Cane&    2016-12-23  Added custom setting population [createAccountValidationRulesByProfileId].
*/
@isTest
public with sharing class AccountTestHelper {

	private static List<Account> createAccounts(Integer n, String namePrefix, String currencyIsoCode, Boolean proceedToInsert){
		
		Account_Validation__c av = Account_Validation__c.getInstance(UserInfo.getProfileId());		
		av.Create_Ancillary_Accounts__c = true;
        av.Create_Chain_Account__c = true;
		av.Create_Client_Account__c = true;
		upsert av;
		
		Account a;
		List<Account> accounts = new List<Account>();
		
		Boolean accountHasRecordType = Schema.SObjectType.Account.fields.getMap().containsKey('RecordTypeId');

		//& Get the default record type for the object.
		Id accountRecordTypeId;
		if (accountHasRecordType){
			accountRecordTypeId = [select r.Id from RecordType r where r.SObjectType='Account' and r.isPersonType=false and r.isActive=true limit 1].Id;
		}
					
		for (Integer i=0; i<n; i++) {
			a = new Account();
			
			if (accountHasRecordType) {
				a.put('RecordTypeId', accountRecordTypeId);
			}
			a.Name = namePrefix+i.format();			 
			a.CurrencyIsoCode = currencyIsoCode;
			accounts.add(a);
		}
		if (proceedToInsert) insert accounts;
		
		return accounts;
	}

	public static List<Account> createAccounts(Integer n, String namePrefix, Boolean proceedToInsert){
		List<CurrencyType> corporateCurrencies = [select ISOCode, ConversionRate from CurrencyType where IsActive=true and IsCorporate=true limit 1];
		
		if (corporateCurrencies.size()>0)			
			return createAccounts(n, namePrefix, corporateCurrencies[0].IsoCode, proceedToInsert);
		else
			return createAccounts(n, namePrefix, 'GBP', proceedToInsert);
	}
		
	public static List<Account> createAccounts(Integer n, String namePrefix){
		List<CurrencyType> corporateCurrencies = [select ISOCode, ConversionRate from CurrencyType where IsActive=true and IsCorporate=true limit 1];
		
		if (corporateCurrencies.size()>0)			
			return createAccounts(n, namePrefix, corporateCurrencies[0].IsoCode, true);
		else
			return createAccounts(n, namePrefix, 'GBP', true);
	}
}