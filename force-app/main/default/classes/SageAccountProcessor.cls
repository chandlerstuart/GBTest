/*
Name:  SageAccountProcessor.cls
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
2.0   Simon Molloy  2017-08-07      Update class to not create Business Accounts (flag) and to include more Account Record Types
2.1   Simon Molloy  2017-09-27      Changed use of Telephone__c to Formatted_Telephone__c
2.2   Simon Molloy  2017-09-27      Updated code to create muitple, individual Contact records and store Email & Phone against each one
*/
public class SageAccountProcessor implements Database.Batchable<sObject>, Database.Stateful{
    
    private Id businessAccountRTId,supplierAccountRTId,financeContactRTId;
    private Id ancillaryAccountRTId, marketingPartnerAccountRTId;
    private Integer businessAccountsCreated=0, supplierAccountsUpdated=0, financeContactsCreated=0; 
     
    public String query { get; set; }

    public List<String> nameList {get; set;}

    //Flag that can be set when this batch class is created & executed to control Account creation
    public boolean doCreate {
        get {
            if (null == doCreate) doCreate = TRUE;
            return doCreate;
        }
        set;
    }
    
    
    public Database.QueryLocator start(Database.BatchableContext BC){       
        Map<String, Id> developerNameToRTId = AppHelper.getRecordTypesByDeveloperName('Account');
        businessAccountRTId=developerNameToRTId.get('Business_Account'); //Was set to just 'Business'
        supplierAccountRTId=developerNameToRTId.get('Supplier');
        ancillaryAccountRTId=developerNameToRTId.get('Ancillary');
        marketingPartnerAccountRTId=developerNameToRTId.get('Marketing_Partner');
        
        System.debug(LoggingLevel.ERROR,'execute>businessAccountRTId:'+businessAccountRTId);        
        System.debug(LoggingLevel.ERROR,'execute>supplierAccountRTId:'+supplierAccountRTId);
        System.debug(LoggingLevel.ERROR,'execute>ancillaryAccountRTId:'+ancillaryAccountRTId);       
        System.debug(LoggingLevel.ERROR,'execute>marketingPartnerAccountRTId:'+marketingPartnerAccountRTId);
        
        developerNameToRTId = AppHelper.getRecordTypesByDeveloperName('Contact');                       
        financeContactRTId=developerNameToRTId.get('Finance');
        
        System.debug(LoggingLevel.ERROR,'execute>financeContactRTId:'+financeContactRTId);
                
        if (String.isBlank(query)){
            query = 'select Id, Name, Account_Reference__c,Account_Name__c, Currency_Code__c, Tax_Number__c, Contact__c, ';
            query += 'Telephone__c, Formatted_Telephone__c, Remittance_Email__c,Post_Code__c, Address_Line_1__c,Address_Line_2__c, Address_Line_3__c, ';
            query += 'Address_Line_4__c, Address_Line_5__c,Country_Name__c, Country_Code__c, Brand__c ';
            query += 'from Sage_Account__c where Is_Processed__c=false order by Account_Reference__c asc, CreatedDate asc, Id asc';
        }
        
        System.debug(LoggingLevel.ERROR,'start>query:'+query);
        
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Sage_Account__c> scope) {
        
        Savepoint sp;
        
        try {
            Set<String> uniqueAccountRefs = new Set<String>();
            Map<String,List<Account>> supplierSageCodeToAccounts = new Map<String,List<Account>>();
            
            System.debug(LoggingLevel.ERROR,'execute>scope.size:'+scope.size());
    
            // Note, AccountRef and SageCode both hold the Sage 200 Account Reference.
    
            // Gather unique AccountReferences.
            for (Sage_Account__c sageAccount : scope){
                if (!String.isBlank(sageAccount.Account_Reference__c)) uniqueAccountRefs.add(sageAccount.Account_Reference__c);
            }
            System.debug(LoggingLevel.ERROR,'execute>uniqueAccountRefs.size:'+uniqueAccountRefs.size());
            System.debug(LoggingLevel.ERROR,'execute>uniqueAccountRefs:'+uniqueAccountRefs);
            if (uniqueAccountRefs.isEmpty()) return;
    
            // Gather existing Supplier and Business Accounts for the same AccountReferences.
            //2017-08-07 : SM : Update to SOQL to include Ancillary & Markting Partner Record Types
            for (Account a : [select Id, Name, Supplier_Sage_Code__c, Invoice_Tax_Reference__c from Account 
                                where Supplier_Sage_Code__c in: uniqueAccountRefs and 
                                (RecordTypeId=:supplierAccountRTId or RecordTypeId=:businessAccountRTId
                                or RecordTypeId=:ancillaryAccountRTId or RecordTypeId=:marketingPartnerAccountRTId)]){
                                                                                
                if (!supplierSageCodeToAccounts.containsKey(a.Supplier_Sage_Code__c)) supplierSageCodeToAccounts.put(a.Supplier_Sage_Code__c,new List<Account>());
                supplierSageCodeToAccounts.get(a.Supplier_Sage_Code__c).add(a);
            }
            System.debug(LoggingLevel.ERROR,'execute>supplierSageCodeToAccounts.size:'+supplierSageCodeToAccounts.size());
    
            // Enumerate the SageAccounts.
            // The Ltd Accounts are first in the import file and should be the first entry for a given AccountReference.
            
            // If Supplier Accounts exist for the same Sage Code then update the Tax Reference with the TaxNumber for the first Sage Account for the Account Reference.
            // Otherwise create a new Business Account.
        
            Map<String,Account> acctRefToAccountsToInsert = new Map<String,Account>();
            Map<Id,Account> idToAccountsToUpdate = new Map<Id,Account>();       
            integer foundAccounts = 0;
            Set<String> processedAcctRefs = new Set<String>();
            for (Sage_Account__c sageAccount : scope){
                
                if (processedAcctRefs.contains(sageAccount.Account_Reference__c)) continue; 
                
                if (supplierSageCodeToAccounts.containsKey(sageAccount.Account_Reference__c)){
                    // UDPATE TAX REFERENCE ON ANY EXISTING TRADE SUPPLIER ACCOUNTS.
                    foundAccounts++;
                    processedAcctRefs.add(sageAccount.Account_Reference__c);
                    // 2017-09-27 : SM : We are not updating Account records for this run
                    /*if(!String.isBlank(sageAccount.Tax_Number__c)){
                        for (Account a : supplierSageCodeToAccounts.get(sageAccount.Account_Reference__c)){            
                            
                            if (!idToAccountsToUpdate.containsKey(a.Id)){
                                a.Invoice_Tax_Reference__c = sageAccount.Tax_Number__c;
                                idToAccountsToUpdate.put(a.Id,a);            
                            }
                        }
                        processedAcctRefs.add(sageAccount.Account_Reference__c);
                    }*/               
                    
                } else {
                    //2017-08-07 : SM : New flag controls account creation
                    if (doCreate) {
                        if (!acctRefToAccountsToInsert.containsKey(sageAccount.Account_Reference__c)){            
                            // NO EXISTING TRADE ACCOUNT - CREATE BUSINESS ACCOUNT.
                            Account a = new Account();
                            a.RecordTypeId=businessAccountRTId;
                            a.Name=sageAccount.Account_Name__c;
                            a.Supplier_Sage_Code__c = sageAccount.Account_Reference__c;
                            a.CurrencyIsoCode = sageAccount.Currency_Code__c;
                            a.Invoice_Tax_Reference__c = String.isBlank(sageAccount.Tax_Number__c) ? null : sageAccount.Tax_Number__c;
                            
                            String s = (String.isBlank(sageAccount.Address_Line_1__c) ? '' : sageAccount.Address_Line_1__c+' ') + (String.isBlank(sageAccount.Address_Line_2__c) ? '' : sageAccount.Address_Line_2__c); 
                            a.BillingStreet = String.isBlank(s) ? null : s;
                            a.BillingCity = String.isBlank(sageAccount.Address_Line_3__c) ? null : sageAccount.Address_Line_3__c;
                            
                            s = (String.isBlank(sageAccount.Address_Line_4__c) ? '' : sageAccount.Address_Line_4__c+' ') + (String.isBlank(sageAccount.Address_Line_5__c) ? '' : sageAccount.Address_Line_5__c); 
        
                            a.BillingState = String.isBlank(s) ? null : s;
                            a.BillingPostalCode = String.isBlank(sageAccount.Post_Code__c) ? null : sageAccount.Post_Code__c;
                            a.BillingCountry = String.isBlank(sageAccount.Country_Name__c) ? null : sageAccount.Country_Name__c;
        
                            acctRefToAccountsToInsert.put(sageAccount.Account_Reference__c,a); 
                            
                        }
                    }

                    processedAcctRefs.add(sageAccount.Account_Reference__c);                    
                }           
            }
            System.debug(LoggingLevel.ERROR,'execute>idToAccountsToUpdate.size:'+idToAccountsToUpdate.size());
            System.debug(LoggingLevel.ERROR,'execute>acctRefToAccountsToInsert.size:'+acctRefToAccountsToInsert.size());
            System.debug(LoggingLevel.ERROR,'execute>businessAccountRTId:'+businessAccountRTId);
            
            
            List<Database.SaveResult> saveResults;
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.allowFieldTruncation = true; // truncate oversized text data, avoid field truncation exception.
            
            sp = Database.setSavepoint();
                    
            if (!idToAccountsToUpdate.isEmpty()){                   
                saveResults = Database.update( idToAccountsToUpdate.values(), dmo );
                supplierAccountsUpdated+=idToAccountsToUpdate.size();
            }
            //2017-08-07 : SM : New flag controls account creation
            if (doCreate){
                if (!acctRefToAccountsToInsert.isEmpty()){
                    saveResults = Database.insert( acctRefToAccountsToInsert.values(), dmo );
                    businessAccountsCreated+=acctRefToAccountsToInsert.size();
                }
            }
    
            system.debug('*** -- Found ' + foundAccounts + ' Accounts -- ***');

            // Query back created Business Accounts.
            for (Account a : [select Id, Name, Supplier_Sage_Code__c from Account 
                                    where Supplier_Sage_Code__c in: uniqueAccountRefs
                                    and (RecordTypeId=:supplierAccountRTId or RecordTypeId=:businessAccountRTId
                                or RecordTypeId=:ancillaryAccountRTId or RecordTypeId=:marketingPartnerAccountRTId)]){
                if (!supplierSageCodeToAccounts.containsKey(a.Supplier_Sage_Code__c)) supplierSageCodeToAccounts.put(a.Supplier_Sage_Code__c,new List<Account>());
                supplierSageCodeToAccounts.get(a.Supplier_Sage_Code__c).add(a);
            }
            System.debug(LoggingLevel.ERROR,'execute>supplierSageCodeToAccounts.size:'+supplierSageCodeToAccounts.size());

            // Create Finance Contacts.
            List<Contact> contactsToInsert = new List<Contact>();
            Set<String> processedContacts = new Set<String>();
            String[] nameTokens;
            String s;
            Contact c;
            
            for (Sage_Account__c sageAccount : scope){
                
                // if key fields populated create a Finance contact - parent to the first Account for the Supplier_Sage_Code__c.
                if (String.isBlank(sageAccount.Contact__c) && String.isBlank(sageAccount.Remittance_Email__c) && String.isBlank(sageAccount.Telephone__c)) continue;
                
                if (String.isBlank(sageAccount.Contact__c)) sageAccount.Contact__c='Finance Contact';

                if (processedContacts.contains(sageAccount.Account_Reference__c+sageAccount.Contact__c)) continue;       
                
                integer counter = 0;
                Map<integer, Contact> contactMap = new Map<integer, Contact>();
                for (String cn : sageAccount.Contact__c.split(' or ')){         
                    c = new Contact(RecordTypeId=financeContactRTId);
    
                    if (!cn.contains(' ')){
                       c.LastName = cn; 
                    } else {
                        c.FirstName = cn.substringBefore(' ');
                        c.LastName = cn.substringAfter(' ');
                    }
                    s = (String.isBlank(sageAccount.Address_Line_1__c) ? '' : sageAccount.Address_Line_1__c + ' ');
                    s+=(String.isBlank(sageAccount.Address_Line_2__c) ? '' : sageAccount.Address_Line_2__c);
                    c.MailingStreet = String.isBlank(s) ? null : s;
                    c.MailingCity = String.isBlank(sageAccount.Address_Line_3__c) ? null : sageAccount.Address_Line_3__c;
                    s = (String.isBlank(sageAccount.Address_Line_4__c) ? '' : sageAccount.Address_Line_4__c+' ') + (String.isBlank(sageAccount.Address_Line_5__c) ? '' : sageAccount.Address_Line_5__c); 
                    c.MailingState = String.isBlank(s) ? null : s;
                    c.MailingPostalCode = String.isBlank(sageAccount.Post_Code__c) ? null : sageAccount.Post_Code__c;
                    c.MailingCountry = String.isBlank(sageAccount.Country_Name__c) ? null : sageAccount.Country_Name__c;
                    
                    contactMap.put(counter, c);
                    counter++;
                }


                if (!String.isBlank(sageAccount.Formatted_Telephone__c)){
                	Contact tc;
                	integer tCount = 0;

                	if (!sageAccount.Contact__c.containsIgnoreCase(' or ') && sageAccount.Telephone__c.containsIgnoreCase(' or ')){
                		c.Phone = sageAccount.Telephone__c.substringBefore(' or ');
                        c.OtherPhone = sageAccount.Telephone__c.substringAfter(' or ');
                        contactMap.put(tCount, c);
                	}else if (sageAccount.Contact__c.containsIgnoreCase(' or ') && sageAccount.Telephone__c.containsIgnoreCase(' or ')){
                		for (String t : sageAccount.Telephone__c.split(' or ')){
                			tc = contactMap.get(tCount);
                			tc.Phone = t;
                			contactMap.put(tCount,tc);
                			tCount++;
                		}	
                	}else {
                		tc = contactMap.get(tCount);
                		tc.Phone = sageAccount.Formatted_Telephone__c;
                		contactMap.put(tCount, tc);
                	}
                	
                }
					/*
                    if (!String.isBlank(sageAccount.Formatted_Telephone__c)){            
                        if (sageAccount.Telephone__c.containsIgnoreCase(' or ')){
                            c.Phone = sageAccount.Telephone__c.substringBefore(' or ');
                            c.OtherPhone = sageAccount.Telephone__c.substringAfter(' or ');
                        } else{
                            c.Phone = sageAccount.Formatted_Telephone__c;
                        }            
                    }
					*/
                    
				if (!String.isBlank(sageAccount.Remittance_Email__c)){
					Contact ec;
					integer eCount = 0;
					if (!sageAccount.Contact__c.containsIgnoreCase(' or ') && sageAccount.Remittance_Email__c.containsIgnoreCase(' or ')){
							c.Email = sageAccount.Remittance_Email__c.substringBefore(' ');
                            //c.Description = sageAccount.Remittance_Email__c.substringAfter(' ').removeStart('or ');
                            c.Description = sageAccount.Remittance_Email__c.substringAfter(' or ');
                            contactMap.put(eCount, c);
                    }else if (sageAccount.Contact__c.containsIgnoreCase(' or ') && sageAccount.Remittance_Email__c.containsIgnoreCase(' or ')){
                    	for (String e : sageAccount.Remittance_Email__c.split(' or ')){
                			ec = contactMap.get(eCount);
                			ec.Email = e;
                			contactMap.put(eCount,ec);
                			eCount++;
                		}
                    }else {
						ec = contactMap.get(eCount);
                		ec.Email = sageAccount.Remittance_Email__c;
                		contactMap.put(eCount, ec);
					}

				}            
					/*
                    if (!String.isBlank(sageAccount.Remittance_Email__c)){            
                        if (sageAccount.Remittance_Email__c.contains(' ')){                
                            c.Email = sageAccount.Remittance_Email__c.substringBefore(' ');
                            c.Description = sageAccount.Remittance_Email__c.substringAfter(' ').removeStart('or ');
                        } else {
                            c.Email = sageAccount.Remittance_Email__c;
                        }
                    }
                    */

                for (Contact cm : contactMap.values()){ 
                    if (supplierSageCodeToAccounts.get(sageAccount.Account_Reference__c) != null){
                        cm.AccountId = supplierSageCodeToAccounts.get(sageAccount.Account_Reference__c)[0].Id; //first Account for the account reference.        
                        contactsToInsert.add(cm);
                        sageAccount.Is_Processed__c = true;    
                    }
                }
                processedContacts.add(sageAccount.Account_Reference__c+sageAccount.Contact__c);
            } // Sage Account import record.
            System.debug(LoggingLevel.ERROR,'execute>contactsToInsert.size:'+contactsToInsert.size());
            
            // Insert the Finance Contacts.
            if (!contactsToInsert.isEmpty()){ 
                saveResults = Database.insert( contactsToInsert, dmo );
                financeContactsCreated+=contactsToInsert.size();
            }
            
            // Finally update the Is_Processed_Flag__c field on the Sage Account import record. 
            update scope;
            
        } catch(Exception e){
            if (sp!=null) Database.rollback(sp);
            
            System.debug(LoggingLevel.ERROR,e.getMessage());
            System.debug(LoggingLevel.ERROR,e.getStackTraceString());
        }
    }
    
    public void finish(Database.BatchableContext BC){ 
        System.debug(LoggingLevel.ERROR,'finish>businessAccountsCreated:'+businessAccountsCreated);
        System.debug(LoggingLevel.ERROR,'finish>supplierAccountsUpdated:'+supplierAccountsUpdated);
        System.debug(LoggingLevel.ERROR,'finish>financeContactsCreated:'+financeContactsCreated);
    }   
}