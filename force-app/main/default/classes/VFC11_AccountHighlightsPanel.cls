/*
Name:  VFC11_AccountHighlightsPanel.cls
======================================================
======================================================
Purpose:
-------
Controller class for VF Page VFP11_AccountHighlightsPanel

======================================================
======================================================
History
------- 
Ver. Author          Date        Detail
1.0  Simon Molloy    2017-06-02  Initial development.
1.1  Simon Molloy  	 2017-09-11  New method to retrieve Client Profile records
1.2  James Radcliffe 2018-05-04  Added 'Last Audit' dev
1.3  James Radcliffe 2019-02-21  Client type Colouring (Repeat = Green, Enquired (Never Booked) = Orange)
*/
global class VFC11_AccountHighlightsPanel 
{
    public final String CLASS_NAME = 'VFC11_AccountHighlightsPanel';
    private Account accountRec;
    public boolean hasErrors {
        get {
            if (null == hasErrors) hasErrors = false;
            return hasErrors;
        }
        set;
    }
    //public List<String> alertMessagesList{get; private set;}
    public List<String> alertMessagesforsalesList{get; private set;}

    public List<RecordWrapper> recentRecords {
        get {
            if (null == recentRecords) recentRecords = new List<RecordWrapper>();

            return recentRecords;
        }
        set;
    }
    public Id leadId {get; set;}
    public RecordWrapper leadRecord {get; set;}
    public RecordWrapper bookingRecord {get; set;}
    public RecordWrapper caseRecord {get; set;}
    public RecordWrapper opportunityRecord {get; set;}
    public String preferredAgentImage {get; set;}
    public boolean newsletterUpdate {get; set;}
    public Individual ind {get;set;}
    public String tableColour {
        get {
            if (null == tableColour) tableColour = 'GhostWhite';
            return tableColour;
        }
        set;
    }
    public integer openCaseCount {
        get {
            if (null == openCaseCount) openCaseCount = 0;

            return openCaseCount;
        }
        set;
    }
    
        
    // Subscription data
    public String lastAudit {get;set;}
    public string weeklyNewsletterState {
        get {
            if (null == weeklyNewsletterState) weeklyNewsletterState = 'null';
            return weeklyNewsletterState;
        }
        set;
    }
    public string quarterlyNewsletterState {
        get {
            if (null == quarterlyNewsletterState) quarterlyNewsletterState = 'null';
            return quarterlyNewsletterState;
        }
        set;
    }
    public string smsState {
        get {
            if (null == smsState) smsState = 'null';
            return smsState;
        }
        set;
    }
    public string postState {
        get {
            if (null == postState) postState  = 'null';
            return postState;
        }
        set;
    }
    public string phoneState {
        get {
            if (null == phoneState) phoneState = 'null';
            return phoneState;
        }
        set;
    }
    
    
    public Account acc {get; set;}
    public boolean showModal {
        get {
            if (null == showModal) showModal = true;
            return showModal;
        }
        set;
    }

    //Boolean flag to determine if we show the Client Profile records
    public boolean showClientProfiles {
        get {
            if (null == showClientProfiles) showClientProfiles = FALSE;
            return showClientProfiles;
        }
        set;
    }
    
    //List of Client Profile records
    public List<Client_Profile__c> clientProfiles {get; set;}
    public integer clientProfileCount {get; set;}
    public String profilePopUp {get; set;}

    public VFC11_AccountHighlightsPanel(ApexPages.StandardController stdController)     
    {   
        this.accountRec = (Account)stdController.getRecord();
        //this.alertMessagesList = getAlertMessages();
        this.alertMessagesforsalesList = getAlertMessagesForSales();

        buildRecordWrappers(this.accountRec.Id);

        showModal = (acc.Notification_Message__c == null ? false : true);

        //2017-07-06 : SM : This code is not needed for Phase 1
        /*
        if (null != accountRec.Preferred_Agent__c){

            ConnectApi.UserDetail userDetail = ConnectApi.ChatterUsers.getUser(Network.getNetworkId(),accountRec.Preferred_Agent__c);
            ConnectApi.Photo userPhoto = userDetail.photo;
            system.debug('*** -- photo : ' + userPhoto.url + ' -- ***');
            this.preferredAgentImage = userPhoto.smallPhotoUrl;
            system.debug('*** -- preferredAgentImage -- ***');
            system.debug(preferredAgentImage);
        //}
        */
        
        if (acc.TotalBookingsCount__c>0) tableColour = '#e0f7aa';//1.3
        if (acc.TotalBookingsCount__c==0 && acc.TotalOpportunitiesCount__c >0) tableColour = '#ffe589';//1.3
        
        if (acc.Is_Blacklisted__pc) tableColour = 'DarkSalmon';
        if (!acc.Is_Blacklisted__pc && (acc.Is_Concierge__c || acc.Is_VIP__pc)) tableColour = 'Gold';
        

        //Call method to retrieve Client Profiles for the current Account
        this.clientProfiles = getClientProfiles();

        newsletterUpdate = FALSE;
        if (null == acc.Newsletter_Interest__c || ('NO'.equalsIgnoreCase(acc.Newsletter_Interest__c ) && 
                                                    acc.Newsletter_Interest_Registered__c < System.now().addMonths(-3))){
            newsletterUpdate = TRUE;
        }
        
        //Subscription Data
        List<Individual> individuals = [SELECT Account__c, Brochure__c, Phone__c, SMS__c, Weekly_Newsletter__c, Quarterly_Newsletter__c, Data_Audit_Last_Completed__c from Individual WHERE Account__c = :this.accountRec.Id];
        if (!individuals.isEmpty()) {
        	ind = individuals[0];
            
            if(ind.Data_Audit_Last_Completed__c!=null && ind.Data_Audit_Last_Completed__c>system.today().addMonths(-3)){
                lastAudit = 'sub';
            }else{
                lastAudit = 'unsub';
            }
            
            //SMS
            if (ind.sms__c == true)
            {smsState = 'sub';} else {smsState = 'unsub';}
            
            //Postal
            if (ind.Brochure__c == true && (!String.isBlank(this.accountRec.PersonMailingPostalCode) && !String.isBlank(this.accountRec.PersonMailingStreet)))
            {
                //System.Debug('has address ' + this.accountRec.BillingPostalCode);
                postState = 'sub';} 
            else if ((String.isBlank(this.accountRec.PersonMailingPostalCode) || String.isBlank(this.accountRec.PersonMailingStreet)) && ind.Brochure__c)
            {postState='alert';}
            else {postState = 'unsub';}    

            //Email
            if (ind.Weekly_Newsletter__c == true)
            {weeklyNewsletterState = 'sub';} else {weeklyNewsletterState = 'unsub';}
            if (ind.Quarterly_Newsletter__c == true)
            {quarterlyNewsletterState = 'sub';} else {quarterlyNewsletterState = 'unsub';}
            
            //Phone
            if (ind.Phone__c == true)
            {phoneState = 'sub';} else {phoneState = 'unsub';}
            
		}

    }   
    
    public PageReference saveUpdates(){
        if (this.accountRec.PersonHomePhone != acc.PersonHomePhone) this.accountRec.PersonHomePhone = acc.PersonHomePhone;
        if (this.accountRec.PersonMobilePhone != acc.PersonMobilePhone) this.accountRec.PersonMobilePhone = acc.PersonMobilePhone;
        if (this.accountRec.Phone != acc.Phone) this.accountRec.Phone = acc.Phone;
        if (this.accountRec.PersonOtherPhone != acc.PersonOtherPhone) this.accountRec.PersonOtherPhone = acc.PersonOtherPhone;
        if (this.accountRec.PersonEmail != acc.PersonEmail) this.accountRec.PersonEmail = acc.PersonEmail;

        updateAccount(this.accountRec);

        return null;
    }

    //2017-07-06 : SM : Not being used in this phase
    /*
    public PageReference saveLead(){
        //String leadId = ApexPages.currentPage().getParameters().get('leadId');
        system.debug('*** -- Lead Id in saveLead ' + leadId + ' -- ***');
        List<Lead> leadList = [select Id, Status from Lead where Id = :leadId LIMIT 1];
        if (!leadList.isEmpty()){
            leadList[0].Status = ApplicationConstant.LEAD_STATUS_CONTACT_ATTEMPTED;
            update leadList[0];
        }

        return null;
    }
    */

    public PageReference updateNewsletterSubscribe(){
        system.debug('*** -- updateNewsletterSubscribe with ' + this.accountRec.NewsletterSignUp__c + ' -- ***');

        if (this.accountRec.NewsletterSignUp__c) {
            this.accountRec.NewsletterSignUp__c = FALSE;
            this.accountRec.Newsletter_Interest__c = 'No';
            this.accountRec.Newsletter_Interest_Registered__c = System.now();
        }else {
            this.accountRec.NewsletterSignUp__c = TRUE;
            this.accountRec.Newsletter_Interest__c = 'Yes';
            this.accountRec.Newsletter_Interest_Registered__c = System.now();
        }

        updateAccount(this.accountRec);

        return null;

    }

    public PageReference emailBreakpointsInvite(){
        system.debug('*** -- emailBreakpointsInvite -- ***');
        //Call out to WS01_RebarHTTPCallout class
        boolean didSend;
        if (test.isRunningTest()){
            didSend = true;
        }else {
            didSend = WS01_RebarHTTPCallout.emailBreakpointsInvite(String.valueOf(this.accountRec.Id));
        }
        system.debug('*** -- emailBreakpointsInvite is ' + didSend + ' -- ***');
        if (didSend){
            system.debug('*** -- updating Account -- ***');
            this.accountRec.Breakpoints_Invite_Sent__c = TRUE;

            updateAccount(this.accountRec);
            
        }
        system.debug('*** -- Account field ' + this.accountRec.Breakpoints_Invite_Sent__c + ' -- ***');
        return null;
    }

    public PageReference clearMessage(){
        this.accountRec.Notification_Message__c = null;

        updateAccount(this.accountRec);

        return null;
    }

    /*
    webservice static void setContactAttempted(String whichId){
        system.debug('*** -- SET CONTACT ATTEMPTED -- ***');
        system.debug('*** -- whichId = ' + whichId + ' -- ***');
        if (null == whichId) return;

        if (whichId.indexOf('00Q') > 0){
            //Its a LEAD
            Lead l = [select Id, Status from Lead where Id = :whichId LIMIT 1];
            if (ApplicationConstant.LEAD_STATUS_NEW.equalsIgnoreCase(l.Status)){
                l.Status = ApplicationConstant.LEAD_STATUS_CONTACT_ATTEMPTED;
                update l;
            }
        }

        return;
    }
    */

    private void buildRecordWrappers(Id accId){
        List<Account> accList = [select Id, Notification_Message__c, Notification_Message_Author__c,
                                    Notification_Message_Author__r.Name, 
                                    Notification_Message_Created__c, NewsletterSignUp__c, Is_Blacklisted__pc, 
                                    Is_Concierge__c, Is_VIP__pc, Is_PGA__pc, PersonHomePhone, Phone, PersonMobilePhone, PersonOtherPhone, 
                                    IsPersonAccount, Bond_Holder__pc, PersonEmail, 
                                    Golfbreaks_Person_Id__c, Latest_Review__c, Breakpoints_Invite_Sent__c,
                                    Newsletter_Interest__c, Newsletter_Interest_Registered__c, TotalBookingsCount__c , TotalOpportunitiesCount__c, 
                        (Select Id, FirstName, LastName, Name, CreatedDate from Leads__r where 
                            IsConverted = FALSE Order By CreatedDate ASC LIMIT 1),
                        (Select Id, Name, Booking_Date__c, Travel_Date__c from Bookings__r where 
                            (Travel_Date__c != null AND Travel_Date__c > TODAY) Order By Travel_Date__c ASC LIMIT 1),
                        (Select Id, CaseNumber, Subject, CreatedDate from Cases where 
                            IsClosed = FALSE Order By CreatedDate ASC),
                        (Select Id, Name, StageName from Opportunities where 
                            IsClosed = FALSE and 
                            RecordTypeId = :ApplicationConstant.getRecordTypeId('Opportunity','NewSalesOpportunity') 
                            Order By LastModifiedDate ASC LIMIT 1)
                            from Account where Id = :accId LIMIT 1];
        acc = accList[0];

        for (Lead l : acc.Leads__r){
            leadRecord = new RecordWrapper(l);
            recentRecords.add(leadRecord);
        }
        for (Booking__c b : acc.Bookings__r){
            bookingRecord = new RecordWrapper(b);
            recentRecords.add(bookingRecord);
        }

        //We are pulling ALL Cases, so only process the first for the panel
        if (!acc.Cases.isEmpty()){
            caseRecord = new RecordWrapper(acc.Cases[0]);
            recentRecords.add(caseRecord);
            openCaseCount = acc.Cases.size();
        }
        
        for (Opportunity o : acc.Opportunities){
            opportunityRecord = new RecordWrapper(o);
            recentRecords.add(opportunityRecord);
        }
    }
    
    /**
    *  This method gets the Id, Case Number, and Case Record URL of the most recent case updated by the Service Agent on the Account record.
    *  @name getCaseDetails()
    *  @param None
    *  @return caseRec - Id, Case Number, and Case Record URL of the most recent case updated by the Service Agent
    *  @throws exception - throws Exception about possible error captured 
    */
    public Case getCaseDetails() {           
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Case caseRec = new Case(); 
        try {
            caseRec = [SELECT Id, CaseNumber, TECH_CaseRecordURL__c FROM Case WHERE AccountId =: accountRec.Id ORDER BY LastModifiedDate DESC LIMIT 1];
        }catch (Exception e){
            System.debug('The following exception has occurred: ' + e.getMessage());
            logs.add(ApplicationConstant.getExceptionLog(e, 'getCaseDetails', CLASS_NAME, null));
        }finally {
            if(!logs.isEmpty()){ Database.insert(logs, false);}
            
            caseRec = null;
        }

        return caseRec;             
    }    
    
    /**
    *  This method gets the total number of Open Case on the Account record.
    *  @name getNumberOfOpenCases()
    *  @param None
    *  @return countOpenCase - total number of Open Case on the Account record
    *  @throws exception - throws Exception about possible error captured 
    */
    public Integer getNumberOfOpenCases() {           
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Integer countOpenCase = 0;
        
        try {
            countOpenCase = [SELECT Id FROM Case WHERE AccountId =: accountRec.Id AND Status <> 'Closed'].size();
        }catch (Exception e){
            System.debug('The following exception has occurred: ' + e.getMessage()); 
            logs.add(ApplicationConstant.getExceptionLog(e, 'getNumberOfOpenCases', CLASS_NAME, null));
        }finally {
            if(!logs.isEmpty()){ Database.insert(logs, false);}
        }

        return countOpenCase;             
    }
    
    /*************************************************************************************** 
    Developer -    Merari Cebrian (Accenture)
    Date -         13/05/2016
    Function -     Build Alert Messages for sales
    #############Change Log#############
    Modified by     Version     Change Date 
    ****************************************************************************************/
    private List<String> getAlertMessagesForSales() {
        List<String> accountAlertMsgs = new List<String>();
        Account currentAccount = new Account();
        
        try 
        {
            currentAccount = [Select PersonEmail, PersonMobilePhone, Phone, PersonHomePhone, PersonOtherPhone, BreakpointsMember__c, 
                                Breakpoints_Invite_Sent__c, NewsletterSignup__c, Newsletter_Interest__c, Newsletter_Interest_Registered__c  
                                FROM Account Where Id =: accountRec.Id LIMIT 1];
        }
        catch (QueryException e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage());  
            return accountAlertMsgs;
        }
        
        if(currentAccount <> null) {
            //2017-07-28 : SM : Commented out for Phase 1
            if (!currentAccount.NewsletterSignup__c && null == currentAccount.Newsletter_Interest__c) accountAlertMsgs.add('Customer does not receive Newsletter');
            if (!currentAccount.NewsletterSignup__c && 'NO'.equalsIgnoreCase(currentAccount.Newsletter_Interest__c) && system.now().addMonths(-3) >= currentAccount.Newsletter_Interest_Registered__c) accountAlertMsgs.add('Check Newsletter sign up interest');
            //if(!currentAccount.Breakpoints_Invite_Sent__c && !currentAccount.BreakpointsMember__c) accountAlertMsgs.add('Invite Customer to Breakpoints');
            //if(currentAccount.Breakpoints_Invite_Sent__c && !currentAccount.BreakpointsMember__c) accountAlertMsgs.add('Customer is not a Breakpoints member');
            if(currentAccount.PersonEmail == null || String.isBlank(String.valueOf(currentAccount.PersonEmail))) accountAlertMsgs.add('Get Customer email address');
            if((currentAccount.PersonMobilePhone == null ||  String.isBlank(String.valueOf(currentAccount.PersonMobilePhone))) 
                && (currentAccount.Phone == null || String.isBlank(String.valueOf(currentAccount.Phone))) 
                && (currentAccount.PersonOtherPhone == null || String.isBlank(String.valueOf(currentAccount.PersonOtherPhone))) 
                && (currentAccount.PersonHomePhone == null ||  String.isBlank(String.valueOf(currentAccount.PersonHomePhone)))) {
                    accountAlertMsgs.add('Get Customer phone number');
                }
            //if(getNumberOfOpenCases()>0) accountAlertMsgs.add('Open Case on Account');
        }
        
        return accountAlertMsgs;
    }

    public PageReference closeModal(){
        showModal = FALSE;
        return null;
    }

    //Private method called when a save to the Account is needed
    private void updateAccount(Account acc){
        try {
            update acc;
        }catch (DmlException dmlEx){
            system.debug('*** -- Error saving Account ' + dmlEx + ' -- ***');
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Error Saving Client record: ' + dmlEx));
            hasErrors = TRUE;
            return;
        }
    }

    //2017-09-11 : SM : Method to return list of Client Profile records for the current Account
    public List<Client_Profile__c> getClientProfiles(){
        profilePopUp = '';
        List<Client_Profile__c> clientProfileList = [select Id, Name, Type__c, Sub_Type__c, Details__c, Account__c from Client_Profile__c where Account__c = :accountRec.Id ORDER BY LastModifiedDate DESC];
        
        if (!clientProfileList.isEmpty()) {
            showClientProfiles = TRUE;
            clientProfileCount = clientProfileList.size();
            integer counter = clientProfileList.size() > 5 ? 5 : clientProfileList.size();
            for (integer i = 0 ; i < counter ; i++){
                Client_Profile__c cp = clientProfileList[i];
                profilePopUp += cp.Type__c + '/' + cp.Sub_Type__c + ': ' + cp.Details__c + '\n';
            }
        }
        return clientProfileList;
    }

    public class recordWrapper {
        public String recordId {get; set;}
        public String recordType {get; set;}
        public String recordName {get; set;}
        public String sfdcRecordName {get; set;}
        public String spriteType {get; set;}
        public String title {get; set;}

        public recordWrapper(SObject inObj){
            this.recordId = inObj.Id;
            //Lead
            if (String.valueOf(inObj.Id).startsWith('00Q')){
                this.recordType = 'LEAD';
                this.spriteType = 'lead';
                this.title = 'Open Lead record';
                //this.recordName = inObj.get('FirstName') + ' ' + inObj.get('LastName') + ' - ' + inObj.get('CreatedDate');
                this.recordName = inObj.get('FirstName') + ' ' + inObj.get('LastName');
                this.sfdcRecordName = String.valueOf(inObj.get('Name'));
            //Booking
            }else if (String.valueOf(inObj.Id).startsWith('a0Y')){
                Booking__c b = (Booking__c)inObj;
                Date travelDate = b.Travel_Date__c;
                this.recordType = 'BOOKING';
                this.spriteType = 'quotes';
                this.title = 'Open Booking record';
                this.recordName = inObj.get('Name') + ' - ' + travelDate.format();
                this.sfdcRecordName = String.valueOf(inObj.get('Name'));
            //Case
            }else if (String.valueOf(inObj.Id).startsWith('500')){
                this.recordType = 'CASE';
                this.spriteType = 'case';
                this.title = 'Open Case record';
                //this.recordName = inObj.get('CaseNumber') + ':' + inObj.get('Subject') + ' - ' + inObj.get('CreatedDate');
                this.recordName = inObj.get('CaseNumber') + ': ' + inObj.get('Subject');
                this.sfdcRecordName = String.valueOf(inObj.get('CaseNumber'));
            //Opportunity
            }else if (String.valueOf(inObj.Id).startsWith('006')){
                this.recordType = 'OPPORTUNITY';
                this.spriteType = 'opportunity';
                this.title = 'Open Opportunity record';
                //this.recordName = inObj.get('Name') + ' - ' + inObj.get('StageName');
                this.recordName = (String)inObj.get('Name');
                this.sfdcRecordName = String.valueOf(inObj.get('Name'));
            }
        }

    }
    
}