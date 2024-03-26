/*
Name:  FeefoReviewResponseHandler.cls
======================================================
======================================================
Purpose: Handler class for Feefo Review Data Event Type(s).
Responsible for creating and managing review data in 
Salesforce (Review__c, GolfCourseReview__c, VenueReview__c)
-------

====================================================== 
======================================================
History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2023-02-22  Initial development
1.1  J Radcliffe   2023-11-17  Isolate post travel reviews (excl event reviews etc)
*/
public with sharing class FeefoReviewResponseHandler implements IDataEventTypeResponseHandler3 {
    
    public class CustomException extends Exception {}

    //Custom Questions
    public static final String SERVICE_QUESTION_BOOK_AGAIN = 'Would you consider using {{merchantName}} to book your next golf trip?';
    public static final String SERVICE_QUESTION_READ_REVIEWS = 'Did you read reviews on the {{merchantName}} website before booking?';

    //Venue Attributes
    public static final String VENUE_ATTRIBUTE_SERVICE = 'Service';
    public static final String VENUE_ATTRIBUTE_ACCOMMODATION = 'Accommodation';
    public static final String VENUE_ATTRIBUTE_FACILITIES = 'Facilities';
    public static final String VENUE_ATTRIBUTE_LOCATION = 'Location';
    public static final String VENUE_ATTRIBUTE_FOOD = 'Food & Dining Experience';

    //Golf Course Attributes
    public static final String GOLF_COURSE_ATTRIBUTE_SERVICE = 'Service at the course';
    public static final String GOLF_COURSE_ATTRIBUTE_CONDITION = 'Condition of golf course';
    public static final String GOLF_COURSE_ATTRIBUTE_FACILITIES = 'Facilities';

    public static Boolean handleOutboundResponse(HttpResponse r, String reshapedResponseBody, Id outboundCalloutId, Set<Id> recordIds){
        try{
            //Deserialize response data
            String jsonString = r.getBody();
            if(jsonString == null) throw new CustomException('No data returned by Feefo.');
            FeefoReviewAPIResponseDataStructure data = (FeefoReviewAPIResponseDataStructure)JSON.deserialize(jsonString, FeefoReviewAPIResponseDataStructure.class);
            if(data == null || data.reviews == null || data.reviews.size()==0) throw new CustomException('No review data returned by Feefo.');

            //Collect Existing Review Data
            Map<String,Review__c> extReviewIdToReviewMap = new Map<String,Review__c>();
            Map<String,GolfCourseReview__c> extGolfCourseReviewIdToGolfCourseReviewMap = new Map<String,GolfCourseReview__c>();
            Map<String,VenueReview__c> extVenueReviewIdToVenueReviewMap = new Map<String,VenueReview__c>();
            Map<String,Booking__c> bookingNumberToBookingMap = new Map<String,Booking__c>();
            Map<Integer,Account> venueIdToVenueAccountMap = new Map<Integer,Account>();
            Map<Integer,GolfCourse__c> golfCourseIdToGolfCourseMap = new Map<Integer,GolfCourse__c>();

            //Create Final Upsert List (DML)
            List<SObject> upsertList = new List<SObject>();
            List<Review__c> reviewList = new List<Review__c>();
            List<VenueReview__c> venueReviewList = new List<VenueReview__c>();
            List<GolfCourseReview__c> golfCourseReviewList = new List<GolfCourseReview__c>();

            //Loop through and collect external ids and references
            Set<String> existingReviewIds = new Set<String>();
            Set<String> bookingNumbers = new Set<String>();
            Set<Integer> venueIds = new Set<Integer>();
            Set<Integer> courseIds = new Set<Integer>();
            for(FeefoReviewAPIResponseDataStructure.Review review : data.reviews){
                String reviewId = review?.service?.id;
                system.debug('reviewId > '+reviewId);
                if(reviewId == null) continue;
                
                if(!isSupportedReview(review?.tags)) continue;//1.1+

                existingReviewIds.add(reviewId);
                if(review?.customer?.order_ref != null) bookingNumbers.add(review.customer.order_ref);
                if(review.products != null && review.products.size()>0){
                    for(FeefoReviewAPIResponseDataStructure.ProductReview prodReview : review.products){
                        String sku = prodReview?.product?.sku;
                        if(sku == null) continue;
                        Boolean isVenue = (sku.startsWithIgnoreCase('v'))?true:false;
                        Boolean isGolfCourse = (sku.startsWithIgnoreCase('g'))?true:false;
                        String idx = sku.right(sku.length()-1);
                        if(isVenue){
                            venueIds.add(Integer.valueOf(idx));
                        }else if(isGolfCourse){
                            courseIds.add(Integer.valueOf(idx));
                        }
                    }
                }
            }

            //Use the ids and references to retrieve existing records and store in maps

            //REVIEW DATA
            for(Review__c review : [Select Id, Review_ID__c,
                                            (Select Id, Sync_External_ID__c From Golf_Course_Reviews__r),
                                            (Select Id, Sync_External_ID__c From Venue_Reviews__r)
                                            From Review__c Where Review_ID__c In :existingReviewIds]){
                extReviewIdToReviewMap.put(review.Review_ID__c,review);
                if(review.Golf_Course_Reviews__r.size()>0){
                    for(GolfCourseReview__c gcr : review.Golf_Course_Reviews__r){
                        extGolfCourseReviewIdToGolfCourseReviewMap.put(gcr.Sync_External_ID__c,gcr);
                    }
                }
                if(review.Venue_Reviews__r.size()>0){
                    for(VenueReview__c vr : review.Venue_Reviews__r){
                        extVenueReviewIdToVenueReviewMap.put(vr.Sync_External_ID__c,vr);
                    }
                }
            }

            //BOOKING DATA
            for(Booking__c booking : [Select Id, Golfbreaks_Booking_Number__c From Booking__c Where Golfbreaks_Booking_Number__c In :bookingNumbers]){
                bookingNumberToBookingMap.put(booking.Golfbreaks_Booking_Number__c,booking);
            }

            //VENUE DATA
            for(Account venue : [Select Id, Golfbreaks_Venue_Id__c From Account Where Golfbreaks_Venue_Id__c In :venueIds]){
                venueIdToVenueAccountMap.put(Integer.valueOf(venue.Golfbreaks_Venue_Id__c),venue);
            }

            //GOLF COURSE DATA
            for(GolfCourse__c course : [Select Id, Golfbreaks_Golf_Course_ID__c From GolfCourse__c Where Golfbreaks_Golf_Course_ID__c In :courseIds]){
                golfCourseIdToGolfCourseMap.put(Integer.valueOf(course.Golfbreaks_Golf_Course_ID__c),course);
            }

            //Loop through review data and construct records for upsert
            for(FeefoReviewAPIResponseDataStructure.Review review : data.reviews){
                
                String extReviewId = review?.service?.id;
                if(extReviewId == null) continue;            

                if(!isSupportedReview(review?.tags)) continue;//1.1+

                String reviewCreatedDateString = review?.service?.created_at;
                if(reviewCreatedDateString == null) continue;
                DateTime createdDate = Datetime.valueOfGMT(review.service.created_at.left(19).replace('T',' '));
                if(createdDate<=DateTime.newInstance(2023,02,20,0,0,0)) continue;//Ignore legacy reviews (imported into Feefo ahead of the release). Legacy reviews won't have a recognisable id and will result in duplicate reviews being created. They also won't have the correct identifiers to link to the related records.

                Boolean isNewReview = !extReviewIdToReviewMap?.containsKey(extReviewId);
                
                String bookingId = bookingNumberToBookingMap.get(review.customer.order_ref)?.Id;
                if(bookingId == null) continue;

                //Create Review__c
                Review__c rev = new Review__c();
                if(!isNewReview) rev.Id = extReviewIdToReviewMap.get(extReviewId)?.Id;//Assign record id for upsert
                //rev.Name = review.customer.name+' ('+review.customer.order_ref+')';
                rev.Review_ID__c = extReviewId;
                if(review?.customer?.customer_ref != null) rev.Client__c = review?.customer?.customer_ref;
                rev.Booking_Number__c = bookingId;
                if(review?.service?.review != null) rev.Comments_about_golf_break__c = review?.service?.review;
                if(review?.nps?.rating != null) rev.NPS__c = review?.nps?.rating; 
                rev.ModerationStatus__c = review?.service?.moderation_status;
                rev.ReviewSubmittedDateTime__c = Datetime.valueOfGMT(review.service.created_at.left(19).replace('T',' '));
                rev.ReviewUpdatedDateTime__c = Datetime.valueOfGMT(review.last_updated_date.left(19).replace('T',' '));
                rev.Source__c = 'Feefo';
                if(review.service?.rating?.rating != null) rev.Overall_Service_Provided__c = review.service?.rating?.rating;

                List<FeefoReviewAPIResponseDataStructure.Custom> customQuestions = review?.service?.custom;
                if(customQuestions != null && customQuestions.size()>0){
                    for(FeefoReviewAPIResponseDataStructure.Custom customQ : customQuestions){
                        if(customQ.question.equalsIgnoreCase(SERVICE_QUESTION_BOOK_AGAIN)){
                            if(customQ.answer != null) rev.Would_book_again__c = customQ.answer;
                        }else if(customQ.question.equalsIgnoreCase(SERVICE_QUESTION_READ_REVIEWS)){
                            if(customQ.answer != null) rev.ReadReviewsBeforeSale__c = customQ.answer;
                        }else{continue;}
                    }
                }

                reviewList.add(rev);

                //Create review reference (for upserting child records)
                Review__c reviewRef = new Review__c(Review_ID__c=extReviewId);
                if(isNewReview) upsertList.add(reviewRef);//Only add to list if existing id is not available

                if(review.products != null && review.products.size()>0){
                    for(FeefoReviewAPIResponseDataStructure.ProductReview prodReview : review.products){
                        
                        String extProdReviewId = prodReview.id;
                        Boolean isNewProdReview; 

                        String sku = prodReview?.product?.sku;
                        if(sku == null) continue;
                        Boolean isVenue = (sku.startsWithIgnoreCase('v'))?true:false;
                        Integer idx = Integer.valueOf(sku.right(sku.length()-1));
                        if(isVenue){//Venue
                            
                            isNewProdReview = (!extVenueReviewIdToVenueReviewMap.containsKey(extProdReviewId))?true:false;

                            //Create VenueReview__c
                            VenueReview__c venRev = new VenueReview__c();
                            venRev.Name = prodReview.product.title+' ('+review.customer.order_ref+')';
                            if(!isNewProdReview) venRev.Id = extVenueReviewIdToVenueReviewMap.get(extProdReviewId)?.Id;//Assign record id for upsert
                            if(isNewReview){
                                venRev.Review__r = reviewRef;
                            }else{
                                venRev.Review__c = rev.Id;
                            }
                            if(venueIdToVenueAccountMap.containsKey(idx)) venRev.Venue__c = venueIdToVenueAccountMap.get(idx)?.Id;
                            if(bookingId != null) venRev.Booking__c = bookingId;
                            if(prodReview.review != null) venRev.Golf_Hotel_General_Comments__c = prodReview.review;
                            if(prodReview?.rating?.rating != null) venRev.Golf_Hotel_Overall_Score__c = prodReview?.rating?.rating;
                            if(sku != null) venRev.Golf_Hotel_SKU__c = sku;
                            if(extProdReviewId != null) venRev.Sync_External_ID__c = extProdReviewId;
                            if(prodReview.moderation_status != null) venRev.ModerationStatus__c = prodReview.moderation_status;

                            if(prodReview.attributes != null && prodReview.attributes.size()>0){
                                for(FeefoReviewAPIResponseDataStructure.Attribute attribute : prodReview.attributes){
                                    if(attribute.name == null) continue;
                                    if(attribute.name.equalsIgnoreCase(VENUE_ATTRIBUTE_SERVICE)){
                                        if(attribute.rating != null) venRev.Golf_Hotel_Service__c = attribute.rating;
                                    }else if(attribute.name.equalsIgnoreCase(VENUE_ATTRIBUTE_ACCOMMODATION)){
                                        if(attribute.rating != null) venRev.Golf_Hotel_Accommodation__c = attribute.rating;
                                    }else if(attribute.name.equalsIgnoreCase(VENUE_ATTRIBUTE_FACILITIES)){
                                        if(attribute.rating != null) venRev.Golf_Hotel_Facility__c = attribute.rating;
                                    }else if(attribute.name.equalsIgnoreCase(VENUE_ATTRIBUTE_LOCATION)){	
                                        if(attribute.rating != null) venRev.Golf_Hotel_Location__c = attribute.rating;
                                    }else if(attribute.name.equalsIgnoreCase(VENUE_ATTRIBUTE_FOOD)){
                                        if(attribute.rating != null) venRev.Golf_Hotel_Food__c = attribute.rating;
                                    }else{continue;}
                                }
                            }
                            
                            venueReviewList.add(venRev);

                        }else{//Golf Course

                            isNewProdReview = (!extGolfCourseReviewIdToGolfCourseReviewMap.containsKey(extProdReviewId))?true:false;

                            //Create GolfCourseReview__c
                            GolfCourseReview__c gcRev = new GolfCourseReview__c();
                            gcRev.Name = prodReview.product.title+' ('+review.customer.order_ref+')';
                            if(!isNewProdReview) gcRev.Id = extGolfCourseReviewIdToGolfCourseReviewMap.get(extProdReviewId)?.Id;//Assign record id for upsert
                            if(isNewReview){
                                gcRev.Review__r = reviewRef;
                            }else{
                                gcRev.Review__c = rev.Id;
                            }
                            if(golfCourseIdToGolfCourseMap.containsKey(idx)) gcRev.Golf_Course__c = golfCourseIdToGolfCourseMap.get(idx)?.Id;
                            if(bookingId != null) gcRev.Booking__c = bookingId;
                            if(prodReview.review != null) gcRev.Golf_Course_General_Comments__c = prodReview.review;
                            if(prodReview?.rating?.rating != null) gcRev.Golf_Course_Overall_Score__c = prodReview?.rating?.rating;
                            gcRev.Sync_External_ID__c = extProdReviewId;
                            gcRev.ModerationStatus__c = prodReview.moderation_status;
                            if(sku != null) gcRev.GolfCourseSKU__c = sku;

                            if(prodReview.attributes != null && prodReview.attributes.size()>0){
                                for(FeefoReviewAPIResponseDataStructure.Attribute attribute : prodReview.attributes){
                                    if(attribute.name == null) continue;
                                    if(attribute.name.equalsIgnoreCase(GOLF_COURSE_ATTRIBUTE_SERVICE)){
                                        if(attribute.rating != null) gcRev.Golf_Course_Service__c = attribute.rating;
                                    }else if(attribute.name.equalsIgnoreCase(GOLF_COURSE_ATTRIBUTE_CONDITION)){
                                        if(attribute.rating != null) gcRev.Condition_of_Golf_Course__c = attribute.rating;
                                    }else if(attribute.name.equalsIgnoreCase(GOLF_COURSE_ATTRIBUTE_FACILITIES)){
                                        if(attribute.rating != null) gcRev.Golf_Course_Facility__c = attribute.rating;
                                    }else{continue;}
                                }
                            }     
                            golfCourseReviewList.add(gcRev);
                        }
                    }
                }
            }
            
            if(reviewList.size()>0) upsertList.addAll(reviewList);
            if(venueReviewList.size()>0) upsertList.addAll(venueReviewList);
            if(golfCourseReviewList.size()>0) upsertList.addAll(golfCourseReviewList);
            
            //Add/update reviews (all or none = false)
            if(upsertList.size()>0){
                Database.UpsertResult[] results = Database.upsert(upsertList,false);
                Golfbreaks.PlatformLogManager.logExceptions(results,'FeefoReviewResponseHandler','handleOutboundResponse',upsertList);
            }

            return true;
        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'FeefoReviewResponseHandler','handleOutboundResponse');
            return false;
        }
    }

    //1.1+
    public static boolean isSupportedReview(List<FeefoReviewAPIResponseDataStructure.Tags> tags){
        if(tags == null || tags.size()==0) return false;
        for(FeefoReviewAPIResponseDataStructure.Tags tag : tags){
            if(tag.key.containsIgnoreCase('campaign') && tag.values.size()==1 && tag.values[0].containsIgnoreCase('Post Travel')) return true;
        }
        return false;
    }

}