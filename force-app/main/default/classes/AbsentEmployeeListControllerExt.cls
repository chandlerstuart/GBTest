/*
Name:  AbsentEmployeeListControllerExt.cls
Copyright © 2014  Kaptio ehf.
======================================================
======================================================
Purpose:
-------
Extension for AbesentEmployeeList.page. 
Retrieves a list of Employees ( User ) who have an approved leave request or are absent due to working pattern on the current day.
======================================================
======================================================
History
------- 
Ver.  Author             Date        Detail
1.0  Halldór Örn   2014-05-21  Class creation.

*/
public without sharing class AbsentEmployeeListControllerExt {
    
    private List<Leave__c> leaveList;
    private static List<Leave__c> empLeaveList;
    private List<EmployeeWorkingPattern__c> patterns;
    private static List<EmployeeWorkingPattern__c> empPatterns;
    public List<AbsentWrapper> absenceList {get; set;}
    public static List<AbsentWrapper> empAbsenceList {get; set;}
    
    /*
    AbsentEmployeeListControllerExt
    ------------------------
    Purpose: Contructor. Leaves and working patterns are retrieved and added to AbsentWrapper list. Wrapper is then sorted by Employee Name
    Input: StandardController for account
    
    */
    public AbsentEmployeeListControllerExt(ApexPages.StandardController controller) {}

    public AbsentEmployeeListControllerExt(){}

    @AuraEnabled
    public static List<AbsentWrapper> getAbsenceList(){
        Set<Id> userIds = new Set<Id>();
        try {
            empLeaveList = LeaveManager.getLeavesForToday();
            empPatterns = EmployeeWorkingPatternManager.getUserWorkingPatternMapActiveToday(System.today());
            empAbsenceList = new List<AbsentWrapper>();

            for(Leave__c l : empLeaveList) {
                if(!userIds.contains(l.Employee__c)) {
                    empAbsenceList.add(new AbsentWrapper(l));
                    userIds.add(l.Employee__c);
                }
            }

            for(EmployeeWorkingPattern__c p : empPatterns) {
                if(!userIds.contains(p.Employee__c)) {
                    empAbsenceList.add(new AbsentWrapper(p));
                    userIds.add(p.Employee__c);
                }
            }
            empAbsenceList.sort();

            return empAbsenceList;

        } catch(Exception e) {
            System.debug('No leaveLists '+ empLeaveList +': ' + e);
            RuntimeExceptionHelper.logException(e);
            return null;
        }
    }

    public PageReference initAction() {
        Set<Id> userIds = new Set<Id>();
        try {
            leaveList = LeaveManager.getLeavesForToday();
            patterns = EmployeeWorkingPatternManager.getUserWorkingPatternMapActiveToday(System.today());
            absenceList = new List<AbsentWrapper>();

            for(Leave__c l : leaveList) {
                if(!userIds.contains(l.Employee__c)) {
                    absenceList.add(new AbsentWrapper(l));
                    userIds.add(l.Employee__c);
                }
            }

            for(EmployeeWorkingPattern__c p : patterns) {
                if(!userIds.contains(p.Employee__c)) {
                    absenceList.add(new AbsentWrapper(p));
                    userIds.add(p.Employee__c);
                }
            }
            absenceList.sort();

        } catch(Exception e) {
            System.debug('No leaveLists '+ leaveList +': ' + e);
            RuntimeExceptionHelper.logException(e);
        }
        return null;
    }

    /*
     Purpose:
        -------
        Wrapper to allow the creaton of an Employee list based on approved leave requests and working patterns.
        Converts all values to string for easy display in view.
        Implements Comparable to allow list to be sorted by Employee name
    */
    public class AbsentWrapper implements Comparable {

        @AuraEnabled
        public String id {get; set;}
        @AuraEnabled
        public String name {get; set;}
        @AuraEnabled
        public String title {get; set;}
        @AuraEnabled
        public String publicNote {get; set;}
        @AuraEnabled
        public String startDate {get; set;}
        @AuraEnabled
        public String endDate {get; set;}
        @AuraEnabled
        public String leaveType {get; set;}

        public AbsentWrapper(Leave__c leave) {
            id = leave.Employee__r.Id;
            name = leave.Employee__r.Name;
            title = leave.Employee__r.Title;
            publicNote = leave.PublicNote__c;
            startDate = DateTime.newInstance(leave.StartDate__c, Time.newInstance(0,0,0,0) ).format('dd/MM/yyyy');
            endDate = DateTime.newInstance(leave.EndDate__c, Time.newInstance(0,0,0,0) ).format('dd/MM/yyyy');
            leaveType = 'All Day';
            // Check if Half day
            if( Date.today() == leave.StartDate__c ){
                if( !leave.AM__c && leave.PMStart__c){
                    leaveType = 'Afternoon';
                } else if ( !leave.PMStart__c && leave.AM__c){
                    leaveType = 'Morning';
                }
            }
            if( Date.today()!= leave.StartDate__c && Date.today() == leave.EndDate__c && !leave.PMReturn__c && leave.AM__c){
                leaveType = 'Morning';
            }
        }

        public AbsentWrapper(EmployeeWorkingPattern__c pattern) {
            name = pattern.Employee__r.Name;
            title = pattern.Employee__r.Title;
            publicNote = 'Non working day';
            startDate = DateTime.newInstance(System.today(), Time.newInstance(0,0,0,0) ).format('dd/MM/yyyy');
            endDate = DateTime.newInstance(System.today(), Time.newInstance(0,0,0,0) ).format('dd/MM/yyyy');
        }

        public Integer compareTo(Object compareTo) {
            AbsentWrapper compareToEmp = (AbsentWrapper)compareTo;
            if (name == compareToEmp.name) return 0;
            if (name > compareToEmp.name) return 1;
            return -1;
        }
    }
}