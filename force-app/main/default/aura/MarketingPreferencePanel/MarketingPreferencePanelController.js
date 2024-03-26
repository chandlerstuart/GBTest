({
    onInit : function(component,event,helper){
        helper.addOrRemoveAlerts(component,event,helper);
    },

    addOrRemoveAlerts : function(component,event,helper){
      helper.addOrRemoveAlerts(component,event,helper);  
    },
    
    handlePreferenceSelection : function(component, event, helper) {
        component.set("v.savePromptRequired", true);
        
        //Expand section to reveal contact details component
        var isExpanded = component.get("v.isExpanded");
        if(!isExpanded){
            component.set("v.isExpanded",true);
        }
        
        //Toggle Preference
        var ind = component.get("v.individual");
        if(!ind){
            console.log('No individual preferences found');
            return;
        }
        var preference = event.currentTarget.id;
        console.log('event.currentTarget.id:'+event.currentTarget.id);
        if(preference){
            if(preference=='phone'){
                ind.Phone__c = !ind.Phone__c;
            }else if(preference=='weekly'){
                ind.Weekly_Newsletter__c = !ind.Weekly_Newsletter__c;
            }else if(preference=='seasonal'){
                ind.Quarterly_Newsletter__c = !ind.Quarterly_Newsletter__c;
            }else if(preference=='brochure'){
                ind.Brochure__c = !ind.Brochure__c;
            }else if(preference=='sms'){
                ind.SMS__c = !ind.SMS__c;
            }else if(preference=='events'){
                ind.EventsNewsletter__c = !ind.EventsNewsletter__c;
            }else if(preference=='tournaments'){
                ind.TournamentsNewsletter__c = !ind.TournamentsNewsletter__c;
            }
        }
        ind.Email__c = helper.isSubscribedToEmail(component,event,helper,ind);
        component.set("v.individual",ind);
        helper.addOrRemoveAlerts(component,event,helper);
        
    },

    expandOrCollapse : function(component, event, helper) {
        //Toggle the isExpanded setting
        var isExpanded = component.get("v.isExpanded");
        if(isExpanded && component.get("v.savePromptRequired")){
            //Prompt users to save their changes when they make changes and collapse the panel (without saving)
            // Fire error toast
            let toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "message":"Remember to save your changes",
                "type" : "warning",
                "title" :"Don't forget!"
            });
            toastEvent.fire();
            component.set("v.savePromptRequired",false);
        }
        component.set("v.isExpanded",!isExpanded);
    },
    

})