/*
Name:  UserLeaveWrapper.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Wrapper class used to aggregate an Employee record with 
the employee's working patterns and leave requests

======================================================
======================================================
History
------- 
Ver. Author                Date                  Detail
1.0  Halldór Örn        2014-05-21      Initial development.


*/
public with sharing class UserLeaveWrapper {
	
	public User user { get; set; }
	public List<EmployeeWorkingPattern__c> workingPattern { get; set; }
	public List<Leave__c> leaves { get; set; }
	
	/*
	UserLeaveWrapper
	------------------------
	Purpose: Constructor
	Input: A user record, List of EmployeeWorkingPattern__c records, List of Leave__c record
	Output: none
	*/
	public UserLeaveWrapper(User user, List<EmployeeWorkingPattern__c> workingPattern, List<Leave__c> leaves ) {
		this.user = user;
		this.workingPattern = getWorkingPattern(workingPattern);
		this.leaves = getLeaves(leaves);
	}

	/*
	getWorkingPattern
	------------------------
	Purpose: Populates the workingPattern member variable with user's workingPattern
	Input: List of EmployeeWorkingPattern__c
	Output: List of EmployeeWorkingPattern__c
	*/
	private List<EmployeeWorkingPattern__c> getWorkingPattern(List<EmployeeWorkingPattern__c> workingPattern){
		List<EmployeeWorkingPattern__c> patterns = new List<EmployeeWorkingPattern__c>();
		for( EmployeeWorkingPattern__c pattern : workingPattern){
			if( pattern.Employee__c == user.Id){
				patterns.add(pattern);				
			}
		}
		return patterns;
	}

	/*
	getLeaves
	------------------------
	Purpose: Populates the leaves member variable with user's leave__c records
	Input: List of Leave__c
	Output: List of Leave__c
	*/
	private List<Leave__c> getLeaves(List<Leave__c> allLeaves){

		List<Leave__c> leaves = new List<Leave__c>();
		for( Leave__c leave : allLeaves){
			if( leave.Employee__c == user.Id){
				leaves.add(leave);
			}
		}
		return leaves;
	}
}