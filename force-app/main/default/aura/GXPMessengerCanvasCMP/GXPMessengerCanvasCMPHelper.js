({
    getCanvasDataSet : function(component,event,helper) {
        let action = component.get("c.getCanvasAppData");
        action.setParams({ recordId : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let data = response.getReturnValue();
                console.log(JSON.stringify(data));
                component.set("v.canvasParameters",JSON.stringify(data));
                component.set("v.showCanvas",true);
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                component.set("v.showCanvas",true);
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