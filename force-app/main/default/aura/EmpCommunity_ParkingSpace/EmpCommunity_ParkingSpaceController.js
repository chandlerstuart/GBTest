({
    doInit : function(component, event, helper){
    	var getUserAction = component.get("c.getUser");
        getUserAction.setCallback(this, function(response){
        	if (response.state == 'SUCCESS' && null != response.getReturnValue()){
            	var currentUser = response.getReturnValue();
            	component.set("v.currentUser", currentUser); 
            }
        });
        
        $A.enqueueAction(getUserAction);
    },
    
    assignSpace : function(component, event, helper) {
        var getUsers = component.get("c.getUsersForAssignment");
        
        getUsers.setCallback(this, function(response){
            if (response.state == 'SUCCESS' && null != response.getReturnValue()){
            	var userList = response.getReturnValue();
            	component.set("v.userList", userList); 
                
            }else {
                //ERROR STARTS HERE
                var errorMsg = 'Error loading records.';
                $A.createComponents([
                    ["ui:message",{
                        "title" : "Error",
                        "severity" : "error",
                    }],
                    ["ui:outputText",{
                        "value" : errorMsg
                    }]
                ],
					function(components, status){
                        if (status === "SUCCESS") {
                            var message = components[0];
                            var outputText = components[1];
                            // set the body of the ui:message to be the ui:outputText
                            message.set("v.body", outputText);
                            var errorDiv = component.find("errorDiv");
                            // Replace div body with the dynamic component
                            errorDiv.set("v.body", message);
                        }
					}
				);
                //ERROR ENDS HERE
            } 
        });
        
        $A.enqueueAction(getUsers);
        
        var space = component.get("v.space");
		var pop = document.getElementById("popout" + space.spaceNumber);
        var popBackground = document.getElementById("popoutBackground");
        
        $A.util.removeClass(popBackground, "slds-hide");
        $A.util.removeClass(pop, "slds-hide");
        
        //var popoutForm = component.find("popoutForm"+component.get("v.space.spaceNumber"));
        //popoutForm.set("v.space", component.get("v.space"));
        
	},
    
    cancelAssign : function(component, event, helper){
        var pop = document.getElementById("popout");
        var popBackground = document.getElementById("popoutBackground");
        
        $A.util.addClass(popBackground, "slds-hide");
        $A.util.addClass(pop, "slds-hide");
    },
})