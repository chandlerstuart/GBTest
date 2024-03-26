/*
Class:  WIREAgentLeaveQueryableTestSuite.cls
Copyright © 2018  Golfbreaks
======================================================
======================================================
Purpose:
-------
Suite of unit tests that exercise (and verify) code behaviour related to core WIREAgentLeaveQueryable functions.

Coverage for classes below (target 85%):
WIREAgentLeaveQueryableTestSuite.cls : 100%

======================================================
======================================================
Revision History
---------------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2018-07-30  Initial development (singleTestCase1-3).
1.1  J Radcliffe   2020-01-16  Extended to test globalisation of Leave Query
1.2  J Radcliffe   2020-02-06  Start/End Dates required for Employee Leave Year following Globalisation
1.3  J Radcliffe   2020-02-06  New Test Methods (singleTestCase 6-9)
2.1  J Radcliffe   2020-05-11  Multiple alterations to test new logic*
2.2  J Radcliffe   2023-05-12  New test methods for half day routing singleTestCase10a, singleTestCase10b, singleTestCase10c, singleTestCase11
2.3  J Radcliffe   2024-01-30  Check the leave data is accessible in the data maps after execution.

*Previously the 'onLeave' agents would include a cumulative total of those on leave today and (if the threshold has lapsed) those on leave tomorrow. Now it will be one or the other depending on the configuration. 
 If the threshold has lapsed (based on their local timezone), and isIncludeNextDay is true, the code will return a list of agents on leave the following day, else it will return a list of agents on leave the same day (never both).

*/
@isTest 
private class WIREAgentLeaveQueryableTestSuite {     
    /*
    Test cases:
        singleTestCase1 - Business Logic. 1 Agent on leave today, 1 Agent not on leave.
        singleTestCase2a - Business Logic. 1 Agent on leave tomorrow; time is before cut-off. On leave=false.
        singleTestCase2b - Business Logic. 1 Agent on leave tomorrow; time is after cut-off. On leave=true.
        singleTestCase4 - Business Logic. 2 Agents on leave on the same date (Tomorrow's Date UTC). The Date is relative to the user's local time. Current time = 2pm UTC. UK Agent is still on Leave on specified date, whilst NZ Agent is back to work that day (2am) //1.1+
        singleTestCase5 - Business Logic. 2 Agents on leave on the next day (Tomorrow's Date UTC). 1 Agent in the UK and 1 in the US. Confirm the system only begins to check next day availability at 5pm relative to the user's local time. //1.1+   
        singleTestCase6 - Business Logic. 1 Agent on company leave today, 1 Agent not on company leave.
        singleTestCase7a - Business Logic. 1 Agent on company leave tomorrow; time is before cut-off. On company leave=false.
        singleTestCase7b - Business Logic. 1 Agent on company leave tomorrow; time is after cut-off. On company leave=true.
        singleTestCase8 - Business Logic. 2 Agents on company leave on the same date (Tomorrow's Date UTC). The Date is relative to the user's local time. Current time = 2pm UTC. UK Agent is still on company Leave on specified date, whilst NZ Agent is back to work that day (2am) 
        singleTestCase9 - Business Logic. 2 Agents on company leave on the next day (Tomorrow's Date UTC). 1 Agent in the UK and 1 in the US. Confirm the system only begins to check next day availability at 5pm relative to the user's local time.
        singleTestCase10a - Business Logic. 1 Agent on leave today (am only). Confirm the agent is only considered absent in the morning.
        singleTestCase10b - Business Logic. 1 Agent on leave today (am only) and then has a second leave request for the same day (pm)
        singleTestCase10c - Business Logic. 2 Agents on leave today (am only). For one, it is the afternoon (UK). For the other, it is the morning (US). Only the US should be considered absent if the time is 13:30pm UTC.
        singleTestCase11 - Business Logic. 1 Agent on leave tomorrow (pm only). Confirm the agent is only considered absent if they are on leave the next morning.
    
    */
    
    @testSetup
    static void setup(){       
        User agent1, agent2,agent3,agent4;
                
        System.runAs(new User(Id=UserInfo.getUserId())){//avoid mixed dml exception. 
            List<User> agents = new List<User>();         
            agent1 = UserTestHelper.createStandardUsers(1, 'Agent1', 'Test',false)[0];
            agent2 = UserTestHelper.createStandardUsers(1, 'Agent2', 'Test',false)[0];            
            agent3 = UserTestHelper.createStandardUsers(1,'Agent3','Test',false)[0];   //1.1+
            agent3.TimezoneSidKey = 'America/New_York';//US Agent (GMT -4hr)   
            agent4 = UserTestHelper.createStandardUsers(1,'Agent4','Test',false)[0];   //1.1+
            agent4.TimezoneSidKey = 'Pacific/Auckland';//US Agent (GMT +12hr)   

            agents.add(agent1);
            agents.add(agent2);
            agents.add(agent3);
            agents.add(agent4);

            insert agents;    
        }    
        
        //2.2+ - Configure half day leave settings
        insert new GBWire__RoutingEngineSettings__c(GBWire__HalfDayAvailabilityStartHour__c=13,GBWire__HalfDayAvailabilityStopHour__c=11);
    }

