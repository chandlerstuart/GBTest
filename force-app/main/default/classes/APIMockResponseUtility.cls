/**
* @author -         Abrar Haq (Accenture)
* @date -           20/05/2016
* @description -    A utility class to store Mock JSON responses (as per Clubhouse documentation).
* This class will help to use mock responses while Clubhouse will be down or not working properly.
* https://test-apisalesforce.golfbreaks.com/
* http://sfdcwebservice.azurewebsites.net/Public/Login?ReturnUrl=%2F
* #############Change Log#############
* Modified by     Version     Change Date
**/
public with sharing class APIMockResponseUtility{

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         20/05/2016
    Version -      1.0 
    Function -     Mock Response of Get Breakpoints API (as per Clubhouse documentation).
    https://test-apisalesforce.golfbreaks.com/
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String getBreakpointsAPIMockResponse(){
        String mockJSONResponse = '{ "SalesforceAccountID":"001b000000qDVy6AAZ", "GolfbreaksClientID":773180, "MembershipStatus":"Member", "QualificationDate":"2011-09-23T00:00:00", "AvailablePoints":-1321, "AvailableMonetaryValue":-132.1000, "PendingPoints":0, "PendingMonetaryValue":0.0, "MissedPoints":0, "MissedMonetaryValue":0.0, "PotentialPoints":0, "PotentialMonetaryValue":0.0, "LiveExpirationDate":"2016-08-31T00:00:00", "Transactions":[ { "PackageDetail":"The Belfry", "TransactionDate":"2011-10-24T00:00:00", "TransactionType":3, "TransactionTypeDescription":"Booking Points", "Status":1, "StatusDescription":"Available", "Points":200, "Description":"Break for 16 people travelling on 23 Oct 2011. Booking Ref: 317582", "MonetaryValue":20.0000, "PromotionID":null, "BookingID":"a0Yb0000008s6fMEAZ" }, { "PackageDetail":"Carden Park Hotel, Golf Resort and Spa", "TransactionDate":"2012-08-15T14:49:00", "TransactionType":4, "TransactionTypeDescription":"Redeemed Points", "Status":1, "StatusDescription":"Available", "Points":-200, "Description":"Mr Steve Cox (200 pts @ std rate)", "MonetaryValue":-20.0000, "PromotionID":null, "BookingID":"a0Yb0000008sDC6EAZ" }, { "PackageDetail":"Carden Park Hotel, Golf Resort and Spa", "TransactionDate":"2012-10-07T00:00:00", "TransactionType":3, "TransactionTypeDescription":"Booking Points", "Status":1, "StatusDescription":"Available", "Points":235, "Description":"Break for 16 people travelling on 6 Oct 2012. Booking Ref: 342889", "MonetaryValue":23.5000, "PromotionID":null, "BookingID":"a0Yb0000008sDC6EAZ" }, { "PackageDetail":"La Cala Resort, La Cala Golf Club", "TransactionDate":"2014-02-06T18:30:00", "TransactionType":4, "TransactionTypeDescription":"Redeemed Points", "Status":1, "StatusDescription":"Available", "Points":-1784, "Description":"Mr Steve Cox (1784 pts @ std rate)", "MonetaryValue":-178.4000, "PromotionID":null, "BookingID":"a0Yb0000008sKnqEAZ" }, { "PackageDetail":"La Cala Resort, La Cala Golf Club", "TransactionDate":"2014-08-31T00:00:00", "TransactionType":3, "TransactionTypeDescription":"Booking Points", "Status":1, "StatusDescription":"Available", "Points":228, "Description":"Break for 6 people travelling on 27 Aug 2014. Booking Ref: 372356", "MonetaryValue":22.8000, "PromotionID":null, "BookingID":"a0Yb0000008sKnqEAZ" } ] }';
        return mockJSONResponse;
    }

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         10/06/2016
    Version -      1.0 
    Function -     Mock JSON sample of Guest Group
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String getGuestGroupJSON(){
        String mockJSONResponse = '{ "ItineraryHotelComponents":[ { "ComponentExternalId":101, "ArrivalDate":"2016-05-25T10:09:51.6469264+01:00", "DepartingDate":"2016-05-25T10:09:51.6469264+01:00", "Description":"3 nights room only at the Hotel name", "HotelName":"text", "BoardType":"picklist", "HotelExternalId":123, "VenueExternalId":57, "Name":"text", "Meal":"text", "Nights":3, "RoomType":"picklist", "Occupancy":2, "Dinners":[ { "DinnerDate":"", "DinnerTime":"", "DinnerExternalId":100 } ] } ], "ItineraryGolfComponents":[ { "ComponentExternalId":102, "GolfDate":"2016-05-25T10:09:51.6469264+01:00", "Description":"desc", "GolfType":"Round/Golfpass/DayTicket/Unlimited/Two nines", "VenueExternalId":57, "Round":1, "Rounds":[ { "RoundsDate":"", "TeeTime":"", "Course":"", "CourseExternalId":34 } ] } ], "ItineraryFlightComponents":[ { "ComponentExternalId":103, "FlightDate":"2016-05-25T10:09:51.6469264+01:00", "ActivityType":"travel", "Description":"desc", "StartDatetime":"2016-05-25T10:09:51.6469264+01:00", "EndDatetime":"2016-05-25T10:09:51.6469264+01:00", "Depart":"London", "Arrival":"Moscow", "Company":"BA", "FlightNumber":"BA1234" } ], "Notes":{ "Accommodation":"text", "Golf":"text", "Flight":"text", "GettingAround":"text" } }';
        return mockJSONResponse;
    }


    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         29/06/2016
    Version -      1.0 
    Function -     Mock JSON sample of Guest Group
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String getGuestGroupJSON_New(){
        String mockJSONResponse = '{"GolfbreaksBookingID":1,"SalesforceBookingID":"SampleData00","GuestGroupItineraries":[{"GolfbreaksGuestGroupID":1,"Description":"SampleData0","AccommodationItineraryItems":[{"GolfbreaksHotelID":1,"SalesforceHotelID":"SampleData2","RoomType":"SampleData3","Meals":[{"MealType":0,"MealTypeDescription":"SampleData3","MenuName":"SampleData4","Allowance":1.0,"AllowanceCurrency":"SampleData5","DietaryRequirements":"SampleData6","MealItineraryDate":"2016-06-27T14:16:16.1755208+00:00","Description":"SampleData7","DisplayOrder":"SampleData8"},{"MealType":0,"MealTypeDescription":"SampleData9","MenuName":"SampleData10","Allowance":1.0,"AllowanceCurrency":"SampleData11","DietaryRequirements":"SampleData12","MealItineraryDate":"2016-06-27T14:16:16.1755208+00:00","Description":"SampleData13","DisplayOrder":"SampleData14"}],"ItineraryDate":"2016-05-13T00:00:00","Description":"SampleData15","DisplayOrder":"SampleData16"}],"FlightItineraryItems":[{"FlightClass":"SampleData17","LuggageAllowance":"SampleData18","GolfCarriageCost":"SampleData19","CustomerApiRequired":true,"CustomerApiUrl":"SampleData20","CustomerApiNotes":"SampleData21","CustomerApiCarrierName":"SampleData22","Notes":"SampleData8","OutboundLegs":[{"ToBeConfirmed":true,"Airline":"SampleData23","FlightNumber":"SampleData24","DepartureAirport":{"Name":"SampleData25","Code":"SampleData26","Country":"SampleData27"},"DepartureDateTime":"2016-06-27T14:16:16.1911736+00:00","DepartureDate":"SampleData28","DepartureTime":"SampleData29","DepartureTerminal":"SampleData30","ArrivalAirport":{"Name":"SampleData32","Code":"SampleData33","Country":"SampleData34"},"ArrivalDateTime":"2016-06-27T14:16:16.1911736+00:00","ArrivalTime":"SampleData35","ArrivalTerminal":"SampleData36"},{"ToBeConfirmed":true,"Airline":"SampleData37","FlightNumber":"SampleData38","DepartureAirport":{"Name":"SampleData39","Code":"SampleData40","Country":"SampleData41"},"DepartureDateTime":"2016-06-27T14:16:16.1911736+00:00","DepartureDate":"SampleData42","DepartureTime":"SampleData43","DepartureTerminal":"SampleData44","ArrivalAirport":{"Name":"SampleData45","Code":"SampleData46","Country":"SampleData47"},"ArrivalDateTime":"2016-06-27T14:16:16.1911736+00:00","ArrivalTime":"SampleData48","ArrivalTerminal":"SampleData49"}],"InboundLegs":[{"ToBeConfirmed":true,"Airline":"SampleData50","FlightNumber":"SampleData51","DepartureAirport":{"Name":"SampleData52","Code":"SampleData53","Country":"SampleData54"},"DepartureDateTime":"2016-06-27T14:16:16.1911736+00:00","DepartureDate":"SampleData55","DepartureTime":"SampleData56","DepartureTerminal":"SampleData57","ArrivalAirport":{"Name":"SampleData58","Code":"SampleData59","Country":"SampleData60"},"ArrivalDateTime":"2016-06-27T14:16:16.1911736+00:00","ArrivalTime":"SampleData61","ArrivalTerminal":"SampleData62"},{"ToBeConfirmed":true,"Airline":"SampleData63","FlightNumber":"SampleData64","DepartureAirport":{"Name":"SampleData65","Code":"SampleData66","Country":"SampleData67"},"DepartureDateTime":"2016-06-27T14:16:16.1911736+00:00","DepartureDate":"SampleData68","DepartureTime":"SampleData69","DepartureTerminal":"SampleData70","ArrivalAirport":{"Name":"SampleData71","Code":"SampleData72","Country":"SampleData73"},"ArrivalDateTime":"2016-06-27T14:16:16.1911736+00:00","ArrivalTime":"SampleData74","ArrivalTerminal":"SampleData75"}],"ItineraryDate":"2016-05-13T00:00:00","Description":"SampleData76","DisplayOrder":"SampleData77"}],"GenericItineraryItems":[{"TypeID":1,"TypeDescription":"SampleData78","ExternalDescription":"SampleData79","ChildItineraryItems":[{"ChildItineraryDate":"2016-06-27T14:16:16.1911736+00:00","StartTypeID":0,"StartType":"SampleData80","Note":"SampleData81","IsGenerated":true},{"ChildItineraryDate":"2016-06-27T14:16:16.1911736+00:00","StartTypeID":0,"StartType":"SampleData82","Note":"SampleData83","IsGenerated":true}],"ShowToClient":true,"ItineraryDate":"2016-05-13T00:00:00","Description":"SampleData84","DisplayOrder":"SampleData85"}],"GolfItineraryItems":[{"GolfBookingType":0,"Duration":1,"QtyRounds":2,"GolfRateType":"SampleData86","GolfRounds":[{"Course":{"GolfbreaksID":1,"SalesforceID":"SampleData87","Name":"SampleData88"},"GolfRoundDate":"2016-06-27T14:16:16.1911736+00:00","Holes":2,"IsPlayed":true,"IsTeeTimesNeeded":true,"DisplayOrder":5,"UseCouponNotes":true,"Note":"SampleData89"},{"Course":{"GolfbreaksID":1,"SalesforceID":"SampleData90","Name":"SampleData91"},"GolfRoundDate":"2016-06-27T14:16:16.1911736+00:00","Holes":2,"IsPlayed":true,"IsTeeTimesNeeded":true,"DisplayOrder":5,"UseCouponNotes":true,"Note":"SampleData92"}],"ItineraryDate":"2016-05-13T00:00:00","Description":"SampleData93","DisplayOrder":"SampleData94"}],"MealItineraryItems":[{"MealType":0,"MealTypeDescription":"SampleData95","MenuName":"SampleData96","Allowance":1.0,"AllowanceCurrency":"SampleData97","DietaryRequirements":"SampleData98","ItineraryDate":"2016-05-13T00:00:00","Description":"SampleData99","DisplayOrder":"SampleData100"},{"MealType":0,"MealTypeDescription":"SampleData101","MenuName":"SampleData102","Allowance":1.0,"AllowanceCurrency":"SampleData103","DietaryRequirements":"SampleData104","ItineraryDate":"2016-05-13T00:00:00","Description":"SampleData105","DisplayOrder":"SampleData106"}],"TransferItineraryItems":[{"Supplier":"SampleData107","SupplierNote":"SampleData108","AwaitingFlightDetails":true,"FlightTransfers":[{"MeetDateTime":"2016-06-27T14:16:16.1911736+00:00","MeetTimeTBC":true,"ToAirport":true,"Hotel":{"GolfbreaksID":1,"SalesforceID":"SampleData109","Name":"SampleData110"},"Airport":{"Name":"SampleData111","Code":"SampleData112","Country":"SampleData113"},"AirlineName":"SampleData114","FlightDateTime":"2016-06-27T14:16:16.1911736+00:00","FlightTimeTBC":true,"FlightNumber":"SampleData115","Terminal":"SampleData116","Notes":"SampleData117"}],"GolfTransfers":[{"MeetDateTime":"2016-06-27T14:16:16.1911736+00:00","MeetTimeTBC":true,"Hotel":{"GolfbreaksID":1,"SalesforceID":"SampleData118","Name":"SampleData119"},"GolfCourse":{"GolfbreaksID":1,"SalesforceID":"SampleData120","Name":"SampleData121"},"TeeTime":"2016-06-27T14:16:16.1911736+00:00","Notes":"SampleData122"}],"Contacts":[{"Name":"SampleData123","TelephoneNumbers":[{"Type":"SampleData124","Country":"SampleData125","CountryCode":"SampleData126","LocalNumber":"SampleData127","FromUKNumber":"SampleData128","Extension":"SampleData129"},{"Type":"SampleData130","Country":"SampleData131","CountryCode":"SampleData132","LocalNumber":"SampleData133","FromUKNumber":"SampleData134","Extension":"SampleData135"}]}],"ItineraryDate":"2016-05-13T00:00:00","Description":"SampleData136","DisplayOrder":"SampleData137"}]}]}';
        return mockJSONResponse;
    }


    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         07/06/2016
    Version -      1.0 
    Function -     Mock JSON sample of Quote and Booking Sundries
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String getQuoteANDBookingSundriesJSON(){
        String mockJSONResponse = '{ "SundriesTravelItems":[ { "ComponentExternalId":101, "TransportType":"Shuttle/Ferry/Car/Train/Airplane", "Vehicle":"Car/CAr and Trailer/Coach/Minibus/Van", "TaxInVehicle":4, "Height":">1.83/<1.83/>1.85/<1.85", "Description":"desc", "RouteDescription":"test", "OutboundDate":"2016-05-25T10:09:51.6469264+01:00", "OutboundTime":"00:00", "InboundDate":"2016-05-25T10:09:51.6469264+01:00", "InboundTime":"00:00", "DriverName":"text", "PassengerName":"text", "SupplierReference":"text" } ], "SundriesTransferItems":{ "FlighTransfers":[ { "ComponentExternalId":102, "MeetAt":"Airport/Hotel", "FlightDate":"2016-05-25T10:09:51.6469264+01:00", "LocalTime":"00:00", "FlightNumber":"text", "AirportCode":"text", "AirportName":"text", "AirportTerminal":"text", "HotelName":"text", "HotelExternalId":123 } ], "GolfTransfers":[ { "ComponentExternalId":103, "GolfTransfersDate":"2016-05-25T10:09:51.6469264+01:00", "GolfTransfersType":"Flight/Golf", "FromHotelExternalId":123, "ToGolfVenueId":57, "ToGolfCourseId":34, "MeetTime":"00:00", "TeeTime":"00:00" } ] }, "SundriesGenericItems":[ { "ComponentExternalId":104, "SundriesGenericItemsType":"Non Refundable Deposit/1 in 8 go Free (not shown to the client)/Transfers (not shown to the client)/ Reduce PAckage Price (not shown to the client)/Increase package Price(not shown to the client)/Free Place/Free place (not shown to the client)/Eurotunnel/Price Match/Cancellation Charge/Other/Other (not shown to the client)/Extra Bed/TeeOfTime/PGA Member commission 5%/Foremost 5% commission/Golf buggy/Tuition/Private dinning/Early Birdie/Children/Coffee & Bacon rolls/Staff Promotion/Discount/Refund/Commissions Earned", "Description":"desc", "Quantity":2 } ] }';
        return mockJSONResponse;
    }

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         11/06/2016
    Version -      1.0 
    Function -     Get Golfbreaks Image API Mock Response
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String getGolfbreaksImageAPIJSON(){
        String mockJSONResponse = '[{"Url":"the-belfry/manor-house.jpg","Title":"Beautiful manor house at the famous Belfry Resort","Description":null}, {"Url":"the-belfry/the-belfry-sams-bar.jpg","Title":"The Belfry Sams Bar, perfect for watching sport after your round","Description":null}]';
        return mockJSONResponse;
    }

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         21/06/2016
    Version -      1.0 
    Function -     Get the JSON to set Cookie in the Browser
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String getBrowserCookieJSON(){
        String mockJSONResponse = '{"MemberId":773180,"url":"http://www.wealthbox.com/wp-content/uploads/2015/06/Marc-Benioff_banner.jpg","notification":4}';
        return mockJSONResponse;
    }

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         22/06/2016
    Version -      1.0 
    Function -     Get the JSON with the list of Booking Ids
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String getBookingIdsJSON(){
        String mockJSONResponse = '{"BookingIDs": [1624296, 2247601, 2247304]}';
        return mockJSONResponse;        
    }
    
    /*************************************************************************************** 
    Developer -    Jerella Ledesma (Accenture)
    Date -         29/06/2016
    Version -      1.0 
    Function -     Get for the JSON of the POST Tokenised Card
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String getPostTokenisedCardJSON(){
        String mockJSONResponse = '{ "Success":true, "ResultCode":"200", "ClientAccountID":"0018E00000HMeOX", "PaymentManager":"Payment Manager", "MerchantAccount":123454321, "Token":"1234567890" }';
        return mockJSONResponse;        
    }

    /*************************************************************************************** 
    Developer -    Abrar Haq (Accenture)
    Date -         30/06/2016
    Version -      1.0 
    Function -     Get the Enquiry JSON
    #############Change Log#############
    Modified by     Version     Change Date
    ****************************************************************************************/
    public static String getEnquiryJSON(){
        //String mockJSONResponse = '{ "AffiliateCampaignID":999726232, "ClientAccountID":"1394598", "Salutation":"Mr.", "FirstName":"Patrick", "LastName":"Villarica", "Phone":"+447561498190", "Email":"patrick.c.villarica+test@accenture.com", "PromotionCode":"sample string 7", "Nights":8, "PreferredTravelDate":"2016-07-02T09:41:08.870Z", "TravelGroupSize":10, "TripRegion":1, "AdditionalInformation":"Initial Testing", "Venue":"Oxford", "VenueAccountIDs":[], "NewsletterSignUp":true }';
        String mockJSONResponse = '{"AffiliateCampaignID":999726232, "ClientAccountID": "", "Salutation":"Mr.", "FirstName": "Patrick", "LastName": "Villarica", "Phone": "+447561498190", "Email": "patrick.c.villarica@accenture.com", "Nights": 8, "PreferredTravelDate": "2016-07-02 12:06:33", "TravelGroupSize": 10, "TripRegion": "1", "AdditionalInformation": "Initial Testing ", "Venue": "Oxford", "VenueAccountIDs": [], "NewsletterSignUp": true}';
        return mockJSONResponse;        
    }
    
}