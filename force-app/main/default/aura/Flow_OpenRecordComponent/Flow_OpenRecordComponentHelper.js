({
    openTab : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        console.log('Open Tab Initiated');
        console.log('RecordId: '+recordId);
        if(recordId != null){
            var workspaceAPI = component.find("workspace");
            workspaceAPI.openTab({
                recordId: recordId,
                focus: true
            }).then(function(response) {
                workspaceAPI.getTabInfo({
                    tabId: response
                }).then(function(tabInfo) {
                    console.log("The url for this tab is: " + tabInfo.url);
                });
            })
            .catch(function(error) {
                console.log(error);
            });
        }else{
            console.log('No Record Id Passed into the Flow Component');
        }
    },
    
    openInCommunity : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        console.log('Open Tab Initiated - Community');
        console.log('RecordId: '+recordId);
        if(recordId != null){
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": recordId,
                "slideDevName": "detail"
            });
            navEvt.fire();
        }
    }
    
})