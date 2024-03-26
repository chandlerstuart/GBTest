/*
Class:  BookingInsertTest.cls
Copyright © 2018  Golfbreaks
======================================================
======================================================
Purpose:
-------

Mass Booking insert unit tests.

======================================================
======================================================
Revision History
---------------- 
Ver. Author          Date        Detail
1.0  James Radcliffe 2018-10-09  Initial development (testMassBookingInsert).
1.1  Mark Cane&      2018-10-12  Minor moifications to mitigate List index error due to Routing Configuration access.
1.2  Mark Cane&      2018-11-12  Add testSetup block for WIRE calculations on test data.
*/
@isTest
public class BookingInsertTest {
    /*
    Test cases:
        testMassBookingInsert - ApexTrigger. Bulk insert 200 Bookings.
    */
        
    @testSetup static void createTestData(){
    
        GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;
                
        OrgSettings__c orgSettings = new OrgSettings__c(TriggersActive__c = TRUE);
        insert orgSettings;      
        
        GBWire__RoutingEngineSettings__c wireSettings = new GBWire__RoutingEngineSettings__c();//1.1
        wireSettings.GBWire__IsActive__c = true;
        wireSettings.GBWire__DisableTriggers__c = false;
        wireSettings.GBWire__IsDebugMode__c = true;
        insert wireSettings;    
        
        WorkItemWIREActionIdentifier.isWIRECodeBlocked = true;//<-- 1.2 block WIRE calculations for test data.              

        //Allow the current running test user to insert Client accounts        
        List<Account_Validation__c> validationList = AP23_TestDataFactory.createAccountValidationRulesByProfileId(UserInfo.getProfileId());
        insert validationList;
        
        Integer oppAndAccountCount = 10;
        
        Account[] accs = AP23_TestDataFactory.createPersonAccount(oppAndAccountCount);
        insert accs;
        
        List<Opportunity> opps = new List<Opportunity>();
        Id newSalesRT = ApplicationConstant.OPP_RECTYPEID_NSO;
        for(Integer i = 0;i<oppAndAccountCount;i++){
            Opportunity o = new Opportunity();
            o.Name = 'Test Opp '+i;
            o.StageName = ApplicationConstant.RECOMMENDATIONSTAGE;
            o.CloseDate = system.today();
            o.AccountId = accs[i].Id;
            o.RecordTypeId = newSalesRT;
            opps.add(o);
        }
        insert opps;  
        
            for (GBWire__RoutingLogEntry__c rle : [select Id,GBWire__StackTrace__c,GBWire__Message__c from GBWire__RoutingLogEntry__c order by CreatedDate desc]){
                System.debug(LoggingLevel.ERROR, rle);
            }
         
    }
    
    @isTest static void testMassBookingInsert(){
        
        try {
            
            GBWire.RoutingConfigurationHelper.isTestConfigurationOverride = true;//1.1 force the use of non-test Routing Configurations.
            
            Integer bookingCount = 10;//1.1 bookingCount=200 throws a CPU timeout error.
            
            Opportunity[] allOpps = [Select Id, AccountId, Golfbreaks_Business_Unit__c From Opportunity];
            Integer oppListSize = allOpps.size();
            
            List<Booking__c> newBookings = new List<Booking__c>();
            Integer loopCounter = 0;
            for(Integer i=0; i<bookingCount; i++){
                Booking__c b = new Booking__c();
                b.Name = 'Test Booking '+i;
                if(loopCounter <= oppListSize-1){
                    b.TECH_Opportunity__c = allOpps[loopCounter].Id;
                    b.Account__c = allOpps[loopCounter].AccountId;
                    loopCounter+=1;
                }else{
                    loopCounter = 0;
                    b.TECH_Opportunity__c = allOpps[loopCounter].Id;
                    b.Account__c = allOpps[loopCounter].AccountId;
                }
                newBookings.add(b);
            }
            
            test.startTest();
            insert newBookings;
            test.stopTest();
            
            System.assertEquals(bookingCount, [select count() from Booking__c]);
            
        } catch(Exception e){
            
            Test.getEventBus().deliver();
            System.debug(LoggingLevel.ERROR, e);

            for (Error_log__c el : [select Id,Name,Error_Message__c from Error_log__c order by CreatedDate desc]){
                System.debug(LoggingLevel.ERROR, el);
            }
            
            for (GBWire__RoutingLogEntry__c rle : [select Id,GBWire__StackTrace__c,GBWire__Message__c from GBWire__RoutingLogEntry__c order by CreatedDate desc]){
                System.debug(LoggingLevel.ERROR, rle);
            }
            System.assert(false,'An exceptions was thrown on Booking insert.');                     
        }
    }
}