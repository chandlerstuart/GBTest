/*
Name:  TealiumVisitorProfileResponseHandlerTest.cls
======================================================
======================================================
Purpose: Test Suite for TealiumVisitorProfileResponseHandler.cls
-------
======================================================
======================================================

History
------- 
Ver. Author        Date         Detail
1.0  J Radcliffe   2022-06-28   Initial development
1.1  C Stuart      2024-03-21   Refactored test methods to support the introduction of Initial UTM Search Term & Initial UTM Referrer assignment
*/
@isTest
public with sharing class TealiumVisitorProfileResponseHandlerTest {
    
    public static String responseJSON = '{"transactionId":"16a09a38-3cde-46fd-a545-3c4c464a8474","live":false,"visitor":{"metrics":{"Total direct visits":17,"Total referred visits":1,"Lifetime visit count":18,"Lifetime event count":61,"Total time spent on site in minutes":36.016666666666666,"Average visit duration in minutes":2.0009259259259258,"Weeks since first visit":64.14285714285714,"Average visits per week":0.2806236080178174,"Tournament Pages Visited (Number of Sessions - 30 Days)":0,"Number of visits for the last 7 days":3},"dates":{"last_visit_start_ts":1656346904000,"audience_golfbreaks_sarazen_111_count_ts":1656346904000,"First visit":1617527080000,"Last visit":1656346904000},"properties":{"profile":"sarazen","account":"golfbreaks","Last event URL":"https://www.golfbreaks.com/en-gb/holidays/northumberland/slaley-hall/packages/6a8605c5-580a-484d-991c-d156761b91cf/","Lifetime devices used (favorite)":"Android","Lifetime browser types used (favorite)":"Chrome","Lifetime operating systems used (favorite)":"Android","Lifetime platforms used (favorite)":"browser","Lifetime browser versions used (favorite)":"Chrome","Interests: Countries (30 days) (favorite)":"England","GA Client ID":"382638270.1649368721","Measurement URL":"%2Fen-gb%2Fmeasurement","Interests: Venues (30 days) (favorite)":"Slaley Hall","Tealium Visitor Id":"01819195f5680015aab840bcfa8f00076011206e004a0","Interests: Location Regions (30 days) (favorite)":"North East England","Utm Source - Tally (favorite)":"gb_newsletter","Utm Campaign - Tally (favorite)":"gbdc_220621_breakingdeals","Utm Medium - Tally (favorite)":"email","Utm Source - First Record":"gb_newsletter","Utm Campaign - First Record":"gbdc_211026_breakingdeals","Utm Medium - First Record":"email","Interests: Sales Region (30 Days) (favorite)":"UK & Ireland","UTM Source - 30 Day Timeout":"gb_newsletter","UTM Medium - 30 Day Timeout":"email","UTM Campaign - 30 Day Timeout":"gbdc_220621_breakingdeals","Interests: County / State (30 days) (favorite)":"Northumberland"},"flags":{"Returning visitor":true,"Booked not travelled":false},"sequences":{"Last 30 days":[{"timestamp":1656004937394,"snapshot":{}},{"timestamp":1656004937991,"snapshot":{}},{"timestamp":1656004938572,"snapshot":{}},{"timestamp":1656006786246,"snapshot":{"Interests: Countries (Visit)":{"England":2},"Interests: Venues (Visit)":{"Slaley Hall":2},"Interests: Destinations (Visit)":{"":2},"Interests: Location Region (Visit)":{"North East England":2},"Interests: Sales Region (Visit)":{"UK & Ireland":2},"Interests: County / State (Visit)":{"Northumberland":2}}},{"timestamp":1656050185961,"snapshot":{}},{"timestamp":1656050185966,"snapshot":{}},{"timestamp":1656052018288,"snapshot":{"Interests: Countries (Visit)":{"England":2},"Interests: Venues (Visit)":{"Slaley Hall":2},"Interests: Destinations (Visit)":{"":2},"Interests: Location Region (Visit)":{"North East England":2},"Interests: Sales Region (Visit)":{"UK & Ireland":2},"Interests: County / State (Visit)":{"Northumberland":2}}},{"timestamp":1656346905005,"snapshot":{}},{"timestamp":1656347558130,"snapshot":{"Interests: Countries (Visit)":{"England":1},"Interests: Venues (Visit)":{"Slaley Hall":1},"Interests: Destinations (Visit)":{"":1},"Interests: Location Region (Visit)":{"North East England":1},"Interests: Sales Region (Visit)":{"UK & Ireland":1},"Interests: County / State (Visit)":{"Northumberland":1}}}],"Last 7 days":[{"timestamp":1656004937394,"snapshot":{}},{"timestamp":1656050185961,"snapshot":{}},{"timestamp":1656346905005,"snapshot":{}}],"Attribution Timeline":[{"timestamp":1656004937394,"snapshot":{"visitUtmSearchTerm":"Portugal1","visitUtmReferrer":"https://www.google.com1","visitUtmMedium":"email1","visitUtmSource":"gb_newsletter1","visitUtmCampaign":"gbdc_220621_breakingdeals1"}},{"timestamp":1656050185961,"snapshot":{"visitUtmSearchTerm":"Portugal2","visitUtmReferrer":"https://www.google.com2","visitUtmMedium":"email2","visitUtmSource":"gb_newsletter2","visitUtmCampaign":"gbdc_220621_breakingdeals2"}},{"timestamp":1656346905005,"snapshot":{"visitUtmMedium":"email3","visitUtmSource":"gb_newsletter3","visitUtmCampaign":"gbdc_220621_breakingdeals3"}}]},"audiences":["All Visitors"],"badges":["Badge - England LocationCountry Fan","Fan"],"metric_sets":{"Lifetime devices used":{"Android":18},"Lifetime browser types used":{"Chrome":18},"Lifetime operating systems used":{"Android":18},"Lifetime platforms used":{"browser":18},"Lifetime browser versions used":{"Chrome":18},"Interests: Countries (30 days)":{"England":4},"Interests: Destinations (30 days)":{"":4},"Interests: Venues (30 days)":{"Slaley Hall":4},"Interests: Location Regions (30 days)":{"North East England":4},"Utm Source - Tally":{"gb_newsletter":3},"Utm Campaign - Tally":{"gbdc_220621_breakingdeals":3},"Utm Medium - Tally":{"email":3},"Interests: Sales Region (30 Days)":{"UK & Ireland":4},"Interests: County / State (30 days)":{"Northumberland":4}}}};'; //1.1+
    
    @TestSetup static void createTestData(){
        Account acc = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert acc;
        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, 'New', acc)[0];
        insert opp;
    }

    //Confirm the response is successfully handled (the values extracted from JSON and set on Opp)
    @isTest static void testOppUpdateSuccess(){

        Opportunity opp = [Select Id, InitialUTMCampaign__c, InitialUTMSource__c, InitialUTMMedium__c,InitialUTMSearchTerm__c, InitialUTMReferrer__c From Opportunity];//1.1+
        system.assertEquals(null, opp.InitialUTMCampaign__c);
        system.assertEquals(null, opp.InitialUTMSource__c);
        system.assertEquals(null, opp.InitialUTMMedium__c);
        system.assertEquals(null, opp.InitialUTMSearchTerm__c);//1.1+
        system.assertEquals(null, opp.InitialUTMReferrer__c);//1.1+

        HttpResponse r = new HttpResponse(); 
        r.setBody(responseJSON);
 
        test.startTest();
            Boolean result = TealiumVisitorProfileResponseHandler.handleOutboundResponse(r, null, null, new Set<Id>{opp.Id});
        test.stopTest();

        system.assertEquals(true, result);

        system.assertEquals(0, [Select Count() From Golfbreaks__PlatformLog__c]);

        Opportunity oppAfterUpdate = [Select Id, InitialUTMCampaign__c, InitialUTMSource__c, InitialUTMMedium__c, InitialUTMSearchTerm__c, InitialUTMReferrer__c From Opportunity];//1.1+
        system.assertEquals('gbdc_220621_breakingdeals1', oppAfterUpdate.InitialUTMCampaign__c);
        system.assertEquals('gb_newsletter1', oppAfterUpdate.InitialUTMSource__c);
        system.assertEquals('email1', oppAfterUpdate.InitialUTMMedium__c);
        system.assertEquals('https://www.google.com1', oppAfterUpdate.InitialUTMReferrer__c);//1.1+
        system.assertEquals('Portugal1', oppAfterUpdate.InitialUTMSearchTerm__c);//1.1+

    }

    //Confirm the update is retried in the event of locking failures
    @isTest static void testOppUpdateRetry(){
        Opportunity opp = [Select Id, InitialUTMCampaign__c, InitialUTMSource__c, InitialUTMMedium__c, InitialUTMSearchTerm__c, InitialUTMReferrer__c From Opportunity];//1.1+
        system.assertEquals(null, opp.InitialUTMCampaign__c);
        system.assertEquals(null, opp.InitialUTMSource__c);
        system.assertEquals(null, opp.InitialUTMMedium__c);
        system.assertEquals(null, opp.InitialUTMSearchTerm__c);//1.1+
        system.assertEquals(null, opp.InitialUTMReferrer__c);//1.1+

        HttpResponse r = new HttpResponse(); 
        r.setBody(responseJSON);
 
        test.startTest();
            //Throw record locking exception on record update
            TealiumVisitorProfileResponseHandler.throwException = true;
            TealiumVisitorProfileResponseHandler.exceptionError = TealiumVisitorProfileResponseHandler.lockError;
            Boolean result = TealiumVisitorProfileResponseHandler.handleOutboundResponse(r, null, null, new Set<Id>{opp.Id});
        test.stopTest();

        system.assertEquals(false, result);//Confirm the initial attempt failed

        system.assertEquals(0, [Select Count() From Golfbreaks__PlatformLog__c]);

        //Confirm the values were set (on retry)
        Opportunity oppAfterUpdate = [Select Id, InitialUTMCampaign__c, InitialUTMSource__c, InitialUTMMedium__c, InitialUTMSearchTerm__c, InitialUTMReferrer__c From Opportunity];//1.1+
        system.assertEquals('gbdc_220621_breakingdeals1', oppAfterUpdate.InitialUTMCampaign__c);
        system.assertEquals('gb_newsletter1', oppAfterUpdate.InitialUTMSource__c);
        system.assertEquals('email1', oppAfterUpdate.InitialUTMMedium__c);
        system.assertEquals('https://www.google.com1', oppAfterUpdate.InitialUTMReferrer__c);//1.1+
        system.assertEquals('Portugal1', oppAfterUpdate.InitialUTMSearchTerm__c);//1.1+
    }

    //Confirm only the values of the EARLIEST attribution entry is set
    @isTest static void testDataSorting(){
        //Replace the June 24th entry (2nd entry) with a June 22nd timestamp (make it the earliest)
        responseJSON = responseJSON.replace('1656050185961', '1655904660000');

        Opportunity opp = [Select Id, InitialUTMCampaign__c, InitialUTMSource__c, InitialUTMMedium__c, InitialUTMSearchTerm__c, InitialUTMReferrer__c From Opportunity];//1.1+
        system.assertEquals(null, opp.InitialUTMCampaign__c);
        system.assertEquals(null, opp.InitialUTMSource__c);
        system.assertEquals(null, opp.InitialUTMMedium__c);
        system.assertEquals(null, opp.InitialUTMSearchTerm__c);//1.1+
        system.assertEquals(null, opp.InitialUTMReferrer__c);//1.1+

        HttpResponse r = new HttpResponse(); 
        r.setBody(responseJSON);
 
        test.startTest();
            Boolean result = TealiumVisitorProfileResponseHandler.handleOutboundResponse(r, null, null, new Set<Id>{opp.Id});
        test.stopTest();

        system.assertEquals(true, result);//Confirm the initial attempt failed

        system.assertEquals(0, [Select Count() From Golfbreaks__PlatformLog__c]);

        //Confirm the NEW (earliest) values were set
        Opportunity oppAfterUpdate = [Select Id, InitialUTMCampaign__c, InitialUTMSource__c, InitialUTMMedium__c, InitialUTMSearchTerm__c, InitialUTMReferrer__c From Opportunity];//1.1+
        system.assertEquals('gbdc_220621_breakingdeals2', oppAfterUpdate.InitialUTMCampaign__c);
        system.assertEquals('gb_newsletter2', oppAfterUpdate.InitialUTMSource__c);
        system.assertEquals('email2', oppAfterUpdate.InitialUTMMedium__c);
        system.assertEquals('https://www.google.com2', oppAfterUpdate.InitialUTMReferrer__c);//1.1+
        system.assertEquals('Portugal2', oppAfterUpdate.InitialUTMSearchTerm__c);//1.1+
    }


}