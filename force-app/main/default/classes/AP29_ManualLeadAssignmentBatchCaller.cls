/**
 ** @author: Alyana Navarro 25/02/2016
 ** Class Name: AP29_ManualLeadAssignmentBatchCaller
 ** @Description: Prototype Manual Lead Assignment batch. This executes when the button (Assign All Leads) in Lead list view is clicked in the Lead record.
 **
 **/

/**
 ** @Edited by: Nicole De Guzman 03/04/2016
 ** @Class Name: AP29_ManualLeadAssignmentBatchCaller
 ** @Description: Code clean-up
 **
 **/
global with sharing class AP29_ManualLeadAssignmentBatchCaller{
    WebService static void processDetails(){
        
        if(!isScheduledbatchRunning()){
            //Query the current user Team and Role
            //List<Sales_Agent_Attributes__c> agentRole = [SELECT Id, Team__c From Sales_Agent_Attributes__c 
                //WHERE Sales_Rep__c =: Userinfo.getUserId() AND Team__c <> NULL ORDER BY LastModifiedDate LIMIT 1];
            
            //Query list of user role
            Set<String> roles = new Set<String>{'Golfbreaks Sales Manager', 'Golfbreaks System Administrator', 'Golfbreaks Service Agent'};
            List<Profile> profiles = [Select Id from Profile where Name IN: roles AND Id = :UserInfo.getProfileId()];
            System.debug('---- AP29_ManualLeadAssignmentBatchCaller permission ---- \n'+ profiles );
            Map<Id, Group> queueMap = new Map<Id, Group>([SELECT Id, Name FROM GROUP WHERE Name IN :ApplicationConstant.TEAM_SET AND Type = 'Queue']);
            System.debug('---- AP29_ManualLeadAssignmentBatchCaller queueMap.keySet() ---- \n'+ queueMap.keySet());
            
            //Check if the list is not null or zero
            if (!queueMap.isEmpty() && !profiles.isEmpty()) {

                AP28_ManualLeadAssignmentBatch manualLeadAssignment = new AP28_ManualLeadAssignmentBatch (queueMap.keySet());
                Database.executeBatch(manualLeadAssignment);
            }
        }
        
    }
    
    private static Boolean isScheduledbatchRunning(){
        // TO DO: Query asyncjobs and apexclass records to know if scheduled batch is running.
        System.debug('************************* isScheduledbatchRunning ----');
        Id classID = [Select Id From ApexClass Where Name = 'AP28_ManualLeadAssignmentBatch'].id;
        List<AsyncApexJob> jobList = [Select Status, ApexClassID from AsyncApexJob where ApexClassID =: classID AND Status = 'Processing'];
        
        return (jobList.size()!=0?true:false);
    }
}