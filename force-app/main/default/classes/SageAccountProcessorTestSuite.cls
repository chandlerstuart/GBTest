/*
Name:  SageAccountProcessorTestSuite.cls
Copyright © 2017 Golfbreaks
======================================================
======================================================
Purpose:
-------

Existing Supplier Accounts have the Tax Number field updated.
New Business Accounts are created.
New Finance Contacts are created.

======================================================
======================================================
History
------- 
Ver.  Author        Date            Detail
1.0   Mark Cane     2017-05-03      Initial development.
1.1   Simon Molloy  2017-10-05      Updated test cases to use new 'doCreate' boolean and no checking for updates
*/
@isTest
private class SageAccountProcessorTestSuite {
    
    /*
    Test cases:
        singleTestCase1 - No existing Trade Account - create new and add finance contact.
        singleTestCase2 - No existing Trade Account - create new and add finance contact (multiple Sage Account import records for the same reference).
        singleTestCase2 - Existing Trade Account - update tax reference and add multiple finance contacts.
        ..
        actualTestCase1 - Actual data - single Account Reference (EUROPE) - one Sage Account import record and no contact.
        actualTestCase2 - Actual data - single Account Reference (ABAMA) - mulitple Sage Account import records and two finance contacts.
        actualTestCase3 - first 200 Sage Account import records.
        actualTestCase4 - first 2000 Sage Account import records.
    */
    /*
    @isTest(SeeAllData=true)
    static void actualDataTestCase1(){
        // Actual data - single Account Reference (EUROPE) - one Sage Account import record and no contact.
                
        Test.startTest();
                
        String query = 'select Id, Name, Account_Reference__c,Account_Name__c, Currency_Code__c, Tax_Number__c, Contact__c, ';
        query+='Telephone__c, Remittance_Email__c,Post_Code__c, Address_Line_1__c,Address_Line_2__c, Address_Line_3__c, ';
        query+='Address_Line_4__c, Address_Line_5__c,Country_Name__c, Country_Code__c, Brand__c ';
        query+=' from Sage_Account__c'; 
        query+=' where Is_Processed__c=false';
        query+=' and Account_Reference__c=\'EUROPE\'';
        query+=' order by Account_Reference__c asc, CreatedDate asc, Id asc';
        
        SageAccountProcessor p = new SageAccountProcessor();
        p.query = query;
        
        Database.executeBatch(p, 200);
        Test.stopTest();
        
        System.debug(LoggingLevel.ERROR, [select Id,Invoice_Tax_Reference__c from Account where Supplier_Sage_Code__c='EUROPE']);   
        System.debug(LoggingLevel.ERROR, [select Id,AccountId,RecordType.Name,Name,LastName,FirstName,MailingStreet,MailingCity,MailingState,MailingPostalCode,MailingCountry,Phone,OtherPhone,Email,Description from Contact where Account.Supplier_Sage_Code__c='EUROPE']);               
        
        System.assertEquals(0,[select count() from Sage_Account__c where Account_Reference__c='EUROPE' and Is_Processed__c=false]);
    }    
    
    @isTest(SeeAllData=true)
    static void actualDataTestCase2(){
        // Actual data - single Account Reference (ABAMA) - mulitple Sage Account import records and two finance contacts.
        
        Test.startTest();
                
        String query = 'select Id, Name, Account_Reference__c,Account_Name__c, Currency_Code__c, Tax_Number__c, Contact__c, ';
        query+='Telephone__c, Remittance_Email__c,Post_Code__c, Address_Line_1__c,Address_Line_2__c, Address_Line_3__c, ';
        query+='Address_Line_4__c, Address_Line_5__c,Country_Name__c, Country_Code__c, Brand__c ';
        query+=' from Sage_Account__c'; 
        query+=' where Is_Processed__c=false';
        query+=' and Account_Reference__c=\'ABAMA\'';
        query+=' order by Account_Reference__c asc, CreatedDate asc, Id asc';
        
        SageAccountProcessor p = new SageAccountProcessor();
        p.query = query;
        
        Database.executeBatch(p, 200);
        Test.stopTest();
    
        System.debug(LoggingLevel.ERROR, [select Id,Invoice_Tax_Reference__c from Account where Supplier_Sage_Code__c='ABAMA']);    
        System.debug(LoggingLevel.ERROR, [select Id,AccountId,RecordType.Name,Name,LastName,FirstName,MailingStreet,MailingCity,MailingState,MailingPostalCode,MailingCountry,Phone,OtherPhone,Email,Description from Contact where Account.Supplier_Sage_Code__c='ABAMA']);        
                
        System.assertEquals(0,[select count() from Sage_Account__c where Account_Reference__c='ABAMA' and Is_Processed__c=false]);
    }
    
    @isTest(SeeAllData=true)
    static void actualDataTestCase3(){
        // Actual data - first 200 Sage Account import records.
        
        Test.startTest();
                
        String query = 'select Id, Name, Account_Reference__c,Account_Name__c, Currency_Code__c, Tax_Number__c, Contact__c, ';
        query+='Telephone__c, Remittance_Email__c,Post_Code__c, Address_Line_1__c,Address_Line_2__c, Address_Line_3__c, ';
        query+='Address_Line_4__c, Address_Line_5__c,Country_Name__c, Country_Code__c, Brand__c ';
        query+=' from Sage_Account__c'; 
        query+=' where Is_Processed__c=false';
        query+=' order by Account_Reference__c asc, CreatedDate asc, Id asc';
        query+=' limit 200';
        
        SageAccountProcessor p = new SageAccountProcessor();
        p.query = query;
        
        Database.executeBatch(p, 200);
        Test.stopTest();
    }
    
    @isTest(SeeAllData=true)
    static void actualDataTestCase4(){
        // Actual data - first 2000 Sage Account import records.
        
        Test.startTest();
                
        String query = 'select Id, Name, Account_Reference__c,Account_Name__c, Currency_Code__c, Tax_Number__c, Contact__c, ';
        query+='Telephone__c, Remittance_Email__c,Post_Code__c, Address_Line_1__c,Address_Line_2__c, Address_Line_3__c, ';
        query+='Address_Line_4__c, Address_Line_5__c,Country_Name__c, Country_Code__c, Brand__c ';
        query+=' from Sage_Account__c'; 
        query+=' where Is_Processed__c=false';
        query+=' order by Account_Reference__c asc, CreatedDate asc, Id asc';
        query+=' limit 2000';
        
        SageAccountProcessor p = new SageAccountProcessor();
        p.query = query;
        
        Database.executeBatch(p, 2000);
        Test.stopTest();
    }
    */               