    /* **/    
    static testMethod void singleTestCase1() {
        // Test Case 1 : Business Logic. 1 Agent on leave today, 1 Agent not on leave.

        Id agent1Id = [select Id from User where FirstName like 'Agent1%' and LastName like 'Test%' limit 1][0].Id;
        Id agent2Id = [select Id from User where FirstName like 'Agent2%' and LastName like 'Test%' limit 1][0].Id;
        
        System.debug(LoggingLevel.ERROR, 'singleTestCase1>agent1Id:'+agent1Id);
        System.debug(LoggingLevel.ERROR, 'singleTestCase1>agent2Id:'+agent2Id);

        Date yearStart = Date.newInstance(System.today().year(), 1, 1);//1.2+
        Date yearEnd = Date.newInstance(System.today().year(), 12, 31);//1.2+
        
        EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Employee Leave Year Test',Employee__c=agent1Id, Year__c = String.valueOf(System.today().year()),StartDate__c=yearStart,EndDate__c=yearEnd);
        insert leaveYear;
        
        Leave__c l = new Leave__c(Employee__c=agent1Id, StartDate__c=System.today(), EndDate__c=System.today().addDays(2), Status__c='approved', EmployeeLeaveYear__c=leaveYear.Id);
        insert l;
        
        WIREAgentLeaveQueryable alq = new WIREAgentLeaveQueryable(); 
        
        Set<Id> agentsOnLeave = alq.getAgentsOnLeave(new Set<Id> { agent1Id, agent2Id }, false, null);
        
        System.assert(agentsOnLeave.contains(agent1Id));
        System.assert(!agentsOnLeave.contains(agent2Id));

        //2.3+
        System.assertEquals(1, alq.agentsOnLeaveMap.keySet().size());
        system.assertEquals(true,alq.agentsOnLeaveMap.keySet().contains(agent1Id));
        system.assertEquals(l.Id,alq.agentsOnLeaveMap.values()[0].Id);
    }
    /* */ 
    
    /* **/    
    static testMethod void singleTestCase2() {
        // Test Case 2 : Business Logic. 1 Agent on leave tomorrow; time is before cut-off. On leave=false.

        Id agent1Id = [select Id from User where FirstName like 'Agent1%' and LastName like 'Test%' limit 1][0].Id;
        
        System.debug(LoggingLevel.ERROR, 'singleTestCase1>agent1Id:'+agent1Id);

        Date yearStart = Date.newInstance(System.today().addDays(1).year(), 1, 1);//1.2+
        Date yearEnd = Date.newInstance(System.today().addDays(1).year(), 12, 31);//1.2+
        
        EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Employee Leave Year Test',Employee__c=agent1Id, Year__c = String.valueOf(System.today().addDays(1).year()),StartDate__c=yearStart,EndDate__c=yearEnd);
        insert leaveYear;
        
        Leave__c l = new Leave__c(Employee__c=agent1Id, AM__c=true, PMStart__c=true, StartDate__c=System.today().addDays(1), EndDate__c=System.today().addDays(3), Status__c='approved', EmployeeLeaveYear__c=leaveYear.Id);
        insert l;
        
        WIREAgentLeaveQueryable.currentDateTimeOverride = Datetime.newInstanceGmt(System.today().year(),System.today().month(),System.today().day(),16,30,0);//<---- 16.30 //2.1~ agent1Id is in Europe/London TZ - Changing from 17 to 16 to factor in DST
        
        WIREAgentLeaveQueryable alq = new WIREAgentLeaveQueryable();
        
        Set<Id> agentsOnLeave = alq.getAgentsOnLeave(new Set<Id> { agent1Id }, true, 18);//<---- 18:00        
        
        System.assert(!agentsOnLeave.contains(agent1Id));

        //2.3+
        System.assertEquals(0, alq.agentsOnLeaveMap.keySet().size());

    }
    /* */
    
    /* **/    
    static testMethod void singleTestCase3() {
        // Test Case 3 : Business Logic. 1 Agent on leave tomorrow; time is after cut-off. On leave=true.

        Id agent1Id = [select Id from User where FirstName like 'Agent1%' and LastName like 'Test%' limit 1][0].Id;
        
        System.debug(LoggingLevel.ERROR, 'singleTestCase1>agent1Id:'+agent1Id);

        Date yearStart = Date.newInstance(System.today().addDays(1).year(), 1, 1);//1.2+
        Date yearEnd = Date.newInstance(System.today().addDays(1).year(), 12, 31);//1.2+
        
        EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Employee Leave Year Test',Employee__c=agent1Id, Year__c = String.valueOf(System.today().addDays(1).year()),StartDate__c=yearStart,EndDate__c=yearEnd);
        insert leaveYear;
        
        Leave__c l = new Leave__c(Employee__c=agent1Id, AM__c=true, PMStart__c=true, StartDate__c=System.today().addDays(1), EndDate__c=System.today().addDays(3), Status__c='approved', EmployeeLeaveYear__c=leaveYear.Id);
        insert l;
        
        WIREAgentLeaveQueryable.currentDateTimeOverride = Datetime.newInstanceGmt(System.today().year(),System.today().month(),System.today().day(),17,30,0);//<---- 17.30
        
        WIREAgentLeaveQueryable alq = new WIREAgentLeaveQueryable();
        
        Set<Id> agentsOnLeave = alq.getAgentsOnLeave(new Set<Id> { agent1Id }, true, 17);//<---- 17:00        
        
        System.assert(agentsOnLeave.contains(agent1Id));

        //2.3+
        System.assertEquals(1, alq.agentsOnLeaveMap.keySet().size());
        system.assertEquals(true,alq.agentsOnLeaveMap.keySet().contains(agent1Id));
        system.assertEquals(l.Id,alq.agentsOnLeaveMap.values()[0].Id);
    }
    /* */      

