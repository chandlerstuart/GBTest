/**
* @author -         Abrar Haq (Accenture)
* @date -           01/04/2016
* @description -    Trigger handler for Account object. 
* #############Change Log#############
* Modified by     Version     Change Date
* S.Molloy        2.0         27/06/2017  Added BeforeUpdate method to update Notification Fields
* S.Molloy        2.1         13/07/2017  Added new AfterInsert & AfterUpdate methods to call out and send Breakpoints Invite
* J.Radcliffe     2.2         21/05/2018  Adding setWeeklyNewsletterOnIndividual method after update. Changes to the Newsletter field (from Clubhouse) should be replicated to the master (Weekly_Newsletter__c)
* M.Cane          2.3         21/06/2018  runRequestQueueBatchProcess changes to ensure 1 RQ record per-Account per update (not 1 RQ per field change) 
* J.Radcliffe     2.4         13/08/2018  Adding 'PGA Pro' as an acceptable record type for the Request Queue sync
* J.Radcliffe     2.5         19/09/2018  Disable WIRE triggers on Before Triggers
* M.Cane          2.6         30/09/2018  Update to restore prior state of WIRE triggers on Before Triggers.
* J.Radcliffe     2.7         16/10/2019  Block Duplicate Emails
* J.Radcliffe     2.8         17/10/2019  Invoke Data Event Handler
* J.Radcliffe     2.9         17/10/2019  Comment Out Redundant Code - IFramework Phase 2
* J.Radcliffe     2.10        31/10/2019  Support for merging Marketing Preferences post Client Merge
* M.Cane          2.11        13/11/2019  Recursion guards extended to support partial processing dml operations (insert and update only).
* J Radcliffe     2.12        04/11/2020  Format Person Accounts on Insert & Update + Error Logging
* J Radcliffe     2.13        31/05/2023  Invoke the integration framework after insert.
* J Radcliffe     2.14        04/06/2023  Added BeforeDelete method, invoking Bond Holder validation.
* J Radcliffe     2.15        13/02/2024  Invoke assignPublicId method (GUID Generator) - Create a PublicId__c before insert.
**/
public with sharing class AP01_AccountTriggerHandler {
    
    //recursion flags Added By Dee June 4 -- Based on Code Review
    public static Boolean isBeforeInsertTriggerCalled = FALSE;//2.11+
    public static Boolean isAfterInsertTriggerCalled = FALSE;
    public static Boolean isBeforeUpdateTriggerCalled = FALSE;
    public static Boolean isAfterUpdateTriggerCalled = FALSE;
    
    @testVisible private static Integer triggerSize=0;//2.11+
    
    public void OnBeforeInsert(Account[] insertedlstAccounts){//2.11+

        try{
            if (!isBeforeInsertTriggerCalled){
                
                AP01_AccountTriggerBL.formatAccountData(insertedlstAccounts);//2.12+
                GUIDGenerator.assignPublicId(insertedlstAccounts);//2.15+ 

                triggerSize = Trigger.new.size();//2.11+ -- set in the first Before phase only, errored records are removed before the After phase.
                
                isBeforeInsertTriggerCalled = TRUE;
            }
        }catch(Exception e){//2.12+
            Golfbreaks.PlatformLogManager.logExceptions(e,'AP01_AccountTriggerHandler','OnBeforeInsert');
        }
    }
    
    //Trigger After Insert context
    //2017-07-14 : SM : COMMENTED OUT FOR PHASE 1
    
    public void OnAfterInsert(Account[] insertedlstAccounts, Map<Id, Account> insertedMapAccounts, Map<Id, Account> oldMapAccounts){
            
        if (!isAfterInsertTriggerCalled || (isAfterInsertTriggerCalled && (Trigger.new.size()!=triggerSize))){//2.11~                   
            //if (updatedlstAccounts.size() == 1){
                //sendBreakpointsInvite(updatedlstAccounts,null);
            //}

            AP01_AccountTriggerBL.blockDuplicateEmails();//2.7+

            DataEventTypeTriggerHandler dth = new DataEventTypeTriggerHandler(ApplicationConstant.OBJECT_TYPE_ACCOUNT);//2.13+
            dth.handleTriggerOperationType();//2.13+

            if(isAfterInsertTriggerCalled) triggerSize = Trigger.new.size();//2.11~
            isAfterInsertTriggerCalled = TRUE;
        }
    }
    

    //Trigger Before Update context
    public void OnBeforeUpdate(Account[] updatedlstAccounts, Map<Id, Account> updatedMapAccounts, Map<Id, Account> oldMapAccounts){
        
        //2.5 - Disable WIRE triggers on Before Triggers
        Boolean wireTriggerState = GBWire.WorkItemTriggerHandler.disableWIRETriggers;//2.6
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = true;
       
        if (!isBeforeUpdateTriggerCalled) triggerSize = Trigger.new.size();//2.11+ -- set in the first before phase only, errored records are removed before the After phase.
        
        if (!isBeforeUpdateTriggerCalled || (isBeforeUpdateTriggerCalled && (Trigger.new.size()!=triggerSize))){//2.11~  
            
            List<Account> accsToFormat = new List<Account>();//2.12+
        
            //If the Notification Message has changed, update the audit fields to who changed it, and when
            for (Account a : updatedlstAccounts){
                Account oldAccount = oldMapAccounts.get(a.Id);
                if (a.Notification_Message__c != oldAccount.Notification_Message__c &&
                    (a.Notification_Message__c != null || !String.isBlank(a.Notification_Message__c))){
                        a.Notification_Message_Author__c = UserInfo.getUserId();
                        a.Notification_Message_Created__c = system.now();
                }else if (a.Notification_Message__c != oldAccount.Notification_Message__c &&
                    (a.Notification_Message__c == null || String.isBlank(a.Notification_Message__c))){
                        a.Notification_Message_Author__c = null;
                        a.Notification_Message_Created__c = null;
                }
                if(a.isPersonAccount && a.FirstName != null && (oldAccount.FirstName == null || !a.FirstName.equals(oldAccount.FirstName))) accsToFormat.add(a);//2.12+
                else if(a.isPersonAccount && a.LastName != null && (oldAccount.LastName == null || !a.LastName.equals(oldAccount.LastName))) accsToFormat.add(a);//2.12+
            }
            system.debug('(accsToFormat.size()>0):'+(accsToFormat.size()>0));
            if(accsToFormat.size()>0) AP01_AccountTriggerBL.formatAccountData(accsToFormat);//2.12+
            
            isBeforeUpdateTriggerCalled = TRUE;
        }        
        GBWire.WorkItemTriggerHandler.disableWIRETriggers = wireTriggerState;//2.5,2.6        
    }
    
    // Trigger After Update context
    public void OnAfterUpdate(Account[] updatedlstAccounts, Map<Id, Account> updatedMapAccounts, Map<Id, Account> oldMapAccounts){
        
        //J.Radcliffe 2.2 New Map to store the AccountIds with updated NewsletterSignUp status
       // Map<Id,Boolean> accountsWithNewsletterSignUpStatus = new Map<Id,Boolean>();     //2.9-
        
        if(!isAfterUpdateTriggerCalled || (isAfterUpdateTriggerCalled && (Trigger.new.size()!=triggerSize))){//2.11~                   
            
            AP01_AccountTriggerBL.blockDuplicateEmails();//2.7+

            //Loop through updated Accounts
            /*2.9-
            for(Account a : updatedMapAccounts.Values()){
                //If the NewsletterSignUp field has been updated, sync changes to Weekly Newsletter field on Individual record
                if(a.NewsletterSignUp__c != oldMapAccounts.get(a.Id).NewsletterSignUp__c){
                    accountsWithNewsletterSignUpStatus.put(a.Id,a.NewsletterSignUp__c);
                }
            }*/
            /*2.9-
            QueueId__c apiId = QueueId__c.getOrgDefaults();
            if(UserInfo.getUserId() != apiId.User_Id__c){
                system.debug('***USER ID = ' + apiId.User_Id__c + ' >> ' + UserInfo.getUserId());
                system.debug('***updatedlstAccounts = ' + updatedlstAccounts);
                system.debug('***oldMapAccounts = ' + oldMapAccounts);
                runRequestQueueBatchProcess(updatedlstAccounts, oldMapAccounts);
            }*/
            //2017-07-14 : SM : COMMENTED OUT FOR PHASE 1
            /*
            if (updatedlstAccounts.size() == 1){
                sendBreakpointsInvite(updatedlstAccounts,oldMapAccounts);
                isAfterUpdateTriggerCalled = TRUE;
            }
            */
            
            /*if(accountsWithNewsletterSignUpStatus != null && accountsWithNewsletterSignUpStatus.keySet().size()>0){ //2.9-
                //Update the Individual records Weekly_Newsletter__c field with new value
                setWeeklyNewsletterOnIndividual(accountsWithNewsletterSignUpStatus);
            }*/

            if(isAfterUpdateTriggerCalled) triggerSize = Trigger.new.size();//2.11~

            isAfterUpdateTriggerCalled = true;                
        }

        DataEventTypeTriggerHandler dth = new DataEventTypeTriggerHandler(ApplicationConstant.OBJECT_TYPE_ACCOUNT);//2.8+
        dth.handleTriggerOperationType();//2.8+
    }

    public void OnAfterDelete(List<Account> oldList){
        DataEventTypeTriggerHandler dth = new DataEventTypeTriggerHandler(ApplicationConstant.OBJECT_TYPE_ACCOUNT);//2.8+
        dth.handleTriggerOperationType();//2.8+
        AP01_AccountTriggerBL.mergeMarketingPreferences(oldList);//2.10+
    }

    // 2.14 Trigger Before Delete context
    public void OnBeforeDelete(List<Account> accountsToDelete){
        AP01_AccountTriggerBL.verifyAccountDeletionPermissions(accountsToDelete);//Confirm the user has permission to delete the records.
    }
    

    /*************************************************************************************** 
    Developer -    Simon Molloy
    Date -         13/07/2017
    Version -      1.0 
    Function -     Send Email Invitation to Breakpoints in an @future method
    This logic runs only on a single Person Account
    #############Change Log#############
    Modified by     Version     Change Date
    Simon M.        1.0         2017-07-14  -  COMMENTED OUT FOR PHASE 1
    ****************************************************************************************/
    /*
    public void sendBreakpointsInvite(List<Account> updatedlstAccounts, Map<Id, Account> oldMapAccounts){
        if (null == oldMapAccounts){
            if (updatedlstAccounts[0].Send_Breakpoints_Invite__c){
                WS01_RebarHTTPCallout.emailBreakpointsInviteFuture(String.valueOf(updatedlstAccounts[0].Id));
            }
        }else {
            Account oldAccount = oldMapAccounts.get(updatedlstAccounts[0].Id);
            if (updatedlstAccounts[0].Send_Breakpoints_Invite__c && !oldAccount.Send_Breakpoints_Invite__c){
                WS01_RebarHTTPCallout.emailBreakpointsInviteFuture(String.valueOf(updatedlstAccounts[0].Id));
            }
        }
    }
    */
    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         01/04/2016
    Version -      1.0 
    Function -     Run Batch Process to process Request Queue records
    This logic runs only on Person Account records
    #############Change Log#############
    Modified by     Version     Change Date
    * M.Cane        2.3         21/06/2018  Changes to ensure 1 RQ record per-Account per update (not 1 RQ per field change).
    ****************************************************************************************/
    /*2.9
    public void runRequestQueueBatchProcess(List<Account> lstUpdatedAccounts, Map<Id, Account> mapUpdatedAccounts){
        //List<Account> lstAccountsToCreateRequestQueueRecords = new List<Account>();//2.3       
        Map<Id, Account> idToAccountToCreateRequestQueueRecords = new Map<Id, Account>();//2.3
        
        if( lstUpdatedAccounts.size() > 0 ){
            // Request Queue record type : Request
            Id recordTypeAccountClienttId = ApplicationConstant.getRecordTypeId( ApplicationConstant.OBJECT_TYPE_ACCOUNT, ApplicationConstant.RECORD_TYPE_ACCOUNT_CLIENT );
            Id recordTypeAccountPGAProId = ApplicationConstant.getRecordTypeId(ApplicationConstant.OBJECT_TYPE_ACCOUNT, ApplicationConstant.RECORD_TYPE_ACCOUNT_PGA_PRO);//2.4

            Set<String> setObjectFields = new Set<String>();
            Id recordId = (Id) lstUpdatedAccounts[0].Id;

            // Get the Object Type
            Schema.SObjectType objectType = recordId.getSobjectType();
            // Get the Object Fields to check 
            setObjectFields = ApplicationConstant.getObjectFields( String.ValueOf(objectType) );

            for(Account accountRecord : lstUpdatedAccounts){

                if( accountRecord.IsPersonAccount && (accountRecord.RecordTypeId == recordTypeAccountClienttId  || accountRecord.RecordTypeId == recordTypeAccountPGAProId)){
                    Account oldAccount = mapUpdatedAccounts.get(accountRecord.Id);
    
                    // First check fields whether either of them has updated or not? using a custom setting "Object Field Mapping"
                    for(String fieldAPIName : setObjectFields){
                        if( accountRecord.get(fieldAPIName) <> oldAccount.get(fieldAPIName) ){
                            
                            if (!idToAccountToCreateRequestQueueRecords.containsKey(accountRecord.Id)){//2.3
                                idToAccountToCreateRequestQueueRecords.put(accountRecord.Id, accountRecord);//2.3
                                continue;//2.3-next account.
                            }
                            //lstAccountsToCreateRequestQueueRecords.add(accountRecord);//2.3
                        }
                    }
                }
            }
            
            //if( lstAccountsToCreateRequestQueueRecords.size() > 0 ){//2.3
            if( !idToAccountToCreateRequestQueueRecords.isEmpty() ){//2.3
                //RequestQueueUtility.populateRequestQueueRecords(lstAccountsToCreateRequestQueueRecords);//2.3
                RequestQueueUtility.populateRequestQueueRecords(idToAccountToCreateRequestQueueRecords.values());//2.3                
            }
        }
    }*/
    
    /*************************************************************************************** 
    Developer -    James Radcliffe
    Date -         21/05/2018
    Version -      1.0 
    Function -     Sets the Weekly Newsletter flag on the Individual record when the Newsletter Sign Up field is changed
    This logic runs only on Person Account records
    2.2 - Adding setWeeklyNewsletterOnIndividual method after update
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/    
    /* 2.9
    public static void setWeeklyNewsletterOnIndividual(Map<Id,Boolean> accountsWithNewsletterSignUpStatus){
        
        List<Individual> individualsForUpdate = new List<Individual>();
        
        //List of logs for error logging
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        
        //Query Individual records for corresponding Accounts
        Individual [] individuals = [Select Id, Account__c, Weekly_Newsletter__c, Weekly_Newsletter_Change_Reason__c From Individual Where Account__c In :accountsWithNewsletterSignUpStatus.keySet()];
        
        for(Individual i:individuals){
            //Only update the record is the Weekly Newsletter does not match the NewsletterSignUp field value
            if(i.Weekly_Newsletter__c != accountsWithNewsletterSignUpStatus.get(i.Account__c)){
                //Set Weekly Newsletter to new value
                i.Weekly_Newsletter__c = accountsWithNewsletterSignUpStatus.get(i.Account__c);
                //The Newsletter Sign Up field will/should only be modified by the Clubhouse Integration
                i.Weekly_Newsletter_Change_Reason__c = 'Account | '+i.Account__c+' | Clubhouse Newsletter Update';
                individualsForUpdate.add(i);
            }
        }
        
        if(individualsForUpdate != null && individualsForUpdate.size()>0){
            try{
                update individualsForUpdate;
            }catch(exception e){
                //Create logs for any errors
                errorLogs.add(ApplicationConstant.getExceptionLog(e,'setWeeklyNewsletterOnIndividual','AP01_AccountTriggerHandler',null));     
            }finally{
                if(!errorLogs.isEmpty()){
                    //Insert error logs
                    database.insert(errorLogs, false);
                }
            }
        }
        
    }*/
    
}