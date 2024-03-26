/*
Name:  SmartCalendarHelper.cls
Copyright © 2014  Kaptio
======================================================
======================================================
Purpose:
-------
Persentation layer wrapper that contains all information needed for displaying 
smartCalender.component correctly for Leave requests.
======================================================
======================================================
History
------- 
Ver. Author             Date                    Detail
1.0  Halldór Örn      2014-05-13       Class Creation
1.1  Örn Ingvar       2014-08-05       Renamed from CalendarWrapper to SmartCalendarHelper
1.2  J Radcliffe      2020-01-23       Globalisation - Replacing 'Holiday' with 'PublicHoliday__c'. Dynamically display Public Holiday based on user's PublicHolidayGroup__c
*/
public with sharing class SmartCalendarHelper {
    
    public CalendarFilter filter { get; set; }
    public CalendarHeader header { get; set; }
    public Integer currentYear { get; set; }
    public Integer currentMonth { get; set; }
    public String  currentMonthName { get; set; }
    public List<CalendarTableRow> rows { get; set; }
    //public Map<Date, List<Holiday>> holidayMap { get; set; } //1.2-
    public Map<Id,Map<Date,PublicHoliday__c>> usersPublicHolidayMap { get; set; }//1.2+
    public Set<Id> employeeIds { get; set; }//1.2+
    public Map<Id, EmployeeLeaveYear__c> leaveYearMap { get; set; }

    public SmartCalendarHelper( Integer currentYear, Integer currentMonth, List<UserLeaveWrapper> userleaves, List<EmployeeLeaveYear__c> leaveYears) {
        this.currentYear = currentYear;
        this.currentMonth = currentMonth;
        header = new CalendarHeader(currentYear, currentMonth);
        filter = new CalendarFilter(currentYear, currentMonth);
        currentMonthName = CalendarHelper.getMonthName(currentMonth, 4);
        rows = new List<CalendarTableRow>();
        
        employeeIds = new Set<Id>();//1.2+
        if(leaveYears.size()>0){//1.2+
            for(EmployeeLeaveYear__c ely : leaveYears){
                if(!employeeIds.contains(ely.Employee__c)) employeeIds.add(ely.Employee__c);
            }
        }

        getLeaveYearMap(leaveYears);

        Date startDate = Date.newInstance(currentYear, currentMonth, 1);
        Date endDate = CalendarHelper.lastDateInMonth(currentYear, currentMonth);
        //holidayMap = new Map<Date, List<Holiday>>();
        usersPublicHolidayMap = new Map<Id,Map<Date,PublicHoliday__c>>();

        try{
            //holidayMap = CalendarHelper.getPublicHolidaysBetweenDates(startDate, endDate);//1.2-
            usersPublicHolidayMap = CalendarHelper.getAgentsPublicHolidayBetweenDates(startDate,endDate,employeeIds );//1.2+
        }catch(Exception e){
            RuntimeExceptionHelper.logException(e);
        }

        Map<Date,PublicHoliday__c> publicHolidayMap;//1.2+
        for(UserLeaveWrapper ulw : userleaves){
            publicHolidayMap =(ulw != null && ulw.user != null && ulw.user.Id != null && usersPublicHolidayMap != null && usersPublicHolidayMap.containsKey(ulw.user.Id))?usersPublicHolidayMap.get(ulw.user.Id):null;
            //CalendarTableRow ctr = new CalendarTableRow(currentYear, currentMonth, ulw, leaveYearMap, holidayMap);//1.2-
            CalendarTableRow ctr = new CalendarTableRow(currentYear, currentMonth, ulw, leaveYearMap, publicHolidayMap);//1.2+
            rows.add(ctr);
        }
    }

    public void getLeaveYearMap(List<EmployeeLeaveYear__c> leaveYears){
        leaveYearMap = new Map<Id, EmployeeLeaveYear__c>();
        for(EmployeeLeaveYear__c l : leaveYears){
            leaveYearMap.put(l.Employee__c, l);
        }
    }

    /*
    Name:  CalendarFilter            
    Purpose:
    -------
    Wrapper class to create the pagination row above calendar.
    This includes years previous and next to the current one
    And a row containing the months of the current year.
    */
    public class CalendarFilter{
        public Integer currentMonth { get; set; }
        public String prevYear { get; set; }
        public String nextYear { get; set; }
        public List<CalendarMonth> months { get; set; }

        public CalendarFilter(Integer currentYear, Integer currentMonth){
            
            prevYear = String.valueOf(currentYear-1);
            nextYear = String.valueOf(currentYear+1);
            months = new List<CalendarMonth>();

            for(Integer i=1; i<=12; i++){
                String mName    = CalendarHelper.getMonthName(i, 3);
                CalendarMonth m = new CalendarMonth( mName, i, currentMonth );
                months.add(m);
            }
        }
    }

    /*
    Name:  CalendarMonth
    Purpose:
    -------
    Wraps the information needed for a single month in CalendarFilter
    */
    public class CalendarMonth{
        public String monthName { get; set; }
        public Integer monthNumber { get; set; }
        public Boolean isCurrent { get; set; }

        public CalendarMonth(String name, Integer monthNumber, Integer month){
            this.monthName = name;
            this.monthNumber = monthNumber;
            this.isCurrent = month == monthNumber;
        }
    }

    /*
    Name:  CalendarHeader            
    Purpose:
    -------
    This header creates the table header and populates it with the days of the current month.
    */
    public class CalendarHeader{
       public List<CalendarHeaderDay> headerDays { get; set; }

        public CalendarHeader(Integer currentYear, Integer currentMonth){
            
            headerDays = new List<CalendarHeaderDay>();
            Integer numberOfDays = Date.daysInMonth(currentYear, currentMonth);
            
            for(Integer i = 1; i <= numberOfDays; i++){             
                CalendarHeaderDay cd = new CalendarHeaderDay(currentYear, currentMonth, i);
                headerDays.add(cd);
            }
        }
    }

    /*
    Name:  CalendarHeaderDay
    Purpose:
    -------
    Wraps the information needed for a single day header in CalendarHeader
    */
    public class CalendarHeaderDay{
        
        public String weekDay       { get; set; }
        public Integer dateNo       { get; set; }
        public String headerclass   { get; set; }

        public CalendarHeaderDay(Integer year, Integer month, Integer day){
            headerclass = '';
            Date thisDay = Date.newInstance(year, month, day);
            if(thisDay == System.today()){
                headerclass = 'today';
            }
            weekday = CalendarHelper.getDayName(year,month, day, 1);
            dateNo = day;
        }
    }

    /*
    Name:  CalendarTableRow
    Purpose:
    -------
    Wraps the information needed for a single row in the calendar
    */
    public class CalendarTableRow{
        public List<CalendarTableData> data { get; set; }
        public User employee { get; set; }
        public String rowClass { get; set; }
        public String leaveYearId { get; set; }
        public String leaveYearName { get; set; }

        //public CalendarTableRow(Integer year, Integer month, UserLeaveWrapper userleaves, Map<Id, EmployeeLeaveYear__c> leaveYearMap, Map<Date, List<Holiday>> holidayMap ) {//1.2-
        public CalendarTableRow(Integer year, Integer month, UserLeaveWrapper userleaves, Map<Id, EmployeeLeaveYear__c> leaveYearMap, Map<Date, PublicHoliday__c> holidayMap ) { //1.2+
            employee = userleaves.user;
            rowClass = 'userRow';
            if(leaveYearMap.containsKey(employee.Id)){
                EmployeeLeaveYear__c leaveYear = leaveYearMap.get(employee.Id);
                leaveYearId     = leaveYear.Id;
                leaveYearName   = leaveYear.Name;
            }
            
            leaveYearId = Utilities.isNullOrEmpty(leaveYearId) ? '' : leaveYearId;
            leaveYearName = Utilities.isNullOrEmpty(leaveYearName) ? '' : leaveYearName;

            data = new List<CalendarTableData>();
            Integer numberOfDays = Date.daysInMonth(year, month);
            
            for(Integer i = 1; i <= numberOfDays; i++){             
                
                Date today = Date.newInstance(year, month, i );
                //Holiday holiday = new Holiday();//1.2-
                PublicHoliday__c holiday = new PublicHoliday__c();//1.2+
                String holidayName = '';

                if(holidayMap != null){
                    Boolean hasHoliday = holidayMap.containsKey(today) ? true : false;
                    if(hasHoliday){
                        //List<Holiday> h = holidayMap.get(today);//1.2-
                        //holiday = h.get(0);
                        holiday = holidayMap.get(today);//1.2+
                    }
                }
                CalendarTableData td = new CalendarTableData(year, month, i, userleaves.workingPattern, userleaves.leaves, holiday);
                data.add(td);
                if(td.dateClass.contains('hasLeave')){
                    addToRowClass(td.dateClass);
                }
            }
        }

        /*
        addToRowClass
        ------------------------
        Purpose: Evaluates current classes assigned to the date and updates as needed.
        Input: String class
        Output: void
        */
        private Void addToRowClass(String dateClass){
            rowClass +=  !rowClass.contains('hasLeave') ? ' hasLeave' : '';         
            rowClass +=  ( !rowClass.contains('approved')  && dateClass.contains('approved') ) ? ' approved' : '';
            rowClass +=  ( !rowClass.contains('rejected')  && dateClass.contains('rejected') ) ? ' rejected' : '';
            rowClass +=  ( !rowClass.contains('requested') && dateClass.contains('requested') ) ? ' requested' : '';
            rowClass +=  ( !rowClass.contains('cancelled') && dateClass.contains('cancelled') ) ? ' cancelled' : '';
        }
    }
    
    /*
    Name:  CalendarTableData
    Purpose:
    -------
    Wraps the information needed for a single table cell in the calendar
    */
    public class CalendarTableData{
        public String dateClass { get; set; }
        public Date dateString { get; set; }
        public String note { get; set; }
        public String title { get; set; }
        public Boolean showControls { get; set; }
        public Boolean dayOff { get; set; }
        public String leaveId { get; set; }
        public String period { get; set; }
        public Boolean hasHoliday { get; set; }
        public Boolean halfdayHoliday { get; set; }
        public PublicHoliday__c publicHoliday {get;set;}
        
        //public CalendarTableData( Integer year, Integer month, Integer day, List<EmployeeWorkingPattern__c> patterns, List<Leave__c> leaves, Holiday holiday) {//1.2-
        public CalendarTableData( Integer year, Integer month, Integer day, List<EmployeeWorkingPattern__c> patterns, List<Leave__c> leaves, PublicHoliday__c holiday) {//1.2+

            showControls = false;
            dayOff = false;
            String dayOfweek = CalendarHelper.getDayName(year,month, day, 4);
            Date today = Date.newInstance(year, month, day);
            dateString = today;
            dateClass = '';
            note = 'Create a new leave Request';
            title = 'New Request';
            period = '';
            this.hasHoliday = (holiday != null && holiday.Id != null);
            this.halfdayHoliday = false;
            this.publicHoliday = holiday;

            // First we add the base class - weekend or weekday;
            if(dayOfweek == 'Saturday' || dayOfweek == 'Sunday'){
                dateClass += 'weekend';
            } else {
                dateClass += 'weekday';
            }

            if(today == System.today()){
                dateClass += ' today';
            }

            if(!Utilities.isNullOrEmpty(patterns)) {
                dayOff = !EmployeeWorkingPatternManager.isWorkingDay(patterns, Date.newInstance(year, month, day) );
                dateClass += dayOff ? ' workingPattern approved hasLeave dayOff' : ' workingPattern workday';
                note = dayOff ? 'Non working day' : note;
                title = dayOff? 'Public Note' : title;
            }

            // If today is a holiday only holiday class is needed.
            if(hasHoliday){
                dateClass += ' holiday';
                title = 'Public Holiday';
                note = holiday.Name;
                //this.halfdayHoliday = !holiday.IsAllDay;//1.2-
                this.halfdayHoliday = !holiday.IsAllDay__c;//1.2+
                // Christmas Eve and New Years Day are half days
                if(this.halfdayHoliday){
                    if(publicHoliday.AM_or_PM__c.containsIgnoreCase('AM')){//1.2+
                        dateClass += ' am';
                    }else{
                        dateClass += ' pm';
                    }
                }
            } //else {
                if(!Utilities.isNullOrEmpty(leaves)){
                    for(Leave__c l : leaves ){
                        if( l.StartDate__c <= today && l.EndDate__c >= today ) {
                            dayOff = true;
                            dateClass += l.Status__c.contains('approval') ? ' requested' : ' ' + l.Status__c.toLowerCase();
                            dateClass +=' hasLeave'; 
                            
                            if(l.LeaveType__c == ApplicationConstant.LEAVE_TYPE_WELLNESS_DAY) dateClass += ' well-being';

                            // Check if Half day
                            if( today == l.StartDate__c ){
                                if( !l.AM__c && l.PMStart__c && !hasHoliday ){
                                    dateClass += ' pm';
                                } else if ( !l.PMStart__c && l.AM__c && !hasHoliday ){
                                    dateClass += ' am';
                                }
                            }
                            if( today != l.StartDate__c && today == l.EndDate__c && !l.PMReturn__c && l.AM__c && !hasHoliday){
                                dateClass += ' am';
                            }

                            if(dateClass.contains('requested')){
                                showControls = true;
                                dayOff = false;
                            }

                            leaveId = l.Id;
                            note = showControls ? l.EmployeeComment__c : l.PublicNote__c;
                            title = showControls ? 'Employee Comment' : 'Public Note';
                            
                            period = Datetime.newInstance(l.StartDate__c, Time.newInstance(0,0,0, 0)).format('d MMM YYYY');

                            if( l.StartDate__c != l.EndDate__c ){
                                period += ' - ' + Datetime.newInstance(l.EndDate__c, Time.newInstance(0,0,0, 0)).format('d MMM YYYY') ;
                            } 
                        }
                    }
                } 
            //}
        }
    }
}