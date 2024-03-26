/*
Name:  MyTeamController.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Controller class for a myTeam.page.

Prepares data for an overview over leave request from users that
have the current user as a manager as well as their current
leave year.

======================================================
======================================================
History
------- 
Ver. Author             Date            Detail
1.0  Halldór Örn        2014-05-23      Initial development.
1.1  J Radcliffe        2020-01-28      Support for globalisation - Retrieve Leave Year based on calculated date (current date or calculated from selected values)
1.2  J Radcliffe        2021-10-05      Added support for multiple levels of hierarchy (direct and indirect reports) from the MyTeams page
1.3  J Radcliffe        2022-08-25      Bug Fix - Employee leave year details are excluded if the user starts in the middle of a month.
*/
public with sharing class MyTeamController {

    public Boolean pagination { get; set; }
    public String filterId { get; set; }
    public Integer currentYear { get; set; }
    public Integer currentMonth { get; set; }
    public String currentMonthName { get; set; }
    public Set<Id> userIds { get; set; }
    public List<User> users { get; set; }
    public List<EmployeeLeaveYear__c> leaveYears { get; set; }
    public List<Leave__c> leaveRequests { get; set; }
    public String requestId { get; set; }
    public String action { get; set; }
    public String comment { get; set; }
    public String userId { get; set; }
    public String success { get; set; }
    public Date focusDate {get;set;} //1.1+ 
    public List<SelectOption> filters {get; set;}//1.2+
    public String filterSelection {get; set;}//1.2+

    private Integer pageSize = 200;
    private String baseQuery = 'SELECT Id, FirstName, LastName, Name FROM User';
    private String myId = UserInfo.getUserId();
    private List<LeaveRequestWithYearWrapper> leaveRequestList = new List<LeaveRequestWithYearWrapper>();
    private List<UserLeaveOverviewWrapper> userLeaveOverview = new List<UserLeaveOverviewWrapper>();
    private List<User> userList = new List<User>();
    private List<SelectOption> viewOptions = new List<SelectOption>();

    public ApexPages.StandardSetController userSetController {

        get{
            if(userSetController == null){

                userSetController = new ApexPages.StandardSetController(Database.getQueryLocator(baseQuery + ' WHERE ManagerId =: myId AND IsActive = true ORDER BY FirstName'));
                userSetController.setPageSize(pageSize);

                if(filterId != null){
                    userSetController.setFilterId(filterId);
                }
            }
            return userSetController;
        }set;
    }

    /*
    MyTeamController
    ------------------------
    Purpose: Contructor 
    */
    public MyTeamController(){
        comment = '';
        requestId = '';

        userId = Utilities.grabParameter('userId');
        success = Utilities.grabParameter('success');

        initPage();        
        System.debug('=== getMyTeamLeaveOverview: ' + getMyTeamLeaveOverview());

    }   

    /*
    initPage
    ------------------------
    Purpose: Initializes data for the Team management tab 
    */
    public void initPage(){

        //1.2+
        if(filters == null){//Set on page load
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('Direct','Direct Reports Only'));
            options.add(new SelectOption('All','All'));
            filters = options;
        }
        if(filterSelection == null){//Default on page load
            filterSelection = 'Direct';
        }else{//Else reset User Set
            String whereClause = ' WHERE '; 
            if(filterSelection == 'All'){
                whereClause = whereClause+'(ManagerId =: myId OR Manager.ManagerId =: myId OR Manager.Manager.ManagerId =: myId OR Manager.Manager.Manager.ManagerId =: myId) ';
            }else{
                whereClause = whereClause+'ManagerId =: myId';
            } 
            whereClause = whereClause+' AND IsActive = true ORDER BY FirstName';
            userSetController = new ApexPages.StandardSetController(Database.getQueryLocator(baseQuery + whereClause));
            userSetController.setPageSize(pageSize);
            if(filterId != null){
                userSetController.setFilterId(filterId);
            }
        } 

        // checks if pagination controls should render in view
        pagination = userSetController.getHasNext() || userSetController.getHasPrevious();

        String year = Utilities.grabParameter('year');
        String month = Utilities.grabParameter('month');

        currentYear = Utilities.isNullOrEmpty(year) ? System.Today().Year() : Integer.valueOf(year);
        currentMonth = Utilities.isNullOrEmpty(month) ? System.Today().Month() : Integer.valueOf(month);
        currentMonthName = CalendarHelper.getMonthName(currentMonth, 4);

        focusDate = calculateFocusDate(currentYear,currentMonth);//1.1+
        system.debug('focusDate > '+focusDate);

        userIds = UserManager.getUsersId( userSetController );
        users = UserManager.getUsers(userSetController);

        system.debug('userIds > '+userIds);

        //leaveYears = EmployeeLeaveYearManager.getEmployeeLeaveYearByUserIdAndYear( userIds, String.valueOf(currentYear) );//1.1-
        leaveYears = EmployeeLeaveYearManager.getEmployeeLeaveYearsByUsersAndDateValue(userIds,focusDate).values();//1.1+
        leaveRequests = LeaveManager.getPendingLeaveByUserId( userIds );

        system.debug('leaveYears > '+leaveYears);
        system.debug('leaveRequests > '+leaveRequestList);

    }


    public static Date calculateFocusDate(Integer year, Integer month){//1.1+
        DateTime nowLocalTimeZone = TimeZoneHelper.getAgentsLocalDateTime(new Set<Id>{UserInfo.getUserId()}).values()[0];
        
        if(year == nowLocalTimeZone.year() && month == nowLocalTimeZone.month()) return Date.newInstance(nowLocalTimeZone.year(), nowLocalTimeZone.month(), nowLocalTimeZone.day());//1.3+ Return current day according to the running user's TimeZone if the current year and month are selected 
        if(year == null && month == null) return Date.newInstance(nowLocalTimeZone.year(), nowLocalTimeZone.month(), nowLocalTimeZone.day());//Return current day according to the running user's TimeZone (for initial page load - no year/month selected)
        if(year != null && month == null) return Date.newInstance(year,1,1);
        if(year != null && month != null) return Date.newInstance(year,month,1);
        return Date.newInstance(nowLocalTimeZone.year(), nowLocalTimeZone.month(), nowLocalTimeZone.day());
    }


    /*
    firstPage
    ------------------------
    Purpose: navigates to first page of the usercontroller and reinitializes data
    */
    public PageReference firstPage(){
        userSetController.first();
        initPage();
        return null;
    }

    /*
    lastPage
    ------------------------
    Purpose: navigates to last page of the usercontroller and reinitializes data
    */
    public PageReference lastPage(){
        userSetController.last();
        initPage();
        return null;
    }

    /*
    next
    ------------------------
    Purpose: navigates to next page of the usercontroller and reinitializes data
    */
    public PageReference next(){
        if(userSetController.getHasNext()){
            userSetController.next();
            initPage();           
        }
         return null;
    }

    /*
    prev
    ------------------------
    Purpose: navigates to previous page of the usercontroller and reinitializes data
    */
    public PageReference prev(){
        if(userSetController.getHasPrevious()){
            userSetController.previous();
            initPage();            
        }
        return null;
    }

    /*
    resetFilter
    ------------------------
    Purpose: Resets usersetcontroller 
    */
    public PageReference resetFilter(){

        userSetController = null;
        userSetController.setPageNumber(1);
        initPage();
        return null;
    }

    /*
    getListViewOptions
    ------------------------
    Purpose: Gets the list of list-view filters for users
    Input: none
    Output: List of SelectOptions 
    */
    public List<SelectOption> getListViewOptions(){
        if(viewOptions.isEmpty()){
            viewOptions = UserManager.getListViewOptions(userSetController);
        }
        return viewOptions;
    }
    
    /*
    getLeaveRequestsWithYear
    ------------------------
    Purpose: Creates a list of LeaveRequestWithYearWrapper with data for users in the team
    Input: none
    Output: List of LeaveRequestWithYearWrapper
    */
    public List<LeaveRequestWithYearWrapper> getLeaveRequestsWithYear(){
        leaveRequestList = new List<LeaveRequestWithYearWrapper>();
        //if(leaveRequestList.isEmpty()){
            for(Leave__c l : leaveRequests){
                for(EmployeeLeaveYear__c ly : leaveYears){
                    if(ly.Employee__c == l.Employee__c)
                        leaveRequestList.add( new LeaveRequestWithYearWrapper( ly, l ) );
                }
            }
        //}
        return leaveRequestList;
    }

    /*
    getUsers
    --------
    Purpose: Gets the user records for the users in the team
    Input: none
    Output: List of users
    */
    public List<User> getUsers()
    {
        if(userList.isEmpty()){
            userlist = UserManager.getUsers(userSetController);
        }
        return userList;
    }

    /*
    getMyTeamLeaveOverview
    ------------------------
    Purpose: Creates a list of UserLeaveOverviewWrapper
    Input: none
    Output: List of UserLeaveOverviewWrapper objects
    */
    public List<UserLeaveOverviewWrapper> getMyTeamLeaveOverview(){
        userLeaveOverview = new List<UserLeaveOverviewWrapper>();
        //if(userLeaveOverview.isEmpty()){            
            for(User user : users ){
                EmployeeLeaveYear__c leaveyear = new EmployeeLeaveYear__c();
                List<Leave__c> leaveRequestList = new List<Leave__c>();
                for(EmployeeLeaveYear__c l : leaveYears){
                    if(l.Employee__c == user.Id)
                        leaveYear = l;
                }
                for(Leave__c r : leaveRequests){
                    if(r.EmployeeLeaveYear__c == leaveYear.Id)
                        leaveRequestList.add(r);
                }

                userLeaveOverview.add( new UserLeaveOverviewWrapper( user, leaveYear, leaveRequestList ) );
            }
        //}

        return userLeaveOverview;

    }

    /*
    approveOrReject
    ------------------------
    Purpose: Handles the approval process for Team management links
    */
    public PageReference approveOrReject(){

        System.debug('=== comment: ' + comment);
        System.debug('=== action: ' + action);
        System.debug('=== requestId: ' + requestId);

        Boolean success;
        try {
            success = updateProcess( comment, action);
        } catch (Exception e) {
            success = false;
            RuntimeExceptionHelper.logException(e);
        }
        String i = success ? '1' : '0';
        String url = '/apex/MyTeam?success='+i;
        
        PageReference pageref = new PageReference(url);
        pageref.setRedirect(true);

        return pageref;

    }  

    /*
    reassign
    --------
    Purpose: Redirects to the reassign approver page for the relevant leave request.
    */
    public PageReference reassign(){

        System.debug('=== requestId: ' + requestId);
        String url = '/apex/MyTeam?success=-1';
        String approvalId = '';
        try{
            List<ProcessInstanceWorkitem> piw = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: requestId ];
            approvalId = piw.get(0).Id;
            System.debug('=== piw: ' + piw);
            System.debug('=== approvalId: ' + approvalId);
        }catch(Exception e){
            System.debug('No piw with id '+ requestId +': ' + e);
            RuntimeExceptionHelper.logException(e);
        }
        
        if(!Utilities.isNullOrEmpty(approvalId))
            url = '/'+approvalId+'/e?et=REASSIGN&retURL=%2Fapex%2FMyTeam';
            
        PageReference pageref = new PageReference(url);
        pageref.setRedirect(true);

        return pageref;

    }  

    /*
    updateProcess
    -------------
    Purpose: Handles updates in leave request approvals
    Input:  String approverComment, String action
    Output: Boolean value of success.
    */
    public Boolean updateProcess(String comment, String action ){
        System.debug('=== updateProcess');
        Boolean results = false;
        List<ProcessInstanceWorkitem> piw = new List<ProcessInstanceWorkitem>();
        try{
            piw = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: requestId ];
            System.debug('=== query: piw: ' + piw);
        }catch(Exception e){
            System.debug('No ProcessInstanceWorkitem with targetid '+ requestId +': ' + e);
            RuntimeExceptionHelper.logException(e);
        }
        
        if(!Utilities.isNullOrEmpty(piw)){
            List<Id> newWorkItemIds =  new List<Id>();
            for(ProcessInstanceWorkitem p : piw){
                newWorkItemIds.add(p.Id);
            }
            System.debug('=== newWorkItemIds: ' + newWorkItemIds);
            // Instantiate the new ProcessWorkitemRequest object and populate it
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setComments(comment);
            System.debug('=== req: ' + req);
            req.setAction(action);
            System.debug('=== req: ' + req);
            req.setNextApproverIds(new Id[] { UserInfo.getUserId() });
            System.debug('=== req: ' + req + ' user: ' + UserInfo.getUserId());
            // Use the ID from the newly created item to specify the item to be worked
            req.setWorkitemId(newWorkItemIds.get(0));
            System.debug('=== req: ' + req);
            // Submit the request for approval
            Approval.ProcessResult result =  Approval.process(req);
            System.debug('=== result: ' + result);
        
            System.debug('=== result.isSuccess(): ' + result.isSuccess());
            results = result.isSuccess();
        }

        return results;

    }

    public class UserLeaveOverviewWrapper {
    /*
        Wrapper that groups a user with his leave year and leave requests
    */    
        public User user { get; set; }
        public EmployeeLeaveYear__c leaveYear { get; set; }
        public List<Leave__c> leaveRequests { get; set; }
        
        public UserLeaveOverviewWrapper(User user, EmployeeLeaveYear__c leaveYear, List<Leave__c> leaveRequests ) {
            this.user = user;
            this.leaveYear = leaveYear;
            this.leaveRequests = leaveRequests;
        }
    }

    public class LeaveRequestWithYearWrapper {
    /*
        Wrapper that groups leave year and leave requests
    */            
        public EmployeeLeaveYear__c leaveYear { get; set; }
        public Leave__c leaveRequest { get; set; }
        public LeaveRequestWithYearWrapper(EmployeeLeaveYear__c leaveYear, Leave__c leaveRequest) {
            this.leaveYear = leaveYear;
            this.leaveRequest = leaveRequest;
        }
    }

}