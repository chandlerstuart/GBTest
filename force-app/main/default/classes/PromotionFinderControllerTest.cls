/*
Name:  PromotionFinderControllerTest
======================================================
======================================================
Purpose:
-------
Test Suite for PromotionFinderController.cls
======================================================
======================================================


History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2023-10-10  Initial development.
1.1  J Radcliffe   2023-12-21  Remove Remaining Promotions
1.2  C Stuart      2024-02-08  Added new field entry (IsPromotionActive__c) to 'Promotion Assignment' to forcefully activate a Promotion & Modified 'Rating__c' field API Name to 'PromotionRating__c'
*/ 
@isTest
private class PromotionFinderControllerTest {

    @isTest
    static void testLoadRecordDetails() {
        // Create test account
        Account testAccount = AP23_TestDataFactory.createPersonAccount(1)[0];
        insert testAccount;

        // Create test opp
        Opportunity testOpportunity = AP23_TestDataFactory.createOpportunity(1, 'New', testAccount)[0];
        testOpportunity.TravelGroupSize__c = 6;
        testOpportunity.CountriesInterested__c = 'Spain';
        testOpportunity.PreferredTravelDate__c = System.today().addDays(10);
        insert testOpportunity;

        Test.startTest();
            // Call the loadRecordDetails method with the test Opportunity Id
            PromotionFinderController.ComponentData result = PromotionFinderController.loadData(testOpportunity.Id);
        Test.stopTest();

        // Verify that the returned Opportunity matches the test Opportunity
        System.assertEquals(testOpportunity.Id, result.Opportunity.Id);
        System.assertEquals(testOpportunity.TravelGroupSize__c, result.Opportunity.TravelGroupSize__c);
        System.assertEquals(testOpportunity.PreferredTravelDate__c, result.Opportunity.PreferredTravelDate__c);
    }

