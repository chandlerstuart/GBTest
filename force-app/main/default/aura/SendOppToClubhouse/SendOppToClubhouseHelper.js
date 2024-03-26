({
	sendOppToClubhouse : function(component, event, helper, theOpp) {
		// create a one-time use instance of the serverEcho action
        // in the server-side controller
        var action = component.get("c.queueAction");
        action.setParams({ opp : theOpp });

        // Create a callback that is executed after 
        // the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Alert the user with the value returned 
                // from the server
                alert("The Request has been successfully sent to Clubhouse. Please wait a couple of seconds, then refresh and confirm the Enquiry Id has been set");

            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
	}
})