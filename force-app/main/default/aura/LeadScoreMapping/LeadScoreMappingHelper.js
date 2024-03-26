({
	getLeadMappings : function(component, selectedObj) {
        if(selectedObj != null && selectedObj != '' && selectedObj != '-'){
            var getLeadMappings = component.get("c.getScoreMappings");
            getLeadMappings.setParams({ "objName" : selectedObj});
            getLeadMappings.setCallback(this, function(response) {
                var state = response.getState();
                var responseData = response.getReturnValue();
                if (state === "SUCCESS") {
                   this.setDataFromResponse(component,"v.leadScoreMappings",responseData.returnObj);
                }
                this.handleResponseMessage(component, responseData, false);
            });
    
            this.enqueueAction(getLeadMappings);
        }
	},
    
    saveMap : function(component, event, helper) {
        var leadMapping = component.get("v.leadScoreMapping");
        leadMapping.Name = component.find("LeadScoreMappingNameBox").get("v.value");
        leadMapping.RuleType__c = component.find("ruletypeBox").get("v.value");
        leadMapping.LeadScoreMinimumValue__c = component.find("LeadScoreMinimumValueBox").get("v.value");
        leadMapping.LeadScoreMaximumValue__c = component.find("LeadScoreMaximumValueBox").get("v.value");
        leadMapping.LeadRating__c = component.find("leadratingBox").get("v.value");
        leadMapping.CasePriority__c = component.find("priorityBox").get("v.value");
        
        var saveLeadMapping = component.get("c.saveScoreMapping");
        saveLeadMapping.setParams({ "lsrObject" : leadMapping});
        saveLeadMapping.setCallback(this, function(response) {
            var state = response.getState();
            var responseData = response.getReturnValue();
            if (state === "SUCCESS") {
                this.getLeadMappings(component, leadMapping.RuleType__c);
            }
            
            this.handleResponseMessage(component, responseData, true);
            
        });

        this.enqueueAction(saveLeadMapping);
	},
    
    setDataFromResponse : function(component,cmpVar,data) {
        component.set(cmpVar,data);
    },
    
    enqueueAction : function(action) {
        $A.enqueueAction(action);
    },
    
    validateRequired : function(fieldObject) {
        var isValid = true;
        var fieldValue = fieldObject.get("v.value");
        if($A.util.isUndefined(fieldValue) || $A.util.isEmpty(fieldValue)){
            fieldObject.set("v.errors", [{message:"This is a required field."}]);
            isValid = false;
        }
        
        return isValid;
    },
    
    validateNumber : function(fieldObject) {
        var isValid = true;
        var fieldValue = fieldObject.get("v.value");
        isValid = this.validateRequired(fieldObject);
        if(isValid && isNaN(fieldValue)){
            fieldObject.set("v.errors", [{message:"Please Enter a Number."}]);
            isValid = false;
        }
        
        return isValid;
    },
    
    validateRange : function(minFieldObject, maxFieldObject) {
        var isValid = true;
        var minFieldValue = minFieldObject.get("v.value");
    	var maxFieldValue = maxFieldObject.get("v.value");
        
        var minValid = this.validateNumber(minFieldObject);
        var maxValid = this.validateNumber(maxFieldObject);
        
        if(!minValid || !maxValid){
            isValid = false;
        }
        
        if(isValid && Number(minFieldValue) > Number(maxFieldValue)){
            minFieldObject.set("v.errors", [{message:"Minimum Value must be lesser than the maximum value"}]);
            isValid = false;
        }
        
        return isValid;
    },
    
    handleResponseMessage : function(component, responseData, isPromptSuccess) {
        if(isPromptSuccess && responseData.statusCode == 200){
        	this.handleMessages(component, "info", responseData.message);
        }
        else if(responseData.statusCode == 400){
        	this.handleMessages(component, "error", responseData.message);
        }
    },
    
    handleMessages : function(component, type, message) {
        if(type === "error"){
            component.set("v.errorMsg", message);
        }
        else if(type === "info"){
            component.set("v.infoMsg", message);
        }
    },
    
    removeErrors : function(fieldObject) {
        fieldObject.set("v.errors", null);
    },
    
    removeServerSideErrors : function(component) {
    	component.set("v.infoMsg", "");
        component.set("v.errorMsg", "");
    }
})