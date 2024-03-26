({
	/*doInit : function(component, event, helper) {
        let recordId = component.get("v.recordId");
        component.set("v.canvasParameters", JSON.stringify({
            recordId: recordId
        }));
    },*/

    doInit : function(component, event, helper) {
        helper.getCanvasDataSet(component,event,helper);
    },

})