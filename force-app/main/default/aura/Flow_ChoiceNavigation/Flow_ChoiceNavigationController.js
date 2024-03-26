({
    
    doInit : function(component,event,helper){
        helper.addStyle(component,event,helper);
        helper.loadButtons(component,event,helper);
    }, 
    
    handleChange : function(component, event, helper) {
        // When an option is selected, navigate to the next screen
        var response = event.getSource().getLocalId();
        console.log('source: ',event.getSource().getGlobalId());
        component.set("v.value", response);
        console.log('value: '+response);
        var navigate = component.get("v.navigateFlow");
        navigate("NEXT");
    }
})