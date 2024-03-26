/*
Name:  LeaveEntitlementUserProfileTestSuite.cls
Copyright © 2014  Kaptio ehf.
======================================================
======================================================
Purpose:
-------
Test class for LeaveEntitlementUserProfileController.cls
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Halldór Örn   2014-09-04  Class creation.
1.1  J Radcliffe   2020-01-28  Start & End Date required for Employee Leave Years
1.2  J Radcliffe   2023-04-19  New tests for wellness days
1.3  J Radcliffe   2023-08-01  New test method: 
*/
@isTest
private class LeaveEntitlementUserProfileTestSuite {
    
    @isTest static void testConstructor() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {

            Date yearStart = Date.newInstance(System.today().year(), 1, 1);//1.1+
            Date yearEnd = Date.newInstance(System.today().year(), 12, 31);//1.1+

            //Need to create a leave that is set for today to be able to test this properly
            User u = UserTestHelper.createStandardUsers(1, 'Flash', 'Gordon')[0];
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year 1',Employee__c=u.Id, Year__c = String.valueOf(System.today().year()),StartDate__c=yearStart,EndDate__c=yearEnd);//1.1~
            insert leaveYear;

            PageReference currPage = Page.LeaveEntitlementSelf;
            Test.setCurrentPage(currPage);
            currPage.getParameters().put('sfdc.userId', u.Id);
            currPage.getParameters().put('sfdc.tabName', 'tab');
            currPage.getParameters().put('year','2014');
            LeaveEntitlementUserProfileController cntr = new LeaveEntitlementUserProfileController();
            boolean showLieuButton = cntr.showLieuButton;
            List<SelectOption> lieuTypes = cntr.lieuTypes;
            system.assertEquals(3, lieuTypes.size());
            cntr.lieuType = lieuTypes[1].getValue();
        }
    }

    @isTest static void testConstructorWithoutParams() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {

            Date yearStart = Date.newInstance(System.today().year(), 1, 1);//1.1+
            Date yearEnd = Date.newInstance(System.today().year(), 12, 31);//1.1+

            //Need to create a leave that is set for today to be able to test this properly
            User u = UserTestHelper.createStandardUsers(1, 'Flash', 'Gordon')[0];
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year 2',Employee__c=u.Id, Year__c = String.valueOf(System.today().year()),StartDate__c=yearStart,EndDate__c=yearEnd);//1.1~
            insert leaveYear;

            PageReference currPage = Page.LeaveEntitlementSelf;
            LeaveEntitlementUserProfileController cntr = new LeaveEntitlementUserProfileController();
            System.assertEquals(cntr.employeeId, UserInfo.getUserId());
        }
    }

    @isTest static void testSubmitLeaveRequest() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {

            Date yearStart = Date.newInstance(System.today().year(), 1, 1);//1.1+
            Date yearEnd = Date.newInstance(System.today().year(), 12, 31);//1.1+

            //Need to create a leave that is set for today to be able to test this properly
            User u = UserTestHelper.createStandardUsers(1, 'Flash', 'Gordon')[0];
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year 3',Employee__c=u.Id, Year__c = String.valueOf(System.today().year()),StartDate__c=yearStart,EndDate__c=yearEnd);//1.1~
            insert leaveYear;
            Date startDate = System.today();
            Date endDate = startDate.addDays(5);

            System.assertEquals('success', 
                LeaveEntitlementUserProfileController.submitLeaveRequest(u.Id, leaveyear.Id, 'Holiday', startDate.format(), endDate.format(), 
                    true, true, true, 'Holiday', 'Holiday') );
        }
    }
    
    @isTest static void testSubmitLieuRequest() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {

            Date yearStart = Date.newInstance(System.today().year(), 1, 1);//1.1+
            Date yearEnd = Date.newInstance(System.today().year(), 12, 31);//1.1+

            //Need to create a leave that is set for today to be able to test this properly
            User u = UserTestHelper.createStandardUsers(1, 'Flash', 'Gordon')[0];
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year 4',Employee__c=u.Id, Year__c = String.valueOf(System.today().year()),StartDate__c=yearStart,EndDate__c=yearEnd);//1.1~
            insert leaveYear;
            
            Date startDate = System.today();
            Date endDate = startDate.addDays(1);

            System.assertEquals('success', 
                LeaveEntitlementUserProfileController.submitLieuRequest(u.Id, leaveyear.Id, 'PAY', startDate.format(), endDate.format(), 
                    true, true, true, 'Lieu', 'Lieu', 'PAY') );
                    
                    
            //Check for start & end dates not in current year
            startDate = System.today().addYears(1);
            endDate = startDate.addDays(1);
            
            System.assertNotEquals('success', 
                LeaveEntitlementUserProfileController.submitLieuRequest(u.Id, leaveyear.Id, 'PAY', startDate.format(), endDate.format(), 
                    true, true, true, 'Lieu', 'Lieu', 'PAY') );
            
        }
    }

    @isTest static void testLeaveRequestForNextYearWithoutLeaveYear() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {

            Date yearStart = Date.newInstance(System.today().year(), 1, 1);//1.1+
            Date yearEnd = Date.newInstance(System.today().year(), 12, 31);//1.1+

            User u = UserTestHelper.createStandardUsers(1, 'Flash', 'Gordon')[0];
            //Create a leave year for current year
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year 4',Employee__c=u.Id, Year__c = String.valueOf(System.today().year()),StartDate__c=yearStart,EndDate__c=yearEnd);//1.1~
            insert leaveYear;
            //Set the start year one year into the future
            Date startDate = System.today().addYears(1);
            Date endDate = startDate.addDays(5);

            System.assertEquals(System.Label.UI_Text_No_Leave_Year_For_Date, 
                LeaveEntitlementUserProfileController.submitLeaveRequest(u.Id, leaveyear.Id, 'Holiday', startDate.format(), endDate.format(), 
                    true, true, true, 'Holiday', 'Holiday') );
        }
    }

    @isTest static void testLeaveRequestForNextYearWithLeaveYear() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {

            Date yearStart = Date.newInstance(System.today().addYears(1).year(), 1, 1);//1.1+
            Date yearEnd = Date.newInstance(System.today().addYears(1).year(), 12, 31);//1.1+

            User u = UserTestHelper.createStandardUsers(1, 'Flash', 'Gordon')[0];
            //Create a leave year for current year
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year 5',Employee__c=u.Id, Year__c = String.valueOf(System.today().addYears(1).year()),StartDate__c=yearStart,EndDate__c=yearEnd);//1.1~
            insert leaveYear;
            //Set the start year one year into the future
            Date startDate = System.today().addYears(1);
            Date endDate = startDate.addDays(5);

            System.assertEquals('success', 
                LeaveEntitlementUserProfileController.submitLeaveRequest(u.Id, leaveyear.Id, 'Holiday', startDate.format(), endDate.format(), 
                    true, true, true, 'Holiday', 'Holiday') );
            List<Leave__c> queriedLeaves = [SELECT Id, EmployeeLeaveYear__c FROM Leave__c WHERE EmployeeLeaveYear__c =: leaveYear.Id];
            System.assertEquals(queriedLeaves.size(), 1);
        }
    }

    @isTest static void testEmailHelper() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
        System.runAs (thisUser) {
            EmailHelper.sendAnEmail('Test', 'Test', 'example@example.org');
        }
    }


    //1.2+
    @isTest static void testSubmitWellnessDayRequest() {
        
        User thisUser = UserTestHelper.createStandardUsers(1, 'Bruce', 'Wayne')[0];
        UserRole role = [Select Id From UserRole Where Name = 'HR' Limit 1][0];
        thisUser.UserRoleId = role.Id;
        update thisUser;
       
        System.runAs (thisUser) {

            insert new OrgSettings__c(TriggersActive__c=true);//Activate triggers

            Date yearStart = Date.newInstance(System.today().year(), 1, 1);
            Date yearEnd = Date.newInstance(System.today().year(), 12, 31);

            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year 6',Employee__c=thisUser.Id, Year__c = String.valueOf(System.today().year()),StartDate__c=yearStart,EndDate__c=yearEnd,WellnessDayLimit__c=1);
            insert leaveYear;
            

            PageReference currPage = Page.LeaveEntitlementSelf;
            Test.setCurrentPage(currPage);
            currPage.getParameters().put('sfdc.userId', thisUser.Id);
            currPage.getParameters().put('sfdc.tabName', 'tab');
            currPage.getParameters().put('year',String.valueOf(yearStart.year()));
            LeaveEntitlementUserProfileController cntr = new LeaveEntitlementUserProfileController();
            
            Date startDate = System.today();
            Date endDate = startDate;
            cntr.aLeave.StartDate__c = startDate;//Simulate user selecting the date

            System.assertEquals(1.0, cntr.getRemainingWellnessDays());

            Test.startTest();

                System.assertEquals('success', 
                    LeaveEntitlementUserProfileController.submitWellnessRequest(thisUser.Id, leaveyear.Id, startDate.format(), endDate.format(), 
                        true, true, ApplicationConstant.LEAVE_TYPE_WELLNESS_DAY, null) );      

            Test.stopTest();
                    
            System.assertEquals(0, cntr.getRemainingWellnessDays());

            //Confirm an error is thrown if the user attempts to request more that permitted number of days
            System.assertEquals('Sorry, you cannot request 0.5 days leave as you only have 0 remaining.', 
                LeaveEntitlementUserProfileController.submitWellnessRequest(thisUser.Id, leaveyear.Id, startDate.format(), endDate.format(), 
                    false, true, ApplicationConstant.LEAVE_TYPE_WELLNESS_DAY, null) );
                    
            //Check for start & end dates not in current year
            startDate = System.today().addMonths(1);
            endDate = startDate;
            cntr.aLeave.StartDate__c = startDate;//Simulate user selecting the next month's date

            System.assertEquals(1.0, cntr.getRemainingWellnessDays());
            
            System.assertEquals('success', 
                LeaveEntitlementUserProfileController.submitWellnessRequest(thisUser.Id, leaveyear.Id, startDate.format(), endDate.format(), 
                    true, true, ApplicationConstant.LEAVE_TYPE_WELLNESS_DAY, null) );
            
        }
    }

    //1.3+
    @isTest static void testWellbeingLeavePeriodDaysRemaining() {
        
        User thisUser = UserTestHelper.createStandardUsers(1, 'Bruce', 'Wayne')[0];
        UserRole role = [Select Id From UserRole Where Name = 'HR' Limit 1][0];
        thisUser.UserRoleId = role.Id;
        update thisUser;
       
        System.runAs (thisUser) {

            insert new OrgSettings__c(TriggersActive__c=true);//Activate triggers

            Date yearStart = Date.newInstance(System.today().year(), 1, 1);
            Date yearEnd = Date.newInstance(System.today().year(), 12, 31);

            //Create
            EmployeeLeaveYear__c leaveYear = new EmployeeLeaveYear__c(Name='Test Leave Year 7',Employee__c=thisUser.Id, Year__c = String.valueOf(System.today().year()),StartDate__c=yearStart,EndDate__c=yearEnd,WellnessDayLimit__c=1);
            insert leaveYear;

            //Create approved leave for jan & feb (0.5 days per month)
            List<Leave__c> leaveRequests = new List<Leave__c>();
            leaveRequests.add(new Leave__c(EmployeeLeaveYear__c=leaveYear.Id,Status__c=ApplicationConstant.LEAVE_STATUS_APPROVED,AM__c=false,PMStart__c=true,Employee__c=thisUser.Id,EmployeeComment__c='Well-being half day',LeaveType__c=ApplicationConstant.LEAVE_TYPE_WELLNESS_DAY,StartDate__c=Date.newInstance(System.today().year(), 1, 1),EndDate__c=Date.newInstance(System.today().year(), 1, 1)));//Jan half day
            leaveRequests.add(new Leave__c(EmployeeLeaveYear__c=leaveYear.Id,Status__c=ApplicationConstant.LEAVE_STATUS_APPROVED,AM__c=false,PMStart__c=true,Employee__c=thisUser.Id,EmployeeComment__c='Well-being half day',LeaveType__c=ApplicationConstant.LEAVE_TYPE_WELLNESS_DAY,StartDate__c=Date.newInstance(System.today().year(), 2, 1),EndDate__c=Date.newInstance(System.today().year(), 2, 1)));//Feb half day
            insert leaveRequests;

            PageReference currPage = Page.LeaveEntitlementSelf;
            Test.setCurrentPage(currPage);
            currPage.getParameters().put('sfdc.userId', thisUser.Id);
            currPage.getParameters().put('sfdc.tabName', 'tab');
            currPage.getParameters().put('year',String.valueOf(yearStart.year()));
            LeaveEntitlementUserProfileController cntr = new LeaveEntitlementUserProfileController();
            
            cntr.aLeave.StartDate__c = Date.newInstance(System.today().year(),1,1);//Simulate user selecting a date in Jan

            Test.startTest();

                System.assertEquals(0.5, cntr.getRemainingWellnessDays());//Half day remaining (limit 1 - Jan half day)

                cntr.aLeave.StartDate__c = Date.newInstance(System.today().year(),2,1);//Simulate user selecting a date in Feb
                System.assertEquals(0.5, cntr.getRemainingWellnessDays());//Half day remaining (limit 1 - Feb half day)

                //Change the well-being leave period to bimonthly
                leaveYear.WellbeingLeavePeriod__c = ApplicationConstant.LEAVE_PERIOD_BIMONTHLY;
                update leaveYear;

                cntr = new LeaveEntitlementUserProfileController();//Refresh page to pick up changes
                cntr.aLeave.StartDate__c = Date.newInstance(System.today().year(),2,1);//Simulate user selecting a date in Feb (again)

                System.assertEquals(0, cntr.getRemainingWellnessDays());//This time, no leave remaining (limit 1 - Jan half day + Feb half day - jan and feb are a bimonthly pair)

                cntr.aLeave.StartDate__c = Date.newInstance(System.today().year(),3,1);//Simulate user selecting a date in March
                System.assertEquals(1, cntr.getRemainingWellnessDays());//Full allowance remaining, no leave in Mar or Apr - mar and apr are a bimonthly pair.

                //Insert a half day leave request for April
                insert new Leave__c(EmployeeLeaveYear__c=leaveYear.Id,AM__c=false,PMStart__c=true,Employee__c=thisUser.Id,EmployeeComment__c='Well-being half day',LeaveType__c=ApplicationConstant.LEAVE_TYPE_WELLNESS_DAY,StartDate__c=Date.newInstance(System.today().year(), 4, 1),EndDate__c=Date.newInstance(System.today().year(), 4, 1));//Apr half day
                System.assertEquals(0.5, cntr.getRemainingWellnessDays());//Half day remaining (limit 1 - No leave used for mar, but apr has half day leave and mar and apr are a bimonthly pair)

            Test.stopTest();
            
        }
    }
    
}