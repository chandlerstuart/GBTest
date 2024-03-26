/*
Name: CallSummaryManagementSchedule
============================================
============================================
History:
--------
Ver.    Author      Date            Detail
1.1     M. Paddeo   05-10-2020      Initial Development
*/

global class CallSummaryManagementSchedule implements Schedulable {
    global void execute(SchedulableContext SC) {
        
        //To populate the Call Routing Snapshot lookup on NVM Call Summaries based on CallGUIDs
        
        //Query Call Routing Snapshots that were created in the past 31 minutes - the schedule runs every 30 - and store their IDs and CallGUIDs in a map
        List<GBWire__CallRoutingSnapshot__c> crs = [SELECT Id, GBWire__CallGUID__c FROM GBWire__CallRoutingSnapshot__c WHERE 
                                                    CreatedDate >= :Datetime.now().addMinutes(-90) AND 
                                                    Id NOT IN (SELECT Call_Routing_Snapshot__c FROM NVMStatsSF__NVM_Call_Summary__c)];
        Map<String,Id> mcrs = new Map<String,Id>();
        if(crs.size()>0){
            for(GBWire__CallRoutingSnapshot__c lcrs:crs) {
                mcrs.put(lcrs.GBWire__CallGUID__c,lcrs.Id);
            }
        }
        
        //Query NVM Call Summaries with the same CallGUIDs as the Snapshots above and populate the Call Routing Snapshot lookup based on the CallGUID
        List<NVMStatsSF__NVM_Call_Summary__c> nvmcs = [SELECT Id, Call_Routing_Snapshot__c, NVMStatsSF__CallGuid__c FROM NVMStatsSF__NVM_Call_Summary__c WHERE 
                                                       NVMStatsSF__CallGuid__c IN :mcrs.keySet() AND Call_Routing_Snapshot__c = null];
        if(nvmcs.size()>0) {
            for(NVMStatsSF__NVM_Call_Summary__c lnvmcs:nvmcs) {
                lnvmcs.Call_Routing_Snapshot__c = mcrs.get(lnvmcs.NVMStatsSF__CallGuid__c);
            }
        }
        
        try {
            Database.SaveResult[] results = database.update(nvmcs,false);
            PlatformLogManager.logExceptions(results, 'CallSummaryManagementSchedule', 'execute', nvmcs);
        } catch(exception e) {
            system.debug('*** -- Exception: ' + e + ' at ' + e.getLineNumber() + ' -- ***');
            PlatformLogManager.logExceptions(e, 'CallSummaryManagementSchedule', 'execute');
        }
    }
}