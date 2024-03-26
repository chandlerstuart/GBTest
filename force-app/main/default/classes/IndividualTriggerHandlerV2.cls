/*
Name:  IndividualTriggerHandlerV2.cls
======================================================
======================================================
Purpose:
-------
Handler class for all trigger operations related to the Individual standard object.

======================================================
======================================================
History
------- 
Ver. Author           Date        Detail
1.0  James Radcliffe  14/05/2018  Initial Development.
1.1  James Radcliffe  15/05/2018  Added Request Queue creation to send Newsletter Subscription changes directly from Individual update
1.2  James Radcliffe  18/05/2018  Do not create a RQ record for updates already originating from Clubhouse
1.3  James Radcliffe  22/05/2018  Clear 'Change Reason' fields
1.4  James Radcliffe  22/10/2019  Remove Redundant Activity - IFramework Phase 2
1.5  James Radcliffe  11/02/2020  Disable local triggers from running when setting Individual Id on Account - Improve CPU
2.1  James Radcliffe  06/10/2020  Substantial changes to trigger logic (see below)
2.2  James Radcliffe  08/03/2023  Introduced Email__c Channel and 2 new subscriptions: TournamentsNewsletter__c & EventsNewsletter__c. Consolidated Change Reason fields into a single field: MarketingSubscriptionChangeReason__c (new)
2.3  James Radcliffe  03/04/2023  New method - updateDuplicateIndividualEntities - This method copies the newly updated email marketing preferences to that of clients with a matching email address to ensure their consent/preferences are universally adopted.
2.4  Mark Cane&       21/08/2023  Bug fixes. W-002756. Exception: Id not specified in an update call.
2.5  Chandler Stuart  20/11/2023  Introduced the ability to invoke Integration Framework on the 'After Update' trigger
*/
public class IndividualTriggerHandlerV2 {

    //2.1 (continued) -- New design pattern implemented resulting in the Individual being created prior to Account creation, inclusive of initial Marketing Preferences.
    //Important! - The Individual will no longer be inserted with the Account__c populated - This will be populated when the Account is inserted (via flow). Treat the setting of the Account__c lookup as 'Insert'
    //Remove Insert Trigger Activity (to be handled onUpdate)
    //Add log entries for all Marketing Preferences (Opt Ins)
    //Redirect Error Logging to Platform Log Object
    //Add support for logging PGA Tour to Change History
    
    // statics to prevent recursive behaviour associated with update operations.
    // (via W/F update later in the context sequence or direct in-trigger update or in-direct via roll-up (OLI, OLIS)).
    public static Boolean firstAfterInsertRun = true;  
    public static Boolean firstAfterUpdateRun = true; 

    public static Boolean isDuplicateUpdate = false;//2.3+ Prevent recursive updates
    
    //A method to handle the After Insert trigger activity
    public void onAfterInsert(List<Individual> newList, Map<Id,Individual> newMap){
        
        system.debug('Individual After Insert Start');
        if(firstAfterInsertRun){
            firstAfterInsertRun = false;
        }
        
    }
    
