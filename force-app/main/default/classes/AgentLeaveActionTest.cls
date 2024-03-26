/*
Class:  AgentLeaveActionTest.cls
Copyright © 2024  Golfbreaks
======================================================
======================================================
Purpose:
-------
Suite of unit tests that exercise (and verify) code behaviour related to the action AgentLeaveAction.

Coverage for classes below (target 85%):
AgentLeaveAction.cls : 78%

======================================================
======================================================
Revision History
---------------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2024-02-08  Initial development.
*/
@isTest 
public class AgentLeaveActionTest {

    /*
    Test cases:
        singleTestCase1 - Business Logic. Agent on leave.
        singleTestCase2 - Business Logic. Agent on public holiday.
    */

    @testSetup static void setup(){ }

    /* **/    
    static testMethod void singleTestCase1() {
        // Test Case 1 : Business Logic. Agent on leave.

        User agent1,agent2;

        System.runAs(new User(Id=UserInfo.getUserId())){
            agent1 = UserTestHelper.createStandardUsers(1, 'Agent1', 'Test',false)[0];
            agent2 = UserTestHelper.createStandardUsers(1, 'Agent2', 'Test',false)[0];
            insert new List<User>{ agent1,agent2 };
        }
        
        Date yearStart = Date.newInstance(System.today().year(), 1, 1);
        Date yearEnd = Date.newInstance(System.today().year(), 12, 31);
        
        EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Employee Leave Year Test',Employee__c=agent1.Id, Year__c = String.valueOf(System.today().year()),StartDate__c=yearStart,EndDate__c=yearEnd);
        insert leaveYear;
        
        Leave__c l = new Leave__c(Employee__c=agent1.Id, StartDate__c=System.today(), EndDate__c=System.today().addDays(2), Status__c='approved', EmployeeLeaveYear__c=leaveYear.Id);
        insert l;
        
        AgentLeaveAction.ActionRequest request;
        List<AgentLeaveAction.ActionRequest> requests = new List<AgentLeaveAction.ActionRequest>();
        
        request = new AgentLeaveAction.ActionRequest();
        request.agentId = agent1.Id;
        requests.add(request);

        request = new AgentLeaveAction.ActionRequest();
        request.agentId = agent2.Id;
        requests.add(request);

        List<AgentLeaveAction.ActionResult> results = AgentLeaveAction.checkAgentIsOnLeave(requests);

        Assert.isTrue(results[0].isSuccess);
        Assert.isTrue(results[0].isAgentOnLeave);
        Assert.areEqual(l.Id,results[0].leaveRecord.Id);

        Assert.isTrue(results[1].isSuccess);
        Assert.isFalse(results[1].isAgentOnLeave);
    }/* */

    /* **/    
    static testMethod void singleTestCase2() {
        // Test Case 2 : Agent on public holiday.

        User agent1,agent2;

        System.runAs(new User(Id=UserInfo.getUserId())){
            agent1 = UserTestHelper.createStandardUsers(1, 'Agent1', 'Test',false)[0];
            agent2 = UserTestHelper.createStandardUsers(1, 'Agent2', 'Test',false)[0];
            insert new List<User>{ agent1,agent2 };
        }
        
        Date yearStart = Date.newInstance(System.today().year(), 1, 1);
        Date yearEnd = Date.newInstance(System.today().year(), 12, 31);
        
        PublicHolidayGroup__c phg1 = CalendarTestHelper.createPublicHolidayGroupsWithHoliday(1,1,System.today(),System.today())[0];//Has Company Holiday Today
        
        insert new List<EmployeeLeaveYear__c>{ new EmployeeLeaveYear__c(Name='Employee Leave Year Test', Employee__c=agent1.Id, Year__c = String.valueOf(System.today().year()),StartDate__c=yearStart,EndDate__c=yearEnd, PublicHolidayGroup__c=phg1.Id),
                                                new EmployeeLeaveYear__c(Name='Employee Leave Year Test', Employee__c=agent2.Id, Year__c = String.valueOf(System.today().year()),StartDate__c=yearStart,EndDate__c=yearEnd, PublicHolidayGroup__c=phg1.Id) };
        
        AgentLeaveAction.ActionRequest request;
        List<AgentLeaveAction.ActionRequest> requests = new List<AgentLeaveAction.ActionRequest>();
        
        request = new AgentLeaveAction.ActionRequest();
        request.agentId = agent1.Id;
        requests.add(request);

        request = new AgentLeaveAction.ActionRequest();
        request.agentId = agent2.Id;
        requests.add(request);

        List<AgentLeaveAction.ActionResult> results = AgentLeaveAction.checkAgentIsOnLeave(requests);

        Assert.isTrue(results[0].isSuccess);
        Assert.isTrue(results[0].isAgentOnLeave);
        Assert.isNotNull(results[0].publicHolidayRecord);

        Assert.isTrue(results[1].isSuccess);
        Assert.isTrue(results[1].isAgentOnLeave);
        Assert.isNotNull(results[1].publicHolidayRecord);
    }/* */
}