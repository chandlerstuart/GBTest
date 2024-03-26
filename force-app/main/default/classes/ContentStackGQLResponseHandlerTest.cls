/*
Name:  ContentStackGQLResponseHandlerTest.cls
Copyright © 2021  Golfbreaks
======================================================
======================================================
Purpose:
-------
Test Suite for ContentStackGQLResponseHandler.cls (Coverage:76% at v1.7)
======================================================
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2021-07-23  Initial development.
1.1  Mark Cane     2021-09-15  Added singleTestCase4.
1.2  Mark Cane&    2021-10-27  Added singleTestCase3b to test missing system block (for Venues in the Location Venue list).
1.3  J Radcliffe   2021-12-03  Added singleTestCase1b to test the existing (reserved) default cache records are successfully updated and related records created.
1.4  Mark Cane&    2021-12-23  Added singleTestCase6.
1.5  Mark Cane&    2022-01-16  Added singleTestCase7a+b.
1.6  Mark Cane&    2022-03-09  Added negativeTestCase1.
1.7  Mark Cane&    2024-03-09  Added singleTestCase8a+b.
1.8  Mark Cane&    2024-03-20  Added singleTestCase8c+d.
1.9  Mark Cane&    2024-03-21  Added singleTestCase8e.
*/
@isTest
public with sharing class ContentStackGQLResponseHandlerTest {

    private static final String locationVenuesContentTypeDET = 'Content_Stack_Location_Venue_Caching';
    private static final String LocationVenueConfigurationCSCT = 'Location_Venue_Configuration';

    private static final String articleContentTypeDET = 'Content_Stack_Article_Caching';//1.1+
    private static final String articleConfigurationCSCT = 'Article_Configuration';//1.1+

    private static Map<String,String> connectionNameToParsingInstructions = new Map<String,String>();
    private static Map<String,String> listNameToCachingInstructions = new Map<String,String>();
    private static Map<String,String> listNameToFilterInstructions = new Map<String,String>();

    //singleTestCase1 - Test the end to end process (from parsing/reshaping to populating the cache)
    //singleTestCase2 - Test Parsing
    //singleTestCase3 - Test Cache population
    //singleTestCase4 - Test Generic Content Reference population.
    //singleTestCase5 - Test Cache population - Location Type.
    //singleTestCase6 - Test Cache population - Venue SalesforceId.
    //singleTestCase7a - Test Cache population - Content Type Field Mappings. Simple case.
    //singleTestCase7b - Test Cache population - Content Type Field Mappings. Complex case.
    //singleTestCase8a - Test Parent filters.
    //singleTestCase8b - Test Child filters.
    //singleTestCase8c - Test Parent (Generic Content) Subfilters.
    //singleTestCase8d - Test Child (Generic Content Item) Subfilters.
    //singleTestCase8e - Test Child (Generic Content Item) Subfilters - scenario test.
    //negativeTestCase1 - Test Cache population - Empty list.

    @testSetup static void setup(){

        system.assertEquals(1, [Select Count() From DataEventType__mdt Where DeveloperName = :locationVenuesContentTypeDET]);
        system.assertEquals(1, [Select Count() From ContentStackContentType__mdt Where DeveloperName = :LocationVenueConfigurationCSCT]);

        //Create a test Outbound Callouts
        insert new OutboundCallout__c(Status__c='Complete',AcceptHeader__c='*/*',ContentTypeHeader__c='application/json',Endpoint__c='https://graphql.contentstack.com/stacks/blt99dd26276e65134a?environment=production',Method__c='POST',DataEventType__c=locationVenuesContentTypeDET);
    }

    @isTest public static void singleTestCase1(){    
        
        system.assertEquals(0, [Select Count() From GenericContent__c]);
        
        //<-- test location venue GraphQL response.
        String responseBody = '{"data":{"all_location":{"items":[{"system":{"uid":"blt72b9040d7e61f5e7"},"location_name":"UK & Ireland","overview":{"product_listsConnection":{"edges":[{"node":{"title":"UK product list","itemsConnection":{"edges":[{"node":{"title":"The Belfry","reference_entityConnection":{"edges":[{"node":{"system":{"uid":"blt8871e98bbf2f5673"},"full_name":"The Belfry","url":"the-belfry","lead_product":{"price":129,"saving":71,"name":"1 night\'s bed & breakfast and 2 rounds of golf (1 round PGA National & 1 round Derby)"},"dataConnection":{"edges":[{"node":{"venue_information":{"official_star_rating":4}}}]},"imagesConnection":{"edges":[{"node":{"fileConnection":{"edges":[{"node":{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt447ea9796f1322cd/5eea1355293eef25d2b6e029/TheBelfry_Clubhouse.jpg"}}]}}},{"node":{"fileConnection":{"edges":[{"node":{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blta5a4fd05fbbb91d8/5bf4165d1724151a76f6e4c1/rs189rs6068tbfoodanddrinksamslounge-lpr.jpg"}}]}}},{"node":{"fileConnection":{"edges":[{"node":{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/bltebb624e80b4b1115/5bf4165b8fcbe9ed7694eca3/rs157rs5899tbfbbrab-bar-lpr.jpg"}}]}}}]}}}]}}},{"node":{"title":"Forest of Arden","reference_entityConnection":{"edges":[{"node":{"system":{"uid":"blt53939687faefd566"},"full_name":"Forest of Arden Marriott Hotel & Country Club","url":"forest-of-arden","lead_product":{"price":129,"saving":0,"name":"1 night\'s dinner, bed & breakfast and 2 rounds of golf (1 round Arden & 1 round Aylesford Course) "},"dataConnection":{"edges":[{"node":{"venue_information":{"official_star_rating":4}}}]},"imagesConnection":{"edges":[{"node":{"fileConnection":{"edges":[{"node":{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt6c4a97f3a9e9b18f/5f22c7fa0e38240638cd8582/forest-of-arden-18th-and-clubhouse.jpg"}}]}}},{"node":{"fileConnection":{"edges":[{"node":{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt1045398b5240a728/5bf416468fcbe9ed7694ec97/mhmangsgrill2-copy.jpg"}}]}}},{"node":{"fileConnection":{"edges":[{"node":{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/bltfdbfbd81e6e1d070/5bf416478054f9d2754cb0dc/pool-image.jpg"}}]}}}]}}}]}}},{"node":{"title":"The Celtic Manor Resort","reference_entityConnection":{"edges":[{"node":{"system":{"uid":"blt97323a28266ff917"},"full_name":"Celtic Manor Resort","url":"celtic-manor","lead_product":{"price":102,"saving":33,"name":"1 night\'s bed & breakfast (Manor House) and 2 rounds of golf (1 round Roman Road & 1 round The Montgomerie Course)"},"dataConnection":{"edges":[{"node":{"venue_information":{"official_star_rating":5}}}]},"imagesConnection":{"edges":[{"node":{"fileConnection":{"edges":[{"node":{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt5cf542bf14df8a57/5bf2ad3544d7f7e46cb70417/romanroadcourse12th.jpg"}}]}}},{"node":{"fileConnection":{"edges":[{"node":{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt1286244ae2eabe48/5bf2ad369ac4a2eb65e4894e/resorthotelatrium.jpg"}}]}}},{"node":{"fileConnection":{"edges":[{"node":{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/bltc5232d806f841cae/5bf2ad377fe327b572795e83/cen-restaurant-decor-9.jpg"}}]}}}]}}}]}}},{"node":{"title":"Slaley Hall","reference_entityConnection":{"edges":[{"node":{"system":{"uid":"blt3f7e3631f11bc9cf"},"full_name":"Slaley Hall","url":"slaley-hall","lead_product":{"price":99,"saving":0,"name":"1 night\'s dinner, bed & breakfast and 2 rounds of golf (1 round Priestman & 1 round Hunting Course) "},"dataConnection":{"edges":[{"node":{"venue_information":{"official_star_rating":4}}}]},"imagesConnection":{"edges":[{"node":{"fileConnection":{"edges":[{"node":{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/bltf32036cd30d94b7e/5bf41b3cf751bc333d881ce6/rs3631slaley-hall-exterior22.jpg"}}]}}},{"node":{"fileConnection":{"edges":[{"node":{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/bltb9d85b291ccabf7d/5bf41b3dc0548d1877a31110/bar.jpg"}}]}}},{"node":{"fileConnection":{"edges":[{"node":{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/bltac14c30b598c1945/5bf41b488fcbe9ed7694ed6d/rs5546shleisurepoolhottub.jpg"}}]}}}]}}}]}}}]}}}]}}}]}}}';
        HttpResponse res = new HttpResponse();
        res.setBody(responseBody);

        Id outboundCalloutId = [Select Id From OutboundCallout__c Where DataEventType__c = :locationVenuesContentTypeDET].Id;
        
        System.Test.startTest();
            ContentStackGQLResponseHandler handler = new ContentStackGQLResponseHandler();
            handler.handleOutboundResponse(res, null, outboundCalloutId);
        System.Test.stopTest();

        List<GenericContent__c> contentCache = [Select Id, ContentJSON__c, ContentType__c, ContentSubtype__c, ContentId__c, IsContentCollection__c, (Select Id, ContentId__c, ContentJSON__c From GenericContentItems__r) From GenericContent__c];
        
        //Assertions
        system.assertNotEquals(null, contentCache);
        system.assertEquals(1, contentCache.size());//One location
        for(GenericContent__c content : contentCache){
            system.assertNotEquals(null, content.ContentId__c);
            system.assertEquals(null, content.ContentJSON__c);//Expected null as data will be stored at child level
            system.assertEquals(true, content.IsContentCollection__c);
            system.assertEquals('Generic List', content.ContentType__c);
            system.assertEquals('Venue', content.ContentSubtype__c);
            system.assertEquals(true, content.GenericContentItems__r.size()>0);//Multiple Venues
            for(GenericContentItem__c contentItem : content.GenericContentItems__r){
                system.assertNotEquals(null, contentItem.ContentId__c);
                system.assertNotEquals(null, contentItem.ContentJSON__c);
            }

        }
    }

    @isTest public static void singleTestCase1b(){    
        
        system.assertEquals(0, [Select Count() From GenericContent__c]);
        
        //<-- test location venue GraphQL response.
        String responseBody = '{"data":{"all_location":{"items":[{"system":{"uid":"blt72b9040d7e61f5e7"},"location_name":"UK & Ireland","overview":{"product_listsConnection":{"edges":[{"node":{"title":"UK product list","itemsConnection":{"edges":[{"node":{"title":"The Belfry","reference_entityConnection":{"edges":[{"node":{"system":{"uid":"blt8871e98bbf2f5673"},"full_name":"The Belfry","url":"the-belfry","lead_product":{"price":129,"saving":71,"name":"1 night\'s bed & breakfast and 2 rounds of golf (1 round PGA National & 1 round Derby)"},"dataConnection":{"edges":[{"node":{"venue_information":{"official_star_rating":4}}}]},"imagesConnection":{"edges":[{"node":{"fileConnection":{"edges":[{"node":{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt447ea9796f1322cd/5eea1355293eef25d2b6e029/TheBelfry_Clubhouse.jpg"}}]}}},{"node":{"fileConnection":{"edges":[{"node":{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blta5a4fd05fbbb91d8/5bf4165d1724151a76f6e4c1/rs189rs6068tbfoodanddrinksamslounge-lpr.jpg"}}]}}},{"node":{"fileConnection":{"edges":[{"node":{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/bltebb624e80b4b1115/5bf4165b8fcbe9ed7694eca3/rs157rs5899tbfbbrab-bar-lpr.jpg"}}]}}}]}}}]}}},{"node":{"title":"Forest of Arden","reference_entityConnection":{"edges":[{"node":{"system":{"uid":"blt53939687faefd566"},"full_name":"Forest of Arden Marriott Hotel & Country Club","url":"forest-of-arden","lead_product":{"price":129,"saving":0,"name":"1 night\'s dinner, bed & breakfast and 2 rounds of golf (1 round Arden & 1 round Aylesford Course) "},"dataConnection":{"edges":[{"node":{"venue_information":{"official_star_rating":4}}}]},"imagesConnection":{"edges":[{"node":{"fileConnection":{"edges":[{"node":{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt6c4a97f3a9e9b18f/5f22c7fa0e38240638cd8582/forest-of-arden-18th-and-clubhouse.jpg"}}]}}},{"node":{"fileConnection":{"edges":[{"node":{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt1045398b5240a728/5bf416468fcbe9ed7694ec97/mhmangsgrill2-copy.jpg"}}]}}},{"node":{"fileConnection":{"edges":[{"node":{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/bltfdbfbd81e6e1d070/5bf416478054f9d2754cb0dc/pool-image.jpg"}}]}}}]}}}]}}},{"node":{"title":"The Celtic Manor Resort","reference_entityConnection":{"edges":[{"node":{"system":{"uid":"blt97323a28266ff917"},"full_name":"Celtic Manor Resort","url":"celtic-manor","lead_product":{"price":102,"saving":33,"name":"1 night\'s bed & breakfast (Manor House) and 2 rounds of golf (1 round Roman Road & 1 round The Montgomerie Course)"},"dataConnection":{"edges":[{"node":{"venue_information":{"official_star_rating":5}}}]},"imagesConnection":{"edges":[{"node":{"fileConnection":{"edges":[{"node":{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt5cf542bf14df8a57/5bf2ad3544d7f7e46cb70417/romanroadcourse12th.jpg"}}]}}},{"node":{"fileConnection":{"edges":[{"node":{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt1286244ae2eabe48/5bf2ad369ac4a2eb65e4894e/resorthotelatrium.jpg"}}]}}},{"node":{"fileConnection":{"edges":[{"node":{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/bltc5232d806f841cae/5bf2ad377fe327b572795e83/cen-restaurant-decor-9.jpg"}}]}}}]}}}]}}},{"node":{"title":"Slaley Hall","reference_entityConnection":{"edges":[{"node":{"system":{"uid":"blt3f7e3631f11bc9cf"},"full_name":"Slaley Hall","url":"slaley-hall","lead_product":{"price":99,"saving":0,"name":"1 night\'s dinner, bed & breakfast and 2 rounds of golf (1 round Priestman & 1 round Hunting Course) "},"dataConnection":{"edges":[{"node":{"venue_information":{"official_star_rating":4}}}]},"imagesConnection":{"edges":[{"node":{"fileConnection":{"edges":[{"node":{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/bltf32036cd30d94b7e/5bf41b3cf751bc333d881ce6/rs3631slaley-hall-exterior22.jpg"}}]}}},{"node":{"fileConnection":{"edges":[{"node":{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/bltb9d85b291ccabf7d/5bf41b3dc0548d1877a31110/bar.jpg"}}]}}},{"node":{"fileConnection":{"edges":[{"node":{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/bltac14c30b598c1945/5bf41b488fcbe9ed7694ed6d/rs5546shleisurepoolhottub.jpg"}}]}}}]}}}]}}}]}}}]}}}]}}}';
        HttpResponse res = new HttpResponse();
        res.setBody(responseBody);

        Id outboundCalloutId = [Select Id From OutboundCallout__c Where DataEventType__c = :locationVenuesContentTypeDET].Id;
        
        System.Test.startTest();
            ContentStackGQLResponseHandler handler = new ContentStackGQLResponseHandler();
            handler.handleOutboundResponse(res, null, outboundCalloutId);

            List<GenericContent__c> contentCache = [Select Id, Name, ContentJSON__c, ContentType__c, ContentSubtype__c, ContentId__c, IsContentCollection__c, (Select Id, ContentId__c, ContentJSON__c From GenericContentItems__r) From GenericContent__c];
            
            //Assertions
            system.assertNotEquals(null, contentCache);
            system.assertEquals(1, contentCache.size());//One location
            for(GenericContent__c content : contentCache){
                system.assertNotEquals(null, content.ContentId__c);
                system.assertEquals(null, content.ContentJSON__c);//Expected null as data will be stored at child level
                system.assertEquals(true, content.IsContentCollection__c);
                system.assertEquals('Generic List', content.ContentType__c);
                system.assertEquals('Venue', content.ContentSubtype__c);
                system.assertEquals(true, content.GenericContentItems__r.size()>0);//Multiple Venues
                for(GenericContentItem__c contentItem : content.GenericContentItems__r){
                    system.assertNotEquals(null, contentItem.ContentId__c);
                    system.assertNotEquals(null, contentItem.ContentJSON__c);
                }

            }

            //Insert Email Content Configuration referencing the first content record as the default
            GenericContent__c defaultGenericContent = contentCache[0];
            insert new EmailContentConfiguration__c(Name='Default Content Reference',ExpectedContentType__c='Generic List',ExpectedContentSubtype__c='Venue',DefaultContent__c=defaultGenericContent.Id);

            //Delete all remaining records (prepare for cache refresh)
            delete [Select Id From GenericContent__c Where (Not Id =:defaultGenericContent.Id)];
            delete [Select Id From GenericContentItem__c];
            
            //Confirm all items have been deleted
            system.assertEquals(0, [Select Count() From GenericContentItem__c]);
            //Confirm the default is the only record that remains
            system.assertEquals(1, [Select Count() From GenericContent__c]);

            //Execute again and confirm the default Id emains, the content and has been updated and related records recreated 
            handler = new ContentStackGQLResponseHandler();
            handler.handleOutboundResponse(res, null, outboundCalloutId);

        System.Test.stopTest();

        Map<Id, GenericContent__c> contentCacheMap = new Map<Id,GenericContent__c>([Select Id, Name, ContentJSON__c, ContentType__c, ContentSubtype__c, ContentId__c, IsContentCollection__c, (Select Id, ContentId__c, ContentJSON__c From GenericContentItems__r) From GenericContent__c]);
        //Confirm the default still exists (and no duplicates were created)
        system.assertEquals(1, contentCacheMap.keySet().size());
        system.assertEquals(true, contentCacheMap.containsKey(defaultGenericContent.Id));
        //Confirm the related items were (re)created successfully (against the existing record)
        system.assertEquals(true, contentCacheMap.values()[0].GenericContentItems__r.size()>0);
    }

    @isTest public static void singleTestCase2(){

        String parsingInstructions='product_listsConnection,promote';
        parsingInstructions+='|itemsConnection,rename=>venues';
        parsingInstructions+='|reference_entityConnection,promote';
        parsingInstructions+='|dataConnection,promote';
        parsingInstructions+='|imagesConnection,rename=>images';
        parsingInstructions+='|fileConnection,promote';//<-- parsing instructions (promote or rename) field value [GQL Parsing Instructions] held on the Content Stack Content Type record.
        
        for (String pi : parsingInstructions.split('\\|')){ 

            List<String> connectionInstructions = pi.split(','); 
            if (connectionInstructions.size()<2) continue;

            connectionNameToParsingInstructions.put(connectionInstructions[0], connectionInstructions[1]);
        }

        //Set/override parsing instructions
        ContentStackGQLResponseHandler.connectionNameToParsingInstructions = connectionNameToParsingInstructions;

        //<-- test location venue GraphQL response.
        String input = '{ "data": { "all_location": { "items": [ { "uid": "12345", "location_name": "Spain", "overview": { "product_listsConnection": { "edges": [ { "node": { "title": "Spain", "itemsConnection": { "edges": [ { "node": { "title": "Hotel La Manga Principe Felipe", "reference_entityConnection": { "edges": [ { "node": { "full_name": "Hotel La Manga Principe Felipe", "url": "la-manga-club", "lead_product": { "price": 295, "saving": 0, "name": "3 nights bed & breakfast at the Hotel La Manga Principe Felipe and 2 rounds of golf (West Course, North Course or South Course) " }, "dataConnection": { "edges": [ { "node": { "venue_information": { "official_star_rating": 5 } } } ] }, "imagesConnection": { "edges": [ { "node": { "fileConnection": { "edges": [ { "node": { "url": "https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt8612d249fa8192a3/5d84dbbd25745254cb353738/north-course-la-manga-5.jpg" } } ] } } }, { "node": { "fileConnection": { "edges": [ { "node": { "url": "https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt4ecc1ce23b5ca2eb/5d84d990614a7d122d37b324/la-manga-lobby.jpg" } } ] } } } ] } } } ] } } }, { "node": { "title": "La Cala Resort", "reference_entityConnection": { "edges": [ { "node": { "full_name": "La Cala Golf Resort", "url": "la-cala-resort", "lead_product": { "price": 219, "saving": 0, "name": "3 nights bed & breakfast at La Cala Resort & Spa and 2 rounds of golf (La Cala Asia, La Cala America or La Cala Europa) " }, "dataConnection": { "edges": [ { "node": { "venue_information": { "official_star_rating": 4 } } } ] }, "imagesConnection": { "edges": [ { "node": { "fileConnection": { "edges": [ { "node": { "url": "https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt4dd65b3a0c9577ea/5ef06c0b688c1c62a49af02d/Asia-Hole_18-final.jpg" } } ] } } } ] } } } ] } } } ] } } } ] } } }, { "overview": { "product_listsConnection": { "edges": [] } } }, { "location_name": "Northern Ireland", "uid": "67890", "overview": { "product_listsConnection": { "edges": [ { "node": { "title": "Northern Ireland", "itemsConnection": { "edges": [ { "node": { "title": "Galgorm Resort & Spa", "reference_entityConnection": { "edges": [ { "node": { "full_name": "Galgorm Resort & Spa", "url": "galgorm-resort-spa", "lead_product": { "price": 195, "saving": 0, "name": "1 nights bed & breakfast and 2 rounds of golf (Galgorm Castle Course)" }, "dataConnection": { "edges": [ { "node": { "venue_information": { "official_star_rating": 4 } } } ] }, "imagesConnection": { "edges": [ { "node": { "fileConnection": { "edges": [ { "node": { "url": "https://images.contentstack.io/v3/assets/blt99dd26276e65134a/bltfcb2fd32ffb744f4/5bf421055fc57fff7689ea3a/banner-galgorm-resort-image-copy.jpg" } } ] } } } ] } } } ] } } }, { "node": { "title": "Hilton Templepatrick", "reference_entityConnection": { "edges": [ { "node": { "full_name": "Hilton Belfast Templepatrick", "url": "hilton-belfast-templepatrick", "lead_product": { "price": 89, "saving": 0, "name": "1 nights bed & breakfast and 2 rounds of golf (Hilton Templepatrick Golf Course) " }, "dataConnection": { "edges": [ { "node": { "venue_information": { "official_star_rating": 4 } } } ] }, "imagesConnection": { "edges": [ { "node": { "fileConnection": { "edges": [ { "node": { "url": "https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt737aad9ec3cfc3ec/5bf41e2a29bffcfc75f466c8/90309.jpg" } } ] } } }, { "node": { "fileConnection": { "edges": [ { "node": { "url": "https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt5a48a3d9889e5911/5bf41e2c807ded0276583258/hotel-lobby-copy.jpg" } } ] } } } ] } } } ] } } } ] } } } ] } } } ] } } }';

        System.Test.startTest();
            Object o = ContentStackGQLResponseHandler.parseObject(JSON.deserializeUntyped(input));
        System.Test.stopTest();

        System.debug(LoggingLevel.ERROR,'Output='+o);

        String actualOutput = JSON.serialize(o);
        System.debug(LoggingLevel.ERROR,actualOutput);

        //String expectedOutput = '{"data":{"all_location":{"items":[{"overview":{"venues":[{"images":[{"file_url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt8612d249fa8192a3/5d84dbbd25745254cb353738/north-course-la-manga-5.jpg"},{"file_url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt4ecc1ce23b5ca2eb/5d84d990614a7d122d37b324/la-manga-lobby.jpg"}],"venue_information":{"official_star_rating":5},"lead_product":{"name":"3 nights bed & breakfast at the Hotel La Manga Principe Felipe and 2 rounds of golf (West Course, North Course or South Course) ","saving":0,"price":295},"reference_entity_url":"la-manga-club","reference_entity_full_name":"Hotel La Manga Principe Felipe","title":"Hotel La Manga Principe Felipe"},{"images":[{"file_url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt4dd65b3a0c9577ea/5ef06c0b688c1c62a49af02d/Asia-Hole_18-final.jpg"}],"venue_information":{"official_star_rating":4},"lead_product":{"name":"3 nights bed & breakfast at La Cala Resort & Spa and 2 rounds of golf (La Cala Asia, La Cala America or La Cala Europa) ","saving":0,"price":219},"reference_entity_url":"la-cala-resort","reference_entity_full_name":"La Cala Golf Resort","title":"La Cala Resort"}],"product_lists_title":"Spain"},"location_name":"Spain","uid":"12345"},{"overview":{}},{"overview":{"venues":[{"images":[{"file_url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/bltfcb2fd32ffb744f4/5bf421055fc57fff7689ea3a/banner-galgorm-resort-image-copy.jpg"}],"venue_information":{"official_star_rating":4},"lead_product":{"name":"1 nights bed & breakfast and 2 rounds of golf (Galgorm Castle Course)","saving":0,"price":195},"reference_entity_url":"galgorm-resort-spa","reference_entity_full_name":"Galgorm Resort & Spa","title":"Galgorm Resort & Spa"},{"images":[{"file_url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt737aad9ec3cfc3ec/5bf41e2a29bffcfc75f466c8/90309.jpg"},{"file_url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt5a48a3d9889e5911/5bf41e2c807ded0276583258/hotel-lobby-copy.jpg"}],"venue_information":{"official_star_rating":4},"lead_product":{"name":"1 nights bed & breakfast and 2 rounds of golf (Hilton Templepatrick Golf Course) ","saving":0,"price":89},"reference_entity_url":"hilton-belfast-templepatrick","reference_entity_full_name":"Hilton Belfast Templepatrick","title":"Hilton Templepatrick"}],"product_lists_title":"Northern Ireland"},"uid":"67890","location_name":"Northern Ireland"}]}}}';
        String expectedOutput = '{"data":{"all_location":{"items":[{"overview":{"venues":[{"images":[{"file_url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt8612d249fa8192a3/5d84dbbd25745254cb353738/north-course-la-manga-5.jpg"},{"file_url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt4ecc1ce23b5ca2eb/5d84d990614a7d122d37b324/la-manga-lobby.jpg"}],"venue_information":{"official_star_rating":5},"lead_product":{"name":"3 nights bed & breakfast at the Hotel La Manga Principe Felipe and 2 rounds of golf (West Course, North Course or South Course) ","saving":0,"price":295},"reference_entity_url":"la-manga-club","reference_entity_full_name":"Hotel La Manga Principe Felipe","title":"Hotel La Manga Principe Felipe"},{"images":[{"file_url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt4dd65b3a0c9577ea/5ef06c0b688c1c62a49af02d/Asia-Hole_18-final.jpg"}],"venue_information":{"official_star_rating":4},"lead_product":{"name":"3 nights bed & breakfast at La Cala Resort & Spa and 2 rounds of golf (La Cala Asia, La Cala America or La Cala Europa) ","saving":0,"price":219},"reference_entity_url":"la-cala-resort","reference_entity_full_name":"La Cala Golf Resort","title":"La Cala Resort"}],"product_lists_title":"Spain"},"location_name":"Spain","uid":"12345"},{"overview":{}},{"overview":{"venues":[{"images":[{"file_url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/bltfcb2fd32ffb744f4/5bf421055fc57fff7689ea3a/banner-galgorm-resort-image-copy.jpg"}],"venue_information":{"official_star_rating":4},"lead_product":{"name":"1 nights bed & breakfast and 2 rounds of golf (Galgorm Castle Course)","saving":0,"price":195},"reference_entity_url":"galgorm-resort-spa","reference_entity_full_name":"Galgorm Resort & Spa","title":"Galgorm Resort & Spa"},{"images":[{"file_url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt737aad9ec3cfc3ec/5bf41e2a29bffcfc75f466c8/90309.jpg"},{"file_url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt5a48a3d9889e5911/5bf41e2c807ded0276583258/hotel-lobby-copy.jpg"}],"venue_information":{"official_star_rating":4},"lead_product":{"name":"1 nights bed & breakfast and 2 rounds of golf (Hilton Templepatrick Golf Course) ","saving":0,"price":89},"reference_entity_url":"hilton-belfast-templepatrick","reference_entity_full_name":"Hilton Belfast Templepatrick","title":"Hilton Templepatrick"}],"product_lists_title":"Northern Ireland"},"uid":"67890","location_name":"Northern Ireland"}]}}}';
        //String expectedOutput = '{"data":{"all_location":{"items":[{"overview":{"venues":[{"images":[{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt8612d249fa8192a3/5d84dbbd25745254cb353738/north-course-la-manga-5.jpg"},{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt4ecc1ce23b5ca2eb/5d84d990614a7d122d37b324/la-manga-lobby.jpg"}],"venue_information":{"official_star_rating":5},"lead_product":{"name":"3 nights bed & breakfast at the Hotel La Manga Principe Felipe and 2 rounds of golf (West Course, North Course or South Course) ","saving":0,"price":295},"url":"la-manga-club","full_name":"Hotel La Manga Principe Felipe","title":"Hotel La Manga Principe Felipe"},{"images":[{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt4dd65b3a0c9577ea/5ef06c0b688c1c62a49af02d/Asia-Hole_18-final.jpg"}],"venue_information":{"official_star_rating":4},"lead_product":{"name":"3 nights bed & breakfast at La Cala Resort & Spa and 2 rounds of golf (La Cala Asia, La Cala America or La Cala Europa) ","saving":0,"price":219},"url":"la-cala-resort","full_name":"La Cala Golf Resort","title":"La Cala Resort"}],"title":"Spain"},"location_name":"Spain","uid":"12345"},{"overview":{}},{"overview":{"venues":[{"images":[{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/bltfcb2fd32ffb744f4/5bf421055fc57fff7689ea3a/banner-galgorm-resort-image-copy.jpg"}],"venue_information":{"official_star_rating":4},"lead_product":{"name":"1 nights bed & breakfast and 2 rounds of golf (Galgorm Castle Course)","saving":0,"price":195},"url":"galgorm-resort-spa","full_name":"Galgorm Resort & Spa","title":"Galgorm Resort & Spa"},{"images":[{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt737aad9ec3cfc3ec/5bf41e2a29bffcfc75f466c8/90309.jpg"},{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt5a48a3d9889e5911/5bf41e2c807ded0276583258/hotel-lobby-copy.jpg"}],"venue_information":{"official_star_rating":4},"lead_product":{"name":"1 nights bed & breakfast and 2 rounds of golf (Hilton Templepatrick Golf Course) ","saving":0,"price":89},"url":"hilton-belfast-templepatrick","full_name":"Hilton Belfast Templepatrick","title":"Hilton Templepatrick"}],"title":"Northern Ireland"},"uid":"67890","location_name":"Northern Ireland"}]}}}';
        System.debug(LoggingLevel.ERROR,expectedOutput);

        System.assertEquals(expectedOutput.deleteWhitespace(), actualOutput.deleteWhitespace());
    }

    @isTest public static void singleTestCase3(){        

        String cachingInstructions='items,location_name,overview=>venues';//<-- caching instructions field value [GQL Caching Instructions] held on the Content Stack Content Type record.
        // Items is the parent, venues is the child - if no child set then Genercic Content only population should be assumed.
        
        for (String ci : cachingInstructions.split('\\|')){ 

            List<String> connectionInstructions = ci.split(',');
            if (connectionInstructions.size()<2) continue;

            String c = connectionInstructions[1];
            if (connectionInstructions.size()==3) c+=','+connectionInstructions[2];

            listNameToCachingInstructions.put(connectionInstructions[0],c);
        }

        //Set/override caching instructions
        ContentStackGQLResponseHandler.listNameToCachingInstructions = listNameToCachingInstructions;

        //<-- test location venue GraphQL response (pre parsed)
        String input = '{"data":{"all_location":{"items":[{"system":{"uid":"blt72b9040d7e61f5e7"},"overview":{"venues":[{"system":{"uid":"blt72b9040d7e61f5e8"},"images":[{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt8612d249fa8192a3/5d84dbbd25745254cb353738/north-course-la-manga-5.jpg"},{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt4ecc1ce23b5ca2eb/5d84d990614a7d122d37b324/la-manga-lobby.jpg"}],"venue_information":{"official_star_rating":5},"lead_product":{"name":"3 nights bed & breakfast at the Hotel La Manga Principe Felipe and 2 rounds of golf (West Course, North Course or South Course) ","saving":0,"price":295},"url":"la-manga-club","full_name":"Hotel La Manga Principe Felipe","title":"Hotel La Manga Principe Felipe"},{"system":{"uid":"blt72b9040d7e61f4e8"},"images":[{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt4dd65b3a0c9577ea/5ef06c0b688c1c62a49af02d/Asia-Hole_18-final.jpg"}],"venue_information":{"official_star_rating":4},"lead_product":{"name":"3 nights bed & breakfast at La Cala Resort & Spa and 2 rounds of golf (La Cala Asia, La Cala America or La Cala Europa) ","saving":0,"price":219},"url":"la-cala-resort","full_name":"La Cala Golf Resort","title":"La Cala Resort"}],"title":"Spain"},"location_name":"Spain","uid":"12345"},{"overview":{}},{"system":{"uid":"blt72b9040d3r61f5e7"},"overview":{"venues":[{"system":{"uid":"blt55b9040d7e61f5e8"},"images":[{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/bltfcb2fd32ffb744f4/5bf421055fc57fff7689ea3a/banner-galgorm-resort-image-copy.jpg"}],"venue_information":{"official_star_rating":4},"lead_product":{"name":"1 nights bed & breakfast and 2 rounds of golf (Galgorm Castle Course)","saving":0,"price":195},"url":"galgorm-resort-spa","full_name":"Galgorm Resort & Spa","title":"Galgorm Resort & Spa"},{"system":{"uid":"blt78b9640d3r61f5e7"},"images":[{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt737aad9ec3cfc3ec/5bf41e2a29bffcfc75f466c8/90309.jpg"},{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt5a48a3d9889e5911/5bf41e2c807ded0276583258/hotel-lobby-copy.jpg"}],"venue_information":{"official_star_rating":4},"lead_product":{"name":"1 nights bed & breakfast and 2 rounds of golf (Hilton Templepatrick Golf Course) ","saving":0,"price":89},"url":"hilton-belfast-templepatrick","full_name":"Hilton Belfast Templepatrick","title":"Hilton Templepatrick"}],"title":"Northern Ireland"},"uid":"67890","location_name":"Northern Ireland"}]}}}';

        List<Map<String,List<SObject>>> cacheData = new List<Map<String,List<SObject>>>();
        //List contains two maps:
        //[0] = Generic Content Map
        cacheData.add(new Map<String,List<SObject>>());
            //[1] = Generic Content Item Map
        //Both maps use the Content Id as the key
        cacheData.add(new Map<String,List<SObject>>());

        ContentStackContentType__mdt csct = [Select Id, Locale__c, ContentType__c, ContentSubtype__c From ContentStackContentType__mdt Where DataEventType__r.DeveloperName = :locationVenuesContentTypeDET];

        System.Test.startTest();
        cacheData = ContentStackGQLResponseHandler.parseToCacheObject(JSON.deserializeUntyped(input),cacheData,csct);
        System.Test.stopTest();

        System.debug(LoggingLevel.ERROR,'cacheData='+cacheData);

        System.assertEquals(2, cacheData[0].values().size(), '2 locations');
        System.assertEquals(2, cacheData[1].values().size(), '2 venue lists');       
        
        for (List<SObject> l : cacheData[1].values()){
            System.assertEquals(2, l.size());
        }
    }    

    @isTest public static void singleTestCase3b(){        

        String cachingInstructions='items,location_name,overview=>venues';//<-- caching instructions field value [GQL Caching Instructions] held on the Content Stack Content Type record.
        // Items is the parent, venues is the child - if no child set then Genercic Content only population should be assumed.
        
        for (String ci : cachingInstructions.split('\\|')){ 

            List<String> connectionInstructions = ci.split(',');
            if (connectionInstructions.size()<2) continue;

            String c = connectionInstructions[1];
            if (connectionInstructions.size()==3) c+=','+connectionInstructions[2];

            listNameToCachingInstructions.put(connectionInstructions[0],c);
        }

        //Set/override caching instructions
        ContentStackGQLResponseHandler.listNameToCachingInstructions = listNameToCachingInstructions;

        //<-- test location venue GraphQL response (pre parsed)
        String input = '{ "data": { "all_location": { "items": [ { "system": { "uid": "blt72b9040d7e61f5e7" }, "overview": { "venues": [ { "images": [ { "url": "https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt8612d249fa8192a3/5d84dbbd25745254cb353738/north-course-la-manga-5.jpg" }, { "url": "https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt4ecc1ce23b5ca2eb/5d84d990614a7d122d37b324/la-manga-lobby.jpg" } ], "venue_information": { "official_star_rating": 5 }, "lead_product": { "name": "3 nights bed & breakfast at the Hotel La Manga Principe Felipe and 2 rounds of golf (West Course, North Course or South Course) ", "saving": 0, "price": 295 }, "url": "la-manga-club", "full_name": "Hotel La Manga Principe Felipe", "title": "Hotel La Manga Principe Felipe" }, { "system": { "uid": "blt72b9040d7e61f4e8" }, "images": [ { "url": "https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt4dd65b3a0c9577ea/5ef06c0b688c1c62a49af02d/Asia-Hole_18-final.jpg" } ], "venue_information": { "official_star_rating": 4 }, "lead_product": { "name": "3 nights bed & breakfast at La Cala Resort & Spa and 2 rounds of golf (La Cala Asia, La Cala America or La Cala Europa) ", "saving": 0, "price": 219 }, "url": "la-cala-resort", "full_name": "La Cala Golf Resort", "title": "La Cala Resort" } ], "title": "Spain" }, "location_name": "Spain", "uid": "12345" }, { "overview": {} }, { "system": { "uid": "blt72b9040d3r61f5e7" }, "overview": { "venues": [ { "images": [ { "url": "https://images.contentstack.io/v3/assets/blt99dd26276e65134a/bltfcb2fd32ffb744f4/5bf421055fc57fff7689ea3a/banner-galgorm-resort-image-copy.jpg" } ], "venue_information": { "official_star_rating": 4 }, "lead_product": { "name": "1 nights bed & breakfast and 2 rounds of golf (Galgorm Castle Course)", "saving": 0, "price": 195 }, "url": "galgorm-resort-spa", "full_name": "Galgorm Resort & Spa", "title": "Galgorm Resort & Spa" }, { "system": { "uid": "blt78b9640d3r61f5e7" }, "images": [ { "url": "https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt737aad9ec3cfc3ec/5bf41e2a29bffcfc75f466c8/90309.jpg" }, { "url": "https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt5a48a3d9889e5911/5bf41e2c807ded0276583258/hotel-lobby-copy.jpg" } ], "venue_information": { "official_star_rating": 4 }, "lead_product": { "name": "1 nights bed & breakfast and 2 rounds of golf (Hilton Templepatrick Golf Course) ", "saving": 0, "price": 89 }, "url": "hilton-belfast-templepatrick", "full_name": "Hilton Belfast Templepatrick", "title": "Hilton Templepatrick" } ], "title": "Northern Ireland" }, "uid": "67890", "location_name": "Northern Ireland" } ] } } }';

        List<Map<String,List<SObject>>> cacheData = new List<Map<String,List<SObject>>>();
        //List contains two maps:
        //[0] = Generic Content Map
        cacheData.add(new Map<String,List<SObject>>());
            //[1] = Generic Content Item Map
        //Both maps use the Content Id as the key
        cacheData.add(new Map<String,List<SObject>>());

        ContentStackContentType__mdt csct = [Select Id, ContentType__c, Locale__c, ContentSubtype__c From ContentStackContentType__mdt Where DataEventType__r.DeveloperName = :locationVenuesContentTypeDET];

        System.Test.startTest();
        cacheData = ContentStackGQLResponseHandler.parseToCacheObject(JSON.deserializeUntyped(input),cacheData,csct);
        System.Test.stopTest();

        System.debug(LoggingLevel.ERROR,'cacheData='+cacheData);

        System.assertEquals(2, cacheData[0].values().size(), '2 locations');
        System.assertEquals(2, cacheData[1].values().size(), '2 venue lists');//2 parent Ids.
        
        for (List<SObject> l : cacheData[1].values()){
            System.assertEquals(1, l.size());//2 venues with no system block are skipped.
        }
    }       

    @isTest public static void singleTestCase4(){        

        String cachingInstructions='items,system.uid=>title,,email_display_options=>references:system.uid=>system.content_type_uid=>full_name;location_name';//<-- caching instructions field value [GQL Caching Instructions] held on the Content Stack Content Type record.        
    
        for (String ci : cachingInstructions.split('\\|')){ 

            List<String> connectionInstructions = ci.split(',');
            if (connectionInstructions.size()<2) continue;

            String c = connectionInstructions[1];
            if (connectionInstructions.size()>=3) c+=','+connectionInstructions[2];
            if (connectionInstructions.size()==4) c+=','+connectionInstructions[3];

            listNameToCachingInstructions.put(connectionInstructions[0],c);
        }        

        //Set/override caching instructions
        ContentStackGQLResponseHandler.listNameToCachingInstructions = listNameToCachingInstructions;

        //<-- test location venue GraphQL response (pre parsed)        
        String input = '{ "data": { "all_article": { "items": [ { "email_display_options": { "references": [ { "system": { "content_type_uid": "venue", "uid": "blt625738a843949291" }, "full_name": "Golf Club La Pinetina", "title": "1780 - Golf Club La Pinetina" }, { "system": { "content_type_uid": "venue", "uid": "bltd22b361975ce037c" }, "full_name": "Grayhawk Golf Club ", "title": "4930 - Grayhawk Golf Club" }, { "system": { "content_type_uid": "venue", "uid": "blt1a3d0fc04c854333" }, "full_name": "Hotel Vila Gale Ampalius", "title": "945 - Hotel Vila Gale Ampalius" }, { "system": { "content_type_uid": "venue", "uid": "bltc0248502c11db1c5" }, "full_name": "Golf de l Ailette", "title": "3356 - Golf de l Ailette" }, { "system": { "content_type_uid": "location", "uid": "blt43426565b910134c" }, "location_name": "England", "title": "Country - England" }, { "system": { "content_type_uid": "location", "uid": "bltb131a94138d9adf4" }, "location_name": "France", "title": "Country - Europe - France" }, { "system": { "content_type_uid": "location", "uid": "blt617cbe592fde49be" }, "location_name": "Algarve", "title": "Region - Algarve" }, { "system": { "content_type_uid": "location", "uid": "blta72d014c967f73af" }, "location_name": "Normandy", "title": "Region - Normandy" } ] }, "url": "https://images.contentstack.io/v3/assets/blta9a7f7c81270e799/blt3369e77393d8b78f/5f0f3e0818cdc41083defbbb/Final-Hole13-RESIZED-1200x800.jpg", "article_intro": { "page_subtitle": "Test article Test article Test article Test articleTest articleTest articleTest articleTest article Test article Test article Test article", "page_title": "Test article" }, "title": "Test article", "short_description": "", "system": { "uid": "blt7688b24e9bc61ace" } }, { "email_display_options": null, "url": "https://images.contentstack.io/v3/assets/blta9a7f7c81270e799/blt5558ee45fc7db4d9/5f0f3ad9b0b27d11516f7f66/Everything-You-Need-to-know-About-The-Masters_.jpg", "article_intro": { "page_subtitle": "Where is the best place to stay? How much will it cost? Who books my flights? All your burning Masters questions answered here.", "page_title": "Everything you need to know about The Masters" }, "title": "Everything You Need To Know About The Masters", "short_description": null, "system": { "uid": "blt78ab09db998f74a5" } } ] } } }';

        List<Map<String,List<SObject>>> cacheData = new List<Map<String,List<SObject>>>();
        //List contains three maps:
        //[0] = Generic Content Map
        cacheData.add(new Map<String,List<SObject>>());
        //[1] = Generic Content Item Map        
        cacheData.add(new Map<String,List<SObject>>());
        //[3] = Generic Content Reference Map
        cacheData.add(new Map<String,List<SObject>>());

        ContentStackContentType__mdt csct = [select Id, ContentType__c, Locale__c, ContentSubtype__c from ContentStackContentType__mdt where DataEventType__r.DeveloperName=:articleContentTypeDET];

        System.Test.startTest();
        cacheData = ContentStackGQLResponseHandler.parseToCacheObject(JSON.deserializeUntyped(input),cacheData,csct);
        System.Test.stopTest();

        System.debug(LoggingLevel.ERROR,'cacheData='+cacheData);

        System.assertEquals(2, cacheData[0].values().size(), '2 articles');
        System.assert(cacheData[2].containsKey('blt7688b24e9bc61ace'));
        System.assert(!cacheData[2].containsKey('blt78ab09db998f74a5'));

        System.assertEquals(8, cacheData[2].get('blt7688b24e9bc61ace').size(), 'Should be 8 article references for article 1');
        System.assert( ((GenericContentReference__c)cacheData[2].get('blt7688b24e9bc61ace')[0]).ContentId__c!=null );
        System.assert( ((GenericContentReference__c)cacheData[2].get('blt7688b24e9bc61ace')[0]).ContentName__c!=null );
        System.assert( ((GenericContentReference__c)cacheData[2].get('blt7688b24e9bc61ace')[0]).ContentType__c!=null );        
    }

    @isTest public static void singleTestCase5(){        

        String cachingInstructions='items,system.uid=>location_name=>type,overview=>venues';//<-- caching instructions field value [GQL Caching Instructions] held on the Content Stack Content Type record.
        // Items is the parent, venues is the child - if no child set then Genercic Content only population should be assumed.
        
        for (String ci : cachingInstructions.split('\\|')){ 

            List<String> connectionInstructions = ci.split(',');
            if (connectionInstructions.size()<2) continue;

            String c = connectionInstructions[1];
            if (connectionInstructions.size()==3) c+=','+connectionInstructions[2];

            listNameToCachingInstructions.put(connectionInstructions[0],c);
        }

        //Set/override caching instructions
        ContentStackGQLResponseHandler.listNameToCachingInstructions = listNameToCachingInstructions;

        //<-- test location venue GraphQL response (pre parsed)
        String input = '{ "data": { "all_location": { "items": [ { "system": { "uid": "blt72b9040d7e61f5e7" }, "overview": { "venues": [ { "images": [ { "url": "https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt8612d249fa8192a3/5d84dbbd25745254cb353738/north-course-la-manga-5.jpg" }, { "url": "https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt4ecc1ce23b5ca2eb/5d84d990614a7d122d37b324/la-manga-lobby.jpg" } ], "venue_information": { "official_star_rating": 5 }, "lead_product": { "name": "3 nights bed & breakfast at the Hotel La Manga Principe Felipe and 2 rounds of golf (West Course, North Course or South Course) ", "saving": 0, "price": 295 }, "url": "la-manga-club", "full_name": "Hotel La Manga Principe Felipe", "title": "Hotel La Manga Principe Felipe" }, { "system": { "uid": "blt72b9040d7e61f4e8" }, "images": [ { "url": "https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt4dd65b3a0c9577ea/5ef06c0b688c1c62a49af02d/Asia-Hole_18-final.jpg" } ], "venue_information": { "official_star_rating": 4 }, "lead_product": { "name": "3 nights bed & breakfast at La Cala Resort & Spa and 2 rounds of golf (La Cala Asia, La Cala America or La Cala Europa) ", "saving": 0, "price": 219 }, "url": "la-cala-resort", "full_name": "La Cala Golf Resort", "title": "La Cala Resort" } ], "title": "Spain" }, "location_name": "Spain", "type" : "Country", "uid": "12345" }, { "overview": {} }, { "system": { "uid": "blt72b9040d3r61f5e7" }, "overview": { "venues": [ { "images": [ { "url": "https://images.contentstack.io/v3/assets/blt99dd26276e65134a/bltfcb2fd32ffb744f4/5bf421055fc57fff7689ea3a/banner-galgorm-resort-image-copy.jpg" } ], "venue_information": { "official_star_rating": 4 }, "lead_product": { "name": "1 nights bed & breakfast and 2 rounds of golf (Galgorm Castle Course)", "saving": 0, "price": 195 }, "url": "galgorm-resort-spa", "full_name": "Galgorm Resort & Spa", "title": "Galgorm Resort & Spa" }, { "system": { "uid": "blt78b9640d3r61f5e7" }, "images": [ { "url": "https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt737aad9ec3cfc3ec/5bf41e2a29bffcfc75f466c8/90309.jpg" }, { "url": "https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt5a48a3d9889e5911/5bf41e2c807ded0276583258/hotel-lobby-copy.jpg" } ], "venue_information": { "official_star_rating": 4 }, "lead_product": { "name": "1 nights bed & breakfast and 2 rounds of golf (Hilton Templepatrick Golf Course) ", "saving": 0, "price": 89 }, "url": "hilton-belfast-templepatrick", "full_name": "Hilton Belfast Templepatrick", "title": "Hilton Templepatrick" } ], "title": "Northern Ireland" }, "uid": "67890", "location_name": "Northern Ireland", "type" : "Country" } ] } } }';

        List<Map<String,List<SObject>>> cacheData = new List<Map<String,List<SObject>>>();
        //List contains two maps:
        //[0] = Generic Content Map
        cacheData.add(new Map<String,List<SObject>>());
            //[1] = Generic Content Item Map
        //Both maps use the Content Id as the key
        cacheData.add(new Map<String,List<SObject>>());

        ContentStackContentType__mdt csct = [Select Id, ContentType__c, ContentSubtype__c, Locale__c From ContentStackContentType__mdt Where DataEventType__r.DeveloperName = :locationVenuesContentTypeDET];

        System.Test.startTest();
        cacheData = ContentStackGQLResponseHandler.parseToCacheObject(JSON.deserializeUntyped(input),cacheData,csct);
        System.Test.stopTest();

        System.debug(LoggingLevel.ERROR,'cacheData='+cacheData);

        System.assertEquals(2, cacheData[0].values().size(), '2 locations');

        GenericContent__c genericContentSObject = (GenericContent__c)cacheData[0].values()[0][0];
        System.assertEquals('Country', genericContentSObject.LocationType__c);

        System.assertEquals(2, cacheData[1].values().size(), '2 venue lists');//2 parent Ids.
        
        for (List<SObject> l : cacheData[1].values()){
            System.assertEquals(1, l.size());//2 venues with no system block are skipped.
        }
    }    

    @isTest public static void singleTestCase6(){        
        
        listNameToCachingInstructions.put('items','system.uid=>full_name=>=>data_salesforce_id');//Set/override caching instructions
        ContentStackGQLResponseHandler.listNameToCachingInstructions = listNameToCachingInstructions;

        //<-- test Venue GraphQL response (pre parsed)
        String input = '{ "data": { "all_venue": { "items": [ {"location":[{"location_url":"west-scotland","system":{"uid":"blt2a6fa916728f35e0"},"website_title":"USA"}],"venue_information":{"official_star_rating":null},"data_salesforce_id":"001b000003V2vNAAAZ","lead_product":null,"url":"/6693---piersland-house-hotel","short_description":null,"full_name":"6693 - Piersland House Hotel","system":{"uid":"blt28c8af7e01f2c34e"}}, {"location":[{"location_url":"limerick","system":{"uid":"bltc029da544a9ea3d6"},"website_title":"UK"},{"location_url":"shannon","system":{"uid":"bltbc18ef2afb63611c"},"website_title":"USA"}],"venue_information":{"official_star_rating":5},"data_salesforce_id":"001b000000TitAqAAJ","lead_product":{"currency":"Sterling","name":"1 night bed & breakfast (Manor Room) and 1 round golf (Adare Golf Club) ","saving":0,"price":475},"url":"adare-manor-hotel-golf-club-spa","short_description":"Adare Manor is a beautiful and luxurious 5-star hotel with elegant rooms and excellent leisure facilities. With a mixture of villas, townhouses and hotel rooms to choose from, the Manor is suitable for smaller and larger groups of golfers.","full_name":"Adare Manor Hotel, Golf Club & Spa","system":{"uid":"blt30139685d1bbcf4e"}} ] }} }';

        List<Map<String,List<SObject>>> cacheData = new List<Map<String,List<SObject>>>();
        //List contains two maps:
        //[0] = Generic Content Map
        cacheData.add(new Map<String,List<SObject>>());
            //[1] = Generic Content Item Map
        //Both maps use the Content Id as the key
        cacheData.add(new Map<String,List<SObject>>());

        ContentStackContentType__mdt csct = new ContentStackContentType__mdt(ContentType__c='Venue',ContentSubtype__c=null);

        System.Test.startTest();
        cacheData = ContentStackGQLResponseHandler.parseToCacheObject(JSON.deserializeUntyped(input),cacheData,csct);
        System.Test.stopTest();

        System.debug(LoggingLevel.ERROR,'cacheData='+cacheData);

        System.assertEquals(2, cacheData[0].values().size(), '2 venues');

        GenericContent__c genericContentSObject = (GenericContent__c)cacheData[0].values()[0][0];
        System.assertEquals('001b000003V2vNAAAZ', genericContentSObject.SalesforceId__c);

        genericContentSObject = (GenericContent__c)cacheData[0].values()[1][0];
        System.assertEquals('001b000000TitAqAAJ', genericContentSObject.SalesforceId__c);
    }

    @isTest public static void singleTestCase7a(){//<---- Test Cache population - Content Type Field Mappings. Simple case.
        
        listNameToCachingInstructions.put('items','system.uid=>full_name');//Set/override caching instructions
        ContentStackGQLResponseHandler.listNameToCachingInstructions = listNameToCachingInstructions;

        //<-- test Venue GraphQL response (pre parsed)
        String input = '{ "data": { "all_venue": { "items": [ {"location":[{"location_url":"west-scotland","system":{"uid":"blt2a6fa916728f35e0"},"website_title":"USA"}],"venue_information":{"official_star_rating":null},"data_salesforce_id":"001b000003V2vNAAAZ","lead_product":null,"url":"/6693---piersland-house-hotel","short_description":null,"full_name":"6693 - Piersland House Hotel","system":{"uid":"blt28c8af7e01f2c34e"}}, {"location":[{"location_url":"limerick","system":{"uid":"bltc029da544a9ea3d6"},"website_title":"UK"},{"location_url":"shannon","system":{"uid":"bltbc18ef2afb63611c"},"website_title":"USA"}],"venue_information":{"official_star_rating":5},"data_salesforce_id":"001b000000TitAqAAJ","lead_product":{"currency":"Sterling","name":"1 night bed & breakfast (Manor Room) and 1 round golf (Adare Golf Club) ","saving":0,"price":475},"url":"adare-manor-hotel-golf-club-spa","short_description":"Adare Manor is a beautiful and luxurious 5-star hotel with elegant rooms and excellent leisure facilities. With a mixture of villas, townhouses and hotel rooms to choose from, the Manor is suitable for smaller and larger groups of golfers.","full_name":"Adare Manor Hotel, Golf Club & Spa","system":{"uid":"blt30139685d1bbcf4e"}} ] }} }';

        List<Map<String,List<SObject>>> cacheData = new List<Map<String,List<SObject>>>();
        //List contains two maps:
        //[0] = Generic Content Map
        cacheData.add(new Map<String,List<SObject>>());
            //[1] = Generic Content Item Map
        //Both maps use the Content Id as the key
        cacheData.add(new Map<String,List<SObject>>());

        ContentStackContentType__mdt csct = new ContentStackContentType__mdt(ContentType__c='Venue',ContentSubtype__c=null);
        ContentTypeFieldMapping__mdt ctfm = new ContentTypeFieldMapping__mdt();
        ctfm.DeveloperName = 'SalesforceId';
        ctfm.MasterLabel = 'SalesforceId';
        ctfm.FieldName__c = 'SalesforceId__c';
        ctfm.FieldValuePath__c = '[get>data_salesforce_id>end]';
        
        ContentStackGQLResponseHandler.contentTypeFieldMappings = new List<ContentTypeFieldMapping__mdt>{ ctfm };

        System.Test.startTest();
        cacheData = ContentStackGQLResponseHandler.parseToCacheObject(JSON.deserializeUntyped(input),cacheData,csct);
        System.Test.stopTest();

        System.debug(LoggingLevel.ERROR,'cacheData='+cacheData);

        System.assertEquals(2, cacheData[0].values().size(), '2 venues');

        GenericContent__c genericContentSObject = (GenericContent__c)cacheData[0].values()[0][0];
        System.assertEquals('001b000003V2vNAAAZ', genericContentSObject.SalesforceId__c);

        genericContentSObject = (GenericContent__c)cacheData[0].values()[1][0];
        System.assertEquals('001b000000TitAqAAJ', genericContentSObject.SalesforceId__c);        
    }  
    
    @isTest public static void singleTestCase7b(){//<---- Test Cache population - Content Type Field Mappings. Complex case.
        
        listNameToCachingInstructions.put('items','system.uid=>full_name');//Set/override caching instructions
        ContentStackGQLResponseHandler.listNameToCachingInstructions = listNameToCachingInstructions;

        //<-- test Venue GraphQL response (pre parsed)
        String input = '{ "data": { "all_venue": { "items": [ {"location":[{"location_url":"west-scotland","system":{"uid":"blt2a6fa916728f35e0"},"website_title":"USA"}],"venue_information":{"official_star_rating":null},"data_salesforce_id":"001b000003V2vNAAAZ","lead_product":null,"url":"/6693---piersland-house-hotel","short_description":null,"full_name":"6693 - Piersland House Hotel","system":{"uid":"blt28c8af7e01f2c34e"}}, {"location":[{"location_url":"limerick","system":{"uid":"bltc029da544a9ea3d6"},"website_title":"UK"},{"location_url":"shannon","system":{"uid":"bltbc18ef2afb63611c"},"website_title":"USA"}],"venue_information":{"official_star_rating":5},"data_salesforce_id":"001b000000TitAqAAJ","lead_product":{"currency":"Sterling","name":"1 night bed & breakfast (Manor Room) and 1 round golf (Adare Golf Club) ","saving":0,"price":475},"url":"adare-manor-hotel-golf-club-spa","short_description":"Adare Manor is a beautiful and luxurious 5-star hotel with elegant rooms and excellent leisure facilities. With a mixture of villas, townhouses and hotel rooms to choose from, the Manor is suitable for smaller and larger groups of golfers.","full_name":"Adare Manor Hotel, Golf Club & Spa","system":{"uid":"blt30139685d1bbcf4e"}} ] }} }';

        List<Map<String,List<SObject>>> cacheData = new List<Map<String,List<SObject>>>();
        //List contains two maps:
        //[0] = Generic Content Map
        cacheData.add(new Map<String,List<SObject>>());
            //[1] = Generic Content Item Map
        //Both maps use the Content Id as the key
        cacheData.add(new Map<String,List<SObject>>());

        ContentStackContentType__mdt csct = new ContentStackContentType__mdt(ContentType__c='Venue',ContentSubtype__c=null);
        ContentTypeFieldMapping__mdt ctfm = new ContentTypeFieldMapping__mdt();
        ctfm.DeveloperName = 'SalesforceId';
        ctfm.MasterLabel = 'SalesforceId';
        ctfm.FieldName__c = 'SalesforceId__c';
        ctfm.FieldValuePath__c = '[get>location>list],[index>0>Map],[get>system>Map],[get>uid>end]';
        
        ContentStackGQLResponseHandler.contentTypeFieldMappings = new List<ContentTypeFieldMapping__mdt>{ ctfm };

        System.Test.startTest();
        cacheData = ContentStackGQLResponseHandler.parseToCacheObject(JSON.deserializeUntyped(input),cacheData,csct);
        System.Test.stopTest();

        System.debug(LoggingLevel.ERROR,'cacheData='+cacheData);

        System.assertEquals(2, cacheData[0].values().size(), '2 venues');

        GenericContent__c genericContentSObject = (GenericContent__c)cacheData[0].values()[0][0];
        System.assertEquals('blt2a6fa916728f35e0', genericContentSObject.SalesforceId__c);

        genericContentSObject = (GenericContent__c)cacheData[0].values()[1][0];
        System.assertEquals('bltc029da544a9ea3d6', genericContentSObject.SalesforceId__c);        
    }

    /* **/
    @isTest public static void singleTestCase8a(){//<---- Test Parent Filters.
        
        listNameToCachingInstructions.put('items','system.uid=>full_name');//Set/override caching instructions
        ContentStackGQLResponseHandler.listNameToCachingInstructions = listNameToCachingInstructions;

        listNameToFilterInstructions.put('items','[system.uid][=][blt30139685d1bbcf4e]');// -- list name, parent filter, [child filter].
        ContentStackGQLResponseHandler.listNameToFilterInstructions = listNameToFilterInstructions;

        //<-- test Venue GraphQL response (pre parsed)
        String input = '{ "data": { "all_venue": { "items": [ {"location":[{"location_url":"west-scotland","system":{"uid":"blt2a6fa916728f35e0"},"website_title":"USA"}],"venue_information":{"official_star_rating":null},"data_salesforce_id":"001b000003V2vNAAAZ","lead_product":null,"url":"/6693---piersland-house-hotel","short_description":null,"full_name":"6693 - Piersland House Hotel","system":{"uid":"blt28c8af7e01f2c34e"}}, {"location":[{"location_url":"limerick","system":{"uid":"bltc029da544a9ea3d6"},"website_title":"UK"},{"location_url":"shannon","system":{"uid":"bltbc18ef2afb63611c"},"website_title":"USA"}],"venue_information":{"official_star_rating":5},"data_salesforce_id":"001b000000TitAqAAJ","lead_product":{"currency":"Sterling","name":"1 night bed & breakfast (Manor Room) and 1 round golf (Adare Golf Club) ","saving":0,"price":475},"url":"adare-manor-hotel-golf-club-spa","short_description":"Adare Manor is a beautiful and luxurious 5-star hotel with elegant rooms and excellent leisure facilities. With a mixture of villas, townhouses and hotel rooms to choose from, the Manor is suitable for smaller and larger groups of golfers.","full_name":"Adare Manor Hotel, Golf Club & Spa","system":{"uid":"blt30139685d1bbcf4e"}} ] }} }';

        List<Map<String,List<SObject>>> cacheData = new List<Map<String,List<SObject>>>();
        //List contains two maps:
        //[0] = Generic Content Map
        cacheData.add(new Map<String,List<SObject>>());
        //[1] = Generic Content Item Map
        //Both maps use the Content Id as the key
        cacheData.add(new Map<String,List<SObject>>());

        ContentStackContentType__mdt csct = new ContentStackContentType__mdt(ContentType__c='Venue',ContentSubtype__c=null);

        System.Test.startTest();
        cacheData = ContentStackGQLResponseHandler.parseToCacheObject(JSON.deserializeUntyped(input),cacheData,csct);
        System.Test.stopTest();

        System.debug(LoggingLevel.ERROR,'cacheData='+cacheData);

        System.assertEquals(1, cacheData[0].values().size(), '1 venue');

        GenericContent__c genericContentSObject = (GenericContent__c)cacheData[0].values()[0][0];
        System.assertEquals('blt30139685d1bbcf4e', genericContentSObject.ContentId__c);
        System.assertEquals('Adare Manor Hotel, Golf Club & Spa', genericContentSObject.Name);
    }/* */   
    
    /* **/
    @isTest public static void singleTestCase8b(){//<---- Test Child Filters.    

        String cachingInstructions='items,location_name,overview=>venues';//<-- caching instructions field value [GQL Caching Instructions] held on the Content Stack Content Type record.
        // Items is the parent, venues is the child - if no child set then Genercic Content only population should be assumed.
        
        for (String ci : cachingInstructions.split('\\|')){ 

            List<String> connectionInstructions = ci.split(',');
            if (connectionInstructions.size()<2) continue;

            String c = connectionInstructions[1];
            if (connectionInstructions.size()==3) c+=','+connectionInstructions[2];

            listNameToCachingInstructions.put(connectionInstructions[0],c);
        }

        listNameToFilterInstructions.put('items','[system.uid][=][blt72b9040d3r61f5e7],[lead_product.price][<>][89]');// -- list name, parent filter, child filter.
        ContentStackGQLResponseHandler.listNameToFilterInstructions = listNameToFilterInstructions;


        //Set/override caching instructions
        ContentStackGQLResponseHandler.listNameToCachingInstructions = listNameToCachingInstructions;

        //<-- test location venue GraphQL response (pre parsed)
        String input = '{"data":{"all_location":{"items":[{"system":{"uid":"blt72b9040d7e61f5e7"},"overview":{"venues":[{"system":{"uid":"blt72b9040d7e61f5e8"},"images":[{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt8612d249fa8192a3/5d84dbbd25745254cb353738/north-course-la-manga-5.jpg"},{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt4ecc1ce23b5ca2eb/5d84d990614a7d122d37b324/la-manga-lobby.jpg"}],"venue_information":{"official_star_rating":5},"lead_product":{"name":"3 nights bed & breakfast at the Hotel La Manga Principe Felipe and 2 rounds of golf (West Course, North Course or South Course) ","saving":0,"price":295},"url":"la-manga-club","full_name":"Hotel La Manga Principe Felipe","title":"Hotel La Manga Principe Felipe"},{"system":{"uid":"blt72b9040d7e61f4e8"},"images":[{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt4dd65b3a0c9577ea/5ef06c0b688c1c62a49af02d/Asia-Hole_18-final.jpg"}],"venue_information":{"official_star_rating":4},"lead_product":{"name":"3 nights bed & breakfast at La Cala Resort & Spa and 2 rounds of golf (La Cala Asia, La Cala America or La Cala Europa) ","saving":0,"price":219},"url":"la-cala-resort","full_name":"La Cala Golf Resort","title":"La Cala Resort"}],"title":"Spain"},"location_name":"Spain","uid":"12345"},{"overview":{}},{"system":{"uid":"blt72b9040d3r61f5e7"},"overview":{"venues":[{"system":{"uid":"blt55b9040d7e61f5e8"},"images":[{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/bltfcb2fd32ffb744f4/5bf421055fc57fff7689ea3a/banner-galgorm-resort-image-copy.jpg"}],"venue_information":{"official_star_rating":4},"lead_product":{"name":"1 nights bed & breakfast and 2 rounds of golf (Galgorm Castle Course)","saving":0,"price":195},"url":"galgorm-resort-spa","full_name":"Galgorm Resort & Spa","title":"Galgorm Resort & Spa"},{"system":{"uid":"blt78b9640d3r61f5e7"},"images":[{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt737aad9ec3cfc3ec/5bf41e2a29bffcfc75f466c8/90309.jpg"},{"url":"https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt5a48a3d9889e5911/5bf41e2c807ded0276583258/hotel-lobby-copy.jpg"}],"venue_information":{"official_star_rating":4},"lead_product":{"name":"1 nights bed & breakfast and 2 rounds of golf (Hilton Templepatrick Golf Course) ","saving":0,"price":89},"url":"hilton-belfast-templepatrick","full_name":"Hilton Belfast Templepatrick","title":"Hilton Templepatrick"}],"title":"Northern Ireland"},"uid":"67890","location_name":"Northern Ireland"}]}}}';

        List<Map<String,List<SObject>>> cacheData = new List<Map<String,List<SObject>>>();
        //List contains two maps:
        //[0] = Generic Content Map
        cacheData.add(new Map<String,List<SObject>>());
            //[1] = Generic Content Item Map
        //Both maps use the Content Id as the key
        cacheData.add(new Map<String,List<SObject>>());

        ContentStackContentType__mdt csct = [Select Id, Locale__c, ContentType__c, ContentSubtype__c From ContentStackContentType__mdt Where DataEventType__r.DeveloperName = :locationVenuesContentTypeDET];

        System.Test.startTest();
        cacheData = ContentStackGQLResponseHandler.parseToCacheObject(JSON.deserializeUntyped(input),cacheData,csct);
        System.Test.stopTest();

        System.debug(LoggingLevel.ERROR,'cacheData='+cacheData);

        System.assertEquals(1, cacheData[0].values().size(), '1 location');
        
        GenericContent__c genericContentSObject = (GenericContent__c)cacheData[0].values()[0][0];
        System.assertEquals('blt72b9040d3r61f5e7', genericContentSObject.ContentId__c);
        System.assertEquals('Northern Ireland', genericContentSObject.Name);
        
        System.assertEquals(1, cacheData[1].values().size(), '1 venue lists');
        System.assertEquals(1, cacheData[1].values()[0].size(), '1 venue');     
        
        GenericContentItem__c genericContentItemSObject = (GenericContentItem__c)cacheData[1].values()[0][0];
        System.assertEquals('blt55b9040d7e61f5e8', genericContentItemSObject.ContentId__c);
    }/* */

    /* **/
    @isTest public static void singleTestCase8c(){//<---- Test Parent (Generic Content) Sub-filters.
        
        listNameToCachingInstructions.put('items','system.uid=>full_name');//Set/override caching instructions -- items,system.uid=>full_name
        ContentStackGQLResponseHandler.listNameToCachingInstructions = listNameToCachingInstructions;

        listNameToFilterInstructions.put('items','[system.uid][=][blt30139685d1bbcf4e]~promotions.offers[visible_to][<=][TODAY]');
        
        // GQLFilterInstructions Design Note:
        // parentFilter excludes Generic Content where filter criteria does not apply.
        // childFilter excludes Generic Content Item where filter criteria does not apply.
        // Sub filters exclude list entries within Generic Content or Generic Content Item objects.
        // Syntax:
        // .. parentList,parentFilter~parentSubfilter,childFilter~childSubfilter|parentList2..
        // .. parentFilter|childFilter: [object.property][operator][value]
        // .. parentSubfilter|childSubfilter: object.list[object.property][operator][value]
        // Examples:
        // .. items,[system.uid][=][blt30139685d1bbcf4e]~location[location_url][=][west-scotland],[lead_product.price][<>][89]~promotions.offers[visible_to][<=][TODAY]
        // .. items,,~promotions.offers[visible_to][<=][TODAY] (exclude promotions within GCI)

        ContentStackGQLResponseHandler.listNameToFilterInstructions = listNameToFilterInstructions;

        //<-- test Venue GraphQL response (pre parsed)
        Datetime dt1 = DateTime.newInstance(System.now().year(),System.now().month(),System.now().day());
        String promotionDate1 = dt1.format('yyyy-MM-dd');//included

        Datetime dt2 = DateTime.newInstance(System.now().addDays(1).year(),System.now().addDays(1).month(),System.now().addDays(1).day());
        String promotionDate2 = dt2.format('yyyy-MM-dd');//excluded by sub filter

        String input = '{ "data": { "all_venue": { "items": [ { "location": [ { "location_url": "west-scotland", "system": { "uid": "blt2a6fa916728f35e0" }, "website_title": "USA" } ], "venue_information": { "official_star_rating": null }, "data_salesforce_id": "001b000003V2vNAAAZ", "lead_product": null, "url": "/6693---piersland-house-hotel", "short_description": null, "full_name": "6693 - Piersland House Hotel", "system": { "uid": "blt28c8af7e01f2c34e" } }, { "location": [ { "location_url": "limerick", "system": { "uid": "bltc029da544a9ea3d6" }, "website_title": "UK" }, { "location_url": "shannon", "system": { "uid": "bltbc18ef2afb63611c" }, "website_title": "USA" } ], "venue_information": { "official_star_rating": 5 }, "data_salesforce_id": "001b000000TitAqAAJ", "promotions":{ "offers":[ { "visible_to":"'+promotionDate1+'", "promotion_title":"Buggy Included" }, { "visible_to":"'+promotionDate2+'", "promotion_title":"Early Booking discount " } ] }, "lead_product": { "currency": "Sterling", "name": "1 night bed & breakfast (Manor Room) and 1 round golf (Adare Golf Club) ", "saving": 0, "price": 475 }, "url": "adare-manor-hotel-golf-club-spa", "short_description": "Adare Manor is a beautiful and luxurious 5-star hotel with elegant rooms and excellent leisure facilities. With a mixture of villas, townhouses and hotel rooms to choose from, the Manor is suitable for smaller and larger groups of golfers.", "full_name": "Adare Manor Hotel, Golf Club & Spa", "system": { "uid": "blt30139685d1bbcf4e" } } ] } } }';

        List<Map<String,List<SObject>>> cacheData = new List<Map<String,List<SObject>>>();
        //List contains two maps:
        //[0] = Generic Content Map
        cacheData.add(new Map<String,List<SObject>>());
        //[1] = Generic Content Item Map
        //Both maps use the Content Id as the key
        cacheData.add(new Map<String,List<SObject>>());

        ContentStackContentType__mdt csct = new ContentStackContentType__mdt(ContentType__c='Venue',ContentSubtype__c=null);

        System.Test.startTest();
        cacheData = ContentStackGQLResponseHandler.parseToCacheObject(JSON.deserializeUntyped(input),cacheData,csct);
        System.Test.stopTest();

        System.debug(LoggingLevel.ERROR,'cacheData='+cacheData);

        System.assertEquals(1, cacheData[0].values().size(), '1 venue');

        GenericContent__c genericContentSObject = (GenericContent__c)cacheData[0].values()[0][0];
        System.assertEquals('blt30139685d1bbcf4e', genericContentSObject.ContentId__c);
        System.assertEquals('Adare Manor Hotel, Golf Club & Spa', genericContentSObject.Name);

        Boolean isSubFilterApplied=false;
        Object o = JSON.deserializeUntyped(genericContentSObject.ContentJSON__c);
        if (o instanceof Map<String,Object>){

            Map<String,Object> outputMap = (Map<String,Object>)o;
            if (outputMap.containsKey('promotions')){

                if (outputMap.get('promotions') instanceof Map<String,Object>){

                    outputMap = (Map<String,Object>)outputMap.get('promotions');

                    if (outputMap.containsKey('offers')){

                        if (outputMap.get('offers') instanceof List<Object>){

                            List<Object> outputList = (List<Object>)outputMap.get('offers');//offers
                            System.assert(outputList.size()==1);
                            
                            if (outputList[0] instanceof Map<String,Object>){
                                Map<String,Object> offerMap = (Map<String,Object>)outputList[0];
                                isSubFilterApplied = offerMap.containsKey('promotion_title') && String.valueOf(offerMap.get('promotion_title')).equalsIgnoreCase('Buggy Included');//[{"promotion_title":"Buggy Included","visible_to":"2024-03-20"}]
                            }
                        }
                    }
                }
            }
        }
        System.assert(isSubFilterApplied);
    }/* */  
    
    /* **/
    @isTest public static void singleTestCase8d(){//<---- Test Child (Generic Content Item) Sub-filters.
        
        String cachingInstructions='items,system.uid=>location_name=>type,overview=>venues';// -- items,system.uid=>location_name=>type,overview=>venues
        // Items is the parent, venues is the child - if no child set then Generic Content only population should be assumed.
        
        for (String ci : cachingInstructions.split('\\|')){ 

            List<String> connectionInstructions = ci.split(',');
            if (connectionInstructions.size()<2) continue;

            String c = connectionInstructions[1];
            if (connectionInstructions.size()==3) c+=','+connectionInstructions[2];

            listNameToCachingInstructions.put(connectionInstructions[0],c);
        }

        listNameToFilterInstructions.put('items',',~promotions.offers[visible_to][<][TODAY]');// -- items,~promotions.offer[visible_to][<][TODAY]

        ContentStackGQLResponseHandler.listNameToFilterInstructions = listNameToFilterInstructions;

        //Set/override caching instructions
        ContentStackGQLResponseHandler.listNameToCachingInstructions = listNameToCachingInstructions;

        //<-- test location venue GraphQL response (pre parsed)
        Datetime dt1 = DateTime.newInstance(System.now().addDays(-1).year(),System.now().addDays(-1).month(),System.now().addDays(-1).day());
        String promotionDate1 = dt1.format('yyyy-MM-dd');//included

        Datetime dt2 = DateTime.newInstance(System.now().addDays(1).year(),System.now().addDays(1).month(),System.now().addDays(1).day());
        String promotionDate2 = dt2.format('yyyy-MM-dd');//excluded by sub filter

        String input = '{ "data": { "all_location": { "items": [';            
        input+='{ "system": { "uid": "blt72b9040d7e61f5e7" }, "overview": ';
        input+='{ "venues": [';
        input+='{ "system": { "uid": "blt72b9040d7e61f5e8" }, "images": [ { "url": "https://images.contentstack.io" } ], "venue_information": { "official_star_rating": 5 }, "promotions": { "offers": [ { "visible_to": "'+promotionDate1+'", "promotion_title": "Buggy Included" }, { "visible_to": "'+promotionDate2+'", "promotion_title": "Early Booking discount " } ] }, "lead_product": { "name": "3 nights bed & breakfast at the Hotel La Manga Principe Felipe and 2 rounds of golf (West Course, North Course or South Course) ", "saving": 0, "price": 295 }, "url": "la-manga-club", "full_name": "Hotel La Manga Principe Felipe", "title": "Hotel La Manga Principe Felipe" },';
        input+='{ "system": { "uid": "blt72b9040d7e61f4e9" }, "images": [ { "url": "https://images.contentstack.io" } ], "venue_information": { "official_star_rating": 4 }, "promotions": { "offers": [ { "visible_to": "'+promotionDate1+'", "promotion_title": "Buggy Included" }, { "visible_to": "'+promotionDate2+'", "promotion_title": "Early Booking discount " } ] }, "lead_product": { "name": "3 nights bed & breakfast at La Cala Resort & Spa and 2 rounds of golf (La Cala Asia, La Cala America or La Cala Europa) ", "saving": 0, "price": 219 }, "url": "la-cala-resort", "full_name": "La Cala Golf Resort", "title": "La Cala Resort" } ],';
        input+='"title": "Spain" }, "location_name": "Spain", "uid": "12345" }, { "overview": {} },';
        input+='{ "system": { "uid": "blt72b9040d3r61f5e12" }, "overview": { "venues": [ ';
        input+='{ "system": { "uid": "blt55b9040d7e61f5e10" }, "images": [ { "url": "https://images.contentstack.io" } ], "venue_information": { "official_star_rating": 4 }, "promotions": { "offers": [ { "visible_to": "'+promotionDate2+'", "promotion_title": "Early Booking discount " } ] }, "lead_product": { "name": "1 nights bed & breakfast and 2 rounds of golf (Galgorm Castle Course)", "saving": 0, "price": 195 }, "url": "galgorm-resort-spa", "full_name": "Galgorm Resort & Spa", "title": "Galgorm Resort & Spa" },';
        input+='{ "system": { "uid": "blt72b9040d3r61f5e11" }, "images": [ { "url": "https://images.contentstack.io" } ], "venue_information": { "official_star_rating": 4 }, "promotions": { "offers": [ { "visible_to": "'+promotionDate2+'", "promotion_title": "Early Booking discount " } ] }, "lead_product": { "name": "1 nights bed & breakfast and 2 rounds of golf (Hilton Templepatrick Golf Course) ", "saving": 0, "price": 89 }, "url": "hilton-belfast-templepatrick", "full_name": "Hilton Belfast TemplepJSONatrick", "title": "Hilton Templepatrick" } ],';
        input+='"title": "Northern Ireland" }, "uid": "67890", "location_name": "Northern Ireland" } ] } } }';

        List<Map<String,List<SObject>>> cacheData = new List<Map<String,List<SObject>>>();
        //List contains two maps:
        //[0] = Generic Content Map
        cacheData.add(new Map<String,List<SObject>>());
            //[1] = Generic Content Item Map
        //Both maps use the Content Id as the key
        cacheData.add(new Map<String,List<SObject>>());

        ContentStackContentType__mdt csct = [Select Id, Locale__c, ContentType__c, ContentSubtype__c From ContentStackContentType__mdt Where DataEventType__r.DeveloperName = :locationVenuesContentTypeDET];

        System.Test.startTest();
        cacheData = ContentStackGQLResponseHandler.parseToCacheObject(JSON.deserializeUntyped(input),cacheData,csct);
        System.Test.stopTest();

        System.debug(LoggingLevel.ERROR,'cacheData='+cacheData);

        System.assertEquals(2, cacheData[0].values().size(), '2 locations');        
        
        GenericContent__c genericContentSObject = (GenericContent__c)cacheData[0].values()[0][0];
        System.assertEquals('Spain', genericContentSObject.Name);
        System.assertEquals('blt72b9040d7e61f5e7', genericContentSObject.ContentId__c);
                
        genericContentSObject = (GenericContent__c)cacheData[0].values()[1][0];
        System.assertEquals('Northern Ireland', genericContentSObject.Name);
        System.assertEquals('blt72b9040d3r61f5e12', genericContentSObject.ContentId__c);
        
        System.assertEquals(2, cacheData[1].values().size(), '2 venue lists');
        System.assertEquals(2, cacheData[1].values()[0].size(), '2 venues');     
        System.assertEquals(2, cacheData[1].values()[1].size(), '2 venues');     
        
        GenericContentItem__c genericContentItemSObject = (GenericContentItem__c)cacheData[1].values()[0][0];
        System.assertEquals('blt72b9040d7e61f5e8', genericContentItemSObject.ContentId__c);

        Boolean isSubFilterApplied=false;
        Object o = JSON.deserializeUntyped(genericContentItemSObject.ContentJSON__c);
        if (o instanceof Map<String,Object>){

            Map<String,Object> outputMap = (Map<String,Object>)o;
            if (outputMap.containsKey('promotions')){

                if (outputMap.get('promotions') instanceof Map<String,Object>){

                    outputMap = (Map<String,Object>)outputMap.get('promotions');

                    if (outputMap.containsKey('offers')){

                        if (outputMap.get('offers') instanceof List<Object>){

                            List<Object> outputList = (List<Object>)outputMap.get('offers');//offers
                            System.assert(outputList.size()==1);
                            
                            if (outputList[0] instanceof Map<String,Object>){
                                Map<String,Object> offerMap = (Map<String,Object>)outputList[0];
                                isSubFilterApplied = offerMap.containsKey('promotion_title') && String.valueOf(offerMap.get('promotion_title')).equalsIgnoreCase('Buggy Included');//[{"promotion_title":"Buggy Included","visible_to":"2024-03-20"}]
                            }
                        }
                    }
                }
            }
        }
        System.assert(isSubFilterApplied);
    }/* */
    
    /* **/
    @isTest public static void singleTestCase8e(){//<---- Test Child (Generic Content Item) Sub-filters.
        
        String cachingInstructions='items,system.uid=>location_name=>type,overview=>venues';// -- items,system.uid=>location_name=>type,overview=>venues
        // Items is the parent, venues is the child - if no child set then Generic Content only population should be assumed.
        
        for (String ci : cachingInstructions.split('\\|')){ 

            List<String> connectionInstructions = ci.split(',');
            if (connectionInstructions.size()<2) continue;

            String c = connectionInstructions[1];
            if (connectionInstructions.size()==3) c+=','+connectionInstructions[2];

            listNameToCachingInstructions.put(connectionInstructions[0],c);
        }

        listNameToFilterInstructions.put('items',',~promotions.offers[visible_to][>=][TODAY]');

        ContentStackGQLResponseHandler.listNameToFilterInstructions = listNameToFilterInstructions;

        //Set/override caching instructions
        ContentStackGQLResponseHandler.listNameToCachingInstructions = listNameToCachingInstructions;

        String input = '{ "data": { "all_location": { "items": [ { "system": { "uid": "blt72b9040d7e61f5e7" }, "overview": { "venues": [ { "images": [ { "file_url": "https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blte373873f5ac21d44/6295f85bbf05100f50a8b5df/Main336_(Copy).jpg", "alt_text": "A villa pool at Aphrodite Hills Hotel" }, { "file_url": "https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt19226268eebd3ad9/6295f81d0d6f4a0fbcbefb99/Hestiades_Golf_View_J006_Balcony_(Copy).jpg", "alt_text": "A balcony with a seating area which overlooks the golf course at Aphrodite Hills Hotel" }, { "file_url": "https://images.contentstack.io/v3/assets/blt99dd26276e65134a/blt48a84c1d2f944283/6295f6d9dd28e20f45d61410/Apartment_Lounge_Apollo_(Copy).jpg", "alt_text": "The apartment lounge in Apollo residence at Aphrodite Hills Hotel" } ], "location": [ { "location_location_name": "Paphos", "location_url": "paphos", "system": { "uid": "blt9461581d775944a2" }, "website_title": "UK" } ], "venue_information": { "official_star_rating": 4 }, "promotions": { "offers": [ { "visible_to": "2023-12-31", "promotion_title": "Buggy Included" }, { "visible_to": "2024-03-31", "promotion_title": "Early Booking discount " } ] }, "lead_product": { "nights": 5, "rounds": 3, "currency": "Sterling", "name": "5 nights self catering at Aphrodite Hills Rentals and 3 rounds of golf (Aphrodite Hills, Secret Valley, Elea or Minthis Hills) - Based on 4 sharing a 2 Bed Apartment. Includes buggies at Aphrodite GC", "saving": 0, "price": 385 }, "reference_entity_url": "aphrodite-residences", "reference_entity_short_description": "Aphrodite Residences are your own “home away from home”. With a range of luxurious villas and apartments on offer, golfers can enjoy ultimate privacy in five-star surroundings with great golf close by.", "reference_entity_short_name": "Aphrodite Residences", "reference_entity_full_name": "Aphrodite Residences", "system": { "uid": "blt70d6a24bde40a738" }, "logo_selector": null, "title": "Aphrodite Hills Holiday Residences" } ], "title": "Cyprus" }, "location_name": "Cyprus", "uid": "12345" } ] } } }';

        List<Map<String,List<SObject>>> cacheData = new List<Map<String,List<SObject>>>();
        //List contains two maps:
        //[0] = Generic Content Map
        cacheData.add(new Map<String,List<SObject>>());
            //[1] = Generic Content Item Map
        //Both maps use the Content Id as the key
        cacheData.add(new Map<String,List<SObject>>());

        ContentStackContentType__mdt csct = [Select Id, Locale__c, ContentType__c, ContentSubtype__c From ContentStackContentType__mdt Where DataEventType__r.DeveloperName = :locationVenuesContentTypeDET];

        System.Test.startTest();
        cacheData = ContentStackGQLResponseHandler.parseToCacheObject(JSON.deserializeUntyped(input),cacheData,csct);
        System.Test.stopTest();

        System.debug(LoggingLevel.ERROR,'cacheData='+cacheData);

        
        GenericContent__c genericContentSObject = (GenericContent__c)cacheData[0].values()[0][0];
        System.assertEquals('Cyprus', genericContentSObject.Name);
        System.assertEquals('blt72b9040d7e61f5e7', genericContentSObject.ContentId__c);
                        
        System.assertEquals(1, cacheData[1].values().size(), '1 venue list');
        System.assertEquals(1, cacheData[1].values()[0].size(), '1 venue');
        
        GenericContentItem__c genericContentItemSObject = (GenericContentItem__c)cacheData[1].values()[0][0];
        System.assertEquals('blt70d6a24bde40a738', genericContentItemSObject.ContentId__c);

        Boolean isSubFilterApplied=false;
        Object o = JSON.deserializeUntyped(genericContentItemSObject.ContentJSON__c);
        if (o instanceof Map<String,Object>){

            Map<String,Object> outputMap = (Map<String,Object>)o;
            if (outputMap.containsKey('promotions')){

                if (outputMap.get('promotions') instanceof Map<String,Object>){

                    outputMap = (Map<String,Object>)outputMap.get('promotions');

                    if (outputMap.containsKey('offers')){

                        if (outputMap.get('offers') instanceof List<Object>){

                            List<Object> outputList = (List<Object>)outputMap.get('offers');//offers
                            System.assert(outputList.size()==1);
                            
                            if (outputList[0] instanceof Map<String,Object>){
                                Map<String,Object> offerMap = (Map<String,Object>)outputList[0];
                                isSubFilterApplied = offerMap.containsKey('promotion_title') && String.valueOf(offerMap.get('promotion_title')).startsWithIgnoreCase('Early Booking discount');
                            }
                        }
                    }
                }
            }
        }
        System.assert(isSubFilterApplied);
    }/* */    
    
    @isTest public static void negativeTestCase1(){//<---- Test Cache population - Empty list.
        
        listNameToCachingInstructions.put('items','system.uid=>full_name');//Set/override caching instructions
        ContentStackGQLResponseHandler.listNameToCachingInstructions = listNameToCachingInstructions;

        //<-- test Venue GraphQL response (pre parsed)
        String input = '{ "data": { "all_venue": { "items": [ { "location": [], "venue_information": { "official_star_rating": null }, "data_salesforce_id": "001b000003V2vNAAAZ", "lead_product": null, "url": "/6693---piersland-house-hotel", "short_description": null, "full_name": "6693 - Piersland House Hotel", "system": { "uid": "blt28c8af7e01f2c34e" } } ] } } }';

        List<Map<String,List<SObject>>> cacheData = new List<Map<String,List<SObject>>>();
        //List contains two maps:
        //[0] = Generic Content Map
        cacheData.add(new Map<String,List<SObject>>());
            //[1] = Generic Content Item Map
        //Both maps use the Content Id as the key
        cacheData.add(new Map<String,List<SObject>>());

        ContentStackContentType__mdt csct = new ContentStackContentType__mdt(ContentType__c='Venue',ContentSubtype__c=null);
        ContentTypeFieldMapping__mdt ctfm = new ContentTypeFieldMapping__mdt();
        ctfm.DeveloperName = 'SalesforceId';
        ctfm.MasterLabel = 'SalesforceId';
        ctfm.FieldName__c = 'SalesforceId__c';
        ctfm.FieldValuePath__c = '[get>location>list],[index>0>Map],[get>system>Map],[get>uid>end]';
        
        ContentStackGQLResponseHandler.contentTypeFieldMappings = new List<ContentTypeFieldMapping__mdt>{ ctfm };

        System.Test.startTest();
        cacheData = ContentStackGQLResponseHandler.parseToCacheObject(JSON.deserializeUntyped(input),cacheData,csct);
        System.Test.stopTest();

        System.debug(LoggingLevel.ERROR,'cacheData='+cacheData);

        System.assertEquals(1, cacheData[0].values().size(), '1 venue');

        GenericContent__c genericContentSObject = (GenericContent__c)cacheData[0].values()[0][0];
        System.assertEquals(null, genericContentSObject.SalesforceId__c);
        System.assertEquals('6693 - Piersland House Hotel', genericContentSObject.Name);
    }    
}