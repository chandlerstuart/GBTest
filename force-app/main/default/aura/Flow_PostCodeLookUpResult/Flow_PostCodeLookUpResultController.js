({
	resultSelected : function(component, event, helper) {
		var selectEvent = component.getEvent("PostcodeLookupResultSelected");
        selectEvent.setParams({
            "text" : component.get("v.text"),
            "description" : component.get("v.description"),
            "id" : component.get("v.id"),
            "type" : component.get("v.type")
        });
        selectEvent.fire();
	}
})