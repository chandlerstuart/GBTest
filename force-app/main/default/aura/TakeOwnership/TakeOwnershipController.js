({ 
    recordLoaded: function(component, event, helper) {
        var record = component.get("v.record");
        if(record.OwnerId == $A.get('$SObjectType').CurrentUser.Id){
            component.set("v.alreadyOwned",true);
        } 
    },
    
    takeOwnership: function(component, event, helper) {
        component.set("v.buttonClicked",true);
        helper.takeOwnership(component, event, helper);
    }
    
})