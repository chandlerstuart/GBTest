({
    //Called at scheduled polling intervals
    execute : function(component,event,helper,isTest){

        //If not on a call or polling is false, return 
        if(!component.get("v.polling") && !isTest) return;
        if(!helper.checkAgentStatus(component,event,helper)) return;
        if(!component.get("v.isNVMUser")) return;//Prevent callouts for users without an NVM Id

        console.log('Executing!');

        let action = component.get("c.executeCallTracking");
        action.setParams({
            "agentId":component.get("v.value"),
            "minimumConnectedCallTime":component.get("v.minimumConnectedCallTime"),
            "pollingInterval":component.get("v.pollingInterval"),
            "messageTypeDeveloperName":component.get("v.messageTypeDeveloperName"),
            "customMessage":component.get("v.customMessage")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let data = response.getReturnValue();
                console.log('Completed execution! ',data);
                if(data.message && data.message != null) component.set("v.message",data.message);
                if(component.get("v.onACall") && data.unrecognisedPhoneNumber && data.unrecognisedPhoneNumber != null){
                    component.set("v.unrecognisedPhoneNumber",data.unrecognisedPhoneNumber);//Cache unrecognised number for retries following record creation
                }else{
                    component.set("v.unrecognisedPhoneNumber",null);
                }
                if(data.nextAttemptInSeconds && data.nextAttemptInSeconds != null){
                    if(!component.get("v.polling")) return;
                    console.log('Queueing another attempt in '+data.nextAttemptInSeconds+' seconds');
                    window.setTimeout(
                        $A.getCallback(function() {
                            helper.execute(component,event,helper,false);
                        }), data.nextAttemptInSeconds*1000
                    );
                }else{
                    console.log('Cancel polling');
                    component.set("v.polling",false);
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
    },

    handleAgentOmniStatusChange : function(component,event,helper){

        var statusId = event.getParam('statusId');
        var channels = event.getParam('channels');
        var statusName = event.getParam('statusName');
        var statusApiName = event.getParam('statusApiName');
        console.log(statusId);
        console.log(channels);
        console.log(statusName);
        console.log(statusApiName);

        component.set("v.activeStatusId",statusId);

        helper.checkAgentStatus(component,event,helper);
    },

    checkAgentStatus : function(component,event,helper,isTest){

        if(!component.get("v.isNVMUser")){
            console.log('Not an NVM User');
            return false;
        }

        let onACallAgentStatusId = component.get("v.onACallAgentStatusId");
        console.log('On call status id > '+onACallAgentStatusId);
        let currentStatusId = component.get("v.activeStatusId");
        console.log('Current status id > '+JSON.stringify(currentStatusId));

        if(onACallAgentStatusId == null || currentStatusId == null){
            component.set("v.onACall",false);
            component.set("v.polling",false);
            return false;
        } 
        
        if(currentStatusId == onACallAgentStatusId || isTest){
            console.log('Agent on a Call!');
            component.set("v.onACall",true);
            if(!component.get("v.polling")) component.set("v.polling",true);
        }else{
            console.log('Agent NOT on a Call');
            component.set("v.onACall",false);
            if(component.get("v.polling")) component.set("v.polling",false);
        }

        return (currentStatusId == onACallAgentStatusId);
    },

    handlePollingStatusChange : function(component,event,helper){
        //If set to true, queue execution
        let polling = component.get("v.polling");
        if(polling == true){
            console.log('Polling start!');
            let pollingInterval = component.get("v.pollingInterval");
            if(!pollingInterval) pollingInterval = 15;
            window.setTimeout(
                $A.getCallback(function() {
                    helper.execute(component,event,helper,false);
                }), pollingInterval*1000
            );
        }else{
            console.log('Polling finish!');
        }

    },

    setIsNVMUser : function(component,event,helper){
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        let nvmUsers = component.get("v.nvmUsers");

        //Exit if test user is selected
        let agentId = component.get("v.value");
        if(agentId && agentId != null){
            component.set("v.isNVMUser",true);
            return;
        }

        if(nvmUsers && nvmUsers.length>0){
            let isNVMUser = false;
            for(let i=0;i<nvmUsers.length;i++){
                if(userId == nvmUsers[i].Id){
                    isNVMUser = true;
                    break;
                }
            }
            component.set("v.isNVMUser",isNVMUser);
        }else{
            component.set("v.isNVMUser",false);
        }
    },

    handleOnACallChange : function(component,event,helper){
        let unrecognisedPhoneNumber = component.get("v.unrecognisedPhoneNumber");
        let onACall = component.get("v.onACall")
        if(!onACall && unrecognisedPhoneNumber != null){
            console.log('No longer on a call. Clearing unrecognised number > '+unrecognisedPhoneNumber);
            component.set("v.unrecognisedPhoneNumber", null);
        }
    },

    onTabFocused : function(component,event,helper){

        if(!component.get("v.onACall")){
            console.log('onTabFocused > Not on a call');
            return;//No action required if the agent isn't on an active call
        } 

        let unrecognisedPhoneNumber = component.get("v.unrecognisedPhoneNumber");
        if(!unrecognisedPhoneNumber){
            console.log('onTabFocused > No customer number to retry');
            return;//No action required if there isn't a number for the active caller
        } 

        //Verify tab details - Focus tab record Id = Opp Id
        console.log("Tab Focused");
        var focusedTabId = event.getParam('currentTabId');
        if(!focusedTabId) return;
        var workspaceAPI = component.find("workspace");        
        workspaceAPI.getTabInfo({
            tabId : focusedTabId
        }).then(function(response) {

            console.log('Tab Data: ',JSON.stringify(response)); 
            
            let unrecognisedPhoneNumber = component.get("v.unrecognisedPhoneNumber");
            if(!unrecognisedPhoneNumber) return;//No action required if there isn't a number for the active caller
            if(response.recordId == null) return;

            if(response.recordId.slice(0,3) == '006'){//Focused on Opp (whilst on a call)
                let action = component.get("c.retryPhoneNumber");
                action.setParams({
                    "agentId":component.get("v.value"),
                    "customerNumber":unrecognisedPhoneNumber,
                    "oppId":response.recordId,
                    "messageTypeDeveloperName":component.get("v.messageTypeDeveloperName"),
                    "customMessage":component.get("v.customMessage")
                });
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        let data = response.getReturnValue();
                        console.log('Completed number retry! ',data);
                        if(data.message && data.message != null){
                            component.set("v.message",data.message);
                            console.log(data.message);
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
            }

        });

    }
})