    //A method to handle all After Update trigger activity
    public void onAfterUpdate(List<Individual> oldList, Map<Id,Individual> oldMap, List<Individual> newList, Map<Id,Individual> newMap){
        
        system.debug('Start After Update');
        if(firstAfterUpdateRun){
                try{//2.1~ Moved to cover all Update Trigger Handling activity

                    // Introduced the abiltiy to invoke Integration Framework (2.5+)
                    DataEventTypeTriggerHandler dth = new DataEventTypeTriggerHandler(ApplicationConstant.OBJECT_TYPE_INDIVIDUAL);//2.5+
                    dth.handleTriggerOperationType();//2.5+

                    //2.3+
                    if(!isDuplicateUpdate) updateDuplicateIndividualEntities(oldMap,newMap);
            
                    //Create a Map to store Account Ids and the new Subscription status for the Weekly Newsletter
                    Map<Id,boolean> accountIdToNewsletterSubscription = new Map<Id,boolean>();
                    
                    //Create a List of Change History records to log changes to the preference centre
                    List<Preference_Centre_Change__b> preferenceCentreChangesToInsert = new List<Preference_Centre_Change__b>();
                    Set<Id> triggerIndividualIds = new Set<Id>();
                    
                    //1.1 Create a list of request queue records for syncing newsletter sign up changes to Clubhouse
                    List<Request_Queue__c> lstRequestQueueRecordsToUpdate = new List<Request_Queue__c>();
                    Id requestRQRecordTypeId = ApplicationConstant.getRecordTypeId(ApplicationConstant.OBJECT_TYPE_REQUEST_QUEUE, ApplicationConstant.RECORD_TYPE_REQUEST_QUEUE_REQUEST);
                    Individual oldInd;
                    for(Individual i : newList){
                        triggerIndividualIds.add(i.Id);
                        oldInd = oldMap.get(i.Id);

                        //2.2+ - Store fields in a map with related log messages
                        Map<String,String> fieldNameToLogMessage = new Map<String,String>();
                        fieldNameToLogMessage.put('Email__c',ApplicationConstant.EMAIL_PREFERENCE);
                        fieldNameToLogMessage.put('SMS__c',ApplicationConstant.SMS_PREFERENCE);
                        fieldNameToLogMessage.put('Phone__c',ApplicationConstant.PHONE_PREFERENCE);
                        fieldNameToLogMessage.put('Brochure__c',ApplicationConstant.BROCHURE_PREFERENCE);
                        fieldNameToLogMessage.put('PGATour__c',ApplicationConstant.PGA_TOUR_PREFERENCE);
                        fieldNameToLogMessage.put('Weekly_Newsletter__c',ApplicationConstant.WEEKLY_NEWSLETTER);
                        fieldNameToLogMessage.put('Quarterly_Newsletter__c',ApplicationConstant.QUARTERLY_NEWSLETTER);
                        fieldNameToLogMessage.put('TournamentsNewsletter__c',ApplicationConstant.TOURNAMENTS_NEWSLETTER_PREFERENCE);
                        fieldNameToLogMessage.put('EventsNewsletter__c',ApplicationConstant.EVENTS_NEWSLETTER_PREFERENCE);

                        //2.1+
                        if(oldInd.Account__c == null && i.Account__c != null && i.CreatedDate >= System.now().addMinutes(-5)){//Assume Individual has been newly created (Account is set by a flow on Account Insert) //2.2~ Added Time Check to confirm the record is new and prevent inadvertent logging if the Account is updated at a later date.
                            preferenceCentreChangesToInsert.add(createChangeHistoryEntry(i.Id,i.Account__c,ApplicationConstant.NEW_CLIENT_DEFAULT,null,'false',ApplicationConstant.NEW_CLIENT_OPT_OUT));//Set initial log entry
                            //Add log entries for Opt-in Marketing Preferences

                            //2.2+ - Loop through and log any subscriptions opted in on (pseudo) 'insert'.
                            for(String fieldName : fieldNameToLogMessage.keySet()){
                                if(i.get(fieldName) == true) preferenceCentreChangesToInsert.add(createChangeHistoryEntry(i.Id,i.Account__c,fieldNameToLogMessage.get(fieldName),'false','true',i.MarketingSubscriptionChangeReason__c)); 
                            }
                            
                            /*2.2-
                            //Marketing Channels
                            if(i.SMS__c) preferenceCentreChangesToInsert.add(createChangeHistoryEntry(i.Id,i.Account__c,ApplicationConstant.SMS_PREFERENCE,'false','true',i.SMS_Change_Reason__c));                  
                            if(i.Phone__c) preferenceCentreChangesToInsert.add(createChangeHistoryEntry(i.Id,i.Account__c,ApplicationConstant.PHONE_PREFERENCE,'false','true',i.Phone_Change_Reason__c));              
                            if(i.Brochure__c) preferenceCentreChangesToInsert.add(createChangeHistoryEntry(i.Id,i.Account__c,ApplicationConstant.BROCHURE_PREFERENCE,'false','true',i.Brochure_Change_Reason__c));   
                            if(i.PGATour__c) preferenceCentreChangesToInsert.add(createChangeHistoryEntry(i.Id,i.Account__c,ApplicationConstant.PGA_TOUR_PREFERENCE,'false','true',i.PGA_Tour_Change_Reason__c)); 
                            
                            //Email Subscriptions
                            if(i.Weekly_Newsletter__c) preferenceCentreChangesToInsert.add(createChangeHistoryEntry(i.Id,i.Account__c,ApplicationConstant.WEEKLY_NEWSLETTER,'false','true',i.Weekly_Newsletter_Change_Reason__c));
                            if(i.Quarterly_Newsletter__c) preferenceCentreChangesToInsert.add(createChangeHistoryEntry(i.Id,i.Account__c,ApplicationConstant.QUARTERLY_NEWSLETTER,'false','true',i.Quarterly_Newsletter_Change_Reason__c));       
                            */         
                        }else if(i.Account__c != null){//2.2+
                            for(String fieldName : fieldNameToLogMessage.keySet()){
                                if(i.get(fieldName) != oldInd.get(fieldName)){
                                    preferenceCentreChangesToInsert.add(createChangeHistoryEntry(i.Id,i.Account__c,fieldNameToLogMessage.get(fieldName),string.valueOf(oldInd.get(fieldName)),string.valueOf(i.get(fieldName)),i.MarketingSubscriptionChangeReason__c));                  
                                } 
                            }
                        }

                        //2.2-
                        /*
                        if(i.SMS__c != oldInd.SMS__c && i.Account__c != null){
                            //Add change log entry
                            preferenceCentreChangesToInsert.add(createChangeHistoryEntry(i.Id,i.Account__c,ApplicationConstant.SMS_PREFERENCE,string.valueOf(oldInd.SMS__c),string.valueOf(i.SMS__c),i.SMS_Change_Reason__c));
                        }    
                        if(i.Phone__c != oldInd.Phone__c && i.Account__c != null){
                            //Add change log entry
                            preferenceCentreChangesToInsert.add(createChangeHistoryEntry(i.Id,i.Account__c,ApplicationConstant.PHONE_PREFERENCE,string.valueOf(oldInd.Phone__c),string.valueOf(i.Phone__c),i.Phone_Change_Reason__c));
                        }   
                        if(i.Brochure__c != oldInd.Brochure__c && i.Account__c != null){
                            //Add change log entry
                            preferenceCentreChangesToInsert.add(createChangeHistoryEntry(i.Id,i.Account__c,ApplicationConstant.BROCHURE_PREFERENCE,string.valueOf(oldInd.Brochure__c),string.valueOf(i.Brochure__c),i.Brochure_Change_Reason__c));
                        }          

                        if(i.Weekly_Newsletter__c != oldInd.Weekly_Newsletter__c && i.Account__c != null){ //1.4+
                            //Add change log entry
                            preferenceCentreChangesToInsert.add(createChangeHistoryEntry(i.Id,i.Account__c,ApplicationConstant.WEEKLY_NEWSLETTER,string.valueOf(oldInd.Weekly_Newsletter__c),string.valueOf(i.Weekly_Newsletter__c),i.Weekly_Newsletter_Change_Reason__c)); //1.4+              
                        }
                        if(i.Quarterly_Newsletter__c != oldInd.Quarterly_Newsletter__c && i.Account__c != null){
                            //Add change log entry
                            preferenceCentreChangesToInsert.add(createChangeHistoryEntry(i.Id,i.Account__c,ApplicationConstant.QUARTERLY_NEWSLETTER,string.valueOf(oldInd.Quarterly_Newsletter__c),string.valueOf(i.Quarterly_Newsletter__c),i.Quarterly_Newsletter_Change_Reason__c));
                        }
                        if(i.PGATour__c != oldInd.PGATour__c && i.Account__c != null){//2.1+
                            //Add change log entry
                            preferenceCentreChangesToInsert.add(createChangeHistoryEntry(i.Id,i.Account__c,ApplicationConstant.PGA_TOUR_PREFERENCE,string.valueOf(oldInd.PGATour__c),string.valueOf(i.PGATour__c),i.PGA_Tour_Change_Reason__c));
                        }*/

                    }           
                    
                    //If there have been changes to the preference centre during this transaction, run post preference centre update processor
                    if(preferenceCentreChangesToInsert.size()>0){
                        system.debug('Runnning Post Preference Centre Update Processor');
                        system.enqueueJob(new PostPreferenceCentreUpdateProcessorClass(preferenceCentreChangesToInsert, triggerIndividualIds/*, accountIdToNewsletterSubscription, lstRequestQueueRecordsToUpdate*/));//1.4~
                    }else{
                        //1.3  James Radcliffe  22/05/2018  Clear 'Change Reason' fields even if no updates are made to the preference centre fields
                        List<Individual> indsForUpdate = clearChangeReasonFields(triggerIndividualIds);
                        if(indsForUpdate != null && indsForUpdate.size()>0){
                                update indsForUpdate;
                        }
                    }
                }catch(exception e){
                    PlatformLogManager.logExceptions(e, 'IndividualTriggerHandlerV2', 'onAfterUpdate');//2.1+              
                }
            firstAfterUpdateRun = false;
        }
    } 
    
