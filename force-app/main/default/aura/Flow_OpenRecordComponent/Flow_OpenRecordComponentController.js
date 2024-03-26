({
    onInit : function(component, event, helper) {
        var isCommunity = component.get("v.IsCommunityFlow");
        var autoOpen = component.get("v.openOnPageLoad");
        if(autoOpen){
            if(!isCommunity){
                helper.openTab(component,event,helper);
            }else{
                helper.openInCommunity(component,event,helper);
            }
        }
    },
    
    openTab : function(component, event, helper) {
        var isCommunity = component.get("v.IsCommunityFlow");
        if(!isCommunity){
            helper.openTab(component,event,helper);
        }else{
            helper.openInCommunity(component,event,helper);
        }
    }
})