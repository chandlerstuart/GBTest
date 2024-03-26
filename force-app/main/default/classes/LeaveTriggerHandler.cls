/*
Name:  LeaveTriggerHandler.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Handler class for all trigger operations related to the Employee Leave Requests
======================================================
======================================================
History
------- 
Ver. Author                 Date            Detail
1.0  Halldór Örn            2014-06-18      Initial development.
1.1  Örn Ingvar             2014-06-20      Code cleanup 
1.2  Simon Molloy           2017-11-02      Added in AM / PM functionality to Parking Space upates    
1.3  J Radcliffe            2019-10-31      Removing coded validation blocking PM Leave on Xmas and New Years eve
1.4  J Radcliffe            2020-01-23      CHanges to support the globalisation of the Leave Management solution (replace Holiday with PublicHoliday__c)

*/
public class LeaveTriggerHandler 
{
    private Boolean isExecuting = false; //& indicates whether the script is executing in a Trigger context.
    private Integer batchSize = 0;
    private OrgSettings__c orgSettings;
    
    //Help constants
    public static final String LEAVE_APPROVED = 'Approved';

    //& statics to prevent recursive behaviour associated with update operations.
    //& (via W/F update later in the context sequence or direct in-trigger update or in-direct via roll-up (OLI, OLIS)).
    @testVisible public static Boolean firstAfterUpdateRun = true;
    @testVisible public static Boolean firstBeforeUpdateRun = true;

    public LeaveTriggerHandler(boolean isExecuting, integer size){
        isExecuting = isExecuting;
        batchSize = size;
        orgSettings = OrgSettings__c.getInstance();
    }
            
    //& trigger action methods.    
    public void onBeforeInsert(Leave__c[] insertedRecords){ 
        System.debug(LoggingLevel.INFO, '=== onBeforeInsert checkEndDate: ');
        checkEndDate(insertedRecords);
        System.debug(LoggingLevel.INFO, '=== onBeforeInsert checkOverlappingRequests: ');
        checkOverlappingRequests(insertedRecords);
        System.debug(LoggingLevel.INFO, '=== onBeforeInsert checkLeaveRequestApprover: ');
        checkLeaveRequestApprover(insertedRecords);    
        System.debug(LoggingLevel.INFO, '=== onBeforeInsert calculateNumberOfDaysOfLeave: ');
        calculateNumberOfDaysOfLeave(insertedRecords);
    }
    
    public void onAfterInsert(Leave__c[] insertedRecords, Map<Id, Leave__c> newMap){
        if(!orgSettings.DisableApprovalSubmission__c) {
            submitLeaveForApproval(insertedRecords);
        }
    }
    
    public void onBeforeUpdate(Leave__c[] updatedRecords, Map<Id, Leave__c> newMap, Map<Id, Leave__c> oldMap){
        if (firstBeforeUpdateRun){
            firstBeforeUpdateRun = false; // prevent recursive updates within applied logic. 
         //   checkOverlappingRequests(updatedRecords);
         System.debug(LoggingLevel.INFO, '=== onBeforeUpdate :  ');
            checkLeaveRequestApprover(updatedRecords);
            calculateNumberOfDaysOfLeave(updatedRecords);
        }
    }
    
    
    
    public void onAfterUpdate(Leave__c[] updatedRecords, Map<Id, Leave__c> newMap, Map<Id, Leave__c> oldMap){
        if (firstAfterUpdateRun){
            firstAfterUpdateRun = false; // prevent recursive updates within applied logic.
            //Update parking spaces by Leave Request Employee
            System.debug(LoggingLevel.INFO, '*** -- onAfterUpdate -- ***');
            updateParkingSpaceAvailability(updatedRecords, false);    
        }
        
    
    }
    public void onBeforeDelete(List<Leave__c> deletedRecords, Map<Id, Leave__c> oldMap){
        //Update Parking Space availability to make the space available again
        updateParkingSpaceAvailability(deletedRecords, true); 
    
    }
    //public void onAfterDelete(List<Leave__c> deletedRecords, Map<Id, Leave__c> oldMap){}
    //public void onAfterUndelete(List<Leave__c> undeletedRecords, Map<Id, Leave__c> newMap){}
    
