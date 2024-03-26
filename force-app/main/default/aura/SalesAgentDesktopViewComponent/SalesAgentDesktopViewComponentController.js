({
	openListView: function(component, event, helper) {
        var  url = component.get("v.viewURL");
        console.log('Opening ' + url);
        sforce.console.openPrimaryTab(null , url, true);
    },
    
    doExpandCollapse : function(component, event, helper){
        var currentStatus = component.get("v.isExpanded");
        console.log(currentStatus);
        if (!currentStatus){
            component.set("v.isExpanded", true);
        }else {
            component.set("v.isExpanded",false);
        }
    }
})