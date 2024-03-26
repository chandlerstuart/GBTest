({
	onInit : function(component, event, helper) {
        
	},
    
    sendOpportunityToClubhouse : function(component, event, helper){
        component.set("v.showButton", false);
        var opp = component.get("v.record");
        if(opp){
        	helper.sendOppToClubhouse(component,event,helper,opp);
        }
    },
    
    recordLoaded : function(component,event,helper){
        var opp = component.get("v.record");
        if(opp.GolfbreaksEnquiryId__c) return;
        component.set("v.showButton", true);
    }
})