/*
Name:  FindDuplicateAccountsAction.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Apex Action class for Finding Duplicate Accounts (Id)
based on input params

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-09-03  Initial development.
*/
global with sharing class FindDuplicateAccountsAction {

    @InvocableMethod(label='Find Dupe Accounts Action' description='Retrieve a list of Account matches (Ids) based on the input values')
    global static List<DuplicateSearchOutput> findDuplicates(List<DuplicateSearchInput> inputs) {

        try{

            if(inputs==null || inputs.size()==0 || inputs[0].actionTypeName == null) return null;

            //Constants
            final String clientAccountRecordTypeDevName = 'Client';

            DuplicateSearchInput details = inputs[0];
            Account acc = new Account();

            //If Person Account Fields do not exist (PA not enabled) substitue with a standard business account field (for deployment/unit test purposes)

            //Get Account Field Map
            List<String> fieldList = new List<String>();
            for(String field : Schema.sObjectType.Account.fields.getMap().keySet()){//1.1+
                fieldList.add(field.toUpperCase());
            }

            String firstNameFieldName = (fieldList.contains('FIRSTNAME'))? 'FirstName':'Name';
            String lastNameFieldName =(fieldList.contains('LASTNAME'))? 'LastName':'AccountSource';
            String emailFieldName = (fieldList.contains('PERSONEMAIL'))? 'PersonEmail':'Fax';
            String mobileFieldName = (fieldList.contains('PERSONMOBILEPHONE'))? 'PersonMobilePhone':'Industry';
            String phoneFieldName = (fieldList.contains('PHONE'))? 'Phone':'Phone';
            String homePhoneFieldName = (fieldList.contains('PERSONHOMEPHONE'))? 'PersonHomePhone':'Type';
            String streetFieldName = (fieldList.contains('PERSONMAILINGSTREET'))? 'PersonMailingStreet':'ShippingStreet';
            String postCodeFieldName = (fieldList.contains('PERSONMAILINGPOSTALCODE'))? 'PersonMailingPostalCode':'ShippingPostalCode';
            String cityFieldName = (fieldList.contains('PERSONMAILINGCITY'))? 'PersonMailingCity':'ShippingCity';
            String countryFieldName = (fieldList.contains('PERSONMAILINGCOUNTRY'))? 'PersonMailingCountry':'ShippingCountry';
            String recordTypeFieldName = (fieldList.contains('RECORDTYPEID'))? 'RecordTypeId':'SicDesc';

            if(details.FirstName != null) acc.put(firstNameFieldName,details.FirstName);
            if(details.LastName != null) acc.put(lastNameFieldName,details.LastName);
            if(details.Email != null) acc.put(emailFieldName,details.Email);
            if(details.MobilePhone != null) acc.put(mobileFieldName,details.MobilePhone);
            if(details.HomePhone != null) acc.put(homePhoneFieldName,details.HomePhone);
            if(details.WorkPhone != null) acc.put(phoneFieldName,details.WorkPhone);    
            if(details.MailingStreet != null) acc.put(streetFieldName,details.MailingStreet);
            if(details.MailingCity != null) acc.put(cityFieldName,details.MailingCity);
            if(details.MailingPostalCode != null) acc.put(postCodeFieldName,details.MailingPostalCode);
            if(details.MailingCountry != null) acc.put(countryFieldName,details.MailingCountry);   
            if(details.RecordTypeDeveloperName != null) acc.put(recordTypeFieldName,(Test.isRunningTest())?'fakeRecTypeId':Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(details.RecordTypeDeveloperName).getRecordTypeId());    

            List<String> duplicateIds = DuplicateManagementHelper.getDuplicateAccountIds(acc, details.actionTypeName);

            List<DuplicateSearchOutput> dsos = new List<DuplicateSearchOutput>();
            dsos.add(new DuplicateSearchOutput(duplicateIds));
            return dsos;
        }catch(exception e){
            LogHelper.logExceptions(e, 'FindDuplicateAccountsAction', 'findDuplicates');
            //[Removed for release] system.debug('Error>FindDuplicateAccountsAction>findDuplicates>'+e);
        }
        return null;

    }


    global class DuplicateSearchInput{
    
        global DuplicateSearchInput(){}

        @InvocableVariable
        global String actionTypeName;

        @InvocableVariable
        global String RecordTypeDeveloperName;

        @InvocableVariable
        global String FirstName;

        @InvocableVariable
        global String LastName;

        @InvocableVariable
        global String Email;

        @InvocableVariable
        global String MobilePhone;

        @InvocableVariable
        global String HomePhone;

        @InvocableVariable
        global String WorkPhone;        

        @InvocableVariable
        global String MailingStreet;

        @InvocableVariable
        global String MailingCity;

        @InvocableVariable
        global String MailingPostalCode;

        @InvocableVariable
        global String MailingCountry;

    }

    global class DuplicateSearchOutput{
        
        @InvocableVariable
        global List<String> dupeAccountIdsList;

        // Action type overrides
        @InvocableVariable
        global String dupeAccountIdsString;

        global DuplicateSearchOutput(List<String> duplicateIds){
            if(duplicateIds != null){
                dupeAccountIdsList = duplicateIds;
                dupeAccountIdsString = String.join(duplicateIds,',');
            }
        }

        

    }


}