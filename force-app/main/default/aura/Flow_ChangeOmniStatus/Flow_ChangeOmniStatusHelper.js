({
    updateStatus : function(component,event,helper) {
        let omniAPI = component.find("omniToolkit");
        let statusId = component.get("v.omniStatusId");
        statusId = statusId.substring(0, 15);
        omniAPI.setServicePresenceStatus({statusId:statusId}).then(function(result)
                                                                   {
                                                                       if(result){
                                                                           component.set("v.isSuccess",true);
                                                                           //fire test message
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
                                                                       }else{
                                                                           
                                                                       }
                                                                       helper.navigate(component,event,helper);
                                                                   }).catch(function(error) {
            component.set("v.isSuccess",false);
            component.set("v.errorMessage",JSON.stringify(error));
            console.log(error);
            helper.navigate(component,event,helper);
        });
    },
    
    navigate : function(component,event,helper){
        var navigate = component.get("v.navigateFlow");
        navigate("NEXT");
    }
})