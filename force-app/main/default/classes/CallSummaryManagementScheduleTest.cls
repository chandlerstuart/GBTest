/*
Name: CallSummaryManagementScheduleTest
==========================================
==========================================
Purpose:
--------
Test Class for CallSummaryManagementSchedule
==========================================
==========================================
History:
--------
Ver.    Author      Date        Detail
1.1     M Paddeo    06-10-2020  Initial Development
*/

@isTest
public class CallSummaryManagementScheduleTest {
    
    @testSetup static void createTestData() {
        
        List<GBWire__CallRoutingSnapshot__c> crs = new List<GBWire__CallRoutingSnapshot__c>();
        List<NVMStatsSF__NVM_Call_Summary__c> nvmcs = new List<NVMStatsSF__NVM_Call_Summary__c>();
        
        //Create 200 Call Routing Snapshots
        for(integer i=0;i<200;i++) {
            GBWire__CallRoutingSnapshot__c newcrs = new GBWire__CallRoutingSnapshot__c();
            newcrs.GBWire__CallGUID__c = '0173b95m-50c9-4b2e-a88b-741b21f393f' + i;
            newcrs.CreatedDate = system.now();
            crs.add(newcrs);
        }
        insert crs;
        
        //Create 200 NVM Call Summaries with the same CallGUID's
        for(integer i=0;i<200;i++) {
            NVMStatsSF__NVM_Call_Summary__c newnvmcs = new NVMStatsSF__NVM_Call_Summary__c();
            newnvmcs.NVMStatsSF__CallGuid__c = '0173b95m-50c9-4b2e-a88b-741b21f393f' + i;
            newnvmcs.CreatedDate = system.now();
            nvmcs.add(newnvmcs);
        }
        insert nvmcs;
    } 
    
    @isTest static void testSchedule() {
        
        test.startTest();
        
        String jobId = system.schedule('CallSummaryManagementSchedule',
                                       '0 5 * * * ?',
                                       new CallSummaryManagementSchedule());
        test.stopTest();
        
        //Query NVM Call Summaries that were created in the past 5 minutes and have a parent Call Routing Snapshot
        NVMStatsSF__NVM_Call_Summary__c[] nvmcs = [SELECT Id FROM NVMStatsSF__NVM_Call_Summary__c WHERE 
                                                   CreatedDate >= :Datetime.now().addMinutes(-5) AND Call_Routing_Snapshot__c != null];
        //Confirm that they're 200
        system.assertEquals(200, nvmcs.size());
    }
    
}