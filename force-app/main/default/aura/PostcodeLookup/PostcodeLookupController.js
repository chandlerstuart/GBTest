({
    startSearch : function(component,event,helper){
        component.set("v.selectedResultId",null);
        helper.startSearch(component,event,helper);
    },
    
    showModal : function(component,event,helper){
        component.set("v.showModal", true);
    },
    
    hideModal : function(component,event,helper){
        component.set("v.showModal", false);
    },
    
    handleSelection : function(component,event,helper){
        console.log('Handling Selection')
        var params = event.getParams();
        console.log('params: '+JSON.stringify(params));
        if(params && params.id && params.type && params.type != 'Address'){
            component.set("v.selectedResultId",params.id);
            helper.startSearch(component,event,helper);
        }else if(params && params.id && params.type && params.type == 'Address'){
            component.set("v.selectedResultId",params.id);
            helper.retrieveAddress(component,event,helper);
        }        
    },
    
    toggleView : function(component,event,helper){
        var isEdit = component.get("v.editMode");
        component.set("v.editMode",!isEdit);
        //Refresh preference panel (colours)
        var event = component.getEvent("changeEvent");
        event.setParams({
            "revisePanelValidation" : true
        })
        event.fire();
    },
    
    clearAddress : function(component,event,helper){
        var account = component.get("v.account");
        account.PersonMailingStreet = '';
        account.PersonMailingCity = '';
        account.Mailing_State_County__pc = '';
        account.PersonMailingCountry = '';
        account.PersonMailingPostalCode = '';
        component.set("v.account",account);
    }
})