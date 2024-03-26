/*
Name:  ClearAgentAvailabilityFlagsScheduleTest.cls
======================================================
======================================================
Purpose:
-------
Test Class for ClearAgentAvailabilityFlagsSchedule.cls
======================================================
======================================================
History
------- 
Ver. Author        Date         Detail
1.1	 J Radcliffe   04-01-19		Initial Development
*/
@isTest
public class ClearAgentAvailabilityFlagsScheduleTest {
    
    @testSetup static void createTestData(){
        
        List<GBWire__AgentProfile__c> profiles = new List<GBWire__AgentProfile__c>();
        
        //Create 100 profiles with agents that are available
        for(integer i=0;i<100;i++){
            GBWire__AgentProfile__c ap = new GBWire__AgentProfile__c();
            ap.GBWire__IsAvailableSaturday__c = true;
            ap.GBWire__IsAvailableSunday__c = true;
            profiles.add(ap);
        }
        
        //Create 100 profiles with agents that are unavailable
        for(integer i=0;i<100;i++){
            GBWire__AgentProfile__c ap = new GBWire__AgentProfile__c();
            ap.GBWire__IsAvailableSaturday__c = false;
            ap.GBWire__IsAvailableSunday__c = false;
            profiles.add(ap);
        }
        try{
            insert profiles;
        }catch(exception e){
            system.debug('Error inserting agent profiles: '+e);
        }
    }
    
    static testmethod void testSchedule() {
        
        test.startTest();
        
        String jobId = System.schedule('ClearAgentAvailabilityFlagsSchedule',
                                       '0 0 0 ? * MON *', 
                                       new ClearAgentAvailabilityFlagsSchedule());
        test.stopTest();
        
        //Query all profiles for unavailable agents        
        GBWire__AgentProfile__c[] profiles = [Select Id, LastModifiedDate, CreatedDate, GBWire__IsAvailableSaturday__c, GBWire__IsAvailableSunday__c From GBWire__AgentProfile__c Where GBWire__IsAvailableSaturday__c = false and GBWire__IsAvailableSunday__c = false];
        //Confirm 200 are retrieved (100 already unavailable and 100 updated by the scheduled job)
        system.assertEquals(200, profiles.size());  
    }
}