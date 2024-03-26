/*
Name:  FeefoReviewOutboundCalloutGeneratorTest.cls
======================================================
======================================================
Purpose: Test Suite for FeefoReviewOutboundCalloutGenerator.cls
-------
Coverage 92%

====================================================== 
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2023-02-24  Initial development
*/
@isTest 
public with sharing class FeefoReviewOutboundCalloutGeneratorTest {

    public static String dataEventTypeName = 'Feefo_Review_Data';
    public static String summaryJSONResponse = '{"meta":{"count":1000,"pages":50,"verified_count":1000,"imported_count":0,"page_size":20}}';
    public static Integer defaultBatchSize = FeefoReviewOutboundCalloutGenerator.defaultBatchSize;

    public class SummaryResponseMockImpl implements HttpCalloutMock {

        public String responseBody;
        public Integer responseStatusCode;

        public SummaryResponseMockImpl(){
            responseBody = summaryJSONResponse;
            responseStatusCode=200;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            res.setStatusCode(responseStatusCode);
            return res;
        }
    }    

    public class SummaryResponseMockImpl2 implements HttpCalloutMock {

        public String responseBody;
        public Integer responseStatusCode;

        public SummaryResponseMockImpl2(){
            responseStatusCode=401;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(responseStatusCode);
            return res;
        }
    }    

    //1. Confirms the correct number of outbound callout records are created.
    //2. Confirms the endpoints are correctly constructed to retrieve each batch.
    @isTest static void testOutboundCalloutGenerationSuccess(){

        Test.setMock(HttpCalloutMock.class, new SummaryResponseMockImpl());//Success response

        DataEventType__mdt det = [Select Id, NamedCredentials__c, EndpointPathFormatString__c,
                                 (Select Id, DeveloperName__c, IntegerValue__c From DataEventTypeSettings__r) 
                                 From DataEventType__mdt Where DeveloperName=:dataEventTypeName];
        
        Integer batchSize = (det.DataEventTypeSettings__r.size()>0)?getConfiguredBatchSize(det.DataEventTypeSettings__r):defaultBatchSize;
        Integer expectedCalloutsRequired = (((Decimal)(1000)).divide(batchSize, 0, System.RoundingMode.UP)).intValue();

        List<OutboundCallout__c> callouts;
        test.startTest();
            FeefoReviewOutboundCalloutGenerator calloutGenerator = new FeefoReviewOutboundCalloutGenerator();
            callouts = calloutGenerator.buildOutboundCalloutList(det,UserInfo.getUserId());
        test.stopTest();

        system.assertEquals(expectedCalloutsRequired, callouts.size());

    }

    public static Integer getConfiguredBatchSize(List<DataEventTypeSetting__mdt> settings){
        if(settings == null) return defaultBatchSize;
        Integer batchSize;
        for(DataEventTypeSetting__mdt dets : settings){
            if(dets.DeveloperName__c != FeefoReviewOutboundCalloutGenerator.batch_size_setting) continue;
            batchSize = Integer.valueOf(dets.IntegerValue__c);
        }
        if(batchSize == null) batchSize = defaultBatchSize;
        return batchSize;
    }

    //Confirm exceptions are logged in the platform logs
    @isTest static void testOutboundCalloutGenerationException(){

        system.assertEquals(0, [Select Count() From Golfbreaks__PlatformLog__c]);
        
        List<OutboundCallout__c> callouts;
        test.startTest();
            FeefoReviewOutboundCalloutGenerator calloutGenerator = new FeefoReviewOutboundCalloutGenerator();
            callouts = calloutGenerator.buildOutboundCalloutList(null,UserInfo.getUserId());//Pass in null for the DET to force a failure
        test.stopTest();

        system.assertEquals(null, callouts);
        system.assertEquals(1, [Select Count() From Golfbreaks__PlatformLog__c]);

    }

    //Confirm fail responses are logged in the platform logs
    @isTest static void testOutboundCalloutGenerationResponseFailure(){

        Test.setMock(HttpCalloutMock.class, new SummaryResponseMockImpl2());//Fail response

        DataEventType__mdt det = [Select Id, NamedCredentials__c, EndpointPathFormatString__c,
                                 (Select Id, DeveloperName__c, IntegerValue__c From DataEventTypeSettings__r) 
                                 From DataEventType__mdt Where DeveloperName=:dataEventTypeName];

        List<OutboundCallout__c> callouts;
        test.startTest();
            FeefoReviewOutboundCalloutGenerator calloutGenerator = new FeefoReviewOutboundCalloutGenerator();
            callouts = calloutGenerator.buildOutboundCalloutList(det,UserInfo.getUserId());
        test.stopTest();

        system.assertEquals(null, callouts);
        system.assertEquals(2, [Select Count() From Golfbreaks__PlatformLog__c]);//1 fail log and 1 summary log

    }

}