public with sharing class FeefoReviewAPIResponseDataStructure {
    
    //Social Links
    public class Social {
		public String facebook;//Link to facebook post
		public String twitter;//Link to twitter post
	}

    //API metadata (pagination etc)
	public class Meta {
		public Integer count;//Number of reviews returned
		public Integer pages;//Number of pages available
		public Integer page_size;//Max reviews per page
		public Integer current_page;//Current page
	}

    //Review data for venue and golf courses
	public class ProductReview {
		public Rating rating;//Customer score for the course or venue //GolfCourseReview__c > Golf_Course_Overall_Score__c //VenueReview__c > Golf_Hotel_Overall_Score__c
		public String id;//Feefo id for product review //GolfCourseReview__c > Sync_External_ID__c
		public String review;//Customer comments //GolfCourseReview__c > Golf_Course_General_Comments__c //VenueReview__c > Golf_Hotel_General_Comments__c
		public Social social;//Links to social media posts
		public String moderation_status;//Feefo publishing status e.g. rejected, pending, published
		public ProductDetail product;//Details about the product e.g. name, id 
		public String created_at;//Creation date in UTC
		public Integer helpful_votes;//Upvotes from other customers
		public List<Attribute> attributes;//Attribute reviews e.g. Services, Accommodation etc //GolfCourseReview__c > Acceptable_Pace_of_Play__c, Condition_of_Golf_Course__c, Golf_Course_Facility__c, Golf_Course_Service__c //VenueReview__c > Golf_Hotel_Accommodation__c, Golf_Hotel_Facility__c, Golf_Hotel_Food__c, Golf_Hotel_Location__c, Golf_Hotel_Service__c
	}

    //Response Container
	public Summary summary;//API context data
	public List<Review> reviews;//Review data

	public class Customer {
		public String name;//Client name
		public String email;//Client email address
		public String order_ref;//Golfbreaks Booking Number
		public String customer_ref;//Client SF Account Id
	}

	public class Rating {
		public Integer min;//Min possible score
		public Integer max;//Max possible score
		public Integer rating;//Selected score
	}

    //Product review attributes e.g. Service, Accommodation, Facilities etc
	public class Attribute {
		public Integer min;//Min possible score
		public Integer max;//Max possible score
		public Integer rating;//Selected score
		public String name;//Attribute name e.g. Location, Food & Dining Experience etc
	}

    //Overall Golfbreaks trip/booking review information e.g. rating, comments, booking again?
	public class Service {
		public Rating rating;//Golfbreaks score rating
		public String id;//Feefo id for service review
		public String title;
		public String review;//Customer Comments //Review__c > Comments_about_golf_break__c
		public List<Custom> custom;//Additional questions e.g Booking again? //Review__c > Would_book_again__c
		public String moderation_status;//Feefo publishing status e.g. rejected, pending, published
		public String created_at;//Creation date (UTC)
		public Integer helpful_votes;//Number of upvotes from others customers
	}

    //Venue and golf details e.g. name (title) and sku (id) 
	public class ProductDetail {
		public String title;//Venue/course name
		public List<Tags> tags;
		public String sku;//Id - Format = Venue (V)/Golf Course (G) + Golfbreaks Id e.g.V7216 (Venue 7216)
		public String url;
		public String reviews_url;//Related (product-specific) feefo url
        public String image_url;
	}

    //Custom question structure 
	public class Custom {
		public String question; //e.g. Would you consider using Golfbreaks to book your next golf trip?
		public String answer; //e.g. "Yes"/"No"
	}

    //NPS score
	public class Nps {
		public Integer rating;//Golfbreaks booking/trip score //Review__c > NPS__c
		public String created_at;
	}

    //Container for review data
	public class Review {
		public Merchant merchant;//Account id e.g. golfbreaks-uk
		public List<Tags> tags;//Custom GB tags
		public String url;
		public Social social;
		public Customer customer;
		public Service service;
		public List<ProductReview> products;
		public Nps nps;
		public List<String> products_purchased;
		public String last_updated_date;
	}

    //Golfbreaks identifier e.g. golfbreaks-uk, golfbreaks-us etc
	public class Merchant {
		public String identifier;
	}

    //Container for api Summary (meta) data 
	public class Summary {
		public Meta meta;
	}

    //Custom tags for data e.g. salesperson, team etc
	public class Tags {
		public String type;
		public String key;
		public List<String> values;
	}

}