/*
Name:  OpportunityCreationWizardController.cls
======================================================
======================================================
Purpose:
-------
Controller for Opportunity Creation Wizard VF Page

======================================================
======================================================
History
------- 
Ver. Author         Date        Detail
1.0  Simon Molloy   2017-06-28  Initial development.
1.1  Mark Cane      2017-07-17  MC tagged modifications (line:327 & line:363)
1.2  Simon Molloy   2017-08-14  Added in LeadSource validation & field processing on Opportunity
1.3  Simon Molloy   2017-09-26  Added showNewsletterSignup boolean to show Newsletter Signup for NEW Clients only
*/
public with sharing class OpportunityCreationWizardController {
    public final integer lastPage = 2; 
    public integer page {
        get {
            if (null == page) page = 1;
            return page;
        }
        set;
    }
    public List<SelectOption> salesUsers {
        get {
            if (null == salesUsers){
                salesUsers = new List<SelectOption>();
                List<Id> profileIdList = new List<Id>();
                
                for (Profile p : [select Id, Name from Profile where (Name = 'Golfbreaks Sales User' OR Name = 'Golfbreaks Sales Manager')]){
                    profileIdList.add(p.Id);
                }
                for (User u : [select Id, Name from User where ProfileId in :profileIdList AND IsActive = TRUE ORDER BY NAME ASC]){
                    salesUsers.add(new SelectOption(u.Id, u.Name));
                }
            }
            return salesUsers;
        }
        set;
    }

    //Opportunity Lead Source pick list
    public List<SelectOption> leadSources {
        get {
            if (null == leadSources){
                leadSources = new List<SelectOption>();
                leadSources.add(new SelectOption('','--None--'));
                for (String s : SalesLeadSource__c.getAll().keySet()){
                    leadSources.add(new SelectOption(s,s));
                }
            }
            return leadSources;
        }
        set;
    }

    //Opportunity Stages pick list
    public List<SelectOption> oppStages {
        get {
            if (null == oppStages){
                oppStages = new List<SelectOption>();
                oppStages.add(new SelectOption('','--None--'));
                for (String s : SalesOpportunityStages__c.getAll().keySet()){
                    oppStages.add(new SelectOption(s,s));
                }
            }
            oppStages.sort();
            return oppStages;
        }
        set;
    }
    //Lead Booker options
    public List<SelectOption> leadBookerOpts {
        get {
            if (null == leadBookerOpts){
                leadBookerOpts = new List<SelectOption>();
                leadBookerOpts.add(new SelectOption('','--None--'));
                leadBookerOpts.add(new SelectOption('Yes','Yes'));
                leadBookerOpts.add(new SelectOption('No','No'));
            }
            return leadBookerOpts;
        }
        set;
    }
    //Recursive callout variable
    public boolean calloutMade {
        get {
            if (null == calloutMade) calloutMade = FALSE;
            return calloutMade;
        }
        set;
    }

    public Lead enquiryForm {get; set;}
    public Opportunity oppForm {get; set;}
    public boolean inviteToBreakpoints {
        get {
            if (null == inviteToBreakpoints) inviteToBreakpoints = FALSE;
            return inviteToBreakpoints;
        }
        set;
    }
    public boolean showInviteToBreakpoints {
        get {
            if (null == showInviteToBreakpoints) showInviteToBreakpoints = TRUE;
            return showInviteToBreakpoints;
        }
        set;
    }
    public boolean showNewsletterSignup {
        get {
            if (null == showNewsletterSignup) showNewsLetterSignup = TRUE;
            
            return showNewsletterSignup;
        }
        set;
    }
    
    public boolean showIsPGA {
        get {
            if (null == showIsPGA) showIsPGA = TRUE;
            
            return showIsPGA;
        }
        set;
    }
    public String selectedStage {get; set;}
    public String opportunityOwnerId {get; set;}
    public String whichRegion {get; set;}
    public String travelDate {get; set;}
    public String diaryDate {get; set;}
    public String newOppId {get; set;}
    public String newAccId {get; set;}
    public List<String> selectedCountries {get; set;}
    public List<SelectOption> countryOptions {get; set;}

    //MAP Of Country by Sales Region (for dependant pick list)
    public Map<String, String> countryMap {
        get {
            if (null == countryMap){
                countryMap = new Map<String, String>();
                countryMap.put('England & Wales',ApplicationConstant.SALESREGIONGROUP_UK_IRELAND);
                countryMap.put('Ireland',ApplicationConstant.SALESREGIONGROUP_UK_IRELAND);
                countryMap.put('Scotland',ApplicationConstant.SALESREGIONGROUP_UK_IRELAND);
                countryMap.put('Austria',ApplicationConstant.SALESREGIONGROUP_EUROPE);
                countryMap.put('Belgium',ApplicationConstant.SALESREGIONGROUP_EUROPE);
                countryMap.put('Czech Republic',ApplicationConstant.SALESREGIONGROUP_EUROPE);
                countryMap.put('Estonia',ApplicationConstant.SALESREGIONGROUP_EUROPE);
                countryMap.put('Finland',ApplicationConstant.SALESREGIONGROUP_EUROPE);
                countryMap.put('Germany',ApplicationConstant.SALESREGIONGROUP_EUROPE);
                countryMap.put('Holland',ApplicationConstant.SALESREGIONGROUP_EUROPE);
                countryMap.put('Hungary',ApplicationConstant.SALESREGIONGROUP_EUROPE);
                countryMap.put('Iceland',ApplicationConstant.SALESREGIONGROUP_EUROPE);
                countryMap.put('Latvia',ApplicationConstant.SALESREGIONGROUP_EUROPE);
                countryMap.put('Lithuania',ApplicationConstant.SALESREGIONGROUP_EUROPE);
                countryMap.put('Slovenia',ApplicationConstant.SALESREGIONGROUP_EUROPE);
                countryMap.put('Sweden',ApplicationConstant.SALESREGIONGROUP_EUROPE);
                countryMap.put('Switzerland',ApplicationConstant.SALESREGIONGROUP_EUROPE);
                countryMap.put('Portugal',ApplicationConstant.SALESREGIONGROUP_EUROPE);
                countryMap.put('Spain',ApplicationConstant.SALESREGIONGROUP_EUROPE);
                countryMap.put('France',ApplicationConstant.SALESREGIONGROUP_EUROPE);
                countryMap.put('Italy',ApplicationConstant.SALESREGIONGROUP_EUROPE);
                countryMap.put('Bulgaria',ApplicationConstant.SALESREGIONGROUP_MIDHAUL);
                countryMap.put('Canary Islands',ApplicationConstant.SALESREGIONGROUP_MIDHAUL);
                countryMap.put('Cyprus',ApplicationConstant.SALESREGIONGROUP_MIDHAUL);
                countryMap.put('Greece',ApplicationConstant.SALESREGIONGROUP_MIDHAUL);
                countryMap.put('Morocco',ApplicationConstant.SALESREGIONGROUP_MIDHAUL);
                countryMap.put('Tunisia',ApplicationConstant.SALESREGIONGROUP_MIDHAUL);
                countryMap.put('Turkey',ApplicationConstant.SALESREGIONGROUP_MIDHAUL);
                countryMap.put('Abu Dhabi',ApplicationConstant.SALESREGIONGROUP_LONGHAUL);
                countryMap.put('Barbados',ApplicationConstant.SALESREGIONGROUP_LONGHAUL);
                countryMap.put('Dominican Republic',ApplicationConstant.SALESREGIONGROUP_LONGHAUL);
                countryMap.put('Dubai',ApplicationConstant.SALESREGIONGROUP_LONGHAUL);
                countryMap.put('Jamaica',ApplicationConstant.SALESREGIONGROUP_LONGHAUL);
                countryMap.put('Malaysia',ApplicationConstant.SALESREGIONGROUP_LONGHAUL);
                countryMap.put('Mauritius',ApplicationConstant.SALESREGIONGROUP_LONGHAUL);
                countryMap.put('Mexico',ApplicationConstant.SALESREGIONGROUP_LONGHAUL);
                countryMap.put('Qatar',ApplicationConstant.SALESREGIONGROUP_LONGHAUL);
                countryMap.put('South Africa',ApplicationConstant.SALESREGIONGROUP_LONGHAUL);
                countryMap.put('Thailand',ApplicationConstant.SALESREGIONGROUP_LONGHAUL);
                countryMap.put('USA',ApplicationConstant.SALESREGIONGROUP_LONGHAUL);
                countryMap.put('United Arab Emirates',ApplicationConstant.SALESREGIONGROUP_LONGHAUL);
            }
            return countryMap;
        }
        set;
    }
    //Sales Region pick list
    public List<SelectOption> regionOptions {
        get {
            if (null == regionOptions){
                regionOptions = new List<SelectOption>();
                regionOptions.add(new SelectOption('','--None--'));
                regionOptions.add(new SelectOption(ApplicationConstant.SALESREGIONGROUP_UK_IRELAND,ApplicationConstant.SALESREGIONGROUP_UK_IRELAND));
                regionOptions.add(new SelectOption(ApplicationConstant.SALESREGIONGROUP_EUROPE,ApplicationConstant.SALESREGIONGROUP_EUROPE));
                regionOptions.add(new SelectOption(ApplicationConstant.SALESREGIONGROUP_MIDHAUL,ApplicationConstant.SALESREGIONGROUP_MIDHAUL));
                regionOptions.add(new SelectOption(ApplicationConstant.SALESREGIONGROUP_LONGHAUL,ApplicationConstant.SALESREGIONGROUP_LONGHAUL));
            }
            return regionOptions;
        }
        set;
    }

    //Called from VF page to get dependant pick list values
    public PageReference getCountries(){
        system.debug('*** -- getCountries Called -- ***');
        if (null == oppForm.SalesRegion__c) return null;

        countryOptions = buildCountryOptions(oppForm.SalesRegion__c);

        return null;

    }

    //Used in Opportunity.AdditionalInformation__c field
    public String tarfbagInput {
        get {
            if (null == tarfbagInput){
                tarfbagInput = 'T - ' + '\n';
                tarfbagInput += 'A - ' + '\n';
                tarfbagInput += 'R - ' + '\n';
                tarfbagInput += 'F - ' + '\n';
                tarfbagInput += 'B - ' + '\n';
                tarfbagInput += 'A - ' + '\n';
                tarfbagInput += 'G - ' + '\n';
                tarfbagInput += 'S - ';
            }
            return tarfbagInput;
        }
        set;
    }
    public Id existingClientId{get; set;}
    public Account client {get; set;}
    public Account oldClient {get; set;} //Account record to track changes
    
    //CONSTRUCTOR
    public OpportunityCreationWizardController(){
        enquiryForm = new Lead();
        oppForm = new Opportunity();

        //EXISTING CLIENT CODE 
        if (null != ApexPages.currentPage().getParameters().get('accid')){
            client = [select Id, FirstName, LastName, PersonEmail, PersonMobilePhone, PersonHomePhone, Salutation,
                                NewsletterSignup__c, Is_PGA__pc, Breakpoints_Invite_Sent__c,
                                PersonMailingStreet, PersonMailingPostalCode, Gender__c
                                from Account where Id = :ApexPages.currentPage().getParameters().get('accid') LIMIT 1];
                                
            if (null != client){
                oldClient = client;
                enquiryForm.LastName = client.LastName;
                enquiryForm.FirstName = client.FirstName;
                enquiryForm.Email = client.PersonEmail;
                enquiryForm.MobilePhone = client.PersonMobilePhone;
                enquiryForm.Phone = client.PersonHomePhone;
                enquiryForm.Salutation = client.Salutation;
                enquiryForm.NewsletterSignup__c = client.NewsletterSignup__c;
                enquiryForm.PGA__c = client.Is_PGA__pc;
                //Address fields
                enquiryForm.Street = client.PersonMailingStreet;
                enquiryForm.PostalCode = client.PersonMailingPostalCode;
                if (client.Breakpoints_Invite_Sent__c) showInviteToBreakpoints = FALSE;
                //enquiryForm.PreferredContactMethod__c = client.PreferredContactMethod__c;

                oppForm.AccountId = client.Id;
                //AccountId, GolfbreaksEnquiryId__c, Integration_Error_Log__c
                showNewsletterSignup = FALSE;
                showIsPGA = FALSE;
            }
        }//END EXISTING CLIENT CODE

        //Defaulting Nights & Travel Group Size to zero as per Salesforce UI
        oppForm.Nights__c = 0;
        oppForm.TravelGroupSize__c = 0;
        oppForm.OwnerId = UserInfo.getUserId();
        oppForm.CloseDate = Date.today();
        oppForm.RecordTypeId = ApplicationConstant.getRecordTypeId('Opportunity','NewSalesOpportunity');
        oppForm.AdditionalInformation__c = tarfbagInput;
        oppForm.SalesRegion__c = getDefaultSalesRegion();
        oppForm.LeadSource = ApplicationConstant.LEAD_SOURCE_PHONE;
        getCountries();         
    }
    
    private boolean phoneValidator(String phoneValue){
        Pattern phonePattern = Pattern.compile('\\+[0-9 ]+');
        Matcher phoneMatcher = phonePattern.matcher(phoneValue);
        return phoneMatcher.matches();
    }

    public PageReference next(){ 
        //Try / Catch block
        try {
            boolean doSave = FALSE;
            system.debug('*** -- Calling NEXT -- ***');
            if (page < lastPage){
                if (1 == page){
                    //Validate Phone fields
                    if (enquiryForm.Phone != null){
                        if (!phoneValidator(enquiryForm.Phone)){
                            enquiryForm.Phone.addError('Only numbers, \'+\' and spaces are allowed. (e.g. +44 123 1234567 or +441231234567)');
                            return null;
                        }
                    }
                    if (enquiryForm.MobilePhone != null){
                        if (!phoneValidator(enquiryForm.MobilePhone)){
                            enquiryForm.MobilePhone.addError('Only numbers, \'+\' and spaces are allowed. (e.g. +44 123 1234567 or +441231234567)');
                            return null;
                        }
                    }

                    if (null == oppForm.SalesRegion__c){
                        oppForm.SalesRegion__c.addError('Please select a Sales Region');
                        return null;
                    }

                    if (null != oppForm.SalesRegion__c && selectedCountries.isEmpty()){
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,' Please select at least one Country of Interest'));
                        return null;
                    }


                    if (null != client){
                        system.debug('*** -- Check if we Save Account -- ***');
                        //DO WE SAVE THE ACCOUNT
                        if (enquiryForm.LastName != oldClient.LastName){
                            client.LastName = enquiryForm.LastName;
                            doSave = TRUE;
                        } 
                        if (enquiryForm.FirstName != oldClient.FirstName){
                            client.FirstName = enquiryForm.FirstName;
                            doSave = TRUE;
                        }
                        if (enquiryForm.Email != oldClient.PersonEmail){
                            client.PersonEmail = enquiryForm.Email;
                            doSave = TRUE;
                        }
                        if (enquiryForm.Phone != oldClient.PersonHomePhone){
                            client.PersonHomePhone = enquiryForm.Phone;
                            doSave = TRUE;
                        }
                        if (enquiryForm.MobilePhone != oldClient.PersonMobilePhone){
                            client.PersonMobilePhone = enquiryForm.MobilePhone;
                            doSave = TRUE;
                        }
                        if (enquiryForm.Salutation != oldClient.Salutation){
                            client.Salutation = enquiryForm.Salutation;
                            doSave = TRUE;
                        }
                        //2017-08-11 : SM : Make sure the Gender field is populated correctly on the Client record
                        if (populateGenderAccount(client)){
                            doSave = TRUE;
                        }
                        if (enquiryForm.NewsletterSignup__c != oldClient.NewsletterSignup__c){
                            client.NewsletterSignup__c = enquiryForm.NewsletterSignup__c;
                            doSave = TRUE;
                        }
                        if (enquiryForm.PGA__c != oldClient.Is_PGA__pc){
                            client.Is_PGA__pc = enquiryForm.PGA__c;
                            doSave = TRUE;
                        }
                        if (enquiryForm.Street != oldClient.PersonMailingStreet){
                            client.PersonMailingStreet = enquiryForm.Street;
                            doSave = TRUE;
                        }
                        if (enquiryForm.PostalCode != oldClient.PersonMailingPostalCode){
                            client.PersonMailingPostalCode = enquiryForm.PostalCode;
                            doSave = TRUE;
                        }

                        if (inviteToBreakpoints){
                            client.Send_Breakpoints_Invite__c = inviteToBreakpoints;
                            doSave = TRUE;
                        }

                    }

                    if (null != selectedCountries){
                        String joinCountries = String.join(selectedCountries, ';');
                        oppForm.CountriesInterested__c = joinCountries;
                    }

                    //We need to callout to clubhouse before saving any records back to Salesforce

                    system.debug('*** -- Call out to clubhouse -- ***');
                    if (null == oppForm.StageName) oppForm.StageName = ApplicationConstant.RECOMMENDATIONSTAGE;

                    String calloutResponse;
                    //Recursive variable
                    if (!calloutMade){
                        calloutResponse = calloutToClubhouse();
                        
                        //calloutMade = TRUE; //MC flag moved to success response - to allow data correction and retry.
                    
                        if (null != calloutResponse){
                            if (calloutResponse.contains('ERROR')){
                                //CALLOUT FAILED - 'split' the response message and return the message to the user
                                String[] msgSplit = calloutResponse.split(';');
                                //Msg format is STATUS_CODE ; "ERROR" ; RESPONSE_MESSAGE
                                String pageMsg = msgSplit[2];

                                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,' ' + pageMsg));
                                return null;
                            } else {
                                calloutMade = TRUE;
                                
                                //Re-select the Opp for last page processing
                                oppForm = [select Id, Name, StageName, DiaryDate__c, DiaryDateNote__c, 
                                            Call_Back_Hour__c, Call_Back_Minute__c, Nights__c, TravelGroupSize__c,
                                            SalesRegion__c, CountriesInterested__c, Rounds__c, NumberOfNonGolfers__c,
                                            AdditionalInformation__c, GolfbreaksEnquiryId__c, PreferredContactMethod__c,
                                            PreferredTravelDate__c, CurrentOwnerOpp__c, OwnerId, AccountId,
                                            Venue__c, RoomTypes__c, LeadBooker__c, LeadSource
                                            from Opportunity where Id = :oppForm.Id LIMIT 1];
                                selectedStage = oppForm.StageName;
                                newOppId = oppForm.Id;
                                newAccId = oppForm.AccountId;
                            }
                        }
                    }
                    
                    system.debug('*** -- doSave = ' + doSave + ' -- ***');
                    if (doSave){
                        try {
                            update client;
                        }catch (DmlException dmlEx){
                            system.debug('*** -- Error saving Account ' + dmlEx + ' -- ***');
                            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,' Error Saving Client record - please contact Salesforce Admin'));
                            return null;
                        }
                    }
                }
                //Page counter variable
                //page = page + 1; //MC - only ever 1 or 2.
                if (page==1) page = 2;
            } 
        }catch (Exception e){
            system.debug('*** -- Error going NEXT ' + e + ' at ' + e.getLineNumber() + ' -- ***');
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,' Something went wrong processing your request.  Please contact Salesforce Admin.'));
            return null;
        }   
        return null;
    }
    
    //2017-07-14 : SM : No longer needed for Phase 1 but keeping code in case its needed for Phase 2
    /*
    public PageReference previous(){
        system.debug('*** -- Calling PREVIOUS -- ***');
        if(page > 1){
            page = page - 1;
        }
        return null;
    }
    */

    //2017-07-25 : SM : method to set Gender on Account based on following rules:
    //2017-07-25 : SM : Ms / Miss / Mrs = FEMALE
    //2017-07-25 : SM : All other = MALE
    private boolean populateGenderAccount(Account acc){
        String genderAssign;
        boolean isUpdated = FALSE;
        if (null != acc){
            if (null != acc.Salutation){
                if ('Ms.'.equalsIgnoreCase(acc.Salutation) || 
                    'Mrs.'.equalsIgnoreCase(acc.Salutation) ||
                    'Miss.'.equalsIgnoreCase(acc.Salutation)){
                    genderAssign = AP04_LeadTriggerBL.GENDER_FEMALE;
                }else {
                    genderAssign = AP04_LeadTriggerBL.GENDER_MALE;
                }
            }else {
                genderAssign = AP04_LeadTriggerBL.GENDER_MALE;
            }

            if (acc.Gender__c != genderAssign){
                acc.Gender__c = genderAssign;
                isUpdated = TRUE;
            }
        }

        return isUpdated;
    }

    public PageReference finish(){
        system.debug('*** -- Calling FINISH -- ***');
        try {
            
                //Make sure the Lead Source is set
                if (null == oppForm.LeadSource){
                    oppForm.LeadSource.addError('Please a Lead Source');
                    return null;   
                }

                //Make sure Travel Date is set correctly
                system.debug('*** -- travelDate ' + travelDate + '-- ***');
                if (null != travelDate){
                    String[] tSplit = travelDate.split('/');
                    Date tDate = Date.newInstance(integer.valueOf(tSplit[2]), integer.valueOf(tSplit[1]), integer.valueOf(tSplit[0]));
                    oppForm.PreferredTravelDate__c = tDate;
                }
                
                //Make sure Dirary Date is set correctly
                system.debug('*** -- diaryDate ' + diaryDate + '-- ***');
                if (null != diaryDate){
                    String[] dSplit = diaryDate.split('/');
                    Date dDate = Date.newInstance(integer.valueOf(dSplit[2]), integer.valueOf(dSplit[1]), integer.valueOf(dSplit[0]));
                    oppForm.DiaryDate__c = dDate;
                }
                try {
                    update oppForm;
                }catch (DmlException dmlEx){
                    system.debug('*** -- Error updating Opp ' + dmlEx + '-- ***');
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'There was an error saving the Opportunity - please contact Salesforce Admin'));
                    return null;
                }

                enquiryForm = null;
                oppForm = null;
                calloutMade = FALSE;
                page = 9;

            
        }catch (Exception e){
            system.debug('*** -- Error going FINISH ' + e + ' at ' + e.getLineNumber() + ' -- ***');
            system.debug('*** -- Error going FINISH ' + e + ' at ' + e.getMessage() + ' -- ***');
            system.debug('*** -- Error going FINISH ' + e + ' at ' + e.getStackTraceString() + ' -- ***');
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,' Something went wrong processing your request.  Please contact Salesforce Admin.'));
            return null;    
        }

        return null;
    }

    //Call to Clubhouse to create Enquiry & create / get Client
    private String calloutToClubhouse(){
        system.debug('*** -- Into calloutToClubhouse -- ***');
        //Before we call out, makes sure we have an Opportunity Name populated
        if (null == oppForm.Name) oppForm.Name = (client != null ? client.FirstName + ' ' + client.LastName + ' - ' + formatDate(Date.today()) : enquiryForm.FirstName + ' ' + enquiryForm.LastName + ' - ' + formatDate(Date.today()));
        //Build the request wrapper
        system.debug('*** -- Opp Owner: ' + oppForm.OwnerId + ' -- ***');
        EnquiryClientRequestWrapper requestWrapper = buildRequestWrapper(enquiryForm, oppForm);
        system.debug('*** -- Wrapper: ' + requestWrapper + ' -- ***');
        //Call out to Clubhouse
        String response = WS01_RebarHTTPCallout.outboundMessageCallerOpportunity(oppForm, requestWrapper);
        system.debug('*** -- Call out response: ' + response + ' -- ***');
        return response;
    }

    //Call out to User Role to Sales Region custom setting to determin default Sales Region for the User
    private String getDefaultSalesRegion(){
        User u = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId() LIMIT 1];
        
        if (null != u.UserRole.Name){
            UserRoleSalesRegion__c ursr = UserRoleSalesRegion__c.getInstance(u.UserRole.Name);
            if (null != ursr){
                return ursr.SalesRegion__c;
            }else {
                return null;
            }
        }

        return null;
    }

    public EnquiryClientRequestWrapper buildRequestWrapper(Lead enquiryForm, Opportunity oppForm){
        Map<String, String> salesRegionMap = getSalesRegionMap();
        EnquiryClientRequestWrapper enqClientRequestWrapper = new EnquiryClientRequestWrapper();
        enqClientRequestWrapper.AdditionalInformation = oppForm.AdditionalInformation__c;
        if (null != client){
            system.debug('*** -- We have a client -- ***');
            enqClientRequestWrapper.ClientAccountID = client.Id;
            enqClientRequestWrapper.Email = client.PersonEmail;
            enqClientRequestWrapper.FirstName = client.FirstName;
            enqClientRequestWrapper.LastName = client.LastName;
            enqClientRequestWrapper.Title = client.Salutation;
            enqClientRequestWrapper.Salutation = client.Salutation;
            enqClientRequestWrapper.IsPGA = client.Is_PGA__pc;
            enqClientRequestWrapper.NewsletterSignUp = client.NewsletterSignup__c;
              
        }else {
            system.debug('*** -- We DO NOT have a client -- ***');
            enqClientRequestWrapper.ClientAccountID = null;
            enqClientRequestWrapper.Email = enquiryForm.Email;
            enqClientRequestWrapper.FirstName = enquiryForm.FirstName;
            enqClientRequestWrapper.LastName = enquiryForm.LastName;
            enqClientRequestWrapper.Title = enquiryForm.Salutation;  
            enqClientRequestWrapper.Salutation = enquiryForm.Salutation;   
            enqClientRequestWrapper.IsPGA = enquiryForm.PGA__c;
            enqClientRequestWrapper.NewsletterSignUp = enquiryForm.NewsletterSignUp__c;

        }
        enqClientRequestWrapper.Nights = oppForm.Nights__c;
        enqClientRequestWrapper.Phone = getPhone(enquiryForm);
        enqClientRequestWrapper.PreferredTravelDate = oppForm.PreferredTravelDate__c;
        enqClientRequestWrapper.TravelGroupSize = oppForm.TravelGroupSize__c;
        enqClientRequestWrapper.TripRegion = salesRegionMap.get(oppForm.SalesRegion__c);
        enqClientRequestWrapper.VenueAccountIDs = new List<String>();
        List<User> leadownerList = [Select Email, Id, Golfbreaks_Employee_Id__c FROM User WHERE Id =: UserInfo.getUserId() Limit 1]; 
        enqClientRequestWrapper.AccountManager = new EnquiryClientRequestWrapper.EmployeeModel(Integer.valueOf(leadownerList[0].Golfbreaks_Employee_Id__c), leadownerList[0].Email, '','');

        return enqClientRequestWrapper;

    }

    //Sales Region value map for the 'TripRegion' value in the wrapper
    private Map<String, String> getSalesRegionMap() {
        
        Map<String, String> salesRegionMap = new Map<String, String>();
        salesRegionMap.put('', '0');
        salesRegionMap.put(ApplicationConstant.SALESREGIONGROUP_UK_IRELAND, '1');
        salesRegionMap.put(ApplicationConstant.SALESREGIONGROUP_EUROPE, '2');
        salesRegionMap.put(ApplicationConstant.SALESREGIONGROUP_USA, '3');
        salesRegionMap.put(ApplicationConstant.SALESREGIONGROUP_FDP, '3');
        salesRegionMap.put(ApplicationConstant.SALESREGIONGROUP_LONGHAUL, '4');
        salesRegionMap.put(ApplicationConstant.SALESREGIONGROUP_MIDHAUL, '4');
        return salesRegionMap;
    }
    //Format date to a String
    private String formatDate(Date inDate){
        String yr = String.valueOf(inDate.year()).replace(',','');
        String mth = ('0' + String.valueOf(inDate.month())).right(2);
        String dy = ('0' + String.valueOf(inDate.day())).right(2);

        return dy + '/' + mth + '/' + yr;
    }

    //Build the list of Country options based on SalesRegion
    private List<SelectOption> buildCountryOptions(String salesRegion){
        List<SelectOption> sOptions = new List<SelectOption>();
        Map<String, SelectOption> sOptionMap = new Map<String, SelectOption>();
        for (String c : countryMap.keySet()){
            if (countryMap.get(c).equalsIgnoreCase(salesRegion)){
                sOptionMap.put(c, new SelectOption(c,c));
            }
        }

        //We have some default ordering custom settings to go through to order the countries displayed
        List<CountryOrdering__c> coList = [select Name, Order__c from CountryOrdering__c ORDER BY Order__c ASC];
        Map<String, CountryOrdering__c> countries = CountryOrdering__c.getAll();
        Map<String, String> checkMap = new Map<String, String>();
        integer counter = 0;
        List<SelectOption> returnedList = new List<SelectOption>();
        for (CountryOrdering__c co : coList){
            returnedList.add(sOptionMap.get(co.Name));
            checkMap.put(co.Name, co.Name);
        }
        //Add the specially ordered countries first
        for (integer i = 0 ; i < sOptionMap.values().size() ; i++){
            SelectOption so = sOptionMap.values().get(i);
            if (!checkMap.containsKey(so.getValue())){
                returnedList.add(so);
            }
        }

        return returnedList;
    }
    //Return the populated Phone field for the request wrapper
    private String getPhone(Lead leadRecord){
        if(!String.isBlank(leadRecord.MobilePhone)) {
            return leadRecord.MobilePhone;
        } else if (!String.isBlank(leadRecord.Phone)) {
            return leadRecord.Phone;
        } else {
            return leadRecord.HomePhone__c;
        }
    }
}