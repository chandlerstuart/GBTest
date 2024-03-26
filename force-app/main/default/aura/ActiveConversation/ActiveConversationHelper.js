({
    loadActiveConversation: function(component, event, helper) {
        // Retrieve attribute values
        var recordId = component.get("v.recordId");
        var conversationLookupFieldName = component.get("v.conversationLookupFieldName");

        // Call an Apex method to query for the most recent active conversation
        var action = component.get("c.getMostRecentActiveConversation");
        action.setParams({
            "recordId": recordId,
            "conversationLookupFieldName": conversationLookupFieldName
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                if (result) {
                    // Set the active conversation attributes
                    component.set("v.activeConversationId", result.Id);
                    component.set("v.activeConversation", result);
                } else {
                    component.set("v.error", "No Active Conversations");
                }
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    component.set("v.error", "Error: " + errors[0].message);
                } else {
                    component.set("v.error", "Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
    },

    closeActiveConversation: function(component, event, helper) {
        // Retrieve attribute values
        var activeConversationId = component.get("v.activeConversationId");

        // Call an Apex method to query for the most recent active conversation
        var action = component.get("c.closeActiveConversation");
        action.setParams({
            "conversationId": activeConversationId,
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                if (result) {
                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "type":"success",
                        "message": "This conversation was closed successfully. If any follow up activity is required, click {0}",
                        messageTemplate : "This conversation was closed successfully. If any follow up activity is required, click {0}",
                        messageTemplateData: [{
                            url: '/'+activeConversationId,
                            label: 'here.',
                            }
                        ]
                    });
                    toastEvent.fire();
                    component.set("v.activeConversationId",null);
                    component.set("v.activeConversation",null);
                    this.loadActiveConversation(component,event,helper);//Refresh
                } else {
                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Whoops!",
                        "message": "Something went wrong. Please contact the Salesforce Team if you require assistance.",
                        "type":"error"
                    });
                    toastEvent.fire();
                }
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    component.set("v.error", "Error: " + errors[0].message);
                } else {
                    component.set("v.error", "Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
    },

    openConversation : function(component,event,helper){
        let navEvt = $A.get("e.force:navigateToSObject");
        var activeConversationId = component.get("v.activeConversationId");
        navEvt.setParams({
          "recordId": activeConversationId
        });
        navEvt.fire();
    },
    
})