    //This Class handles the asynchronous processing of Individual Records following an update to the Preference Centre
    public class PostPreferenceCentreUpdateProcessorClass implements Queueable{
        
        public List<Preference_Centre_Change__b> preferenceCentreChangesToInsert;
        public Set<Id> triggerIndividualIds;
        //Map<Id,Boolean> accountIdToNewsletterSubscription; //1.4-
        //List<Request_Queue__c> requestQueueList; ////1.4-
        
        
        public PostPreferenceCentreUpdateProcessorClass(List<Preference_Centre_Change__b> inChangeHistory, Set<Id> inTriggerIndividualIds /*1.4- Map<Id,Boolean> inAccountIdToNewsletterSubscription, List<Request_Queue__c> inRequestQueueList*/){
            this.preferenceCentreChangesToInsert = inChangeHistory;
            this.triggerIndividualIds = inTriggerIndividualIds; 
        }
        
        public void execute(QueueableContext context){           
            
            //1. LOG PREFERENCE CENTRE CHANGES
            if(preferenceCentreChangesToInsert != null && !preferenceCentreChangesToInsert.isEmpty()){
                system.debug('Logging Preference Centre Changes');
                try{
                    system.debug('executing Change History Insert for: '+preferenceCentreChangesToInsert.size()+'records');    
                    //Big Objects are not supported by the standard testing framework without introducing a custom Mock framework. 
                    //Excluding insert from Test context. See solution summary in S485 for details
                    if(!Test.isRunningTest()){
                        //Insert Change History Log Entries
                        Database.SaveResult[] sr = database.insertImmediate(preferenceCentreChangesToInsert);
                        Golfbreaks.PlatformLogManager.logExceptions(sr,'IndividualTriggerHandlerV2','execute',preferenceCentreChangesToInsert);
                    }
                }catch(exception e){
                    //Create logs for any errors
                    PlatformLogManager.logExceptions(e, 'PostPreferenceCentreUpdateProcessorClass', 'execute');    
                    //logs.add(ApplicationConstant.getExceptionLog(e,'logPreferenceCentreChanges',CLASS_NAME,null));  //2.1-             
                }
            }
                        
            //2. CLEAR PREFERENCE CENTRE CHANGE REASON
            if(triggerIndividualIds != null && triggerIndividualIds.size()>0){
                system.debug('Clearing Change Reason Field Values');
                //Clear Change Reason Fields
                List<Individual> individualsForUpdate = clearChangeReasonFields(triggerIndividualIds);
                if(individualsForUpdate.size()>0){
                    try{
                        update individualsForUpdate;
                    }catch(exception e){
                        PlatformLogManager.logExceptions(e, 'PostPreferenceCentreUpdateProcessorClass', 'execute');    
                    }
                }
            }           
        }
    }
        
