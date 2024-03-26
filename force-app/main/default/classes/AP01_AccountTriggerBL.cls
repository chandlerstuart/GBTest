/**
* @author -         
* @date -           16-10-19
* @description -    Trigger Business Logic Class for Account Object. 
* #############Change Log#############
* Modified by     Version     Change Date   Detail
* J.Radcliffe     1.0         16-10-19      Initial Development
* J.Radcliffe     1.1         06-07-20      Strengthening dupe check (case-sensitivity TestEmail@example.com == testemail@example.com) & limiting check to Client & PGA Record Types
* J.Radcliffe     1.2         04-11-2020    New method: formatAccountData
* J.Radcliffe     1.3         04-06-2023    New method: verifyAccountDeletionPermissions - Confirm the user has permission to delete the trigger records
**/
public without sharing class AP01_AccountTriggerBL {

    @TestVisible public static Boolean allowDupes = false;
    
    //This method ensures no two Accounts have a matching email
    public static void blockDuplicateEmails(){

        if(Test.isRunningTest() && allowDupes == true) return;

        Set<String> setEmailID = new set<String>();
	    Set<Id> setAccID = new set<ID>();
        Map<Id,Account> oldMap = new Map<Id,Account>();
        if(System.Trigger.isUpdate) oldMap = (Map<Id,Account>)System.Trigger.oldMap;
        for (Account acc : (List<Account>)System.Trigger.new){
            //Only evaluate on insert and email update
            if ((acc.PersonEmail != null) &&  (System.Trigger.isInsert ||  (acc.PersonEmail != oldMap.get(acc.Id).PersonEmail))){
			    setEmailID.add(acc.PersonEmail);
			    setAccID.add(acc.id);
		    }
        }

        Set<Id> recordTypeIds = new Set<Id>{ApplicationConstant.ACC_RECTYPEID_CLIENT,ApplicationConstant.ACC_RECTYPEID_PGA_PRO};//1.1+

        List<Account> accList = [select Id , PersonEmail from Account where PersonEmail in :setEmailID and Id not in :setAccID and RecordTypeId In :recordTypeIds];//1.1~ 
        
        //Store the emails of the existing Accounts
        Map<String, Account> acctMap = new Map<String, Account>();

        for(Account acc : accList){
            acctMap.put(acc.PersonEmail.toLowerCase(), acc);//1.1~ (.toLowerCase())
        }	

        //Store the emails of the trigger records
        Set<String> triggerListEmails = new Set<String>();

        for (Account acc : (List<Account>)System.Trigger.new){
            if ((acc.PersonEmail != null) &&  (System.Trigger.isInsert ||  (acc.PersonEmail != oldMap.get(acc.Id).PersonEmail)) && recordTypeIds.contains(acc.RecordTypeId)){//1.1~ (recordTypeIds check)
                //Validate against existing client database
                if(acctMap.containsKey(acc.PersonEmail.toLowerCase())){//1.1~ (.toLowerCase())
                    acc.PersonEmail.addError(Label.Account_Trigger_Matching_Email_Alert_Message_Existing_Client);
                //Validate against records in the Trigger List
                }else if(triggerListEmails.contains(acc.PersonEmail)){
                    acc.PersonEmail.addError(Label.Account_Trigger_Matching_Email_Alert_Message_Trigger_List);
                }else{
                    triggerListEmails.add(acc.PersonEmail);
                }
            }	
        }	
    }

    //This method faciliates the merging or clearing of Marketing Preferences following a client merge
    public static void mergeMarketingPreferences(List<Account> deletedAccounts){

        Set<Id> masterRecordIds = new Set<Id>();
        Map<Id,Individual> masterRecordWithIndividual = new Map<Id,Individual>();
        Map<Id,Individual> masterRecordWithIndividualToCopy = new Map<Id,Individual>();
        Set<Id> masterRecordsNeverAudited = new Set<Id>();

        //Isolate the master record Id for merged Accounts
        for(Account acc : deletedAccounts){
            //Store the Ids of winning accounts (following a merge)
            if(acc.MasterRecordId != null && !masterRecordIds.contains(acc.MasterRecordId)) masterRecordIds.add(acc.MasterRecordId);
        }

        if(masterRecordIds.size()==0) return;
        //Re-Query Master Account Records with related Individuals
        //Note - On client merge all child Individuals will be transferred to the winning client. All should be retrieved, sorted by last audited
        for(Account acc : [Select Id, PersonIndividualId, (Select Id, Weekly_Newsletter__c, Weekly_Newsletter_Change_Reason__c, SMS__c, SMS_Change_Reason__c, Brochure__c, Brochure_Change_Reason__c, Phone__c, Phone_Change_Reason__c, Quarterly_Newsletter__c, Quarterly_Newsletter_Change_Reason__c, Data_Audit_Last_Completed__c, Email__c, MarketingSubscriptionChangeReason__c From Individuals__r order by Data_Audit_Last_Completed__c Desc Nulls Last ) From Account Where Id in :masterRecordIds]){
            if(acc.PersonIndividualId == null || acc.Individuals__r.size()==0) continue;//unable to take action
            //Store the master record id with it's active individual record (for update)
            for(Individual i : acc.Individuals__r){
                if(acc.PersonIndividualId == i.Id && !masterRecordWithIndividual.containsKey(acc.Id)){
                    masterRecordWithIndividual.put(acc.Id,i);
                    break;
                } 
            }
            //The query will ensure the last audited are at the top. If there is no audit date for the 1st record, add to the never audited set - (Requires clearing)
            if(acc.Individuals__r[0].Data_Audit_Last_Completed__c == null){
                masterRecordsNeverAudited.add(acc.Id);
            }else{
                //Else the last audit details (preferences) should be copied to the active individual record
                masterRecordWithIndividualToCopy.put(acc.Id,acc.Individuals__r[0]);
            }       
        }

        if(masterRecordWithIndividual.keySet().size()==0) return;

        List<Individual> indsToUpdate = new List<Individual>();
        for(Id accId : masterRecordWithIndividual.keySet()){
            //If the client has never been audited, clear all preferences and audit date
            if(masterRecordsNeverAudited.contains(accId) && masterRecordWithIndividual.get(accId) != null){
                indsToUpdate.add(clearMarketingPreferences(masterRecordWithIndividual.get(accId)));
                continue;
            }else if(masterRecordWithIndividualToCopy.containsKey(accId) && masterRecordWithIndividual.get(accId) != null){
                indsToUpdate.add(copyMarketingPreferences(masterRecordWithIndividual.get(accId),masterRecordWithIndividualToCopy.get(accId)));
            }
        }

        if(indsToUpdate.size()>0){
            Database.SaveResult[] results = database.update(indsToUpdate,false);
            PlatformLogManager.logExceptions(results, 'AP01_AccountTriggerBL', 'mergeMarketingPreferences', indsToUpdate);
        }

    }

    public static Individual clearMarketingPreferences(Individual ind){
        
        ind.Brochure__c = false;
        //ind.Brochure_Change_Reason__c = ApplicationConstant.CLIENT_MERGE_NEVER_AUDITED;
        ind.Phone__c = false;
        //ind.Phone_Change_Reason__c = ApplicationConstant.CLIENT_MERGE_NEVER_AUDITED;
        ind.SMS__c = false;
        //ind.SMS_Change_Reason__c = ApplicationConstant.CLIENT_MERGE_NEVER_AUDITED;
        ind.Weekly_Newsletter__c = false;
        //ind.Weekly_Newsletter_Change_Reason__c = ApplicationConstant.CLIENT_MERGE_NEVER_AUDITED;
        ind.Quarterly_Newsletter__c = false;
        //ind.Quarterly_Newsletter_Change_Reason__c = ApplicationConstant.CLIENT_MERGE_NEVER_AUDITED;
        ind.MarketingSubscriptionChangeReason__c = ApplicationConstant.CLIENT_MERGE_NEVER_AUDITED;
        ind.Email__c = false;
        ind.Data_Audit_Last_Completed__c = null;
        
        return ind;
    }

    public static Individual copyMarketingPreferences(Individual ind, Individual copyInd){
        if(copyInd == null) return ind;
        
        ind.Brochure__c = copyInd.Brochure__c;
        //ind.Brochure_Change_Reason__c = ApplicationConstant.CLIENT_MERGE_LAST_AUDIT;
        ind.Phone__c = copyInd.Phone__c;
        //ind.Phone_Change_Reason__c = ApplicationConstant.CLIENT_MERGE_LAST_AUDIT;
        ind.SMS__c = copyInd.SMS__c;
        //ind.SMS_Change_Reason__c = ApplicationConstant.CLIENT_MERGE_LAST_AUDIT;
        ind.Weekly_Newsletter__c = copyInd.Weekly_Newsletter__c;
        //ind.Weekly_Newsletter_Change_Reason__c = ApplicationConstant.CLIENT_MERGE_LAST_AUDIT;
        ind.Quarterly_Newsletter__c = copyInd.Quarterly_Newsletter__c;
        //ind.Quarterly_Newsletter_Change_Reason__c = ApplicationConstant.CLIENT_MERGE_LAST_AUDIT;
        ind.Email__c = copyInd.Email__c;
        ind.MarketingSubscriptionChangeReason__c = ApplicationConstant.CLIENT_MERGE_LAST_AUDIT;
        ind.Data_Audit_Last_Completed__c = null;//Clear the last audit date so the agents follow up when they next make contact

        return ind;
    }

    //1.2+ Format Trigger Account Records (e.g convert Person Accounts Initials to Upper Case)
    public static List<Account> formatAccountData(List<Account> accs){
        for(Account acc : accs){
            if(acc.IsPersonAccount){
                if(acc.FirstName != null) acc.FirstName = acc.FirstName.substring(0,1).toUpperCase()+acc.FirstName.substring(1,acc.FirstName.length());
                if(acc.LastName != null && !isInternationalFormat(acc.LastName)) acc.LastName = acc.LastName.substring(0,1).toUpperCase()+acc.LastName.substring(1,acc.LastName.length());
            }
        }
        return accs;
    }

    public static boolean isInternationalFormat(String surname){
        if(surname == null || surname.length()<3) return false;
        String substring = surname.substring(0,3);
        if(substring.startsWith('d\'')) return true;
        if(substring == 'la ') return true;
        if(substring == 'de ') return true;
        if(substring == 'do ') return true;
        if(substring == 'le ') return true;
        return false;
    }

    //1.3 Confirm the user has permission to delete the trigger records
    //Design note - Initially attempted this with record trigger flow + apex action (a declarative solution for all custom permission validation), but addError isn't applied to record. 
    //Presumably this is because the record passed into the apex action ({!Record}) is not the original trigger record (i.e. from trigger.new/old). Resorted to coded trigger.
    public static void verifyAccountDeletionPermissions(List<Account> accountsToDelete){

        if(accountsToDelete == null || accountsToDelete.size()==0) return;

        for(Account acc : accountsToDelete){
            if(acc.Bond_Holder__pc){
                if(!FeatureManagement.checkPermission(ApplicationConstant.CUSTOM_PERMISSION_DELETE_BOND_HOLDER)){
                    acc.addError(Label.Delete_Bond_Holder_Error_Message); 
                } 
            }
        }

    }

}