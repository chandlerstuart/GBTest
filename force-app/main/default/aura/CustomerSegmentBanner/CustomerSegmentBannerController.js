({
	handleRecordUpdated : function(component, event, helper) {
		var account = component.get("v.accountRecord");
        console.log('account:'+JSON.stringify(account));
        if(account){
            if(account.TotalBookingsCount__c > 0){
                var bannerText = component.get("v.booker");
                if(account.TotalBookingsCount__c>1){
                    bannerText = bannerText+': '+account.TotalBookingsCount__c+' Bookings';
                }else{
                    bannerText = bannerText+': '+account.TotalBookingsCount__c+' Booking';
                }             
                var bannerColour = 'background-color:'+component.get("v.bookerColour");
                component.set("v.bannerText",bannerText);
                component.set("v.bannerColour",bannerColour);
            }else if(account.TotalOpportunitiesCount__c > 0){
                var bannerText = component.get("v.enquirer");
                if(account.TotalOpportunitiesCount__c > 1){
                    bannerText = bannerText+': '+account.TotalOpportunitiesCount__c+' Enquiries';
                }else{
                    bannerText = bannerText+': '+account.TotalOpportunitiesCount__c+' Enquiry';
                }             
                var bannerColour = 'background-color:'+component.get("v.enquirerColour");
                component.set("v.bannerText",bannerText);
                component.set("v.bannerColour",bannerColour);
            }else{
                var bannerText = component.get("v.new");
                var bannerColour = 'background-color:'+component.get("v.newColour");
                component.set("v.bannerText",bannerText);
                component.set("v.bannerColour",bannerColour);
            }
        }
	}
})