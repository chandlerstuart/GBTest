/*
Name:  ApplicationConstant.cls
======================================================
======================================================
Purpose:
-------
A general constant class

======================================================
======================================================
History
------- 
Ver. Author                  Date        Detail
1.0  Abrar Haq (Accenture)   2016-03-03  Initial development.
2.0  Merari Cebrian          20/04/2016  Added ACC_HIGHLIGHTS_MAX_ALERTS, LEAD_STATUS_CLOSED_CONVERTED
2.1  Simon Molloy            2017-01-18  Added in Custom Setting code to control amount of Error Logs created
2.2  Simon Molloy            2017-09-06  New method to return Org Wide Email Address by Name
2.3  Simon Molloy            2017-10-18  New methods added for error logging when DELETING records
2.4  James Radcliffe         2019-02-12  New Constants for Platform Event Logging
2.5  James Radcliffe         2019-02-26  Adding new Opportunity Record Type references and replacing the old means of obtaining a record type id (from dev name) with the new lightweight approach (as of Summer 18)
2.6  James Radcliffe         2019-04-29  New paramter to access Req Queue Record Type Id
2.7  James Radcliffe         2019-05-08  New Territory__c Constants
2.8  James Radcliffe         2019-07-05  Replace Old Opp Stages with New (remove the numbering)
2.9  James Radcliffe         2019-10-23  Data Event Type Constants
2.10 Chandler Stuart         2023-02-20  OutboundCallout__c & GBWire__RoutingLogEntry__c constants
2.11 Chandler Stuart         2023-11-20  Added new property to support 'Individual' Object API Name
2.12 Chandler Stuart         2024-01-31  Added new properties to support 'New' status on the Opportunity object & Added Compatibility for Preferred Agent Constants
*/
public with sharing class ApplicationConstant {
    public static RecordType recordTypeRecord;
    
    // OPPOrtunity API RecordTypes
    public static final String OPPORTUNITY_RECORD_CLOSEDSALES = 'ClosedSalesOpportunity';
    public static final String OPPORTUNITY_RECORD_COOPFUNDING = 'Co_op_Funding';
    public static final String OPPORTUNITY_RECORD_SALES = 'Sales_Opportunity';
    public static final String OPPORTUNITY_RECORD_NEWSALES = 'NewSalesOpportunity';
    //2.5
    public static final String OPPORTUNITY_CONTACTED = 'Contacted_Opportunity';
    public static final String OPPORTUNITY_UNCONTACTED = 'Uncontacted_Opportunity';

    // Object API Names
    public static final String OBJECT_TYPE_REQUEST_QUEUE = 'Request_Queue__c';
    public static final String OBJECT_TYPE_ACCOUNT = 'Account';
    public static final String OBJECT_TYPE_OPPORTUNITY = 'Opportunity';
    public static final String OBJECT_TYPE_BOOKING = 'Booking__c';
    public static final String OBJECT_TYPE_LEAD = 'Lead';
    public static final String OBJECT_TYPE_BOOKING_GUEST = 'BookingGuest__c';
    public static final String OBJECT_TYPE_TASK = 'Task';
    public static final String OBJECT_TYPE_BOOKING_PAYMENT = 'Booking_Payment__c';
    public static final string OBJECT_TYPE_INDIVIDUAL = 'Individual';

    // Object Names
    public static final String OBJECT_NAME_BOOKING = 'Booking';

    // Request Queue objects
    public static final String REQUEST_QUEUE_STATUS_WAITING = 'Waiting';
    public static final String REQUEST_QUEUE_STATUS_RETRYING = 'Retrying';
    public static final String REQUEST_QUEUE_STATUS_FAILED = 'Failed';
    public static final String REQUEST_QUEUE_STATUS_SUCCESS = 'Success';

    // Record Type API Names
    public static final String RECORD_TYPE_REQUEST_QUEUE_LOG = 'Log';
    public static final String RECORD_TYPE_REQUEST_QUEUE_REQUEST = 'Request';
    public static final String RECORD_TYPE_ACCOUNT_CLIENT = 'Client';
    public static final String RECORD_TYPE_ACCOUNT_PGA_PRO = 'PGA_Pro';
    public static final String RECORD_TYPE_ACCOUNT_VENUE = 'Venue';
    public static final String RECORD_TYPE_CASE_IT_SUPPORT = 'IT_Support';
    public static final String RECORD_TYPE_CASE_SALESFORCE = 'Salesforce';

    //Custom Permissions
    public static final String CUSTOM_PERMISSION_DELETE_BOND_HOLDER = 'Delete_Bond_Holders';

    // Account Record Type Ids
    public static final Id ACC_RECTYPEID_CLIENT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(RECORD_TYPE_ACCOUNT_CLIENT).getRecordTypeId();
    public static final Id ACC_RECTYPEID_PGA_PRO = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(RECORD_TYPE_ACCOUNT_PGA_PRO).getRecordTypeId();
    public static final Id ACC_RECTYPEID_VENUE = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(RECORD_TYPE_ACCOUNT_VENUE).getRecordTypeId();

    // Record Type Ids
    public static final Id REQ_QUEUE_RTID_REQUEST = Schema.SObjectType.Request_Queue__c.getRecordTypeInfosByDeveloperName().get(RECORD_TYPE_REQUEST_QUEUE_REQUEST).getRecordTypeId(); //<-- Added 2.6

    // Custom Settings
    // Get Request Queue Status values to process records
    public static final Map<String, Request_Queue_Status_Setting__c> CUSTOM_SETTING_REQUEST_QUEUE_STATUS_SETTING = Request_Queue_Status_Setting__c.getAll();
    // Get Request Queue Priority based on Object Type
    public static final Map<String, Request_Queue_Priority_Setting__c> CUSTOM_SETTING_REQUEST_QUEUE_PRIORITY_SETTING = Request_Queue_Priority_Setting__c.getAll();
    // Get Object Field Mapping
    public static final Map<String, Object_Field_Mapping__c> CUSTOM_SETTING_OBJECT_FIELD_MAPPING_SETTING = Object_Field_Mapping__c.getAll();

    // Number of Request Queue records to process at a time
    // Note (Important) : This number should not be greater than 10 because we are using "SingleEmailMessage"
    // which has a limitation that you cannot call this method more than 10 times in a single transaction.
    public static final Integer NUMBER_OF_RECORDS_REQUEST_QUEUE_TO_PROCESS = 10;
    // Number of Retry for Request Queue object records
    public static final Integer MAX_NUMBER_OF_RETRY_REQUEST_QUEUE = 5;

    // Exceptions
    public static final String GENERAL_EXCEPTION_GET_FIELDS = 'Fields Causing Error: ';
    public static final String GENERAL_EXCEPTION_GET_STATUS_CODE = 'Error Status Code: ';
    public static final String GENERAL_EXCEPTION_GET_ERROR_MESSAGE = 'Error Message: ';

    // Named Credentials
    // for Request Queue
    public static final String NAMED_CREDENTIAL_REQUEST_QUEUE = 'callout:ClubhouseCredentials/api/Client';
    public static final String CHANGED_ACCOUNT_MANAGER_REQUEST_QUEUE = 'callout:ClubhouseCredentials/api/AccountManager';

    // Apex Batch Job class Name of "Request Queue" object
    public static final String APEX_CLASS_REQUEST_QUEUE_BATCH = 'RequestQueueBatch';
    // Status values of AsyncApexJob
    public static final Set<String> SET_ASYNC_APEX_JOB_STATUS = new Set<String> {'Queued', 'Processing', 'Preparing', 'Holding'};

    // Send Email via Apex
    public static final String SEND_EMAIL_SUBJECT_REQUEST_QUEUE_BATCH = Label.SendEmail_Subject_RequestQueueBatch;

    /***************************************************************************************
    Developer -    Abrar Haq (Accenture)
    Date -         31/03/2016
    Version -      1.0
    Function -     Get the record type by developer name and object type
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Id getRecordTypeId(String objectAPIName, String recordTypeDeveloperName) {
        recordTypeRecord = [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = :objectAPIName AND DeveloperName = :recordTypeDeveloperName];
        return recordTypeRecord.Id;
    }

    /***************************************************************************************
    Developer -    Abrar Haq (Accenture)
    Date -         01/04/2016
    Version -      1.0
    Function -     Get the custom setting values for Request Queue Object and Priority
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Map<String, Integer> getRequestQueueObjectPriority() {
        Map<String, Integer> mapObjectTypeAndPriority = new Map<String, Integer>();
        for (Request_Queue_Priority_Setting__c requestQueuePriorityRecord : CUSTOM_SETTING_REQUEST_QUEUE_PRIORITY_SETTING.values()) {
            mapObjectTypeAndPriority.put( requestQueuePriorityRecord.ObjectType__c, Integer.ValueOf(requestQueuePriorityRecord.Priority__c) );
        }
        return mapObjectTypeAndPriority;
    }

    /***************************************************************************************
    Developer -    Abrar Haq (Accenture)
    Date -         01/04/2016
    Version -      1.0
    Function -     Get the custom setting values for Fields specific to Object Type
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Set<String> getObjectFields(String objectType) {
        Set<String> setObjectFields = new Set<String>();
        // Process custom setting records
        for (Object_Field_Mapping__c objectFieldMapping : ApplicationConstant.CUSTOM_SETTING_OBJECT_FIELD_MAPPING_SETTING.values()) {
            if ( objectFieldMapping.Object_API_Name__c == objectType ) {
                setObjectFields.add(objectFieldMapping.Field_API_Name__c);
            }
        }
        return setObjectFields;
    }

    /***************************************************************************************
    Developer -    Simon Molloy
    Date -         06/09/2017
    Version -      1.0
    Function -     Returns input phone number into E.164 format
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String formatPhone(String inPhone){
        String regEx = '\\+?\\d{10,14}';

        Pattern pat = Pattern.compile(regEx);
        String editPhone = inPhone.trim();
        
        editPhone = editPhone.replace(' ','');
        editPhone = editPhone.replace('-','');
        editPhone = editPhone.replace('(','');
        editPhone = editPhone.replace(')','');

        if ('0' == editPhone.substring(0,1)){
            editPhone = '+44' + editPhone.substring(1);
        }else if ('44' == editPhone.substring(0,2)){
            editPhone = '+44' + editPhone.substring(3);
        }else {
            editPhone = '+' + editPhone;
        }

        Matcher match2 = pat.matcher(editPhone);
        if (match2.matches()){
            return editPhone;
        }else {
            return inPhone;
        }
    }

    /***************************************************************************************
    Developer -    Abram Vixen Reyes
    Date -         04/03/2016
    Version -      1.0
    Function -     Constant for TriggerHandler Classes
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/

    //CaseTriggerHandler Constants
    public static final String CASE_SOBJECTTYPE = 'Case';
    public static final String ENT_ACTIVE_STATUS = 'Active';
    public static final String CASE_DEBUG_MSG = 'The following exception has occurred: ';

    //LeadTriggerHandler Constants
    public static final String LEAD_DEBUG_MSG = 'The following exception has occurred: ';
    public static final String LEAD_RATING_HOT = 'Hot';
    public static final String LEAD_RATING_WARM = 'Warm';
    public static final String LEAD_RATING_COLD = 'Cold';
    public static final String LEAD_STATUS_DUPLICATE = 'Duplicate/Not a lead';
    public static final String LEAD_RATING_CONVERTED = 'Converted';
    public static final String LEAD_CLOSED_CONVERTED = 'Closed- Converted';
    public static final String LEAD_NO_SALE = 'No Sale';
    public static final String LEAD_SALES_AGENT = 'Sales Agent';
    public static final String LEAD_SPC_SALESTEAM = 'S- Specialist Sales Team';
    public static final String LEAD_SPC_SALESTEAM_DEVNAME = 'SSpecialistSalesTeam';

    //OpportunityTriggerHandler Constants
    public static final String OPP_DEBUG_MSG = 'The following exception has occurred: ';
    public static final String STAGENAME = 'Customer Paid: Full Deposit'; //2.8~ (Previous: '6a. Customer Paid: Full Deposit')
    public static final String OPP_TYPE_OPEN = 'Open';

    //UserServicePresenceTriggerHandler Constants
    public static final String USP_SERVICE_AGENT = 'Service Agent';
    public static final String USP_QUEUE_PRESENCE = 'Queue Presence';
    public static final String USP_SALES_AGENT = 'Sales Agent';
    public static final String USP_SALES_MANAGER = 'Sales Manager';
    public static final String USP_QUEUE = 'Queue';
    public static final String USP_OBJECT = 'Sales_Agent_Attributes__c';
    public static final String USP_QUEUE_PRESENCE_DEVNAME = 'SAA_QueuePresence';
    public static final String USP_SALES_AGENT_DEVNAME = 'Sales_Agent';
    public static final String USP_SALES_MANAGER_DEVNAME = 'Sales_Manager';
    
    //QuoteTriggerHandler Constants
    public static final String RECOMMENDATIONSTAGE = 'Qualification'; //2.8~ (Previous: 'Recommendations')
    //public static final String PRODUCEQUOTESTAGE = '2. Quote Sent';
    //public static final String QUOTESENTSTAGE = '3. Close Sale';
    public static final String QUOTESENTSTAGE = 'Quote Sent'; //2.8~ (Previous: '2. Quote Sent')
    public static final String CLOSESALESTAGE = 'Close Sale'; //2.8~ (Previous: '3. Close Sale')
    public static final String CUSTOMERACCEPTEDSTAGE = 'Customer Accepted'; //2.8~ (Previous: '4. Customer Accepted')
    public static final String QUOTEBOOKINGSTATUS = 'Booking';
    public static final String QUOTECANCELLATION = 'Cancellation';
    public static final String QUOTEUNKNOWN = 'Unknown';
    public static final String QUOTEOPTION = 'Quote option';
    public static final String QUOTEACCEPTEDSTATUS = 'Accepted';

    //Calendar Constants
    public static final String CALENDAR_CAMPAIGN = 'Campaign';
    public static final String CALENDAR_TYPE_NONE = '-None-';
    public static final String CALENDAR_CAMPAIGNEVENT = 'Marketing Campaign/Event';
    public static final String CALENDAR_CAMPAIGNPROGRAM = 'Marketing Program';
    public static final String CALENDAR_EVENT_CAMPAIGN = 'event-campaign';
    public static final String CALENDAR_TITLE = 'title';
    public static final String CALENDAR_START = 'start';
    public static final String CALENDAR_END = 'end';
    public static final String CALENDAR_URL = 'url';
    public static final String CALENDAR_ALLDAY = 'allDay';
    public static final String CALENDAR_COLOR = 'color';
    public static final String CALENDAR_LIGHTGREENFORR1 = '#A9D18E'; //campaign/event
    public static final String CALENDAR_LIGHTBLUEFORR1 = '#B4C7E7'; //program
    public static final String CALENDAR_LIGHTGREENFORSIT = '#E2F0D9'; //expected to be light green for program
    public static final String CALENDAR_LIGHTYELLOWFORSIT = '#FFE699'; //expected to be light yellow for campaign/event
    public static final String CALENDAR_BLUE = 'blue';
    // public static final String CALENDAR_DTFORMAT = 'EEE, d MMM yyyy HH:mm:ss z';
    public static final String CALENDAR_DTFORMAT = 'yyyy-MM-dd HH:mm:ss.SSSZ';
    //ExpectedPaymentTriggerHandler Constants
    public static final String EPAYMENTTYPEPARTIALDEPOSIT = 'Partial Deposit';
    public static final String EPAYMENTTYPEFULLDEPOSIT = 'Full Deposit';
    public static final String EPAYMENTTYPEFULLBALANCE = 'Full Balance';
    public static final String PAIDPARTIALDEPOSITSTAGE = 'Customer Paid: Partial Deposit'; //2.8~ (Previous: '5. Customer Paid: Partial Deposit')
    public static final String PAIDFULLDEPOSITSTAGE = 'Customer Paid: Full Deposit'; //2.8~ (Previous: '6a. Customer Paid: Full Deposit')
    public static final String PAIDFULLBALANCESTAGE = 'Customer Paid: Full Balance'; //2.8~ (Previous: '6b. Customer Paid: Full Balance')
    
    //NVM CallBack Constants
    public static final String NVMCALLBACK_ASAP = 'ASAP';

    /***************************************************************************************
    Developer -    Renz Melecotones (Accenture)
    Date -         05/04/2016
    Version -      1.0
    Function -     Constant for Case
    #############Change Log#############
    Modified by     Version     Change Date
    Renz Melecotones  2.0           4/13
    Renz Melecotones  3.0           5/16
    ****************************************************************************************/

    //Case Constants
    public static final String CASE_STATUS_CLOSED = 'Closed';
    public static final String CASE_STATUS_NEW = 'New';
    public static final String CASE_STATUS_ONHOLD_WFC = 'On Hold - Waiting for Customer';
    public static final String CASE_STATUS_ONHOLD_WFS = 'On Hold - Waiting for Supplier';
    public static final String CASE_STATUS_CSC = 'Check Supplier Confirmation';
    public static final String CASE_STATUS_INPROGRESS = 'In Progress';
    public static final String CASE_TYPE_AMENDMENT = 'Amendment';
    public static final String CASE_CLOSED_SUBSTATUS_ACCEPTED = 'Accepted';
    public static final String OPP_STAGE_CP_FULLBALANCE = 'Customer Paid: Full Balance'; //2.8~ (Previous: '6b. Customer Paid: Full Balance')
    public static final String OPP_STATUS_CANCELLED = 'Cancelled';
    public static final String BOOKING_STATUS_CANCELLED = 'Cancelled';
    public static final String COMPLAINT_CATEGORY_ONSITE = 'C- On Site';
    public static final String COMPLAINT_SUBCATEGORY_ONSITE = 'Expectations';
    public static final String CASE_ORIGIN  = 'Email';
    public static final String CASE_COMPSOURCE_CLIENT = 'Client';
    public static final String CASE_COMPLIABILITY_SUPPLIER = 'Supplier';
    public static final String CASE_FEEDBACK = 'Feedback';
    public static final String CASE_CATEG_FONSITE = 'F- On Site';
    public static final String CASE_SUBCATEG_POS = 'Positive';
    
    //Entitlement Start and End Date
    public static final Date ENTITLEMENT_STARTDATE = Date.newInstance(2016, 3, 15);
    public static final Date ENTITLEMENT_ENDDATE = Date.newInstance(2020, 3, 15);

    /***************************************************************************************
    Developer -    Erika Hidalgo (Accenture Cloud First)
    Date -         07/04/2016
    Version -      1.0
    Function -     Constant for TaskTriggerBL Class
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static final String LEAD_STATUS_NEW = 'New';
    public static final String LEAD_STATUS_QUALIFIED = 'Qualified';
    public static final String LEAD_STATUS_CONTACT_ATTEMPTED = 'Contact Attempted';
    public static final String LEADE_STATUS_CONTACTED_INPROGRESS = 'Contacted-In Progress';
    public static final String LEAD_SOURCE_EVENT = 'Event';
    public static final String TASK_CALL = 'Call';
    public static final String TASK_EMAIL = 'Email';
    public static final String TASK_STAT_INPROGRESS = 'In Progress';
    public static final String CALLRESULT_NO_ANSWER = 'No Answer/Engaged';
    public static final String CALLRESULT_CALL_REFUSED =  'Client Refused Call (Not interested)';
    public static final String CALLRESULT_LM_VOICEMAIL_1N2 = 'LM Voicemail (1st time/2nd time)';
    public static final String CALLRESULT_LM_VOICEMAIL_3 = 'LM Voicemail (3rd time)';
    public static final String CALLRESULT_RESCHED = 'Rescheduled Call';
    public static final String CALLRESULT_CONVERSATION_COMPLETED = 'Conversation Completed';
    public static final String LEAD_STATUS_CLOSED_CONVERTED = 'Closed- Converted';

    //AP22_ExpectedPaymentBatch
    public static final String GETINITIALDEPOSIT = 'Get Initial Deposit';
    public static final String GETDEPOSITBALANCE = 'Get Deposit Balance';
    public static final String GETFINALBALANCE = 'Get Final Balance';
    public static final String TASKSUBJ_GETTRANSFER = 'Get Transfer Details from Client';
    public static final String TASKSUBJ_GETROOMING = 'Get Rooming List from Client';
    public static final String TASKSUBJ_CHECKCH = 'Check Clubhouse - ';
    public static final String ADMINCASESUBJ = 'Admin Case';
    public static final String TASKSTATUS_NOTSTARTED = 'Not Started';
    public static final String TASKSTATUS_COMPLETED = 'Completed';
    public static final String TASKPRIORITY_NORMAL = 'Normal';
    public static final String CASEORIGIN_CLUBHOUSE = 'Clubhouse';
    public static final String CASETYPE_ADMIN = 'Admin';
    public static final String CASESTATUS_NEW = 'New';
    public static final String CASETASKTYPE_PAYMENT = 'Payment';
    public static final String CASETASKTYPE_CUSTOMER = 'Customer';
    public static final String CASETASKTYPE_SUPPLIER = 'Supplier';
    public static final String ADMINTASKSUBJ_CHECKCH = 'Check Clubhouse%';
    public static final Id CASERECTYPEID_ADMIN = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Admin').getRecordTypeId();
    public static final Set<String> ADMINTASKSET = new Set<String> {'Get Initial Deposit', 'Get Deposit Balance', 'Get Final Balance', 'Get Transfer Details from Client', 'Get Rooming List from Client'};
    //public static final Set<String> SALESOPPSTAGESET = new Set<String> {'1. Recommendations', '2. Quote Sent', '3. Close Sale', '4. Customer Accepted', '5. Customer Paid: Partial Deposit'}; //2.8-
    public static final Set<String> SALESOPPSTAGESET = new Set<String> {'Qualification', 'Quote Sent', 'Close Sale', 'Customer Accepted', 'Customer Paid: Partial Deposit'}; //2.8+
    public static final Set<String> EPTYPESET = new Set<String> {'Partial Deposit', 'Full Deposit', 'Full Balance'};


    /***************************************************************************************
    Developer -    Bryanne Perez (Accenture)
    Date -         08/04/2016
    Version -      1.0
    Function -     Constant for WS01_RebarHTTPCallout
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static final String LEAD_SOBJECTTYPE = 'Lead';
    public static Lead getLead(String leadID) {

        Lead lead = [SELECT Id FROM Lead WHERE Id = : leadID LIMIT 1];

        return lead;
    }

    // public static CampaignMember getCampaignId(String leadId) {

    //     List<CampaignMember> campaignRecords = [SELECT
    //                                       Id FROM CampaignMember
    //                                       WHERE LeadId = :leadId LIMIT 1];

    //     return campaignRecords[0];
    // }

    /***************************************************************************************
    Developer -    Erika Hidalgo (Accenture Cloud First)
    Date -         14/04/2016
    Version -      1.0
    Function -     Constant for SalesAgentDesktopController
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    //Today
    public static final String LEADS_TODAY = 'My New Leads Today';
    public static final String LEADS_CALLBACK_TODAY = 'My Call Back(Leads) Today';
    public static final String OPP_TODAY = 'My New Opportunities Today';
    public static final String OPP_CALLBACKS_TODAY = 'My Call Backs(Opportunities) Today';
    public static final String CASES_NEWBOOK_TODAY = 'My New Cases(Books) Today';
    public static final String CASES_CALLBACKS_TODAY = 'My Call Backs(Cases) Today';

    public static final String OPPORTUNITIES_RECOMMENDATION_TODAY = 'My Opportunities — Recommendation Today';
    public static final String OPPORTUNITIES_QUOTE_SENT_TODAY = 'My Opportunities — Quote Sent Today';
    public static final String OPPORTUNITIES_CLOSED_TODAY = 'My Opportunities — Closed Today';

    //ThisWeeks
    public static final String LEADS_THISWEEK = 'My Open Leads This Week';
    public static final String LEADS_CALLBACK_THISWEEK = 'My Call Backs (Leads) This Week';
    public static final String OPP_THISWEEK = 'My Opportunities This Week';
    public static final String OPP_CALLBACKS_THISWEEK = 'My Call Backs(Opportunities) This Week';
    public static final String CASES_NEWBOOK_THISWEEK = 'My Open Cases(Bookings) This Week';
    public static final String CASES_CALLBACKS_THISWEEK = 'My Call Backs(Cases) This Week';

    public static final String OPPORTUNITIES_RECOMMENDATION_THISWEEK = 'My Opportunities — Recommendation This Week';
    public static final String OPPORTUNITIES_QUOTE_SENT_THISWEEK = 'My Opportunities — Quote Sent This Week';
    public static final String OPPORTUNITIES_CLOSED_THISWEEK = 'My Opportunities — Closed This Week';

    //TOTAL
    public static final String LEADS_TOTAL = 'My Open Leads Total';
    public static final String LEADS_CALLBACK_TOTAL = 'My Call Backs(Leads) Total';
    public static final String OPP_TOTAL = 'My Open Opportunities Total';
    public static final String OPP_CALLBACKS_TOTAL = 'My Call Backs(Opportunities) Total';
    public static final String CASES_NEWBOOK_TOTAL = 'My Open Cases(Bookings) Total';
    public static final String CASES_CALLBACKS_TOTAL = 'My Call Backs(Cases) Total';
    public static final String OPPORTUNITIES_CLOSED_TOTAL = 'My Opportunities — Closed Total';
    public static final String OPPORTUNITIES_QUOTE_SENT_TOTAL = 'My Opportunities — Quote Sent Total';
    public static final String OPPORTUNITIES_RECOMMENDATION_TOTAL = 'My Opportunities — Recommendation Total';

    //OPPORTUNITY LEAD SOURCE
    public static final String OPPORTUNITY_LEAD_SOURCE_BOOKING_REQUEST = 'Booking Request';
    
    //CaseRecordTypes
    public static final String SERVICE_CASE = 'Service Case';
    public static final String AMENDMENT = 'Amendment';
    public static final String COMPLAINT = 'Complaint';
    public static final String ADMIN = 'Admin';

    //String Replace query on Task
    public static final String TASK_OWNERID = 'TASK_OWNERID';

    /***************************************************************************************
    Developer -    Renz Melecotones (Accenture Cloud First)
    Date -         14/04/2016
    Version -      2.0
    Function -     Constant for updateOpportunityServiceAgentAssigned() & updateCaseMileStone() & updateAmendmentCaseStatusToClosed()
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    //Sales Region Group
    public static final String SALESREGIONGROUP_UK_IRELAND = 'UK & Ireland';
    public static final String SALESREGIONGROUP_EUROPE = 'Europe';
    public static final String SALESREGIONGROUP_MIDHAUL = 'ROW - Mid Haul';
    public static final String SALESREGIONGROUP_LONGHAUL = 'ROW - Long Haul';
    public static final String SALESREGIONGROUP_USA = 'USA';
    public static final String SALESREGIONGROUP_FDP = 'ROW - FDP';
    
    public static final String COUNTRY_ENGLAND_WALES = 'England & Wales';
    //Queues
    public static final String QUEUE_CS_UK = 'CS-UK';
    public static final String QUEUE_CS_EU = 'CS-EU';
    public static final String QUEUE_CS_URGENT = 'CS-Urgent';
    public static final String QUEUE_CS_MIDHAUL = 'CS-ROW-MidHaul';
    public static final String QUEUE_CS_LONGHAUL = 'CS-ROW-Long Haul';

    //Case Record Type Ids
    public static final Id CASERECTYPEID_AMENDMENT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Amendment').getRecordTypeId();
    public static final Id CASERECTYPEID_COMPLAINT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
    public static final Id CASERECTYPEID_SERVICECASE = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Case').getRecordTypeId();

    //Milestones
    public static final String MILESTONE_RESPONSE_TIME = 'Response Time';
    public static final String MILESTONE_RESOLUTION_TIME = 'Resolution Time';
    public static final String MILESTONE_ABTA_RESOLUTION = 'ABTA Resolution';
    public static final String MILESTONE_FIRST_RESPONSE = 'First Response';
    public static final String MILESTONE_INITIAL_RESPONSE_ABTA = 'Initial Response - ABTA';

    //Case
    public static final String CASE_ACCOUNTABLE_FOR_ISSUE_NONE = 'None';
    public static final String CASE_CUSTOMER_SATISFACTION_NA = 'Not Applicable';

    //Opportunity Record Type Id
    //public static final Id OPP_RECTYPEID_NSO = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('New Sales Opportunity').getRecordTypeId(); //<-- comment out 2.5
    //public static final Id OPP_RECTYPEID_CSO = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Closed Sales Opportunity').getRecordTypeId(); //<-- comment out 2.5
    public static final Id OPP_RECTYPEID_NSO = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(OPPORTUNITY_RECORD_NEWSALES).getRecordTypeId(); //<-- Added 2.5
    public static final Id OPP_RECTYPEID_CSO = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(OPPORTUNITY_RECORD_CLOSEDSALES).getRecordTypeId(); //<-- Added 2.5
    public static final Id OPP_RECTYPEID_UNCONTACTED = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(OPPORTUNITY_UNCONTACTED).getRecordTypeId(); //<-- Added 2.5
    public static final Id OPP_RECTYPEID_CONTACTED = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(OPPORTUNITY_CONTACTED).getRecordTypeId(); //<-- Added 2.5

    //Opportunity Stage
    public static final String OPP_STAGE_TRIPCOMPLETED = 'Trip Completed'; //2.8~ (Previous: '6c. Trip Completed')
    public static final String OPP_STAGE_DUPLICATE = 'Duplicate';
    public static final String OPP_STAGE_NOSALE = 'No Sale';
    public static final String OPP_STAGE_CANCELLED = 'Cancelled';
    public static final String OPP_STAGE_NEW = 'New';

    //Account Highlights Panel Alert
    public static final Integer ACC_HIGHLIGHTS_MAX_ALERTS = 3;

    public static final String GBP_CURRENCY = 'GBP';
    public static final String USD_CURRENCY = 'USD';
    
    /***************************************************************************************
    Developer -    Recuerdo Bregente
    Date -         23/04/2016
    Version -      1.0
    Function -     Constants for lead routing
    #############Change Log#############
    Modified by     Version     Change Date
    Simon M         1.1         31/01/2017 -- Added in 'Specialist' Queue variable, and included in TEAM_SET variable
    ****************************************************************************************/

    //Values used to qualify leads for lead routing
    public static final Set<String> LEAD_ROUTING_RATING = new Set<String> {'Warm', 'Hot'};
    public static final Set<String> UNQUALIFIED_SOURCE = new Set<String> {'Auto generate- returning traveller'};
    public static final String UNKNOWN_SALES_TEAM = 'S- Unknown Leads Sales Team';
    public static final String EUROPE_8_TEAM = 'S- EU 8+ Sales Team';
    public static final String EUROPE_0_7_TEAM = 'S- EU 0-7 Sales Team';
    public static final String UK_AND_IRELAND_9_TEAM = 'S- UK 9+ Sales Team';
    public static final String UK_AND_IRELAND_0_8_TEAM = 'S- UK 0-8 Sales Team';
    public static final String ROW_MID_HAUL_TEAM = 'S- ROW-Mid Haul Sales Team';
    public static final String ROW_LONG_HAUL_TEAM = 'S- ROW-Long Haul Sales Team';
    public static final String US_TEAM = 'S- USA Sales Team';
    public static final String COLD_TEAM = 'S- Cold Leads';
    public static final String RETURNING_TRAVELLER_TEAM = 'S- Returning Traveller';
    public static final String SPECIALIST_TEAM = 'S- Specialist Sales Team';
    public static final Set<String> TEAM_SET = new Set<String> {ApplicationConstant.EUROPE_8_TEAM, ApplicationConstant.EUROPE_0_7_TEAM, ApplicationConstant.UK_AND_IRELAND_9_TEAM, ApplicationConstant.UK_AND_IRELAND_0_8_TEAM, ApplicationConstant.ROW_MID_HAUL_TEAM, ApplicationConstant.ROW_LONG_HAUL_TEAM, ApplicationConstant.SPECIALIST_TEAM};
    public static final String NOT_SPECIALIST = 'Not Specialist';
    public static final String IS_SPECIALIST = 'Specialist';
    public static final String RETURNING_TRAVELLER = 'Auto generate- returning traveller';
    public static final String SCORING_EQUALS = 'equals';
    public static final String SCORING_CONTAINS = 'contains';
    public static final String SCORING_STARTSWITH = 'starts with';
    public static final String CASE_ORIGIN_WEB = 'Web';
    public static final String LEAD_SOURCE_PHONE = 'Phone';
    public static final String LEAD_SOURCE_WEBSITEFORM = 'Website form';
    public static final String LEAD_DUPLICATE_REASON = 'Same date and/or venue (< 3 months old)';

    //Values for User Roles
    public static final String  COMMERCIAL_DIRECTOR = 'Commercial_Director';
    public static final String  CS_EU_AGENT = 'CS_EU_Agent';
    public static final String  CS_ROW_AGENT = 'CS_ROW_Agent';
    public static final String  CS_UK_AGENT = 'CS_UK_Agent';
    public static final String  CUSTOMEREXPERIENCEMANAGER = 'CustomerExperienceManager';
    public static final String  CUSTOMERSERVICEMANAGER = 'CustomerServiceManager';
    public static final String  DATA = 'Data';
    public static final String  DIRECTOR = 'Director';
    public static final String  EUGROUPS8SALESAGENT = 'EUGroups8SalesAgent';
    public static final String  EUPRODUCTMANAGER = 'EUProductManager';
    public static final String  EUSALESMANAGER = 'EUSalesManager';
    public static final String  EUTRANSIENTSALESAGENT = 'EUTransientSalesAgent';
    public static final String  EU_SALES_TEAM_LEADER = 'EU_Sales_Team_Leader';
    public static final String  FINANCE = 'Finance';
    public static final String  FINANCE_MANAGER = 'Finance_Manager';
    public static final String  HEADOFCUSTOMERSERVICE = 'HeadOfCustomerService';
    public static final String  HEADOFIT = 'HeadofIT';
    public static final String  HEADOFNEWBUSINESSDEVELOPMENT = 'HeadOfNewBusinessDevelopment';
    public static final String  HEADOFUKSALES = 'HeadOfUKSales';
    public static final String  HEAD_OF_CONTACT_CENTRE = 'Head_of_Contact_Centre';
    public static final String  HEAD_OF_FINANCE = 'Head_of_Finance';
    public static final String  HEAD_OF_HR = 'Head_of_HR';
    public static final String  HEAD_OF_MARKETING = 'Head_of_Marketing';
    public static final String  HEAD_OF_PRODUCT_AND_PRICING = 'Head_of_Product_and_Pricing';
    public static final String  HEAD_OF_SCANDI_SALES = 'Head_of_Scandi_Sales';
    public static final String  HEAD_OF_US_SALES = 'Head_of_US_Sales';
    public static final String  HR = 'HR';
    public static final String  HRMANAGER = 'HRManager';
    public static final String  INFRASTRUCTURE_SERVICES = 'Infrastructure_Services';
    public static final String  IT_MANAGER = 'IT_Manager';
    public static final String  MARKETINGEXECUTIVE = 'MarketingExecutive';
    public static final String  MARKETINGMANAGER = 'MarketingManager';
    public static final String  PGA_TOURNAMENT = 'PGA_Tournament';
    public static final String  PRICINGANDINVENTORYASSISTANT = 'PricingAndInventoryAssistant';
    public static final String  PRICINGANDINVENTORYMANAGER = 'PricingAndInventoryManager';
    public static final String  ROWLONGHAULSALESAGENT = 'ROWLongHaulSalesAgent';
    public static final String  ROWMIDHAULSALESAGENT = 'ROWMidHaulSalesAgent';
    public static final String  ROWPRODUCTMANAGER = 'ROWProductManager';
    public static final String  ROW_SALES_TEAM_LEADER = 'ROW_Sales_Team_Leader';
    public static final String  SALESFORCE = 'Salesforce';
    public static final String  SCANDI_SALES_AGENT = 'Scandi_Sales_Agent';
    public static final String  SCANDI_SALES_MANAGER = 'Scandi_Sales_Manager';
    public static final String  SOFTWARE_DEVELOPER = 'Software_Developer';
    public static final String  UKANDIRELANDPRODUCTMANAGER = 'UKAndIrelandProductManager';
    public static final String  UKSALESMANAGER = 'UKSalesManager';
    public static final String  UK_GROUPS_SALES_AGENT = 'UK_Groups_Sales_Agent';
    public static final String  UK_SALES_TEAM_LEADER = 'UK_Sales_Team_Leader';
    public static final String  UK_TRANSIENT_SALES_AGENT = 'UK_Transient_Sales_Agent';
    public static final String  USSALESCONSULTANT = 'USSalesConsultant';
    public static final String  US_SALES_MANAGER = 'US_Sales_Manager';
    public static final String  WEB_DEVELOPER = 'Web_Developer';
    

    /***************************************************************************************
    Developer -    Recuerdo Bregente
    Date -         14/05/2016
    Version -      1.0
    Function -     Uitity methods for error handling
    #############Change Log#############
    Modified by     Version     Change Date
    SMolloy         1.1         18/01/2017  Added Custom Setting functionality to alter amount
                                            of logs saved, controlled through the UI
    SMolloy         1.2         30/01/2017  Changed getDMLLog to a private method and turned off
                                            check for 'isBatch' in getSaveResultLog as per Mark C. instructions
    SMolloy         1.3         09/03/2017  Added in extra fields to the Error Log object, to enable better reporting                                            
    ****************************************************************************************/
    public static final String EXCEPTION_LOG = 'Exception';
    public static final String DML_ERROR_LOG = 'DML Error';
    public static final String GENERAL_ERROR_LOG = 'Error';
    public static final String INFO_LOG = 'Information';
    public static final String WARNING_LOG = 'Warning';

    public static Error_Log__c getExceptionLog(Exception e, String methodName, String className, String objectName){
        Error_Log__c log = new Error_Log__c();
        
        Database.DMLOptions dmlOpt = new Database.DMLOptions();
        dmlOpt.AllowFieldTruncation = TRUE;
        log.setOptions(dmlOpt);

        log.Error_Type__c = ApplicationConstant.EXCEPTION_LOG;
        String fullTrace = 'Type: ' + e.getTypeName() + '\n' + 'Cause: ' + e.getCause() + '\n' + 'Message: ' 
                            + e.getMessage() + '\n' + 'Line #: ' + e.getLineNumber() + '\n' + e.getStackTraceString() + '\n'
                            + ' In Method: ' + methodName + ' \nFrom Class: ' + className + ' \nBy: ' + UserInfo.getUserName();
        if(!String.isEmpty(objectName)){
            fullTrace += '\nOn Object: ' + objectName;
        }
        log.trace__c = fullTrace;
        log.Trace_Summary__c = fullTrace;
        
        //Update individual fields with the right information
        log.Class_Name__c = className;
        log.Method_Name__c = methodName;
        log.Error_Message__c = e.getMessage();
        log.Error_Line_Number__c = e.getLineNumber().format().replace(',','');
        
        //ApplicationConstant.deleteOldLogs();                    
        return log;
    }

    //2017-10-18 : SM : New method to return logs generated by Delete operations
    public static List<Error_Log__c> getDeleteResultLog(Database.DeleteResult[] deleteResults, String methodName, 
                                                String className, String objectName, String dmlType){
        boolean doInfo = TRUE;
        boolean doDML = TRUE;
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Error_Log__c log;
        Error_Log_Setting__c elsInfo;
        Error_Log_Setting__c elsDML;
        Map<String, Error_Log_Setting__c> elsList = Error_Log_Setting__c.getAll();
        if (null != elsList && !elsList.isEmpty()){
            elsInfo = elsList.get(ApplicationConstant.INFO_LOG);    
            elsDML = elsList.get(ApplicationConstant.DML_ERROR_LOG);
        }

        if (null != elsInfo && !elsInfo.Enabled__c){
            doInfo = FALSE;
        } 

        if (null != elsDML && !elsDML.Enabled__c){
            doDML = FALSE;
        }
        
        //if(!System.isBatch()){
            for(Database.DeleteResult delResult : deleteResults){
                if(!delResult.isSuccess()){
                    if (doDML){
                        logs.add(ApplicationConstant.getDMLLog(delResult, methodName, className, objectName, dmlType));
                    }
                }
            }
            

            if(logs.isEmpty()){
                if (doInfo){
                    if (null == log) log = new Error_Log__c();
                    log.Error_Type__c = ApplicationConstant.INFO_LOG;
                    log.trace__c = 'SUCCESS! ';
                    log.trace__c += ' \nIn Method: ' + methodName + ' \nFrom Class: ' + className;
                    log.trace__c += ' \nOn Object: ' + objectName + ' \nUpon: ' + dmlType + ' \nBy: ' + UserInfo.getUserName();
                    logs.add(log);
                }
            }
        //}
        //ApplicationConstant.deleteOldLogs();                    
        return logs;
    }
    
    public static List<Error_Log__c> getSaveResultLog(Database.SaveResult[] updateLeadList, String methodName, 
                                                String className, String objectName, String dmlType){
        boolean doInfo = TRUE;
        boolean doDML = TRUE;
        List<Error_Log__c> logs = new List<Error_Log__c>();
        Error_Log__c log;
        Error_Log_Setting__c elsInfo;
        Error_Log_Setting__c elsDML;
        Map<String, Error_Log_Setting__c> elsList = Error_Log_Setting__c.getAll();
        if (null != elsList && !elsList.isEmpty()){
            elsInfo = elsList.get(ApplicationConstant.INFO_LOG);    
            elsDML = elsList.get(ApplicationConstant.DML_ERROR_LOG);
        }

        if (null != elsInfo && !elsInfo.Enabled__c){
            doInfo = FALSE;
        } 

        if (null != elsDML && !elsDML.Enabled__c){
            doDML = FALSE;
        }
        
        //if(!System.isBatch()){
            for(Database.SaveResult saveResult : updateLeadList){
                if(!saveResult.isSuccess()){
                    if (doDML){
                        logs.add(ApplicationConstant.getDMLLog(saveResult, methodName, className, objectName, dmlType));
                    }
                }
            }
            

            if(logs.isEmpty()){
                if (doInfo){
                    if (null == log) log = new Error_Log__c();
                    log.Error_Type__c = ApplicationConstant.INFO_LOG;
                    log.trace__c = 'SUCCESS! ';
                    log.trace__c += ' \nIn Method: ' + methodName + ' \nFrom Class: ' + className;
                    log.trace__c += ' \nOn Object: ' + objectName + ' \nUpon: ' + dmlType + ' \nBy: ' + UserInfo.getUserName();
                    logs.add(log);
                }
            }
        //}
        //ApplicationConstant.deleteOldLogs();                    
        return logs;
    }
    
    //2017-10-18 : SM : Overloaded getDMLLog method to accept DeleteResult as opposed saveResult
    private static Error_Log__c getDMLLog(Database.DeleteResult deleteResult, String methodName,
                                            String className, String objectName, String dmlType){ 
        Error_Log__c log = new Error_Log__c();

        Database.DMLOptions dmlOpt = new Database.DMLOptions();
        dmlOpt.AllowFieldTruncation = TRUE;
        log.setOptions(dmlOpt);

        String fullTrace;
        if(deleteResult.isSuccess()){
            log.Error_Type__c = ApplicationConstant.INFO_LOG;
            log.trace__c = 'SUCCESS: ' + deleteResult.getId();
            log.Trace_Summary__c = 'SUCCESS: ' + deleteResult.getId();
        }
        else{
            //2017-03-09 : SM : As we process multiple Database.Error records, we will only capture the first one
            //2017-03-09 : SM : And report on that in the individual fields
            integer counter = 0;
            log.Error_Type__c = ApplicationConstant.DML_ERROR_LOG;
            fullTrace = 'ERROR: ' + deleteResult.getId();
            for(Database.Error dbError : deleteResult.getErrors()){
                fullTrace += ' \n' + dbError.getMessage();
                fullTrace += ' \n' + dbError.getStatusCode();
                fullTrace += ' \n' + dbError.getFields();
                if (counter == 0){ //First iteration of the loop
                    //Update individual fields with the right information
                    log.Class_Name__c = className;
                    log.Method_Name__c = methodName;
                    log.Error_Message__c = dbError.getMessage();
                }
                counter ++;
            }
        }
            
        fullTrace += ' \nIn Method: ' + methodName + ' \nFrom Class: ' + className;
        fullTrace += ' \nOn Object: ' + objectName + ' \nUpon: ' + dmlType + ' \nBy: ' + UserInfo.getUserName();
        
        log.trace__c = fullTrace;
        log.Trace_Summary__c = fullTrace;

        return log;                                            

    }

    private static Error_Log__c getDMLLog(Database.SaveResult saveResult, String methodName, 
                                                String className, String objectName, String dmlType){
        Error_Log__c log = new Error_Log__c();

        Database.DMLOptions dmlOpt = new Database.DMLOptions();
        dmlOpt.AllowFieldTruncation = TRUE;
        log.setOptions(dmlOpt);

        String fullTrace;
        if(saveResult.isSuccess()){
            log.Error_Type__c = ApplicationConstant.INFO_LOG;
            log.trace__c = 'SUCCESS: ' + saveResult.getId();
            log.Trace_Summary__c = 'SUCCESS: ' + saveResult.getId();
        }
        else{
            //2017-03-09 : SM : As we process multiple Database.Error records, we will only capture the first one
            //2017-03-09 : SM : And report on that in the individual fields
            integer counter = 0;
            log.Error_Type__c = ApplicationConstant.DML_ERROR_LOG;
            fullTrace = 'ERROR: ' + saveResult.getId();
            for(Database.Error dbError : saveResult.getErrors()){
                fullTrace += ' \n' + dbError.getMessage();
                fullTrace += ' \n' + dbError.getStatusCode();
                fullTrace += ' \n' + dbError.getFields();
                if (counter == 0){ //First iteration of the loop
                    //Update individual fields with the right information
                    log.Class_Name__c = className;
                    log.Method_Name__c = methodName;
                    log.Error_Message__c = dbError.getMessage();
                }
                counter ++;
            }
        }
            
        fullTrace += ' \nIn Method: ' + methodName + ' \nFrom Class: ' + className;
        fullTrace += ' \nOn Object: ' + objectName + ' \nUpon: ' + dmlType + ' \nBy: ' + UserInfo.getUserName();
        
        log.trace__c = fullTrace;
        log.Trace_Summary__c = fullTrace;

        return log;
    }
    
    public static void deleteOldLogs(){
        List<Error_Log__c> logsToDelete = [Select Id FROM Error_Log__c Where CreatedDate <= N_DAYS_AGO:2 LIMIT 500];
        
        if(!logsToDelete.isEmpty()){
            Database.delete(logsToDelete, false);
        }
    }
    
    public static Date setStringToDateFormat(String myDate) {
       String[] myDateOnly = myDate.split(' ');
       String[] strDate = myDateOnly[0].split('-');
       Integer myIntDate = integer.valueOf(strDate[2]);
       Integer myIntMonth = integer.valueOf(strDate[1]);
       Integer myIntYear = integer.valueOf(strDate[0]);
       Date d = Date.newInstance(myIntYear, myIntMonth, myIntDate);
       return d;
    }
    
    public static List<OrgWideEmailAddress> getOrgWideEmailAddressByName(String whichName){
        return [select Id, Address, DisplayName from OrgWideEmailAddress where DisplayName = :whichName];
    }

    /***************************************************************************************
    Developer -    Jerome To
    Date -         MAY 5, 2016
    Version -      1.0
    Function -     Constants for MONTHLY SALES TARGET
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static final Id MONTHLY_SALES_TARGET_GROSS_PROFIT = Schema.SObjectType.Monthly_Sales_Target__c.getRecordTypeInfosByName().get('Sales Target By Gross Profit').getRecordTypeId();
    public static final Id MONTHLY_SALES_TARGET_BOOKINGS = Schema.SObjectType.Monthly_Sales_Target__c.getRecordTypeInfosByName().get('Sales Target by Bookings').getRecordTypeId();

    public static final String OPPORTUNITY_STAGENAME_FULL_DEPOSIT = 'Customer Paid: Full Deposit'; //2.8~ (Previous: '6a. Customer Paid: Full Deposit')
    public static final String OPPORTUNITY_STAGENAME_FULL_BALANCE = 'Customer Paid: Full Balance'; //2.8~ (Previous: '6b. Customer Paid: Full Balance')
    public static final String OPPORTUNITY_STAGENAME_TRIP_COMPLETED = 'Trip Completed'; //2.8~ (Previous: '6c. Trip Completed')


    public static final String USER_NAME_API_USER = 'API User';

    //User Profile Names
    public static final String PROFILE_SYSADMIN = 'System Administrator';
    public static final String PROFILE_GB_SYSADMIN = 'Golfbreaks System Administrator';
    public static final String PROFILE_SALES_AGENT = 'Golfbreaks Sales User';

    // Campaign API RecordTypes
    public static final String CAMPAIGN_MARKETING_PROGRAM = 'MarketingProgram';
    public static final String CAMPAIGN_MARKETING_CAMPAIGN_EVENT = 'MarketingCampaignEvent';
    
        
    /***************************************************************************************
    Developer -    C Gaylan
    Date -         MAY 14, 2016
    Version -      1.0
    Function -     Get List Size using Iteration instead of <list>.size()
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static Integer getCount(List<SObject> sList){
        Integer count = 0;
        for(SObject ctr : sList){
            count++;        
        }
        return count;
    }
    
    public static Integer getSaveCount(List<Database.SaveResult> saveList){
        Integer count = 0;
        for(Database.SaveResult sv: saveList){
            count++;        
        }
        return count;
    }
    
    public static Integer getErrorCount(List<Database.Error> errList){
        Integer count = 0;
        for(Database.Error err : errList){
            count++;        
        }
        return count;
    }

    /***************************************************************************************
    Developer -    Jerome To
    Date -         MAY 25, 2016
    Version -      1.0
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static final String CASE_RECORD_TYPE_COMPLAINT = 'CAS_Complaint';
    public static final String CASE_RECORD_TYPE_AMENDMENT = 'CAS_Amendment';
    public static final String CASE_RECORD_TYPE_SERVICE_CASE = 'CAS_ServiceCase';
    
    /****************************************************************************************
    * Developer - James Radcliffe
    * Date - 27/08/2017
    * Version - 1.0
    * Function - Sprint Trigger & Trigger Tests Contants
    *****************************************************************************************/
    public static final String ACTIVE_SPRINT = 'Active Sprint';
    public static final String INACTIVE_SPRINT = 'Inactive Sprint';
    public static final String OTHER_SPRINT = 'Other Sprint';
    public static final String SALESFORCE_SPRINT_TYPE = 'Salesforce - Standard';
    public static final String WEB_SPRINT_TYPE = 'Web - Standard';

    public static final String OVERLAPPING_SPRINT_ERROR = 'The specified date range conflicts with the following Sprint of a matching type: ';
    
   /****************************************************************************************
    * Developer - James Radcliffe
    * Date - 17/04/2018
    * Version - 1.0
    * Function - Preference Centre Change History Contants
    *****************************************************************************************/
    
    //Preference Centre Field Labels
    public static final String NEW_CLIENT_DEFAULT = 'All';
    public static final String WEEKLY_NEWSLETTER = 'Weekly Newsletter';
    public static final String QUARTERLY_NEWSLETTER = 'Seasonal Newsletter';
    public static final String SMS_PREFERENCE = 'SMS';
    public static final String PHONE_PREFERENCE = 'Phone';
    public static final String EMAIL_PREFERENCE = 'Email';
    public static final String BROCHURE_PREFERENCE = 'Brochure';
    public static final String PGA_TOUR_PREFERENCE = 'PGA Tour';
    public static final String TOURNAMENTS_NEWSLETTER_PREFERENCE = 'Tournaments Newsletter';
    public static final String EVENTS_NEWSLETTER_PREFERENCE = 'Events Newsletter';


    //Preference Centre Change Reasons
    public static final String NEW_CLIENT_OPT_OUT = 'New Client Default (Opt Out)';
    public static final String AGENT_CONSOLE_EDIT = 'Client Contact Details Edit Page (Console)';
    public static final String CLIENT_MERGE_LAST_AUDIT = 'Merged Clients - Preferences updated to reflect Last Audit';
    public static final String CLIENT_MERGE_NEVER_AUDITED = 'Merged Clients - Preferences Cleared - Last Audit Not Identifiable';
    
    //Platform Log Constants
    public static final String PLATFORM_LOG_EXCEPTION_RT = 'Exception';
    public static final String PLATFORM_LOG_API_REQUEST_RT = 'APIRequest';
    public static final String PLATFORM_CALLOUT_LOG_RT = 'OutboundCallout';

    
    /****************************************************************************************
    * Developer - James Radcliffe
    * Date - 07/05/2019
    * Version - 2.7
    * Function - Territory Object/Automation Constants
    #############Change Log#############
    Modified by     Version     Change Date
    *****************************************************************************************/
    public static final String TERRITORY_DEFAULT_DELETION_ERROR = 'You must choose a new default territory (for the corresponding Business Unit) before removing this territory';
    public static final String TERRITORY_COUNTRY_VALIDATION_ERROR = 'A Territory with the same Country/Countries has been found. You must first remove the Country from the existing Territory before applying it to the new Territory';
    public static final String BUSINESS_UNIT_DEFAULT_DELETION_ERROR = 'You must choose a new default before removing this Business Unit';

    /****************************************************************************************
    * Developer - James Radcliffe
    * Date - 23/10/2019
    * Version - 1.1
    * Function - Integration Framework Constants
    #############Change Log#############
    Modified by     Version     Change Date
    *****************************************************************************************/
    public static final String DATA_EVENT_TYPE_REQUEST_TYPE_PAYLOAD = 'Payload';
    public static final String DATA_EVENT_TYPE_REQUEST_TYPE_WEBHOOK = 'Webhook';

    /****************************************************************************************
    * Developer - James Radcliffe
    * Date - 07/02/2022
    * Version - 1.1
    * Function - Breakpoints Constants 
    #############Change Log#############
    Modified by     Version     Change Date
    *****************************************************************************************/
    public static final String BREAKPOINTS_INVITE_EMAIL_STATUS_PENDING = 'Pending';
    public static final String BREAKPOINTS_INVITE_EMAIL_STATUS_PROCCESSED = 'Processed';
    public static final String BREAKPOINTS_INVITE_EMAIL_STATUS_SENT = 'Sent';
    public static final String BREAKPOINTS_INVITE_EMAIL_STATUS_CANCELLED = 'Cancelled';

    /****************************************************************************************
    * Developer - James Radcliffe
    * Date - 03/03/2022
    * Version - 1.1
    * Function - Booking Task Constants 
    #############Change Log#############
    Modified by     Version     Change Date
    *****************************************************************************************/
    public static final String BOOKING_TASK_STATUS_REQUIRED = 'Required';
    public static final String BOOKING_TASK_STATUS_PARTIAL_COMPLETE = 'Partially Complete';
    public static final String BOOKING_TASK_STATUS_COMPLETE = 'Complete';
    public static final String BOOKING_TASK_STATUS_NOT_REQUIRED = 'Not Required';

    /****************************************************************************************
    * Developer - James Radcliffe
    * Date - 13/02/2023
    * Version - 1.1
    * Function - Salesforce Utility Package Constants
    #############Change Log#############
    Modified by     Version     Change Date
    *****************************************************************************************/
    @Testvisible public static final String ENTITY_LOCKING_PERMISSION_SET_NAME = 'Entity_Administration_Lock_User';

    /****************************************************************************************
    * Developer - James Radcliffe
    * Date - 13/02/2023
    * Version - 1.1
    * Function - Booking Experience (BookingExperience__c) Constants
    #############Change Log#############
    Modified by     Version     Change Date
    *****************************************************************************************/
    @Testvisible public static final String BOOKING_EXPERIENCE_TYPE_STANDARD = 'Standard';

    /****************************************************************************************
     * Developer (Admin - Chandler Stuart)
     * Date -20-03-2023
     * Version - 3.0
     * Function - Outbound Callout (OutboundCallout__c) Constants
    #############Change Log#############
    Modified by     Version     Change Date
    *****************************************************************************************/
    @Testvisible public static final string OUTBOUND_CALLOUT_ENDPOINT = 'https://test';
    @Testvisible public static final string OUTBOUND_CALLOUT_HTTP_METHOD_REQUEST = 'GET';
    @Testvisible public static final string OUTBOUND_CALLOUT_CONTENT_TYPE_HEADER_JSON = 'application/json';
    @Testvisible public static final string OUTBOUND_CALLOUT_ACCEPT_HEADER_ANY = '*/*';
    @Testvisible public static final string OUTBOUND_CALLOUT_BODY = 'Test';
    @Testvisible public static final string OUTBOUND_CALLOUT_DATA_EVENT_TYPE_CH_OPP_CREATE = 'CHOpportunityCreate';
    
    /****************************************************************************************
     * Developer (Admin - Chandler Stuart)
     * Date - 20-03-2023
     * Version -3.0
     * Function - Routing Log Entry (GBWire__RoutingLogEntry__c) Constants
    #############Change Log#############
    Modified by     Version     Change Date
    *****************************************************************************************/
    @Testvisible public static final string ROUTING_LOG_ENTRY_MESSAGE = 'Test';

    /****************************************************************************************  
     * Developer - J Radcliffe  
     * Date - 11-04-2023  
     * Version -3.0  
     * Function - Leave Management Constants  
    #############Change Log#############  
    Modified by     Version     Change Date  
    *****************************************************************************************/  
    public static final String LEAVE_TYPE_WELLNESS_DAY = 'Well-being';  
    public static final String LEAVE_STATUS_PENDING_APPROVAL = 'Waiting for approval';  
    public static final String LEAVE_STATUS_APPROVED = 'Approved';

    public static final String LEAVE_PERIOD_BIMONTHLY = 'Bimonthly';

    /****************************************************************************************  
     * Developer - J Radcliffe  
     * Date - 26-09-2023  
     * Version - 1.0  
     * Function - Conversation__c constants
    #############Change Log#############  
    Modified by     Version     Change Date  
    *****************************************************************************************/  
    public static final String CONVERSATION_STATUS_CLOSED = 'Closed';  
    
     /****************************************************************************************
     * Developer (Admin - Chandler Stuart)
     * Date - 31-01-2024
     * Version - 1.0
     * Function - Preferred Agent (GBWIRE__Package) Constants
    #############Change Log#############
    Modified by     Version     Change Date
    *****************************************************************************************/
    public static final String PREFERRED_AGENT_TYPE_SHORT_TERM = 'Short Term';

}