({
	onInit : function(component, event, helper) {
        helper.removeServerSideErrors(component);
        var selectedObj = component.get("v.ruleSelected");
        helper.getLeadMappings(component, selectedObj);
	},
    
    ruleChanged : function(component, event, helper) {
        helper.removeServerSideErrors(component);
        var selectedObj = component.get("v.ruleSelected");
        helper.getLeadMappings(component, selectedObj);
	},
    
    handleSave : function(component, event, helper) {
        helper.removeServerSideErrors(component);
        
        var Name = component.find("LeadScoreMappingNameBox");
        var Min = component.find("LeadScoreMinimumValueBox");
        var Max = component.find("LeadScoreMaximumValueBox");
        helper.removeErrors(Name);
        helper.removeErrors(Min);
        helper.removeErrors(Max);
        
        var isValid = true;
          
        if(!helper.validateRequired(Name)){
           	isValid = false;	
        }
        
        if(!helper.validateRange(Min,Max)){
           	isValid = false;	
        }
        
        if(isValid){
            helper.saveMap(component, event);
        }
	},
    
    delete: function(component, event, helper) {
    	helper.removeServerSideErrors(component);
        //Get data via "data-data" attribute from button (button itself or icon's parentNode)
        var selectedObj = component.find("ruletypeBox").get("v.value");
        var Id = event.target.getAttribute("data-data") || event.target.parentNode.getAttribute("data-data")
        if(Id){
        	var deleteLeadMapping = component.get("c.deleteLeadScoreMapping");
            deleteLeadMapping.setParams({ "lsmId" : Id});
            deleteLeadMapping.setCallback(this, function(response) {
                var state = response.getState();
                var responseData = response.getReturnValue();
                if (state === "SUCCESS") {
                    helper.getLeadMappings(component, selectedObj);
                }
                
                helper.handleResponseMessage(component, responseData, true);
            });
    
            $A.enqueueAction(deleteLeadMapping);
    	}
        else{
            helper.handleMessages(component, "error", "Parameter error occurred. Please try again later.");
        }
   }
})