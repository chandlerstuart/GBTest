({
	takeOwnership : function(component) {
		var record = component.get("v.record"),
            recordData = component.find("recordData");
        	record.OwnerId = $A.get('$SObjectType').CurrentUser.Id;
        if(!component.get("v.complete")) { // Avoid infinite loop
            component.set("v.complete", true);
            component.set("v.record", record);
            recordData.saveRecord($A.getCallback(function(result) {
                if(result.state === "SUCCESS" || result.state === "DRAFT") {
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get("e.force:refreshView").fire();
                } else { 
                    console.log('Error Assigning Record: '+JSON.stringify(result.error)) 
                }
            }));
        }
	}
})