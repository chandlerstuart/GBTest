({
    
    onInit : function(component,event,helper){
        let action = component.get("c.getNVMUsers");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let users = response.getReturnValue();
                if(users && users.length>0){
                    component.set("v.nvmUsers",users);
                    let options = [];
                    for(let i=0;i<users.length;i++){
                        let option = {};
                        option.label = users[i].Name;
                        option.value = users[i].NVMContactWorld__NVM_Agent_Id__c;
                        options.push(option);
                    }
                    component.set("v.options",options);
                }
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

        helper.checkAgentStatus(component,event,helper);
        //helper.setIsNVMUser(component,event,helper);

    },

    execute : function(component,event,helper){
        helper.execute(component,event,helper,true);
    },

    handleAgentOmniStatusChange : function(component,event,helper){
        helper.setIsNVMUser(component,event,helper);
        helper.handleAgentOmniStatusChange(component,event,helper);
    },

    handlePollingStatusChange : function(component,event,helper){
        helper.handlePollingStatusChange(component,event,helper);
    },

    handleUserSelection : function(component,event,helper){
        helper.setIsNVMUser(component,event,helper);
        helper.checkAgentStatus(component,event,helper);
    },

    handleOnACallChange : function(component,event,helper){
        helper.handleOnACallChange(component,event,helper);
    },

    onTabFocused : function(component,event,helper){
        helper.onTabFocused(component,event,helper);
    },
    
})