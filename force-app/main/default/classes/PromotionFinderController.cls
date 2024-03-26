/*
Name:  PromotionFinderController
======================================================
======================================================
Purpose:
-------
Controller for Promotion Finder lwc. 
This component displays recommended promotions based on enquiry details and recent web insights for the client (last 30 days).
Agents can also search for alternative active promotions by name or destination, adjusting travel dates and group size as needed.
Promotions are sorted first by relevance (either insights or user search criteria) and then priority rating (controlled by product).
Additional promotion details like expiration dates, discount amounts and T&Cs can be seen by hovering over the icon to the right.
======================================================
======================================================


History
------- 
Ver. Author        Date        Detail
1.0  J Radcliffe   2023-10-10  Initial development.
1.1  J Radcliffe   2023-12-18  Remove "Remaining" promotions, leaving only relevant search results.
1.2  J Radcliffe   2023-12-18  Remove the promotion summary. The lwc will now fire an event to a neighbouring component to show promotion details on mouse-over.
1.3  C Stuart      2024-02-08  Modified 'promotionQuery' due to field dependencies API names changes (IsPromotionActive__c & PromotionRating__c)
1.4  C Stuart      2024-02-08  Modified 'PromotionWrapper' to lower recommeneded scale from (>7) down to (>4) Promotions Rating run from 1 - 5
*/
public with sharing class PromotionFinderController {

    public static final String INSIGHTS_TOP_COUNTRIES_30_DAYS = 'TI_TopCountriesLast30Days';
    public static final String INSIGHTS_TOP_VENUES_30_DAYS = 'TI_TopVenuesLast30Days';
    public static final String INSIGHTS_TOP_REGIONS_30_DAYS = 'TI_TopLocationRegionsLast30Days';

    public class PromotionWrapper implements Comparable{
        @AuraEnabled public ProductPromotion__c promotion;
        @AuraEnabled public Integer priority;
        //@AuraEnabled public String promotionDetails;//1.2-
        //@AuraEnabled public Boolean isRecommended = false;//1.1-
        @AuraEnabled public Boolean isProductRecommended = false;

        //Add other status flags that influence the design e.g. isCloseToBookingDeadline

        public PromotionWrapper(ProductPromotion__c promotion){
            this.promotion = promotion;
            this.priority = (promotion.PromotionRating__c != null)?Integer.valueOf(promotion.PromotionRating__c):0; // 1.3~ (Modified API Names of conditional statement (Rating__c to PromotionRating__c))
            //this.promotionDetails = constructPromotionDetails(promotion);//1.2-
            this.isProductRecommended = (promotion.PromotionRating__c>4)?true:false; // 1.3~ (Modified API Names of conditional statement (Rating__c to PromotionRating__c))
                                                                                     // 1.4~ (Reduced Recommnended Promotion value scale from '7' down to '4')
        }

        //Implement comparable - sort by priority
        public Integer compareTo(Object compareTo) {
            PromotionWrapper compareToPromo = (PromotionWrapper)compareTo;
            if (priority == compareToPromo.priority) return 1;
            if (priority > compareToPromo.priority) return 0;
            return -1;        
        }
    }

    public class PromotionData{
        @AuraEnabled public List<PromotionWrapper> recommendedPromotions;
        //@AuraEnabled public List<PromotionWrapper> remainingPromotions;//1.1-

        public PromotionData(List<PromotionWrapper> recommended /*, List<PromotionWrapper> remaining*/){//1.1~
            //for(PromotionWrapper promo : recommended){promo.isRecommended = true;}//1.1-
            recommendedPromotions = recommended;
            //remainingPromotions = remaining;//1.1-
        }
    }

    public class ComponentData{
        @AuraEnabled public Opportunity opportunity;
        @AuraEnabled public List<Golfbreaks__MetricSet__c> insights;
    }

    @AuraEnabled
    public static ComponentData loadData(String recordId){
        ComponentData data = new ComponentData();
        data.opportunity = [Select Id, TravelGroupSize__c, PreferredTravelDate__c, CountriesInterested__c, Venue__c, AccountId From Opportunity Where Id = :recordId];
        data.insights = [Select Id, Name, golfbreaks__TopMetricName__c, golfbreaks__SecondMetricName__c, golfbreaks__ThirdMetricName__c, golfbreaks__FourthMetricName__c, golfbreaks__FifthMetricName__c From Golfbreaks__MetricSet__c Where Golfbreaks__Account__c = :data.opportunity.AccountId and (Name =:INSIGHTS_TOP_COUNTRIES_30_DAYS or Name = :INSIGHTS_TOP_VENUES_30_DAYS or Name = :INSIGHTS_TOP_REGIONS_30_DAYS) and LastModifiedDate = LAST_N_DAYS:30];   
        return data;   
    }

    @AuraEnabled
    public static PromotionData searchActivePromotions(List<String> searchTerms, List<String> searchFields, Date bookingDate, Date travelDate, Integer groupSize){

        try{

            if(bookingDate == null) bookingDate = System.today();
            //if(searchFields == null || searchFields.size()==0) searchFields = new List<String>{'Name','Sales_Region__c','BillingCountry','BillingCity','Tour_Region__c','Billing_State_County__c'};
            
            Map<Id,Account> venueAccountsMap = new Map<Id,Account>();
            Map<Id, PromotionWrapper> recommendedPromotionsMap = new Map<Id, PromotionWrapper>();
            //Map<Id, PromotionWrapper> remainingPromotionsMap = new Map<Id, PromotionWrapper>();

            //Design note - Picklists are not search indexed, meaning SOQL must be used (with LIKE %) instead of SOSL.
            //https://ideas.salesforce.com/s/idea/a0B8W00000Gdk6OUAR/allow-date-datetime-and-picklist-fields-to-be-indexed
            
            if (searchTerms != null && searchTerms.size() > 0 && !String.isBlank(searchTerms[0])) {
                // Query accounts first
                String venueRT = ApplicationConstant.RECORD_TYPE_ACCOUNT_VENUE;
                String accountQuery = 'SELECT Id, Name FROM Account WHERE RecordType.DeveloperName = :venueRT ';
                accountQuery += ' AND (';
                Integer innerCounter;
                Integer outerCounter = 1;
                for (String searchTerm : searchTerms) {
                    if(outerCounter>1) accountQuery += ' OR ';
                    outerCounter++;
                    innerCounter = 1;
                    for (String searchField : searchFields) {
                        if (innerCounter > 1) {
                            accountQuery += ' OR ';
                        }
                        accountQuery += ' ' + searchField + ' LIKE \'%' + searchTerm.trim() + '%\'';
                        innerCounter++;
                    }
                }
                accountQuery += ')';

                system.debug('Account Query > '+accountQuery);
                for(Account venue : Database.query(accountQuery)){
                    venueAccountsMap.put(venue.Id,venue);
                }
            }

            String promotionQuery = 'SELECT Id, Name, PromotionDetails__c, PromotionAmount__c, TermsConditions__c, Venue__r.Name, BookingWindowEndDate__c, PromotionRating__c, TravelEndDate__c FROM ProductPromotion__c '+'WHERE IsPromotionActive__c = true'; // 1.3~ (Modified API Names of defined query (Rating__c to PromotionRating__c) && (IsActive__c to IsPromotionActive__c))
            if (bookingDate != null) {
                promotionQuery += ' AND (BookingWindowStartDate__c = null OR BookingWindowStartDate__c <= :bookingDate) AND (BookingWindowEndDate__c = null OR BookingWindowEndDate__c > :bookingDate)';
            }
            if (travelDate != null) {
                promotionQuery += ' AND (TravelStartDate__c = null OR TravelStartDate__c <= :travelDate) AND (TravelEndDate__c = null OR TravelEndDate__c > :travelDate)';
            }
            if (groupSize != null && groupSize > 0) {
                promotionQuery += ' AND (MinimumNumberOfGuests__c = null OR MinimumNumberOfGuests__c <= :groupSize) AND (MaximumNumberOfGuests__c = null OR MaximumNumberOfGuests__c >= :groupSize)';
            }
            promotionQuery = promotionQuery+' Order by PromotionRating__c DESC nulls last Limit 50 ';//Limit 50. If this number needs to increase, consider introducing pagination. // 1.3~ (Modified API Names of defined query (Rating__c to PromotionRating__c))

            for (ProductPromotion__c promo : Database.query(promotionQuery)) {
                if((promo.Venue__c != null && venueAccountsMap != null && venueAccountsMap.containsKey(promo.Venue__c)) || isSearchedByName(promo, searchTerms)){
                    recommendedPromotionsMap.put(promo.Id, new PromotionWrapper(promo));
                }else{
                    continue;//1.1+
                    //remainingPromotionsMap.put(promo.Id, new PromotionWrapper(promo));//1.1-
                }
            }
            
            //Sort the lists in priority order
            List<PromotionWrapper> recommendedPromotions = new List<PromotionWrapper>(recommendedPromotionsMap.values());
            recommendedPromotions.sort();
            //List<PromotionWrapper> remainingPromotions = new List<PromotionWrapper>(remainingPromotionsMap.values());//1.1-
            //remainingPromotions.sort();//1.1-

            //return new PromotionData(recommendedPromotions, remainingPromotions);//1.1-
            return new PromotionData(recommendedPromotions);//1.1+

        }catch(Exception e){
            Golfbreaks.PlatformLogManager.logExceptions(e,'PromotionFinderController','searchActivePromotions');
            system.debug('Failure > '+e.getMessage()+' - '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage()+'-'+e.getStackTraceString());
        }

    }

    /*1.2-
    public static String constructPromotionDetails(ProductPromotion__c promotion){
        if(promotion == null) return null;
        Map<String,Object> nameValueMap = new Map<String,Object>();
        
        if(promotion.PromotionDetails__c != null) nameValueMap.put('Details',promotion.PromotionDetails__c);
        if(promotion.TermsConditions__c != null) nameValueMap.put('T&C\'s',promotion.TermsConditions__c);
        if(promotion.PromotionAmount__c != null) nameValueMap.put('Amount',promotion.PromotionAmount__c+'%');
        if(promotion.BookingWindowEndDate__c != null) nameValueMap.put('Book Before',formatDateValue(promotion.BookingWindowEndDate__c));
        if(promotion.TravelEndDate__c != null) nameValueMap.put('Travel Before',formatDateValue(promotion.TravelEndDate__c));

        String promoDetails = '';
        if(nameValueMap.values().size()>0){
            promoDetails = '<table class="slds-table" style="width:100%;border-radius:5px 5px 5px 5px;">';
            for(String name : nameValueMap.keySet()){
                promoDetails = promoDetails+'<tr>';
                promoDetails = promoDetails+'<td><b>'+name+':</b></td><td>'+nameValueMap.get(name)+'</td>';
                promoDetails = promoDetails+'</tr>';
            }
            promoDetails = promoDetails+'</table>';
        }

        return promoDetails;
    }*/

    public static boolean isSearchedByName(ProductPromotion__c promotion, List<String> searchTerms){
        if(searchTerms == null || searchTerms.size() == 0) return false;

        for(String searchTerm : searchTerms){
            if(String.isBlank(searchTerm)) continue;
            if(promotion.Name.containsIgnoreCase(searchTerm)) return true;
        }
        return false;
    }

    //1.2-
    /*public static String formatDateValue(Date fieldValue){
        return DateTime.newInstance(fieldValue.year(),fieldValue.month(),fieldValue.day(),0,0,0).format('EEE d MMM yyyy');
    }*/

}