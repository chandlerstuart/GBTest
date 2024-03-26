({
	getAlertMsg : function(cmp, hlp) {
        var action= cmp.get("c.getStatusAlertMsg");
        var recId = cmp.get("v.recordId");
        console.log('recId = ' + recId);

        action.setParams({
            'recId' : recId
        });
        
        action.setCallback(this, function(response){
            console.log(response);
            if (response.state == 'SUCCESS' && null != response.getReturnValue()){
                var retList = response.getReturnValue();
                console.log(retList);
                
            	$A.createComponents([
                ["ui:message",{
                    "title" : "Change Request Status",
                    "severity" : retList[0],
                }],
                ["ui:outputText",{
                    "value" : retList[1]
                }]
                ],
                function(components, status, errorMessage){
                    if (status === "SUCCESS") {
                        var message = components[0];
                        var outputText = components[1];
                        // set the body of the ui:message to be the ui:outputText
                        message.set("v.body", outputText);
                        var alertMsg = cmp.find("alertMsg");
                        // Replace div body with the dynamic component
                        alertMsg.set("v.body", message);
                    }
                }
            );    
            }            
            //
        });
        
        $A.enqueueAction(action);
	},
})