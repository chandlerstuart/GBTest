/*
Name:  AccountManagerRequestWrapper.cls
======================================================
======================================================
Purpose:
-------
This class is a wrapper class used to send data to the AccountManager API in Clubhouse
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon M       2017-08-09  Initial development.
*/
public with sharing class AccountManagerRequestWrapper {
	public Integer AccountManagerEntity;
    public String EntityGolfbreaksID;
    public EnquiryClientRequestWrapper.EmployeeModel NewAccountManager; 

    //Constructor - entityType = 1 for Lead, 0 for Unknown (see API Documentation)
	public AccountManagerRequestWrapper(integer entityType, String enquiryId) {
		this.AccountManagerEntity = entityType;
		this.EntityGolfbreaksID = enquiryId;
	}
}