/*
Name:  FeefoReviewResponseHandlerTest.cls
======================================================
======================================================
Purpose: Test Suite for FeefoReviewResponseHandler.cls

97% Coverage
-------

====================================================== 
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2023-02-23  Initial development
*/
@isTest
public with sharing class FeefoReviewResponseHandlerTest {
    
    public static final String JSON_STATIC_RESOURCE_NAME = 'FeefoReviewTestJSON';

    @testSetup static void createTestData(){

        //Create a client account
        Account client = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert client;
        //Create a venue
        List<Account> venues = AP23_TestDataFactory.createVenueAccounts(1,true);
        //Create a golf course
        AP23_TestDataFactory.createGolfCourses(1,venues,true);
        //Create a booking
        Opportunity opp = AP23_TestDataFactory.createOpportunity(1, ApplicationConstant.PAIDFULLBALANCESTAGE,client)[0];
        insert opp;
        Booking__c booking = AP23_TestDataFactory.createBooking(1, client, opp.Id)[0];
        insert booking;


    }

    //1. Confirm the response is successfully deserialized and mapped to the correct fields in Salesforce
    //2. Confirm the records are all linked correctly
    //3. Confirm subsequent requests for this review result in an update rather than insert (no dupes)
    //4. Confirm new reviews are created if the id is unrecognised
    @isTest static void testResponseHandlingSuccess(){

        //Confirm no reviews exist
        system.assertEquals(0, [Select Count() From Review__c]);

        //Retrieve test setup data
        Account venueAccount = [Select Id, Golfbreaks_Venue_Id__c From Account Where IsPersonAccount = false]; 
        Account clientAccount = [Select Id, Name From Account Where IsPersonAccount = true]; 
        GolfCourse__c golfCourse = [Select Id, Name, Golfbreaks_Golf_Course_ID__c From GolfCourse__c];
        Booking__c booking = [Select Id, Golfbreaks_Booking_Number__c From Booking__c];

        //Retrieve sample json response from static resource
        String jsonResponseBody = [SELECT Id, Body FROM StaticResource WHERE Name = :JSON_STATIC_RESOURCE_NAME LIMIT 1]?.Body?.toString();
        system.assertEquals(true, jsonResponseBody.contains('{{AccountId}}'));
        system.assertEquals(true, jsonResponseBody.contains('{{BookingNumber}}'));
        system.assertEquals(true, jsonResponseBody.contains('{{VenueId}}'));
        system.assertEquals(true, jsonResponseBody.contains('{{GolfCourseId}}'));

        //Replace id references with available ids
        jsonResponseBody = jsonResponseBody.replace('{{AccountId}}', clientAccount.Id);
        jsonResponseBody = jsonResponseBody.replace('{{BookingNumber}}', Booking.Golfbreaks_Booking_Number__c);
        jsonResponseBody = jsonResponseBody.replace('{{VenueId}}', String.valueOf(venueAccount.Golfbreaks_Venue_Id__c));
        jsonResponseBody = jsonResponseBody.replace('{{GolfCourseId}}', String.valueOf(golfCourse.Golfbreaks_Golf_Course_Id__c));

        HttpResponse res = new HttpResponse();
        res.setBody(jsonResponseBody);

        test.startTest();
            Boolean isSucces = FeefoReviewResponseHandler.handleOutboundResponse(res, null, null, null);

            //Assertions
            system.assertEquals(true, isSucces);
            Review__c review = [Select Id, Client__c, Booking_Number__c, ModerationStatus__c, ReviewSubmittedDateTime__c, Source__c,
                                            ReviewUpdatedDateTime__c, NPS__c, Would_book_again__c, Comments_about_golf_break__c,
                                            Overall_Service_Provided__c, ReadReviewsBeforeSale__c,
                                            
                                            (Select Id, Name, Booking__c, ModerationStatus__c, Golf_Course__c, Golf_Course_General_Comments__c,
                                            Golf_Course_Overall_Score__c, Golf_Course_Facility__c,Golf_Course_Service__c,                                      
                                            Condition_of_Golf_Course__c, GolfCourseSKU__c
                                            From Golf_Course_Reviews__r),
                                            
                                            (Select Id, Name, Venue__c, Booking__c, ModerationStatus__c, Golf_Hotel_General_Comments__c,
                                            Golf_Hotel_Overall_Score__c, Golf_Hotel_Facility__c, Golf_Hotel_Service__c, Golf_Hotel_Accommodation__c, 
                                            Golf_Hotel_Location__c, Golf_Hotel_Food__c
                                            From Venue_Reviews__r) 
                                            
                                            From Review__c];
            
            //Review Field Mapping
            system.assertEquals(clientAccount.Id, review.Client__c);//linked to the client
            system.assertEquals(booking.Id, review.Booking_Number__c);//linked to the booking
            system.assertEquals('published',review.ModerationStatus__c);//is published
            system.assertEquals(DateTime.newInstance(2023,02,20,15,42,47), review.ReviewSubmittedDateTime__c);//expected created date
            system.assertEquals(DateTime.newInstance(2023,02,20,15,42,48), review.ReviewUpdatedDateTime__c );//expected modified date
            system.assertEquals(10, review.NPS__c);
            system.assertEquals('Yes', review.Would_book_again__c);
            system.assertEquals('No', review.ReadReviewsBeforeSale__c);
            system.assertEquals('Really really good', review.Comments_about_golf_break__c);
            system.assertEquals('Feefo', review.Source__c);
            system.assertEquals(5, review.Overall_Service_Provided__c);

            //Course Review Field Mapping
            system.assertEquals(1, review.Golf_Course_Reviews__r.size());

            GolfCourseReview__c course = review.Golf_Course_Reviews__r[0];
            system.assertEquals(booking.Id, course.Booking__c);
            system.assertEquals('published', course.ModerationStatus__c);
            system.assertEquals(golfCourse.Id, course.Golf_Course__c);
            system.assertEquals('Black Mountain Championship'+' ('+booking.Golfbreaks_Booking_Number__c+')', course.Name);
            system.assertEquals('Fantastic but challenging golf course.', course.Golf_Course_General_Comments__c);
            system.assertEquals(4, course.Golf_Course_Overall_Score__c);
            system.assertEquals(5, course.Golf_Course_Facility__c);
            system.assertEquals(4, course.Golf_Course_Service__c);
            system.assertEquals(5, course.Condition_of_Golf_Course__c);
            system.assertEquals('G1235', course.GolfCourseSku__c);

            //Venue Review Field Mapping
            system.assertEquals(1, review.Venue_Reviews__r.size());

            VenueReview__c venue = review.Venue_Reviews__r[0];
            system.assertEquals(booking.Id, venue.Booking__c);
            system.assertEquals('published', venue.ModerationStatus__c);
            system.assertEquals(venueAccount.Id, venue.Venue__c);
            system.assertEquals('Centara Grand Beach Resort & Villas Hua Hin'+' ('+booking.Golfbreaks_Booking_Number__c+')', venue.Name);
            system.assertEquals('Great location. Staff were excellent. Food and accommodation 5star.', venue.Golf_Hotel_General_Comments__c);
            system.assertEquals(5, venue.Golf_Hotel_Overall_Score__c);
            system.assertEquals(4, venue.Golf_Hotel_Facility__c);
            system.assertEquals(5, venue.Golf_Hotel_Service__c);
            system.assertEquals(5, venue.Golf_Hotel_Accommodation__c);
            system.assertEquals(4, venue.Golf_Hotel_Location__c);
            system.assertEquals(5, venue.Golf_Hotel_Food__c);

            //Manipulate the comments in the response (simulate review ammendments)
            jsonResponseBody = jsonResponseBody.replace('Really really good', 'Very good, well done Golfbreaks.');
            jsonResponseBody = jsonResponseBody.replace('Great location. Staff were excellent. Food and accommodation 5star.', 'Superb all around, thank you!');
            jsonResponseBody = jsonResponseBody.replace('Fantastic but challenging golf course.', 'Best... course... ever!');

            res.setBody(jsonResponseBody);//Apply changes

            //Process response
            isSucces = FeefoReviewResponseHandler.handleOutboundResponse(res, null, null, null);
        
            system.assertEquals(true, isSucces);
            //Confirm the existing reviews were updated
            review = [Select Id, Comments_about_golf_break__c,                                  
                                    (Select Id, Golf_Course_General_Comments__c From Golf_Course_Reviews__r),                                  
                                    (Select Id, Golf_Hotel_General_Comments__c From Venue_Reviews__r)    
                                    From Review__c];//Would throw an error if more than one (i.e. a dupe was expectedly created)
            //New comments added
            system.assertEquals('Very good, well done Golfbreaks.', review.Comments_about_golf_break__c);
            system.assertEquals('Superb all around, thank you!', review.Venue_Reviews__r[0].Golf_Hotel_General_Comments__c);
            system.assertEquals('Best... course... ever!', review.Golf_Course_Reviews__r[0].Golf_Course_General_Comments__c);

            //Manipulate the review's id. An unrecognised id should result in a new review being added
            jsonResponseBody = jsonResponseBody.replace('63f394f7e4b0af47c45c9aae', '63f394f7e4b0af47c45c9aaa');

            res.setBody(jsonResponseBody);//Apply changes

            system.assertEquals(0, [Select Count() From Review__c Where Id != :review.Id]);

            //Process response
            isSucces = FeefoReviewResponseHandler.handleOutboundResponse(res, null, null, null);

            //Confirm a new review entry was created.
            system.assertEquals(true, isSucces);
            system.assertEquals(1, [Select Count() From Review__c Where Id != :review.Id]);

        test.stopTest();

    }

    //Confirm exceptions are handled (failures logged to the Platform Log)
    @isTest static void testResponseHandlingFailure(){

        //Retrieve test setup data
        Account venueAccount = [Select Id, Golfbreaks_Venue_Id__c From Account Where IsPersonAccount = false]; 
        Account clientAccount = [Select Id, Name From Account Where IsPersonAccount = true]; 
        GolfCourse__c golfCourse = [Select Id, Name, Golfbreaks_Golf_Course_ID__c From GolfCourse__c];
        Booking__c booking = [Select Id, Golfbreaks_Booking_Number__c From Booking__c];

        //Retrieve sample json response from static resource
        String jsonResponseBody = [SELECT Id, Body FROM StaticResource WHERE Name = :JSON_STATIC_RESOURCE_NAME LIMIT 1]?.Body?.toString();
        system.assertEquals(true, jsonResponseBody.contains('{{AccountId}}'));
        system.assertEquals(true, jsonResponseBody.contains('{{BookingNumber}}'));
        system.assertEquals(true, jsonResponseBody.contains('{{VenueId}}'));
        system.assertEquals(true, jsonResponseBody.contains('{{GolfCourseId}}'));

        //Replace id references with available ids
        jsonResponseBody = jsonResponseBody.replace('INVALID ID!', clientAccount.Id);//Force a failure (invalid account id)
        jsonResponseBody = jsonResponseBody.replace('{{BookingNumber}}', Booking.Golfbreaks_Booking_Number__c);
        jsonResponseBody = jsonResponseBody.replace('{{VenueId}}', String.valueOf(venueAccount.Golfbreaks_Venue_Id__c));
        jsonResponseBody = jsonResponseBody.replace('{{GolfCourseId}}', String.valueOf(golfCourse.Golfbreaks_Golf_Course_Id__c));

        HttpResponse res = new HttpResponse();
        res.setBody(jsonResponseBody);

        test.startTest();
            Boolean isSucces = FeefoReviewResponseHandler.handleOutboundResponse(res, null, null, null);
        test.stopTest();

        system.assertEquals(false, isSucces);
        //Error is logged successfully
        system.assertEquals(1, [Select Count() From Golfbreaks__PlatformLog__c]);
    }



}