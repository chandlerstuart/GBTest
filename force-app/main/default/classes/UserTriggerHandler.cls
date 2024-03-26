/*
Name:  UserTriggerHandler.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Handler class for all trigger operations related to Users
======================================================
======================================================
History
------- 
Ver. Author                Date                 Detail
1.0  Örn Ingvar          2014-08-13    Initial development 

*/
public without sharing class UserTriggerHandler {
    private Boolean isExecuting = false; // indicates whether the script is executing in a Trigger context.
    private Integer batchSize = 0;

    //statics to prevent recursive behaviour associated with update operations.
    //(via W/F update later in the context sequence or direct in-trigger update or in-direct via roll-up (OLI, OLIS)).
    public static Boolean firstAfterUpdateRun = true;
    public static Boolean firstBeforeUpdateRun = true;
    public static Boolean isTest = false; //Used to throw exceptions while testing
    public static Boolean otherTestsRunning = false; //Used to disable managed sharing while running other tests
    
    public UserTriggerHandler(boolean isExecuting, integer size) {
        isExecuting = isExecuting;
        batchSize = size;
    }

    public void onAfterUpdate(List<User> updatedRecords, Map<Id, User> newMap, Map<Id, User> oldMap) {
        //Disable this if other tests running that don't rely on sharing calculations
        // this is done to avoid UNABLE_TO_LOCK_ROW errors
        if(!otherTestsRunning) {
            Set<Id> usersWithNewManagerIdSet = new Set<Id>();
            Map<Id, Id> newManagerMap = new Map<Id, Id>();
            for(User u: updatedRecords) {
                //Check if the manager changed
                if(newMap.get(u.Id).ManagerId != oldMap.get(u.Id).ManagerId) {
                    usersWithNewManagerIdSet.add(u.Id);
                    newManagerMap.put(u.Id, u.ManagerId);
                }
            }

            //Only run if there has been a change of manager 
            if(usersWithNewManagerIdSet.size() > 0) {
                //Set to hold all employee leave year Ids belonging to users with new managers
                Set<Id> employeeLeaveYearIdSet = new Set<Id>();
                // Create a new list of sharing objects for EmployeeLeaveYear
                List<EmployeeLeaveYear__Share> leaveYearShrs  = new List<EmployeeLeaveYear__Share>();
                
                // Declare variable for manager sharing
                EmployeeLeaveYear__Share employeeManagerShr;

                for(EmployeeLeaveYear__c el : [SELECT Id, OwnerId FROM EmployeeLeaveYear__c WHERE OwnerId IN: usersWithNewManagerIdSet]) {
                    employeeLeaveYearIdSet.add(el.Id);
                    // Instantiate the sharing objects
                    employeeManagerShr = new EmployeeLeaveYear__Share();
                    
                    // Set the ID of record being shared
                    employeeManagerShr.ParentId = el.Id;
                    
                    // Set the ID of user or group being granted access
                    employeeManagerShr.UserOrGroupId = newManagerMap.get(el.OwnerId);
                    
                    // Set the access level
                    employeeManagerShr.AccessLevel = 'edit';
                    
                    // Set the Apex sharing reason for hiring manager and recruiter
                    employeeManagerShr.RowCause = Schema.EmployeeLeaveYear__Share.RowCause.Manager_Leave_Request_Access__c;
                    
                    // Add objects to list for insert
                    leaveYearShrs.add(employeeManagerShr);
                }

                //Find older shares that need to be deleted
                List<EmployeeLeaveYear__Share> sharesToDelete = [SELECT Id 
                                                        FROM EmployeeLeaveYear__Share 
                                                        WHERE ParentId IN :employeeLeaveYearIdSet 
                                                        AND RowCause = 'Manager_Leave_Request_Access__c'];
                System.debug(LoggingLevel.DEBUG, '=== sharesToDelete.size(): ' + sharesToDelete.size());
                if(!sharesToDelete.isEmpty()){
                    try {
                        Database.Delete(sharesToDelete, false);
                        if(isTest) throw new RuntimeExceptionHelper.testThrownException('Exception thrown while testing');
                    } catch (Exception e) {
                        RuntimeExceptionHelper.logException(e);
                    }
                }

                // Insert sharing records and capture save result 
                // The false parameter allows for partial processing if multiple records are passed 
                // into the operation 
                Database.SaveResult[] lsr;
                try {
                    lsr = Database.insert(leaveYearShrs,false);
                    if(isTest) throw new RuntimeExceptionHelper.testThrownException('Exception thrown while testing');
                } catch (Exception e) {
                    RuntimeExceptionHelper.logException(e);
                }
                
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
            }
        }
    }
}