({
    onInit : function(component, event, helper) {
        //Check to see if the user is already at this status
        let omniAPI = component.find("omniToolkit");
        omniAPI.getServicePresenceStatusId().then(function(result) {
            let currentStatus = result.statusId;
            currentStatus = (currentStatus != null)?currentStatus.substring(0,15):currentStatus;
            let newStatus = component.get("v.omniStatusId");
            newStatus = (newStatus != null)?newStatus.substring(0,15):newStatus;
            console.log('currentStatus >>> '+currentStatus);
            console.log('newStatus >>> '+newStatus);
            if(currentStatus == newStatus){
                console.log('Already in correct status');
                component.set("v.isSuccess",true);
                let successMessage = component.get("v.successMessage");
                if(successMessage && successMessage != null && successMessage != ''){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "message": successMessage,
                        "mode":"dismissible",
                        "type":"success"
                    });
                    toastEvent.fire();
                } 
                helper.navigate(component,event,helper);
            }else{
                //Attempt to Change status
                helper.updateStatus(component,event,helper);
            }
        }).catch(function(error) {
            console.log(error);
             helper.updateStatus(component,event,helper);
        });
        
    }
})