    //1.1+ 
    static testMethod void singleTestCase4() {
        // Test Case 4 : Business Logic. 2 Agents on leave on the same date (Today's Date UTC). The Date is relative to the user's local time. Current time = 2pm UTC. UK Agent is still on Leave on specified date, whilst NZ Agent is back to work that day (3am)

        Id agent1Id = [select Id from User where FirstName like 'Agent1%' and LastName like 'Test%' limit 1][0].Id;//UK
        Id agent4Id = [select Id from User where FirstName like 'Agent4%' and LastName like 'Test%' limit 1][0].Id;//NZ (+12hrs)
        
        System.debug(LoggingLevel.ERROR, 'singleTestCase4>agent1Id:'+agent1Id);
        System.debug(LoggingLevel.ERROR, 'singleTestCase4>agent4Id:'+agent4Id);

        Date yearStart = Date.newInstance(System.today().year(), 1, 1);//1.2+
        Date yearEnd = Date.newInstance(System.today().year(), 12, 31);//1.2+
        
        EmployeeLeaveYear__c leaveYear1 = new EmployeeLeaveYear__c(Name='Employee Leave Year Test 1',Employee__c=agent1Id, Year__c = String.valueOf(System.today().year()),StartDate__c=yearStart,EndDate__c=yearEnd);
        EmployeeLeaveYear__c leaveYear2 = new EmployeeLeaveYear__c(Name='Employee Leave Year Test 2',Employee__c=agent4Id, Year__c = String.valueOf(System.today().year()),StartDate__c=yearStart,EndDate__c=yearEnd);

        List<EmployeeLeaveYear__c> leaveYears = new List<EmployeeLeaveYear__c>{leaveYear1,leaveYear2};        

        insert leaveYears;
        
        Leave__c l1 = new Leave__c(Employee__c=agent1Id, AM__c=true, PMStart__c=true, StartDate__c=System.today(), EndDate__c=System.today(), Status__c='approved', EmployeeLeaveYear__c=leaveYears[0].Id);
        Leave__c l2 = new Leave__c(Employee__c=agent4Id, AM__c=true, PMStart__c=true, StartDate__c=System.today(), EndDate__c=System.today(), Status__c='approved', EmployeeLeaveYear__c=leaveYears[1].Id);

        List<Leave__c> leave = new List<Leave__c>{l1,l2};

        insert leave;

        system.assertEquals(leave[0].StartDate__c, leave[1].StartDate__c);
        system.assertEquals(leave[0].EndDate__c, leave[1].EndDate__c);
        
        WIREAgentLeaveQueryable.currentDateTimeOverride = Datetime.newInstanceGmt(System.today().year(),System.today().month(),System.today().day(),14,0,0);//<---- 14:00 (UTC) (03:00 NZ)
        
        WIREAgentLeaveQueryable alq = new WIREAgentLeaveQueryable();
        
        Set<Id> agentsOnLeave = alq.getAgentsOnLeave(new Set<Id> { agent1Id, agent4Id }, true, null);     
        
        System.assert(agentsOnLeave.contains(agent1Id));
        System.assert(!agentsOnLeave.contains(agent4Id));

        //2.3+
        System.assertEquals(1, alq.agentsOnLeaveMap.keySet().size());
        system.assertEquals(true,alq.agentsOnLeaveMap.keySet().contains(agent1Id));
        system.assertEquals(l1.Id,alq.agentsOnLeaveMap.values()[0].Id);

        //Add Leave for next day for the NZ agent and confirm that both are now returned.
        Leave__c l3 = new Leave__c(Employee__c=agent4Id, StartDate__c=System.today().addDays(1), EndDate__c=System.today().addDays(1), Status__c='approved', EmployeeLeaveYear__c=leaveYears[1].Id);
        insert l3;

        agentsOnLeave = alq.getAgentsOnLeave(new Set<Id> { agent1Id, agent4Id }, true, null);
        
        System.assert(agentsOnLeave.contains(agent1Id));
        System.assert(agentsOnLeave.contains(agent4Id));

        //2.3+
        System.assertEquals(2, alq.agentsOnLeaveMap.keySet().size());
        system.assertEquals(true,alq.agentsOnLeaveMap.keySet().contains(agent1Id));
        system.assertEquals(true,alq.agentsOnLeaveMap.keySet().contains(agent4Id));
        system.assertEquals(l1.Id,alq.agentsOnLeaveMap.get(agent1Id).Id);
        system.assertEquals(l3.Id,alq.agentsOnLeaveMap.get(agent4Id).Id);
    }
    /* */      

