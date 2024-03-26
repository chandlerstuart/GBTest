/*
Name:  AccountClientRequestWrapper_Test.cls
======================================================
======================================================
Purpose:
-------
Test class for AccountClientRequestWrapper.cls

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Simon Molloy  2017-09-21  Initial development.
1.1  James Radcliffe 2018-06-11 nullToEmpty test
*/
@isTest
private class AccountClientRequestWrapper_Test {
    
    static testMethod void testClass() {
        AccountClientRequestWrapper wrapper = new AccountClientRequestWrapper();
        wrapper.ClientAccountID = '12345'; 
        wrapper.Salutation = 'Mr.';
        wrapper.FirstName = 'Test';
        wrapper.LastName = 'Account';
        wrapper.PersonEmail = 'test.account@email.com';
        wrapper.PersonMobilePhone = '+447911111111';
        wrapper.PersonHomePhone = '+440987654321';
        wrapper.PersonOtherPhone = '+441234567890';
        wrapper.NewsletterSignup = TRUE;
        wrapper.SalesforceAddress = new AccountClientRequestWrapper.SalesforceAddressModel(AP23_TestDataFactory.createPersonAccount(1)[0]);
        wrapper.SalesforceAddress = new AccountClientRequestWrapper.SalesforceAddressModel('Test Street','Test City','Test Country','Test PostCode','Test County');
        
        boolean returnValue = wrapper.returnValue();
        
        system.assertEquals(true, returnValue);
    }
    
    //1.1
    static testMethod void testNullToEmpty(){
        
        String nullString = null;
        String emptyString = '';
        String testString = 'testString';
                
        //Confirm the method does not return null when null is passed
        system.assertNotEquals(null, AccountClientRequestWrapper.nullToEmpty(nullString));        
        //Confirm the method returns an empty string when null is passed
        system.assertEquals(emptyString, AccountClientRequestWrapper.nullToEmpty(nullString));
        //Confirm the value remains as is if it is not null
        system.assertEquals('testString', AccountClientRequestWrapper.nullToEmpty(testString));
        
    }
    
    
    
}