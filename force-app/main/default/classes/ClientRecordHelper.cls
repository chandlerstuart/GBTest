/*
Name:  ClientRecordHelper.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Client Record Helper class

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-06-10  Initial development.
1.1  J Radcliffe   2019-06-13  Bug Fix - Invalid conversion from runtime type Decimal to String
1.2  J Radcliffe   2019-06-14  Bug Fix - Account Id Missing from Property Cache
1.3  J Radcliffe   2019-08-09  Bug Fix - containsKey is case sensitive. Setting values to lowerCase
1.4  J Radcliffe   2019-08-09  Bug Fix - Exclude 'Job Applicant' from Client Lookup
1.5  Mark Cane&    2019-08-16  Bug Fix - removed record type dependency to allow unit tests to pass in SO with no RT/PA.
1.5  J Radcliffe   2019-08-21  Replacing Client Record Helper with DuplicateManagementHelper
*/
public with sharing class ClientRecordHelper {
    
    
    /*  ======================================================
        Method: queryExistingClients
        Params: List of Enquiries related to ActionTypes.
        Returns: Boolean (false=runtime exception). 
        Purpose: 
        
        Queries for existing clients based on Email only.
        The property e.clientDetails.accountId is set which prevents Clubhouse enquiry set.

        Todo:
        
        DONE  ----> (1) Unit tests.

        ----------------
        Revision History
        ----------------
        Ver. Author        Date        Detail
        1.0  Mark Cane&    2019-05-13  Initial development.
        1.1  J Radcliffe   2019-06-13  Bug Fix - Invalid conversion from runtime type Decimal to String
        1.2  J Radcliffe   2019-06-14  Bug Fix - Account Id Missing from Property Cache
        1.3  J Radcliffe   2019-08-09  Bug Fix - containsKey is case sensitive. Setting values to lowerCase
        1.4  J Radcliffe   2019-08-09  Bug Fix - Exclude 'Job Applicant' from Client Lookup
        ======================================================
    */
    /*1.5
    public static Boolean queryExistingClients(List<EnquiryManager.Enquiry> enquiries){   
        try {

            Set<String> emailAddresses = new Set<String>();

            for (EnquiryManager.Enquiry e : enquiries){
                if (e.isAborted) continue;

                if (String.isNotBlank(e.clientDetails.email)){
                    e.clientDetails.email = e.clientDetails.email.toLowerCase();//1.3+
                    emailAddresses.add(e.clientDetails.email);
                } 
            }
            if (emailAddresses.isEmpty()) return true;

            String emailFieldName =  Schema.sObjectType.Account.fields.getMap().containsKey( 'isPersonAccount' ) ? 'PersonEmail' : 'Fax';//allow unit testing via standard Fax field.
            String identifierFieldName =  Schema.sObjectType.Account.fields.getMap().containsKey( 'Golfbreaks_Person_Id__c' ) ? 'Golfbreaks_Person_Id__c' : 'Description';//allow unit testing via a standard field.
        
            //1.5- String q='select Id,'+emailFieldName+','+identifierFieldName+' from Account where RecordType.DeveloperName != \'Job_Applicant\' and '+emailFieldName+' in:emailAddresses';//1.4~
            String q='select Id,'+emailFieldName+','+identifierFieldName+' from Account where '+emailFieldName+' in:emailAddresses';//1.4~,1.5~
            if (DescribeHelper.getObjectFieldMap('Account').containsKey('RecordTypeId')) q+=' and RecordType.DeveloperName != \'Job_Applicant\'';//1.5+

            String emailAddress, clientId, externalId;

            Map<String,String> emailToClientId = new Map<String,String>();
            for (SObject o : Database.query(q)){

                emailAddress = ((String)o.get(emailFieldName)).toLowerCase();//1.3~
                clientId = (String)o.get('Id');
                //externalId = (String)o.get(identifierFieldName);<--1.1
                externalId = String.valueOf(o.get(identifierFieldName)); //1.1

                emailToClientId.put(emailAddress,clientId+'-'+externalId);
            }
            if (emailAddresses.isEmpty()) return true;

            for (EnquiryManager.Enquiry e : enquiries){
                if (e.isAborted) continue;

                if (String.isNotBlank(e.clientDetails.email) &&
                    emailToClientId.containsKey(e.clientDetails.email)){
                
                    e.clientDetails.accountId = emailToClientId.get(e.clientDetails.email).split('-')[0];
                    e.propertyCache.put('ClientDetails.accountId',e.clientDetails.accountId);//1.2
                    e.bookingSystemClientId = emailToClientId.get(e.clientDetails.email).split('-')[1];
                    e.propertyCache.put('bookingSystemClientId',e.bookingSystemClientId);
                }
            }
            return true;

        } catch(Exception ex){  LogHelper.logExceptions(ex, 'ClientRecordHelper', 'queryExistingClients'); }
        return false;
    }*/
}