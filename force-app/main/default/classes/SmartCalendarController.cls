/*
Name:  SmartCalendarController.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Controller class for a calendar displaying leave requests,
working patterns and public holidays.

======================================================
======================================================
History
------- 
Ver. Author                Date                  Detail
1.0  Halldór Örn        2014-05-23      Initial development.
1.1  Halldór Örn        2014-07-29      Renamed to SmartCalendarController.
1.2  Halldór Örn        2014-07-30      Added to class for persistant filtering.
1.3  J Radcliffe        2021-10-07      Added support for multiple levels of hierarchy (direct and indirect reports) from the MyTeams page

*/
public without sharing class SmartCalendarController {
    
    public Boolean      pagination          { get; set; }
    public Boolean      isFirst             { get; set; }
    public Boolean      isLast              { get; set; }
    public String       filterId            { get; set; }
    public Integer      currentPageNumber   { get; set; }
    public String       currentPage         { get; set; }
    public Integer      currentYear         { get; set; }
    public Integer      currentMonth        { get; set; }
    public String       currentMonthName    { get; set; }
    public Set<Id>      userIds             { get; set; }
    public Boolean      pager               { get; set; }
    public String       listTypeValue       { get; set; }

    //1.3+ - apex:attributes are set AFTER the constructor, meaning the data needs to be reinitialised from the setter (when the listType is available)
    public String listType{
        set{
            if(Utilities.getCurrentPageName().contains('MyTeam') && listTypeValue != value){
                listTypeValue = value;
                initCalendar();
            }
        }
        get;
    }

    private Integer     pageSize   = 100;
    private String      baseQuery  = 'SELECT Id, FirstName, LastName, Name FROM User';
    private String      myId       = UserInfo.getUserId();
    private String      queryExtension = '';
    private Boolean     myteam = false;

    private List<SelectOption> viewOptions = new List<SelectOption>();

    //public ApexPages.StandardSetController userSetController { get; set; } 

    public ApexPages.StandardSetController userSetController {
        // UserSet controller is defined based on if this it the Team Managment tab og Employee Calendar tab
        get{
            if(userSetController == null){
                if(Utilities.getCurrentPageName().contains('MyTeam')){
                    queryExtension = ' AND ManagerId =: myId';
                    myteam = true;
                } else {
                    Set<ID> userIds = LeaveManager.getUsersWithApprovedLeaveThisMonth(currentYear,currentMonth);
                    System.debug(LoggingLevel.DEBUG, '=== userIds: ' + userIds);
                    //Add all the users with a working pattern for the current month to the set
                    userIds.addAll(EmployeeWorkingPatternManager.getUSersWithWorkingPatternByPeriod(currentYear, currentMonth));
                    queryExtension = ' AND Id IN: userIds';
                }
                userSetController = new ApexPages.StandardSetController(Database.getQueryLocator(baseQuery + ' WHERE IsActive = true ' + 
                                                                                                                            queryExtension + ' ORDER BY FirstName'));
                userSetController.setPageSize(pageSize);
                
                if(filterId != null){
                    userSetController.setFilterId(filterId);
                }                
            }
            return userSetController;
        }set;
    }

    /*
    public SmartCalendarController
    ------------------------
    Purpose: Constructor. Initializes data
    Input: none
    Output: none
    */
    public SmartCalendarController(){
        System.debug(logginglevel.INFO,'=== SmartCalendarController: ' );
        pager = false;
        initCalendar();     
    }   

    /*
    initCalendar
    ------------------------
    Purpose: initiates needed data for calendar 
    Input: none
    Output: none
    */
    private void initCalendar(){
        
        //1.3+
        if(listTypeValue != null && Utilities.getCurrentPageName().contains('MyTeam')){
            system.debug('Setting standard set controller > '+listTypeValue);
            if(listTypeValue == 'All'){
                queryExtension = ' AND (ManagerId =: myId OR Manager.ManagerId =: myId OR Manager.Manager.ManagerId =: myId OR Manager.Manager.Manager.ManagerId =: myId)';
            }else{
                queryExtension = ' AND ManagerId =: myId';
            }
            myteam = true;
            userSetController = new ApexPages.StandardSetController(Database.getQueryLocator(baseQuery + ' WHERE IsActive = true ' + 
            queryExtension + ' ORDER BY FirstName'));
            userSetController.setPageSize(pageSize);        
            if(filterId != null){
                userSetController.setFilterId(filterId);
            }       
        }
        
        currentPageNumber = userSetController.getPageNumber();
        String year     = Utilities.grabParameter('year');
        String month    = Utilities.grabParameter('month');
        String filter   = Utilities.grabParameter('filterId');
        String pageNo   = Utilities.grabParameter('page');

        if(!Utilities.isNullOrEmpty(filter) && filterId == null){
            
            // this should not interfere with normal filter behaviour 
            // so if filterId is already set this shouldn't run

            filterId = filter;
            userSetController.setFilterId(filter);
        }
        if(!Utilities.isNullOrEmpty(pageNo) && !pager){
            // pager boolean prevents this from interfering with
            // standard pagination behaviour.
            currentPageNumber = Integer.valueOf(pageNo);
            userSetController.setPageNumber(currentPageNumber);
        }

        // checks if pagination controls should render in view
        pagination      = userSetController.getHasNext() || userSetController.getHasPrevious();
        isFirst         = userSetController.getHasPrevious() ? false : true;
        isLast          = userSetController.getHasNext()     ? false : true;
        
        System.debug(logginglevel.INFO,'=== currentPageNumber: ' + currentPageNumber);
        currentPage     = Utilities.getCurrentPageName();
        
        System.debug(logginglevel.INFO,'=== initCalendar filterId: ' + filterId);
        currentYear         = Utilities.isNullOrEmpty(year)  ? System.Today().Year()  : Integer.valueOf(year);
        currentMonth        = Utilities.isNullOrEmpty(month) ? System.Today().Month() : Integer.valueOf(month);
        currentMonthName    = CalendarHelper.getMonthName(currentMonth, 4);      
        userIds             = UserManager.getUsersId(userSetController);
    }

    /*
    firstPage
    ------------------------
    Purpose: navigates to first page of the usercontroller and reinitializes data
    */
    public PageReference firstPage(){
        userSetController.first();
        pager = true;
        initCalendar();
        pager = false;
        return null;
    }   

    /*
    lastPage
    ------------------------
    Purpose: navigates to last page of the usercontroller and reinitializes data
    */
    public PageReference lastPage(){
        userSetController.last();
        pager = true;
        initCalendar();
        pager = false;
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
            pager = true;
            initCalendar();
            pager = false;
            
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
            pager = true;
            initCalendar();
            pager = false;
            
        }
        return null;
    }

    /*
    resetFilter
    ------------------------
    Purpose: Resets usersetcontroller 
    */    
    public PageReference resetFilter(){
        // Reset userSetController
        userSetController = null;
        userSetController.setPageNumber(1);
        initCalendar();

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
    getCalendar
    ------------------------
    Purpose: Creates a SmartCalendarHelper with needed data for calendar
    Input: none
    Output: SmartCalendarHelper object 
    */
    public SmartCalendarHelper getCalendar(){
        return new SmartCalendarHelper(currentYear, currentMonth, getUsersLeaves(), getUsersLeaveYears() );
    }

    /*
    getUsers
    --------
    Purpose: Gets the user records for the users in the team
    Input: none
    Output: List of users
    */
    public List<User> getUsers(){
        return (List<User>)userSetController.getRecords();
    }

    /*
    getUsersLeaveYears
    --------
    Purpose: Gets a list of EmployeeLeaveYears__c for current users and years
    Input: none
    Output: A list of EmployeeLeaveYears__c 
    */
    public List<EmployeeLeaveYear__c> getUsersLeaveYears(){
        // Gets the User Leave Years records of this year for the users in the userSetController
        return EmployeeLeaveYearManager.getEmployeeLeaveYearByUserIdAndYear(userIds, String.valueOf(currentYear));
    }

    /*
    getUsersLeaves
    ------------------------
    Purpose: Gets a list of UserLeaveWrapper objects each containing a user and a list of it's relevant working pattern and a list of Leaves
    Input: none
    Output: A list of UserLeaveWrapper objects
    */
    public List<UserLeaveWrapper> getUsersLeaves(){

        List<UserLeaveWrapper> usersleaves = new List<UserLeaveWrapper>();
        List<User>  users = UserManager.getUsers(userSetController);
        List<Leave__c> leaves = LeaveManager.getLeaveByUserIdAndMonth(userIds, currentYear, currentMonth, !myteam );
        Date startDate  = CalendarHelper.firstDateInMonth(currentYear, currentMonth);
        Date endDate    = CalendarHelper.lastDateInMonth(currentYear, currentMonth);
        List<EmployeeWorkingPattern__c> patterns = EmployeeWorkingPatternManager.getUserWorkingPatternByIdAndPeriod(userIds, startDate, endDate);
        for(User user : users ){
            UserLeaveWrapper ulw = new UserLeaveWrapper(user, patterns, leaves );
            usersleaves.add(ulw);
        }

        return usersleaves;
    }

}