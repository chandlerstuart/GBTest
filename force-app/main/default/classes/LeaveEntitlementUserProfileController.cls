/*
Name:  LeaveEntitlementUserProfileController.cls
Copyright © 2014  Kaptio ehf.
======================================================
======================================================
Purpose:
-------
Cotroller for LeaveEntitlementUserProfile.component
======================================================
======================================================
History
------- 
Ver.  Author             Date        Detail
1.0  Halldór Örn   2014-06-20  Class creation.
2.0  Simon Molloy  2016-10-21  Added Lieu Request functionality.
2.1  J Radcliffe   2020-01-27  Changes to support the globalisation of the leave management system
2.2  J Radcliffe   2020-01-28  Query appropriate leave year based on new date range feature
2.3  J Radcliffe   2020-02-03  Make validation errors more user friendly on Submit
2.4  J Radcliffe   2023-06-04  Adding support for logging 'wellness days'
2.5  J Radcliffe   2023-07-17  New logic for USA well-being. The USA are breaking their calendar into fixed bi-months (e.g. Jan > Feb, March > April etc). During this period they can have up to the configured limit of well-being leave.
2.6  J Radcliffe   2024-11-01  New logic for Scheduled Well-being Leave. Remaining days should adopt the 'Schduled Well-being Leave Limit Value' if the date selected is after the 'Scheduled Well-being Leave Limit Start'.
*/
global class LeaveEntitlementUserProfileController {
   
    public Id userId { get; set; }
    public String activeYear { get; set; }
    public String currentYear { get; set; }
    public String selectedYear { get; set; }
    public String lastYear { get; set; }
    public String nextYear { get; set; }
    public String employeeId { get; set; }
    public User employee { get; set; }
    public String tabId { get; set; }
    public String tab { get; set; }
    public EmployeeLeaveYear__c leaveYear { get; set; }
    public EmployeeLeaveYear__c activeLeaveYear { get; set; }
    public LeaveManager.LeaveWrapper leave { get; set; }
    public Leave__c aLeave { get; set; }
    public List<SelectOption> types { get; set; }
    public List<Leave__c> leaveRequests { get; set; }
    public Boolean hasNext { get; set; }
    public Boolean hasPrev { get; set; }
    public Boolean notOpenFromChatterTab { get; set; }
    public Decimal wellnessDaysRemaining {get;set;}//2.4+
    public String lieuType {get; set;}
    public String lastDayOfYearString {get;set;}
    public boolean showLieuButton {
        get {
            if (null == showLieuButton) showLieuButton = false;
            return showLieuButton;
        }
        set;
    }
    public boolean showWellnessButton {//2.4+
        get {
            if (null == showWellnessButton) showWellnessButton = false;
            return showWellnessButton;
        }
        set;
    }
    public string leaveYearButtonPosition{
        get{
            if(null == leaveYearButtonPosition) leaveYearButtonPosition = '223'; 
            return leaveYearButtonPosition;
        }
        set;
    }

    public string lieuButtonPosition{
        get {
            if (null == lieuButtonPosition) lieuButtonPosition = '115';//default buttons position
            return lieuButtonPosition;
        }
        set;
    }
    public List<SelectOption> lieuTypes {
        get {
            if (null == lieuTypes){
                lieuTypes = new List<SelectOption>();
                lieuTypes.add(new SelectOption('','--Select--'));
                lieuTypes.add(new SelectOption('DAYS','Days in lieu'));
                lieuTypes.add(new SelectOption('PAY','Pay in lieu'));
            }
            return lieuTypes;
        }
        set;
    }

    private static Map<Integer,Integer> bimonthlyPairsMap= new Map<Integer,Integer>{1=>2,3=>4,5=>6,7=>8,9=>10,11=>12,2=>1,4=>3,6=>5,8=>7,10=>9,12=>11};//2.5+

    private final User user;
    private Map<String,EmployeeLeaveYear__c> leaveMap;

    /*
    LeaveEntitlementUserProfileController
    ------------------------
    Purpose: Constructor. Gets values of the current user and the profile's owner - not necessarily the same user.
    Retrieves the requested Employee Leave Year record and associated leave requests.
    Input: none
    Output:none
    */
    public LeaveEntitlementUserProfileController() {

            this.userId = UserInfo.getUserId();
            //Do we show the 'Request Lieu' button?
            Leave_Requests_Settings__c lrs = Leave_Requests_Settings__c.getInstance(UserInfo.getUserId());
            if (null == lrs) lrs = Leave_Requests_Settings__c.getInstance(UserInfo.getProfileId());
            if (null != lrs){
                showLieuButton = lrs.Log_Lieu_Requests__c;
            }
            employeeId = ApexPages.currentPage().getParameters().get('employeeId');
            if(employeeId == null) employeeId = Utilities.grabParameter('sfdc.userId');
            //Added this to avoid errors when application is opened from a standard tab instead of a chatter subtab
            if(Utilities.isNullOrEmpty(employeeId)) {
                employeeId = UserInfo.getUserId();
                ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, 'Please open this app from the Chatter Tab');
                //ApexPages.addMessage(msg);
            } else {
                employeeId = employeeId;
            }
            
            tabId = Utilities.grabParameter('sfdc.tabName');
            tab = userId == employeeId ? 'LeaveEntitlement' : 'LeaveEntitlementAdmin';

            //Get the active Leave Years based on the current date (considering running user's timezone)
            DateTime nowLocalTimeZone = TimeZoneHelper.getAgentsLocalDateTime(new Set<Id>{UserInfo.getUserId()}).values()[0];//2.1+
            Date todayLocalTimeZone = Date.newInstance(nowLocalTimeZone.year(), nowLocalTimeZone.month(), nowLocalTimeZone.day());//2.1+ 
            Map<Id,EmployeeLeaveYear__c> activeLeaveYears = EmployeeLeaveYearManager.getEmployeeLeaveYearsByUsersAndDateValue(new Set<Id>{employeeId},todayLocalTimeZone);//2.1+
            system.debug('activeLeaveYears: '+activeLeaveYears);
            system.debug('employeeId: '+employeeId);
            
            if(activeLeaveYears == null || !activeLeaveYears.containsKey(employeeId)){//2.1+
                ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, 'No Active Leave Year Found. Please contact HR.');
                ApexPages.addMessage(msg);
            }else{
                activeLeaveYear = activeLeaveYears.get(employeeId);

                if(activeLeaveYear.WellnessDayLimit__c != null && activeLeaveYear.WellnessDayLimit__c > 0 ){//2.4+
                    lieuButtonPosition = '304';//Shift lieu button to the left
                    leaveYearButtonPosition = '412';
                    showWellnessButton = true;
                } 
                activeYear = activeLeaveYear.Year__c;
            }
            
            selectedYear = Utilities.grabParameter('year');//2.1+
            currentYear = Utilities.isNullOrEmpty(selectedYear)?activeYear:selectedYear;   

            /* 2.1-
            currentYear = String.valueOf( System.Today().Year() );
            activeYear = currentYear; // perserve the current year value.

            selectedYear = Utilities.grabParameter('year');
            selectedYear = Utilities.isNullOrEmpty(selectedYear) ? String.valueOf( System.Today().Year() ) : selectedYear;
            
            currentYear = selectedYear;

            lastYear = String.valueOf( Integer.valueOf( selectedYear ) - 1);
            nextYear = String.valueOf( Integer.valueOf( selectedYear ) + 1);*/

            if(currentYear != null){
                lastYear = String.valueOf( Integer.valueOf( currentYear ) - 1);//2.1+
                nextYear = String.valueOf( Integer.valueOf( currentYear ) + 1);//2.1+
                lastDayOfYearString = DateTime.newInstance(Integer.valueOf(currentYear), 12, 31,0,0,0).format('yyyy-MM-dd');
            } 

            List<String> yearlist = new List<String>{ currentYear, lastYear, nextYear };
            
            // Initialize empty object for Leave Request form
            aLeave = new Leave__c();
            aLeave.AM__c = true;
            aLeave.PMReturn__c = true;
            aLeave.PMStart__c = true;

            employee = UserManager.getUsersById(new Set<Id>{ employeeId })[0];

            leave = new LeaveManager.LeaveWrapper();
            leave.employeeName = employeeId;
            leave.employeeLeaveYear = currentYear;
            types = LeaveManager.getLeaveType();

            Set<Id> userIds = new Set<Id>{ employeeId };
            
            leaveMap = EmployeeLeaveYearManager.getEmployeeLeaveYearsByUserIdAndYears(employeeId, yearlist);
            if(!leaveMap.isEmpty()){
                leaveYear = leaveMap.get( currentYear );
                /*activeLeaveYear = EmployeeLeaveYearManager.getEmployeeLeaveYearByUserIdAndYear( employeeId,  activeYear); //2.1-
                if(activeLeaveYear == null) {
                    ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, 'No Leave Year Found. Please contact HR.');
                    ApexPages.addMessage(msg);
                }*/
            }

            hasNext = leaveMap.get( nextYear ) != null;
            hasPrev = leaveMap.get( lastYear ) != null;

            leaveRequests = LeaveManager.getLeaveByUserIdAndYear(userIds, currentYear);
        
    }

    /*
    submitLeaveRequest
    ------------------------
    Purpose: Gets form values from Javascript Remoting function on LeanEntitlementUserProfile.component and creates a new leave requests.
    Input: String userId, String leaveYearId, String leaveType, String startDate, String endDate, Boolean am, Boolean pmStart, Boolean pmReturn, String comment, String publicNote
    Output: String value of result
    */
    @RemoteAction
    global static String submitLeaveRequest(String userId, String leaveYearId, String leaveType, String startDate, String endDate, Boolean am, Boolean pmStart, Boolean pmReturn, String comment, String publicNote ){
        
        String year = '';
        EmployeeLeaveYear__c leaveYear;
        String returnStr = '';

        Date fromDate;//2.2+

        try {
            fromDate = Date.parse(startDate);//2.2+
            year = String.valueOf(Date.parse(startDate).year());
        } catch (Exception e) {
            //return 'Problem occurred parsing the year from the start date';
        }
           //Check if the start date occurs in a leave year that is not the current year
        if(year != '' && year != String.valueOf(System.now().year())) {
                //Start date is not in current year. Check for a leave year record for this employee
                try {
                    //leaveYear = [SELECT Id FROM EmployeeLeaveYear__c WHERE Employee__c =: userId AND Year__c =: year]; //2.2-
                    leaveYear = [SELECT Id FROM EmployeeLeaveYear__c WHERE Employee__c =: userId AND StartDate__c <=: fromDate and EndDate__c >=: fromDate];//2.2+
                } catch (Exception e) {
                    String result = System.Label.UI_Text_No_Leave_Year_For_Date;
                    //'No leave year exists for this date. HR has been notified and will inform you when the leave year has been created.';
                    
                    notifyHR(year);
                    return result;
                }
        }
        
        Leave__c newLeave = New Leave__c();
        newLeave.Employee__c = !Utilities.isNullOrEmpty(userId) ? userId : '';
        newLeave.LeaveType__c = !Utilities.isNullOrEmpty(leaveType) ? leaveType : '';
        newLeave.StartDate__c = Utilities.isNullOrEmpty(startDate) ? null : Date.parse(startDate);
        newLeave.EndDate__c = Utilities.isNullOrEmpty(endDate) ? null : Date.parse(endDate);
        newLeave.AM__c = am != null ? am : false;
        newLeave.PMStart__c = pmStart != null ? pmStart : false;
        newLeave.PMReturn__c = pmReturn != null ? pmReturn : false;
        newLeave.EmployeeComment__c = !Utilities.isNullOrEmpty(comment) ? comment : '';
        newLeave.PublicNote__c = !Utilities.isNullOrEmpty(publicNote) ? publicNote : '';
        if(leaveYear != null) {
            newLeave.EmployeeLeaveYear__c = leaveYear.Id;
        } else {
            try {
                newLeave.EmployeeLeaveYear__c = !Utilities.isNullOrEmpty(leaveYearId) ? leaveYearId : '';
            } catch (Exception e) {
                String retStr = System.Label.UI_Text_No_Leave_Year_For_Date;
                //'No Leave Year has been created for you. Contact HR for assistance';

                notifyHR(String.valueOf(System.today().year()));
                return retStr;
            }
        }
        newLeave.HR_Comments__c = 'Submitted by Employee';
        
        returnStr = LeaveManager.insertLeaveRequest(newLeave);

        returnStr = (returnStr.containsIgnoreCase('FIELD_CUSTOM_VALIDATION_EXCEPTION'))? returnStr.substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION, ') :returnStr;//2.3+
        
        return returnStr;
    }
    
    /*
    submitLieuRequest
    ------------------------
    Purpose: Gets form values from Javascript Remoting function on LeanEntitlementUserProfile.component and creates a new lieu request.
    Input: String userId, String leaveYearId, String leaveType, String startDate, String endDate, Boolean am, Boolean pmStart, Boolean pmReturn, String comment, String publicNote
    Output: String value of result
    */
    @RemoteAction
    global static String submitLieuRequest(String userId, String leaveYearId, String leaveType, String startDate, String endDate, Boolean am, Boolean pmStart, Boolean pmReturn, String comment, String publicNote, String lieuType ){

        String year = '';
        EmployeeLeaveYear__c leaveYear;
        String returnStr = '';

        Date fromDate;//2.2+

        try {
            fromDate = Date.parse(startDate);//2.2+            
            year = String.valueOf(Date.parse(startDate).year());
        } catch (Exception e) {
            //return 'Problem occurred parsing the year from the start date';
        }
           //Check if the start date occurs in a leave year that is not the current year
        if(year != '' && year != String.valueOf(System.now().year())) {
                //Start date is not in current year. Check for a leave year record for this employee
                try {
                    //leaveYear = [SELECT Id FROM EmployeeLeaveYear__c WHERE Employee__c =: userId AND Year__c =: year]; //2.2-
                    leaveYear = [SELECT Id FROM EmployeeLeaveYear__c WHERE Employee__c =: userId AND StartDate__c <=: fromDate and EndDate__c >=: fromDate];//2.2+
                } catch (Exception e) {
                    String result = System.Label.UI_Text_No_Leave_Year_For_Date;
                    //'No leave year exists for this date. HR has been notified and will inform you when the leave year has been created.';
                    
                    notifyHR(year);
                    return result;
                }
        }
        
        Leave__c newLeave = New Leave__c();
        newLeave.Employee__c = !Utilities.isNullOrEmpty(userId) ? userId : '';
        //String lieuType = '';
        //if (!Utilities.isNullOrEmpty(leaveType)){
        //    lieuType = ('PAY'.equalsIgnoreCase(leaveType) ? 'Lieu Pay' : 'Lieu Holiday');
        //}
        String whichLieuType = '';
        if (!Utilities.isNullOrEmpty(lieuType)){
            whichLieuType = lieuType;
        }else {
            if (!Utilities.isNullOrEmpty(leaveType)){
                whichLieuType = ('PAY'.equalsIgnoreCase(leaveType) ? 'Lieu Pay' : 'Lieu Holiday');
            }    
        }
        system.debug('*** -- whichLieuType = ' + whichLieuType + ' -- ***');
        //newLeave.LeaveType__c = !Utilities.isNullOrEmpty(lieuType) ? lieuType : '';
        newLeave.LeaveType__c = whichLieuType;
        newLeave.StartDate__c = Utilities.isNullOrEmpty(startDate) ? null : Date.parse(startDate);
        newLeave.EndDate__c = Utilities.isNullOrEmpty(endDate) ? null : Date.parse(endDate);
        newLeave.AM__c = am != null ? am : false;
        newLeave.PMStart__c = pmStart != null ? pmStart : false;
        newLeave.PMReturn__c = pmReturn != null ? pmReturn : false;
        newLeave.EmployeeComment__c = !Utilities.isNullOrEmpty(comment) ? comment : '';
        newLeave.PublicNote__c = !Utilities.isNullOrEmpty(publicNote) ? publicNote : '';
        if(leaveYear != null) {
            newLeave.EmployeeLeaveYear__c = leaveYear.Id;
        } else {
            try {
                newLeave.EmployeeLeaveYear__c = !Utilities.isNullOrEmpty(leaveYearId) ? leaveYearId : '';
            } catch (Exception e) {
                String retStr = System.Label.UI_Text_No_Leave_Year_For_Date;
                //'No Leave Year has been created for you. Contact HR for assistance';

                notifyHR(String.valueOf(System.today().year()));
                return retStr;
            }
        }
        newLeave.HR_Comments__c = 'Submitted by Employee';
        
        returnStr = LeaveManager.insertLeaveRequest(newLeave);

        returnStr = (returnStr.containsIgnoreCase('FIELD_CUSTOM_VALIDATION_EXCEPTION'))? returnStr.substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION, ') :returnStr;//2.3+
        
        return returnStr;
    }

    private static void notifyHR(String year) {
        //Send Email to HR
        LeaveEntitlementSettings__c leaveSettings = LeaveEntitlementSettings__c.getInstance();
        if (leaveSettings.HRNotifyEmail__c != '' && leaveSettings.HRNotifyEmail__c != null) {
        //Get the current instance URL of Saleforce
        String sfBaseUrl = URL.getSalesforceBaseUrl().getHost();
        EmailHelper.sendAnEmail(
            //Subject
            'User ' + UserInfo.getName() + ' needs a Leave Year for ' + year,
            //Body
            UserInfo.getName() + ' needs an Employee Leave Year created. \n\n\n Click to see users profile : ' + 
                'https://'+sfBaseUrl+'/'+UserInfo.getUserId() + '\n', 
            //Email address
            leaveSettings.HRNotifyEmail__c);
        } else {
            System.debug(LoggingLevel.ERROR, 'No email address for HR registered');
        }
    }

    //2.4+
    public void calculateRemainingDays(){}

    //2.4+
    public Decimal getRemainingWellnessDays(){
        
        Date focusDate = (aLeave.StartDate__c != null)?aLeave.StartDate__c:System.today();
        Integer focusMonth = focusDate.month();
        Integer bimonth = bimonthlyPairsMap.containsKey(focusMonth)?bimonthlyPairsMap.get(focusMonth):null;//2.5+ - The month matching the focus (selected) month, for bimonth leave calculations.

        Boolean isBimonthlyAllowance = (activeLeaveYear?.WellbeingLeavePeriod__c != null && activeLeaveYear?.WellbeingLeavePeriod__c == ApplicationConstant.LEAVE_PERIOD_BIMONTHLY)?true:false;//2.5+

        //2.5+ 
        String query = 'Select Id, StartDate__c, EndDate__c, WellnessDayLimit__c, ScheduledWellbeingLeaveLimitStart__c, ScheduledWellbeingLeaveLimitValue__c, (Select Id, StartDate__c, EndDate__c, NumberOfHolidays__c From Leave_Requests__r Where LeaveType__c = \''+ApplicationConstant.LEAVE_TYPE_WELLNESS_DAY+'\' and (Status__c = \''+ApplicationConstant.LEAVE_STATUS_PENDING_APPROVAL+'\' or Status__c = \''+ApplicationConstant.LEAVE_STATUS_APPROVED+'\') '; //2.6~ ScheduledWellbeingLeaveLimitStart__c + ScheduledWellbeingLeaveLimitValue__c
        if(isBimonthlyAllowance){
            query = query+'and (CALENDAR_MONTH(StartDate__c) = :focusMonth or CALENDAR_MONTH(StartDate__c) = :bimonth)';//Include leave booked in month pair
        }else{
            query = query+'and CALENDAR_MONTH(StartDate__c) = :focusMonth';//Pull in the leave for the selected month (only)
        }
        query = query+') From EmployeeLeaveYear__c Where StartDate__c<=:focusDate and EndDate__c >=:focusDate and Employee__c =: userId';//2.5+

        EmployeeLeaveYear__c ely = Database.query(query);//2.5+
        //EmployeeLeaveYear__c ely = [Select Id, StartDate__c, EndDate__c, WellnessDayLimit__c, (Select Id, StartDate__c, EndDate__c, NumberOfHolidays__c From Leave_Requests__r Where LeaveType__c = :ApplicationConstant.LEAVE_TYPE_WELLNESS_DAY and CALENDAR_MONTH(StartDate__c) = :focusMonth and (Status__c = :ApplicationConstant.LEAVE_STATUS_PENDING_APPROVAL or Status__c = :ApplicationConstant.LEAVE_STATUS_APPROVED)) From EmployeeLeaveYear__c Where StartDate__c<=:focusDate and EndDate__c >=:focusDate and Employee__c =: userId];//2.5-
        
        Decimal daysUsed = 0;
        Decimal daysAllowed = ely.WellnessDayLimit__c != null?ely.WellnessDayLimit__c:0;

        //2.6+ If the date selected is after the 'Scheduled Well-being leave start' then adopt the (new) scheduled limit.
        if(ely.ScheduledWellbeingLeaveLimitValue__c != null && ely.ScheduledWellbeingLeaveLimitStart__c != null && ely.ScheduledWellbeingLeaveLimitStart__c<=focusDate) daysAllowed = ely.ScheduledWellbeingLeaveLimitValue__c;
        
        if(ely.Leave_Requests__r.size()>0){
            for(Leave__c lr : ely.Leave_Requests__r){
                daysUsed = daysUsed+lr.NumberOfHolidays__c;
            }
        }
        Decimal daysRemaining = daysAllowed-daysUsed;
        wellnessDaysRemaining = (daysRemaining>0)?daysRemaining:0;        
        return wellnessDaysRemaining;
    }

    /*2.4+
    Purpose: Gets form values from Javascript Remoting function on LeanEntitlementUserProfile.component and creates a new wellness day request.
    Input: String userId, String leaveYearId, String leaveType, String startDate, String endDate, Boolean am, Boolean pmStart, String comment, String publicNote
    Output: String value of result
    */
    @RemoteAction
    global static String submitWellnessRequest(String userId, String leaveYearId, String startDate, String endDate, Boolean am, Boolean pmStart, String comment, String publicNote ){
        
        String year = '';
        Integer month;
        EmployeeLeaveYear__c leaveYear;
        String returnStr = '';
        Decimal wellnessDaysRemaining;

        Date fromDate;//2.2+
        Date toDate;//2.2+

    
        try {
            fromDate = Date.parse(startDate);//2.2+      
            toDate = Date.parse(endDate);//2.2+                  
            year = String.valueOf(Date.parse(startDate).year());
            month = Date.parse(startDate).month();
        } catch (Exception e) {
            //return 'Problem occurred parsing the year from the start date';
        }

        system.debug('fromDate > '+fromDate);
        system.debug('toDate > '+toDate);
        system.debug('year > '+year);
        system.debug('month > '+month);

        //2.5+
        DateTime nowLocalTimeZone = TimeZoneHelper.getAgentsLocalDateTime(new Set<Id>{UserInfo.getUserId()}).values()[0];//2.1+
        Date todayLocalTimeZone = Date.newInstance(nowLocalTimeZone.year(), nowLocalTimeZone.month(), nowLocalTimeZone.day());//2.1+ 
        EmployeeLeaveYear__c activeLeaveYear = EmployeeLeaveYearManager.getEmployeeLeaveYearsByUsersAndDateValue(new Set<Id>{UserInfo.getUserId()},todayLocalTimeZone).values()[0];//2.1+
        Integer bimonth = bimonthlyPairsMap.containsKey(month)?bimonthlyPairsMap.get(month):null;//2.5+ - The month matching the focus (selected) month, for bimonth leave calculations.

        Boolean isBimonthlyAllowance = (activeLeaveYear?.WellbeingLeavePeriod__c != null && activeLeaveYear?.WellbeingLeavePeriod__c == ApplicationConstant.LEAVE_PERIOD_BIMONTHLY)?true:false;


        try {
            //leaveYear = [SELECT Id FROM EmployeeLeaveYear__c WHERE Employee__c =: userId AND Year__c =: year]; //2.2-
            
            //2.5+
            String query = 'SELECT Id, WellnessDayLimit__c, ScheduledWellbeingLeaveLimitStart__c, ScheduledWellbeingLeaveLimitValue__c, (Select Id, StartDate__c, EndDate__c, NumberOfHolidays__c From Leave_Requests__r Where LeaveType__c = \''+ApplicationConstant.LEAVE_TYPE_WELLNESS_DAY+'\' and (Status__c = \''+ApplicationConstant.LEAVE_STATUS_PENDING_APPROVAL+'\' or Status__c = \''+ApplicationConstant.LEAVE_STATUS_APPROVED+'\') '; //2.6~ ScheduledWellbeingLeaveLimitStart__c + ScheduledWellbeingLeaveLimitValue__c
            if(isBimonthlyAllowance){
                query = query+' and (CALENDAR_MONTH(StartDate__c) = :month or CALENDAR_MONTH(StartDate__c) = :bimonth)) ';
            }else{
                query = query+' and CALENDAR_MONTH(StartDate__c) = :month )';
            }
            query = query+' From EmployeeLeaveYear__c Where Employee__c = :userId and StartDate__c <= :fromDate and EndDate__c >= :toDate '; 
            system.debug('theQuery = '+query);
            leaveYear = Database.query(query);

            //leaveYear = [SELECT Id, WellnessDayLimit__c, (Select Id, StartDate__c, EndDate__c, NumberOfHolidays__c From Leave_Requests__r Where LeaveType__c = :ApplicationConstant.LEAVE_TYPE_WELLNESS_DAY and CALENDAR_MONTH(StartDate__c) = :month and (Status__c = :ApplicationConstant.LEAVE_STATUS_PENDING_APPROVAL or Status__c = :ApplicationConstant.LEAVE_STATUS_APPROVED)) FROM EmployeeLeaveYear__c WHERE Employee__c =: userId AND StartDate__c <=: fromDate and EndDate__c >: toDate];//2.5-
        } catch (Exception e) {
            String result = System.Label.UI_Text_No_Leave_Year_For_Date;
            //'No leave year exists for this date. HR has been notified and will inform you when the leave year has been created.';
            
            notifyHR(year);
            return result;
        }
        
        system.debug('leave year > '+leaveYear);

        Decimal daysUsed = 0;
        Decimal daysAllowed = leaveYear?.WellnessDayLimit__c != null?leaveYear?.WellnessDayLimit__c:0;

        //2.6+ If the date selected is after the 'Scheduled Well-being leave start' then adopt the (new) scheduled limit.
        if(leaveYear.ScheduledWellbeingLeaveLimitValue__c != null && leaveYear.ScheduledWellbeingLeaveLimitStart__c != null && leaveYear.ScheduledWellbeingLeaveLimitStart__c<=fromDate) daysAllowed = leaveYear.ScheduledWellbeingLeaveLimitValue__c;

        if(leaveYear?.Leave_Requests__r.size()>0){
            for(Leave__c lr : leaveYear.Leave_Requests__r){
                daysUsed = daysUsed+lr.NumberOfHolidays__c;
            }
        }
        Decimal daysRemaining = daysAllowed-daysUsed;
        wellnessDaysRemaining = (daysRemaining>0)?daysRemaining:0;   

        Decimal requestedAmount = 0;
        if(am == true) requestedAmount = requestedAmount+0.5;
        if(pmStart == true) requestedAmount = requestedAmount+0.5;

        system.debug('requestedAmount > '+requestedAmount);

        if(requestedAmount == 0){
            return 'Please select either am, pm or both';
        }else if(requestedAmount > wellnessDaysRemaining){
            return 'Sorry, you cannot request '+requestedAmount+' days leave as you only have '+wellnessDaysRemaining+' remaining.';
        }

        Leave__c newLeave = New Leave__c();
        newLeave.Employee__c = !Utilities.isNullOrEmpty(userId) ? userId : '';
        newLeave.LeaveType__c = ApplicationConstant.LEAVE_TYPE_WELLNESS_DAY;
        newLeave.StartDate__c = Utilities.isNullOrEmpty(startDate) ? null : Date.parse(startDate);
        newLeave.EndDate__c = Utilities.isNullOrEmpty(endDate) ? null : Date.parse(endDate);
        newLeave.AM__c = am != null ? am : false;
        newLeave.PMStart__c = pmStart != null ? pmStart : false;
        newLeave.PMReturn__c = (!pmStart && am)? false : true;
        newLeave.EmployeeComment__c = !Utilities.isNullOrEmpty(comment) ? comment : '';
        newLeave.PublicNote__c = !Utilities.isNullOrEmpty(publicNote) ? publicNote : 'Well-being';
        
        if(newLeave.AM__c == true && newLeave.PMStart__c == true) newLeave.PublicNote__c = newLeave.PublicNote__c+ ' (All Day)';
        else if(newLeave.AM__c == true) newLeave.PublicNote__c = newLeave.PublicNote__c+ ' (AM)';
        else newLeave.PublicNote__c = newLeave.PublicNote__c+ ' (PM)';

        if(leaveYear != null) {
            newLeave.EmployeeLeaveYear__c = leaveYear.Id;
        } else {
            try {
                newLeave.EmployeeLeaveYear__c = !Utilities.isNullOrEmpty(leaveYearId) ? leaveYearId : '';
            } catch (Exception e) { 
                String retStr = System.Label.UI_Text_No_Leave_Year_For_Date;
                //'No Leave Year has been created for you. Contact HR for assistance';

                notifyHR(String.valueOf(System.today().year()));
                return retStr;
            }
        }
        newLeave.HR_Comments__c = 'Submitted by Employee';
        
        returnStr = LeaveManager.insertLeaveRequest(newLeave);

        returnStr = (returnStr.containsIgnoreCase('FIELD_CUSTOM_VALIDATION_EXCEPTION'))? returnStr.substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION, ') :returnStr;//2.3+

        return returnStr;
    }
}