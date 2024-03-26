/*
Name:  TealiumVisitorProfileResponseHandler.cls
======================================================
======================================================
Purpose: Response Handler for mapping data from 
Tealium Profile to Salesforce record(s) 
-------
======================================================
======================================================

History
------- 
Ver. Author        Date         Detail
1.0  J Radcliffe   2022-06-28   Initial development
1.1  C Stuart      2024-03-21   Introduced new properties to Attribution Entry Data Structure && Assigned new values to sObject align with updated Data Structure
*/
public with sharing class TealiumVisitorProfileResponseHandler implements IDataEventTypeResponseHandler3{

    @TestVisible public static Boolean throwException = false;
    @TestVisible public static String exceptionError = 'Error Updating the Opportunity';
    @TestVisible public static final String lockError = 'UNABLE_TO_LOCK_ROW';


    public class CustomException extends Exception{}
    
    public static Boolean handleOutboundResponse(HttpResponse r, String reshapedResponseBody, Id outboundCalloutId, Set<Id> recordIds) {
        
        try{
            //Verify Inputs
            if(recordIds == null || recordIds.size()!=1 ) throw new CustomException('Expected a single sObject record Id and received: '+recordIds);
            if(r == null || r.getBody() == null){
                System.debug('No data returned by Tealium vistor profile api call');
                return null;
            }

            Id recordId;
            for(Id recId: recordIds){recordId=recId;break;}

            //Attempt to deserialize JSON
            List<Object> attributionTimelineEntries = (List<Object>)((Map<String,Object>)((Map<String,Object>)((Map<String,Object>)JSON.deserializeUntyped(r.getBody()))?.get('visitor'))?.get('sequences'))?.get('Attribution Timeline');
            
            system.debug(attributionTimelineEntries);

            if(attributionTimelineEntries != null && attributionTimelineEntries.size()>0){
                
                List<AttributionEntry> attributionEntries = new List<AttributionEntry>();
                
                //Convert date/time value
                for(Object entry : attributionTimelineEntries){
                    system.debug(entry);
                    Map<String,Object> entryMap = (Map<String,Object>)entry;
                    if(!entryMap.containsKey('snapshot')) continue;
                    if(!entryMap.containsKey('timestamp')) continue;
                    attributionEntries.add(new AttributionEntry((long)entryMap.get('timestamp'),(Map<String,Object>)entryMap.get('snapshot')));
                }
                
                if(attributionEntries.size()==0) return true;

                //Sort timeline by date time - Meaning index [0] is the first tracking entry (for the last 30 days)
                attributionEntries.sort();

                //Assign values to SObject
                Opportunity opp = new Opportunity(Id=recordId);
                opp.InitialUTMSource__c = attributionEntries[0]?.snapshot?.visitUtmSource;
                opp.InitialUTMMedium__c = attributionEntries[0]?.snapshot?.visitUtmMedium;
                opp.InitialUTMCampaign__c = attributionEntries[0]?.snapshot?.visitUtmCampaign;
                opp.InitialUTMSearchTerm__c = attributionEntries[0]?.snapshot?.visitUtmSearchTerm;//1.1+
                opp.InitialUTMReferrer__c = attributionEntries[0]?.snapshot?.visitUtmReferrer;//1.1+

                //DML
                //Add support for retries (on locking failures)
                try{
                    if(throwException) throw new TestCodeException(exceptionError);
                    update opp;
                }catch(Exception e){
                    if(e.getMessage().containsIgnoreCase(lockError)){
                        system.enqueueJob(new handleRecordUpdateQueueable(opp,lockError));//Queue for retry
                    }else{
                        PlatformLogManager.logExceptions(e, 'TealiumVisitorProfileResponseHandler', 'handleOutboundResponse');
                        return false;
                    }
                    return false;
                }
            }
            return true;

        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'TealiumVisitorProfileResponseHandler','handleOutboundResponse');
            return false;
        }
    }

    public class AttributionEntry implements Comparable{
        public long timestamp;
        public DateTime convertedTimeStamp;
        public AttributionEntrySnapshot snapshot;
        public AttributionEntry(long timestamp, Map<String,Object> snapshot){
            if(timestamp != null) this.timestamp = timestamp;
            if(timestamp != null) this.convertedTimeStamp = Datetime.newInstance(timestamp);
            if(snapshot != null) this.snapshot = new AttributionEntrySnapshot(snapshot);
        }

        public Integer compareTo(Object compareTo) {
            AttributionEntry compareToEntry = (AttributionEntry)compareTo;
            if (convertedTimeStamp == compareToEntry.convertedTimeStamp) return 0;
            if (convertedTimeStamp > compareToEntry.convertedTimeStamp) return 1;
            return -1;        
        }
    }

    public class AttributionEntrySnapshot{
        public String visitUtmMedium;
        public String visitUtmSource;
        public String visitUtmCampaign;
        public String visitUtmSearchTerm;//1.1+
        public String visitUtmReferrer;//1.1+
        public AttributionEntrySnapshot(Map<String,Object> snapshot){
            if(snapshot == null || snapshot.values().size()==0) return;
            if(snapshot.containsKey('visitUtmMedium')) this.visitUtmMedium = (String)snapshot.get('visitUtmMedium');
            if(snapshot.containsKey('visitUtmSource')) this.visitUtmSource = (String)snapshot.get('visitUtmSource');
            if(snapshot.containsKey('visitUtmCampaign')) this.visitUtmCampaign = (String)snapshot.get('visitUtmCampaign');
            if(snapshot.containsKey('visitUtmSearchTerm')) this.visitUtmSearchTerm = (String)snapshot.get('visitUtmSearchTerm');//1.1+
            if(snapshot.containsKey('visitUtmReferrer')) this.visitUtmReferrer = (String)snapshot.get('visitUtmReferrer');//1.1+
        }

    }

    public class handleRecordUpdateQueueable implements Queueable{

        public Opportunity opp;
        public String lockError;

        public handleRecordUpdateQueueable(Opportunity opp, String lockError){
            this.opp = opp;
            this.lockError = lockError;
        }

        public void execute(QueueableContext context) {
            //Retry DML
            try{
                update opp;
            }catch(Exception e){
                if(e.getMessage().containsIgnoreCase(lockError)){
                    system.enqueueJob(new handleRecordUpdateQueueable(opp,lockError));//Queue for retry
                }else{
                    PlatformLogManager.logExceptions(e, 'handleRecordUpdateQueueable', 'execute');
                }
            }
        }
    }

}