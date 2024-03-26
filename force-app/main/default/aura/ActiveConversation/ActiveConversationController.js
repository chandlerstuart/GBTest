({
    doInit: function(component, event, helper) {
        helper.loadActiveConversation(component,event,helper);
    },

    openConversation : function(component,event,helper){
        if(component.get("v.activeConversationId") == null) return; 
        helper.openConversation(component,event,helper);
    },

    closeConversation : function(component,event,helper){
        if(component.get("v.activeConversationId") == null) return; 
        //Are you sure?
        if(confirm('Are you sure you want to close this conversation?')){
            helper.closeActiveConversation(component,event,helper);
        }
    }
})