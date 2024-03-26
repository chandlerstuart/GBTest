/*
Name:  SprintTriggerHandler.cls
======================================================
======================================================
Purpose:
-------
Trigger handler for SprintTrigger.trigger
This class handles the business logic for Sprint records following DML operations

======================================================
======================================================
History
------- 
Ver. Author             Date        Detail
1.0  James Radcliffe    2017-09-01  Initial development.
*/
public class SprintTriggerHandler{
    public static final String CLASS_NAME = 'SprintTriggerHandler';
    //Recursion flags
    public static Boolean isBeforeUpdateTriggerCalled = FALSE;
    public static Boolean isBeforeInsertTriggerCalled = FALSE;
   

    //This method processes Sprint records before they are inserted
    public void onBeforeInsert(List<Sprint__c> newSprints){
        if (!isBeforeInsertTriggerCalled){
            if(newSprints != null){
                //check for any overlapping Sprints
                checkForOverlappingSprints(newSprints);
            }
            
            isBeforeInsertTriggerCalled = TRUE;
        }
    }

    //This method processes Sprint records before they are updated
    public void onBeforeUpdate(Map<Id,Sprint__c> oldMap, Map<Id,Sprint__c> newMap){    
        if (!isBeforeUpdateTriggerCalled){    
            List<Sprint__c> dateChangeSprints = new List<Sprint__c>();
            for(Sprint__c newSprint : newMap.values()){
                Sprint__c oldSprint = oldMap.get(newSprint.Id);
                if(oldSprint.Start_Date__c != newSprint.Start_Date__c
                ||oldSprint.End_Date__c != newSprint.End_Date__c){
                    dateChangeSprints.add(newSprint);
                }
            }
            
                //Check the 'dateChangeSprints' for any overlapping with existing sprints of a matching type following the change
                checkForOverlappingSprints(dateChangeSprints);
            
            }

            isBeforeUpdateTriggerCalled = TRUE;
        }
    
    //This method ensures there are no two Sprints (of a matching 'Type') overlapping at any time (Start/End Dates).
    public void checkForOverlappingSprints(List<Sprint__c> sprints){
        List<Error_Log__c> logs = new List<Error_Log__c>();
    
        system.debug('Checking for overlapping Sprints');
    
        try {
            //Query all sprints (excluding those that ended more than 3 months ago - future proof method by limiting the number of records retrieved for governor limits)
            List<Sprint__c> allOtherSprints = [Select Id, Type__c, Name, Start_Date__c, End_Date__c From Sprint__c WHERE End_Date__c > N_Months_Ago:3];
            
            //Loop through all Trigger & Queried Sprints
            for(Sprint__c triggerSprint : sprints){
            
                for(Sprint__c otherSprint : allOtherSprints){
                    
                    //Check if the Start or End dates of the Trigger Sprint falls within the timeframe of an existing Sprint of a matching 'Type'
                    if(triggerSprint.Id != otherSprint.Id
                    &&triggerSprint.Type__c == otherSprint.Type__c
                    &&((triggerSprint.Start_Date__c <= otherSprint.End_Date__c && triggerSprint.Start_Date__c >= otherSprint.Start_Date__c)
                    ||(triggerSprint.End_Date__c <= otherSprint.End_Date__c && triggerSprint.End_Date__c >= otherSprint.Start_Date__c))){
                        
                        String url = System.Url.getSalesforceBaseURL().toExternalForm();
                        system.debug('BaseUrl = '+url);
                        String link = '<a href="'+url+'/'+otherSprint.Id+'">'+otherSprint.Name+'</a>';
                        
                        //Display an error with a link to the existing Sprint record                    
                        triggerSprint.adderror(ApplicationConstant.OVERLAPPING_SPRINT_ERROR+link, false);
                    }
                }
            }
        }catch (Exception e){
            system.debug('*** -- Exception: ' + e + ' at ' + e.getLineNumber() + ' -- ***');
            logs.add(ApplicationConstant.getExceptionLog(e, 'checkForOverlappingSprints', CLASS_NAME, null));    
        }finally {
             if(!logs.isEmpty()){ Database.insert(logs, false); }
        }
    }
    
}