    //1.1+
    static testMethod void singleTestCase5() {
        // Test Case 5 : Business Logic. 2 Agents on leave on the next day (Tomorrow's Date UTC). 1 Agent in the UK and 1 in the US. The system will start to check next day availability at 5pm (relative to the user's local time). 
        //Current time = 6pm UTC. UK Agent's next day availability should be checked (considered 'on leave'), whereas the US is 4 hours behind and should ignore next days availability.

        Id agent1Id = [select Id from User where FirstName like 'Agent1%' and LastName like 'Test%' limit 1][0].Id;//UK
        Id agent3Id = [select Id from User where FirstName like 'Agent3%' and LastName like 'Test%' limit 1][0].Id;//USA (-4hrs)
        
        System.debug(LoggingLevel.ERROR, 'singleTestCase5>agent1Id:'+agent1Id);//1.2+
        System.debug(LoggingLevel.ERROR, 'singleTestCase5>agent3Id:'+agent3Id);//1.2+

        Date yearStart = Date.newInstance(System.today().year(), 1, 1);
        Date yearEnd = Date.newInstance(System.today().year(), 12, 31);
        
        EmployeeLeaveYear__c leaveYear1 = new EmployeeLeaveYear__c(Name='Employee Leave Year Test 1',Employee__c=agent1Id, Year__c = String.valueOf(System.today().addDays(1).year()),StartDate__c=yearStart,EndDate__c=yearEnd);
        EmployeeLeaveYear__c leaveYear2 = new EmployeeLeaveYear__c(Name='Employee Leave Year Test 2',Employee__c=agent3Id, Year__c = String.valueOf(System.today().addDays(1).year()),StartDate__c=yearStart,EndDate__c=yearEnd);

        List<EmployeeLeaveYear__c> leaveYears = new List<EmployeeLeaveYear__c>{leaveYear1,leaveYear2};        

        insert leaveYears;
        
        Leave__c l1 = new Leave__c(Employee__c=agent1Id, AM__c=true, PMStart__c=true, StartDate__c=System.today().addDays(1), EndDate__c=System.today().addDays(1), Status__c='approved', EmployeeLeaveYear__c=leaveYears[0].Id);
        Leave__c l2 = new Leave__c(Employee__c=agent3Id, AM__c=true, PMStart__c=true, StartDate__c=System.today().addDays(1), EndDate__c=System.today().addDays(1), Status__c='approved', EmployeeLeaveYear__c=leaveYears[1].Id);

        List<Leave__c> leave = new List<Leave__c>{l1,l2};

        insert leave;

        system.assertEquals(leave[0].StartDate__c, leave[1].StartDate__c);
        system.assertEquals(leave[0].EndDate__c, leave[1].EndDate__c);
        
        WIREAgentLeaveQueryable.currentDateTimeOverride = Datetime.newInstanceGmt(System.today().year(),System.today().month(),System.today().day(),18,0,0);//<---- 18:00 (UTC) (13:00 US)
        
        WIREAgentLeaveQueryable alq = new WIREAgentLeaveQueryable();
        
        Set<Id> agentsOnLeave = alq.getAgentsOnLeave(new Set<Id> { agent1Id, agent3Id }, true, 17); //<---- 17:00 next day availability check time    
        
        //Both Agents are on AL Next Day
        System.assert(agentsOnLeave.contains(agent1Id));//UK Agent is considered on AL
        System.assert(!agentsOnLeave.contains(agent3Id));//US Next Day leave is ignored


        //Change current date time to +4 hours - Confirm next day availability is now checked for US agent also

        WIREAgentLeaveQueryable.currentDateTimeOverride = Datetime.newInstanceGmt(System.today().year(),System.today().month(),System.today().day(),23,0,0);//<---- 23:00 (UTC) (18:00 US)

        agentsOnLeave = alq.getAgentsOnLeave(new Set<Id> { agent1Id, agent3Id }, true, 17); //<---- 17:00 next day availability check time (same as before)   
        
        //Next Day Availability is checked for both Agents
        System.assert(agentsOnLeave.contains(agent1Id));
        System.assert(agentsOnLeave.contains(agent3Id));

    }

    /* **/    
    static testMethod void singleTestCase6() {
        // Test Case 1 : Business Logic. 1 Agent on company leave today, 1 Agent not on company leave.

        Id agent1Id = [select Id from User where FirstName like 'Agent1%' and LastName like 'Test%' limit 1][0].Id;
        Id agent2Id = [select Id from User where FirstName like 'Agent2%' and LastName like 'Test%' limit 1][0].Id;
        
        System.debug(LoggingLevel.ERROR, 'singleTestCase6>agent1Id:'+agent1Id);
        System.debug(LoggingLevel.ERROR, 'singleTestCase6>agent2Id:'+agent2Id);

        Date yearStart = Date.newInstance(System.today().year(), 1, 1);//1.2+
        Date yearEnd = Date.newInstance(System.today().year(), 12, 31);//1.2+

        PublicHolidayGroup__c phg1 = CalendarTestHelper.createPublicHolidayGroupsWithHoliday(1,1,System.today(),System.today())[0];//Has Company Holiday Today
        
        EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Employee Leave Year Test', Employee__c=agent1Id, Year__c = String.valueOf(System.today().year()),StartDate__c=yearStart,EndDate__c=yearEnd, PublicHolidayGroup__c=phg1.Id);
        insert leaveYear;
        
        WIREAgentLeaveQueryable alq = new WIREAgentLeaveQueryable(); 
        
        Set<Id> agentsOnLeave = alq.getAgentsOnCompanyHoliday(new Set<Id> { agent1Id, agent2Id }, false, null);
        
        System.assert(agentsOnLeave.contains(agent1Id));
        System.assert(!agentsOnLeave.contains(agent2Id));

        //2.3+
        System.assertEquals(1, alq.agentsOnCompanyLeaveMap.keySet().size());
        system.assertEquals(true,alq.agentsOnCompanyLeaveMap.keySet().contains(agent1Id));
        system.assertEquals(phg1.PublicHolidays__r[0].Id,alq.agentsOnCompanyLeaveMap.values()[0].Id);
    }
    /* */ 
    
