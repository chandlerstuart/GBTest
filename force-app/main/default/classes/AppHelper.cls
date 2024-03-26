/*
Name:  AppHelper.cls
Copyright © 2014  CloudMethods
======================================================
======================================================
Purpose:
-------
General helper methods.
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2014-05-29  Initial development.
*/
public with sharing class AppHelper {

	public static Map<String, Id> getRecordTypesByDeveloperName(String SObjectType){
		Map<String, Id> developerNameToRTId = new Map<String, Id>();
		
		for (RecordType rt : [select r.Id, r.DeveloperName from RecordType r where r.SobjectType=:SObjectType]){
			developerNameToRTId.put(rt.DeveloperName, rt.Id);
		}
		
		//& code could be added to apply active flag and to augment with Describe information (isAccessible etc.).
		
		return developerNameToRTId;
	}
}