/*
Name: EnquiryAPIV1Request.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Enquiry API V1 Request Class Structure

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2019-05-21  Initial development.
1.1  Mark Cane&    2019-06-03  Removed username and additionalFields parameters.
1.2  J Radcliffe   2019-06-07  Added 'preferredContactMethod' parameter
1.3  J Radcliffe   2019-06-17  new Inner Class - Client Address
1.4  J Radcliffe   2019-06-27  removed round property
1.5  J Radcliffe   2020-01-13  New 'source' and 'tealiumId' properties
1.6  J Radcliffe   2020-01-28  New 'languagePreferenceCode' property
1.7  J Radcliffe   2020-02-12  Changing name of 'source' property (see 1.5) to 'accountSource' for consistency with ApexAction and field mapping
1.6  J Radcliffe   2020-03-04  New Properties (to support project Sarazen): accountRecordTypeId, languagePreferenceCode, enquiryType
1.7  J Radcliffe   2020-04-04  New property (for the Data Import tool): suppressWelcomeEmail
1.8  J Radcliffe   2020-03-20  Re-instating 'rounds' as a property of the API
1.9  J Radcliffe   2020-03-31  New property: 'timeZone' - The customer's timeZone (to help the agent understand when customer should be contacted)
1.10 J Radcliffe   2020-05-11  New properties: 'tournamentName','region','stateOrCounty'
1.11 J Radcliffe   2020-07-07  New property: isTest - To be to true when web enquiries are identifiable as Tests (for ring-fencing test records)
1.12 J Radcliffe   2020-10-01  New Class (CompetitionInformation) - To collect details regarding Competition entries + Plus PGA Tour Marketing Preference
1.13 J Radcliffe   2021-04-21  New ClientDetails property: referredBy - To be populated with the identifier for a Client who's referral resulted in this Action Type request. e.g. Portal sign up invitations from the Lead Booker. Typically this property will be populated with the SF Account Id (for directly mapping to created records), but could accept other identifiers such as an email in combination with a request handler to lookup the Account.
1.14 J Radcliffe   2021-11-10  New marketing tracking properties to support attribution modelling
1.15 J Radcliffe   2023-03-02  New channel marketing attribute - email, and email subscription types.
1.16 J Radcliffe   2023-04-04  New properties: accountSourceDetails & isPGAPro
1.17 J Radcliffe   2024-02-12  New properties: utmReferrer & utmSearchTerm 
*/
global with sharing class EnquiryAPIV1Request {
    
    public EnquiryAPIV1Request.ClientDetails clientDetails;
    public EnquiryAPIV1Request.TripDetails tripDetails;
    public EnquiryAPIV1Request.MarketingPreferences marketingPreferences;
    public EnquiryAPIV1Request.TaskDetails taskDetails;
    public EnquiryAPIV1Request.TrackingInformation trackingInformation;
    public EnquiryAPIV1Request.CompetitionInformation competitionInformation;//1.12+

    global EnquiryAPIV1Request(){}
    
    global String actionTypeName { get; set; } //Required
    global Boolean isTest { get; set; } //1.11+
    //1.1- global String username {get;set;} //Required - Identifier for caller (i.e. golfbreaksUK, golfbreaksScandi etc)
    //1.1 - global Map<String,Object> additionalFields {get;set;}
    

    global class ClientDetails {
        global String accountId {get; set;} //<-- If null, a find or create is performed
        global String memberNumber {get;set;}
        global String firstName {get; set;} 
        global String lastName {get; set;}
        global String email {get; set;}
        global String mobilePhone {get; set;}
        global String workPhone {get; set;}
        global String homePhone {get; set;}
        global String otherPhone {get; set;}
        global String salutation {get; set;}
        global String accountSource {get; set;}//1.5+ //1.7~
        global String accountSourceDetails {get;set;}//1.16+
        global String languagePreferenceCode {get; set;}//1.6+ e.g. en-GB, sv, en-US
        global String preferredContactMethod {get; set;} //e.g. Phone, Email
        global EnquiryAPIV1Request.ClientAddress clientAddress;//1.3
        global String accountRecordTypeId {get; set;}//1.6+
        global String timeZone {get; set;}//1.9+ 
        global String referredBy {get; set;}//1.13+
        global Boolean isPGAPro {get;set;}//1.16+
    }

    global class TripDetails{
        global String territoryId {get; set;} //<-- If null the territory is derived from the Business Unit & Countries
        global Integer groupSize {get;set;}
        global String rounds {get;set;} //1.4- //1.8+
        global Integer nights {get;set;}
        global String additionalInformation {get;set;}
        global String venue {get;set;}
        global Date travelDate {get;set;}
        global List<String> countries {get;set;} 
        global DateTime callBackDateTime {get;set;}
        global String source {get;set;}
        public Boolean tournamentEnquiry {get;set;}
        public String associationId {get;set;}
        public String basketDetails {get;set;}
        public String currencyISOCode {get;set;}
        public List<String> specialistSkills {get;set;}
        public Decimal amount {get;set;}
        public Decimal transactionAuthorisedAmount {get;set;}
        global String enquiryType {get; set;}//1.6+
        global String tournamentName {get;set;}//1.10+
        global String region {get;set;}//1.10+
        global String stateOrCounty {get;set;}//1.10+
    }

    global class TaskDetails{
        public String bookingId {get; set;}
        public String subject { get; set; }
        public String origin { get; set; }
        public String detail { get; set; }
        public String type {get;set;}
    }

    global class MarketingPreferences{
        //IMPORTANT - Marketing Preferences are tri-state: 
        //false = Unsubscribe
        //true = Subscribe
        //null = Ignore

        //Channel
        global Boolean phone { get; set; }
        global Boolean sms { get; set; }
        global Boolean brochure { get; set; }
        global Boolean email { get; set; }//1.15+

        //Email Subscriptions
        global Boolean seasonalNewsletter { get; set; }
        global Boolean weeklyNewsletter { get; set; }
        global Boolean tournamentsNewsletter { get; set; }//1.15+
        global Boolean eventsNewsletter { get; set; }//1.15+

        //Other
        global Boolean pgaTour { get; set; } //1.12+
        global String changeReason { get; set; }//<--- Derive from Action Type
        global Boolean suppressWelcomeEmail {get; set;}//1.7+
    }

    global class TrackingInformation{
        global String campaignId {get;set;} //Incl in Enquiry API Call to CH //Lead //Opp 
        global String sessionId {get;set;} //Ident for particular web visit //Lead //Opp 
        global String googleAnalyticsClientId {get;set;} //GA generated identifier for the device //Lead //Opp
        global String googleAnalyticsClickId {get;set;} //GA generated identifier for clicks //Lead //Opp
        global String tealiumId {get; set;} // Identifier for tealium client record //1.5+
        global String utmSource {get; set;} //1.14+ Marketing tracking property to support attribution modelling
        global String utmMedium {get; set;} //1.14+ Marketing tracking property to support attribution modelling
        global String utmCampaign {get; set;} //1.14+ Marketing tracking property to support attribution modelling
        global String additionalTrackingInformation  {get; set;} //1.14+ - General property for mapping trackig details to long text area field(s) in Salesforce (expected JSON string)
        global String utmReferrer {get;set;} //1.17+ The source website where the client or enquiry originates.
        global String utmSearchTerm {get;set;}//1.17+ The search term entered by the customer/prospect. 
    } 

    //1.3
    global class ClientAddress{
        global String street {get;set;}
        global String city {get;set;}
        global String state {get;set;}
        global String country {get;set;}
        global String postalCode {get;set;}
    }

    //1.12
    global class CompetitionInformation{ 
        global String competitionName {get;set;} //Name of the Competition
        global String customerAnswer {get;set;} //The customer's submitted answer
    }

}