    //& helper methods.
    
    /*
    checkEndDate
    ------------------------
    Purpose: Checks if leave request has end date. If not set it as start date
    Input: List of leave records
    Output: none
    */
    private void checkEndDate(List<Leave__c> leaveRecords){
        for(Leave__c l : leaveRecords){
            if( l.EndDate__c == null ){
                l.EndDate__c = l.StartDate__c;
            }
        }
    }

    /*
    checkOverlappingRequests
    ------------------------
    Purpose: Checks if new record overlaps with other records.
    Input: List of leave records
    Output: none
    */
    private void checkOverlappingRequests(List<Leave__c> leaveRecords){
        Set<Id> idSet = new Set<Id>();
        for(Leave__c l: leaveRecords) {
            idSet.add(l.Id);
        }
        List<Leave__c> overlap = LeaveManager.checkForOverlappingRequests(leaveRecords);
        System.debug(LoggingLevel.DEBUG, '=== TRIGGER: overlap: ' + overlap);
        if(!Utilities.isNullOrEmpty(overlap)){
            for(Leave__c l : overlap){
                if(idSet.contains(l.Id)) {
                    l.addError('Leave requests are not allowed to overlap');
                    System.debug(LoggingLevel.ERROR, '=== TRIGGER: adding Error: ' + l.Id);
                }
            }
        }
    }

    /*
    checkLeaveRequestApprover
    ------------------------
    Purpose: Checks leave record's employee for manager and assignes manager as approver
    Input: List of leave records
    Output: none
    */
    private void checkLeaveRequestApprover(List<Leave__c> leaveRecords){
        List<Leave__c> leavesWithoutApprover = new List<Leave__c>();
        System.debug('=== checkLeaveRequestApprover: ' + leaveRecords);
        for(Leave__c l: leaveRecords){
            System.debug(LoggingLevel.INFO, '=== l.ManagerId__c: ' + l.ManagerId__c);
            if(!Utilities.isNullOrEmpty(l.ManagerId__c) && Utilities.isNullOrEmpty(l.Approver__c) ){
                l.Approver__c = l.ManagerId__c;
            }
            if(Utilities.isNullOrEmpty(l.ManagerId__c) && Utilities.isNullOrEmpty(l.Approver__c)) {
                leavesWithoutApprover.add(l);
            }

            System.debug(LoggingLevel.INFO, '=== l.Approver__c: ' + l.Approver__c);
        }
        //Check if there are any leave requests without an approver
        if(!leavesWithoutApprover.isEmpty()) {
            Set<Id> employeeIds = new Set<Id>();
            Map<Id, Id> delegatedApproverMap = new Map<Id, Id>();
            for(Leave__c l: leavesWithoutApprover) {
                employeeIds.add(l.Employee__c);
            }
            for(User u: [SELECT Id, DelegatedApproverId FROM USER WHERE Id IN: employeeIds]) {
                delegatedApproverMap.put(u.Id, u.DelegatedApproverId);
            }
            for(Leave__c l: leavesWithoutApprover) {
                if(delegatedApproverMap.containsKey(l.Employee__c)) {
                    l.Approver__c = delegatedApproverMap.get(l.Employee__c);
                }
            }
        }
    }

    /*
    submitLeaveForApproval
    ------------------------
    Purpose: Submits leave requests for approval
    Input: List of leave records
    Output: none
    */
    private void submitLeaveForApproval(List<Leave__c> leaveRecords) {
        List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest> ();
        // Subtmitting the leave request for approval if approver is available.
        for (Leave__c l : leaveRecords) {
            if( !Utilities.isNullOrEmpty(l.Approver__c) ){
                Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
                app.setObjectId(l.id);
                requests.add(app);
            }
        }
        Approval.ProcessResult[] processResults = null;
        try {
            processResults = Approval.process(requests, true);
        }catch (System.DmlException e) {
            RuntimeExceptionHelper.logException(e);
        }
    }

