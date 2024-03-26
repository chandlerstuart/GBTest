({
	initMethod : function(component, event, helper) {
		
        var getUserDetails = component.get("c.getUser");
		
        getUserDetails.setCallback(this, function(response){
            if (response.state == 'SUCCESS' && null != response.getReturnValue()){
            	var userRecord = response.getReturnValue();
            	component.set("v.userRecord", userRecord);                 
            } //else starts here
        });
		
        $A.enqueueAction(getUserDetails);
            
        var action = component.get("c.getSpaces");
        
        action.setCallback(this, function(response){
            	//REMOVE SPINNER
                var x = document.getElementById("spinner");
                $A.util.addClass(x, "slds-hide");
            if (response.state == 'SUCCESS' && null != response.getReturnValue()){
            	var parkingList = response.getReturnValue();
                console.log('FOUND ' + parkingList.length + ' spaces');
            	component.set("v.parkingSpaces", parkingList); 
                
                for (var i = 0 ; i < parkingList.length ; i++){
                	var space = parkingList[i];
                    var spaceComponent = component.find("ps" + space.spaceNumber);
                    if (null != spaceComponent){
                        spaceComponent.set("v.space", space);
                    } 
                }

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
        
        $A.enqueueAction(action);
	}
})