    /* **/    
    static testMethod void singleTestCase7a() {
        // Test Case 2 : Business Logic. 1 Agent on company leave tomorrow; time is before cut-off. On leave=false.

        Id agent1Id = [select Id from User where FirstName like 'Agent1%' and LastName like 'Test%' limit 1][0].Id;
        
        System.debug(LoggingLevel.ERROR, 'singleTestCase7a>agent1Id:'+agent1Id);

        Date yearStart = Date.newInstance(System.today().addDays(1).year(), 1, 1);//1.2+
        Date yearEnd = Date.newInstance(System.today().addDays(1).year(), 12, 31);//1.2+

        PublicHolidayGroup__c phg1 = CalendarTestHelper.createPublicHolidayGroupsWithHoliday(1,1,System.today().addDays(1),System.today().addDays(1))[0];//Has Company Holiday Tomorrow
        
        EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Employee Leave Year Test', Employee__c=agent1Id, Year__c = String.valueOf(System.today().addDays(1).year()),StartDate__c=yearStart,EndDate__c=yearEnd,PublicHolidayGroup__c=phg1.Id);
        insert leaveYear;
        
        WIREAgentLeaveQueryable.currentDateTimeOverride = Datetime.newInstanceGmt(System.today().year(),System.today().month(),System.today().day(),16,30,0);//<---- 16.30 //2.1~ agent1Id is in Europe/London TZ - Changing from 17 to 16 to factor in DST
        
        WIREAgentLeaveQueryable alq = new WIREAgentLeaveQueryable();
        
        Set<Id> agentsOnLeave = alq.getAgentsOnCompanyHoliday(new Set<Id> { agent1Id }, true, 18);//<---- 18:00        
        
        System.assert(!agentsOnLeave.contains(agent1Id));

        //2.3+
        System.assertEquals(0, alq.agentsOnCompanyLeaveMap.keySet().size());
    }
    /* */
    
    /* **/    
    static testMethod void singleTestCase7b() {
        // Test Case 3 : Business Logic. 1 Agent on company leave tomorrow; time is after cut-off. On leave=true.

        Id agent1Id = [select Id from User where FirstName like 'Agent1%' and LastName like 'Test%' limit 1][0].Id;
        
        System.debug(LoggingLevel.ERROR, 'singleTestCase7b>agent1Id:'+agent1Id);

        Date yearStart = Date.newInstance(System.today().addDays(1).year(), 1, 1);//1.2+
        Date yearEnd = Date.newInstance(System.today().addDays(1).year(), 12, 31);//1.2+

        PublicHolidayGroup__c phg1 = CalendarTestHelper.createPublicHolidayGroupsWithHoliday(1,1,System.today().addDays(1),System.today().addDays(1))[0];//Has Company Holiday Tomorrow
        
        EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Employee Leave Year Test', Employee__c=agent1Id, Year__c = String.valueOf(System.today().addDays(1).year()),StartDate__c=yearStart,EndDate__c=yearEnd,PublicHolidayGroup__c=phg1.Id);
        insert leaveYear;
                
        WIREAgentLeaveQueryable.currentDateTimeOverride = Datetime.newInstanceGmt(System.today().year(),System.today().month(),System.today().day(),17,30,0);//<---- 17.30
        
        WIREAgentLeaveQueryable alq = new WIREAgentLeaveQueryable();
        
        Set<Id> agentsOnLeave = alq.getAgentsOnCompanyHoliday(new Set<Id> { agent1Id }, true, 17);//<---- 17:00        
        
        System.assert(agentsOnLeave.contains(agent1Id));

        //2.3+
        System.assertEquals(1, alq.agentsOnCompanyLeaveMap.keySet().size());
        system.assertEquals(true,alq.agentsOnCompanyLeaveMap.keySet().contains(agent1Id));
        system.assertEquals(phg1.PublicHolidays__r[0].Id,alq.agentsOnCompanyLeaveMap.values()[0].Id);
    }
    /* */      

    //1.1+
    static testMethod void singleTestCase8() {
        // Test Case 4 : Business Logic. 2 Agents on company leave on the same date (Today's Date UTC). The Date is relative to the user's local time. Current time = 2pm UTC. UK Agent is still on Leave on specified date, whilst NZ Agent is back to work that day (3am)

        Id agent1Id = [select Id from User where FirstName like 'Agent1%' and LastName like 'Test%' limit 1][0].Id;//UK
        Id agent4Id = [select Id from User where FirstName like 'Agent4%' and LastName like 'Test%' limit 1][0].Id;//NZ (+12hrs)
        
        System.debug(LoggingLevel.ERROR, 'singleTestCase8>agent1Id:'+agent1Id);
        System.debug(LoggingLevel.ERROR, 'singleTestCase8>agent4Id:'+agent4Id);

        Date yearStart = Date.newInstance(System.today().year(), 1, 1);//1.2+
        Date yearEnd = Date.newInstance(System.today().year(), 12, 31);//1.2+

        PublicHolidayGroup__c phg1 = CalendarTestHelper.createPublicHolidayGroupsWithHoliday(1,1,System.today(),System.today())[0];//Has Company Holiday Today
        
        EmployeeLeaveYear__c leaveYear1 = new EmployeeLeaveYear__c(Name='Employee Leave Year Test 1', Employee__c=agent1Id, Year__c = String.valueOf(System.today().year()),StartDate__c=yearStart,EndDate__c=yearEnd,PublicHolidayGroup__c=phg1.Id);
        EmployeeLeaveYear__c leaveYear2 = new EmployeeLeaveYear__c(Name='Employee Leave Year Test 2', Employee__c=agent4Id, Year__c = String.valueOf(System.today().year()),StartDate__c=yearStart,EndDate__c=yearEnd,PublicHolidayGroup__c=phg1.Id);

        List<EmployeeLeaveYear__c> leaveYears = new List<EmployeeLeaveYear__c>{leaveYear1,leaveYear2};        

        insert leaveYears;
                
        WIREAgentLeaveQueryable.currentDateTimeOverride = Datetime.newInstanceGmt(System.today().year(),System.today().month(),System.today().day(),14,0,0);//<---- 14:00 (UTC) (03:00 NZ)
        
        WIREAgentLeaveQueryable alq = new WIREAgentLeaveQueryable();
        
        Set<Id> agentsOnLeave = alq.getAgentsOnCompanyHoliday(new Set<Id> { agent1Id, agent4Id }, true, null);     
        
        System.assert(agentsOnLeave.contains(agent1Id));
        System.assert(!agentsOnLeave.contains(agent4Id));

        //Add Public Holiday for next day and confirm that both are now returned.
        insert new PublicHoliday__c(Date__c=System.today().addDays(1), PublicHolidayGroup__c=phg1.Id,Name='Tomorrow Holiday');
        
        agentsOnLeave = alq.getAgentsOnCompanyHoliday(new Set<Id> { agent1Id, agent4Id }, true, null);
        
        System.assert(agentsOnLeave.contains(agent1Id));
        System.assert(agentsOnLeave.contains(agent4Id));
    }
    /* */      

