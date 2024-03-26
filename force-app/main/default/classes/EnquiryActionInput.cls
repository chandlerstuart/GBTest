/*
Name: EnquiryActionInput.cls
Copyright @ 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------
Enquiry Action Input Class Structure.

Note - @InvocableVariable annotation required for Action interface;
this can't be added to class or property - so no inner classes.

Todo:
        
    TODO ----> (1) Add modifiers - @InvocableVariable(label='yourLabel' description='yourDescription' required=(true | false))
    TODO ----> (2) ...

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-06-13  Initial development.
1.1  J Radcliffe   2019-06-17  new input variables (client address)
1.2  Mark Cane&    2019-06-20  Added action type override properties.
1.3  J Radcliffe   2019-06-21  Added new Trip Details property; roomTypes
1.4  J Radcliffe   2019-06-24  Added new Trip Details property; numberOfNonGolfers
1.5  J Radcliffe   2019-06-27  Changed data type of 'rounds' from Integer to String (to allow for 'unlimited') - Sam B Request
1.6  J Radcliffe   2019-07-09  Added new Trip Details property; bookingSystemRecordOwnerId
1.7  J Radcliffe   2019-09-04  New Client Details Property - bypassDupeCheck - Skips matching rules (force creates the Client)
1.8  J Radcliffe   2020-03-04  New properties to support the Sarazen project: accountRecordTypeId, enquiryType, currencyISOCode, languagePreferenceCode
1.9  J Radcliffe   2020-02-06  New 'accountSource' property
1.10 J Radcliffe   2020-05-28  New 'sendToExternal' property - If true the Client will be sent to the external booking system (even if there is no related enquiry)
1.11 Mark Cane&    2020-06-10  Bug fixes. Commented out duplicate propertyName accountSource.
1.12 J Radcliffe   2021-11-10  New properties for UTM Tracking
1.13 J Radcliffe   2023-03-02  New poperty - email (marketing channel)
1.14 J Radcliffe   2023-03-20  New preferences tournamentsNewsletters and eventsNewsletters
1.15 J Radcliffe   2023-04-04  New properties - accountSourceDetails & isPGAPro
*/
global with sharing class EnquiryActionInput {
    
    global EnquiryActionInput(){}
 
    @InvocableVariable
    global String actionTypeName;

    // Action type overrides
    @InvocableVariable
    global String enquiryRecordTypeId;//1.2+

    @InvocableVariable
    global String recordName;//1.2+

    @InvocableVariable
    global String recordStatus;//1.2+

    @InvocableVariable
    global String bookingSystem;//1.2+

    @InvocableVariable
    global String businessUnitId;//1.2+

    @InvocableVariable
    global Boolean routeOnCreate;//1.2+

    @InvocableVariable
    global Boolean sendToExternal;//1.10+

    // Client details
    @InvocableVariable
    global String accountId;
    
    @InvocableVariable
    global String memberNumber;
    
    @InvocableVariable
    global String firstName;
    
    @InvocableVariable
    global String lastName;
    
    @InvocableVariable
    global String email;
    
    @InvocableVariable
    global String mobilePhone;
    
    @InvocableVariable
    global String workPhone;
    
    @InvocableVariable
    global String homePhone;
    
    @InvocableVariable
    global String otherPhone;
    
    @InvocableVariable
    global String salutation;

    @InvocableVariable
    global String languagePreferenceCode;//1.8+
    
    @InvocableVariable
    global String preferredContactMethod;

    @InvocableVariable
    global Boolean bypassDupeCheck;//1.7+

    @InvocableVariable
    global String accountSource;//1.9+

    @InvocableVariable
    global String accountSourceDetails;//1.15+

    @InvocableVariable
    global String accountRecordTypeId;//1.8+

    @InvocableVariable
    global Boolean isPGAPro;//1.15+

    //1.11- @InvocableVariable
    //1.11- global String accountSource;

    //  Client Address <--1.1
    @InvocableVariable
    global String street;

    @InvocableVariable
    global String city;

    @InvocableVariable
    global String state;

    @InvocableVariable
    global String country;

    @InvocableVariable
    global String postalCode;

    // Trip details
    @InvocableVariable
    global String territoryId;
    
    @InvocableVariable
    global Integer groupSize;
    
    @InvocableVariable
    global String rounds;//1.5
    
    @InvocableVariable
    global Integer nights;
    
    @InvocableVariable
    global String additionalInformation;
    
    @InvocableVariable
    global String venue;
    
    @InvocableVariable
    global Date travelDate;
    
    @InvocableVariable
    global List<String> countries;
    
    @InvocableVariable
    global DateTime callBackDateTime;
    
    @InvocableVariable
    global String source;
    
    @InvocableVariable
    global Boolean tournamentEnquiry;
    
    @InvocableVariable
    global String associationId;
    
    @InvocableVariable
    global String basketDetails;
    
    @InvocableVariable
    global String currencyISOCode;
    
    @InvocableVariable
    global List<String> specialistSkills;
    
    @InvocableVariable
    global Decimal amount;
    
    @InvocableVariable
    global Decimal transactionAuthorisedAmount;

    @InvocableVariable
    global String roomTypes;//1.3+

    @InvocableVariable
    global Integer numberOfNonGolfers;//1.3+

    @InvocableVariable
    global String bookingSystemRecordOwnerId;//1.6

    @InvocableVariable
    global String enquiryType;//1.8+

    // Task details
    @InvocableVariable
    global String bookingId;
    
    @InvocableVariable
    global String subject;
    
    @InvocableVariable
    global String origin;
    
    @InvocableVariable
    global String detail;
    
    @InvocableVariable
    global String type;

    // Marketing preferences.
    @InvocableVariable
    global Boolean phone;
    
    @InvocableVariable
    global Boolean sms;

    @InvocableVariable
    global Boolean subscribedToEmail;//1.13
    
    @InvocableVariable(label='Seasonal Newsletter' description='Manage Seasonal Newsletter subscription. true = subscribe, false = opt out/unsubscribe, null = no change')
    global Boolean seasonalNewsletter;
    
    @InvocableVariable(label='Weekly Newsletter' description='Manage Weekly Newsletter subscription. true = subscribe, false = opt out/unsubscribe, null = no change')
    global Boolean weeklyNewsletter;

    @InvocableVariable(label='Tournaments Newsletter' description='Manage Tournaments Newsletter subscription. true = subscribe, false = opt out/unsubscribe, null = no change')
    global Boolean tournamentsNewsletter;//1.14+

    @InvocableVariable(label='Events Newsletter' description='Manage Events Newsletter subscription. true = subscribe, false = opt out/unsubscribe, null = no change')
    global Boolean eventsNewsletter;//1.14+
    
    @InvocableVariable
    global Boolean brochure;
    
    @InvocableVariable
    global String changeReason;

    //Tracking 

    @InvocableVariable//1.12+
    global String utmSource;

    @InvocableVariable//1.12+
    global String utmMedium;

    @InvocableVariable//1.12+
    global String utmCampaign;

}