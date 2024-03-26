/*
Name:  ContentStackOutboundCalloutGeneratorTest.cls
Copyright © 2021  Golfbreaks
======================================================
======================================================
Purpose:
-------
Test Suite for ContentStackOutboundCalloutGenerator.cls
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2021-07-05  Initial development.
1.1  Mark Cane&    2021-10-10  Bug fixes. calloutsRequired calculation 319/5=63, fixed to be 64.
*/
@isTest
public with sharing class ContentStackOutboundCalloutGeneratorTest {
    
    public static final Integer contentCount = 460;
    public static final String failResponse = '{"errors":[{"message":"Cannot query field \"totalConnection\" on type \"AllLocation\".","locations":[{"line":3,"column":9}]}]}';
    public static String contentGQLQueryName;
    
    @isTest static void testCalloutGenerationPositive(){

        Test.setMock(HttpCalloutMock.class, new ContectStackCountQuerySuccessCalloutMock());//Success Response

        //Retrieve one of the data event types
        DataEventType__mdt scheduledDET = [Select Id, OutboundCalloutGeneratorClass__c, EndpointPathFormatString__c,
                                            HttpMethod__c, ContentType__c, ResponseHandler__c, CalloutTimeout__c,
                                            CalloutSequenceType__c, NamedCredentials__c, DeveloperName, RequestFormat__c,
                                            (Select Id, Key__c, Value__c From CustomHeaders__r),
                                            (Select Id, BatchSize__c,GQLQueryName__c From ContentStackContentTypes__r)
                                            From DataEventType__mdt Where IsActive__c = true and IsTest__c = false and Id IN (Select DataEventType__c From ContentStackContentType__mdt Where BatchSize__c > 0)][0];

        Integer batchSize = Integer.valueOf(scheduledDET.ContentStackContentTypes__r[0].BatchSize__c);
        //Expected Callouts = The total number of content entries broken down into batches (rounded to 1 to ensure the remainder are also retrieved);
        //1.1- Integer calloutsRequired = (Integer)((Decimal)(contentCount/batchSize)).setScale(0,System.RoundingMode.UP);
        Integer calloutsRequired = (((Decimal)(contentCount)).divide(batchSize, 0, System.RoundingMode.UP)).intValue();//1.1+
        contentGQLQueryName = scheduledDET.ContentStackContentTypes__r[0].GQLQueryName__c;

        test.startTest();
            ContentStackOutboundCalloutGenerator csocg = new ContentStackOutboundCalloutGenerator();
            List<OutboundCallout__c> ocs = csocg.buildOutboundCalloutList(scheduledDET,null);
        test.stopTest();    

        system.assertEquals(true, ocs.size()>0);
        system.assertEquals(calloutsRequired, ocs.size());
        for(Integer i=0;i < ocs.size();i++){
            system.assertEquals(true, ocs[i].Body__c.contains('limit:'+batchSize));
            if(i>0) system.assertEquals(true, ocs[i].Body__c.contains('skip:'+batchSize*i));
        }
    }

    @isTest static void testCalloutGenerationNegative(){

        Test.setMock(HttpCalloutMock.class, new ContectStackCountQueryFailCalloutMock());//Success Response

        //No log entries
        system.assertEquals(0, [Select Count() From Golfbreaks__PlatformLog__c]);

        //Retrieve one of the data event types
        DataEventType__mdt scheduledDET = [Select Id, OutboundCalloutGeneratorClass__c, EndpointPathFormatString__c,
                                            HttpMethod__c, ContentType__c, ResponseHandler__c, CalloutTimeout__c,
                                            CalloutSequenceType__c, NamedCredentials__c, DeveloperName, RequestFormat__c,
                                            (Select Id, Key__c, Value__c From CustomHeaders__r),
                                            (Select Id, BatchSize__c,GQLQueryName__c From ContentStackContentTypes__r)
                                            From DataEventType__mdt Where IsActive__c = true and IsTest__c = false and Id IN (Select DataEventType__c From ContentStackContentType__mdt Where BatchSize__c > 0)][0];

        Integer batchSize = Integer.valueOf(scheduledDET.ContentStackContentTypes__r[0].BatchSize__c);
        contentGQLQueryName = scheduledDET.ContentStackContentTypes__r[0].GQLQueryName__c;

        test.startTest();
            ContentStackOutboundCalloutGenerator csocg = new ContentStackOutboundCalloutGenerator();
            List<OutboundCallout__c> ocs = csocg.buildOutboundCalloutList(scheduledDET,null);
        test.stopTest();    

        system.assertEquals(null, ocs);
        //Confirm a log of the failure was generated
        system.assertEquals(1, [Select Count() From Golfbreaks__PlatformLog__c]);
        system.assertEquals(true, [Select golfbreaks__LogDetail__c From Golfbreaks__PlatformLog__c].golfbreaks__LogDetail__c.contains(failResponse));


    }

    public class ContectStackCountQuerySuccessCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"data":{"'+contentGQLQueryName+'":{"total":'+contentCount+'}}}');
            res.setStatusCode(200);
            return res;
        }
    }

    public class ContectStackCountQueryFailCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(failResponse);
            res.setStatusCode(400);//Bad Request
            return res;
        }
    }
}