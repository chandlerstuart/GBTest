import { LightningElement, track, api, wire } from 'lwc';
import loadData from '@salesforce/apex/PromotionFinderController.loadData';
import searchActivePromotions from '@salesforce/apex/PromotionFinderController.searchActivePromotions';
import { publish, MessageContext } from "lightning/messageService";
import dynamicRecordForm from "@salesforce/messageChannel/dynamicRecordForm__c";

/*
History
------- 
Ver. Author        Date        Detail
1.1  J Radcliffe   2023-12-18  Remove "Remaining" promotions, leaving only relevant search results.
*/

export default class PromotionFinder extends LightningElement {

    @wire(MessageContext)
    messageContext;

    @api recordId; 

    @track searchTermArray = [];
    @track searchTerm = '';
    @track travelDate;
    @track groupSize;
 
    @track venues = [];
    @track countries = [];
    @track regions = [];

    @track promotions = [];
    @track noPromos;
    @track showSpinner = false;
    @track errorMessage;
    @track showError = false;
    @track isRecommendedTitle = '';

    connectedCallback() {
        this.loadComponent();
    }

    loadComponent(){
        this.showSpinner = true;
        loadData({
            recordId: this.recordId
        })
        .then(result => {
            console.log('Promotions Component Data > ',result);
            try{
                //Identify priority venue and country destinations based on opportunity attributes.
                if(result.opportunity != null){
                    this.groupSize = result.opportunity.TravelGroupSize__c;
                    this.travelDate = result.opportunity.PreferredTravelDate__c;
        
                    if(result.opportunity.Venue__c != null && result.opportunity.Venue__c.length >0){
                        this.venues = this.removeStarRating(result.opportunity.Venue__c);
                    }
        
                    if(result.opportunity.CountriesInterested__c != null && result.opportunity.CountriesInterested__c.length>0){
                        if(result.opportunity.CountriesInterested__c.includes(';')){
                            this.countries = result.opportunity.CountriesInterested__c.split(';');
                        }else{
                            this.countries.push(result.opportunity.CountriesInterested__c);
                        }
                    }
                }
                
                //Identify priority venue and country destinations based on insights data.
                if(result.insights != null && result.insights.length>0){
                    for(let i=0;i<result.insights.length;i++){
                        if(result.insights[i].Name.includes('TopCountries')){
                            if(result.insights[i].golfbreaks__TopMetricName__c != null && result.insights[i].golfbreaks__TopMetricName__c != '' && !this.countries.includes(result.insights[i].golfbreaks__TopMetricName__c)) this.countries.push(result.insights[i].golfbreaks__TopMetricName__c);
                            if(result.insights[i].golfbreaks__SecondMetricName__c != null && result.insights[i].golfbreaks__SecondMetricName__c != '' && !this.countries.includes(result.insights[i].golfbreaks__SecondMetricName__c)) this.countries.push(result.insights[i].golfbreaks__SecondMetricName__c);
                            if(result.insights[i].golfbreaks__ThirdMetricName__c != null && result.insights[i].golfbreaks__ThirdMetricName__c != '' && !this.countries.includes(result.insights[i].golfbreaks__ThirdMetricName__c)) this.countries.push(result.insights[i].golfbreaks__ThirdMetricName__c);
                            if(result.insights[i].golfbreaks__FourthMetricName__c != null && result.insights[i].golfbreaks__FourthMetricName__c != '' && !this.countries.includes(result.insights[i].golfbreaks__FourthMetricName__c)) this.countries.push(result.insights[i].golfbreaks__FourthMetricName__c);
                            if(result.insights[i].golfbreaks__FifthMetricName__c != null && result.insights[i].golfbreaks__FifthMetricName__c != '' && !this.countries.includes(result.insights[i].golfbreaks__FifthMetricName__c)) this.countries.push(result.insights[i].golfbreaks__FifthMetricName__c);
                        }else if(result.insights[i].Name.includes('TopVenues')){
                            if(result.insights[i].golfbreaks__TopMetricName__c != null && result.insights[i].golfbreaks__TopMetricName__c != '' && !this.venues.includes(result.insights[i].golfbreaks__TopMetricName__c)) this.venues.push(result.insights[i].golfbreaks__TopMetricName__c);
                            if(result.insights[i].golfbreaks__SecondMetricName__c != null && result.insights[i].golfbreaks__SecondMetricName__c != '' && !this.venues.includes(result.insights[i].golfbreaks__SecondMetricName__c)) this.venues.push(result.insights[i].golfbreaks__SecondMetricName__c);
                            if(result.insights[i].golfbreaks__ThirdMetricName__c != null && result.insights[i].golfbreaks__ThirdMetricName__c != '' && !this.venues.includes(result.insights[i].golfbreaks__ThirdMetricName__c)) this.venues.push(result.insights[i].golfbreaks__ThirdMetricName__c);
                            if(result.insights[i].golfbreaks__FourthMetricName__c != null && result.insights[i].golfbreaks__FourthMetricName__c != '' && !this.venues.includes(result.insights[i].golfbreaks__FourthMetricName__c)) this.venues.push(result.insights[i].golfbreaks__FourthMetricName__c);
                            if(result.insights[i].golfbreaks__FifthMetricName__c != null && result.insights[i].golfbreaks__FifthMetricName__c != '' && !this.venues.includes(result.insights[i].golfbreaks__FifthMetricName__c)) this.venues.push(result.insights[i].golfbreaks__FifthMetricName__c);
                        }else if(result.insights[i].Name.includes('TopLocationRegions')){
                            if(result.insights[i].golfbreaks__TopMetricName__c != null && result.insights[i].golfbreaks__TopMetricName__c != '' && !this.regions.includes(result.insights[i].golfbreaks__TopMetricName__c)) this.regions.push(result.insights[i].golfbreaks__TopMetricName__c);
                            if(result.insights[i].golfbreaks__SecondMetricName__c != null && result.insights[i].golfbreaks__SecondMetricName__c != '' && !this.regions.includes(result.insights[i].golfbreaks__SecondMetricName__c)) this.regions.push(result.insights[i].golfbreaks__SecondMetricName__c);
                            if(result.insights[i].golfbreaks__ThirdMetricName__c != null && result.insights[i].golfbreaks__ThirdMetricName__c != '' && !this.regions.includes(result.insights[i].golfbreaks__ThirdMetricName__c)) this.regions.push(result.insights[i].golfbreaks__ThirdMetricName__c);
                            if(result.insights[i].golfbreaks__FourthMetricName__c != null && result.insights[i].golfbreaks__FourthMetricName__c != '' && !this.regions.includes(result.insights[i].golfbreaks__FourthMetricName__c)) this.regions.push(result.insights[i].golfbreaks__FourthMetricName__c);
                            if(result.insights[i].golfbreaks__FifthMetricName__c != null && result.insights[i].golfbreaks__FifthMetricName__c != '' && !this.regions.includes(result.insights[i].golfbreaks__FifthMetricName__c)) this.regions.push(result.insights[i].golfbreaks__FifthMetricName__c);                            
                        }
                    }
                }

                this.getActivePromotions(false);

            }catch(error){
                console.error('Error loading opportunity: '+JSON.stringify(error.message));
            }
        })
        .catch(error => {
            this.showSpinner = false;
            this.errorMessage = 'Error loading opportunity. Please check the console log for further details.';
            this.showError = true;
            console.error('Error loading opportunity: ' + JSON.stringify(error));
        });
    }

