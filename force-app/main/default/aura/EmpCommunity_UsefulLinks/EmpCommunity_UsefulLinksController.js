({
	onInit : function(component, event, helper) {
		var getLinks = component.get("c.getUsefulLinkWrappers");
        
        getLinks.setCallback(this, function(response){
            console.log('Links Call = ' + response.state + ' ' + response.getReturnValue());
            if (response.state == 'SUCCESS' && null != response.getReturnValue()){
            	var usefulLinks = response.getReturnValue();
           		console.log('Links List = ' + usefulLinks);
            	component.set("v.usefulLinks", usefulLinks);    
            }else if (response.state == 'SUCCESS' && null == response.getReturnValue()){
                //ERROR STARTS HERE
                var errorMsg = 'There were no Link record found.';
                $A.createComponents([
                    ["ui:message",{
                        "title" : "Error Loading Records",
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
        
        $A.enqueueAction(getLinks);
	}
})