    //1.1+
    static testMethod void singleTestCase9() {
        // Test Case 5 : Business Logic. 2 Agents on company leave on the next day (Tomorrow's Date UTC). 1 Agent in the UK and 1 in the US. The system will start to check next day availability at 5pm (relative to the user's local time). 
        //Current time = 6pm UTC. UK Agent's next day availability should be checked (considered 'on leave'), whereas the US is 4 hours behind and should ignore next days availability.

        Id agent1Id = [select Id from User where FirstName like 'Agent1%' and LastName like 'Test%' limit 1][0].Id;//UK
        Id agent3Id = [select Id from User where FirstName like 'Agent3%' and LastName like 'Test%' limit 1][0].Id;//USA (-4hrs)
        
        System.debug(LoggingLevel.ERROR, 'singleTestCase9>agent1Id:'+agent1Id);//1.2+
        System.debug(LoggingLevel.ERROR, 'singleTestCase9>agent3Id:'+agent3Id);//1.2+

        Date yearStart = Date.newInstance(System.today().year(), 1, 1);
        Date yearEnd = Date.newInstance(System.today().year(), 12, 31);

        PublicHolidayGroup__c phg1 = CalendarTestHelper.createPublicHolidayGroupsWithHoliday(1,1,System.today().addDays(1),System.today().addDays(1))[0];//Has Company Holiday Tomorrow
        
        EmployeeLeaveYear__c leaveYear1 = new EmployeeLeaveYear__c(Name='Employee Leave Year Test 1', Employee__c=agent1Id, Year__c = String.valueOf(System.today().addDays(1).year()),StartDate__c=yearStart,EndDate__c=yearEnd,PublicHolidayGroup__c=phg1.Id);
        EmployeeLeaveYear__c leaveYear2 = new EmployeeLeaveYear__c(Name='Employee Leave Year Test 2', Employee__c=agent3Id, Year__c = String.valueOf(System.today().addDays(1).year()),StartDate__c=yearStart,EndDate__c=yearEnd,PublicHolidayGroup__c=phg1.Id);

        List<EmployeeLeaveYear__c> leaveYears = new List<EmployeeLeaveYear__c>{leaveYear1,leaveYear2};        

        insert leaveYears;
        
        WIREAgentLeaveQueryable.currentDateTimeOverride = Datetime.newInstanceGmt(System.today().year(),System.today().month(),System.today().day(),18,0,0);//<---- 18:00 (UTC) (13:00 US)
        
        WIREAgentLeaveQueryable alq = new WIREAgentLeaveQueryable();
        
        Set<Id> agentsOnLeave = alq.getAgentsOnCompanyHoliday(new Set<Id> { agent1Id, agent3Id }, true, 17); //<---- 17:00 next day availability check time    
        
        //Both Agents are on AL Next Day
        System.assert(agentsOnLeave.contains(agent1Id));//UK Agent is considered on AL
        System.assert(!agentsOnLeave.contains(agent3Id));//US Next Day leave is ignored


        //Change current date time to +4 hours - Confirm next day availability is now checked for US agent also

        WIREAgentLeaveQueryable.currentDateTimeOverride = Datetime.newInstanceGmt(System.today().year(),System.today().month(),System.today().day(),23,0,0);//<---- 23:00 (UTC) (18:00 US)

        agentsOnLeave = alq.getAgentsOnCompanyHoliday(new Set<Id> { agent1Id, agent3Id }, true, 17); //<---- 17:00 next day availability check time (same as before)   
        
        //Next Day Availability is checked for both Agents
        System.assert(agentsOnLeave.contains(agent1Id));
        System.assert(agentsOnLeave.contains(agent3Id));

    }
    /* */  

