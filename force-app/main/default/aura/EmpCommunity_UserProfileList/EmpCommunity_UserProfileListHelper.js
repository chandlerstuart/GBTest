({
    getAllPages : function(component, event){
    	var getPages = component.get("c.getAllPages");
        
        getPages.setCallback(this, function(response){
            //Hide spinner
            var x = document.getElementById("spinner");
	        $A.util.addClass(x, "slds-hide");
            
            if (response.state == 'SUCCESS' && null != response.getReturnValue()){
                var returnMap = response.getReturnValue();
                component.set("v.allPages",returnMap);
                component.set("v.nextToken","1");
                component.set("v.prevToken","0");
                var userList = returnMap[0];
                component.set("v.uList",userList);
            }else {
                helper.processError(component, event, response);
            }
        });
        
        $A.enqueueAction(getPages);  
    },
    
    processError : function(component, event, serverResponse){
    	if (serverResponse.state == 'SUCCESS' && null == serverResponse.getReturnValue()){
            //ERROR STARTS HERE
            var errorMsg = 'There were no User records found.';
            $A.createComponents([
                ["ui:message",{
                    "title" : "No Records Found",
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
    }
})