    //This method returns a list of Individual records which require the clearing of one or more change reason fields
    public static List<Individual> clearChangeReasonFields(Set<Id> triggerIndividualIds){
        
        //Create a list of Individuals to Update
        List<Individual> individualsToUpdate = new List<Individual>();
        
        //for(Individual i : [Select Id, Weekly_Newsletter_Change_Reason__c, SMS_Change_Reason__c, Phone_Change_Reason__c, Brochure_Change_Reason__c, Quarterly_Newsletter_Change_Reason__c , PGA_Tour_Change_Reason__c  From Individual Where Id In:triggerIndividualIds]){//2.2-
        for(Individual i : [Select Id, MarketingSubscriptionChangeReason__c From Individual Where Id In:triggerIndividualIds]){//2.2+
            
            //2.2+
            if(i.MarketingSubscriptionChangeReason__c != null){
                i.MarketingSubscriptionChangeReason__c = null;
                individualsToUpdate.add(i);
            }

            /*2.2-
            //Only update Individuals where the Change Reason is populated
            //Flag to ensure only records that need to be updated are added to the update list
            boolean requiresUpdate = false;

            if(i.Weekly_Newsletter_Change_Reason__c != null){
                i.Weekly_Newsletter_Change_Reason__c = null;
                requiresUpdate = true;
            }
            if(i.SMS_Change_Reason__c != null){
                i.SMS_Change_Reason__c = null;
                requiresUpdate = true;
            }
            if(i.Phone_Change_Reason__c != null){
                i.Phone_Change_Reason__c = null;
                requiresUpdate = true;
            }
            if(i.Brochure_Change_Reason__c != null){
                i.Brochure_Change_Reason__c = null;
                requiresUpdate = true;
            }
            if(i.Quarterly_Newsletter_Change_Reason__c != null){
                i.Quarterly_Newsletter_Change_Reason__c = null;
                requiresUpdate = true;
            } 
            if(i.PGA_Tour_Change_Reason__c != null){//2.1+
                i.PGA_Tour_Change_Reason__c = null;
                requiresUpdate = true;
            } 
            if(requiresUpdate){
                individualsToUpdate.add(i);
                system.debug('change reason update required');
            }*/            
        }            
        
        return individualsToUpdate;
        
    }             
    
