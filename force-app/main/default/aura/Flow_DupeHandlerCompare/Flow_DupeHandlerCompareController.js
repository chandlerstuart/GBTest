({	    
	toggleOverwrite : function(component, event, helper) {
        var buttonClicked = event.getSource().getLocalId();
        console.log('buttonClicked: '+buttonClicked);
        var record = component.get("v.compareData");
        if(buttonClicked == "existingValueButton"){
            record.isOverwrite = false;
        }else if(buttonClicked == "userInputButton"){
            record.isOverwrite = true;
        }
        component.set("v.compareData",record);
        console.log('data: '+JSON.stringify(component.get("v.compareData")));
	}
})