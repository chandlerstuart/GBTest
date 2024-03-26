({
    onInit : function(component, event, helper) {
        helper.doInit(component,event,helper);
    },
    
    handleChangeEvent : function(component,event,helper){
        
        console.log('HandlingChangeEvent');
        var params = event.getParams();
        console.log('params: '+JSON.stringify(params));
        if(params && params.refresh){
            console.log('Re-initialising Component');
            helper.doInit(component,event,helper);
        }
        if(params && params.revisePanelValidation){
            var childPanelCmp = component.find("preferencePanel");
            if(childPanelCmp){
                childPanelCmp.revisePanelValidation();
            }
        }
    }
    
})