    //A method to generate and return a new Preference Centre Change History entry
    public static Preference_Centre_Change__b createChangeHistoryEntry(Id individualId, Id personAccountId, String preference, String oldValue, String newValue, String detail){
        
        Preference_Centre_Change__b pcch = new Preference_Centre_Change__b();
        pcch.Date__c = system.now();
        pcch.Individual__c = individualId;
        pcch.Account__c = personAccountId;
        pcch.Old_Value__c = oldValue;
        pcch.New_Value__c = newValue;
        pcch.Detail__c = detail;
        pcch.Preference__c = preference;
        
        return pcch;
    }

    //2.3+ This method copies the newly updated email marketing preferences to that of clients with a matching email address, to ensure the consent/preferences are universally adopted.
    public static void updateDuplicateIndividualEntities(Map<Id,Individual> oldMap, Map<Id,Individual> newMap){
        try{
            
            //Store the individual records that have had changes to their email preferences
            Map<Id,Individual> idsToEmailChangeIndividualsMap = new Map<Id,Individual>();
            //Store the most recent individual details for a given email address
            Map<String,Individual> emailAddressesToIndividualsMap = new Map<String,Individual>();

            //Evaluate records
            for(Individual newInd : newMap.values()){
                //Exclude records that cannot be processed
                if(newInd.Account__c == null || newInd.EmailAddress__c == null) continue;//Cannot identify dupes without client/email
                if(!newInd.IsPrimary__c) continue;//Only changes to the primary individual record should be included
                //Identify email preference status changes
                Individual oldInd = oldMap.get(newInd.Id);
                if(newInd.Email__c != oldInd.Email__c
                || newInd.Quarterly_Newsletter__c != oldInd.Quarterly_Newsletter__c
                || newInd.Weekly_Newsletter__c != oldInd.Weekly_Newsletter__c
                || newInd.TournamentsNewsletter__c != oldInd.TournamentsNewsletter__c
                || newInd.EventsNewsletter__c != oldInd.EventsNewsletter__c){
                    system.debug('change detected');
                    //Store details
                    idsToEmailChangeIndividualsMap.put(newInd.Id,newInd);
                    emailAddressesToIndividualsMap.put(newInd.EmailAddress__c,newInd);
                }
            }
            
            if(emailAddressesToIndividualsMap.values().size()>0){
                //Query for clients with a matching email address that haven't had their preferences changed already (excl updated individual records)
                List<Individual> individualsForUpdate = new List<Individual>();
                List<Account> duplicateAccounts = [Select Id, PersonEmail, PersonIndividualId From Account Where PersonEmail In:emailAddressesToIndividualsMap.keySet() and (NOT PersonIndividualId In:idsToEmailChangeIndividualsMap.keySet()) and PersonIndividualId<>null];//2.4~
                if(duplicateAccounts.size()>0){
                    for(Account acc : duplicateAccounts){
                        //Retrieve the updated preferences
                        Individual newPrefs = emailAddressesToIndividualsMap.get(acc.PersonEmail);

                        //Copy email preference details to primary individual record for the duplicate account
                        individualsForUpdate.add(new Individual(
                            Id=acc.PersonIndividualId,//Assign Id (for update)
                            Email__c = newPrefs.Email__c,
                            Weekly_Newsletter__c = newPrefs.Weekly_Newsletter__c,
                            Quarterly_Newsletter__c = newPrefs.Quarterly_Newsletter__c,
                            TournamentsNewsletter__c = newPrefs.TournamentsNewsletter__c,
                            EventsNewsletter__c = newPrefs.EventsNewsletter__c,
                            MarketingSubscriptionChangeReason__c = newPrefs.MarketingSubscriptionChangeReason__c//Copy original reason for change logging
                        ));
                        
                    }
                    if(individualsForUpdate.size()>0){

                        system.debug('Copying Email Status Changes to '+individualsForUpdate.size()+' individual records');
                        
                        //Cache static flags before change
                        Boolean isFirstAfterUpdateBeforeExecution = firstAfterUpdateRun;
                        firstAfterUpdateRun = true;//Treat the duplicate update as the first update.
                        isDuplicateUpdate = true;//Prevent recursive updates
                        
                        Database.SaveResult[] results = Database.update(individualsForUpdate,false);//all or none = false 
                        Golfbreaks.PlatformLogManager.logExceptions(results,'IndividualTriggerHandlerV2','updateDuplicateIndividualEntities',individualsForUpdate);

                        isDuplicateUpdate = false;//Release static variable once complete
                        //Restore static flags after update
                        firstAfterUpdateRun = isFirstAfterUpdateBeforeExecution;
                    }
                }
            }
        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'IndividualTriggerHandlerV2','updateDuplicateIndividualEntities');
        }
    }
    
}