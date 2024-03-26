({
	doInit : function(component, event, helper) {
        helper.initMethod(component, event, helper);
	},
    
    handleUpdateEvent : function(component, event, helper){
		helper.initMethod(component, event, helper);
    },
    
    assignSpace : function(component, event, helper){
    	var whichButton = event.getSource();
        console.log(whichButton);
    },
    
    findMySpace : function(component, event, helper){
        var spaces = component.get("v.parkingSpaces");
        var currentUser = component.get("v.userRecord");
        var gotoId;
        for (var i = 0 ; i < spaces.length ; i++){
            if (spaces[i].currentUser != null){
                //console.log(spaces[i]);
	            if (spaces[i].parkingRecord.Current_User__r.Id == currentUser.Id){
    	            //console.log('FOUND MATCH');
        	        gotoId = 'ps'+spaces[i].parkingRecord.Name;
            	    //console.log('*** -- Go to ' + gotoId + ' -- ***');
                	break;
            	}
            }
        }
		var element = document.getElementById(gotoId);
        //console.log(element);
        if (element != 'undefined'){
            element.scrollIntoView();
            //element.focus();
        }
    },
})