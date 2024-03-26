({
	onInit : function(component, event, helper) {
		var loadRec = component.get("c.getOpportunityById");
        var currentUrl = window.location.href;
        var oppIdFromURL = component.get("v.vfOppId");

        if(oppIdFromURL){
			
            loadRec.setParams({
                oppId : oppIdFromURL
            });
            loadRec.setCallback(this, function(response){
                console.log('Call = ' + response.state + ' ' + response.getReturnValue());
                if(response.state == 'SUCCESS' && null != response.getReturnValue()) {
                    var oppRecord = response.getReturnValue();
                    component.set("v.oppRecord", oppRecord);
                    component.set("v.quotes", oppRecord.qwList);
                    console.log(oppRecord.qwList);
                    //console.log(response.getReturnValue());
                }else if (response.state == 'SUCCESS' && null == response.getReturnValue()){
                    //ERROR STARTS HERE
                    var errorMsg = 'There was an error loading your records.';
                    errorMsg += '\n' + 'Please go back to the Opportunity page and try again.';
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
                } else {
                    //ERROR STARTS HERE
                    var errorMsg = 'Something has gone wrong.';
                    errorMsg += '\n' + 'Please contact IT Support.';
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
            
            $A.enqueueAction(loadRec);  
            
            //if (wasSuccess){
                //Also get the Quote list
                var quoteAction = component.get("c.getQuoteWrapperList");
                quoteAction.getCallback(this, function(response){
                    if (response.state == 'SUCCESS'){
                        console.log(response.getReturnValue());
                        component.set("v.quotes", response.getReturnValue());
                    }
                });
                
                $A.enqueueAction(quoteAction);
            //}
            
        }
        else{
        	//ERROR STARTS HERE
        	var errorMsg = 'No record ID has been provided to the page';
            errorMsg += '\n' + 'Please go back to the Opportunity page and try again';
            $A.createComponents([
                ["ui:message",{
                    "title" : "No Record ID Provided",
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
	},
    
    doSave : function(component, event, helper){
        //shows spinner 
        var x = document.getElementById("spinner");
        $A.util.removeClass(x, "slds-hide");
        
		var quotes = component.get("v.quotes");
        var quotesJSON = JSON.stringify(quotes);
        console.log(quotesJSON);
        var oppId = component.get("v.oppRecord.opportunity.Id");
        var oppName = component.get("v.oppRecord.opportunity.Name");
        var oppExpiryDate = component.get("v.oppRecord.opportunity.ExpiryDate__c");
        var action = component.get("c.saveRecords");
        
        action.setParams({
            "inQuotes" : quotesJSON,
            "inOppId" : oppId,
            "inOppName" : oppName,
            "inOppExpiryDate" : oppExpiryDate
        });
        
        action.setCallback(this, function(response){
            if(response.state == 'SUCCESS') {
                var oppRecord = response.getReturnValue();
                component.set("v.oppRecord", oppRecord);
                component.set("v.quotes", oppRecord.qwList);
                console.log(oppRecord.qwList);
                //2016-11-07 : SM : No longer using Preview for Portal 2.0
                //component.set("v.showPreviewPrompt", true);
                //Hide Spinner
                var x = document.getElementById("spinner");
        		$A.util.addClass(x, "slds-hide");
                //console.log(response.getReturnValue());
            } else {
                //Hide Spinner
                var x = document.getElementById("spinner");
        		$A.util.addClass(x, "slds-hide");
                
                //ERROR STARTS HERE
                var errorMsg = 'There was an error saving your records.';
                errorMsg += '\n' + 'Please go back to the Opportunity page and try again.';
                errorMsg += '\n' + 'If the error persist, please contact IT Support';
                $A.createComponents([
                    ["ui:message",{
                        "title" : "Error Saving Records",
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
        console.log('Enqueue Action');
        $A.enqueueAction(action);
    },
    
    hidePrompt : function(component, event, helper){
    	component.set("v.showPreviewPrompt", false);  
    },

})