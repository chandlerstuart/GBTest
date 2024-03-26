/*
Name:  EmployeeLeaveYearTriggerHandler.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Handler class for all trigger operations related to the Employee Leave Year
======================================================
======================================================
History
------- 
Ver. Author                Date                 Detail
1.0  Örn Ingvar          2014-08-13    Initial development 
1.2  Örn Ingvar          2014-08-16    Added better exception handling
*/
public class EmployeeLeaveYearTriggerHandler 
{
    private Boolean isExecuting = false; // indicates whether the script is executing in a Trigger context.
    private Integer batchSize = 0;

    //statics to prevent recursive behaviour associated with update operations.
    //(via W/F update later in the context sequence or direct in-trigger update or in-direct via roll-up (OLI, OLIS)).
    public static Boolean firstAfterUpdateRun = true;
    public static Boolean firstBeforeUpdateRun = true;
    public static Boolean isTest = false; //Used to throw exceptions while testing
    public static Boolean otherTestsRunning = false; //Used to disable managed sharing while running other tests

    public EmployeeLeaveYearTriggerHandler(boolean isExecuting, integer size){
        isExecuting = isExecuting;
        batchSize = size;
    }

    public void onBeforeInsert(EmployeeLeaveYear__c[] insertedRecords) {
        for(EmployeeLeaveYear__c el: insertedRecords) {
            if(el.Employee__c != null && el.Employee__c != el.OwnerId) {
                try {
                    el.OwnerId = el.Employee__c;
                    if(isTest) throw new RuntimeExceptionHelper.testThrownException('Exception thrown while testing');
                } catch (Exception e) {
                    RuntimeExceptionHelper.logException(e);
                }
            }
        }
    }

    //Give the manager of the employee access via sharing to the leave year
    public void onAfterInsert(EmployeeLeaveYear__c[] insertedRecords, Map<Id, EmployeeLeaveYear__c> newMap) {
        //Disable this if other tests running that don't rely on sharing calculations
        // this is done to avoid UNABLE_TO_LOCK_ROW errors
        if(!otherTestsRunning) {
            Set<Id> userIdSet = new Set<Id>();
            for(EmployeeLeaveYear__c leaveYear: insertedRecords) {
                userIdSet.add(leaveYear.OwnerId);
            }
            Map<Id, Id> userToManagerMap = new Map<Id, Id>();
            for(User u: [SELECT Id, ManagerId FROM User WHERE Id IN: userIdSet AND ManagerId != null ]){
                userToManagerMap.put(u.Id, u.ManagerId);
            }

            // Create a new list of sharing objects for EmployeeLeaveYear
            List<EmployeeLeaveYear__Share> leaveYearShrs  = new List<EmployeeLeaveYear__Share>();
            
            // Declare variables for employee and manager sharing
            EmployeeLeaveYear__Share employeeManagerShr;
            
            for(EmployeeLeaveYear__c leaveYear : insertedRecords){
            // Instantiate the sharing objects
                employeeManagerShr = new EmployeeLeaveYear__Share();
                
                // Set the ID of record being shared
                employeeManagerShr.ParentId = leaveYear.Id;
                
                // Set the ID of user or group being granted access
                if(userToManagerMap.containsKey(leaveYear.OwnerId)) {
                    employeeManagerShr.UserOrGroupId = userToManagerMap.get(leaveYear.OwnerId) ;
                } else {
                    //No manager found. Skip to next record in loop
                    continue;
                }
                
                // Set the access level
                employeeManagerShr.AccessLevel = 'edit';
                
                // Set the Apex sharing reason for hiring manager and recruiter
                employeeManagerShr.RowCause = Schema.EmployeeLeaveYear__Share.RowCause.Manager_Leave_Request_Access__c;
                System.debug(LoggingLevel.DEBUG, '=== employeeManagerShr: ' + employeeManagerShr);
                // Add objects to list for insert
                leaveYearShrs.add(employeeManagerShr);
            }
            
            // Insert sharing records and capture save result 
            // The false parameter allows for partial processing if multiple records are passed 
            // into the operation 
            System.debug(LoggingLevel.DEBUG, '=== leaveYearShrs.size(): ' + leaveYearShrs.size());
            try {
                Database.SaveResult[] lsr = Database.insert(leaveYearShrs,false);
                // Create counter
                Integer i=0;
                // Process the save results
                for(Database.SaveResult sr : lsr) {
                    if(!sr.isSuccess()) {
                        // Get the first save result error
                        Database.Error err = sr.getErrors()[0];
                        
                        // Check if the error is related to a trivial access level
                        // Access levels equal or more permissive than the object's default 
                        // access level are not allowed. 
                        // These sharing records are not required and thus an insert exception is 
                        // acceptable. 
                        if(!(err.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION  
                                                       &&  err.getMessage().contains('AccessLevel'))) {
                            // Throw an error when the error is not related to trivial access level.
                            trigger.newMap.get(leaveYearShrs[i].ParentId).
                              addError(
                               'Unable to grant sharing access due to following exception: '
                               + err.getMessage());
                        }
                    }
                    i++;
                }
                if(isTest) throw new RuntimeExceptionHelper.testThrownException('Exception thrown while testing');
            } catch (Exception e) {
                RuntimeExceptionHelper.logException(e);
            }
        }
    }

    //Update the owner if its not the employee already
    public void onBeforeUpdate(EmployeeLeaveYear__c[] updatedRecords, Map<Id, EmployeeLeaveYear__c> newMap, 
        Map<Id, EmployeeLeaveYear__c> oldMap) {
        if (firstBeforeUpdateRun) {
            firstBeforeUpdateRun = false; // prevent recursive updates within applied logic. 
            for(EmployeeLeaveYear__c el: updatedRecords) {
                if(el.Employee__c != null && el.Employee__c != el.OwnerId) {
                    try {
                        el.OwnerId = el.Employee__c;
                        if(isTest) throw new RuntimeExceptionHelper.testThrownException('Exception thrown while testing');
                    } catch (Exception e) {
                        RuntimeExceptionHelper.logException(e);
                    }
                }
            }
        }
    }
}