    /*
    calculateNumberOfDaysOfLeave
    ------------------------
    Purpose: Calculates the number of days in a leave request
    Input: List of leave records
    Output: none
    */
    private void calculateNumberOfDaysOfLeave(List<Leave__c> leaveRecords){
        Date startDate  = null;
        Date endDate    = null; 
        Set<Id> employeeIds = new Set<Id>();
        
        //Find the earliest start date and the latest end date
        for (Leave__c l : leaveRecords) {
            if( l.StartDate__c <= startDate || startDate == null ) {
                startDate = l.StartDate__c;
            }
            if( l.EndDate__c >= endDate || endDate == null ) {
                endDate = l.EndDate__c;
            }
            employeeIds.add(l.Employee__c);
        }

        //Get the working pattern for the employee given the start and end dates. Returns an empty map if no patterns for employee
        Map<Id, List<EmployeeWorkingPattern__c>> patternMap 
            = EmployeeWorkingPatternManager.getUserWorkingPatternMapByIdAndPeriod(employeeIds, startDate, endDate);
        System.debug(LoggingLevel.DEBUG, '=== patternMap: ' + patternMap);
        //Map<Date, List<Holiday>> holidays = CalendarHelper.getPublicHolidaysBetweenDates(startDate, endDate);//1.4-
        Map<Id,Map<Date,PublicHoliday__c>> usersPublicHolidayMap = CalendarHelper.getAgentsPublicHolidayBetweenDates(startDate,endDate,employeeIds);//1.4+
        Date xmas = Date.newInstance(System.today().year(), 12, 24);
        Date nyear = Date.newInstance(System.today().year(), 12, 31);

        Map<Date,PublicHoliday__c> publicHolidays;//1.4+
        for (Leave__c l : leaveRecords) {
            Date s = l.StartDate__c;
            Date e = l.EndDate__c;
            Boolean isOneDay = s == e;

            publicHolidays = (l.Employee__c != null && usersPublicHolidayMap.containsKey(l.Employee__c)) ? usersPublicHolidayMap.get(l.Employee__c):new Map<Date,PublicHoliday__c>();//1.4+

            //TODO: Are there different rules for LIEU days?  For now, do nothing if 
            //TODO: Leave Type is Lieu Holiday or Lieu Pay
            if(l.LeaveType__c == 'Authorised') {
                //Authorised leaves don't count as a holiday so do nothing
            } else if (l.LeaveType__c.toUpperCase().indexOf('LIEU') > -1 || l.LeaveType__c == ApplicationConstant.LEAVE_TYPE_WELLNESS_DAY){
                //LIEU days just need to calculate the number of days being logged
                //l.NumberOfHolidays__c = LeaveManager.calculateNumberOfDaysOfLeave(l, patternMap, holidays);//1.4-
                l.NumberOfHolidays__c = LeaveManager.calculateNumberOfDaysOfLeave(l, patternMap, publicHolidays);//1.4+
            
            /*} else if ( ( s == xmas || s == nyear || e == xmas || e == nyear ) && !( l.AM__c && !l.PMStart__c && !l.PMReturn__c ) && isOneDay ) {
                // stop pm leave on christmas eve and new years eve
                //l.addError('PM leave on half day holidays is not available');//1.3-*/
            } else {
                //l.NumberOfHolidays__c = LeaveManager.calculateNumberOfDaysOfLeave(l, patternMap, holidays);//1.4-
                l.NumberOfHolidays__c = LeaveManager.calculateNumberOfDaysOfLeave(l, patternMap, publicHolidays);//1.4+
                System.debug(LoggingLevel.DEBUG, '=== Number of holidays returned from Leave Manager: ' + l.NumberOfHolidays__c);
                if(Utilities.isNullOrEmpty(l.NumberOfHolidays__c)){
                    l.addError('Leave length 0');
                }
            }
        }
    }
    
