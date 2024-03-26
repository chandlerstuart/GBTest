/*
Name:  ContentStackOutboundCalloutGenerator.cls
Copyright © 2021  Golfbreaks
======================================================
======================================================
Purpose:
-------
Implements the IOutboundCalloutGenerator class (IFramework)
This class is responsible for generating Outbound Callouts
that will subsequently retrieve data from Content Stack and store
as Generic Content and Generic Content Items
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2021-07-02  Initial development.
1.1  Mark Cane&    2021-10-10  Bug fixes. calloutsRequired calculation 319/5=63, fixed to be 64.
1.2  Mark Cane&    2021-10-13  Bug fixes. issue with space between GQL queryname and leading ( fixed.
1.3  J Radcliffe   2021-12-03  Exclude content reference by Email Configuration Settings from deletion.
1.4  Mark Cane&    2022-09-30  Bug fixes. Child record deletion is now constrained by Content Type and Sub Type.
1.5  Mark Cane&    2022-10-05  Bug fixes. Locale added to 1.4 fix.
1.6  J Radcliffe   2022-10-06  Enhancements. Add support for locale GQL queries.
*/
global with sharing class ContentStackOutboundCalloutGenerator implements IOutboundCalloutGenerator {

    @testVisible public static Integer calloutsRequired;
    
    global List<OutboundCallout__c> buildOutboundCalloutList(DataEventType__mdt det, Id scheduledJobId){

        try{
            //ENDPOINT: 
            //Base (Named Credentials):  https://graphql.contentstack.com
            //Relative (DET):  /stacks/{{api_key}}?environment=production

            //Retrieve the related Content Stack Content Type mtd
            ContentStackContentType__mdt contentType = [Select Id, GQLQueryName__c, BatchSize__c, ContentType__c, ContentSubtype__c, Locale__c From ContentStackContentType__mdt Where DataEventType__c = :det.Id];//1.5~
            Integer batchSize = (contentType.BatchSize__c != null)?Integer.valueOf(contentType.BatchSize__c):200;
            String locale = (contentType.Locale__c == null)?'en-gb':contentType.Locale__c;

            //Construct HTTP Request for investigative query with Content Stack (to identify the total number of content entries)
            String endpoint = 'callout:'+det.NamedCredentials__c+det.EndpointPathFormatString__c;
            //String countQueryBody = '{"query":"query{'+contentType.GQLQueryName__c+'(limit:1){total}}","variables":null}';
            String countQueryBody = '{"query":"query{'+contentType.GQLQueryName__c+'(locale:\\"'+locale+'\\",limit:1){total}}","variables":null}';
            
            countQueryBody = countQueryBody.replaceAll('\n', '');
            countQueryBody = countQueryBody.replaceAll('\r', '');

            system.debug('countQueryBody > '+countQueryBody);

            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            if(det?.CustomHeaders__r.size()>0){
                for(CustomHeader__mdt ch : det.CustomHeaders__r){
                    if(ch.Key__c == null || ch.Value__c == null) continue;
                    req.setHeader(ch.Key__c,ch.Value__c);
                }
            }
            req.setMethod('GET');
            req.setBody(countQueryBody);

            //Callout to Content Stack
            HttpResponse res = h.send(req);

            //Evaluate results and compare with batch size
            if(res.getStatusCode()!=200){
                String failMessage = 'Content Stack count query failure ('+contentType.Id+')';
                String failDetail = 'Response: '+res.getBody();
                Golfbreaks.PlatformLogManager.logCustomMessage(failDetail,failMessage,'ContentStackOutboundCalloutGenerator','buildOutboundCalloutList',null);
                return null;
            } 
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Integer contentCount = (Integer)((Map<String, Object>)((Map<String, Object>)results.get('data')).get(contentType.GQLQueryName__c)).get('total');

            if(contentCount>0){
                
                //1.3+
                Set<Id> defaultsAndOverrideContentIds = new Set<Id>();
                for(EmailContentConfiguration__c config : [Select DefaultContent__c, ContentOverride__c From EmailContentConfiguration__c]){
                    if(config.DefaultContent__c != null && !defaultsAndOverrideContentIds.contains(config.DefaultContent__c)) defaultsAndOverrideContentIds.add(config.DefaultContent__c);
                    if(config.ContentOverride__c != null && !defaultsAndOverrideContentIds.contains(config.ContentOverride__c)) defaultsAndOverrideContentIds.add(config.ContentOverride__c);
                }

                delete [select Id from GenericContent__c where ContentType__c=:contentType.ContentType__c and ContentSubtype__c=:contentType.ContentSubtype__c and Locale__c=:contentType.Locale__c and (NOT Id In:defaultsAndOverrideContentIds) ];//1.5~ 1.3~ Clear the Cache for this content type.
                delete [select Id from GenericContentItem__c where GenericContent__r.ContentType__c=:contentType.ContentType__c and GenericContent__r.ContentSubtype__c=:contentType.ContentSubtype__c and GenericContent__r.Locale__c=:contentType.Locale__c and GenericContent__c In:defaultsAndOverrideContentIds];//1.5~ 1.4~ 1.3+ Delete default/override content's related data (to be recreated by refresh cycle).
                delete [select Id from GenericContentReference__c where GenericContent__r.ContentType__c=:contentType.ContentType__c and GenericContent__r.ContentSubtype__c=:contentType.ContentSubtype__c and GenericContent__r.Locale__c=:contentType.Locale__c and GenericContent__c In:defaultsAndOverrideContentIds];//1.5~ 1.4~  1.3+ Delete default/override content's related data (to be recreated by refresh cycle).

                //1.1- calloutsRequired = (Integer)((Decimal)(contentCount/batchSize)).setScale(0,System.RoundingMode.UP);
                calloutsRequired = (((Decimal)(contentCount)).divide(batchSize, 0, System.RoundingMode.UP)).intValue();//1.1+

                //Construct Outbound Callouts and return to the framework
                List<OutboundCallout__c> outboundCallouts = new List<outboundCallout__c>();
                String requestBody; 
                String requestFormat;//1.2+

                for(Integer i=0;i<calloutsRequired;i++){

                    requestFormat = det.RequestFormat__c.replace(contentType.GQLQueryName__c+' (', contentType.GQLQueryName__c+'(');//1.2+

                    if(requestFormat.containsIgnoreCase(contentType.GQLQueryName__c+'(where:')){
                        requestBody = (i==0) ? '{"query":"'+requestFormat.replace(contentType.GQLQueryName__c+'(',contentType.GQLQueryName__c+'(limit:'+batchSize+', ')+'","variables":null}' : '{"query":"'+requestFormat.replace(contentType.GQLQueryName__c+'(',contentType.GQLQueryName__c+'(limit:'+batchSize+', skip:'+(i*batchSize)+', ')+'","variables":null}';
                    }else requestBody = (i==0)?'{"query":"'+requestFormat.replace(contentType.GQLQueryName__c,contentType.GQLQueryName__c+'(limit:'+batchSize+')')+'","variables":null}':'{"query":"'+requestFormat.replace(contentType.GQLQueryName__c,contentType.GQLQueryName__c+'(limit:'+batchSize+', skip:'+(i*batchSize)+')')+'","variables":null}';
                    
                    requestBody = requestBody.replace(contentType.GQLQueryName__c+'(',contentType.GQLQueryName__c+'(locale :\\"'+locale+'\\",');

                    requestBody = requestBody.replaceAll('\n', '');
                    requestBody = requestBody.replaceAll('\r', '');
                    outboundCallouts.add(new OutboundCallout__c(
                        Body__c=requestBody
                    ));
                }
                return outboundCallouts;
            }

            return null;
        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'ContentStackOutboundCalloutGenerator','buildOutboundCalloutList');
            return null;
        }
    }

}