    @isTest 
    static void testSearchActivePromotions() {
        
        // Create 10 venues
        List<Account> testVenues = AP23_TestDataFactory.createVenueAccounts(5, false);
        
        //Assign values
        testVenues[0].Name = 'The Belfry';
        testVenues[0].BillingCountry = 'United Kingdom';
        testVenues[2].Sales_Region__c = 'England & Wales';
        testVenues[1].Name = 'Celtic Manor';
        testVenues[1].BillingCountry = 'United Kingdom';
        testVenues[1].Sales_Region__c = 'England & Wales';
        testVenues[2].Name = 'Golden Clube Resort Cabanas';
        testVenues[2].BillingCountry = 'Portugal';
        testVenues[2].Sales_Region__c = 'Portugal';
        testVenues[3].Name = 'Hyatt Centric Brickell Miami';
        testVenues[3].BillingCountry = 'United States';
        testVenues[3].Sales_Region__c = 'USA';
        testVenues[4].Name = 'Vincci Maritimo';
        testVenues[4].BillingCountry = 'Spain';
        testVenues[4].Sales_Region__c = 'Spain';
        insert testVenues;

        //Assign promotions to each venue
        List<ProductPromotion__c> promotions = new List<ProductPromotion__c>();
        promotions.add(new ProductPromotion__c(Name = 'The Belfry INACTIVE Promo', Venue__c = testVenues[0].Id, PromotionRating__c = 6, MinimumNumberOfGuests__c=5, MaximumNumberOfGuests__c = 10, TravelStartDate__c = System.today().addDays(-10), TravelEndDate__c = System.today().addDays(10), BookingWindowStartDate__c = System.today().addDays(3), IsPromotionActive__c = true)); // 1.2+ New field entry required (IsPromotionActive__c) & Modified 'Rating__c' field API Name to 'PromotionRating__c'
        promotions.add(new ProductPromotion__c(Name = 'The Belfry Promo', Venue__c = testVenues[0].Id, PromotionRating__c = 5, MinimumNumberOfGuests__c=10, MaximumNumberOfGuests__c = 20, TravelStartDate__c = System.today().addDays(-10), TravelEndDate__c = System.today().addDays(10), IsPromotionActive__c = true)); // 1.2+ New field entry required (IsPromotionActive__c) & Modified 'Rating__c' field API Name to 'PromotionRating__c'
        promotions.add(new ProductPromotion__c(Name = 'Celtic Manor Promo', Venue__c = testVenues[1].Id, PromotionRating__c = 4, MinimumNumberOfGuests__c=7, MaximumNumberOfGuests__c = 10, TravelStartDate__c = System.today().addDays(-5), TravelEndDate__c = System.today().addDays(10), IsPromotionActive__c = true)); // 1.2+ New field entry required (IsPromotionActive__c) & Modified 'Rating__c' field API Name to 'PromotionRating__c'
        promotions.add(new ProductPromotion__c(Name = 'Golden Clube Resort Cabanas Promo', Venue__c = testVenues[2].Id, PromotionRating__c = 3, MinimumNumberOfGuests__c=null, MaximumNumberOfGuests__c = 10, TravelStartDate__c = System.today().addDays(3), TravelEndDate__c = System.today().addDays(20), IsPromotionActive__c = true)); // 1.2+ New field entry required (IsPromotionActive__c) & Modified 'Rating__c' field API Name to 'PromotionRating__c'
        promotions.add(new ProductPromotion__c(Name = 'Hyatt Centric Brickell Miami Promo', Venue__c = testVenues[3].Id, PromotionRating__c = 2, MinimumNumberOfGuests__c=2, MaximumNumberOfGuests__c = null, TravelStartDate__c = System.today().addDays(5), TravelEndDate__c = System.today().addDays(45), IsPromotionActive__c = true)); // 1.2+ New field entry required (IsPromotionActive__c) & Modified 'Rating__c' field API Name to 'PromotionRating__c'
        promotions.add(new ProductPromotion__c(Name = 'Vincci Maritimo', Venue__c = testVenues[4].Id, PromotionRating__c = 1, MinimumNumberOfGuests__c = 3, MaximumNumberOfGuests__c = 20, TravelStartDate__c = System.today().addDays(-10), TravelEndDate__c = System.today().addDays(10), IsPromotionActive__c = true)); // 1.2+ New field entry required (IsPromotionActive__c) & Modified 'Rating__c' field API Name to 'PromotionRating__c'
        insert promotions;

        Test.startTest();
            PromotionFinderController.PromotionData data;

            //1. Check the expected default results when no search terms or filters applied.

            data = PromotionFinderController.searchActivePromotions(null, null, null, null, null);
            system.assertNotEquals(null, data);
            system.assertEquals(0, data.recommendedPromotions.size());//No recommended promotions - no insights or filter criteria defined.
            //system.assertEquals(5, data.remainingPromotions.size());//5 active remaining promotions are returned. //1.1-
            //Confirm display order (highest to lowest)
            /*1.1-
            Integer expectedRating = 5;
            for(Integer i=0;i<5;i++){
                system.assertEquals(expectedRating, data.remainingPromotions[i].priority);
                expectedRating--;
            }*/

            //2. Add search term. Confirm that accounts matching the search term are prioritised and the remainder are listed in priority order desc.

            data = PromotionFinderController.searchActivePromotions(new List<String>{'USA'}, new List<String>{'Name','BillingCountry','Sales_Region__c'}, null, null, null);//USA promotions take priority.
            system.assertNotEquals(null, data);
            system.assertEquals(1, data.recommendedPromotions.size());//1 Recommended promotion (under USA Sales Region)
            //system.assertEquals(4, data.remainingPromotions.size());//4 remaining promotions retrieved. //1.1-
            //Confirm display order (USA first then highest to lowest)
            system.assertEquals(testVenues[3].Id, data.recommendedPromotions[0].promotion.Venue__c);
            
            /*1.1-
            Integer rating;
            for(PromotionFinderController.PromotionWrapper promotion : data.remainingPromotions){
                if(rating == null){
                    rating = promotion.priority;//Assign the first priority rating
                }else {
                    system.assertEquals(true, promotion.priority<rating);//Each promotion has a lower rating than the previous rating
                    rating = promotion.priority;
                }
            }*/

            //3. Apply a group size filter and confirm only promotions relevant to that group size are returned.

            data = PromotionFinderController.searchActivePromotions(new List<String>{'England'}, new List<String>{'Name','BillingCountry','Sales_Region__c'} , null, null, 6);//England promotions take priority. Promotions applicable for 6 people.
            system.assertNotEquals(null, data);
            system.assertEquals(0, data.recommendedPromotions.size());//0 recommended. The only two 'would-be' recommended promotions are either inactive OR outside the minimum required group size
            //system.assertEquals(3, data.remainingPromotions.size());//Only 3 remaining active promotions are within the required min/max guest size. //1.1-
            
            /* 1.1-
            rating = null;
            for(PromotionFinderController.PromotionWrapper promotion : data.remainingPromotions){
                if(rating == null){
                    rating = promotion.priority;//Assign the first priority rating
                }else {
                    system.assertEquals(true, promotion.priority<rating);//Each promotion has a lower rating than the previous rating
                    rating = promotion.priority;
                }
            }*/

            //4. Apply a travel date filter and confirm only promotions relevant to that travel date are returned.
            
            data = PromotionFinderController.searchActivePromotions(new List<String>{'Miami'}, new List<String>{'Name','BillingCountry','Sales_Region__c'}, null, system.today().addDays(6), null);//Miami promotions take priority. Promotions applicable for travelling in 6 days.
            system.assertNotEquals(null, data);
            system.assertEquals(1, data.recommendedPromotions.size());//1 recommended.
            //system.assertEquals(4, data.remainingPromotions.size());//4 active promotions are within the required min/max guest size. //1.1-
            //Confirm display order (Maiami Venue first then highest to lowest)
            system.assertEquals(testVenues[3].Id, data.recommendedPromotions[0].promotion.Venue__c);
            
            /*1.1-
            rating = null;
            for(PromotionFinderController.PromotionWrapper promotion : data.remainingPromotions){
                if(rating == null){
                    rating = promotion.priority;//Assign the first priority rating
                }else {
                    system.assertEquals(true, promotion.priority<rating);//Each promotion has a lower rating than the previous rating
                    rating = promotion.priority;
                }
            }*/

        Test.stopTest();

    }
}