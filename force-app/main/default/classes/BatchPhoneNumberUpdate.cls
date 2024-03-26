/**************************************************************
@author - Simon Molloy (Golfbreaks)
@date - 10/08/2016
@description - Batch class to update phone numbers - removing spaces
***************************************************************/
global class BatchPhoneNumberUpdate implements Database.Batchable<sObject> {

    global String query {get; set;}
    
    global BatchPhoneNumberUpdate(){
        //query = 'select Id, Phone, PersonHomePhone, PersonMobilePhone from Account where (Phone != null OR PersonMobilePhone != null OR PersonHomePhone != null)';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        if (null == query){
            query = 'select Id, Phone, PersonHomePhone, PersonMobilePhone from Account where (Phone != null OR PersonMobilePhone != null OR PersonHomePhone != null)';
        }
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope){

         for (Account a : scope){

             if (a.Phone != null) a.Phone = a.Phone.replaceAll( '\\s+', '');
             if (a.PersonHomePhone != null) a.PersonHomePhone = a.PersonHomePhone.replaceAll( '\\s+', '');
             if (a.PersonMobilePhone != null) a.PersonMobilePhone = a.PersonMobilePhone.replaceAll( '\\s+', '');

         }
            
         update scope;
    }
    
    global void finish(Database.BatchableContext BC){
        //EMPTY
    }

}