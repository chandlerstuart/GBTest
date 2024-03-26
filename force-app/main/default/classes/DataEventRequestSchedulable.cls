/*
Name: DataEventRequestSchedulable.cls
Copyright © 2022  Golfbreaks
======================================================
======================================================
Purpose:
-------

======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  Mark Cane&    2022-06-20  Initial development.
1.1  Mark Cane&    2022-08-28  Enhancements. Exceptions now abort the in-batch DER.
1.2  Mark Cane&    2022-08-28  Enhancements. dataEventRequestPerSchedulable.
*/
global without sharing class DataEventRequestSchedulable implements Schedulable{

    private String dataEventTypeName;

    public DataEventRequestSchedulable(){}

    public DataEventRequestSchedulable(String dataEventTypeName){
        this();

        this.dataEventTypeName = dataEventTypeName;
    }
    
    public void execute(SchedulableContext sc) {
        List<DataEventRequest__c> derToProcess;

        try {            

            if (sc!=null) System.abortJob(sc.getTriggerId());

            if (String.isBlank(dataEventTypeName)) return;

            Integer dataEventRequestPerSchedulable = 10;//1.2+

            DataEventType__mdt deferredDET = [select Id, DeferredRequestsPerSchedulable__c from DataEventType__mdt Where DeveloperName =:dataEventTypeName and IsTest__c=:Test.isRunningTest()];
            if (deferredDET!=null && deferredDET.DeferredRequestsPerSchedulable__c!=null && deferredDET.DeferredRequestsPerSchedulable__c>0) dataEventRequestPerSchedulable = (Integer)deferredDET.DeferredRequestsPerSchedulable__c;//1.2+
            
            Map<Id,DataEventRequest__c> recordIdToDER = new Map<Id,DataEventRequest__c>();
            Map<String,Map<Id,String>> dataEventTypeToRecordIds = new Map<String,Map<Id,String>>();
            
            if (Test.isRunningTest()) derToProcess = [select Id, DataEventType__c, RecordId__c from DataEventRequest__c where Status__c='New' and DataEventType__c=:dataEventTypeName limit:dataEventRequestPerSchedulable];//1.2~
            else derToProcess = [select Id, DataEventType__c, RecordId__c from DataEventRequest__c where Status__c='New' and DataEventType__c=:dataEventTypeName and CalloutDate__c<=:Datetime.now() order by CalloutDate__c asc limit:dataEventRequestPerSchedulable];//1.2~

            for (DataEventRequest__c der : derToProcess){

                if (!dataEventTypeToRecordIds.containsKey(der.DataEventType__c)) dataEventTypeToRecordIds.put(der.DataEventType__c, new Map<Id,String>());
                dataEventTypeToRecordIds.get(der.DataEventType__c).put(der.RecordId__c,'');

                recordIdToDER.put(der.RecordId__c,der);//1.x. Should be 1 der per recordId and DET combination.
            }
            if (!dataEventTypeToRecordIds.isEmpty()){

                DataEventTypeManager detm = new DataEventTypeManager(true);
                
                Map<Id,Map<Boolean,String>> recordIdToResult = detm.processDataEventTypesDetailed(dataEventTypeToRecordIds,true);

                Boolean isSuccess=false;
                List<String> resultDetails;

                for (Id recordId : recordIdToResult.keySet()){
                    
                    if (!recordIdToDER.containsKey(recordId)) continue;

                    isSuccess = new List<Boolean>(recordIdToResult.get(recordId).keySet())[0];                    
                    if (isSuccess){
                        recordIdToDER.get(recordId).Status__c = 'Complete';
                    } else {
                        recordIdToDER.get(recordId).Status__c = 'Aborted';
                        resultDetails = recordIdToResult.get(recordId).get(isSuccess)!=null ? recordIdToResult.get(recordId).get(isSuccess).split(DataEventTypeManager.DELIM_TOKEN) : new List<String>();
                    
                        recordIdToDER.get(recordId).AbortedReason__c = String.join(resultDetails, ',');
                    }
                }                                    
                if (!recordIdToDER.isEmpty()) updateDERStatus(recordIdToDER.values(), null, null);//1.1~
            }
            
            List<DataEventRequest__c> remainingDER = [select Id, CalloutDate__c from DataEventRequest__c where Status__c='New' and DataEventType__c=:dataEventTypeName and CalloutDate__c>=:Datetime.now() order by CalloutDate__c asc limit 1];            
            if (remainingDER.size()==1) DeferredDataEventTypeHelper.rescheduleCron(dataEventTypeName,remainingDER[0].CalloutDate__c);
        
        } catch(Exception e){
            LogHelper.logExceptions(e, 'DataEventRequestSchedulable', 'execute');
            if (derToProcess!=null && !derToProcess.isEmpty()) updateDERStatus(derToProcess, 'Aborted', e.getMessage());//1.1+
        }
    }

    private void updateDERStatus(List<DataEventRequest__c> derToUpdate, String overrideStatus, String abortedReason){//1.1+
        try {

            if (String.isNotBlank(overrideStatus)){
                for (DataEventRequest__c der : derToUpdate){ 
                    der.Status__c=overrideStatus; 
                    if (String.isNotBlank(abortedReason)) der.AbortedReason__c = abortedReason;
                }
            }
            List<Database.SaveResult> saveResults = Database.update(derToUpdate,true);
            LogHelper.logExceptions(saveResults, 'DataEventRequestSchedulable','updateDERStatus', derToUpdate);

        } catch(Exception e){ LogHelper.logExceptions(e, 'DataEventRequestSchedulable', 'updateDERStatus'); }
    }
}