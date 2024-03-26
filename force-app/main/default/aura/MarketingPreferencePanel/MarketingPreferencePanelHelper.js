({
    //This method overrides the green and red styling in instances where the client is subscribed but information is missing
    addOrRemoveAlerts : function(component,event,helper){
        
        var account = component.get("v.account");
        var individual = component.get("v.individual");
                
        //Brochure
        if(!account.PersonMailingStreet && !account.PersonMailingPostalCode && individual.Brochure__c){
            var brochureIcon = component.find('home-icon');
            console.log('Adding alert to Brochure Icon: '+brochureIcon);
            try{
                $A.util.addClass(brochureIcon, 'alert');
            }catch(exception){
                console.log("error applying alert class: "+exception);
            }
        }else{
            var brochureIcon = component.find('home-icon');
            $A.util.removeClass(brochureIcon, 'alert');
        }

        //Weekly and Seasonal Newsletters 
        let weeklyNLIcon = component.find('weekly-icon');
        let seasonalNLIcon = component.find('seasonal-icon');
        let eventsNLIcon = component.find('events-icon');
        let tournamentsNLIcon = component.find('tournaments-icon');
        if(account.EmailUndeliverable__c && !account.EmailUndeliverableOverride__c){
            if(individual.Quarterly_Newsletter__c){
                console.log('Adding alert to Seasonal Newsletter Icon: '+seasonalNLIcon);
                $A.util.addClass(seasonalNLIcon, 'alert');
            }else{
                $A.util.removeClass(seasonalNLIcon, 'alert');
            }
            if(individual.Weekly_Newsletter__c){
                console.log('Adding alert to Weekly Newsletter Icon: '+weeklyNLIcon);
                $A.util.addClass(weeklyNLIcon, 'alert');
            }else{
                $A.util.removeClass(weeklyNLIcon, 'alert');
            }       
            if(individual.TournamentsNewsletter__c){
                console.log('Adding alert to Tournaments Newsletter Icon: '+tournamentsNLIcon);
                $A.util.addClass(tournamentsNLIcon, 'alert');
            }else{
                $A.util.removeClass(tournamentsNLIcon, 'alert');
            } 
            if(individual.EventsNewsletter__c){
                console.log('Adding alert to Events Newsletter Icon: '+eventsNLIcon);
                $A.util.addClass(eventsNLIcon, 'alert');
            }else{
                $A.util.removeClass(eventsNLIcon, 'alert');
            }      
        }else{
            $A.util.removeClass(weeklyNLIcon, 'alert');
            $A.util.removeClass(seasonalNLIcon, 'alert');
            $A.util.removeClass(eventsNLIcon, 'alert');
            $A.util.removeClass(tournamentsNLIcon, 'alert');
        }
        
    },

    isSubscribedToEmail : function(component,event,helper,ind){
        if(ind.Quarterly_Newsletter__c == true 
            || ind.Weekly_Newsletter__c == true
            || ind.EventsNewsletter__c == true
            || ind.TournamentsNewsletter__c == true
            || ind.PGATour__c == true){
            return true;
        }else{
            return false;
        }
    },
})