    static testMethod void singleTestCase10a(){
        // Test Case 10a : Business Logic. 1 Agent on leave today (am only).

        //Two UK agents
        Id agent1Id = [select Id from User where FirstName like 'Agent1%' and LastName like 'Test%' limit 1][0].Id;
        Id agent2Id = [select Id from User where FirstName like 'Agent2%' and LastName like 'Test%' limit 1][0].Id;
        
        System.debug(LoggingLevel.ERROR, 'singleTestCase1>agent1Id:'+agent1Id);
        System.debug(LoggingLevel.ERROR, 'singleTestCase1>agent2Id:'+agent2Id);

        Date yearStart = Date.newInstance(System.today().year(), 1, 1);//1.2+
        Date yearEnd = Date.newInstance(System.today().year(), 12, 31);//1.2+
        
        //Create employee leave for the first agent (only)
        EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Employee Leave Year Test', Employee__c=agent1Id, Year__c = String.valueOf(System.today().year()),StartDate__c=yearStart,EndDate__c=yearEnd);
        insert leaveYear;
        
        //agent1 is on leave in the am and returning to work in the pm
        Leave__c l = new Leave__c(Employee__c=agent1Id, AM__c=true, PMStart__c=false, PMReturn__c=false,StartDate__c=System.today(), EndDate__c=System.today(), Status__c='approved', EmployeeLeaveYear__c=leaveYear.Id);
        insert l;
        
        WIREAgentLeaveQueryable alq = new WIREAgentLeaveQueryable(); 
        
        //Test today's routing, current dt = am
        WIREAgentLeaveQueryable.currentDateTimeOverride = DateTime.newInstanceGMT(System.today().year(),System.today().month(),System.today().day(),11,00,00);//AM (11am GMT or 12pm BST)
        Set<Id> agentsOnLeave = alq.getAgentsOnLeave(new Set<Id> { agent1Id, agent2Id }, false, null);
        
        System.assert(agentsOnLeave.contains(agent1Id));//Absent (before the routing start hour 1pm)
        System.assert(!agentsOnLeave.contains(agent2Id));

        //Test today's routing, current dt = pm
        WIREAgentLeaveQueryable.currentDateTimeOverride = DateTime.newInstanceGMT(System.today().year(),System.today().month(),System.today().day(),13,00,00);//PM (1pm GMT or 2pm BST)
        Set<Id> agentsOnLeave2 = alq.getAgentsOnLeave(new Set<Id> { agent1Id, agent2Id }, false, null);
        System.assert(!agentsOnLeave2.contains(agent1Id));//No longer absent (after or including the routing start hour 1pm)
        System.assert(!agentsOnLeave2.contains(agent2Id));

    }

    /* */  

    static testMethod void singleTestCase10b(){
        // Test Case 10a : Business Logic. 1 Agent on leave today (am only).

        //Two UK agents
        Id agent1Id = [select Id from User where FirstName like 'Agent1%' and LastName like 'Test%' limit 1][0].Id;
        Id agent2Id = [select Id from User where FirstName like 'Agent2%' and LastName like 'Test%' limit 1][0].Id;
        
        System.debug(LoggingLevel.ERROR, 'singleTestCase1>agent1Id:'+agent1Id);
        System.debug(LoggingLevel.ERROR, 'singleTestCase1>agent2Id:'+agent2Id);

        Date yearStart = Date.newInstance(System.today().year(), 1, 1);//1.2+
        Date yearEnd = Date.newInstance(System.today().year(), 12, 31);//1.2+
        
        //Create employee leave for the first agent (only)
        EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Employee Leave Year Test', Employee__c=agent1Id, Year__c = String.valueOf(System.today().year()),StartDate__c=yearStart,EndDate__c=yearEnd);
        insert leaveYear;
        
        //agent1 is on leave in the am and returning to work in the pm
        Leave__c l = new Leave__c(Employee__c=agent1Id, AM__c=true, PMStart__c=false, PMReturn__c=false,StartDate__c=System.today(), EndDate__c=System.today(), Status__c='approved', EmployeeLeaveYear__c=leaveYear.Id);
        insert l;
        
        WIREAgentLeaveQueryable alq = new WIREAgentLeaveQueryable(); 
        
        //Test today's routing, current dt = am
        WIREAgentLeaveQueryable.currentDateTimeOverride = DateTime.newInstanceGMT(System.today().year(),System.today().month(),System.today().day(),11,00,00);//AM (11am GMT or 12pm BST)
        Set<Id> agentsOnLeave = alq.getAgentsOnLeave(new Set<Id> { agent1Id, agent2Id }, false, null);
        
        System.assert(agentsOnLeave.contains(agent1Id));//Absent (before the routing start hour 1pm)
        System.assert(!agentsOnLeave.contains(agent2Id));

        //Test today's routing, current dt = pm
        WIREAgentLeaveQueryable.currentDateTimeOverride = DateTime.newInstanceGMT(System.today().year(),System.today().month(),System.today().day(),13,00,00);//PM (1pm GMT or 2pm BST)
        Set<Id> agentsOnLeave2 = alq.getAgentsOnLeave(new Set<Id> { agent1Id, agent2Id }, false, null);
        System.assert(!agentsOnLeave2.contains(agent1Id));//No longer absent (after or including the routing start hour 1pm)
        System.assert(!agentsOnLeave2.contains(agent2Id));

        //Create a second leave request for the same day (e.g. well-being request)
        Leave__c l2 = new Leave__c(Employee__c=agent1Id, AM__c=false, PMStart__c=true, PMReturn__c=false,StartDate__c=System.today(), EndDate__c=System.today(), Status__c='approved', EmployeeLeaveYear__c=leaveYear.Id);
        insert l2;

        //Repeat
        WIREAgentLeaveQueryable.currentDateTimeOverride = DateTime.newInstanceGMT(System.today().year(),System.today().month(),System.today().day(),11,30,00);//PM (11:30pm GMT or 12:30pm BST)
        Set<Id> agentsOnLeave3 = alq.getAgentsOnLeave(new Set<Id> { agent1Id, agent2Id }, false, null);
        System.assert(agentsOnLeave3.contains(agent1Id));//Confirm the agent is now considered absent
    }

    /* */

