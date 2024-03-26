/*
Name:  FeefoReviewOutboundCalloutGenerator.cls
Copyright © 2023  Golfbreaks
======================================================
======================================================
Purpose:
-------
Implements the IOutboundCalloutGenerator class (IFramework)
This class is responsible for generating Outbound Callouts
that will retrieve review data from Feefo and store in the 
Review__c, GolfCourseReview__c and VenueReview__c objects
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2023-02-21  Initial development.
*/
global with sharing class FeefoReviewOutboundCalloutGenerator implements IOutboundCalloutGenerator { 
 
    private static final String time_period_setting = 'time_period';
    @TestVisible public static final String batch_size_setting = 'batch_size'; 
    @TestVisible public static Integer defaultBatchSize = 20;

    public class CustomException extends Exception{}

    global List<OutboundCallout__c> buildOutboundCalloutList(DataEventType__mdt det, Id scheduledJobId){

        try{ 
 
            //ENDPOINT: 
            //Base (Named Credentials):  https://api.feefo.com
            //Relative (DET): /api/20/reviews/all?merchant_identifier={{merchant_id}}&updated_date_time={{Enum OR date/time representation of last modified date (UTC)}}&page_size={{batch size (max 100)}}&page={{batch number}}

            //Prepare default settings
            String timePeriodString = 'updated_date_time='+DateTime.newInstanceGmt(System.now().addDays(-1).yearGmt(), System.now().addDays(-1).monthGmt(), System.now().addDays(-1).dayGmt(), 0, 0, 0).format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');//By default retrieve reviews updated yesterday
            Integer batchSize = defaultBatchSize;

            //Query the relevant data event type settings
            List<DataEventTypeSetting__mdt> settings = [Select Id, DeveloperName__c, TextValue__c, IntegerValue__c From DataEventTypeSetting__mdt Where DataEventType__c = :det.Id];
            if(settings != null && settings.size()>0){
                for(DataEventTypeSetting__mdt setting : settings){
                    if(setting.DeveloperName__c == null) continue;
                    if(setting.DeveloperName__c?.equalsIgnoreCase(time_period_setting)){
                        //
                        if(setting.TextValue__c == null) continue;
                        setting.TextValue__c = setting.TextValue__c.deleteWhiteSpace();
                        if(setting.TextValue__c.equalsIgnoreCase('month') //Retrieve all reviews updated this month
                        || setting.TextValue__c.equalsIgnoreCase('year') //Retrieve all reviews updated this year
                        || setting.TextValue__c.equalsIgnoreCase('all')){ //Retrieve all reviews 
                            timePeriodString = 'since_updated_period='+setting.TextValue__c.toLowerCase();
                        }else{
                            //Retrieve reviews updated on the specified date
                            Integer dayOffset;
                            try{
                                dayOffset = Integer.valueOf(setting.TextValue__c);
                                if(dayOffset>0) throw new CustomException('Invalid configuration for '+time_period_setting+' setting. Expected: Integer <= 0. Actual: '+setting.TextValue__c);
                            }catch(Exception e){
                                Golfbreaks.PlatformLogManager.logExceptions(e,'FeefoReviewOutboundCalloutGenerator','buildOutboundCalloutList');
                            }
                            timePeriodString = 'updated_date_time='+DateTime.newInstanceGmt(System.now().addDays(dayOffset).yearGmt(), System.now().addDays(dayOffset).monthGmt(), System.now().addDays(dayOffset).dayGmt(), 0, 0, 1).format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
                        }
                    }else if(setting.DeveloperName__c?.equalsIgnoreCase(batch_size_setting)){
                        if(setting.IntegerValue__c != null){
                            if(setting.IntegerValue__c > 100) throw new CustomException('Batch Size. Feefo Limit Exceeded. Maximum 100 reviews per callout. Actual: '+setting.IntegerValue__c);
                            batchSize = Integer.valueOf(setting.IntegerValue__c);
                        } 
                    }
                }
            }

            //Construct the endpoints for the speculative summary callout and the callouts for data retrieval 
            String endpoint = 'callout:'+det.NamedCredentials__c+det.EndpointPathFormatString__c;//Scheduled DET suffix
            
            //Apply the merchant id and time period to the endpoints (to isolate the reviews that should be pulled to Salesforce)
            if(timePeriodString != null) endpoint = endpoint+'&'+timePeriodString;

            //Query summary api to count the number of reviews (applying the same query string filters) and calculate the number of trips required
            String summaryEndpoint = endpoint.replace('reviews/all', 'reviews/summary/all');
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(summaryEndpoint);
            req.setMethod('GET');
            req.setTimeout(12000);
            HttpResponse res = h.send(req);

            //Temporary logging for troubleshooting absent review data: 
            String logMessage = 'Review Summary Callout Log Entry';
            String logDetail = 'Review Summary GET Request Endpoint: '+summaryEndpoint+' Response: '+res.getBody();
            Golfbreaks.PlatformLogManager.logCustomMessage(logDetail,logMessage,'FeefoReviewOutboundCalloutGenerator','buildOutboundCalloutList',null);
            
            //Handle failures
            if(res.getStatusCode()!=200){
                String failMessage = 'Failed to perform initial speculative call to identify the total number of reviews';
                String failDetail = 'Response: '+res.getBody();
                Golfbreaks.PlatformLogManager.logCustomMessage(failDetail,failMessage,'FeefoReviewOutboundCalloutGenerator','buildOutboundCalloutList',null);
                return null;
            } 

            //Get total review count
            Integer reviewCount;
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            reviewCount = (Integer)((Map<String, Object>)results.get('meta')).get('count');

            //Calculate the number of trips required to retrieve all updated reviews
            if(reviewCount == 0) return null;
            Integer requiredCalloutsCount = 0;
            if(reviewCount<=batchSize){
                requiredCalloutsCount = 1;
            }else{
                requiredCalloutsCount = (((Decimal)(reviewCount)).divide(batchSize, 0, System.RoundingMode.UP)).intValue();
            }

            //Construct Outbound Callouts and return to the framework
            List<OutboundCallout__c> outboundCallouts = new List<outboundCallout__c>();

            for(Integer i=0;i<requiredCalloutsCount;i++){
                outboundCallouts.add(new OutboundCallout__c(Endpoint__c=endpoint+'&page_size='+batchSize+'&page='+(i+1)));
            }
    
            return outboundCallouts;
    
        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'FeefoReviewOutboundCalloutGenerator','buildOutboundCalloutList');
            return null;
        }

    }

}