/**
* @author -         Abrar Haq (Accenture)
* @date -           12/04/2016
* @description -    A request wrapper class of Client type Account
* #############Change Log#############
* Modified by     Version     Change Date
* Simon M         1.2         26-09-2017   Added 'Is PGA' flag
* James R         1.3         14-03-2018   Added in Address models for SFDC addresses
* James R         1.4         11-06-2018   Added nullToEmpty method
**/
public with sharing class AccountClientRequestWrapper{
    public String ClientAccountID; // Salesforce Record ID
    public String Salutation;
    public String FirstName;
    public String LastName;
    public String PersonEmail;
    public String PersonMobilePhone;
    public String PersonHomePhone;
    public String PersonOtherPhone;
    public Boolean NewsletterSignup;
    public Boolean IsPGA; // Is_PGA__pc
    public SalesforceAddressModel SalesforceAddress;    
    
    public boolean returnValue(){
        return true;
    }
    /*
public String SalesChannel; // Sales_Channel__c
public Boolean IsSensitive; // Is_Sensitive__pc
public Boolean IsBlacklisted; // Is_Blacklisted__pc
public Boolean IsPress; // Is_Press__pc
public Boolean IsVIP; // Is_VIP__pc

public Boolean IsDeceased; // Is_Deceased__pc
public Boolean BondHolder; // Bond_Holder__pc
public Date BirthDate;
public Date LastLogin; // Last_Login__pc
public Date LoginCreated; // Login_Created__pc
public Date LoyaltyQualificationDate; // Loyalty_Qualification_Date__pc
*/
    
    //SalesforceAddressModel - overloaded constructors to accept Strings, or an Account
    public class SalesforceAddressModel {
        public String Street;
        public String City;
        public String Country;
        public String PostalCode;
        public String State;
        
        public SalesforceAddressModel(String inStreet, String inCity, String inCountry, String inPostalCode, String inCounty){
            this.Street = nullToEmpty(inStreet);
            this.City = nullToEmpty(inCity);
            this.Country = nullToEmpty(inCountry);
            this.PostalCode = nullToEmpty(inPostalCode);
            this.State = nullToEmpty(inCounty);
        }   
        
        public SalesforceAddressModel(Account inAccount){
            this.Street = nullToEmpty(inAccount.PersonMailingStreet);
            this.City = nullToEmpty(inAccount.PersonMailingCity);
            this.Country = nullToEmpty(inAccount.PersonMailingCountry);
            this.PostalCode = nullToEmpty(inAccount.PersonMailingPostalCode);
            this.State = nullToEmpty(inAccount.Mailing_State_County__pc);
        }
    }
    
    //1.4 - Clubhouse will ignore null values. This method returns an empty string for any field values that are null to ensure they are cleared in Clubhouse. If not null, the field value is returned 
    public static String nullToEmpty(String fieldValue){
        
        if(null == fieldValue){
            return '';
        }else{
            return fieldValue;
        }

    }
    
    
}