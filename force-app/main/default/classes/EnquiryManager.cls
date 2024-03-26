/*
Name:  EnquiryManager.cls
Copyright © 2019  Golfbreaks
======================================================
======================================================
Purpose:
-------

Manager class responsible for Enquiry creation, de-duplication and update.

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2019-05-05  Initial development.
1.1  Mark Cane&    2019-05-15  Property cache added to Enquiry object + code integration changes.
1.2  J Radcliffe   2019-05-20  Derived attributes added to Enquiry.
1.3  Mark Cane&    2019-05-23  Enquiry object property modifications.
1.4  J Radcliffe   2019-05-24  Mapped APIV1Request attributes to local Enquiry Attributes via constructor/s
1.5  Mark Cane&    2019-06-03  processEnquiries>Enquiry object property modifications.
1.6  J Radcliffe   2019-06-03  processEnquiries>Enquiry object property modifications.
1.7  J Radcliffe   2019-06-03  Change in terminology from 'record' to 'sfRecord'
1.8  Mark Cane&    2019-06-05  Enhancements. Error messages and validation logic.
1.9  Mark Cane&    2019-06-06  Extensions to 1.8.
1.10 J Radcliffe   2019-06-07  new Enq property 'sfRecordObjectType'.
1.11 Mark Cane&    2019-06-10  processEnquiries>Added call to ClientRecordHelper.queryExistingClients (duplicate prevention on Email only).
1.12 J Radcliffe   2019-06-12  Big Fix - Null check on Action Type.
1.13 Mark Cane&    2019-06-12  processEnquiries>Clubhouse API callout refactoring (Client API if no matched client and no Enquiry - otherwise Enquiry API).
1.14 J Radcliffe   2019-06-17  new parameters for collecting client address details
1.15 Mark Cane&    2019-06-20  processEnquiries>New action override properties added to Enquiry class - action only.
1.16 J Radcliffe   2019-06-20  returning more error details in the response for Technical Errors
1.17 J Radcliffe   2019-06-21  new Enquiry Property; roomTypes
1.18 Mark Cane&    2019-06-21  Validation changes: 1-Phone number not mandatory, Email+Lastname not mandatory if accountId set.
1.19 J Radcliffe   2019-06-24  new Enquiry Property: numberOfNonGolfers
1.20 J Radcliffe   2019-06-24  do not override recordStatus if explicitly set (via the flow)
1.21 J Radcliffe   2019-06-27  Changed data type of 'rounds' from Integer to String (to allow for 'unlimited') - Sam B Request
1.22 J Radcliffe   2019-07-01  New technical error label.
1.23 Mark Cane&    2019-07-01  warningMessages handling added.
1.24 J Radcliffe   2019-07-04  New Enquiry Property: bookingSystemEnquiryKey
1.25 J Radcliffe   2019-07-09  New Enquiry Property: bookingSystemRecordOwnerId
1.26 Mark Cane&    2019-08-07  Enhancement. Booking System Assignment Rules.
1.26 J Radcliffe   2019-08-13  Replace call to 'ClientRecordHelper.queryExistingClients' with a call to 'DuplicateManagementHelper.findDuplicates'
1.27 J Radcliffe   2019-08-15  New method invocation following Client De-Dupe; DuplicateManagementHelper.upsertIndividualAndClientAccounts
1.28 J Radcliffe   2019-09-03  Adding support for specifying Duplicate Rules per Action Type (for Client Matching)
1.29 J Radcliffe   2019-09-04  New Enquiry Property 'bypassDupeCheck' - If true, skip the duplicate matching (force create client)
1.30 J Radcliffe   2019-09-09  Bug Fix -  External entry point - Invalid Id:
1.31 J Radcliffe   2019-09-30  New Properties - Data Event Types (Client and Enquiry).
1.32 Mark Cane&    2019-10-14  processEnquiries>Code tidy-up pluse re-location of Booking System Assignment rule execution. 
1.33 J Radcliffe   2019-10-18  Bug Fix - Booking System Assignment must take place before work item creation (to set on the work item)
1.34 J Radcliffe   2019-10-22  Bug Fix - Client Id must be passed to Client Data Event (not work item Id)
1.35 J Radcliffe   2019-10-28  New Action Type property to support our efforts to selectively sync data to external system - If SendToExternalSystem__c is true AND a data event is assigned, sync to external system
1.36 J Radcliffe   2020-01-09  Bug Fix - Work Item Insert resulting in the update of Accounts resulting in failure due to dupe management. Duplicate Management is handled within the package logic. Setting DML Option to 'Allow Save'
1.37 J Radcliffe   2020-01-09  New Enquiry Properties - tealiumId (Tracking Information -Audience Stream) and source (Client Information - Acquisition Source)
1.38 J Radcliffe   2020-01-09  Retiring two properties - bookingSystemEnquiryKey and bookingSystemEnquiryId (made redundant by the Dec19 release)
1.39 J Radcliffe   2020-01-28  New 'languagePreferenceCode' property
1.49 J Radcliffe   2020-02-12  Changing name of 'source' property (see 1.37) to 'accountSource' for consistency with ApexAction and field mapping
1.39 J Radcliffe   2020-03-04  New Enquiry Properties to support the Sarazen project - enquiryType, languagePreferenceCode, accountRecordTypeId
1.40 J Radcliffe   2020-03-04  New Enquiry Properties - suppressWelcomeEmail & clientCreatedOrUpdated - the latter returns 'CREATED'/'UPDATED' depending on whether an existing client record was found - returned in response and can be mapped to work item(s) as required
1.41 J Radcliffe   2020-03-20  Re-instating 'rounds' as a property of the API
1.42 J Radcliffe   2020-03-31  New property: 'timeZone' - e.g. TZ database name https://en.wikipedia.org/wiki/List_of_tz_database_time_zones - The customer's timeZone (to help the agent understand when customer should be contacted)
1.43 J Radcliffe   2020-05-11  New properties: 'tournamentName','region','stateOrCounty' - Support 'Demand' reporting with data passed from the web
1.44 J Radcliffe   2020-05-28  New property: 'sendToExternal' - If true, send Client to external system even if there is no related Opportunity/Enquiry
1.45 Mark Cane&    2020-06-10  Bug fixes. Null deference for unset sendToExternal. Commented out duplicate propertyName tournamentName,region,stateOrCounty 1.41+ and 1.43+.
1.46 J Radcliffe   2020-07-07  New property: isTest - To be to true when web enquiries are identifiable as Tests (for ring-fencing test records)
1.47 J Radcliffe   2020-10-01  New Class (CompetitionInformation) - To collect details regarding Competition entries + Plus PGA Tour Marketing Preference
1.48 J Radcliffe   2021-04-21  New ClientDetails property: referredBy - To be populated with the identifier for a Client who's referral resulted in this Action Type request. e.g. Portal sign up invitations from the Lead Booker. Typically this property will be populated with the SF Account Id (for directly mapping to created records), but could accept other identifiers such as an email in combination with a request handler to lookup the Account.
1.49 J Radcliffe   2021-11-10  New marketing tracking properties to support attribution modelling
1.50 J Radcliffe   2023-03-02  New marketing subscription properties - email (channel) + tournamentsNewsletter (subscription) + eventsNewsletter (subscription)
1.51 J Radcliffe   2023-03-20  Add events and tournaments newsletter properties to apex action.
1.52 J Radcliffe   2023-04-04  New properties: accountSourceDetails & isPGAPro
1.53 Mark Cane&    2023-11-23  Enhancements. ActionTypeRequest related changes.
1.54 J Radcliffe   2024-02-12  New properties: utmReferrer & utmSearchTerm
1.55 J Radcliffe   2024-03-06  New constructor for ActionTypeRequest__c requests (Salesforce data imports)
*/
global with sharing class EnquiryManager {

    global EnquiryManager(){}

    /*  ======================================================
        Method: processEnquiries
        Params: List of Enquiries to process.
        Returns: Boolean (false=runtime exception). 
        Purpose: Creates a Customer via the Clubhouse Client API for each Enquiry instance and populate the accountId property.
        Todo:
        
        TODO ----> (1) Additional unit tests.

        ----------------
        Revision History
        ----------------
        Ver. Author        Date        Detail
        1.0  Mark Cane&    2019-05-13  Initial development.
        1.5  Mark Cane&    2019-06-03  Code structure changes.
        1.8  Mark Cane&    2019-06-05  Enhacements. Error messages and validation logic.
        1.9  Mark Cane&    2019-06-06  Extensions to 1.8.
        1.11 Mark Cane&    2019-06-10  Added call to ClientRecordHelper.queryExistingClients (duplicate prevention on Email only).
        1.12 J Radcliffe   2019-06-12  Big Fix - Null check on Action Type
        1.13 Mark Cane&    2019-06-12  processEnquiries>Clubhouse API callout refactoring (Client API if no matched client and no Enquiry - otherwise Enquiry API).
        1.16 J Radcliffe   2019-06-20  returning more error details in the response for Technical Errors
        1.26 Mark Cane&    2019-08-07  Enhancement. Booking System Assignment Rules.
        1.26 J Radcliffe   2019-08-13  Replace call to 'ClientRecordHelper.queryExistingClients' with a call to 'DuplicateManagementHelper.findDuplicates'
        1.27 J Radcliffe   2019-08-15  New method invocation following Client De-Dupe; DuplicateManagementHelper.upsertIndividualAndClientAccounts
        1.28 J Radcliffe   2019-09-03  Adding support for specifying Duplicate Rules per Action Type (for client matching)
        1.32 Mark Cane&    2019-10-14  Code tidy-up pluse re-location of Booking System Assignment rule execution. 
        1.33 J Radcliffe   2019-10-18  Bug Fix - Booking System Assignment must take place before work item creation (to set on the work item)
        1.34 J Radcliffe   2019-10-22  Bug Fix - Client Id must be passed to Client Data Event (not work item Id)
        1.35 J Radcliffe   2019-10-28  New Action Type property to support our efforts to selectively sync data to external system - If SendToExternalSystem__c is true AND a data event is assigned, sync to external system
        1.36 J Radcliffe   2020-01-09  Bug Fix - Work Item Insert resulting in the update of Accounts resulting in failure due to dupe management. Duplicate Management is handled within the package logic. Setting DML Option to 'Allow Save'
        1.37 J Radcliffe   2020-03-08  Bug Fix - Trim the actionTypeName property before it is evaluated (remove trailing white space so it is recognised in query)
        ======================================================
    */
    global List<Enquiry> processEnquiries(List<Enquiry> enquiries){

        try {

            // 1. Validate specified ActionTypeName.

            Map<String,List<Enquiry>> actionTypeNameToEnquiries = new Map<String,List<Enquiry>>();
            for (Enquiry e : enquiries){
                e.validate();
                if (!e.isValid) continue;
                if(String.isBlank(e.actionTypeName)) continue;//1.12+
                e.actionTypeName = e.actionTypeName.trim();//1.37+

                if (!actionTypeNameToEnquiries.containsKey(e.actionTypeName)) actionTypeNameToEnquiries.put(e.actionTypeName, new List<Enquiry>());
                actionTypeNameToEnquiries.get(e.actionTypeName).add(e);                
            }
            if (actionTypeNameToEnquiries.isEmpty()) return enquiries;


            //List of records for upsert
            List<sObject> recordsToInsert = new List<sObject>();
            List<sObject> recordsToUpdate = new List<sObject>();
            List<Enquiry> insertEnquiries = new List<Enquiry>();
            List<Enquiry> updateEnquiries = new List<Enquiry>();

            for (String actionTypeName : actionTypeNameToEnquiries.keySet()){//1.1+
                
                ActionType__mdt actionType = ActionTypeHelper.getActionTypeByName(actionTypeName);
                
                //1. Retrieve & Set Action Types

                for (Enquiry e : actionTypeNameToEnquiries.get(actionTypeName)){
                    if(actionType == null){//1.12
                        e.errorMessages.put('1020',Label.Enquiry_Validation_Error_Invalid_Action_Type);//1.12
                        e.isAborted = true;//1.12
                        continue;//1.12
                    } else {
                        e.actionType = actionType;
                        ActionTypeHelper.addActionTypeSettingsToEnquiryPropertyCache(e,actionType);
                        //Default local enquiry properties
                        if(e.recordStatus == null && actionType.RecordStageStatus__c != null) e.recordStatus = actionType.RecordStageStatus__c; //1.20-
                        if(actionType.SObjectType__c != null) e.sfRecordObjectType = actionType.SObjectType__c;//1.10
                    }
                }
                if(actionType==null) continue;//1.12+
                
                //2. Duplicate Management - Check for existing Client record based on select Duplicate Rules (based on A/T config)

                if (!DuplicateManagementHelper.findDuplicates(actionTypeNameToEnquiries.get(actionTypeName),actionType.ClientDuplicateRuleDeveloperName__c/*1.28*/)){ continue; }//1.26+
                //if (!ClientRecordHelper.queryExistingClients( actionTypeNameToEnquiries.get(actionTypeName) )){ continue; }//1.11+//1.26-
                
                //3. Create or Update Client Accounts

                if (!DuplicateManagementHelper.upsertIndividualAndClientAccounts(actionTypeNameToEnquiries.get(actionTypeName))){ continue; }//1.27+
                
                //4. Booking System Assignment

                BookingSystemAssignmentRuleHelper.runBookingSystemAssignmentRules(enquiries);//1.33+

                //5. Local Handler Processing

                if (String.isNotBlank(actionType.RecordHandlerClassName__c)){
                    IEnquiryRecordHandler recordHandler = ActionTypeHelper.getHandlerClass(actionType.RecordHandlerClassName__c);
                    if (recordHandler==null){
                        for (Enquiry e : actionTypeNameToEnquiries.get(actionTypeName)){
                            e.errorMessages.put('1020',Label.Enquiry_Validation_Error_Invalid_Record_Helper);//1.8~//1.22~
                            e.isAborted=true;
                        }
                        continue;
                    }
                    if(!recordHandler.processEnquiries(actionTypeNameToEnquiries.get(actionTypeName))){ continue; } //1.6
                }

                //6. Work Item Creation

                //Instantiate and prepare record (sObject) on enquiries
                if(!EnquiryRecordHelper.mapEnquiryToSObject(actionTypeNameToEnquiries.get(actionTypeName))){ continue; }//1.6

                for(Enquiry e : actionTypeNameToEnquiries.get(actionTypeName)){
                    if(e.sfRecord!=null && !e.isAborted){//1.7,1.8~
                        //DML on generic List<SObject> only allowed for insert, update or delete - Separating into insert & update lists
                        if(e.sfRecord.get('Id')!= null){
                            recordsToUpdate.add(e.sfRecord);//1.7
                            updateEnquiries.add(e);
                        }else{
                            recordsToInsert.add(e.sfRecord);//1.7
                            insertEnquiries.add(e);
                        }
                    } 
                }                   
            }//actionType.

            //1.36+
            Database.DMLOptions dml = new Database.DMLOptions(); 
            dml.DuplicateRuleHeader.allowSave = true;
            dml.optAllOrNone = false;

            if(recordsToInsert.size()>0){
                //[Removed for release] system.debug('Inserting records');
                Database.SaveResult[] results = database.insert(recordsToInsert,dml);//1.36~ (changing from 'false' to 'dml')

                LogHelper.logExceptions(results, 'EnquiryManager','processEnquiries', recordsToInsert);

                for(integer i = 0;i<results.size();i++){
                    if(results[i].isSuccess()){
                        insertEnquiries[i].sfRecordId = (Id)results[i].getId();
                        
                        //[Removed for release] System.debug('Inserted record='+insertEnquiries[i].sfRecordId);
                        //[Removed for release] System.debug('Inserted record error state='+insertEnquiries[i].errorMessages);
                        //[Removed for release] System.debug('Inserted record error state='+insertEnquiries[i].isAborted);

                    }else{
                        insertEnquiries[i].errorMessages.put('3001',Label.Enquiry_Logic_Error_Record_Insert_Failed+': '+results[i].getErrors()[0].message);//1.8~, 1.9~
                        insertEnquiries[i].isAborted = true;
                    }
                }
            }
            if(recordsToUpdate.size()>0){
                //[Removed for release] system.debug('Updating records');
                Database.SaveResult[] results = database.update(recordsToUpdate,dml);//1.36~ (changing from 'false' to 'dml')

                LogHelper.logExceptions(results, 'EnquiryManager','processEnquiries', recordsToUpdate);

                for(integer i = 0;i<results.size();i++){
                    if(results[i].isSuccess()){
                        updateEnquiries[i].sfRecordId = results[i].getId();
                    }else{                    
                        updateEnquiries[i].errorMessages.put('3010',Label.Enquiry_Logic_Error_Record_Update_Failed+': '+results[i].getErrors()[0].message);//1.8~, 1.9~
                        updateEnquiries[i].isAborted = true;
                    }
                }
            }

            //BookingSystemAssignmentRuleHelper.runBookingSystemAssignmentRules(enquiries);//1.26+,1.32~ //1.33-

            // 2. Booking System Integeration - Data Event Types.

            List<DataEventTypeAction.DataEventTypeActionRequest> requests = new List<DataEventTypeAction.DataEventTypeActionRequest>();
            Map<Id,Enquiry> sfRecordIdToEnquiry = new Map<Id,Enquiry>();
            for(Enquiry enq : enquiries){
                if(enq.isAborted || enq.sfRecordId == null || enq.clientDetails == null || enq.clientDetails.accountId == null) continue;//1.34~
                if(!enq.actionType.SendToExternalSystem__c && (enq.sendToExternal==null || !enq.sendToExternal)) continue;//1.35+ //1.44~ 1.45~
                if(!enq.actionType.CreateEnquiry__c){//1.13+ Use the Client API if Enquiry is not created for the action type.
                    if (String.isNotBlank(enq.clientDataEvent)) requests.add(new DataEventTypeAction.DataEventTypeActionRequest(enq.clientDataEvent,enq.clientDetails.accountId));//1.34~
                } else {
                   if (String.isNotBlank(enq.enquiryDataEvent)) requests.add(new DataEventTypeAction.DataEventTypeActionRequest(enq.enquiryDataEvent,enq.sfRecordId));
                }
                sfRecordIdToEnquiry.put(enq.sfRecordId,enq);
            }

            if (!requests.isEmpty()){
            
                Enquiry e;
                for(DataEventTypeAction.DataEventTypeActionResult result : DataEventTypeAction.invokeDataEventType(requests)){
                    if(!sfRecordIdToEnquiry.containsKey(result.recordId)) continue;
                    e = sfRecordIdToEnquiry.get(result.recordId);
                    e.isAborted = !result.isSuccess;
                    if(!result.isSuccess) e.errorMessages.put('1060',Label.Data_Event_Processing_Failure);
                }
            }            

        } catch(Exception ex){
            //[Removed for release] system.debug('Apex Exception: '+ex);
            LogHelper.logExceptions(ex, 'EnquiryManager', 'processEnquiries');
            for (Enquiry e : enquiries){ e.errorMessages.put('0001',Label.Enquiry_Technical_Error+': '+ex.getMessage()); }//1.8+//1.16+
        }

        for (Enquiry e : enquiries){ 
            //[Removed for release] system.debug('isAborted: '+e.isAborted);
            //[Removed for release] system.debug('hasErrors: '+e.hasErrors);
            //[Removed for release] system.debug('errors: '+e.errorMessages);
            e.isSuccess = (!e.isAborted && !e.hasErrors); 
            //[Removed for release] system.debug('isSuccess: '+e.isSuccess);            
        }//1.8+
        return enquiries;
    }

    // Inner classes.
    global class Enquiry {

        public Map<String,Object> propertyCache = new Map<String,Object>();//1.1+

        // Input members.
        public String actionTypeName { get; set; }        

        // Derived members.
        public Boolean isValid { get; private set; }// record passed initial validation.
        public Boolean isAborted { get; set; }//1.8~ record was aborted during processing.
        public ActionType__mdt actionType { get; set; }
        
        //1.2+
        public sObject sfRecord { get;set; }
        public String sfRecordObjectType {get;set;}//1.10
        public Id duplicateEnquiryId { get;set; }
        public String uniqueIdentifier { get;set; }
        public String recordStatus { get; set{
            recordStatus = value;
            propertyCache.put('recordStatus',value);
        }}
        public String recordName { get; set{
            recordName = value;
            propertyCache.put('recordName',value);
        }}
        public String bookingSystemClientId { get; set; }//1.3+
        
        public String clientCreatedOrUpdated { get; set;} //1.40+

        /*public String bookingSystemEnquiryId { get; set{//1.3+ //1.38-
            bookingSystemEnquiryId = value;
            propertyCache.put('bookingSystemEnquiryId',value);
        }}*/

        /*public String bookingSystemEnquiryKey { get; set{//1.24 //1.38-
            bookingSystemEnquiryKey = value;
            propertyCache.put('bookingSystemEnquiryKey',value);
        }}*/

        public String enquiryDataEvent { get; set{//1.31
            enquiryDataEvent = value;
        }}

        public String clientDataEvent { get; set{//1.31
            clientDataEvent = value;
        }}

        public String bookingSystemRecordOwnerId { get; set{//1.25
            bookingSystemRecordOwnerId = value;
            propertyCache.put('bookingSystemRecordOwnerId',value);
        }}

        public String enquiryRecordTypeId { get; set {
                enquiryRecordTypeId = value;
                propertyCache.put('enquiryRecordTypeId',value);
            }
        }//1.15+

        public String bookingSystem { get; set {
                bookingSystem = value;
                propertyCache.put('bookingSystem',value);
            }
        }//1.15+       

        public String businessUnitId { get; set {
                businessUnitId = value;
                propertyCache.put('businessUnitId',value);
            }
        }//1.15+

        public Boolean routeOnCreate { get; set {
                routeOnCreate = value;
                propertyCache.put('routeOnCreate',value);
            }
        }//1.15+

        public string relatedToId { get; set {
                relatedToId = value;
                propertyCache.put('relatedToId',value);
            }        
        }//1.27+
        public Boolean bypassDupeCheck { get; set {
                bypassDupeCheck = value;
                propertyCache.put('bypassDupeCheck',value);
            }
        }//1.29+

        public Boolean sendToExternal { get; set{//1.44+
            sendToExternal = value;
            propertyCache.put('sendToExternal',value);
        } }    

        public Boolean isTest { get; set{//1.46+
            isTest = value;
            propertyCache.put('isTest',value);
        } }    

        public EnquiryManager.ClientDetails clientDetails;
        public EnquiryManager.TripDetails tripDetails;
        public EnquiryManager.MarketingPreferences marketingPreferences;
        public EnquiryManager.TaskDetails taskDetails;
        public EnquiryManager.TrackingInformation trackingInformation;
        public EnquiryManager.CompetitionInformation competitionInformation;//1.47+
        
        // Output members.
        public Boolean isSuccess { get; set; }//1.8~ record was successfully processed; set post-processing.       

        public Boolean hasErrors {//1.3~,1.8~
            get {
                return (errorMessages!=null && !errorMessages.isEmpty());
            } private set;
        }
        
        public Map<String,String> errorMessages { get; set; }
        public Map<String,String> warningMessages { get; set; }//1.23+

        public Id sfRecordId { get; set;}

        public Enquiry(){
            //default constructor - use for non-API inputs.
            this.isSuccess=false;//1.8+
            this.isAborted=false;//1.8+

            errorMessages = new Map<String,String>();
            warningMessages = new Map<String,String>();//1.23+

            this.clientDetails = new EnquiryManager.ClientDetails();
            this.tripDetails = new EnquiryManager.TripDetails();
            this.marketingPreferences = new EnquiryManager.MarketingPreferences();
            this.taskDetails = new EnquiryManager.TaskDetails();
            this.trackingInformation = new EnquiryManager.TrackingInformation();
            this.competitionInformation = new EnquiryManager.CompetitionInformation();//1.47+
        }

        //1.55+
        public Enquiry(ActionTypeRequest__c actionTypeRequest){
            this.isSuccess=false;
            this.isAborted=false;

            errorMessages = new Map<String,String>();
            warningMessages = new Map<String,String>();

            this.clientDetails = new EnquiryManager.ClientDetails(actionTypeRequest);
            propertyCache.putAll(this.clientDetails.propertyCache);
            propertyCache.putAll(this.clientDetails.clientAddress.propertyCache);//1.14

            this.tripDetails = new EnquiryManager.TripDetails(actionTypeRequest);
            propertyCache.putAll(this.tripDetails.propertyCache);

            this.marketingPreferences = new EnquiryManager.MarketingPreferences(actionTypeRequest);
            propertyCache.putAll(this.marketingPreferences.propertyCache);

            this.taskDetails = new EnquiryManager.TaskDetails();
            this.trackingInformation = new EnquiryManager.TrackingInformation();
            this.competitionInformation = new EnquiryManager.CompetitionInformation();

            

        }

        public Enquiry(EnquiryAPIV1Request enquiryAPIRequest){            
            //specific parameterised constructor - use for API inputs.
            this.isSuccess=false;//1.8+
            this.isAborted=false;//1.8+

            errorMessages = new Map<String,String>();
            warningMessages = new Map<String,String>();//1.23+

            this.actionTypeName = enquiryAPIRequest.actionTypeName;
            this.isTest = enquiryAPIRequest.isTest;//1.46+
            
            this.clientDetails = new EnquiryManager.ClientDetails(enquiryAPIRequest.ClientDetails);
            propertyCache.putAll(this.clientDetails.propertyCache);
            propertyCache.putAll(this.clientDetails.clientAddress.propertyCache);//1.14

            this.tripDetails = new EnquiryManager.TripDetails(enquiryAPIRequest.TripDetails);
            propertyCache.putAll(this.tripDetails.propertyCache);

            this.marketingPreferences = new EnquiryManager.MarketingPreferences(enquiryAPIRequest.MarketingPreferences);
            propertyCache.putAll(this.marketingPreferences.propertyCache);

            this.taskDetails = new EnquiryManager.TaskDetails(enquiryAPIRequest.TaskDetails);
            propertyCache.putAll(this.taskDetails.propertyCache);

            this.trackingInformation = new EnquiryManager.TrackingInformation(enquiryAPIRequest.TrackingInformation);
            propertyCache.putAll(this.trackingInformation.propertyCache);

            this.competitionInformation = new EnquiryManager.CompetitionInformation(enquiryAPIRequest.CompetitionInformation);//1.47+
            propertyCache.putAll(this.competitionInformation.propertyCache);
        }

        public Enquiry(EnquiryActionInput enquiryActionInput){            
            //specific parameterised constructor - use for Action inputs.
            this.isSuccess=false;
            this.isAborted=false;

            errorMessages = new Map<String,String>();
            warningMessages = new Map<String,String>();//1.23+

            this.actionTypeName = enquiryActionInput.actionTypeName;

            this.enquiryRecordTypeId = enquiryActionInput.enquiryRecordTypeId;//1.15+
            this.recordStatus = enquiryActionInput.recordStatus;//1.15 map to pre-existing property.
            this.bookingSystem = enquiryActionInput.bookingSystem;
            this.recordName = enquiryActionInput.recordName;//1.15 map to pre-existing property.
            this.businessUnitId = enquiryActionInput.businessUnitId;
            this.routeOnCreate = enquiryActionInput.routeOnCreate;
            this.bookingSystemRecordOwnerId = enquiryActionInput.bookingSystemRecordOwnerId;//1.26
            this.bypassDupeCheck = enquiryActionInput.bypassDupeCheck;//1.29+
            this.sendToExternal = (enquiryActionInput.sendToExternal != null)?enquiryActionInput.sendToExternal:false;//1.44+
            
            this.clientDetails = new EnquiryManager.ClientDetails(enquiryActionInput);
            propertyCache.putAll(this.clientDetails.propertyCache);
            propertyCache.putAll(this.clientDetails.clientAddress.propertyCache);//1.14

            this.tripDetails = new EnquiryManager.TripDetails(enquiryActionInput);
            propertyCache.putAll(this.tripDetails.propertyCache);

            this.marketingPreferences = new EnquiryManager.MarketingPreferences(enquiryActionInput);
            propertyCache.putAll(this.marketingPreferences.propertyCache);

            this.taskDetails = new EnquiryManager.TaskDetails(enquiryActionInput);
            propertyCache.putAll(this.taskDetails.propertyCache);

            //this.trackingInformation = new EnquiryManager.TrackingInformation(); //1.49-
            this.trackingInformation = new EnquiryManager.TrackingInformation(enquiryActionInput); //1.49+
            propertyCache.putAll(this.trackingInformation.propertyCache);//1.49+
        }        

        public Object getValue(String propertyName){//1.1+
            return propertyCache.containsKey(propertyName) ? propertyCache.get(propertyName) : null;
        }        

        public void validate(){
            if(errorMessages == null) errorMessages = new Map<String,String>();
            if(warningMessages == null) warningMessages = new Map<String,String>();//1.23+
            
            if (String.isBlank(actionTypeName)) errorMessages.put('1001',Label.Enquiry_Validation_Error_Missing_Action_Type);

            Set<String> missingMandatoryFields = new Set<String>();

            if (String.isBlank(clientDetails.accountId) && !propertyCache.containsKey('ClientDetails.accountId')){//1.18+ 1.53~
                if (String.isBlank(clientDetails.lastName) && !propertyCache.containsKey('ClientDetails.lastName')) missingMandatoryFields.add('LastName');//1.53~
                if (String.isBlank(clientDetails.email) && !propertyCache.containsKey('ClientDetails.email')) missingMandatoryFields.add('Email');//1.53~
            }

            //1.18- if (String.isBlank(clientDetails.homePhone) && 
            //    String.isBlank(clientDetails.mobilePhone) && 
            //    String.isBlank(clientDetails.workPhone)) missingMandatoryFields.add('Phone');            
            
            if (!missingMandatoryFields.isEmpty()){                                                
                errorMessages.put('1020',Label.Enquiry_Validation_Error_Missing_Mandatory_Fields+' ['+String.join(new List<String>( missingMandatoryFields ), ',')+']');
            }
            isValid = errorMessages.isEmpty();
            isAborted = !isValid;
        }
    }

    public class ClientDetails {//<-- If null, a find or create is performed
        
        public EnquiryManager.ClientAddress clientAddress;//1.14
        
        public String accountId {get; set{
            if(String.isEmpty(value)) value=null;//1.30+
            accountId = value;
            propertyCache.put('ClientDetails.accountId',value);
        }} 
        public String accountSource { get; set{//1.37+ //1.49~
            accountSource = value;
            propertyCache.put('ClientDetails.accountSource',value);
        }}
        public String accountSourceDetails { get; set{//1.52+
            accountSourceDetails = value;
            propertyCache.put('ClientDetails.accountSourceDetails',value);
        }}
        public Boolean isPGAPro { get; set{//1.52+
            isPGAPro = value;
            propertyCache.put('ClientDetails.isPGAPro',value);
        }}
        public String preferredContactMethod {get; set{
            preferredContactMethod = value;
            propertyCache.put('ClientDetails.preferredContactMethod',value);
        }} 
        public String salutation {get; set{
            salutation = value;
            propertyCache.put('ClientDetails.salutation',value);
        }} 
        public String firstName { get; set{
            firstName = value;
            propertyCache.put('ClientDetails.firstName',value);
        }}
        public String lastName { get; set{
            lastName = value;
            propertyCache.put('ClientDetails.lastName',value);
        } }
        public String email { get; set{
            email = value;
            propertyCache.put('ClientDetails.email',value);
        } }
        public String mobilePhone { get; set{
            mobilePhone = value;
            propertyCache.put('ClientDetails.mobilePhone',value);
        } }
        public String workPhone { get; set{
            workPhone = value;
            propertyCache.put('ClientDetails.workPhone',value);
        } }
        public String homePhone { get; set{
            homePhone = value;
            propertyCache.put('ClientDetails.homePhone',value);
        } }    
        public String languagePreferenceCode { get; set{//1.39+
            languagePreferenceCode = value;
            propertyCache.put('ClientDetails.languagePreferenceCode',value);
        } }   

        public String accountRecordTypeId { get; set{//1.39+
            accountRecordTypeId = value;
            propertyCache.put('ClientDetails.accountRecordTypeId',value);
        } }    

        public String timeZone { get; set{//1.42+
            timeZone = value;
            propertyCache.put('ClientDetails.timeZone',value);
        } }    

        public String referredBy { get; set{//1.48+
            referredBy = value;
            propertyCache.put('ClientDetails.referredBy',value);
        } }    

        public Map<String,Object> propertyCache = new Map<String,Object>();//1.1+

        public ClientDetails(){}

        public ClientDetails(EnquiryAPIV1Request.ClientDetails clientDetails){ 
            if(clientDetails == null) clientDetails = new EnquiryAPIV1Request.clientDetails();            
            //1.4
            this.accountId = clientDetails.accountId;
            this.firstName = clientDetails.firstName;
            this.lastName = clientDetails.lastName;
            this.email = clientDetails.email;
            this.mobilePhone = clientDetails.mobilePhone;
            this.workPhone = clientDetails.workPhone;
            this.homePhone = clientDetails.homePhone;
            this.salutation = clientDetails.salutation;
            this.languagePreferenceCode = clientDetails.languagePreferenceCode;//1.39+
            this.preferredContactMethod = clientDetails.preferredContactMethod;           
            this.clientAddress = new EnquiryManager.ClientAddress(clientDetails.clientAddress);//1.14
            this.accountSource = clientDetails.accountSource;
            this.accountRecordTypeId = clientDetails.accountRecordTypeId;//1.39+
            this.timeZone = clientDetails.timeZone;//1.42+
            this.referredBy = clientDetails.referredBy;//1.48+
            this.accountSourceDetails = clientDetails.accountSourceDetails;//1.52+
            this.isPGAPro = clientDetails.isPGAPro;//1.52+
            
        }

        //1.55+
        public ClientDetails(ActionTypeRequest__c atr){ 
            if(atr == null) atr = new ActionTypeRequest__c();            
            this.accountId = atr.Account__c;
            this.firstName = atr.FirstName__c;
            this.lastName = atr.LastName__c;
            this.email = atr.Email__c;
            this.mobilePhone = atr.MobilePhone__c;
            this.workPhone = atr.Phone__c;
            this.homePhone = atr.HomePhone__c;
            this.salutation = atr.Salutation__c;
            this.languagePreferenceCode = atr.LanguagePreference__c;
            this.accountSource = atr.AccountSource__c;
            this.timeZone = atr.TimeZone__c;
            this.referredBy = atr.ReferredBy__c;

            this.clientAddress = new EnquiryManager.ClientAddress(atr);

            
        }

        public ClientDetails(EnquiryActionInput enquiryActionInput){ 
            this.accountId = enquiryActionInput.accountId;
            this.firstName = enquiryActionInput.firstName;
            this.lastName = enquiryActionInput.lastName;
            this.email = enquiryActionInput.email;
            this.mobilePhone = enquiryActionInput.mobilePhone;
            this.workPhone = enquiryActionInput.workPhone;
            this.homePhone = enquiryActionInput.homePhone;
            this.salutation = enquiryActionInput.salutation;
            this.preferredContactMethod = enquiryActionInput.preferredContactMethod;
            this.languagePreferenceCode = enquiryActionInput.languagePreferenceCode;//1.39+
            this.clientAddress = new EnquiryManager.ClientAddress(enquiryActionInput);//1.14
            this.accountSource = enquiryActionInput.accountSource;
            this.accountRecordTypeId = enquiryActionInput.accountRecordTypeId;//1.39+
            this.accountSource = enquiryActionInput.accountSource;
            this.accountSourceDetails = enquiryActionInput.accountSourceDetails;
            this.isPGAPro = enquiryActionInput.isPGAPro;
        }        
    }

    public class TaskDetails {
        public String bookingId {get; set{
            bookingId = value;
            propertyCache.put('TaskDetails.bookingId',value);
        }}
        public String subject { get; set{
            subject = value;
            propertyCache.put('TaskDetails.subject',value);
        } }
        public String type { get; set{
            type = value;
            propertyCache.put('TaskDetails.type',value);
        }}
        public String origin { get; set{
            origin = value;
            propertyCache.put('TaskDetails.origin',value);
        }}
        public String detail { get; set{
            detail = value;
            propertyCache.put('TaskDetails.detail',value);
        } }
        public Map<String,Object> propertyCache = new Map<String,Object>();//1.1+

        public TaskDetails(){}

        public TaskDetails(EnquiryAPIV1Request.TaskDetails taskDetails){ 
            if(taskDetails == null) taskDetails = new EnquiryAPIV1Request.taskDetails();  
        
            this.bookingId = taskDetails.bookingId;
            this.subject = taskDetails.subject;
            this.type = taskDetails.type;
            this.origin = taskDetails.origin;
            this.detail = taskDetails.detail;
        }

        public TaskDetails(EnquiryActionInput enquiryActionInput){ 
            this.bookingId = enquiryActionInput.bookingId;
            this.subject = enquiryActionInput.subject;
            this.type = enquiryActionInput.type;
            this.origin = enquiryActionInput.origin;
            this.detail = enquiryActionInput.detail;
        }        
    }

    public class TripDetails {//<-- If null the territory is derived from the Business Unit & Countries
        public String territoryId {get; set{
            territoryId = value;
            propertyCache.put('TripDetails.territoryId',value);
        }} 
        public Integer groupSize {get;set{
            groupSize = value;
            propertyCache.put('TripDetails.groupSize',value);
        }}
        public String rounds {get;set{//1.21
            rounds = value;
            propertyCache.put('TripDetails.rounds',value);
        }}
        public Integer nights {get;set{
            nights = value;
            propertyCache.put('TripDetails.nights',value);
        }}
        public String additionalInformation {get;set{
            additionalInformation = value;
            propertyCache.put('TripDetails.additionalInformation',value);
        }}
        public String venue {get;set{
            venue = value;
            propertyCache.put('TripDetails.venue',value);
        }}
        public Date travelDate {get;set{
            travelDate = value;
            propertyCache.put('TripDetails.travelDate',value);
        }}
        public List<String> countries {get;set{
            countries = value;
            propertyCache.put('TripDetails.countries',value);
        }}
        public DateTime callBackDateTime {get;set{
            callBackDateTime = value;
            propertyCache.put('TripDetails.callBackDateTime',value);
        }}
        public String source {get;set{
            source = value;
            propertyCache.put('TripDetails.source',value);
        }}
        public Boolean tournamentEnquiry {get;set{
            tournamentEnquiry = value;
            propertyCache.put('TripDetails.tournamentEnquiry',value);
        }}
        public String associationId {get;set{
            associationId = value;
            propertyCache.put('TripDetails.associationId',value);
        }}
        public String basketDetails {get;set{
            basketDetails = value;
            propertyCache.put('TripDetails.basketDetails',value);
        }}
        public String currencyISOCode {get;set{
            currencyISOCode = value;
            propertyCache.put('TripDetails.currencyISOCode',value);
        }}
        public List<String> specialistSkills {get;set{
            specialistSkills = value;
            propertyCache.put('TripDetails.specialistSkills',value);
        }}
        public Decimal amount {get;set{
            amount = value;
            propertyCache.put('TripDetails.amount',value);
        }}
        public Decimal transactionAuthorisedAmount {get;set{
            transactionAuthorisedAmount = value;
            propertyCache.put('TripDetails.transactionAuthorisedAmount',value);
        }}
        public String roomTypes {get;set{
            roomTypes = value;
            propertyCache.put('TripDetails.roomTypes',value);
        }}//1.17+
        public Integer numberOfNonGolfers {get;set{
            numberOfNonGolfers = value;
            propertyCache.put('TripDetails.numberOfNonGolfers',value);
        }}//1.19+
        public String enquiryType { get; set{//1.39+
            enquiryType = value;
            propertyCache.put('TripDetails.enquiryType',value);
        } }   
        public String tournamentName { get; set{//1.43+
            tournamentName = value;
            propertyCache.put('TripDetails.tournamentName',value);
        } }  
        public String region { get; set{//1.43+
            region = value;
            propertyCache.put('TripDetails.region',value);
        } }  
        public String stateOrCounty { get; set{//1.43+
            stateOrCounty = value;
            propertyCache.put('TripDetails.stateOrCounty',value);
        } }  

        //1.45- public String tournamentName { get; set{//1.41+
        //1.45-     tournamentName = value;
        //1.45-     propertyCache.put('TripDetails.tournamentName',value); 
        //1.45- } }   

        //1.45- public String region { get; set{//1.41+
        //1.45-     region = value;
        //1.45-     propertyCache.put('TripDetails.region',value);
        //1.45- } }   

        //1.45- public String stateOrCounty { get; set{//1.41+
        //1.45-     stateOrCounty = value;
        //1.45-     propertyCache.put('TripDetails.stateOrCounty',value);
        //1.45- } }   

        public Map<String,Object> propertyCache = new Map<String,Object>();//1.1+

        public TripDetails(){}

        public TripDetails(EnquiryAPIV1Request.TripDetails tripDetails){
            if(tripDetails == null) tripDetails = new EnquiryAPIV1Request.tripDetails();
            //1.4
            this.territoryId = tripDetails.territoryId;
            this.groupSize = tripDetails.groupSize;
            this.rounds = tripDetails.rounds; //1.21 //1.41
            this.nights = tripDetails.nights;
            this.additionalInformation = tripDetails.additionalInformation;
            this.venue = tripDetails.venue;
            this.travelDate = tripDetails.travelDate;
            this.countries = tripDetails.countries;
            this.callBackDateTime = tripDetails.callBackDateTime;
            this.source = tripDetails.source;
            this.tournamentEnquiry = tripDetails.tournamentEnquiry;
            this.associationId = tripDetails.associationId;
            this.basketDetails = tripDetails.basketDetails;
            this.currencyISOCode = tripDetails.currencyISOCode;
            this.specialistSkills = tripDetails.specialistSkills;
            this.amount = tripDetails.amount;
            this.transactionAuthorisedAmount = tripDetails.transactionAuthorisedAmount;
            this.enquiryType = tripDetails.enquiryType;//1.39+
            this.tournamentName = tripDetails.tournamentName;//1.43+
            this.region = tripDetails.region;//1.43+
            this.stateOrCounty = tripDetails.stateOrCounty;//1.43+
        }

        //1.55+
        public TripDetails(ActionTypeRequest__c atr){
            if(atr == null) atr = new ActionTypeRequest__c();
            this.territoryId = atr.Territory__c;
            this.groupSize = (atr.TravelGroupSize__c != null)?Integer.valueOf(atr.TravelGroupSize__c):null;
            this.rounds = atr.Rounds__c; 
            this.nights = (atr.Nights__c != null)?Integer.valueOf(atr.Nights__c):null;
            this.additionalInformation = atr.AdditionalInformation__c;
            this.venue = atr.Venue__c;
            this.travelDate = atr.PreferredTravelDate__c;
            this.countries = (atr.CountriesInterested__c != null)?(atr.CountriesInterested__c.contains(','))?atr.CountriesInterested__c.split(','):new List<String>{atr.CountriesInterested__c}:null;
            this.source = atr.LeadSource__c;
            this.associationId = atr.Association__c;
            this.currencyISOCode = atr.CurrencyIsoCode__c;
            this.specialistSkills = (atr.SpecialistSkills__c != null)?(atr.SpecialistSkills__c.contains(','))?atr.SpecialistSkills__c.split(','):new List<String>{atr.SpecialistSkills__c}:null;
            this.enquiryType = atr.EnquiryType__c;
        }


        public TripDetails(EnquiryActionInput enquiryActionInput){
            this.territoryId = enquiryActionInput.territoryId;
            this.groupSize = enquiryActionInput.groupSize;
            this.rounds = enquiryActionInput.rounds;
            this.nights = enquiryActionInput.nights;
            this.additionalInformation = enquiryActionInput.additionalInformation;
            this.venue = enquiryActionInput.venue;
            this.travelDate = enquiryActionInput.travelDate;
            this.countries = enquiryActionInput.countries;
            this.callBackDateTime = enquiryActionInput.callBackDateTime;
            this.source = enquiryActionInput.source;
            this.tournamentEnquiry = enquiryActionInput.tournamentEnquiry;
            this.associationId = enquiryActionInput.associationId;
            this.basketDetails = enquiryActionInput.basketDetails;
            this.currencyISOCode = enquiryActionInput.currencyISOCode;
            this.specialistSkills = enquiryActionInput.specialistSkills;
            this.amount = enquiryActionInput.amount;
            this.transactionAuthorisedAmount = enquiryActionInput.transactionAuthorisedAmount;
            this.roomTypes = enquiryActionInput.roomTypes;//1.17+
            this.numberOfNonGolfers = enquiryActionInput.numberOfNonGolfers;//1.19+
            this.enquiryType = EnquiryActionInput.enquiryType;//1.39+
        }
    }

    public class MarketingPreferences {
        //IMPORTANT - Marketing Preferences are tri-state: 
        //false = Unsubscribe
        //true = Subscribe
        //null = Ignore
        //1.4
        public Boolean phone { get; set{
            phone = value;
            propertyCache.put('MarketingPreferences.phone',value);
        }}
        public Boolean sms { get; set{
            sms = value;
            propertyCache.put('MarketingPreferences.sms',value);
        }}
        public Boolean email { get; set{//1.50+
            email = value;
            propertyCache.put('MarketingPreferences.email',value);
        }}
        public Boolean seasonalNewsletter { get; set{
            seasonalNewsletter = value;
            propertyCache.put('MarketingPreferences.seasonalNewsletter',value);
        } }
        public Boolean weeklyNewsletter { get; set{
            weeklyNewsletter = value;
            propertyCache.put('MarketingPreferences.weeklyNewsletter',value);
        } }
        public Boolean tournamentsNewsletter { get; set{//1.50+
            tournamentsNewsletter = value;
            propertyCache.put('MarketingPreferences.tournamentsNewsletter',value);
        } }
        public Boolean eventsNewsletter { get; set{//1.50+
            eventsNewsletter = value;
            propertyCache.put('MarketingPreferences.eventsNewsletter',value);
        } }
        public Boolean brochure { get; set{
            brochure = value;
            propertyCache.put('MarketingPreferences.brochure',value);
        } }
        public Boolean pgaTour { get; set{//1.47+
            pgaTour = value;
            propertyCache.put('MarketingPreferences.pgaTour',value);
        } }
        public String changeReason { get; set{
            changeReason = value;
            propertyCache.put('MarketingPreferences.changeReason',value);
        } }
        public Boolean suppressWelcomeEmail { get; set{//1.40+
            suppressWelcomeEmail = value;
            propertyCache.put('MarketingPreferences.suppressWelcomeEmail',value);
        } }   
        public Map<String,Object> propertyCache = new Map<String,Object>();//1.1+

        public MarketingPreferences(){}

        public MarketingPreferences(EnquiryAPIV1Request.MarketingPreferences marketingPreferences){ 
            if(marketingPreferences == null) marketingPreferences = new EnquiryAPIV1Request.MarketingPreferences();
            //Channels
            this.phone = marketingPreferences.phone;
            this.sms = marketingPreferences.sms;
            this.email = marketingPreferences.email;//1.50+
            this.brochure = marketingPreferences.brochure;

            //Subscriptions
            this.seasonalNewsletter = marketingPreferences.seasonalNewsletter;
            this.weeklyNewsletter = marketingPreferences.weeklyNewsletter;
            this.tournamentsNewsletter = marketingPreferences.tournamentsNewsletter;//1.50+
            this.eventsNewsletter = marketingPreferences.eventsNewsletter;//1.50+

            this.changeReason = marketingPreferences.changeReason;
            this.suppressWelcomeEmail = marketingPreferences.suppressWelcomeEmail;//1.40+
            this.pgaTour = marketingPreferences.pgaTour;//1.47+
        }

        //1.55+
        public MarketingPreferences(ActionTypeRequest__c atr){ 
            if(atr == null) atr = new ActionTypeRequest__c();
            this.sms = atr.SMS__c;
            this.brochure = atr.Brochure__c;
            this.seasonalNewsletter = atr.QuarterlyNewsletter__c;
            this.weeklyNewsletter = atr.WeeklyNewsletter__c;
            //TO DO - Add Email + Phone Channels, Tournaments + Events Newsletters, Marketing Change Reason
        }

        public MarketingPreferences(EnquiryActionInput enquiryActionInput){ 
            //Channel
            this.phone = enquiryActionInput.phone;
            this.sms = enquiryActionInput.sms;
            this.email = enquiryActionInput.subscribedToEmail;//1.50+ 
            this.brochure = enquiryActionInput.brochure;

            //Subscriptions
            this.seasonalNewsletter = enquiryActionInput.seasonalNewsletter;
            this.weeklyNewsletter = enquiryActionInput.weeklyNewsletter;
            this.tournamentsNewsletter = enquiryActionInput.tournamentsNewsletter;//1.51+
            this.eventsNewsletter = enquiryActionInput.eventsNewsletter;//1.51+

            this.changeReason = enquiryActionInput.changeReason;
        }
    }

    public class TrackingInformation {
        public String campaignId {get; set{
            campaignId = value;
            propertyCache.put('TrackingInformation.campaignId',value);
        }}
        public String sessionId { get; set{
            sessionId = value;
            propertyCache.put('TrackingInformation.sessionId',value);
        } }
        public String googleAnalyticsClientId { get; set{
            googleAnalyticsClientId = value;
            propertyCache.put('TrackingInformation.googleAnalyticsClientId',value);
        }}
        public String googleAnalyticsClickId { get; set{
            googleAnalyticsClickId = value;
            propertyCache.put('TrackingInformation.googleAnalyticsClickId',value);
        }}
        public String tealiumId { get; set{//1.37+
            tealiumId = value;
            propertyCache.put('TrackingInformation.tealiumId',value);
        }}
        public String utmSource { get; set{//1.49+
            utmSource = value;
            propertyCache.put('TrackingInformation.utmSource',value);
        }}
        public String utmMedium { get; set{//1.49+
            utmMedium = value;
            propertyCache.put('TrackingInformation.utmMedium',value);
        }}
        public String utmCampaign { get; set{//1.49+
            utmCampaign = value;
            propertyCache.put('TrackingInformation.utmCampaign',value);
        }}
        public String additionalTrackingInformation { get; set{//1.49+
            additionalTrackingInformation = value;
            propertyCache.put('TrackingInformation.additionalTrackingInformation',value);
        }}
        public String utmReferrer { get; set{//1.54+
            utmReferrer = value;
            propertyCache.put('TrackingInformation.utmReferrer',value);
        }}
        public String utmSearchTerm { get; set{//1.54+
            utmSearchTerm = value;
            propertyCache.put('TrackingInformation.utmSearchTerm',value);
        }}

        public Map<String,Object> propertyCache = new Map<String,Object>();//1.1+

        public TrackingInformation(){}

        public TrackingInformation(EnquiryAPIV1Request.TrackingInformation trackingInformation){ 
            if(trackingInformation == null) trackingInformation = new EnquiryAPIV1Request.trackingInformation();  
            //1.4         
            this.campaignId = trackingInformation.campaignId;
            this.sessionId = trackingInformation.sessionId;
            this.googleAnalyticsClientId = trackingInformation.googleAnalyticsClientId;
            this.googleAnalyticsClickId = trackingInformation.googleAnalyticsClickId;
            this.tealiumId = trackingInformation.tealiumId;
            this.utmSource = trackingInformation.utmSource;//1.49+
            this.utmMedium = trackingInformation.utmMedium;//1.49+
            this.utmCampaign = trackingInformation.utmCampaign;//1.49+
            this.additionalTrackingInformation = trackingInformation.additionalTrackingInformation;//1.49+
            this.utmReferrer = trackingInformation.utmReferrer;//1.54+
            this.utmSearchTerm = trackingInformation.utmSearchTerm;//1.54+
        }

        public TrackingInformation(EnquiryActionInput enquiryActionInput){//1.49+ New constructor for passing data to int framework via apex action
            if(enquiryActionInput == null) enquiryActionInput = new EnquiryActionInput();
            this.utmSource = enquiryActionInput.utmSource;//1.49+
            this.utmMedium = enquiryActionInput.utmMedium;//1.49+
            this.utmCampaign = enquiryActionInput.utmCampaign;//1.49+
        }
    }

    //1.14
    public class ClientAddress{
        public Map<String,Object> propertyCache = new Map<String,Object>();
        public String street {get; set{
            street = value;
            propertyCache.put('ClientDetails.clientAddress.street',value);
        }}
        public String city {get; set{
            city = value;
            propertyCache.put('ClientDetails.clientAddress.city',value);
        }}
        public String state {get; set{
            state = value;
            propertyCache.put('ClientDetails.clientAddress.state',value);
        }}
        public String country {get; set{
            country = value;
            propertyCache.put('ClientDetails.clientAddress.country',value);
        }}
        public String postalCode {get; set{
            postalCode = value; 
            propertyCache.put('ClientDetails.clientAddress.postalCode',value);
        }}

        //1.14
        public ClientAddress(EnquiryAPIV1Request.ClientAddress clientAddress){
            if(clientAddress == null) clientAddress = new EnquiryAPIV1Request.ClientAddress();
            this.street = clientAddress.street;
            this.city = clientAddress.city;
            this.state = clientAddress.state;
            this.country = clientAddress.country;
            this.postalCode = clientAddress.postalCode;
        }

        //1.55+
        public ClientAddress(ActionTypeRequest__c atr){
            if(atr == null) atr = new ActionTypeRequest__c();
            this.street = atr.AddressStreet__c;
            this.city = atr.AddressCity__c;
            this.state = atr.AddressStateCounty__c;
            this.country = atr.AddressCountry__c;
            this.postalCode = atr.AddressPostalCode__c;

        }
        
        public ClientAddress(EnquiryActionInput enquiryActionInput){
            if(enquiryActionInput == null) enquiryActionInput = new EnquiryActionInput();
            this.street = enquiryActionInput.street;
            this.city = enquiryActionInput.city;
            this.state = enquiryActionInput.state;
            this.country = enquiryActionInput.country;
            this.postalCode = enquiryActionInput.postalCode;

        }

    }

    //1.47+
    public class CompetitionInformation{
            
        public Map<String,Object> propertyCache = new Map<String,Object>();//1.1+

        public String competitionName {get; set{
            competitionName = value;
            propertyCache.put('CompetitionInformation.competitionName',value);
        }}
        public String customerAnswer {get; set{
            customerAnswer = value;
            propertyCache.put('CompetitionInformation.customerAnswer',value);
        }}

        public CompetitionInformation(){}

        public CompetitionInformation(EnquiryAPIV1Request.CompetitionInformation competitionInformation){
            if(competitionInformation == null) competitionInformation = new EnquiryAPIV1Request.CompetitionInformation();
            this.competitionName = competitionInformation.competitionName;
            this.customerAnswer = competitionInformation.customerAnswer;    
        }

    }
    // End Inner classes.
}