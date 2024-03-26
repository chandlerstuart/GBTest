({
	onInit : function(component, event, helper) {
        var action = component.get("c.getAbsenceList");
        
        action.setCallback(this, function(response){
            console.log('Call = ' + response.state + ' ' + response.getReturnValue());
            if (response.state == 'SUCCESS' && null != response.getReturnValue()){
            	var absenceList = response.getReturnValue();
           		console.log('List = ' + absenceList);
            	component.set("v.absenceList", absenceList);    
            }else if (response.state == 'SUCCESS' && null == response.getReturnValue()){
                //ERROR STARTS HERE
                var errorMsg = 'There were no Absence records found.';
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
        
        $A.enqueueAction(action);
	}
})