/**
* @author -         Merari Cebrian (Accenture)
* @date -           14/04/2016
* @description -    A request wrapper class of Client type Enquiry
* #############Change Log#############
* Ver. Author        Date        Detail
*1.0  Merari C.      2016-05-11 Initial development.
*1.1  Simon M.       2017-04-21 Added new property RecordTypeDeveloperName
*1.2  James R.		 2018-05-29 Added new property SalesRegions - The sales regions that the enquiry should cover.
**/
public with sharing class EnquiryClientRequestWrapper{ 
    
    public String AdditionalInformation;
    public Decimal AffiliateCampaignID;
    public String SalesChannel;
    public String ClientAccountID;
    public String Email;
    public String PersonEmail;
    public String PersonMobilePhone;
    public String PersonHomePhone;
    public String PersonOtherPhone;
    public String Title;
    public String FirstName;
    public String LastName;
    public boolean NewsletterSignUp;
    public boolean IsPGA;
    public Decimal Nights;
    public String Phone; 
    public Datetime PreferredTravelDate;
    public String PromotionCode;
    public String Salutation;
    public Decimal TravelGroupSize;
    public String TripRegion;
    public String Venue;
    public List<String> VenueAccountIDs;
    public EmployeeModel AccountManager;
    //2017-04-21 : SM : New property to store Record Type Name for 'Is PGA' type Accounts
    public String RecordTypeDeveloperName;
    //1.2 - SalesRegions
    public String[] SalesRegions;
    
    /*************************************************************************************** 
    Developer -    Merari Cebrian (Accenture)
    Date -         2016-05-11
    Version -      1.0 
    Function -     LeadConvertResult
    #############Change Log#############
    Modified by     Version     Change Date 
    ****************************************************************************************/
    public class EmployeeModel {
        public Integer GolfbreaksEmployeeID;
        public String Email;
        public String Forename;
        public String Surname;
        public EmployeeModel(Integer GolfbreaksEmployeeID, String Email, String Forename, String Surname){
            this.GolfbreaksEmployeeID = GolfbreaksEmployeeID;
            this.Email = Email;
            this.Forename = Forename;
            this.Surname = Surname;
        }
    }
}