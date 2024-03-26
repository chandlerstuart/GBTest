@isTest
private class AP42_MonthlySalesTargetBL_Test {
    
    @testSetup 
    static void setupData(){
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;
        
        
        List<User> usrs = new List<User>();

        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name =:ApplicationConstant.PROFILE_SYSADMIN].Id,
            LastName = 'Snow',
            Email = 'snow@test.com',
            Username = 'testuser000@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            //UserRoleId = r.Id
        );
        usrs.add(u);

        u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = :ApplicationConstant.PROFILE_SYSADMIN].Id,
            LastName = 'Stark',
            Email = 'stark000@test.com',
            Username = 'testuser000@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            //UserRoleId = r.Id
        );
        usrs.add(u);

        insert usrs;
        List<User> userList = [SELECT Id FROM User WHERE IsActive=true LIMIT 2];        

        List<Monthly_Sales_Target__c> monthlySalesTargetList = new List<Monthly_Sales_Target__c>();
        Monthly_Sales_Target__c monthlySalesTarget1 = AP23_TestDataFactory.createMonthlySalesTargetByGrossProfit(userList.get(0), Date.today());
        Monthly_Sales_Target__c monthlySalesTarget2 = AP23_TestDataFactory.createMonthlySalesTargetByGrossProfit(userList.get(0), Date.today().addMonths(1));
        Monthly_Sales_Target__c monthlySalesTarget3 = AP23_TestDataFactory.createMonthlySalesTargetByBookings(userList.get(0), Date.today().addMonths(2));
        
        Monthly_Sales_Target__c monthlySalesTarget4 = AP23_TestDataFactory.createMonthlySalesTargetByGrossProfit(userList.get(1), Date.today());
        Monthly_Sales_Target__c monthlySalesTarget5 = AP23_TestDataFactory.createMonthlySalesTargetByGrossProfit(userList.get(1), Date.today().addMonths(1));
        Monthly_Sales_Target__c monthlySalesTarget6 = AP23_TestDataFactory.createMonthlySalesTargetByBookings(userList.get(1), Date.today().addMonths(2));
        
        monthlySalesTargetList.add(monthlySalesTarget1);
        monthlySalesTargetList.add(monthlySalesTarget2);
        monthlySalesTargetList.add(monthlySalesTarget3);
        monthlySalesTargetList.add(monthlySalesTarget4);
        monthlySalesTargetList.add(monthlySalesTarget5);
        monthlySalesTargetList.add(monthlySalesTarget6);
        
        insert monthlySalesTargetList;
        
        List<Account> accts = AP23_TestDataFactory.createAccount(1);
        insert accts;
    }
      
     
    static testmethod void updateMonthlySalesTargetRollupTest(){
        
        Test.startTest();
        Account acct = [SELECT Id, Name FROM Account LIMIT 1];
        List<Monthly_Sales_Target__c> monthlySalesTargetList = [SELECT Id, Won_Amount__c, Target_Month_Year__c, Total_Booking_Amount__c, SalesAgent__c FROM Monthly_Sales_Target__c];
        List<Id> userIds = new List<Id>();
        Set<Id> userIdSet = new Set<Id>();
        for(Monthly_Sales_Target__c mst : monthlySalesTargetList){
            userIdSet.add(mst.SalesAgent__c);
        }
        userIds.addAll(userIdSet);
        

        List<Opportunity> opportunityList = AP23_TestDataFactory.createOpportunity(3, ApplicationConstant.OPPORTUNITY_STAGENAME_TRIP_COMPLETED, acct);
        for(Opportunity opp : opportunityList){
            opp.OwnerId = userIds[0];
            opp.Amount = 10000;
            opp.BookingAmount__c = 6000;
            opp.CloseDate = Date.today();
            opp.RecordTypeId = ApplicationConstant.OPP_RECTYPEID_NSO;
            opp.StageName = ApplicationConstant.OPPORTUNITY_STAGENAME_TRIP_COMPLETED;
        }
        insert opportunityList;
        resetHandler();        
        for (Monthly_Sales_Target__c monthlySalesTarget : [SELECT Id, RecordTypeId, Won_Amount__c, Total_no_of_Closed_Bookings__c, Total_Booking_Amount__c, SalesAgent__c, Target_Month_Year__c FROM Monthly_Sales_Target__c]){
            if(monthlySalesTarget.RecordTypeId == ApplicationConstant.MONTHLY_SALES_TARGET_GROSS_PROFIT){
                if(monthlySalesTarget.SalesAgent__c == userIds[0] && monthlySalesTarget.Target_Month_Year__c == Date.today()){
                    System.assertEquals(monthlySalesTarget.Won_Amount__c, 30000);
                    System.assertEquals(monthlySalesTarget.Total_Booking_Amount__c, 18000);
                }else {
                    System.assertEquals(monthlySalesTarget.Won_Amount__c, 0);
                    System.assertEquals(monthlySalesTarget.Total_Booking_Amount__c, 0);
                }
            } else if(monthlySalesTarget.RecordTypeId == ApplicationConstant.MONTHLY_SALES_TARGET_BOOKINGS){
                if(monthlySalesTarget.SalesAgent__c == userIds[0]){
                    System.assertEquals(monthlySalesTarget.Total_no_of_Closed_Bookings__c, 0);
                } else if(monthlySalesTarget.SalesAgent__c == userIds[1]){
                    System.assertEquals(monthlySalesTarget.Total_no_of_Closed_Bookings__c, 0);
                }
            }
        }

        Opportunity opportunityTest = [SELECT Id, TECH_Monthly_Sales_Target__c, StageName, Amount, BookingAmount__c, OwnerId FROM Opportunity WHERE Id = :opportunityList[0].Id];
        opportunityTest.OwnerId = userIds[1];
        update opportunityTest;
        resetHandler();
        for (Monthly_Sales_Target__c monthlySalesTarget : [SELECT Id, RecordTypeId, Won_Amount__c, Total_no_of_Closed_Bookings__c, Total_Booking_Amount__c, SalesAgent__c, Target_Month_Year__c FROM Monthly_Sales_Target__c]){
            if(monthlySalesTarget.RecordTypeId == ApplicationConstant.MONTHLY_SALES_TARGET_GROSS_PROFIT){
                if(monthlySalesTarget.SalesAgent__c == userIds[0] && monthlySalesTarget.Target_Month_Year__c == Date.today()){
                    System.assertEquals(monthlySalesTarget.Won_Amount__c, 20000);
                    System.assertEquals(monthlySalesTarget.Total_Booking_Amount__c, 12000);
                }else if (monthlySalesTarget.SalesAgent__c == userIds[1] && monthlySalesTarget.Target_Month_Year__c == Date.today()){
                    System.assertEquals(monthlySalesTarget.Won_Amount__c, 10000);
                    System.assertEquals(monthlySalesTarget.Total_Booking_Amount__c, 6000);
                }else{
                    System.assertEquals(monthlySalesTarget.Won_Amount__c, 0);
                    System.assertEquals(monthlySalesTarget.Total_Booking_Amount__c, 0);
                }
            } else if(monthlySalesTarget.RecordTypeId == ApplicationConstant.MONTHLY_SALES_TARGET_BOOKINGS){
                if(monthlySalesTarget.SalesAgent__c == userIds[0]){
                    System.assertEquals(monthlySalesTarget.Total_no_of_Closed_Bookings__c, 0);
                } else if(monthlySalesTarget.SalesAgent__c == userIds[1]){
                    System.assertEquals(monthlySalesTarget.Total_no_of_Closed_Bookings__c, 0);
                }
            }
        }
        
        opportunityTest = [SELECT Amount, BookingAmount__c, OwnerId FROM Opportunity WHERE Id = :opportunityList[0].Id];
        opportunityTest.Amount = 6000;
        opportunityTest.BookingAmount__c = 10000;
        update opportunityTest;
        resetHandler();
        for (Monthly_Sales_Target__c monthlySalesTarget : [SELECT Id, RecordTypeId, Won_Amount__c, Total_no_of_Closed_Bookings__c, Total_Booking_Amount__c, SalesAgent__c, Target_Month_Year__c FROM Monthly_Sales_Target__c]){
            if(monthlySalesTarget.RecordTypeId == ApplicationConstant.MONTHLY_SALES_TARGET_GROSS_PROFIT){
                if(monthlySalesTarget.SalesAgent__c == userIds[0] && monthlySalesTarget.Target_Month_Year__c == Date.today()){
                    System.assertEquals(monthlySalesTarget.Won_Amount__c, 20000);
                    System.assertEquals(monthlySalesTarget.Total_Booking_Amount__c, 12000);
                }else if (monthlySalesTarget.SalesAgent__c == userIds[1] && monthlySalesTarget.Target_Month_Year__c == Date.today()){
                    System.assertEquals(monthlySalesTarget.Won_Amount__c, 6000);
                    System.assertEquals(monthlySalesTarget.Total_Booking_Amount__c, 10000);
                }else{
                    System.assertEquals(monthlySalesTarget.Won_Amount__c, 0);
                    System.assertEquals(monthlySalesTarget.Total_Booking_Amount__c, 0);
                }
            } else if(monthlySalesTarget.RecordTypeId == ApplicationConstant.MONTHLY_SALES_TARGET_BOOKINGS){
                if(monthlySalesTarget.SalesAgent__c == userIds[0]){
                    System.assertEquals(monthlySalesTarget.Total_no_of_Closed_Bookings__c, 0);
                } else if(monthlySalesTarget.SalesAgent__c == userIds[1]){
                    System.assertEquals(monthlySalesTarget.Total_no_of_Closed_Bookings__c, 0);
                }
            }
        }

        opportunityTest = [SELECT Amount, TECH_Monthly_Sales_Target__c, BookingAmount__c, OwnerId, CloseDate FROM Opportunity WHERE Id = :opportunityTest.Id];
        opportunityTest.CloseDate = Date.today().addMonths(1);
        update opportunityTest;
        resetHandler();
        for (Monthly_Sales_Target__c monthlySalesTarget : [SELECT Id, RecordTypeId, Won_Amount__c, Total_no_of_Closed_Bookings__c, Total_Booking_Amount__c, SalesAgent__c, Target_Month_Year__c FROM Monthly_Sales_Target__c]){
            if(monthlySalesTarget.RecordTypeId == ApplicationConstant.MONTHLY_SALES_TARGET_GROSS_PROFIT){
                if (monthlySalesTarget.SalesAgent__c == userIds[0] && monthlySalesTarget.Target_Month_Year__c == Date.today()){
                    System.assertEquals(monthlySalesTarget.Won_Amount__c, 20000);
                    System.assertEquals(monthlySalesTarget.Total_Booking_Amount__c, 12000);
                }else if (monthlySalesTarget.SalesAgent__c == userIds[1] && monthlySalesTarget.Target_Month_Year__c == Date.today().addMonths(1)){
                    System.assertEquals(monthlySalesTarget.Won_Amount__c, 6000);
                    System.assertEquals(monthlySalesTarget.Total_Booking_Amount__c, 10000);
                }else {
                    System.assertEquals(monthlySalesTarget.Won_Amount__c, 0);
                    System.assertEquals(monthlySalesTarget.Total_Booking_Amount__c, 0);
                }
            } else if(monthlySalesTarget.RecordTypeId == ApplicationConstant.MONTHLY_SALES_TARGET_BOOKINGS){
                if(monthlySalesTarget.SalesAgent__c == userIds[0]){
                    System.assertEquals(monthlySalesTarget.Total_no_of_Closed_Bookings__c, 0);
                } else if(monthlySalesTarget.SalesAgent__c == userIds[1]){
                    System.assertEquals(monthlySalesTarget.Total_no_of_Closed_Bookings__c, 0);
                }
            }
        }
        
        opportunityTest = [SELECT Amount, TECH_Monthly_Sales_Target__c, BookingAmount__c, OwnerId, CloseDate FROM Opportunity WHERE Id = :opportunityTest.Id];
        opportunityTest.CloseDate = Date.today().addMonths(2);
        update opportunityTest;
        resetHandler();
        for (Monthly_Sales_Target__c monthlySalesTarget : [SELECT Id, RecordTypeId, Won_Amount__c, Total_no_of_Closed_Bookings__c, Total_Booking_Amount__c, SalesAgent__c, Target_Month_Year__c FROM Monthly_Sales_Target__c]){
            if(monthlySalesTarget.RecordTypeId == ApplicationConstant.MONTHLY_SALES_TARGET_GROSS_PROFIT) {
                if  (monthlySalesTarget.SalesAgent__c == userIds[0] && monthlySalesTarget.Target_Month_Year__c == Date.today()){
                    System.assertEquals(monthlySalesTarget.Won_Amount__c, 20000);
                    System.assertEquals(monthlySalesTarget.Total_Booking_Amount__c, 12000);
                }else {
                    System.assertEquals(monthlySalesTarget.Won_Amount__c, 0);
                    System.assertEquals(monthlySalesTarget.Total_Booking_Amount__c, 0);
                }
            } else if(monthlySalesTarget.RecordTypeId == ApplicationConstant.MONTHLY_SALES_TARGET_BOOKINGS){
                    if(monthlySalesTarget.SalesAgent__c == userIds[0]){
                        System.assertEquals(monthlySalesTarget.Total_no_of_Closed_Bookings__c, 0);
                    } else if(monthlySalesTarget.SalesAgent__c == userIds[1]){
                        System.assertEquals(monthlySalesTarget.Total_no_of_Closed_Bookings__c, 1);
                    }
            }
        }
        
        List<Opportunity> opportunityList2 = AP23_TestDataFactory.createOpportunity(3,ApplicationConstant.OPP_STAGE_NOSALE , acct);
        for(Opportunity opp : opportunityList2){
            opp.OwnerId = userIds[1];
            opp.Amount = 5000;
            opp.BookingAmount__c = 1000;
            opp.CloseDate = Date.today();
            opp.RecordTypeId = ApplicationConstant.OPP_RECTYPEID_NSO;
            opp.StageName = ApplicationConstant.OPP_STAGE_NOSALE;
        }
        insert opportunityList2;
        resetHandler();
        for (Monthly_Sales_Target__c monthlySalesTarget : [SELECT Id, RecordTypeId, Won_Amount__c, Total_no_of_Closed_Bookings__c, Total_Booking_Amount__c, SalesAgent__c, Target_Month_Year__c FROM Monthly_Sales_Target__c]){
            if(monthlySalesTarget.RecordTypeId == ApplicationConstant.MONTHLY_SALES_TARGET_GROSS_PROFIT) {
                if  (monthlySalesTarget.SalesAgent__c == userIds[0] && monthlySalesTarget.Target_Month_Year__c == Date.today()){
                    System.assertEquals(monthlySalesTarget.Won_Amount__c, 20000);
                    System.assertEquals(monthlySalesTarget.Total_Booking_Amount__c, 12000);
                }else {
                    System.assertEquals(monthlySalesTarget.Won_Amount__c, 0);
                    System.assertEquals(monthlySalesTarget.Total_Booking_Amount__c, 0);
                }
            } else if(monthlySalesTarget.RecordTypeId == ApplicationConstant.MONTHLY_SALES_TARGET_BOOKINGS){
                    if(monthlySalesTarget.SalesAgent__c == userIds[0]){
                        System.assertEquals(monthlySalesTarget.Total_no_of_Closed_Bookings__c, 0);
                    } else if(monthlySalesTarget.SalesAgent__c == userIds[1]){
                        System.assertEquals(monthlySalesTarget.Total_no_of_Closed_Bookings__c, 1);
                    }
            }
        }
        
        delete [SELECT Id FROM Monthly_Sales_Target__c WHERE SalesAgent__c =:userIds[1]];
        resetHandler();
        opportunityList2 = [SELECT Amount, BookingAmount__c, OwnerId, CloseDate, TECH_Monthly_Sales_Target__c FROM Opportunity WHERE StageName = :ApplicationConstant.OPP_STAGE_NOSALE];
        for(Opportunity opp : opportunityList2) {
            System.assertEquals(opp.TECH_Monthly_Sales_Target__c, null);
        }
        
        Test.stopTest();

    }

    private static void resetHandler(){
        AP41_MonthlySalesTargetTriggerHandler.isBeforeUpdateTriggerCalled = FALSE;
        AP41_MonthlySalesTargetTriggerHandler.isBeforeInsertTriggerCalled = FALSE;
        
        AP05_OpportunityTriggerHandler.isBeforeUpdateTriggerCalled = FALSE;
        AP05_OpportunityTriggerHandler.isBeforeInsertTriggerCalled = FALSE;
        AP05_OpportunityTriggerHandler.isAfterUpdateTriggerCalled = FALSE;
        AP05_OpportunityTriggerHandler.isAfterDeleteTriggerCalled = FALSE;
        AP05_OpportunityTriggerHandler.isAfterInsertTriggerCalled = FALSE;
    }
}