    refresh(){
        this.searchTermArray = [];
        this.promotions = [];
        this.countries = [];
        this.venues = [];
        this.groupSize = null;
        this.travelDate = null;
        this.loadComponent();
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
    }

    handleTravelDateChange(event) {
        this.travelDate = event.target.value;
        this.getActivePromotions();
    }

    handleGroupSizeChange(event) {
        this.groupSize = event.target.value;
        this.getActivePromotions();
    }

    handleEnter(event){
        if (event.keyCode === 13) {
            this.getActivePromotions(this.searchTerm.trim() !== '');
        }
    }

    getActivePromotions(isUserSearch) {
        console.log('isUserSearch: '+isUserSearch);

        this.showSpinner = true;
        this.noPromos = false;

        let searchTermList = [];
        let searchFields = [];

        //console.log(JSON.stringify(this.venues));
        if(isUserSearch == true){
            //Push new search term to existing list
            this.isRecommendedTitle = 'Recommended based on your search criteria.';
            searchTermList.push(this.searchTerm);
            //Search for search term in all relevant fields. Search fields control the scope of the query.
            searchFields = ['Name','Sales_Region__c','BillingCountry','BillingCity','Tour_Region__c','Billing_State_County__c'];
        }else{
            this.isRecommendedTitle = 'Recommended based on opportunity details and recent web activity.';
            if(this.venues != null && this.venues.length>0){
                for(let i=0;i<this.venues.length;i++){
                    searchTermList.push(this.venues[i]);
                }
            }
            if(this.countries != null && this.countries.length>0){
                for(let i=0;i<this.countries.length;i++){
                    searchTermList.push(this.countries[i]);
                }
            }
            if(this.regions != null && this.regions.length>0){
                for(let i=0;i<this.regions.length;i++){
                    searchTermList.push(this.regions[i]);
                }
            }
            //Search venue (name), country and region fields. Search fields control the scope of the query.
            searchFields = ['Name','Sales_Region__c','BillingCountry','Tour_Region__c'];
        }
        
        console.log('Search terms: '+searchTermList);

        let travelDate = (this.travelDate != null && this.travelDate != '')? this.travelDate:null;
        let groupSize = (this.groupSize != null && this.groupSize != '')? this.groupSize:null;

        this.promotions = [];

        searchActivePromotions({
            searchTerms: searchTermList,
            searchFields: searchFields,
            travelDate: travelDate,
            groupSize: groupSize
        })
            .then(result => {

                console.log('result > ',result);
                //this.promotions = result.recommendedPromotions.concat(result.remainingPromotions);//1.1-
                this.promotions = result.recommendedPromotions;//1.1+
                if(this.promotions == null || this.promotions.length==0) this.noPromos = true;
                this.showSpinner = false;
            })
            .catch(error => {
                this.showSpinner = false;
                this.errorMessage = 'Error fetching promotions. Please check the console log for further details.';
                this.showError = true;
                console.error('Error fetching promotions: ' + JSON.stringify(error));
            });
    }

    removeStarRating(venueString) {
        if(venueString == null || venueString == '') return null;

        // Split the input string into an array of venues
        let venuesArray = [];
        if(venueString.includes(',')){
            venuesArray = venueString.split(',');
        }else{
            venuesArray.push(venueString);
        }
      
        // Iterate through each venue and remove the star rating
        let cleanVenuesArray = venuesArray.map(venue => {
          // Use a regular expression to remove the star rating
          let cleanVenue = venue.replace(/\s\d\*$/, '').trim(); // Removes the star rating and preceding space
          return cleanVenue;
        });
       
        return cleanVenuesArray;
    } 

    fireFocusedPromoEvent(event){
        let promotionId = event.currentTarget.dataset.id;
            this.fireAppEvent(promotionId);
        }

    fireUnfocusedPromoEvent(event){
        this.fireAppEvent(null);
    }
        

    fireAppEvent(promotionId){
        let payload = {
            recordId : promotionId,
            title : 'Promotion Details',
            objectApiName : 'ProductPromotion__c'
        }
        publish(this.messageContext, dynamicRecordForm, payload);
    }
}