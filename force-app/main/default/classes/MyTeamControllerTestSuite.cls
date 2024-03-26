@isTest
private class MyTeamControllerTestSuite {
    
    @isTest static void testBasicConstructor() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            User u = UserTestHelper.createStandardUsers(1, 'Flash', 'Gordon')[0];

            Date yearStart = Date.newInstance(system.today().year(),1,1);
            Date yearEnd = Date.newInstance(system.today().year(),12,31);

            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Employee__c=u.Id, Year__c = String.valueOf(System.today().year()),StartDate__c=yearStart,EndDate__c=yearEnd);
            insert leaveYear;
            Leave__c l = new Leave__c(Employee__c=u.Id, StartDate__c=System.today(), EndDate__c=System.today().addDays(2),
                    Status__c='Waiting approval', EmployeeLeaveYear__c=leaveYear.Id);
            insert l;

            PageReference currPage = Page.MyTeam;
            Test.setCurrentPage(currPage);
            currPage.getParameters().put('userId', u.Id);
            MyTeamController teamCntr = new MyTeamController();
            teamCntr.initPage();
            teamCntr.firstPage();
            teamCntr.lastPage();
            teamCntr.next();
            teamCntr.prev();
            teamCntr.resetFilter();
            teamCntr.getListViewOptions();
            teamCntr.getLeaveRequestsWithYear();
            teamCntr.getUsers();
            teamCntr.getMyTeamLeaveOverview();
            teamCntr.approveOrReject();
            teamCntr.reassign();
            teamCntr.updateProcess('Approved', 'String action');
        }
    }
    
    @isTest static void testUserLeaveOverviewWrapperConstructor() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {

            Date yearStart = Date.newInstance(system.today().year(),1,1);
            Date yearEnd = Date.newInstance(system.today().year(),12,31);

            User u = UserTestHelper.createStandardUsers(1, 'Flash', 'Gordon')[0];
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Employee__c=u.Id, Year__c = String.valueOf(System.today().year()),StartDate__c=yearStart,EndDate__c=yearEnd);
            insert leaveYear;
            Leave__c l = new Leave__c(Employee__c=u.Id, StartDate__c=System.today(), EndDate__c=System.today().addDays(2),
                    Status__c='approved', EmployeeLeaveYear__c=leaveYear.Id);
            insert l;
            MyTeamController.UserLeaveOverviewWrapper wrap = new MyTeamController.UserLeaveOverviewWrapper(u, leaveYear, new List<Leave__c>{l});
            System.assertEquals(wrap.user, u);
            System.assertEquals(wrap.leaveYear, leaveYear);
            System.assertEquals(wrap.leaveRequests, new List<Leave__c>{l});
        }
    }

    @isTest static void testLeaveRequestWithYearWrapper() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            
            Date yearStart = Date.newInstance(system.today().year(),1,1);
            Date yearEnd = Date.newInstance(system.today().year(),12,31);

            User u = UserTestHelper.createStandardUsers(1, 'Flash', 'Gordon')[0];
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Employee__c=u.Id, Year__c = String.valueOf(System.today().year()),StartDate__c=yearStart,EndDate__c=yearEnd);
            insert leaveYear;
            Leave__c l = new Leave__c(Employee__c=u.Id, StartDate__c=System.today(), EndDate__c=System.today().addDays(2),
                    Status__c='approved', EmployeeLeaveYear__c=leaveYear.Id);
            insert l;
            MyTeamController.LeaveRequestWithYearWrapper wrap = new MyTeamController.LeaveRequestWithYearWrapper(leaveYear, l);
            System.assertEquals(wrap.leaveYear, leaveYear);
            System.assertEquals(wrap.leaveRequest, l);
        }
    }
    
}