    /*
    updateParkingSpaceAvailability
    ------------------------
    Purpose: Updates any associated Parking Spaces to this user
    To show that they are available while this person is on leave
    Input: List of leave records
    Output: none
    */
    private void updateParkingSpaceAvailability(List<Leave__c> leaveRecords, boolean isDelete){
        System.debug(LoggingLevel.INFO, '*** -- updateParkingSpaceAvailabilty -- ***');
        Set<Id> userIdSet = new Set<Id>();
        
        //Get a collection of users we need to search parking spaces for
        for (Leave__c l : leaveRecords){
            //Only process Approved leave
            if (LEAVE_APPROVED.equalsIgnoreCase(l.Status__c)){
                userIdSet.add(l.Employee__c);
            }
        }
        
        //Get a collection of parking spaces we can process later
        //TODO : Make sure you pull in the right fields
        Map<Id, Parking_Space__c> parkingSpaceMap = new Map<Id, Parking_Space__c>();
        for (Parking_Space__c ps : [select Id, Available_From__c, Available_To__c, Current_User__c,
                                    Mark_As_Available__c, Owner__c, AM__c, PM__c 
                                    from Parking_Space__c where Owner__c in :userIdSet]){

            parkingSpaceMap.put(ps.Owner__c, ps);                            

        }
        
        //A unique collection to save the parking spaces - we can use this to make sure we do not 
        //Duplicate a Parking Space in the list
        Map<Id, Parking_Space__c> updatedParkingSpaces = new Map<Id, Parking_Space__c>();
        
        if (!isDelete){
            for (Leave__c l : leaveRecords){
                Parking_Space__c ps = parkingSpaceMap.get(l.Employee__c);
                if (ps != null){
                    if (null == ps.Available_From__c && null == ps.Available_To__c){
                        //Update the Parking Space record with the Leave dates
                        ps.Available_From__c = l.StartDate__c;
                        ps.Available_To__c = l.EndDate__c;
                        
                        if (l.StartDate__c == Date.today()) {
                            ps.Available__c = TRUE;
                            ps.Current_User__c = null;
                            ps.Car_Detail__c = null;
                        }
                        //If it is just one day leave, check if it's AM or PM only
                        if (l.StartDate__c == l.EndDate__c){
                            ps.AM__c = l.AM__c;
                            ps.PM__c = l.PMStart__c;
                        }
                        
                        if (!updatedParkingSpaces.containsKey(ps.Id)) updatedParkingSpaces.put(ps.Id, ps);
                    }else {
                        if (l.StartDate__c < ps.Available_From__c){
                            //The start of this leave is nearer than the current Available From
                            ps.Available_From__c = l.StartDate__c;
                        }
                        if (l.EndDate__c > ps.Available_To__c){
                            //The end of this leave is after the current Available To
                            ps.Available_To__c = l.EndDate__c;
                        }
    
                        if (l.StartDate__c == Date.today()) {
                            ps.Available__c = TRUE;
                            ps.Current_User__c = null;
                            ps.Car_Detail__c = null;
                        }

                        //If it is just one day leave, check if it's AM or PM only
                        if (l.StartDate__c == l.EndDate__c){
                            ps.AM__c = l.AM__c;
                            ps.PM__c = l.PMStart__c;
                        }
                        
                        if (!updatedParkingSpaces.containsKey(ps.Id)) updatedParkingSpaces.put(ps.Id, ps);
                    }
                }
            }
        }else {
            for (Leave__c l : leaveRecords){
                Parking_Space__c ps = parkingSpaceMap.get(l.Employee__c);
                if (ps != null){
                    if (l.StartDate__c == ps.Available_From__c && l.EndDate__c == ps.Available_To__c){
                        //Update the Parking Space record with the Leave dates
                        ps.Available_From__c = null;
                        ps.Available_To__c = null;
                        
                        if (ps.Available__c) {
                            ps.Available__c = FALSE;
                            ps.Current_User__c = null;
                            ps.Car_Detail__c = null;
                        }

                        ps.AM__c = FALSE;
                        ps.PM__c = FALSE;
                        
                        if (!updatedParkingSpaces.containsKey(ps.Id)) updatedParkingSpaces.put(ps.Id, ps);
                    }
                }
            }
        }
        
        update updatedParkingSpaces.values();
    }    
    
  //& End helper methods.
}