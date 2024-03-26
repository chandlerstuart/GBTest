({
    doInit : function(component, event, helper){

    },
    
    handleUserEvent : function(component, event, helper){
        console.log('Handling Event');
        var userList = event.getParam("userList");
        component.set("v.userList", userList);
        
    },
    
    cancelAssign : function(component, event, helper){
        component.set("v.selectedUserId", '');
        var space = component.get("v.space");
		var pop = document.getElementById("popout" + space.spaceNumber);
        var popBackground = document.getElementById("popoutBackground");
        
        $A.util.addClass(popBackground, "slds-hide");
        $A.util.addClass(pop, "slds-hide");
    },
    
    assignSpace : function(component, event, helper){
        var space = component.get("v.space");
		var pop = document.getElementById("popout" + space.spaceNumber);
        var popBackground = document.getElementById("popoutBackground");
        
        $A.util.addClass(popBackground, "slds-hide");
        $A.util.addClass(pop, "slds-hide");
        
        if (component.get("v.selectedUserId") != null){
            var whichSpace = space.spaceNumber;
            var selectedUserId = component.get("v.selectedUserId");
            console.log('Assigning ' + whichSpace + ' to ' + selectedUserId);
            
            var assignAction = component.get("c.assignSpaceToUser");
            assignAction.setParams({
                "selectedUserId" : selectedUserId,
                "whichSpace" : whichSpace
            });
            
            assignAction.setCallback(this, function(response){
            	if (response.state == 'SUCCESS'){
                    
	            	//DO WE INFORM THEM?
	            	var assignedEvent = component.getEvent("spaceUpdated");
                    assignedEvent.fire();
	            }	                                        
			});
            
            $A.enqueueAction(assignAction);
        }
    },
    
    onSelectChange : function(component, event, helper) {
    	var selected = component.find("assignUsers").get("v.value");
        console.log(selected + ' selected');
        component.set("v.selectedUserId", selected);
    	//do something else
	},
})