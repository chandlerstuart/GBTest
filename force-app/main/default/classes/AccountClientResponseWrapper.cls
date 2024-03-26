/**
* @author -         Abrar Haq (Accenture)
* @date -           12/04/2016
* @description -    A response wrapper class of Client type Account
* #############Change Log#############
* Modified by     Version     Change Date
**/
public with sharing class AccountClientResponseWrapper{
    public String SalesforceClientID;
    public String GolfbreaksClientID; // Golfbreaks_Person_Id__c
    public List<UpdatedFields> lstUpdatedFields;
    public class UpdatedFields{
        public String Field;
        public String OldValue;
        public String NewValue;        
    }    
}