    static testmethod void singleTestCase1(){
        // No existing Trade Account - create new and add finance contact.
        
        Map<String, Id> developerNameToRTId = AppHelper.getRecordTypesByDeveloperName('Account');
        Id businessAccountRTId=developerNameToRTId.get('Business_Account');
        
        developerNameToRTId = AppHelper.getRecordTypesByDeveloperName('Contact');
        Id financeContactRTId=developerNameToRTId.get('Finance');
        
        Sage_Account__c s = buildSageAccount();         
        insert s;       
 
        Test.startTest();
        SageAccountProcessor sap = new SageAccountProcessor();
        sap.doCreate = TRUE;
        Database.executeBatch(sap, 200);
        Test.stopTest();
        
        System.assert([select Is_Processed__c from Sage_Account__c where Id=:s.Id].Is_Processed__c);

        System.assertEquals(1,[select count() from Account]);
        Account a = [select Id,Name,RecordTypeId,Supplier_Sage_Code__c,CurrencyIsoCode,Invoice_Tax_Reference__c,BillingStreet,BillingCity,BillingState,BillingPostalCode,BillingCountry from Account limit 1];
        System.debug(LoggingLevel.ERROR, a);
        System.assertEquals(businessAccountRTId, a.RecordTypeId);  
        
        System.assertEquals(1,[select count() from Contact where AccountId=:a.Id]);         
        Contact c = [select Id,RecordTypeId,AccountId,Name,LastName,FirstName,MailingStreet,MailingCity,MailingState,MailingPostalCode,MailingCountry,Phone,OtherPhone,Email,Description from Contact where AccountId=:a.Id limit 1];
        System.debug(LoggingLevel.ERROR, c);
        System.assertEquals(financeContactRTId, c.RecordTypeId);
    }
        
    static testMethod void singleTestCase2(){
        // No existing Trade Account - create new and add finance contact (multiple Sage Account import records for the same reference).
        
        Sage_Account__c s = buildSageAccount();
        insert s;
        
        Sage_Account__c s2 = buildSageAccount2();       
        insert s2;
 
        Test.startTest();
        SageAccountProcessor sap = new SageAccountProcessor();
        sap.doCreate = TRUE;
        Database.executeBatch(sap, 200);
        Test.stopTest();
        
        System.assert([select Is_Processed__c from Sage_Account__c where Id=:s.Id].Is_Processed__c);
        System.assert([select Is_Processed__c from Sage_Account__c where Id=:s2.Id].Is_Processed__c);
        
        System.assertEquals(1,[select count() from Account]);
        Account a = [select Id,Name,RecordTypeId,Supplier_Sage_Code__c,CurrencyIsoCode,Invoice_Tax_Reference__c,BillingStreet,BillingCity,BillingState,BillingPostalCode,BillingCountry from Account limit 1];
        System.debug(LoggingLevel.ERROR, a);
        
        System.assertEquals(2,[select count() from Contact where AccountId=:a.Id]);         
        System.debug(LoggingLevel.ERROR, [select Id,AccountId,Name,LastName,FirstName,MailingStreet,MailingCity,MailingState,MailingPostalCode,MailingCountry,Phone,OtherPhone,Email,Description from Contact where AccountId=:a.Id]);        
    } 
    