    static testMethod void singleTestCase10c(){
        // Test Case 10b : Business Logic. 2 Agents on leave today (am only). For one, it is the afternoon (UK). For the other, it is the morning (US). Only the US should be considered absent if the time is 13:30pm UTC.

        Id agent1Id = [select Id from User where FirstName like 'Agent1%' and LastName like 'Test%' limit 1][0].Id;
        Id agent3Id = [select Id from User where FirstName like 'Agent3%' and LastName like 'Test%' limit 1][0].Id;
        
        System.debug(LoggingLevel.ERROR, 'singleTestCase1>agent1Id:'+agent1Id);//UK Agent
        System.debug(LoggingLevel.ERROR, 'singleTestCase1>agent3Id:'+agent3Id);//US Agent

        Date yearStart = Date.newInstance(System.today().year(), 1, 1);//1.2+
        Date yearEnd = Date.newInstance(System.today().year(), 12, 31);//1.2+
        
        List<EmployeeLeaveYear__c> leaveYears = new List<EmployeeLeaveYear__c>();
        leaveYears.add(new EmployeeLeaveYear__c(Name='Employee Leave Year Test 1', Employee__c=agent1Id, Year__c = String.valueOf(System.today().year()),StartDate__c=yearStart,EndDate__c=yearEnd));
        leaveYears.add(new EmployeeLeaveYear__c(Name='Employee Leave Year Test 2', Employee__c=agent3Id, Year__c = String.valueOf(System.today().year()),StartDate__c=yearStart,EndDate__c=yearEnd));
        insert leaveYears;
        
        List<Leave__c> leaveRequests = new List<Leave__c>();
        leaveRequests.add(new Leave__c(Employee__c=agent1Id, AM__c=true, PMStart__c=false, PMReturn__c=false,StartDate__c=System.today(), EndDate__c=System.today(), Status__c='approved', EmployeeLeaveYear__c=leaveYears[0].Id));
        leaveRequests.add(new Leave__c(Employee__c=agent3Id, AM__c=true, PMStart__c=false, PMReturn__c=false,StartDate__c=System.today(), EndDate__c=System.today(), Status__c='approved', EmployeeLeaveYear__c=leaveYears[1].Id));

        insert leaveRequests;//Insert matching leave requests for both agents
        
        WIREAgentLeaveQueryable alq = new WIREAgentLeaveQueryable(); 
        
        //Test today's routing (am)
        WIREAgentLeaveQueryable.currentDateTimeOverride = DateTime.newInstanceGMT(System.today().year(),System.today().month(),System.today().day(),13,30,00);//1:30pm UTC/2:30pm BST/ 9am EDT (UK is working, US still on leave)
        Set<Id> agentsOnLeave = alq.getAgentsOnLeave(new Set<Id> { agent1Id, agent3Id }, false, null);
        
        System.assert(agentsOnLeave.contains(agent3Id));//US Absent
        System.assert(!agentsOnLeave.contains(agent1Id));//UK Working

        //Test today's routing (pm)
        WIREAgentLeaveQueryable.currentDateTimeOverride = DateTime.newInstanceGMT(System.today().year(),System.today().month(),System.today().day(),19,00,00);//7pm UTC/ 8pm BST/ 3pm EDT (it's now pm and both are working)
        Set<Id> agentsOnLeave2 = alq.getAgentsOnLeave(new Set<Id> { agent1Id, agent3Id }, false, null);
        System.assert(!agentsOnLeave2.contains(agent1Id));//No longer absent
        System.assert(!agentsOnLeave2.contains(agent3Id));

    }

    /* */  

    static testMethod void singleTestCase11(){
        // Test Case 11 : Business Logic. 1 Agent on leave tomorrow (pm only).

        Id agent1Id = [select Id from User where FirstName like 'Agent1%' and LastName like 'Test%' limit 1][0].Id;
        
        System.debug(LoggingLevel.ERROR, 'singleTestCase1>agent1Id:'+agent1Id);

        Date yearStart = Date.newInstance(System.today().addDays(1).year(), 1, 1);//1.2+
        Date yearEnd = Date.newInstance(System.today().addDays(1).year(), 12, 31);//1.2+
        
        EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Employee Leave Year Test',Employee__c=agent1Id, Year__c = String.valueOf(System.today().addDays(1).year()),StartDate__c=yearStart,EndDate__c=yearEnd);
        insert leaveYear;
        
        Leave__c l = new Leave__c(Employee__c=agent1Id, AM__c=true, PMStart__c=true, StartDate__c=System.today().addDays(1), EndDate__c=System.today().addDays(3), Status__c='approved', EmployeeLeaveYear__c=leaveYear.Id);
        insert l;//Agent on leave all day tomorrow
        
        WIREAgentLeaveQueryable.currentDateTimeOverride = Datetime.newInstanceGmt(System.today().year(),System.today().month(),System.today().day(),17,30,0);//<---- 17.30 (after cutoff)
        
        WIREAgentLeaveQueryable alq = new WIREAgentLeaveQueryable();
        
        Set<Id> agentsOnLeave = alq.getAgentsOnLeave(new Set<Id> { agent1Id }, true, 17);//<---- 17:00 cutoff = 5pm
        
        System.assert(agentsOnLeave.contains(agent1Id));

        l.AM__c = false;
        l.HR_Comments__c = 'No longer absent in the morning';
        update l;//Agent on leave in pm only tomorrow

        Set<Id> agentsOnLeave2 = alq.getAgentsOnLeave(new Set<Id> { agent1Id }, true, 17);//<---- 17:00 cutoff = 5pm       
        
        System.assert(!agentsOnLeave2.contains(agent1Id));//No longer considered absent

    }

}