({
    openAccount : function(component, event, helper) {
        var id = event.target.getAttribute("data-id");
        var name = component.get("v.newAccntName");
        //First find the ID of the primary tab to put the new PrimaryTab in
            sforce.console.getEnclosingPrimaryTabId(
                function openPrimaryTab(result) {
                //Now that we have the primary tab ID, we can open a new PrimaryTab in it
                var primaryTabId = result.id;
                var newURL = window.location.protocol + "//" + window.location.host + "/";
                sforce.console.openPrimaryTab(null , newURL+id, true, name, null);
            });
    },
    openOpp : function(component, event, helper) {
        var id = event.target.getAttribute("data-id");
        var name = component.get("v.newOppName");
        //First find the ID of the primary tab to put the new PrimaryTab in
            sforce.console.getEnclosingPrimaryTabId(
                function openPrimaryTab(result) {
                //Now that we have the primary tab ID, we can open a new PrimaryTab in it
                var primaryTabId = result.id;
                var newURL = window.location.protocol + "//" + window.location.host + "/";
                sforce.console.openPrimaryTab(null , newURL+id, true, name, null);
            });
    }
})