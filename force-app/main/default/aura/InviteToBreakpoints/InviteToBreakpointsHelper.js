({
    inviteToBreakpoints : function(component,event,helper) {
        
        component.set("v.showSpinner", true);
        
        var action = component.get("c.sendInvite");
        action.setParams({
            "fieldName" : component.get("v.fieldName"),
            "sObjectType" : component.get("v.sObjectType"),
            "recordId" : component.get("v.recordId")
        })
        action.setCallback(this,function(response){
            var state = response.getState();
            console.log('Marketing Preferences Call State: '+state);
            if( state ==='SUCCESS'){
                var data = response.getReturnValue();
                if(data){
                    // Fire success toast
                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "message":"The client was successfully invited to Breakpoints",
                        "type" : "success",
                        "title" :"Success!"
                    });
                    toastEvent.fire();
                    component.set("v.showSpinner", false);
                    component.set("v.showButton", false);
                }else{
                    // Fire error toast
                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "message":"Error Inviting the Client to Breakpoints. Please contact the Salesforce Team if you require assistance",
                        "type" : "error",
                        "title" :"There was an error"
                    });
                    toastEvent.fire();
                    component.set("v.showSpinner", false);
                }
            }else if( state=== 'ERROR'){
                // Fire error toast
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "message":"Error Inviting the Client to Breakpoints: "+response.getError()[0].message,
                    "type" : "error",
                    "title" :"There was an error"
                });
                toastEvent.fire();
                component.set("v.showSpinner", false);
            }
        });
        
        $A.enqueueAction(action);
        
    },
    
})