    static testMethod void singleTestCase3(){
        // Existing Trade Account - update tax reference and add multiple finance contacts.

        Map<String, Id> developerNameToRTId = AppHelper.getRecordTypesByDeveloperName('Account');
        Id supplierAccountRTId=developerNameToRTId.get('Supplier');
        
        
        Account a = new Account(RecordTypeId=supplierAccountRTId);
        a.Name = 'The Ritz Carlton Abama';
        a.Supplier_Sage_Code__c = 'ABAMA';
        insert a;       
        
        Sage_Account__c s = buildSageAccount();         
        insert s;       
        
        Sage_Account__c s2 = buildSageAccount2();       
        insert s2;      
 
        Test.startTest();
        SageAccountProcessor sap = new SageAccountProcessor();
        sap.doCreate = TRUE;
        Database.executeBatch(sap, 200);
        Test.stopTest();
        
        System.assert([select Is_Processed__c from Sage_Account__c where Id=:s.Id].Is_Processed__c);
        System.assert([select Is_Processed__c from Sage_Account__c where Id=:s2.Id].Is_Processed__c);
        
        System.assertEquals(1,[select count() from Account]);
        a = [select Id,RecordTypeId,Invoice_Tax_Reference__c from Account where Id=:a.Id];
        System.debug(LoggingLevel.ERROR, a);        
        System.assertEquals(supplierAccountRTId, a.RecordTypeId);
        //System.assertEquals(s.Tax_Number__c, a.Invoice_Tax_Reference__c); // first record created.
        
        System.assertEquals(2,[select count() from Contact where AccountId=:a.Id]);         
        System.debug(LoggingLevel.ERROR, [select Id,AccountId,Name,LastName,FirstName,MailingStreet,MailingCity,MailingState,MailingPostalCode,MailingCountry,Phone,OtherPhone,Email,Description from Contact where AccountId=:a.Id]);        
    }     
     

    // Test helpers.    
    private static Sage_Account__c buildSageAccount(){
        Sage_Account__c s = new Sage_Account__c();
        s.Is_Processed__c = false;
        s.Account_Name__c = 'The Ritz Carlton Abama';
        s.Account_Reference__c = 'ABAMA';
        s.Tax_Number__c = 'B38521084';
        s.Currency_Code__c = 'EUR';
        
        s.Telephone__c = '0101887722';
        s.Remittance_Email__c = 'finance@abcinc.com';
        
        s.Contact__c = 'Jose-Antonio Morin';        
        
        s.Address_Line_1__c = 'Carretera Genral del Sur'; 
        s.Address_Line_2__c = 'TF47, km9';
        s.Address_Line_3__c = '38687b Guia de Isora';
        s.Address_Line_4__c = 'Tenerife';
        s.Address_Line_5__c = '';
        s.Post_Code__c = '38687';
        s.Country_Name__c = 'Spain';
        
        return s;       
    } 
    
    private static Sage_Account__c buildSageAccount2(){
        Sage_Account__c s = new Sage_Account__c();
        s.Is_Processed__c = false;
        s.Account_Name__c = 'The Ritz Carlton Abama';
        s.Account_Reference__c = 'ABAMA';
        s.Tax_Number__c = 'X38521084';
        s.Currency_Code__c = 'EUR';
        
        s.Telephone__c = '999 or 111';
        s.Remittance_Email__c = 'finance@abcinc.com or res@abcinc.com';
        
        s.Contact__c = 'Maria Morin';       
        
        s.Address_Line_1__c = 'Carretera Genral del Sur'; 
        s.Address_Line_2__c = 'TF47, km9';
        s.Address_Line_3__c = '38687b Guia de Isora';
        s.Address_Line_4__c = 'Tenerife';
        s.Address_Line_5__c = '';
        s.Post_Code__c = '38687';
        s.Country_Name__c = 'Spain';
        
        return s;       
    } 
}