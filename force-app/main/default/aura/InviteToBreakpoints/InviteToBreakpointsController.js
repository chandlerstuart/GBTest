({
	inviteToBreakpoints : function(component, event, helper) {
		helper.inviteToBreakpoints(component,event,helper);		
	},
    
    onInit : function(component,event,helper){
        
        var recordId = component.get("v.recordId");
        var fieldName = component.get("v.fieldName");
        var sObjectType = component.get("v.sObjectType");
        
        //Validating parameters for server side call
        if(!recordId || !fieldName || !sObjectType){
            var errorMessage = 'Missing Info: ';
            if(!recordId) errorMessage += 'No Record Id set. ';
            if(!fieldName) errorMessage += 'No Field Name set. ';
            if(!sObjectType) errorMessage += 'No sObjectType set. ';
            component.set("v.errorMessage",errorMessage);
            console.error('Error: '+errorMessage);
            return;
        }
    }
})