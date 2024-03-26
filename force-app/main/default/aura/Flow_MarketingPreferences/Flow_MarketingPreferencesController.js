({
    togglePreference : function(component, event, helper) {
        var preference = event.currentTarget.id;
        var attribute = "v."+preference;
        var currentState = component.get(attribute);
        component.set(attribute,!currentState);
    },
    
    onInit :function(component,event,helper){
        helper.addPadding(component,event,helper);
    }
})