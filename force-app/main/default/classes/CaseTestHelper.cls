/*
Copyright © 2014  CloudMethods
======================================================
======================================================
Purpose:
-------
Creates Case records for use in unit testing.
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2014-05-20  Initial development.
1.1  Mark Cane&    2014-05-21  Added createSimpleCase overload.
1.2  Mark Cane&    2016-12-23  Moved createSimpleCase RT query to static initialization code block. 
*/
@isTest
public with sharing class CaseTestHelper {

	static final Id salesQueryCaseRtId;
	
	//static initialization code block - runs the first time the class is referenced only.
	static {
		salesQueryCaseRtId = [select Id from RecordType where SObjectType = 'Case' and DeveloperName = 'Sales_Query' LIMIT 1].Id;		
	}
				
	public static List<Case> createCases(Integer n, String subject, Id accountId, Id contactId, Boolean proceedToInsert){
		return createCaseRecords(n, subject, accountId, contactId, proceedToInsert); 
	}
	
	public static List<Case> createCases(Integer n, String subject, Id accountId, Id contactId){
		return createCaseRecords(n, subject, accountId, contactId, true);
	}
	
	public static Case createSimpleCase(){
		return createSimpleCase(true);
	}
		
	public static Case createSimpleCase(Boolean proceedToInsert){
		Case c = new Case();
		c.RecordTypeId = salesQueryCaseRtId; //1.2 [select Id from RecordType where SObjectType = 'Case' and DeveloperName = 'Sales_Query' LIMIT 1].Id;
		c.Subject = 'test case';
		c.Origin = 'Email';
		if (proceedToInsert) insert c;
		
		return c;		
	}	

	private static List<Case> createCaseRecords(Integer n, String subject, Id accountId, Id contactId, Boolean proceedToInsert){		
		Case c;
		List<Case> cases = new List<Case>();
					
		for (Integer i=0; i<n; i++) {
			c = new Case(AccountId=accountId, ContactId=contactId);
			c.Origin = 'email';
			c.Subject = subject+i.format();
			cases.add(c);
		}
		if (proceedToInsert) insert cases;
		
		return cases;
	}
}